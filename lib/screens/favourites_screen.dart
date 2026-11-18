import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'recipe_detail_screen.dart';

/// Saved favourite recipes, stored locally in SQLite.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final favourites = state.favouriteRecipes;
          if (favourites.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No favourites yet.\n'
                  'Tap the heart on any recipe to save it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              final recipe = favourites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${recipe.cuisine} • ${recipe.totalMinutes} min • '
                    '${recipe.veg ? 'Veg' : 'Non-veg'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RecipeDetailScreen(recipe: recipe, state: state),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
