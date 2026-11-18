import 'dart:convert';

/// One ingredient inside a recipe: a normalised name plus the
/// human-readable quantity (e.g. "1 cup", "2 tbsp, chopped").
class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.quantity});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: (json['name'] as String).trim().toLowerCase(),
      quantity: (json['quantity'] as String?) ?? '',
    );
  }

  final String name;
  final String quantity;

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};
}

/// A single bundled recipe from assets/recipes.json.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.veg,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String,
      veg: json['veg'] as bool,
      prepMinutes: (json['prepMinutes'] as num).toInt(),
      cookMinutes: (json['cookMinutes'] as num).toInt(),
      difficulty: json['difficulty'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map(
            (e) => RecipeIngredient.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  final String id;
  final String name;
  final String cuisine;
  final bool veg;
  final int prepMinutes;
  final int cookMinutes;
  final String difficulty;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  int get totalMinutes => prepMinutes + cookMinutes;

  /// Ingredient names that count towards matching. Pantry staples that
  /// almost every Indian kitchen has (salt, sugar) are assumed present
  /// so they do not drag every match score down.
  List<RecipeIngredient> get matchableIngredients =>
      ingredients.where((i) => !Recipe.staples.contains(i.name)).toList();

  static const Set<String> staples = {'salt', 'sugar'};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cuisine': cuisine,
    'veg': veg,
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'difficulty': difficulty,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'steps': steps,
  };
}

/// Parse the bundled recipes JSON text into a list of [Recipe]s.
List<Recipe> parseRecipes(String jsonText) {
  final decoded = jsonDecode(jsonText) as List<dynamic>;
  return decoded
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList();
}
