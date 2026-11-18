import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ingredient_catalog.dart';
import '../services/gemini_service.dart';
import '../services/settings_service.dart';
import '../state/app_state.dart';

/// "My Fridge": photo detection (Gemini, needs the user's key) plus the
/// grouped manual checklist and a free-text add field.
class FridgeScreen extends StatefulWidget {
  const FridgeScreen({
    super.key,
    required this.state,
    required this.onFindRecipes,
  });

  final AppState state;
  final VoidCallback onFindRecipes;

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _customController = TextEditingController();
  final SettingsService _settings = SettingsService();
  final GeminiService _gemini = GeminiService();

  bool _detecting = false;
  String? _detectMessage;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _settings.getApiKey();
    if (mounted) setState(() => _apiKey = key);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _detectFromPhoto(ImageSource source) async {
    if (_apiKey == null) {
      setState(() {
        _detectMessage =
            'Photo detection needs a Gemini API key. Add yours in Settings — '
            'it stays on your device. Or use the checklist below, which '
            'works fully offline.';
      });
      return;
    }
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _detecting = true;
      _detectMessage = null;
    });
    try {
      final bytes = await File(picked.path).readAsBytes();
      final mime = picked.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final detected = await _gemini.detectIngredients(
        apiKey: _apiKey!,
        imageBytes: bytes,
        mimeType: mime,
      );
      if (!mounted) return;
      if (detected.isEmpty) {
        setState(() {
          _detectMessage =
              'No food ingredients were visible in that photo. '
              'Try a clearer shot, or tick ingredients below.';
        });
        return;
      }
      final before = widget.state.selectedIngredients.length;
      widget.state.addIngredients(detected);
      final added = widget.state.selectedIngredients.length - before;
      setState(() {
        _detectMessage = added > 0
            ? 'Detected ${detected.length} ingredient(s), '
                  '$added new: ${detected.join(', ')}'
            : 'Detected: ${detected.join(', ')} — all already in your list.';
      });
    } on GeminiException catch (e) {
      if (mounted) setState(() => _detectMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _detectMessage = 'Photo detection failed: $e');
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  String _label(String name) {
    return name
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fridge'),
        actions: [
          if (state.selectedIngredients.isNotEmpty)
            TextButton(
              onPressed: state.clearIngredients,
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final selected = state.selectedIngredients;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photograph your fridge',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _apiKey == null
                            ? 'AI detection needs your Gemini key (Settings). '
                                  'Without it, the checklist below still '
                                  'works fully offline.'
                            : 'Gemini key saved. Snap a photo and we\'ll '
                                  'read the ingredients for you.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _detecting
                                  ? null
                                  : () =>
                                        _detectFromPhoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take photo'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _detecting
                                  ? null
                                  : () =>
                                        _detectFromPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('From gallery'),
                            ),
                          ),
                        ],
                      ),
                      if (_detecting)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (_detectMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _detectMessage!,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (selected.isNotEmpty) ...[
                Text(
                  'You have (${selected.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selected.map((name) {
                    return Chip(
                      label: Text(_label(name)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => state.removeIngredient(name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: widget.onFindRecipes,
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(
                    'Find recipes with ${selected.length} ingredient(s)',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Or tick what you have',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      decoration: const InputDecoration(
                        labelText: 'Add an ingredient',
                        hintText: 'e.g. sweet potato',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCustom(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addCustom,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add ingredient',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...IngredientCatalog.groups.entries.map((group) {
                return ExpansionTile(
                  title: Text(group.key),
                  subtitle: Text(
                    '${group.value.where(selected.contains).length}'
                    ' of ${group.value.length} selected',
                  ),
                  children: group.value.map((name) {
                    final isSelected = selected.contains(name);
                    return CheckboxListTile(
                      title: Text(_label(name)),
                      value: isSelected,
                      onChanged: (_) => state.toggleIngredient(name),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),
              if (selected.isEmpty)
                const Text(
                  'Nothing selected yet — tick a few ingredients above, '
                  'or photograph your fridge, and FridgeChef will rank '
                  'recipes by what you can cook right now.',
                  style: TextStyle(color: Colors.black54),
                ),
            ],
          );
        },
      ),
    );
  }

  void _addCustom() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    widget.state.addIngredients([value]);
    _customController.clear();
  }
}
