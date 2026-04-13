import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/journal_entry.dart';

/// Manages the local journal SQLite database.
///
/// One entry per reflection — multiple entries per day are allowed.
/// The database file lives in the app documents directory; iCloud Drive
/// or Supabase sync can be layered on top of this without changing the schema.
class JournalService {
  Database? _db;

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'journal.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE journal_entries (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            date       TEXT    NOT NULL,
            body       TEXT    NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_journal_date ON journal_entries (date)',
        );
      },
    );
  }

  Future<void> saveEntry(String date, String body) async {
    await _db!.insert('journal_entries', {
      'date': date,
      'body': body.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<JournalEntry>> getEntriesForDate(String date) async {
    final rows = await _db!.query(
      'journal_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }
}
