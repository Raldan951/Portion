/// A single persisted journal entry.
class JournalEntry {
  final int id;

  /// ISO date string (yyyy-MM-dd) — one day's worth of entries share a date.
  final String date;

  final String body;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.body,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int,
      date: map['date'] as String,
      body: map['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
