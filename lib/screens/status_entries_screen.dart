import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/khata_provider.dart';
import '../providers/language_provider.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../widgets/edit_entry_form.dart';
import '../services/text_translation_service.dart';

class StatusEntriesScreen extends StatefulWidget {
  final String status;
  final DateTime selectedDate;
  final bool isMonthlyView; // true for monthly, false for daily

  const StatusEntriesScreen({
    super.key,
    required this.status,
    required this.selectedDate,
    this.isMonthlyView = false,
  });

  @override
  State<StatusEntriesScreen> createState() => _StatusEntriesScreenState();
}

class _StatusEntriesScreenState extends State<StatusEntriesScreen> with TickerProviderStateMixin {
  final Set<String> _selectedEntries = {};
  final Map<String, AnimationController> _undoControllers = {};
  final Map<String, bool> _pendingDeletes = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _subtotalHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextTranslationService _translationService = TextTranslationService();

  bool _isScrollingSyncing = false;
  DateTime _currentDate = DateTime.now();
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  String? _previousLanguage;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _currentMonth = widget.selectedDate.month;
    _currentYear = widget.selectedDate.year;

    // Sync horizontal scrolling between header and data
    _horizontalController.addListener(() {
      if (!_isScrollingSyncing && _headerHorizontalController.hasClients) {
        _isScrollingSyncing = true;
        _headerHorizontalController.jumpTo(_horizontalController.offset);
        if (_subtotalHorizontalController.hasClients) {
          _subtotalHorizontalController.jumpTo(_horizontalController.offset);
        }
        _isScrollingSyncing = false;
      }
    });

