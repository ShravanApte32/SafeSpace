class MoodLog {
  final String label;
  final String emoji;
  final int colorValue;
  final DateTime at;

  MoodLog({
    required this.label,
    required this.emoji,
    required this.colorValue,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'emoji': emoji,
    'color': colorValue,
    'at': at.toIso8601String(),
  };

  factory MoodLog.fromMap(Map<String, dynamic> m) => MoodLog(
    label: m['label'],
    emoji: m['emoji'],
    colorValue: m['color'],
    at: DateTime.parse(m['at']),
  );
}
