/// The journal document for a single day — one continuous page of text.
///
/// Replaces the list-of-entries model with a single editable document per day,
/// styled like an open notebook page with free-form text and clipped passages.
class JournalDocument {
  final String date;
  final String body;
  final DateTime updatedAt;

  const JournalDocument({
    required this.date,
    required this.body,
    required this.updatedAt,
  });

  factory JournalDocument.fromMap(Map<String, dynamic> map) {
    return JournalDocument(
      date: map['date'] as String,
      body: map['body'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
