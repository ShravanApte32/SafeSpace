class JournalEntry {
  final String id;
  String text;
  DateTime at;
  String mood;
  double sentiment;
  bool isPrivate;

  JournalEntry({
    required this.id,
    required this.text,
    required this.at,
    required this.mood,
    required this.sentiment,
    required this.isPrivate,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': text,
      'mood': mood,
      'sentiment_score': sentiment, // This should be double
      'created_at': at.toUtc().toIso8601String(),
      'is_private': isPrivate,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> m) {
    // Safe ID parsing
    String parseId(dynamic idValue) {
      if (idValue == null) return DateTime.now().millisecondsSinceEpoch.toString();
      if (idValue is int) return idValue.toString();
      if (idValue is String) return idValue;
      return idValue.toString();
    }

    return JournalEntry(
      id: parseId(m['id']),
      text: m['content']?.toString() ?? '',
      at: m['created_at'] != null
          ? DateTime.parse(m['created_at'].toString()).toLocal()
          : DateTime.now(),
      mood: m['mood']?.toString() ?? '😌',
      sentiment: (m['sentiment_score'] is double)
          ? m['sentiment_score'] as double
          : (m['sentiment_score'] is int)
              ? (m['sentiment_score'] as int).toDouble()
              : double.tryParse(m['sentiment_score']?.toString() ?? '0.0') ?? 0.0,
      isPrivate: m['is_private'] == true || m['is_private'] == 1, // 👈 added
    );
  }
}