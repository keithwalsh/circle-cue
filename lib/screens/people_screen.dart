import 'package:flutter/material.dart';
import 'dart:io';
import '../database/app_database.dart';
import '../repositories/person_repository.dart';

class PeopleScreen extends StatefulWidget {
  final AppDatabase database;

  const PeopleScreen({super.key, required this.database});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<PeopleData> _people = [];
  bool _isLoading = true;
  late PersonRepository _personRepository;

  @override
  void initState() {
    super.initState();
    _personRepository = PersonRepository(widget.database);
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final people = await _personRepository.getAllPeople();
    setState(() {
      _people = people;
      _isLoading = false;
    });
  }

  Future<void> _refreshPeople() async {
    final people = await _personRepository.getAllPeople();
    setState(() {
      _people = people;
    });
  }

  Future<void> _showAddPersonDialog() async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Person'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter person\'s name...',
              border: OutlineInputBorder(),
              labelText: 'Name',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _personRepository.addPerson(result);
      _refreshPeople();
    }
    
    nameController.dispose();
  }

  Future<void> _deletePerson(PeopleData person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Person'),
          content: Text('Are you sure you want to delete ${person.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _personRepository.deletePerson(person.id);
      _refreshPeople();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('People (${_people.length})'),
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      body: _people.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No people yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first person',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _people.length,
                itemBuilder: (context, index) {
                  final person = _people[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: person.photoPath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(person.photoPath!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      person.name.isNotEmpty
                                          ? person.name[0].toUpperCase()
                                          : '?',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                person.name.isNotEmpty
                                    ? person.name[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Text(
                        person.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _deletePerson(person),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete person',
                        color: theme.colorScheme.error,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonDialog,
        tooltip: 'Add Person',
        child: const Icon(Icons.add),
      ),
    );
  }
} 