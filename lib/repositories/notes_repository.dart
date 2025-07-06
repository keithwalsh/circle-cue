import 'package:drift/drift.dart';
import '../database/app_database.dart';

class NotesRepository {
  final AppDatabase _database;

  NotesRepository(this._database);

  // Get all notes ordered by creation date (newest first)
  Stream<List<Note>> watchAllNotes() {
    return (_database.select(_database.notes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }

  // Get all notes as a future (for one-time fetch)
  Future<List<Note>> getAllNotes() {
    return (_database.select(_database.notes)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // Add a new note
  Future<int> addNote(String content) {
    return _database.into(_database.notes).insert(
      NotesCompanion(
        content: Value(content),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update an existing note
  Future<bool> updateNote(int id, String content) async {
    final result = await (_database.update(_database.notes)
          ..where((t) => t.id.equals(id)))
        .write(NotesCompanion(
          content: Value(content),
          updatedAt: Value(DateTime.now()),
        ));
    return result > 0;
  }

  // Delete a note by ID
  Future<int> deleteNote(int id) {
    return (_database.delete(_database.notes)..where((t) => t.id.equals(id)))
        .go();
  }

  // Delete all notes
  Future<int> deleteAllNotes() {
    return _database.delete(_database.notes).go();
  }

  // Get note by ID
  Future<Note?> getNoteById(int id) {
    return (_database.select(_database.notes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // Close the database connection
  Future<void> close() {
    return _database.close();
  }
} 