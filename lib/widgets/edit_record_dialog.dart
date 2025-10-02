import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../providers/records_provider.dart';
import '../utils/bilingual_text_styles.dart';

class EditRecordDialog extends StatefulWidget {
  final Record record;

  const EditRecordDialog({
    super.key,
    required this.record,
  });

  @override
  State<EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<EditRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  
  bool _isLoading = false;
  
  final List<String> _predefinedCategories = [
    'Work',
    'Personal',
    'Learning',
    'Health',
    'Finance',
    'Travel',
    'Projects',
    'Ideas',
    'Notes',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record.title);
    _descriptionController = TextEditingController(text: widget.record.description);
    _categoryController = TextEditingController(text: widget.record.category);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Record'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter record title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Category field with dropdown
              DropdownButtonFormField<String>(
                value: _predefinedCategories.contains(_categoryController.text) 
                    ? _categoryController.text 
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  hintText: 'Select or enter category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _predefinedCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _categoryController.text = value;
                  }
                },
                validator: (value) {
                  if (_categoryController.text.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 8),
              
              // Custom category input
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Custom Category',
                  hintText: 'Or enter custom category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Enter record description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 16),
              
              // Record info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BilingualText.bilingual(
                      'Created: ${_formatDateTime(widget.record.createdAt)}',
                      style: BilingualTextStyles.bodySmall(
                        'Created: ${_formatDateTime(widget.record.createdAt)}',
                      ),
                    ),
                    BilingualText.bilingual(
                      'Last Updated: ${_formatDateTime(widget.record.updatedAt)}',
                      style: BilingualTextStyles.bodySmall(
                        'Last Updated: ${_formatDateTime(widget.record.updatedAt)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateRecord,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if any changes were made
    if (_titleController.text.trim() == widget.record.title &&
        _descriptionController.text.trim() == widget.record.description &&
        _categoryController.text.trim() == widget.record.category) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedRecord = widget.record.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      final success = await context.read<RecordsProvider>().updateRecord(updatedRecord);
      
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update record'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}