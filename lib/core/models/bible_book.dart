enum BibleTestament { ot, nt }

enum BibleGroup {
  law,
  history,
  poetry,
  majorProphets,
  minorProphets,
  gospelsActs,
  epistles,
  revelation;

  String get displayName => switch (this) {
        BibleGroup.law => 'Law',
        BibleGroup.history => 'History',
        BibleGroup.poetry => 'Poetry',
        BibleGroup.majorProphets => 'Major Prophets',
        BibleGroup.minorProphets => 'Minor Prophets',
        BibleGroup.gospelsActs => 'Gospels & Acts',
        BibleGroup.epistles => 'Epistles',
        BibleGroup.revelation => 'Revelation',
      };

  BibleTestament get testament => switch (this) {
        BibleGroup.law ||
        BibleGroup.history ||
        BibleGroup.poetry ||
        BibleGroup.majorProphets ||
        BibleGroup.minorProphets =>
          BibleTestament.ot,
        BibleGroup.gospelsActs ||
        BibleGroup.epistles ||
        BibleGroup.revelation =>
          BibleTestament.nt,
      };
}

class BibleBook {
  const BibleBook(this.name, this.chapters, this.group);

  final String name;
  final int chapters;
  final BibleGroup group;

  BibleTestament get testament => group.testament;
}

// All 66 canonical books. Chapter counts are fixed canon — no DB query needed.
// Book names match BibleDatabaseService._bookNameMap input keys so the service
// can map them to DB names (e.g. "1 Samuel" → "I Samuel") transparently.
const List<BibleBook> kBibleBooks = [
  // ── Law ─────────────────────────────────────────────────────────────────
  BibleBook('Genesis',      50, BibleGroup.law),
  BibleBook('Exodus',       40, BibleGroup.law),
  BibleBook('Leviticus',    27, BibleGroup.law),
  BibleBook('Numbers',      36, BibleGroup.law),
  BibleBook('Deuteronomy',  34, BibleGroup.law),

  // ── History (OT) ────────────────────────────────────────────────────────
  BibleBook('Joshua',        24, BibleGroup.history),
  BibleBook('Judges',        21, BibleGroup.history),
  BibleBook('Ruth',           4, BibleGroup.history),
  BibleBook('1 Samuel',      31, BibleGroup.history),
  BibleBook('2 Samuel',      24, BibleGroup.history),
  BibleBook('1 Kings',       22, BibleGroup.history),
  BibleBook('2 Kings',       25, BibleGroup.history),
  BibleBook('1 Chronicles',  29, BibleGroup.history),
  BibleBook('2 Chronicles',  36, BibleGroup.history),
  BibleBook('Ezra',          10, BibleGroup.history),
  BibleBook('Nehemiah',      13, BibleGroup.history),
  BibleBook('Esther',        10, BibleGroup.history),

  // ── Poetry ──────────────────────────────────────────────────────────────
  BibleBook('Job',              42, BibleGroup.poetry),
  BibleBook('Psalms',          150, BibleGroup.poetry),
  BibleBook('Proverbs',         31, BibleGroup.poetry),
  BibleBook('Ecclesiastes',     12, BibleGroup.poetry),
  BibleBook('Song of Solomon',   8, BibleGroup.poetry),

  // ── Major Prophets ──────────────────────────────────────────────────────
  BibleBook('Isaiah',      66, BibleGroup.majorProphets),
  BibleBook('Jeremiah',    52, BibleGroup.majorProphets),
  BibleBook('Lamentations', 5, BibleGroup.majorProphets),
  BibleBook('Ezekiel',     48, BibleGroup.majorProphets),
  BibleBook('Daniel',      12, BibleGroup.majorProphets),

  // ── Minor Prophets ──────────────────────────────────────────────────────
  BibleBook('Hosea',      14, BibleGroup.minorProphets),
  BibleBook('Joel',        3, BibleGroup.minorProphets),
  BibleBook('Amos',        9, BibleGroup.minorProphets),
  BibleBook('Obadiah',     1, BibleGroup.minorProphets),
  BibleBook('Jonah',       4, BibleGroup.minorProphets),
  BibleBook('Micah',       7, BibleGroup.minorProphets),
  BibleBook('Nahum',       3, BibleGroup.minorProphets),
  BibleBook('Habakkuk',    3, BibleGroup.minorProphets),
  BibleBook('Zephaniah',   3, BibleGroup.minorProphets),
  BibleBook('Haggai',      2, BibleGroup.minorProphets),
  BibleBook('Zechariah',  14, BibleGroup.minorProphets),
  BibleBook('Malachi',     4, BibleGroup.minorProphets),

  // ── Gospels & Acts ──────────────────────────────────────────────────────
  BibleBook('Matthew', 28, BibleGroup.gospelsActs),
  BibleBook('Mark',    16, BibleGroup.gospelsActs),
  BibleBook('Luke',    24, BibleGroup.gospelsActs),
  BibleBook('John',    21, BibleGroup.gospelsActs),
  BibleBook('Acts',    28, BibleGroup.gospelsActs),

  // ── Epistles ────────────────────────────────────────────────────────────
  BibleBook('Romans',           16, BibleGroup.epistles),
  BibleBook('1 Corinthians',    16, BibleGroup.epistles),
  BibleBook('2 Corinthians',    13, BibleGroup.epistles),
  BibleBook('Galatians',         6, BibleGroup.epistles),
  BibleBook('Ephesians',         6, BibleGroup.epistles),
  BibleBook('Philippians',       4, BibleGroup.epistles),
  BibleBook('Colossians',        4, BibleGroup.epistles),
  BibleBook('1 Thessalonians',   5, BibleGroup.epistles),
  BibleBook('2 Thessalonians',   3, BibleGroup.epistles),
  BibleBook('1 Timothy',         6, BibleGroup.epistles),
  BibleBook('2 Timothy',         4, BibleGroup.epistles),
  BibleBook('Titus',             3, BibleGroup.epistles),
  BibleBook('Philemon',          1, BibleGroup.epistles),
  BibleBook('Hebrews',          13, BibleGroup.epistles),
  BibleBook('James',             5, BibleGroup.epistles),
  BibleBook('1 Peter',           5, BibleGroup.epistles),
  BibleBook('2 Peter',           3, BibleGroup.epistles),
  BibleBook('1 John',            5, BibleGroup.epistles),
  BibleBook('2 John',            1, BibleGroup.epistles),
  BibleBook('3 John',            1, BibleGroup.epistles),
  BibleBook('Jude',              1, BibleGroup.epistles),

  // ── Revelation ──────────────────────────────────────────────────────────
  BibleBook('Revelation', 22, BibleGroup.revelation),
];
