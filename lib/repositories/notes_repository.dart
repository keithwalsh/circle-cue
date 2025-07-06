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

  // Get notes for a specific person ordered by creation date (newest first)
  Stream<List<Note>> watchNotesForPerson(int personId) {
    return (_database.select(_database.notes)
      ..where((t) => t.personId.equals(personId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }

  // Get notes for a specific person as a future (for one-time fetch)
  Future<List<Note>> getNotesForPerson(int personId) {
    return (_database.select(_database.notes)
          ..where((t) => t.personId.equals(personId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // Get global notes (where personId is null) ordered by creation date (newest first)
  Stream<List<Note>> watchGlobalNotes() {
    return (_database.select(_database.notes)
      ..where((t) => t.personId.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }

  // Get global notes as a future (for one-time fetch)
  Future<List<Note>> getGlobalNotes() {
    return (_database.select(_database.notes)
          ..where((t) => t.personId.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // Add a new note (global if personId is null, person-specific if personId is provided)
  Future<int> addNote(String content, {int? personId}) {
    return _database.into(_database.notes).insert(
      NotesCompanion(
        content: Value(content),
        personId: Value(personId),
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

  // Delete all notes for a specific person
  Future<int> deleteNotesForPerson(int personId) {
    return (_database.delete(_database.notes)..where((t) => t.personId.equals(personId)))
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