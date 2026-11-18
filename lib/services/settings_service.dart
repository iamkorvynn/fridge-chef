import 'package:shared_preferences/shared_preferences.dart';

/// On-device settings: the user's own Gemini API key and onboarding
/// state. The key is stored only in SharedPreferences on this device
/// and is never sent anywhere except to Google's Gemini API when the
/// user taps "Detect from photo".
class SettingsService {
  static const String _keyApiKey = 'gemini_api_key';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keySelectedIngredients = 'selected_ingredients';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyApiKey);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key.trim());
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
  }

  Future<bool> get onboardingDone async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<Set<String>> getSelectedIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySelectedIngredients)?.toSet() ?? {};
  }

  Future<void> setSelectedIngredients(Set<String> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keySelectedIngredients,
      ingredients.toList()..sort(),
    );
  }
}
