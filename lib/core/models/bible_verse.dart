/// A single verse of Scripture returned from a local Bible database.
class BibleVerse {
  final int chapter;
  final int verse;
  final String text;

  const BibleVerse({
    required this.chapter,
    required this.verse,
    required this.text,
  });
}
