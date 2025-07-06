import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../database/app_database.dart';
import '../repositories/person_repository.dart';

class PersonDetailScreen extends StatefulWidget {
  final AppDatabase database;
  final PeopleData person;

  const PersonDetailScreen({
    super.key,
    required this.database,
    required this.person,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late PersonRepository _personRepository;
  late TextEditingController _nameController;
  late TextEditingController _tagsController;
  final _formKey = GlobalKey<FormState>();
  
  String? _photoPath;
  bool _isLoading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _personRepository = PersonRepository(widget.database);
    _nameController = TextEditingController(text: widget.person.name);
    _tagsController = TextEditingController(text: widget.person.tags ?? '');
    _photoPath = widget.person.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _photoPath = pickedFile.path;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _photoPath = null;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    return null;
  }

  Future<void> _savePerson() async {
    setState(() {
      _nameError = _validateName(_nameController.text);
      _isLoading = true;
    });

    if (_nameError != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final success = await _personRepository.updatePerson(
        widget.person.id,
        _nameController.text.trim(),
        photoPath: _photoPath,
        tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Person updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate changes were made
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update person'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _parseTags(String tagsString) {
    if (tagsString.trim().isEmpty) return [];
    return tagsString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  Widget _buildPhotoSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _photoPath != null
                  ? ClipOval(
                      child: Image.file(
                        File(_photoPath!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 60,
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.add_a_photo,
                      size: 60,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
            ),
          ),
        ),
        if (_photoPath != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Photo'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection() {
    final theme = Theme.of(context);
    final tags = _parseTags(_tagsController.text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: 'Enter tags separated by commas...',
            border: OutlineInputBorder(),
            labelText: 'Tags',
          ),
          textCapitalization: TextCapitalization.words,
          maxLines: 2,
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: theme.colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Details'),
        backgroundColor: theme.colorScheme.surfaceContainer,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _savePerson,
              icon: const Icon(Icons.save),
              tooltip: 'Save changes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo section
              _buildPhotoSection(),
              
              const SizedBox(height: 24),
              
              // Name section
              Text(
                'Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter person\'s name...',
                  border: const OutlineInputBorder(),
                  labelText: 'Name',
                  errorText: _nameError,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  if (_nameError != null) {
                    setState(() {
                      _nameError = _validateName(value);
                    });
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Tags section
              _buildTagsSection(),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _savePerson,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 