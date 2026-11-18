import 'package:material_ui/material_ui.dart';

import '../services/matcher.dart';
import '../state/app_state.dart';
import 'recipe_detail_screen.dart';

/// Ranked recipe list: best match first, with the missing ingredients
/// shown on each card. Search + veg/time filters on top.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (!state.recipesLoaded) {
            return Center(
              child: Text(
                state.loadError ?? 'Loading recipes…',
                textAlign: TextAlign.center,
              ),
            );
          }
          final matches = state.rankedMatches;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search recipes',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: state.setSearchQuery,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<VegFilter>(
                        segments: const [
                          ButtonSegment(
                            value: VegFilter.all,
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: VegFilter.veg,
                            label: Text('Veg'),
                          ),
                          ButtonSegment(
                            value: VegFilter.nonVeg,
                            label: Text('Non-veg'),
                          ),
                        ],
                        selected: {state.vegFilter},
                        onSelectionChanged: (selected) {
                          state.setVegFilter(selected.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int?>(
                      value: state.maxTotalMinutes,
                      hint: const Text('Any time'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any time')),
                        DropdownMenuItem(value: 15, child: Text('≤ 15 min')),
                        DropdownMenuItem(value: 30, child: Text('≤ 30 min')),
                        DropdownMenuItem(value: 45, child: Text('≤ 45 min')),
                        DropdownMenuItem(value: 60, child: Text('≤ 60 min')),
                      ],
                      onChanged: state.setMaxTotalMinutes,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.selectedIngredients.isEmpty
                        ? '${matches.length} recipes — add ingredients in '
                              'My Fridge to rank them by what you have.'
                        : '${matches.length} recipes ranked by your '
                              '${state.selectedIngredients.length} '
                              'ingredient(s).',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? const Center(
                        child: Text(
                          'No recipes match these filters.\n'
                          'Try widening the time limit or clearing the search.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          return _RecipeCard(
                            match: matches[index],
                            state: state,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match, required this.state});

  final RecipeMatch match;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recipe = match.recipe;
    final isFavourite = state.isFavourite(recipe.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RecipeDetailScreen(recipe: recipe, state: state),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: isFavourite ? Colors.red : null,
                    ),
                    onPressed: () => state.toggleFavourite(recipe.id),
                    tooltip: isFavourite
                        ? 'Remove from favourites'
                        : 'Save to favourites',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      '${match.percent}% match',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: match.canCookNow
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ),
                  Chip(label: Text(recipe.veg ? 'Veg' : 'Non-veg')),
                  Chip(label: Text('${recipe.totalMinutes} min')),
                  Chip(label: Text(recipe.difficulty)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                recipe.cuisine,
                style: const TextStyle(color: Colors.black54),
              ),
              if (match.missing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Missing: ${match.missing.map((i) => i.name).join(', ')}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'You have everything — cook it now!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
