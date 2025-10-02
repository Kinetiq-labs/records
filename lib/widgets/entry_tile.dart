import 'package:flutter/material.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';

class EntryTile extends StatelessWidget {
  final KhataEntry entry;
  final VoidCallback? onTap;
  final String currentLang;

  const EntryTile({
    super.key,
    required this.entry,
    this.onTap,
    required this.currentLang,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'recheck':
        return const Color(0xFF9C27B0);
      case 'card':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'gold':
        return Icons.star;
      case 'recheck':
        return Icons.refresh;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'gold':
        return 'Gold';
      case 'recheck':
        return 'Recheck';
      case 'card':
        return 'Card';
      default:
        return status ?? 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with entry number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Entry number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF0B5D3B) : const Color(0xFF0B5D3B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${Translations.get('entry', currentLang)} #${entry.entryIndex}',
                      style: BilingualTextStyles.getTextStyle(
                        text: '${Translations.get('entry', currentLang)} #${entry.entryIndex}',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0B5D3B),
                      ),
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(entry.status),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusDisplay(entry.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Customer name
              Text(
                entry.name,
                style: BilingualTextStyles.getTextStyle(
                  text: entry.name,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              // Date and time row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(entry.entryDate),
                    style: BilingualTextStyles.getTextStyle(
                      text: _formatDate(entry.entryDate),
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                  if (entry.entryTime != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(entry.entryTime),
                      style: BilingualTextStyles.getTextStyle(
                        text: _formatTime(entry.entryTime),
                        fontSize: 12,
                        color: isDarkMode ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),

              // Additional details if available
              if (entry.detail != null && entry.detail!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.detail!,
                  style: BilingualTextStyles.getTextStyle(
                    text: entry.detail!,
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Weight info if available
              if (entry.weight != null || entry.number != 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (entry.number != 0) ...[
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: isDarkMode ? Colors.white54 : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${Translations.get('number', currentLang)}: ${entry.number}',
                        style: BilingualTextStyles.getTextStyle(
                          text: '${Translations.get('number', currentLang)}: ${entry.number}',
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                    if (entry.number != 0 && entry.weight != null) const SizedBox(width: 12),
                    if (entry.weight != null) ...[
                      Icon(
                        Icons.scale,
                        size: 16,
                        color: isDarkMode ? Colors.white54 : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${Translations.get('weight', currentLang)}: ${entry.weight}g',
                        style: BilingualTextStyles.getTextStyle(
                          text: '${Translations.get('weight', currentLang)}: ${entry.weight}g',
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}