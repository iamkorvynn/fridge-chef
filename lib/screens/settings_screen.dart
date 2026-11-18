import 'package:material_ui/material_ui.dart';

import '../services/settings_service.dart';

/// Settings: the user's own Gemini API key for photo detection, plus
/// how the app works. The key is stored only on this device and is
/// never baked into the app or sent anywhere except to Google's
/// Gemini API when the user taps "Detect from photo".
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final TextEditingController _keyController = TextEditingController();

  bool _keySaved = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await _settings.getApiKey();
    if (mounted) {
      setState(() {
        _keySaved = key != null;
        if (key != null) _keyController.text = key;
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final value = _keyController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your Gemini API key first.')),
      );
      return;
    }
    await _settings.setApiKey(value);
    if (mounted) {
      setState(() => _keySaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key saved on this device.')),
      );
    }
  }

  Future<void> _removeKey() async {
    await _settings.clearApiKey();
    if (mounted) {
      setState(() {
        _keySaved = false;
        _keyController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Gemini API key',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Photo detection uses Google Gemini. Get a free key from '
            'Google AI Studio (aistudio.google.com), paste it here, and '
            'FridgeChef will read ingredients from your fridge photos. '
            'The key is stored only on this device. Without a key, photo '
            'detection is unavailable — the manual checklist still works '
            'fully offline and never fakes a result.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyController,
            obscureText: _obscured,
            decoration: InputDecoration(
              labelText: 'Gemini API key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscured ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
                tooltip: _obscured ? 'Show key' : 'Hide key',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saveKey,
                  child: Text(_keySaved ? 'Update key' : 'Save key'),
                ),
              ),
              if (_keySaved) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _removeKey,
                    child: const Text('Remove key'),
                  ),
                ),
              ],
            ],
          ),
          if (_keySaved)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text('Key saved — photo detection is ready.'),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'About FridgeChef',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'FridgeChef matches what is in your fridge against 34 real, '
            'bundled recipes — dal tadka, paneer butter masala, chole, '
            'masala dosa, chicken curry and more. Recipes are ranked by '
            'the percentage of ingredients you already have, and the '
            'missing ones are listed so you know what to buy.\n\n'
            'Your ingredients and favourites are stored only on this '
            'device. No account, no tracking, no data leaves your phone '
            'except the photo you choose to send to Gemini for detection.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          const Text(
            'Version 1.0.0 • Made by Numaan Bin Husain',
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
