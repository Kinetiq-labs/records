import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../providers/records_provider.dart';
import '../utils/bilingual_text_styles.dart';
import 'edit_record_dialog.dart';

class RecordCard extends StatelessWidget {
  final Record record;

  const RecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecordDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Category chip
              Chip(
                label: Text(
                  record.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                record.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer with timestamps
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  BilingualText.bilingual(
                    'Updated ${_formatDate(record.updatedAt)}',
                    style: BilingualTextStyles.bodySmall(
                      'Updated ${_formatDate(record.updatedAt)}',
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (record.createdAt != record.updatedAt)
                    BilingualText.bilingual(
                      'Created ${_formatDate(record.createdAt)}',
                      style: BilingualTextStyles.bodySmall(
                        'Created ${_formatDate(record.createdAt)}',
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(record.category),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 16),
              
              // Timestamps
              Text(
                'Details',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              BilingualText.bilingual(
                'Created: ${_formatDateTime(record.createdAt)}',
                style: BilingualTextStyles.bodySmall(
                  'Created: ${_formatDateTime(record.createdAt)}',
                ),
              ),
              BilingualText.bilingual(
                'Updated: ${_formatDateTime(record.updatedAt)}',
                style: BilingualTextStyles.bodySmall(
                  'Updated: ${_formatDateTime(record.updatedAt)}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDialog(context);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditRecordDialog(record: record),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (record.id != null) {
                final success = await context
                    .read<RecordsProvider>()
                    .deleteRecord(record.id!);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? 'Record deleted successfully' 
                          : 'Failed to delete record'),
                      backgroundColor: success 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}