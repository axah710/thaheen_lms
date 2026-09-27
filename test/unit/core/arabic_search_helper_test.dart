import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/core/utils/arabic_search_helper.dart';

void main() {
  group('ArabicSearchHelper Normalization Tests (Rule 3 Table-Driven)', () {
    test('normalizes Arabic character variants across all supported rules', () {
      // Arrange
      const normalizationCases = <String, ({String input, String expected})>{
        'alef variants to bare alef': (
          input: 'أحمد إبراهيم آمنة ٱمرأة',
          expected: 'احمد ابراهيم امنه امراه',
        ),
        'diacritics (tashkeel)': (
          input: 'مُقَدِّمَةٌ فِي التَّشْرِيحِ',
          expected: 'مقدمه في التشريح',
        ),
        'taa marbuta and alef maqsura': (
          input: 'دكتورة سارة المستشفى',
          expected: 'دكتوره ساره المستشفي',
        ),
        'tatweel (kashida)': (input: 'تــــشريـــح', expected: 'تشريح'),
      };

      // Act & Assert
      for (final entry in normalizationCases.entries) {
        final actual = ArabicSearchHelper.normalize(entry.value.input);
        expect(actual, entry.value.expected, reason: 'Failed for ${entry.key}');
      }
    });
  });

  group('ArabicSearchHelper Substring Matching Tests (AAA Pattern)', () {
    const sampleSource = 'مقدمة في التشريح البشري - د. سارة';

    test('returns true when query is contained in source with diacritics normalized', () {
      // Arrange
      const query = 'تشريح';

      // Act
      final result = ArabicSearchHelper.matches(sampleSource, query);

      // Assert
      expect(result, isTrue);
    });

    test('returns true when query normalizes taa marbuta to haa in source', () {
      // Arrange
      const query = 'ساره';

      // Act
      final result = ArabicSearchHelper.matches(sampleSource, query);

      // Assert
      expect(result, isTrue);
    });

    test('returns true when query has surrounding whitespace', () {
      // Arrange
      const query = '  تشريح  ';

      // Act
      final result = ArabicSearchHelper.matches(sampleSource, query);

      // Assert
      expect(result, isTrue);
    });

    test('returns true when query is empty or whitespace-only', () {
      // Arrange
      const emptyQuery = '';
      const whitespaceQuery = '   ';

      // Act & Assert
      expect(ArabicSearchHelper.matches(sampleSource, emptyQuery), isTrue);
      expect(ArabicSearchHelper.matches(sampleSource, whitespaceQuery), isTrue);
    });

    test('returns false when source does not contain query text', () {
      // Arrange
      const unmatchedQuery = 'فيزياء';

      // Act
      final result = ArabicSearchHelper.matches(sampleSource, unmatchedQuery);

      // Assert
      expect(result, isFalse);
    });

    test('matchesNormalized evaluates against pre-normalized query without re-normalization', () {
      // Arrange
      final normalizedQuery = ArabicSearchHelper.normalize('سارة');

      // Act
      final result = ArabicSearchHelper.matchesNormalized(
        sampleSource,
        normalizedQuery,
      );

      // Assert
      expect(result, isTrue);
    });
  });
}
