/// Pure Dart utility for Arabic text normalization and fuzzy substring matching.
///
/// Strips Arabic diacritics (tashkeel), typographical tatweel (kashida),
/// and unifies letter variants (alef, taa marbuta, alef maqsura) so user queries
/// match syllabus titles and instructor names regardless of keyboard orthography.
class ArabicSearchHelper {
  ArabicSearchHelper._();

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
  static final RegExp _tatweelRegex = RegExp(r'\u0640');
  static final RegExp _alefRegex = RegExp(r'[أإآٱ]');

  /// Normalizes Arabic text by removing diacritics, unifying letter variants,
  /// collapsing tatweel, and trimming whitespace to ensure search recall parity.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    return text
        .replaceAll(_tashkeelRegex, '')
        .replaceAll(_tatweelRegex, '')
        .replaceAll(_alefRegex, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  /// Checks if [source] matches an already normalized query [normalizedQuery].
  ///
  /// Avoids re-normalizing the same query repeatedly when filtering lists.
  static bool matchesNormalized(String? source, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    if (source == null || source.isEmpty) return false;

    final normalizedSource = normalize(source);
    return normalizedSource.contains(normalizedQuery);
  }

  /// Checks if [source] contains [query] after applying Arabic normalization to both.
  ///
  /// Returns `true` if [query] is empty or whitespace-only.
  static bool matches(String? source, String? query) {
    if (query == null || query.trim().isEmpty) return true;
    if (source == null || source.isEmpty) return false;

    final normalizedQuery = normalize(query);
    return matchesNormalized(source, normalizedQuery);
  }
}
