import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bible_translation.dart';
import '../models/bible_verse.dart';

/// Provides access to bundled Bible translation SQLite databases.
///
/// Each translation's DB is opened lazily on first access and kept open
/// for the lifetime of the service. On first run, the asset is copied to
/// the app's documents directory (SQLite requires a writable path).
class BibleDatabaseService {
  final Map<BibleTranslation, Database> _dbs = {};

  static const Map<BibleTranslation, String> _assetPaths = {
    BibleTranslation.kjv: 'assets/data/KJV.db',
    BibleTranslation.bsb: 'assets/data/BSB.db',
  };

  /// DB table prefix per translation — e.g. 'KJV' → KJV_books / KJV_verses.
  static const Map<BibleTranslation, String> _tablePrefix = {
    BibleTranslation.kjv: 'KJV',
    BibleTranslation.bsb: 'BSB',
  };

  /// Book name mapping: M'Cheyne JSON names → database names.
  ///
  /// Both KJV and BSB databases use the same Roman-numeral convention
  /// ("I Samuel", "II Kings") and "Psalms" / "Revelation of John".
  static const Map<String, String> _bookNameMap = {
    '1 Samuel': 'I Samuel',
    '2 Samuel': 'II Samuel',
    '1 Kings': 'I Kings',
    '2 Kings': 'II Kings',
    '1 Chronicles': 'I Chronicles',
    '2 Chronicles': 'II Chronicles',
    '1 Corinthians': 'I Corinthians',
    '2 Corinthians': 'II Corinthians',
    '1 Thessalonians': 'I Thessalonians',
    '2 Thessalonians': 'II Thessalonians',
    '1 Timothy': 'I Timothy',
    '2 Timothy': 'II Timothy',
    '1 Peter': 'I Peter',
    '2 Peter': 'II Peter',
    '1 John': 'I John',
    '2 John': 'II John',
    '3 John': 'III John',
    'Psalm': 'Psalms',
    'Revelation': 'Revelation of John',
  };

  /// Returns all verses for [book] chapter [chapter] through [chapterEnd].
  /// If [chapterEnd] is null, returns a single chapter.
  Future<List<BibleVerse>> getChapter(
    BibleTranslation translation,
    String book,
    int chapter, {
    int? chapterEnd,
  }) async {
    final db = await _openDb(translation);
    final prefix = _tablePrefix[translation]!;
    final dbBook = _bookNameMap[book] ?? book;
    final end = chapterEnd ?? chapter;

    final rows = await db.rawQuery(
      'SELECT v.chapter, v.verse, v.text '
      'FROM ${prefix}_verses v '
      'JOIN ${prefix}_books b ON v.book_id = b.id '
      'WHERE b.name = ? AND v.chapter BETWEEN ? AND ? '
      'ORDER BY v.chapter, v.verse',
      [dbBook, chapter, end],
    );

    return rows
        .map(
          (r) => BibleVerse(
            chapter: r['chapter'] as int,
            verse: r['verse'] as int,
            text: r['text'] as String,
          ),
        )
        .toList();
  }

  Future<Database> _openDb(BibleTranslation translation) async {
    if (_dbs.containsKey(translation)) return _dbs[translation]!;

    final assetPath = _assetPaths[translation]!;
    final fileName = assetPath.split('/').last;
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, fileName);

    if (!File(dbPath).existsSync()) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(dbPath, readOnly: true);
    _dbs[translation] = db;
    return db;
  }
}
