/// Room chat content moderation: masks mild terms, blocks threats and severe language.
class ChatModerationResult {
  final String text;
  final bool wasBlocked;
  final bool hadFilteredWords;
  final String? blockReason;
  final List<String> matchedTerms;

  const ChatModerationResult({
    required this.text,
    this.wasBlocked = false,
    this.hadFilteredWords = false,
    this.blockReason,
    this.matchedTerms = const [],
  });
}

class ChatModeration {
  ChatModeration._();

  static final RegExp _wordBoundary = RegExp(r'(^|[^a-zA-Z0-9])');

  /// Masked with asterisks but still delivered.
  static const List<String> maskWords = [
    'abuse',
    'asshole',
    'bastard',
    'bitch',
    'crap',
    'damn',
    'dick',
    'fuck',
    'hate',
    'hell',
    'idiot',
    'moron',
    'nude',
    'porn',
    'shit',
    'stupid',
    'whore',
  ];

  /// Message is rejected and not sent.
  static const List<String> blockWords = [
    'kys',
    'nazi',
    'rape',
    'suicide',
  ];

  /// Threat / harm patterns — blocked entirely.
  static final List<RegExp> blockPatterns = [
    RegExp(r"\b(i'?ll|im|i am)\s+kill\b", caseSensitive: false),
    RegExp(r'\b(gonna|going to)\s+kill\b', caseSensitive: false),
    RegExp(r'\bkill\s+(you|u|yourself)\b', caseSensitive: false),
    RegExp(r'\b(die|hurt)\s+(you|u)\b', caseSensitive: false),
    RegExp(r'\bbomb\s+(the|this|you)\b', caseSensitive: false),
    RegExp(r'\bshoot\s+(you|u)\b', caseSensitive: false),
  ];

  static ChatModerationResult moderate(
    String input, {
    required bool enabled,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ChatModerationResult(text: '');
    }
    if (!enabled) {
      return ChatModerationResult(text: trimmed);
    }

    final lower = trimmed.toLowerCase();

    for (final pattern in blockPatterns) {
      if (pattern.hasMatch(lower)) {
        return ChatModerationResult(
          text: trimmed,
          wasBlocked: true,
          blockReason:
              'Threatening or harmful language is not allowed in this room.',
          matchedTerms: const ['threat'],
        );
      }
    }

    for (final word in blockWords) {
      if (_containsWord(lower, word)) {
        return ChatModerationResult(
          text: trimmed,
          wasBlocked: true,
          blockReason:
              'This message contains language that is not allowed in this room.',
          matchedTerms: [word],
        );
      }
    }

    var output = trimmed;
    final matched = <String>[];
    for (final word in maskWords) {
      if (_containsWord(output.toLowerCase(), word)) {
        matched.add(word);
        output = _maskWord(output, word);
      }
    }

    return ChatModerationResult(
      text: output,
      hadFilteredWords: matched.isNotEmpty,
      matchedTerms: matched,
    );
  }

  static bool _containsWord(String value, String word) {
    final pattern = RegExp(
      '${_wordBoundary.pattern}${RegExp.escape(word)}(?=\$|[^a-zA-Z0-9])',
      caseSensitive: false,
    );
    return pattern.hasMatch(value);
  }

  static String _maskWord(String value, String word) {
    final pattern = RegExp(
      '${_wordBoundary.pattern}${RegExp.escape(word)}(?=\$|[^a-zA-Z0-9])',
      caseSensitive: false,
    );
    return value.replaceAllMapped(pattern, (match) {
      final prefix = match.group(1) ?? '';
      final masked = '*' * word.length;
      return '$prefix$masked';
    });
  }
}
