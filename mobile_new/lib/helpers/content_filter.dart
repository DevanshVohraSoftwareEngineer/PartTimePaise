class ContentFilter {
  // A comprehensive list of forbidden keywords (Common English and Hindi)
  // In a production app, this would ideally be handled by a more robust NLP service
  // or a periodically updated list from a remote config.
  static final List<String> _badWords = [
    // Sexual / Nudity
    'sex', 'naked', 'nudity', 'nude', 'porn', 'xxx', 'dick', 'pussy', 'boobs', 'vagina',
    'choot', 'lund', 'gaand', 'randi', 'bhosda', 'saali', 'kamini', 'sexo',
    
    // Abusive / Slurs
    'fuck', 'shit', 'asshole', 'bitch', 'bastard', 'motherfucker', 'cunt',
    'behenchod', 'madarchod', 'bhenchod', 'mc', 'bc', 'chutiya', 'harami',
    'lowda', 'lauda', 'gandu', 'kaminey', 'kutta',
    
    // Violent / Dangerous
    'kill', 'murder', 'suicide', 'bomb', 'terrorist', 'attack', 'weapon', 'gun', 'knife', 'shoot',
    
    // Illegal Drugs / Substances
    'drug', 'cocaine', 'heroin', 'meth', 'weed', 'ganja', 'charas', 'opium', 'ecstasy', 'lsd', 'mdma',
    
    // Scams / Illegal Activities
    'hack', 'scam', 'fraud', 'steal', 'rob', 'darkweb', 'tor', 'bitcoin', 'crypto', 'payment', 'advance',
    'bank', 'otp', 'carding', 'phishing', 'spam', 'betting', 'gambling', 'casino', 'casino',
  ];

  /// Checks if the provided text contains any forbidden words.
  /// Returns `true` if safe, `false` if it contains forbidden content.
  static bool isSafe(String text) {
    if (text.isEmpty) return true;
    
    final lowerText = text.toLowerCase();
    
    for (final word in _badWords) {
      // Use regex to match whole words or specific patterns to avoid false positives 
      // like "assessment" matching "ass"
      final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
      if (pattern.hasMatch(lowerText)) {
        return false;
      }
    }
    
    return true;
  }

  /// Filters out bad words from the text, replacing them with asterisks.
  static String filter(String text) {
    String filtered = text;
    for (final word in _badWords) {
      final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
      filtered = filtered.replaceAllMapped(pattern, (match) => '*' * match.group(0)!.length);
    }
    return filtered;
  }
}
