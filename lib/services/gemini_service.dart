import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/ingredient_catalog.dart';

/// Error thrown when the Gemini call fails or returns something we
/// cannot understand. The message is safe to show to the user.
class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;

  @override
  String toString() => 'GeminiException: $message';
}

/// Calls the Gemini vision API to list ingredients visible in a photo.
///
/// The API key is supplied by the user in Settings and is never stored
/// anywhere except on the device. No detection is ever faked: if there
/// is no key, or the call fails, the caller gets an exception and must
/// tell the user plainly.
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Detect ingredients in [imageBytes] (JPEG/PNG). Returns normalised
  /// ingredient names, e.g. ["tomato", "onion", "paneer"].
  Future<List<String>> detectIngredients({
    required String apiKey,
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'List every food ingredient you can see in this photo of '
                  'fridge contents. Reply with ONLY a JSON array of '
                  'lowercase ingredient names, for example '
                  '["tomato", "onion", "paneer", "milk"]. '
                  'Use simple generic names (tomato, not cherry tomato). '
                  'If no food is visible, reply with an empty array [].',
            },
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.2},
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw GeminiException('Could not reach Gemini: $e');
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw GeminiException(
        'Gemini rejected the request. Check your API key in Settings.',
      );
    }
    if (response.statusCode == 429) {
      throw GeminiException(
        'Gemini rate limit reached. Please wait a bit and try again.',
      );
    }
    if (response.statusCode != 200) {
      throw GeminiException(
        'Gemini returned status ${response.statusCode}. Try again later.',
      );
    }

    return parseIngredientsFromResponse(response.body);
  }

  /// Parse the ingredient list out of a raw Gemini generateContent
  /// response body. Tolerant of markdown fences around the JSON.
  static List<String> parseIngredientsFromResponse(String responseBody) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('Gemini returned no ingredients.');
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw GeminiException('Gemini returned no ingredients.');
    }
    final text = (parts.first as Map<String, dynamic>)['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw GeminiException('Gemini returned no ingredients.');
    }
    return parseIngredientText(text);
  }

  /// Parse a model text reply into normalised ingredient names.
  /// Accepts a bare JSON array, an object with an "ingredients" key,
  /// or the same wrapped in ```json fences. Unknown items are kept
  /// as-is (normalised) so the user can confirm them.
  static List<String> parseIngredientText(String text) {
    var cleaned = text.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final fenceMatch = fence.firstMatch(cleaned);
    if (fenceMatch != null) {
      cleaned = fenceMatch.group(1)!.trim();
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException {
      throw GeminiException('Gemini returned an unexpected format.');
    }
    final List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final inner = decoded['ingredients'];
      if (inner is List) {
        rawList = inner;
      } else {
        throw GeminiException('Gemini returned an unexpected format.');
      }
    } else {
      throw GeminiException('Gemini returned an unexpected format.');
    }
    final seen = <String>{};
    final result = <String>[];
    for (final item in rawList) {
      final name = IngredientCatalog.normalize(item.toString());
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);
      result.add(name);
    }
    return result;
  }
}
