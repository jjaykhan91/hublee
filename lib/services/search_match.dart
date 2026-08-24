/// Exact-word vs substring ranking for English search queries.
library;

/// True when [needle] appears as a whole word in [haystack].
///
/// Case-insensitive. "mercy" matches "Show mercy" but not "merciful".
bool englishExactWordMatch(String haystack, String needle) {
  final trimmed = needle.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(
    '\\b${RegExp.escape(trimmed)}\\b',
    caseSensitive: false,
  ).hasMatch(haystack);
}
