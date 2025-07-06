import 'package:drift/drift.dart';
import '../database/app_database.dart';

class PersonRepository {
  final AppDatabase _database;

  PersonRepository(this._database);

  // Get all people ordered alphabetically by name
  Stream<List<PeopleData>> watchAllPeople() {
    return (_database.select(_database.people)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
  }

  // Get all people as a future (for one-time fetch) ordered alphabetically
  Future<List<PeopleData>> getAllPeople() {
    return (_database.select(_database.people)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
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

  // Add test data for verification
  Future<void> addTestData() async {
    // Clear existing data first
    await deleteAllPeople();
    
    // Add test people in non-alphabetical order to verify sorting
    final testPeople = [
      'Zoe Williams',
      'Alice Johnson',
      'Bob Smith',
      'Charlie Brown',
      'David Davis',
      'Emma Wilson',
      'Frank Miller',
      'Grace Lee',
      'Henry Taylor',
      'Ivy Chen',
    ];
    
    for (String name in testPeople) {
      await addPerson(name);
    }
  }

  // Close the database connection
  Future<void> close() {
    return _database.close();
  }
} 