    _headerHorizontalController.addListener(() {
      if (!_isScrollingSyncing && _horizontalController.hasClients) {
        _isScrollingSyncing = true;
        _horizontalController.jumpTo(_headerHorizontalController.offset);
        if (_subtotalHorizontalController.hasClients) {
          _subtotalHorizontalController.jumpTo(_headerHorizontalController.offset);
        }
        _isScrollingSyncing = false;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
      _setInitialScrollPosition();
    });
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in _undoControllers.values) {
      controller.dispose();
    }
    _horizontalController.dispose();
    _headerHorizontalController.dispose();
    _subtotalHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _setInitialScrollPosition() {
    // Set scroll position based on language direction after a short delay
    // to ensure the scroll controllers are properly initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final languageProvider = context.read<LanguageProvider>();
      final currentLang = languageProvider.currentLanguage;

      // With reverse scroll property, both RTL and LTR start at position 0
      // but the interpretation changes:
      // - RTL (reverse: true): position 0 = rightmost
      // - LTR (reverse: false): position 0 = leftmost
      if (_horizontalController.hasClients) {
        _horizontalController.jumpTo(0);
      }
      if (_headerHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(0);
      }
      if (_subtotalHorizontalController.hasClients) {
        _subtotalHorizontalController.jumpTo(0);
      }
    });
  }

  void _loadEntries() {
    final khataProvider = context.read<KhataProvider>();
    if (widget.isMonthlyView) {
      khataProvider.loadEntriesByMonth(_currentYear, _currentMonth);
    } else {
      khataProvider.loadEntriesByDate(_currentDate);
    }
  }

  List<KhataEntry> _getFilteredEntries(List<KhataEntry> allEntries) {
    return allEntries.where((entry) {
      // Filter by status
      final entryStatus = (entry.status ?? '').toLowerCase();
      final filterStatus = widget.status.toLowerCase();

      final statusMatch = entryStatus == filterStatus;

      // Filter out deleted entries
      final notDeleted = _pendingDeletes[entry.entryId] != true;

      return statusMatch && notDeleted;
    }).toList();
  }

  void _toggleSelection(String entryId) {
    setState(() {
      if (_selectedEntries.contains(entryId)) {
        _selectedEntries.remove(entryId);
      } else {
        _selectedEntries.add(entryId);
      }
    });
  }

  void _deleteSelectedEntries() async {
    final khataProvider = context.read<KhataProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    final entriesToDelete = List<String>.from(_selectedEntries);

    // Mark entries as pending delete
    setState(() {
      for (String entryId in entriesToDelete) {
        _pendingDeletes[entryId] = true;

        // Create animation controller for undo timer
        final controller = AnimationController(
          duration: const Duration(seconds: 5),
          vsync: this,
        );
        _undoControllers[entryId] = controller;

        // Start the countdown
        controller.forward().then((_) {
          // If not undone, actually delete from database
          if (_pendingDeletes[entryId] == true) {
            khataProvider.deleteEntry(entryId);
            setState(() {
              _pendingDeletes.remove(entryId);
              _undoControllers.remove(entryId);
            });
            controller.dispose();
          }
        });
      }
      _selectedEntries.clear();
    });

    // Show undo snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entriesToDelete.length} ${Translations.get(entriesToDelete.length == 1 ? 'entry_deleted' : 'entries_deleted', currentLang)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: Translations.get('undo', currentLang),
            textColor: Colors.white,
            onPressed: () => _undoDelete(entriesToDelete),
          ),
        ),
      );
    }
  }

  void _undoDelete(List<String> entryIds) {
    setState(() {
      for (String entryId in entryIds) {
        _pendingDeletes.remove(entryId);
        _undoControllers[entryId]?.stop();
        _undoControllers[entryId]?.dispose();
        _undoControllers.remove(entryId);
      }
    });
  }

  void _editEntry(KhataEntry entry) {
    showDialog(
      context: context,
      builder: (context) => EditEntryForm(
        entry: entry,
        onEntryUpdated: () {
          // Refresh the entries list after update
          _loadEntries();
        },
      ),
    );
  }

  void _navigateToPreviousPeriod() {
    setState(() {
      if (widget.isMonthlyView) {
        if (_currentMonth == 1) {
          _currentMonth = 12;
          _currentYear--;
        } else {
          _currentMonth--;
        }
      } else {
        _currentDate = _currentDate.subtract(const Duration(days: 1));
      }
    });
    _loadEntries();
  }

  void _navigateToNextPeriod() {
    setState(() {
      if (widget.isMonthlyView) {
        if (_currentMonth == 12) {
          _currentMonth = 1;
          _currentYear++;
        } else {
          _currentMonth++;
        }
      } else {
        _currentDate = _currentDate.add(const Duration(days: 1));
      }
    });
    _loadEntries();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
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

  Widget _buildDataTable(List<KhataEntry> entries, String currentLang) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredEntries = _getFilteredEntries(entries);

    // Calculate silver subtotal
    double silverSubtotal = 0.0;
    for (final entry in filteredEntries) {
      if (entry.silver != null) {
        silverSubtotal += entry.silver!;
      }
    }

    return Column(
      children: [
        // Fixed Header
        RawScrollbar(
          controller: _headerHorizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 14.0,
          radius: const Radius.circular(7),
          thumbColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          trackColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0),
          trackBorderColor: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
          child: SingleChildScrollView(
            controller: _headerHorizontalController,
            scrollDirection: Axis.horizontal,
            reverse: currentLang == 'ur',
            child: Container(
              width: 2200,
              height: 60,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFF0B5D3B).withValues(alpha: 0.15),
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFF0B5D3B).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: _buildHeaderRow(currentLang, isDarkMode),
            ),
          ),
        ),

        // Scrollable Data Rows
        Expanded(
          child: RawScrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 14.0,
            radius: const Radius.circular(7),
            thumbColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
            trackColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0),
            trackBorderColor: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: RawScrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 14.0,
                radius: const Radius.circular(7),
                thumbColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                trackColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0),
                trackBorderColor: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  reverse: currentLang == 'ur',
                  child: Container(
                    width: 2200,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: filteredEntries.map((entry) => _buildDataRow(entry, currentLang, isDarkMode)).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Silver subtotal row
        _buildSilverSubtotalRow(silverSubtotal, currentLang, isDarkMode),
      ],
    );
  }

  Widget _buildHeaderRow(String currentLang, bool isDarkMode) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
      fontSize: 16,
    );

    return Row(
      textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
      children: [
        _buildHeaderCell(Translations.get('entry', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('name', currentLang), 140, headerStyle),
        _buildHeaderCell(Translations.get('number', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('weight', currentLang), 100, headerStyle),
        _buildHeaderCell(Translations.get('detail', currentLang), 150, headerStyle),
        _buildHeaderCell(Translations.get('first_weight', currentLang), 100, headerStyle),
        _buildHeaderCell(Translations.get('silver', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('return_weight_1', currentLang), 120, headerStyle),
        _buildHeaderCell(Translations.get('return_weight_2', currentLang), 120, headerStyle),
        _buildHeaderCell(Translations.get('nalki', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('total', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('difference', currentLang), 100, headerStyle),
        _buildHeaderCell(Translations.get('sum_value', currentLang), 100, headerStyle),
        _buildHeaderCell(Translations.get('rtti', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('carat', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('masha', currentLang), 80, headerStyle),
        _buildHeaderCell(Translations.get('entry_time', currentLang), 120, headerStyle),
        _buildHeaderCell(Translations.get('status', currentLang), 120, headerStyle),
      ],
    );
  }

  Widget _buildHeaderCell(String text, double width, TextStyle style) {
    return Container(
      width: width,
      height: 60,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: BilingualTextStyles.labelLarge(text, color: style.color).copyWith(
          fontWeight: style.fontWeight,
          fontSize: style.fontSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(KhataEntry entry, String currentLang, bool isDarkMode) {
    final isSelected = _selectedEntries.contains(entry.entryId);
    final rowColor = isSelected
        ? (isDarkMode ? const Color(0xFF4A7C59).withValues(alpha: 0.3) : const Color(0xFF0B5D3B).withValues(alpha: 0.25))
        : (isDarkMode ? const Color(0xFF1E1E1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8));

    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
    );

    return InkWell(
      onTap: () => _toggleSelection(entry.entryId),
      onDoubleTap: () => _editEntry(entry),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? const Color(0xFF4A4A4A).withValues(alpha: 0.3) : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _buildDataCell('#${entry.entryIndex}', 80, textStyle, isIndexCell: true),
            _buildBilingualDataCell(_translationService.getDisplayText(entry.name, currentLang), 140, textStyle),
            _buildDataCell(entry.number.toString(), 80, textStyle),
            _buildDataCell(entry.weight?.toStringAsFixed(4) ?? '-', 100, textStyle),
            _buildBilingualDataCell(entry.detail ?? '-', 150, textStyle),
            _buildDataCell(entry.firstWeight?.toString() ?? '-', 100, textStyle),
            _buildDataCell(entry.silver?.toString() ?? '-', 80, textStyle, isSilverCell: true),
            _buildDataCell(entry.returnWeight1Display ?? entry.returnWeight1?.toString() ?? '-', 120, textStyle),
            _buildDataCell(entry.returnWeight2?.toString() ?? '-', 120, textStyle),
            _buildDataCell(entry.nalki?.toString() ?? '-', 80, textStyle),
            _buildDataCell(entry.total?.toStringAsFixed(2) ?? '-', 80, textStyle),
            _buildDataCell(entry.difference?.toStringAsFixed(2) ?? '-', 100, textStyle),
            _buildDataCell(entry.sumValue?.toStringAsFixed(3) ?? '-', 100, textStyle),
            _buildDataCell(entry.rtti?.toStringAsFixed(2) ?? '-', 80, textStyle),
            _buildDataCell(entry.carat?.toStringAsFixed(3) ?? '-', 80, textStyle),
            _buildDataCell(entry.masha?.toStringAsFixed(3) ?? '-', 80, textStyle),
            _buildDataCell(entry.entryTime != null ? _formatTime(entry.entryTime!) : '-', 120, textStyle),
            _buildStatusCell(entry, currentLang, isDarkMode, 120),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, TextStyle style, {bool isIndexCell = false, bool isSilverCell = false}) {
    Color? backgroundColor;
    if (isIndexCell) {
      backgroundColor = const Color(0xFF0B5D3B);
      style = style.copyWith(color: Colors.white, fontWeight: FontWeight.bold);
    } else if (isSilverCell) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      style = style.copyWith(color: isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFF2196F3));
    }

    return Container(
      width: width,
      height: 50,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: isIndexCell ? BorderRadius.circular(4) : null,
            )
          : null,
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBilingualDataCell(String text, double width, TextStyle style, {bool isIndexCell = false, bool isSilverCell = false}) {
    Color? backgroundColor;
    if (isIndexCell) {
      backgroundColor = const Color(0xFF0B5D3B);
      style = style.copyWith(color: Colors.white, fontWeight: FontWeight.bold);
    } else if (isSilverCell) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      style = style.copyWith(color: isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFF2196F3));
    }

    return Container(
      width: width,
      height: 50,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: isIndexCell ? BorderRadius.circular(4) : null,
            )
          : null,
      child: Text(
        text,
        style: BilingualTextStyles.getTextStyle(
          text: text,
          color: style.color!,
          fontSize: style.fontSize!,
          fontWeight: style.fontWeight!,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusCell(KhataEntry entry, String currentLang, bool isDarkMode, double width) {
    return Container(
      width: width,
      height: 50,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(entry.status ?? '').withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(entry.status ?? ''),
            width: 1,
          ),
        ),
        child: Row(
          textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(entry.status ?? ''),
              size: 12,
              color: _getStatusColor(entry.status ?? ''),
            ),
            const SizedBox(width: 4),
            Text(
              entry.status ?? 'Unknown',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(entry.status ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverSubtotalRow(double silverSubtotal, String currentLang, bool isDarkMode) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFF0B5D3B).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: RawScrollbar(
        controller: _subtotalHorizontalController,
        thumbVisibility: false,
        child: SingleChildScrollView(
          controller: _subtotalHorizontalController,
          scrollDirection: Axis.horizontal,
          reverse: currentLang == 'ur',
          child: SizedBox(
            width: 2200,
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              children: [
                _buildSubtotalCell(Translations.get('subtotal', currentLang), 80, isDarkMode, isLabel: true),
                _buildSubtotalCell('', 140, isDarkMode), // Name
                _buildSubtotalCell('', 80, isDarkMode), // Number
                _buildSubtotalCell('', 100, isDarkMode), // Weight
                _buildSubtotalCell('', 150, isDarkMode), // Detail
                _buildSubtotalCell('', 100, isDarkMode), // First Weight
                _buildSubtotalCell(silverSubtotal.toString(), 80, isDarkMode, isSilverTotal: true), // Silver
                _buildSubtotalCell('', 120, isDarkMode), // Return Weight 1
                _buildSubtotalCell('', 120, isDarkMode), // Return Weight 2
                _buildSubtotalCell('', 80, isDarkMode), // Nalki
                _buildSubtotalCell('', 80, isDarkMode), // Total
                _buildSubtotalCell('', 100, isDarkMode), // Difference
                _buildSubtotalCell('', 100, isDarkMode), // Sum Value
                _buildSubtotalCell('', 80, isDarkMode), // RTTI
                _buildSubtotalCell('', 80, isDarkMode), // Carat
                _buildSubtotalCell('', 80, isDarkMode), // Masha
                _buildSubtotalCell('', 120, isDarkMode), // Entry Time
                _buildSubtotalCell('', 120, isDarkMode), // Status
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtotalCell(String text, double width, bool isDarkMode, {bool isLabel = false, bool isSilverTotal = false}) {
    TextStyle style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
    );

    Widget content = Container(
      width: width,
      height: 50,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );

    if (isLabel) {
      content = Container(
        width: width,
        height: 50,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: BilingualTextStyles.labelMedium(
              text,
              color: Colors.white,
            ).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    } else if (isSilverTotal) {
      content = Container(
        width: width,
        height: 50,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF4A7C59) : const Color(0xFFE8F5E8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return content;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildActionButtons(String currentLang) {
    if (_selectedEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_selectedEntries.length == 1) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final khataProvider = context.read<KhataProvider>();
                  final entry = khataProvider.entries.firstWhere((e) => e.entryId == _selectedEntries.first);
                  _editEntry(entry);
                },
                icon: const Icon(Icons.edit, size: 20),
                label: Text(Translations.get('edit', currentLang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5D3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _deleteSelectedEntries,
              icon: const Icon(Icons.delete, size: 20),
              label: Text(
                '${Translations.get('delete', currentLang)} (${_selectedEntries.length})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodTitle(String currentLang) {
    if (widget.isMonthlyView) {
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${monthNames[_currentMonth - 1]} $_currentYear';
    } else {
      return _currentDate.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final khataProvider = context.watch<KhataProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if language changed and update scroll position accordingly
    if (_previousLanguage != null && _previousLanguage != currentLang) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setInitialScrollPosition());
    }
    _previousLanguage = currentLang;

    final allEntries = khataProvider.entries;
    final filteredEntries = _getFilteredEntries(allEntries);
    final statusColor = _getStatusColor(widget.status);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(widget.status),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.status} ${Translations.get('entries', currentLang)}',
              style: BilingualTextStyles.headlineMedium(
                '${widget.status} ${Translations.get('entries', currentLang)}',
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B5D3B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Date/Period header with navigation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                  ? [const Color(0xFF2D2D2D), const Color(0xFF4A4A4A)]
                  : [statusColor, statusColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Previous period button
                IconButton(
                  onPressed: _navigateToPreviousPeriod,
                  icon: Icon(
                    currentLang == 'ur' ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),

                // Entry count container (left side)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${filteredEntries.length} ${widget.status} ${Translations.get('entries', currentLang)}',
                    style: BilingualTextStyles.bodyMedium(
                      '${filteredEntries.length} ${widget.status} ${Translations.get('entries', currentLang)}',
                      color: Colors.white,
                    ).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                const Spacer(),

                // Rightmost: Period type above date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.isMonthlyView
                          ? Translations.get('monthly_entries', currentLang)
                          : Translations.get('daily_entries', currentLang),
                      style: BilingualTextStyles.bodyMedium(
                        widget.isMonthlyView
                            ? Translations.get('monthly_entries', currentLang)
                            : Translations.get('daily_entries', currentLang),
                        color: Colors.white70,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getPeriodTitle(currentLang),
                      style: BilingualTextStyles.titleLarge(
                        _getPeriodTitle(currentLang),
                        color: Colors.white,
                      ).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isMonthlyView ? Icons.calendar_month : Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),

                // Next period button
                IconButton(
                  onPressed: _navigateToNextPeriod,
                  icon: Icon(
                    currentLang == 'ur' ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Entries table
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: khataProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                      ),
                    )
                  : filteredEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStatusIcon(widget.status),
                                size: 64,
                                color: statusColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${Translations.get('no', currentLang)} ${widget.status} ${Translations.get('entries_found', currentLang)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildDataTable(allEntries, currentLang),
            ),
          ),

          // Action buttons
          _buildActionButtons(currentLang),
        ],
      ),
    );
  }
}