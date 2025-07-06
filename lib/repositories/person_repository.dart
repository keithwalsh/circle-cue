import 'package:drift/drift.dart';
import '../database/app_database.dart';

class PersonRepository {
  final AppDatabase _database;

  PersonRepository(this._database);

  // Get all people ordered by creation date (newest first)
  Stream<List<PeopleData>> watchAllPeople() {
    return (_database.select(_database.people)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }

  // Get all people as a future (for one-time fetch)
  Future<List<PeopleData>> getAllPeople() {
    return (_database.select(_database.people)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // Add a new person
  Future<int> addPerson(String name, {String? photoPath}) {
    return _database.into(_database.people).insert(
      PeopleCompanion(
        name: Value(name),
        photoPath: Value(photoPath),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update an existing person
  Future<bool> updatePerson(int id, String name, {String? photoPath}) async {
    final result = await (_database.update(_database.people)
          ..where((t) => t.id.equals(id)))
        .write(PeopleCompanion(
          name: Value(name),
          photoPath: Value(photoPath),
          updatedAt: Value(DateTime.now()),
        ));
    return result > 0;
  }

  // Delete a person by ID
  Future<int> deletePerson(int id) {
    return (_database.delete(_database.people)..where((t) => t.id.equals(id)))
        .go();
  }

  // Delete all people
  Future<int> deleteAllPeople() {
    return _database.delete(_database.people).go();
  }

  // Get person by ID
  Future<PeopleData?> getPersonById(int id) {
    return (_database.select(_database.people)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // Close the database connection
  Future<void> close() {
    return _database.close();
  }
} 