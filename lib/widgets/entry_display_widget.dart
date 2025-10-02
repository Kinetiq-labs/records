import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/khata_entry.dart';
import '../providers/language_provider.dart';
import '../services/text_translation_service.dart';
import '../utils/translations.dart';

class EntryDisplayWidget extends StatelessWidget {
  final KhataEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EntryDisplayWidget({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final translationService = TextTranslationService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with entry index and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${Translations.get('entry', currentLang)} #${entry.entryIndex}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  entry.entryDate.toIso8601String().substring(0, 10),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Main entry information
            _buildInfoRow(
              Translations.get('name', currentLang),
              translationService.getDisplayText(entry.name, currentLang),
              Icons.person,
              Colors.green,
            ),
            
            if (entry.number != 0)
              _buildInfoRow(
                Translations.get('number', currentLang),
                entry.number.toString(),
                Icons.tag,
                Colors.blue,
              ),
            
            if (entry.weight != null)
              _buildInfoRow(
                Translations.get('weight', currentLang),
                entry.weight!.toStringAsFixed(2),
                Icons.scale,
                Colors.orange,
              ),
            
            if (entry.detail != null && entry.detail!.isNotEmpty)
              _buildInfoRow(
                Translations.get('detail', currentLang),
                translationService.getDisplayText(entry.detail!, currentLang),
                Icons.description,
                Colors.purple,
              ),
            
            // Input fields section
            if (_hasInputFields())
              _buildSectionHeader(Translations.get('input_fields', currentLang)),
            
            if (entry.firstWeight != null)
              _buildInfoRow(
                Translations.get('first_weight', currentLang),
                entry.firstWeight.toString(),
                Icons.fitness_center,
                Colors.indigo,
              ),
            
            if (entry.silver != null)
              _buildInfoRow(
                Translations.get('silver', currentLang),
                entry.silver.toString(),
                Icons.brightness_7,
                Colors.grey,
              ),
            
            if (entry.returnWeight1 != null)
              _buildInfoRow(
                Translations.get('return_weight_1', currentLang),
                entry.returnWeight1Display ?? entry.returnWeight1.toString(),
                Icons.undo,
                Colors.teal,
              ),
            
            if (entry.returnWeight2 != null)
              _buildInfoRow(
                Translations.get('return_weight_2', currentLang),
                entry.returnWeight2.toString(),
                Icons.undo,
                Colors.teal,
              ),
            
            if (entry.nalki != null)
              _buildInfoRow(
                Translations.get('nalki', currentLang),
                entry.nalki.toString(),
                Icons.grain,
                Colors.brown,
              ),
            
            // Computed fields section
            if (_hasComputedFields())
              _buildSectionHeader(Translations.get('computed_fields', currentLang)),
            
            if (entry.total != null)
              _buildInfoRow(
                Translations.get('total', currentLang),
                entry.total!.toStringAsFixed(2),
                Icons.calculate,
                Colors.green[700]!,
              ),
            
            if (entry.difference != null)
              _buildInfoRow(
                Translations.get('difference', currentLang),
                entry.difference!.toStringAsFixed(2),
                Icons.compare_arrows,
                Colors.red[700]!,
              ),
            
            if (entry.sumValue != null)
              _buildInfoRow(
                Translations.get('sum_value', currentLang),
                entry.sumValue!.toStringAsFixed(3),
                Icons.add_circle,
                Colors.blue[700]!,
              ),
            
            if (entry.rtti != null)
              _buildInfoRow(
                Translations.get('rtti', currentLang),
                entry.rtti!.toStringAsFixed(3),
                Icons.analytics,
                Colors.purple[700]!,
              ),
            
            if (entry.carat != null)
              _buildInfoRow(
                Translations.get('carat', currentLang),
                entry.carat!.toStringAsFixed(3),
                Icons.diamond,
                Colors.yellow[700]!,
              ),
            
            if (entry.masha != null)
              _buildInfoRow(
                Translations.get('masha', currentLang),
                entry.masha!.toStringAsFixed(3),
                Icons.balance,
                Colors.orange[700]!,
              ),
            
            // Action buttons
            if (onEdit != null || onDelete != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(Translations.get('edit', currentLang)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 8),
                    
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: Text(Translations.get('delete', currentLang)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            
            // Sync status indicator
            if (entry.syncStatus != 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sync_problem,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Translations.get('pending_sync', currentLang),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasInputFields() {
    return entry.firstWeight != null ||
           entry.silver != null ||
           entry.returnWeight1 != null ||
           entry.returnWeight2 != null ||
           entry.nalki != null;
  }

  bool _hasComputedFields() {
    return entry.total != null ||
           entry.difference != null ||
           entry.sumValue != null ||
           entry.rtti != null ||
           entry.carat != null ||
           entry.masha != null;
  }
}