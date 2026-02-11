class ContentFilter {
  // Whitelist: Words explicitly allowed even if they hit other rules
  static const List<String> _whitelist = ['cigarette', 'ciggirate', 'sutta', 'smoke'];

  // A comprehensive list of forbidden keywords (Sexual, Abusive, Illegal, Random)
  static final List<String> _badWords = [
    // Sexual / Nudity (Expanded)
    'sex', 'naked', 'nudity', 'nude', 'porn', 'xxx', 'dick', 'pussy', 'boobs', 'vagina',
    'choot', 'lund', 'gaand', 'randi', 'bhosda', 'saali', 'kamini', 'sexo', 'rape', 
    'molest', 'condom', 'slut', 'whore', 'clitoris', 'penis', 'erection', 'orgasm',
    
    // Abusive / Slurs (Expanded)
    'fuck', 'shit', 'asshole', 'bitch', 'bastard', 'motherfucker', 'cunt',
    'behenchod', 'madarchod', 'bhenchod', 'mc', 'bc', 'chutiya', 'harami',
    'lowda', 'lauda', 'gandu', 'kaminey', 'kutta', 'haramkhor', 'bakchod', 
    'faggot', 'retard', 'nigga', 'nigger', 'idiot', 'stupid',
    
    // Violent / Dangerous / Weapons
    'kill', 'murder', 'suicide', 'bomb', 'terrorist', 'attack', 'weapon', 'gun', 
    'knife', 'shoot', 'grenade', 'explosive', 'rifles', 'pistol', 'assassin',
    
    // Illegal Drugs / Substances (Cigarettes are whitelisted above)
    'drug', 'cocaine', 'heroin', 'meth', 'weed', 'ganja', 'charas', 'opium', 
    'ecstasy', 'lsd', 'mdma', 'hashish', 'marijuana', 'junkie',
    
    // Scams / Illegal Activities
    'hack', 'scam', 'fraud', 'steal', 'rob', 'darkweb', 'tor', 'bitcoin', 'crypto', 
    'payment', 'advance', 'bank', 'otp', 'carding', 'phishing', 'spam', 'betting', 
    'gambling', 'casino', 'money laundering', 'ransom',
  ];

  static final _badWordsPattern = RegExp(
    '\\b(${_badWords.map(RegExp.escape).join('|')})\\b',
    caseSensitive: false,
  );

  /// Checks if the provided text contains any forbidden words or gibberish.
  /// Returns `true` if safe, `false` if it contains forbidden content.
  static bool isSafe(String text) {
    if (text.isEmpty) return true;
    
    final lowerText = text.toLowerCase();
    
    // 1. Fast path: check full text for any bad word first
    // We only do deeper word-by-word analysis if something hits or for gibberish
    if (_badWordsPattern.hasMatch(lowerText)) {
      // Check if the match is whitelisted
      final words = lowerText.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isEmpty) continue;
        if (_whitelist.contains(word)) continue;
        if (_badWordsPattern.hasMatch(word)) return false;
      }
    }

    // 2. Gibberish Detection (Heuristic) - require word-by-word
    final words = lowerText.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.isEmpty) continue;
      if (_isGibberish(word)) return false;
    }
    
    return true;
  }

  /// Heuristic to check if a word is random gibberish (e.g., "asdfghjkl")
  static bool _isGibberish(String word) {
    if (word.length < 5) return false; // Short words are rarely detected accurately

    // Check for repetitive characters (aaaaa, 121212)
    if (RegExp(r'(.)\1{3,}').hasMatch(word)) return true;

    // Check for consonant-only clusters (very indicative of keyboard smashing)
    // Avoid marking common abbreviations or local names (if any)
    if (word.length >= 6 && !RegExp(r'[aeiouy]', caseSensitive: false).hasMatch(word)) {
      return true;
    }

    // Check for high consonant density in longer words
    final vowels = RegExp(r'[aeiouy]', caseSensitive: false).allMatches(word).length;
    if (word.length > 8 && vowels < 2) return true;

    return false;
  }

  /// Filters out bad words from the text, replacing them with asterisks.
  static String filter(String text) {
    String filtered = text;
    for (final word in _badWords) {
      if (_whitelist.contains(word.toLowerCase())) continue;
      final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
      filtered = filtered.replaceAllMapped(pattern, (match) => '*' * match.group(0)!.length);
    }
    return filtered;
  }
}
