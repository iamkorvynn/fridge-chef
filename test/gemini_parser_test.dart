import 'package:flutter_test/flutter_test.dart';
import 'package:fridgechef/services/gemini_service.dart';

void main() {
  group('GeminiService.parseIngredientText', () {
    test('parses a bare JSON array', () {
      final result = GeminiService.parseIngredientText(
        '["tomato", "onion", "paneer"]',
      );
      expect(result, ['tomato', 'onion', 'paneer']);
    });

    test('parses a fenced json block', () {
      final result = GeminiService.parseIngredientText(
        '```json\n["tomato", "milk", "egg"]\n```',
      );
      expect(result, ['tomato', 'milk', 'egg']);
    });

    test('parses an object with an ingredients key', () {
      final result = GeminiService.parseIngredientText(
        '{"ingredients": ["carrot", "peas"]}',
      );
      expect(result, ['carrot', 'peas']);
    });

    test('normalises case and whitespace, drops duplicates and blanks', () {
      final result = GeminiService.parseIngredientText(
        '["  Tomato ", "ONION", "tomato", ""]',
      );
      expect(result, ['tomato', 'onion']);
    });

    test('parses an empty array', () {
      expect(GeminiService.parseIngredientText('[]'), isEmpty);
    });

    test('throws GeminiException on non-JSON text', () {
      expect(
        () => GeminiService.parseIngredientText('no ingredients here'),
        throwsA(isA<GeminiException>()),
      );
    });
  });

  group('GeminiService.parseIngredientsFromResponse', () {
    test('extracts the ingredient list from a sample API response', () {
      const sampleResponse = '''
{
  "candidates": [
    {
      "content": {
        "parts": [
          {"text": "```json\\n[\\"tomato\\", \\"onion\\", \\"paneer\\", \\"milk\\"]\\n```"}
        ],
        "role": "model"
      },
      "finishReason": "STOP"
    }
  ],
  "usageMetadata": {"promptTokenCount": 120}
}
''';
      final result = GeminiService.parseIngredientsFromResponse(sampleResponse);
      expect(result, ['tomato', 'onion', 'paneer', 'milk']);
    });

    test('extracts plain array text without fences', () {
      const sampleResponse = '''
{
  "candidates": [
    {"content": {"parts": [{"text": "[\\"egg\\", \\"bread\\"]"}], "role": "model"}}
  ]
}
''';
      final result = GeminiService.parseIngredientsFromResponse(sampleResponse);
      expect(result, ['egg', 'bread']);
    });

    test('throws when there are no candidates', () {
      expect(
        () => GeminiService.parseIngredientsFromResponse('{"candidates": []}'),
        throwsA(isA<GeminiException>()),
      );
    });

    test('throws when the response has no text part', () {
      expect(
        () => GeminiService.parseIngredientsFromResponse(
          '{"candidates": [{"content": {"parts": []}}]}',
        ),
        throwsA(isA<GeminiException>()),
      );
    });
  });
}
