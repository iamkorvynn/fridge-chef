import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/ingredient_catalog.dart';
import '../models/recipe.dart';
import '../services/favourites_db.dart';
import '../services/matcher.dart';
import '../services/settings_service.dart';

/// Shared app state: the bundled recipes, the ingredients the user
/// currently has, saved favourites, and the recipe-list filters.
class AppState extends ChangeNotifier {
  AppState({SettingsService? settings, FavouritesDb? favouritesDb})
    : _settings = settings ?? SettingsService(),
      _favouritesDb = favouritesDb ?? FavouritesDb.instance;

  final SettingsService _settings;
  final FavouritesDb _favouritesDb;

  List<Recipe> recipes = [];
  bool recipesLoaded = false;
  String? loadError;

  final Set<String> selectedIngredients = {};
  final Set<String> favouriteIds = {};

  VegFilter vegFilter = VegFilter.all;
  int? maxTotalMinutes;
  String searchQuery = '';

  Future<void> init() async {
    try {
      final jsonText = await rootBundle.loadString('assets/recipes.json');
      recipes = parseRecipes(jsonText);
      recipesLoaded = true;
    } catch (e) {
      loadError = 'Could not load the recipe book: $e';
    }
    selectedIngredients.addAll(await _settings.getSelectedIngredients());
    favouriteIds.addAll(await _favouritesDb.getAll());
    notifyListeners();
  }

  void toggleIngredient(String name) {
    final key = IngredientCatalog.normalize(name);
    if (key.isEmpty) return;
    if (selectedIngredients.contains(key)) {
      selectedIngredients.remove(key);
    } else {
      selectedIngredients.add(key);
    }
    _persistIngredients();
    notifyListeners();
  }

  void addIngredients(Iterable<String> names) {
    var changed = false;
    for (final raw in names) {
      final key = IngredientCatalog.normalize(raw);
      if (key.isNotEmpty && selectedIngredients.add(key)) changed = true;
    }
    if (changed) {
      _persistIngredients();
      notifyListeners();
    }
  }

  void removeIngredient(String name) {
    if (selectedIngredients.remove(IngredientCatalog.normalize(name))) {
      _persistIngredients();
      notifyListeners();
    }
  }

  void clearIngredients() {
    if (selectedIngredients.isEmpty) return;
    selectedIngredients.clear();
    _persistIngredients();
    notifyListeners();
  }

  Future<void> _persistIngredients() async {
    await _settings.setSelectedIngredients(selectedIngredients);
  }

  Future<void> toggleFavourite(String recipeId) async {
    final nowFavourite = await _favouritesDb.toggle(recipeId);
    if (nowFavourite) {
      favouriteIds.add(recipeId);
    } else {
      favouriteIds.remove(recipeId);
    }
    notifyListeners();
  }

  bool isFavourite(String recipeId) => favouriteIds.contains(recipeId);

  List<Recipe> get favouriteRecipes =>
      recipes.where((r) => favouriteIds.contains(r.id)).toList();

  /// Ranked matches for the current ingredients, after search + filters.
  List<RecipeMatch> get rankedMatches {
    final searched = searchRecipes(recipes, searchQuery);
    final ranked = rankRecipes(searched, selectedIngredients);
    return filterMatches(
      ranked,
      vegFilter: vegFilter,
      maxTotalMinutes: maxTotalMinutes,
    );
  }

  void setVegFilter(VegFilter filter) {
    vegFilter = filter;
    notifyListeners();
  }

  void setMaxTotalMinutes(int? minutes) {
    maxTotalMinutes = minutes;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }
}
