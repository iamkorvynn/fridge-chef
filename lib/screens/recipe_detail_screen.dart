import 'package:material_ui/material_ui.dart';

import '../models/recipe.dart';
import '../state/app_state.dart';

/// Full recipe: ingredients with have/missing marks, numbered steps,
/// and a favourite toggle.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.state,
  });

  final Recipe recipe;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final isFavourite = state.isFavourite(recipe.id);
              return IconButton(
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: isFavourite ? Colors.red : null,
                ),
                onPressed: () => state.toggleFavourite(recipe.id),
                tooltip: isFavourite
                    ? 'Remove from favourites'
                    : 'Save to favourites',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(recipe.cuisine)),
                  Chip(label: Text(recipe.veg ? 'Veg' : 'Non-veg')),
                  Chip(label: Text('Prep ${recipe.prepMinutes} min')),
                  Chip(label: Text('Cook ${recipe.cookMinutes} min')),
                  Chip(label: Text(recipe.difficulty)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ingredients (${recipe.ingredients.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((ingredient) {
                final have = state.selectedIngredients.contains(
                  ingredient.name,
                );
                final isStaple = Recipe.staples.contains(ingredient.name);
                return ListTile(
                  leading: Icon(
                    have || isStaple
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: have || isStaple ? Colors.green : Colors.grey,
                  ),
                  title: Text(ingredient.name),
                  subtitle: Text(ingredient.quantity),
                  trailing: isStaple
                      ? const Text(
                          'pantry staple',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        )
                      : have
                          ? const Text(
                              'you have it',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            )
                          : const Text(
                              'missing',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Steps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map((entry) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${entry.key + 1}'),
                  ),
                  title: Text(entry.value),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
