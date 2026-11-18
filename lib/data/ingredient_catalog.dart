/// The manual ingredient picker catalogue: common Indian and
/// international ingredients, grouped so the checklist stays scannable.
/// Names are lowercase and match the `name` fields in assets/recipes.json.
class IngredientCatalog {
  static const Map<String, List<String>> groups = {
    'Vegetables': [
      'tomato',
      'onion',
      'potato',
      'cauliflower',
      'spinach',
      'peas',
      'capsicum',
      'carrot',
      'cabbage',
      'brinjal',
      'okra',
      'beans',
      'beetroot',
      'cucumber',
      'mushroom',
      'corn',
      'broccoli',
      'lemon',
      'ginger',
      'garlic',
      'green chilli',
      'coriander leaves',
      'curry leaves',
      'fenugreek leaves',
    ],
    'Dairy & Eggs': [
      'milk',
      'curd',
      'paneer',
      'butter',
      'ghee',
      'cheese',
      'cream',
      'egg',
    ],
    'Grains & Breads': [
      'rice',
      'basmati rice',
      'wheat flour',
      'maida',
      'bread',
      'pasta',
      'noodles',
      'oats',
      'poha',
      'semolina',
      'besan',
      'dosa batter',
    ],
    'Spices & Seasonings': [
      'cumin seeds',
      'turmeric',
      'red chilli powder',
      'garam masala',
      'coriander powder',
      'mustard seeds',
      'black pepper',
      'bay leaf',
      'cardamom',
      'cinnamon',
      'cloves',
      'asafoetida',
      'pav bhaji masala',
      'soy sauce',
      'salt',
      'sugar',
    ],
    'Proteins & Pulses': [
      'chicken',
      'fish',
      'prawns',
      'chickpeas',
      'kidney beans',
      'moong dal',
      'toor dal',
      'masoor dal',
      'urad dal',
      'soya chunks',
      'tofu',
      'peanuts',
      'cashew nuts',
      'grated coconut',
    ],
  };

  /// Every ingredient in the catalogue, flattened.
  static List<String> get all =>
      groups.values.expand((items) => items).toList();

  /// Normalise a free-text ingredient the user typed so it matches the
  /// catalogue / recipe naming (lowercase, trimmed, single spaces).
  static String normalize(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
