import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite store for saved favourite recipes.
/// Only recipe ids are stored; the recipes themselves live in the
/// bundled assets/recipes.json, so this table is tiny.
class FavouritesDb {
  FavouritesDb._();

  static final FavouritesDb instance = FavouritesDb._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'fridge_chef.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE favourites ('
          'recipe_id TEXT PRIMARY KEY, '
          'saved_at INTEGER NOT NULL)',
        );
      },
    );
    return _db!;
  }

  Future<Set<String>> getAll() async {
    final db = await _database;
    final rows = await db.query('favourites', columns: ['recipe_id']);
    return rows.map((r) => r['recipe_id'] as String).toSet();
  }

  Future<bool> isFavourite(String recipeId) async {
    final db = await _database;
    final rows = await db.query(
      'favourites',
      columns: ['recipe_id'],
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    return rows.isNotEmpty;
  }

  /// Toggles the favourite state and returns the new state.
  Future<bool> toggle(String recipeId) async {
    final db = await _database;
    final wasFavourite = await isFavourite(recipeId);
    if (wasFavourite) {
      await db.delete(
        'favourites',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );
    } else {
      await db.insert('favourites', {
        'recipe_id': recipeId,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    return !wasFavourite;
  }

  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('favourites');
  }
}
