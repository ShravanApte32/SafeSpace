class JournalEntry {
  final String id;
  String text;
  DateTime at;
  String mood;
  double sentiment;

  JournalEntry({
    required this.id,
    required this.text,
    required this.at,
    required this.mood,
    required this.sentiment,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'at': at.toIso8601String(),
    'mood': mood,
    'sentiment': sentiment,
  };

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
    id: m['id'],
    text: m['text'],
    at: DateTime.parse(m['at']),
    mood: m['mood'] ?? '😌',
    sentiment: (m['sentiment'] ?? 0.0).toDouble(),
  );
}
