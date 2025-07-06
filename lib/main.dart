import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'database/app_database.dart';
import 'repositories/notes_repository.dart';
import 'screens/people_screen.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CircleCue',
      debugShowCheckedModeBanner: false,
      home: NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final TextEditingController _noteController = TextEditingController();
  List<Note> _notes = [];
  bool _isDarkMode = false;
  bool _isLoading = true;
  int _currentIndex = 0;
  late AppDatabase _database;
  late NotesRepository _notesRepository;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    _database = AppDatabase();
    _notesRepository = NotesRepository(_database);
    await _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme preference
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    // Load notes from database (only global notes, not person-specific)
    final notes = await _notesRepository.getGlobalNotes();
    
    // Migrate existing SharedPreferences notes to database if any exist
    final existingNotes = prefs.getStringList('notes');
    if (existingNotes != null && existingNotes.isNotEmpty && notes.isEmpty) {
      // Migrate old notes to database
      for (final noteContent in existingNotes.reversed) {
        await _notesRepository.addNote(noteContent);
      }
      // Clear the old SharedPreferences data
      await prefs.remove('notes');
      // Reload notes from database after migration (only global notes)
      final migratedNotes = await _notesRepository.getGlobalNotes();
      setState(() {
        _notes = migratedNotes;
        _isDarkMode = isDarkMode;
        _isLoading = false;
      });
    } else {
      setState(() {
        _notes = notes;
        _isDarkMode = isDarkMode;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> _addNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isNotEmpty) {
      await _notesRepository.addNote(noteText);
      _noteController.clear();
      _refreshNotes();
    }
  }

  Future<void> _editNote(Note note) async {
    final TextEditingController editController = TextEditingController(text: note.content);
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: 'Edit your note...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final editedText = editController.text.trim();
                if (editedText.isNotEmpty) {
                  Navigator.of(context).pop(editedText);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _notesRepository.updateNote(note.id, result);
      _refreshNotes();
    }
    
    editController.dispose();
  }

  Future<void> _deleteNote(Note note) async {
    await _notesRepository.deleteNote(note.id);
    _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    final notes = await _notesRepository.getGlobalNotes();
    setState(() {
      _notes = notes;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveTheme();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! ☀️';
    } else if (hour < 17) {
      return 'Good afternoon! 🌤️';
    } else {
      return 'Good evening! 🌙';
    }
  }

  String _getTodaysDate() {
    return DateFormat('EEEE, MMMM d, y').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final ThemeData theme = _isDarkMode
        ? ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          )
        : ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          );

    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _currentIndex == 0 
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting, date, and theme toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTodaysDate(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleTheme,
                          icon: Icon(
                            _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                            size: 28,
                          ),
                          tooltip: _isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick note input section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick note',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _noteController,
                                    decoration: InputDecoration(
                                      hintText: 'Type a short reminder or idea...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    onSubmitted: (_) => _addNote(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: _addNote,
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notes list section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your notes (${_notes.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _notes.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.note_add_outlined,
                                          size: 64,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No notes yet',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add your first note above to get started',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _notes.length,
                                    itemBuilder: (context, index) {
                                      final note = _notes[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(
                                            note.content,
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () => _editNote(note),
                                                icon: const Icon(Icons.edit),
                                                tooltip: 'Edit note',
                                                color: theme.colorScheme.primary,
                                              ),
                                              IconButton(
                                                onPressed: () => _deleteNote(note),
                                                icon: const Icon(Icons.close),
                                                tooltip: 'Delete note',
                                                color: theme.colorScheme.error,
                                              ),
                                            ],
                                          ),
                                          onTap: () => _editNote(note),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : PeopleScreen(database: _database),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.note),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'People',
            ),
          ],
        ),
      ),
    );
  }
} 