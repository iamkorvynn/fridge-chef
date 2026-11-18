import '../models/recipe.dart';

/// Veg / non-veg filter for the recipe list.
enum VegFilter { all, veg, nonVeg }

/// How well one recipe matches the ingredients the user has.
class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.matchedCount,
    required this.totalCount,
    required this.missing,
  });

  final Recipe recipe;
  final int matchedCount;
  final int totalCount;
  final List<RecipeIngredient> missing;

  /// Percentage of the recipe's matchable ingredients the user has.
  int get percent =>
      totalCount == 0 ? 100 : ((matchedCount / totalCount) * 100).round();

  bool get canCookNow => missing.isEmpty;
}

/// Score one recipe against the ingredients the user has.
RecipeMatch matchRecipe(Recipe recipe, Set<String> have) {
  final needed = recipe.matchableIngredients;
  final missing = needed.where((i) => !have.contains(i.name)).toList();
  return RecipeMatch(
    recipe: recipe,
    matchedCount: needed.length - missing.length,
    totalCount: needed.length,
    missing: missing,
  );
}

/// Rank all recipes by match percentage (best first), then by fewest
/// missing ingredients, then by shortest total time.
List<RecipeMatch> rankRecipes(List<Recipe> recipes, Set<String> have) {
  final matches = recipes.map((r) => matchRecipe(r, have)).toList();
  matches.sort((a, b) {
    final byPercent = b.percent.compareTo(a.percent);
    if (byPercent != 0) return byPercent;
    final byMissing = a.missing.length.compareTo(b.missing.length);
    if (byMissing != 0) return byMissing;
    return a.recipe.totalMinutes.compareTo(b.recipe.totalMinutes);
  });
  return matches;
}

/// Apply the veg filter and the max-total-time filter to a ranked list.
List<RecipeMatch> filterMatches(
  List<RecipeMatch> matches, {
  VegFilter vegFilter = VegFilter.all,
  int? maxTotalMinutes,
}) {
  return matches.where((m) {
    if (vegFilter == VegFilter.veg && !m.recipe.veg) return false;
    if (vegFilter == VegFilter.nonVeg && m.recipe.veg) return false;
    if (maxTotalMinutes != null &&
        m.recipe.totalMinutes > maxTotalMinutes) {
      return false;
    }
    return true;
  }).toList();
}

/// Case-insensitive name search over the recipe list.
List<Recipe> searchRecipes(List<Recipe> recipes, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List<Recipe>.of(recipes);
  return recipes.where((r) {
    return r.name.toLowerCase().contains(q) ||
        r.cuisine.toLowerCase().contains(q);
  }).toList();
}
