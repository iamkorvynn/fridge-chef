import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/models/recipe.dart';
import 'package:fridgechef/services/matcher.dart';

Recipe _recipe({
  String id = 'test',
  String name = 'Test Dish',
  bool veg = true,
  int prep = 10,
  int cook = 20,
  List<String> ingredients = const ['tomato', 'onion', 'paneer'],
}) {
  return Recipe(
    id: id,
    name: name,
    cuisine: 'North Indian',
    veg: veg,
    prepMinutes: prep,
    cookMinutes: cook,
    difficulty: 'Easy',
    ingredients: ingredients
        .map((n) => RecipeIngredient(name: n, quantity: '1'))
        .toList(),
    steps: const ['Cook it.', 'Serve it.'],
  );
}

void main() {
  group('matchRecipe', () {
    test('100% when the user has every matchable ingredient', () {
      final recipe = _recipe();
      final match = matchRecipe(recipe, {'tomato', 'onion', 'paneer'});
      expect(match.percent, 100);
      expect(match.missing, isEmpty);
      expect(match.canCookNow, isTrue);
    });

    test('partial match reports the right percent and missing list', () {
      final recipe = _recipe();
      final match = matchRecipe(recipe, {'tomato'});
      // 1 of 3 matchable ingredients.
      expect(match.percent, 33);
      expect(match.matchedCount, 1);
      expect(match.totalCount, 3);
      expect(match.missing.map((i) => i.name), ['onion', 'paneer']);
      expect(match.canCookNow, isFalse);
    });

    test('0% when the user has none of the ingredients', () {
      final recipe = _recipe();
      final match = matchRecipe(recipe, {'chicken'});
      expect(match.percent, 0);
      expect(match.missing.length, 3);
    });

    test('salt and sugar are pantry staples and do not count', () {
      final recipe = _recipe(
        ingredients: const ['tomato', 'salt', 'sugar', 'onion'],
      );
      final match = matchRecipe(recipe, {'tomato', 'onion'});
      expect(match.totalCount, 2);
      expect(match.percent, 100);
    });

    test('empty ingredient list matches at 100% (nothing needed)', () {
      final recipe = _recipe(ingredients: const ['salt']);
      final match = matchRecipe(recipe, {});
      expect(match.percent, 100);
      expect(match.canCookNow, isTrue);
    });
  });

  group('rankRecipes', () {
    test('best match first, ties broken by fewest missing then time', () {
      final best = _recipe(id: 'best', ingredients: const ['tomato']);
      final partial = _recipe(
        id: 'partial',
        ingredients: const ['tomato', 'onion', 'paneer'],
      );
      final none = _recipe(id: 'none', ingredients: const ['chicken']);
      final ranked = rankRecipes(
        [none, partial, best],
        {'tomato', 'onion'},
      );
      expect(ranked.map((m) => m.recipe.id), ['best', 'partial', 'none']);
      expect(ranked[0].percent, 100);
      expect(ranked[1].percent, 67);
      expect(ranked[2].percent, 0);
    });
  });

  group('filterMatches', () {
    final vegRecipe = _recipe(id: 'veg', veg: true, prep: 5, cook: 10);
    final nonVegRecipe = _recipe(id: 'nonveg', veg: false, prep: 5, cook: 10);
    final slowRecipe = _recipe(id: 'slow', veg: true, prep: 30, cook: 40);

    List<RecipeMatch> all() => [vegRecipe, nonVegRecipe, slowRecipe]
        .map((r) => matchRecipe(r, {'tomato', 'onion', 'paneer'}))
        .toList();

    test('veg filter keeps only veg recipes', () {
      final filtered = filterMatches(all(), vegFilter: VegFilter.veg);
      expect(filtered.map((m) => m.recipe.id), ['veg', 'slow']);
    });

    test('non-veg filter keeps only non-veg recipes', () {
      final filtered = filterMatches(all(), vegFilter: VegFilter.nonVeg);
      expect(filtered.map((m) => m.recipe.id), ['nonveg']);
    });

    test('max time filter drops slow recipes', () {
      final filtered = filterMatches(all(), maxTotalMinutes: 30);
      expect(filtered.map((m) => m.recipe.id), ['veg', 'nonveg']);
    });

    test('veg + max time combine', () {
      final filtered = filterMatches(
        all(),
        vegFilter: VegFilter.veg,
        maxTotalMinutes: 30,
      );
      expect(filtered.map((m) => m.recipe.id), ['veg']);
    });
  });

  group('searchRecipes', () {
    test('matches by name, case-insensitive', () {
      final recipes = [
        _recipe(id: 'a', name: 'Dal Tadka'),
        _recipe(id: 'b', name: 'Paneer Butter Masala'),
      ];
      expect(searchRecipes(recipes, 'dal').map((r) => r.id), ['a']);
      expect(searchRecipes(recipes, 'PANEER').map((r) => r.id), ['b']);
    });

    test('matches by cuisine and empty query returns everything', () {
      final recipes = [_recipe(id: 'a', name: 'X')];
      expect(searchRecipes(recipes, 'north').length, 1);
      expect(searchRecipes(recipes, '').length, 1);
      expect(searchRecipes(recipes, 'zzz'), isEmpty);
    });
  });

  group('parseRecipes', () {
    test('parses a recipe JSON document', () {
      const jsonText = '''
[
  {
    "id": "dal-tadka",
    "name": "Dal Tadka",
    "cuisine": "North Indian",
    "veg": true,
    "prepMinutes": 10,
    "cookMinutes": 25,
    "difficulty": "Easy",
    "ingredients": [
      {"name": "toor dal", "quantity": "1 cup"},
      {"name": "salt", "quantity": "to taste"}
    ],
    "steps": ["Cook the dal.", "Serve hot."]
  }
]
''';
      final recipes = parseRecipes(jsonText);
      expect(recipes.length, 1);
      expect(recipes.first.name, 'Dal Tadka');
      expect(recipes.first.totalMinutes, 35);
      expect(recipes.first.ingredients.length, 2);
      expect(recipes.first.steps.length, 2);
    });
  });
}
