import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/pdf_text_service.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import '../providers/khata_provider.dart';
import '../providers/language_provider.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../widgets/edit_entry_form.dart';
import '../widgets/new_entry_form.dart';
import '../widgets/pos_receipt_dialog.dart';
import '../widgets/receipt_dialog.dart';
import '../providers/user_provider.dart';
import '../services/text_translation_service.dart';
import '../utils/responsive_utils.dart';

class EntriesScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? highlightEntryId; // Entry ID to highlight

  const EntriesScreen({
    super.key,
    required this.selectedDate,
    this.highlightEntryId,
  });

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> with TickerProviderStateMixin {
  final Set<String> _selectedEntries = {};
  final Map<String, AnimationController> _undoControllers = {};
  final Map<String, bool> _pendingDeletes = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _subtotalHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextTranslationService _translationService = TextTranslationService();

  bool _isScrollingSyncing = false;

  // Inline editing state
  String? _editingEntryId;
  String? _editingField;
  TextEditingController? _editingController;
  String? _highlightedEntryId;
  bool _showHighlight = false;
  String? _previousLanguage;

  @override
  void initState() {
    super.initState();

    // Set highlighted entry if provided
    if (widget.highlightEntryId != null) {
      _highlightedEntryId = widget.highlightEntryId;
      _showHighlight = true;
      // Remove highlight after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showHighlight = false;
          });
        }
      });
    }

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
      context.read<KhataProvider>().loadEntriesByDate(widget.selectedDate);
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
    _editingController?.dispose();
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
          context.read<KhataProvider>().loadEntriesByDate(widget.selectedDate);
        },
      ),
    );
  }

  Widget _buildDataTable(List<KhataEntry> entries, String currentLang) {
    final visibleEntries = entries.where((entry) => _pendingDeletes[entry.entryId] != true).toList();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate silver subtotal
    double silverSubtotal = 0.0;
    for (final entry in visibleEntries) {
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
              width: 2470,
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
                    width: 2470,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: visibleEntries.map((entry) => _buildDataRow(entry, currentLang, isDarkMode)).toList(),
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
        _buildHeaderCell(Translations.get('silver_sold', currentLang), 120, headerStyle),
        _buildHeaderCell(Translations.get('silver_amount', currentLang), 150, headerStyle),
        _buildHeaderCell(Translations.get('discount_percent', currentLang), 100, headerStyle),
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
      child: BilingualText.bilingual(
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
    final isHighlighted = _highlightedEntryId == entry.entryId;

    Color rowColor;
    if (isHighlighted) {
      // Use animated highlight color for the target entry
      rowColor = Colors.transparent; // Will be overridden by AnimatedBuilder
    } else if (isSelected) {
      rowColor = isDarkMode ? const Color(0xFF4A7C59).withValues(alpha: 0.3) : const Color(0xFF0B5D3B).withValues(alpha: 0.25);
    } else {
      rowColor = isDarkMode ? const Color(0xFF1E1E1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8);
    }

    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
    );

    Widget containerChild = Container(
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
            _buildSilverPaidCell(entry, 120, textStyle),
            _buildDataCell(entry.silverAmount?.toStringAsFixed(2) ?? '-', 150, textStyle),
            _buildEditableDataCell(entry, 'discountPercent', entry.discountPercent?.toStringAsFixed(1) ?? '-', 100, textStyle),
            _buildEditableDataCell(entry, 'total', entry.total?.toStringAsFixed(2) ?? '-', 80, textStyle),
            _buildEditableDataCell(entry, 'difference', entry.difference?.toStringAsFixed(2) ?? '-', 100, textStyle),
            _buildEditableDataCell(entry, 'sumValue', entry.sumValue?.toStringAsFixed(3) ?? '-', 100, textStyle),
            _buildEditableDataCell(entry, 'rtti', entry.rtti?.toStringAsFixed(2) ?? '-', 80, textStyle),
            _buildEditableDataCell(entry, 'carat', entry.carat?.toStringAsFixed(3) ?? '-', 80, textStyle),
            _buildEditableDataCell(entry, 'masha', entry.masha?.toStringAsFixed(3) ?? '-', 80, textStyle),
            _buildDataCell(entry.entryTime != null ? _formatTime(entry.entryTime!) : '-', 120, textStyle),
            _buildStatusCell(entry, currentLang, isDarkMode, 120),
          ],
        ),
    );

    // If this entry is highlighted, wrap with colored background
    if (isHighlighted && _showHighlight) {
      containerChild = Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEB3B).withValues(alpha: 0.8), // Bright yellow highlight
        ),
        child: containerChild,
      );
    }

    return InkWell(
      onTap: () => _toggleSelection(entry.entryId),
      onDoubleTap: () => _showEditDialog(entry),
      child: containerChild,
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
      child: BilingualText.bilingual(
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
      child: _buildStatusSelector(entry, currentLang, isDarkMode),
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
            width: 2470,
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
                _buildSubtotalCell('', 120, isDarkMode), // Silver Price
                _buildSubtotalCell('', 150, isDarkMode), // Silver Amount
                _buildSubtotalCell('', 100, isDarkMode), // Discount %
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

  Widget _buildSilverPaidCell(KhataEntry entry, double width, TextStyle style) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasSilverPrice = entry.silverSold != null && entry.silverSold! > 0;

    return Container(
      width: width,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
          width: 0.5,
        ),
      ),
      child: hasSilverPrice
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Silver price display
              Flexible(
                child: Text(
                  entry.silverSold!.toStringAsFixed(2),
                  style: style.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 2),
              // Checkbox for silver paid status
              Transform.scale(
                scale: 0.5,
                child: Checkbox(
                  value: entry.silverPaid,
                  onChanged: (bool? value) async {
                    if (value != null) {
                      await _updateSilverPaidStatus(entry, value);
                    }
                  },
                  activeColor: const Color(0xFF0B5D3B),
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          )
        : const SizedBox.shrink(), // Hide completely when no silver price
    );
  }

  Future<void> _updateSilverPaidStatus(KhataEntry entry, bool isPaid) async {
    try {
      final khataProvider = context.read<KhataProvider>();

      // Update only the silver_paid field without triggering full refresh
      await khataProvider.updateSilverPaidStatus(entry.entryId, isPaid);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPaid ? 'Silver marked as paid' : 'Silver marked as unpaid',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0B5D3B),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating silver status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
          child: BilingualText.bilingual(
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

  // Build status selector widget for each entry
  Widget _buildStatusSelector(KhataEntry entry, String currentLang, bool isDarkMode) {
    final statusOptions = ['Paid', 'Pending', 'Gold', 'Recheck', 'Card'];
    final currentStatus = entry.status ?? '';

    return SizedBox(
      width: 100,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus.isEmpty ? null : currentStatus,
          hint: Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          items: statusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
                ),
              ),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              _updateEntryStatus(entry, newStatus);
            }
          },
          isExpanded: true,
          dropdownColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          iconEnabledColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
          ),
        ),
      ),
    );
  }

  // Helper method to show edit dialog
  void _showEditDialog(KhataEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditEntryForm(
          entry: entry,
          onEntryUpdated: () {
            final khataProvider = context.read<KhataProvider>();
            khataProvider.loadEntriesByDate(widget.selectedDate);
          },
        );
      },
    );
  }

  void _showPosReceiptDialog(KhataEntry entry) {
    final userProvider = context.read<UserProvider>();
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PosReceiptDialog(
          entry: entry,
          user: userProvider.currentUser,
          currentLang: languageProvider.currentLanguage,
        );
      },
    );
  }


  void _showReceiptDialog(KhataEntry entry) {
    final userProvider = context.read<UserProvider>();
    final languageProvider = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReceiptDialog(
          entry: entry,
          user: userProvider.currentUser,
          currentLang: languageProvider.currentLanguage,
        );
      },
    );
  }

  // Helper method to format time in HH:MM AM/PM format
  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }


  // Update entry status
  void _updateEntryStatus(KhataEntry entry, String newStatus) async {
    try {
      final khataProvider = context.read<KhataProvider>();
      await khataProvider.updateEntryStatus(entry.entryId, newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Show export dialog
  void _showExportDialog(BuildContext context, String currentLang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              const Icon(Icons.download, color: Color(0xFF0B5D3B)),
              const SizedBox(width: 8),
              BilingualText.bilingual(
                Translations.get('export_data', currentLang),
                style: BilingualTextStyles.titleMedium(
                  Translations.get('export_data', currentLang),
                  color: const Color(0xFF0B5D3B),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BilingualText.bilingual(
                '${Translations.get('export_format', currentLang)}:',
                style: BilingualTextStyles.bodyLarge(
                  '${Translations.get('export_format', currentLang)}:',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PDF Export Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _exportToPDF(currentLang);
                      },
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const Text('PDF', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CSV Export Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _exportToCSV(currentLang);
                      },
                      icon: const Icon(Icons.table_chart, color: Colors.white),
                      label: const Text('CSV', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                Translations.get('cancel', currentLang),
                style: BilingualTextStyles.bodyMedium(
                  Translations.get('cancel', currentLang),
                  color: const Color(0xFF0B5D3B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Export to PDF with mixed Urdu-English text support
  Future<void> _exportToPDF(String currentLang) async {
    try {
      final khataProvider = context.read<KhataProvider>();
      final entries = khataProvider.entries.where((entry) =>
          _pendingDeletes[entry.entryId] != true).toList();

      if (entries.isEmpty) {
        _showMessage('No entries to export', Colors.orange);
        return;
      }

      // Initialize PDF text service
      await PdfTextService.instance.initializeFonts();

      final pdf = pw.Document();
      final dateStr = widget.selectedDate.toIso8601String().substring(0, 10);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            // Title
            pw.Header(
              level: 0,
              child: PdfTextService.instance.createStyledText(
                'Khata Entries - $dateStr',
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            // Custom table with mixed text support
            _buildPdfTable(entries, currentLang),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'khata_entries_$dateStr.pdf';
      final filePath = await _saveFileToDownloads(bytes, fileName);
      if (filePath != null) {
        _showMessage('PDF exported to: $filePath', Colors.green);
      } else {
        _showMessage('Error saving PDF file', Colors.red);
      }

    } catch (e) {
      _showMessage('Error exporting PDF: ${e.toString()}', Colors.red);
    }
  }

  // Build custom PDF table with mixed text support and RTL layout support
  pw.Widget _buildPdfTable(List<dynamic> entries, String currentLang) {
    final engHeaders = [
      'Entry', 'Name', 'Number', 'Weight', 'Detail',
      'First Weight', 'Silver', 'Return Weight 1', 'Return Weight 2', 'Nalki',
      'Silver Price', 'Silver Amount', 'Discount %',
      'Total', 'Difference', 'Sum', 'RTTI', 'Carat', 'Masha',
      'Time', 'Status'
    ];

    final urduHeaders = [
      'انٹری', 'نام', 'نمبر', 'وزن', 'تفصیل',
      'پہلا وزن', 'چاندی', 'واپسی وزن ۱', 'واپسی وزن ۲', 'نالکی',
      'چاندی کی قیمت', 'چاندی کی مقدار', 'رعایت %',
      'ٹوٹل', 'فرق', 'سم', 'رتی', 'کیریٹ', 'ماشہ',
      'وقت', 'حالت'
    ];

    // Use appropriate headers based on language and reverse for RTL if Urdu
    final headers = currentLang == 'en' ? engHeaders : urduHeaders.reversed.toList();

    final baseColumnWidths = [
      35.0, 80.0, 45.0, 45.0, 70.0, // Entry, Name, Number, Weight, Detail
      55.0, 50.0, 65.0, 65.0, 45.0, // First Weight, Silver, Return Weight 1&2, Nalki
      80.0, 70.0, 45.0, 45.0, 45.0, // Silver Price, Amount, Discount, Total, Difference
      70.0, 65.0, 50.0, 50.0, 60.0, 50.0 // Sum Value, RTTI, Carat, Masha, Time, Status
    ];

    // Reverse column widths for RTL layout if Urdu
    final columnWidths = currentLang == 'en' ? baseColumnWidths : baseColumnWidths.reversed.toList();

    return pw.Table(
      columnWidths: Map.fromIterables(
        List.generate(headers.length, (i) => i),
        columnWidths.map((width) => pw.FixedColumnWidth(width)),
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map((header) => pw.Container(
                    padding: const pw.EdgeInsets.all(2),
                    alignment: currentLang == 'en' ? pw.Alignment.center : pw.Alignment.center,
                    child: PdfTextService.instance.createStyledText(
                      header,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      textAlign: currentLang == 'en' ? pw.TextAlign.center : pw.TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        // Data rows
        ...entries.map<pw.TableRow>((entry) {
          final rowData = [
            _buildPdfCell('#${entry.entryIndex}'),
            _buildPdfCell(entry.name ?? '-'), // Mixed text support for names
            _buildPdfCell(entry.number?.toString() ?? '-'),
            _buildPdfCell(entry.weight?.toStringAsFixed(4) ?? '-'),
            _buildPdfCell(entry.detail ?? '-'), // Mixed text support for details
            _buildPdfCell(entry.firstWeight?.toString() ?? '-'),
            _buildPdfCell(entry.silver?.toString() ?? '-'),
            _buildPdfCell(entry.returnWeight1Display ??
                         entry.returnWeight1?.toString() ?? '-'),
            _buildPdfCell(entry.returnWeight2?.toString() ?? '-'),
            _buildPdfCell(entry.nalki?.toString() ?? '-'),
            _buildPdfCell(entry.silverSold?.toStringAsFixed(2) ?? '-'),
            _buildPdfCell(entry.silverAmount?.toStringAsFixed(2) ?? '-'),
            _buildPdfCell(entry.discountPercent?.toStringAsFixed(1) ?? '-'),
            _buildPdfCell(entry.total?.toStringAsFixed(2) ?? '-'),
            _buildPdfCell(entry.difference?.toStringAsFixed(2) ?? '-'),
            _buildPdfCell(entry.sumValue?.toStringAsFixed(3) ?? '-'),
            _buildPdfCell(entry.rtti?.toStringAsFixed(3) ?? '-'),
            _buildPdfCell(entry.carat?.toStringAsFixed(3) ?? '-'),
            _buildPdfCell(entry.masha?.toStringAsFixed(3) ?? '-'),
            _buildPdfCell(entry.entryTime != null
                         ? _formatTime(entry.entryTime!) : '-'),
            _buildPdfCell(entry.status ?? '-'),
          ];

          // Reverse data order for RTL layout if Urdu
          final children = currentLang == 'en' ? rowData : rowData.reversed.toList();

          return pw.TableRow(children: children);
        }),
      ],
    );
  }

  // Build PDF table cell with mixed text support
  pw.Widget _buildPdfCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: PdfTextService.instance.createStyledText(
        text,
        fontSize: 8,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Export to CSV
  Future<void> _exportToCSV(String currentLang) async {
    try {
      final khataProvider = context.read<KhataProvider>();
      final entries = khataProvider.entries.where((entry) => 
          _pendingDeletes[entry.entryId] != true).toList();

      if (entries.isEmpty) {
        _showMessage('No entries to export', Colors.orange);
        return;
      }

      final dateStr = widget.selectedDate.toIso8601String().substring(0, 10);
      
      // Create CSV data
      final List<List<dynamic>> csvData = [
        // Header row
        [
          'Entry', 'Name', 'Number', 'Weight', 'Detail',
          'First Weight', 'Silver', 'Return Weight 1', 'Return Weight 2', 'Nalki',
          'Silver Price', 'Silver Amount (in grams)', 'Discount %',
          'Total', 'Difference', 'Sum Value', 'RTTI', 'Carat', 'Masha',
          'Entry Time', 'Status', 'Created At'
        ],
        // Data rows
        ...entries.map((entry) => [
          entry.entryIndex,
          entry.name,
          entry.number,
          entry.weight ?? '',
          entry.detail ?? '',
          entry.firstWeight ?? '',
          entry.silver ?? '',
          entry.returnWeight1Display ?? entry.returnWeight1?.toString() ?? '',
          entry.returnWeight2 ?? '',
          entry.nalki ?? '',
          entry.silverSold ?? '',
          entry.silverAmount ?? '',
          entry.discountPercent ?? '',
          entry.total ?? '',
          entry.difference ?? '',
          entry.sumValue ?? '',
          entry.rtti ?? '',
          entry.carat ?? '',
          entry.masha ?? '',
          entry.entryTime != null ? _formatTime(entry.entryTime!) : '',
          entry.status ?? '',
          entry.createdAt.toIso8601String(),
        ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      // Add BOM (Byte Order Mark) for better Unicode support in Excel and other programs
      const utf8Bom = [0xEF, 0xBB, 0xBF];
      final utf8Bytes = utf8.encode(csvString);
      final bytes = Uint8List.fromList([...utf8Bom, ...utf8Bytes]);
      
      final fileName = 'khata_entries_$dateStr.csv';
      final filePath = await _saveFileToDownloads(bytes, fileName);
      if (filePath != null) {
        _showMessage('CSV exported to: $filePath', Colors.green);
      } else {
        _showMessage('Error saving CSV file', Colors.red);
      }

    } catch (e) {
      _showMessage('Error exporting CSV: ${e.toString()}', Colors.red);
    }
  }

  // Save file to Downloads folder
  Future<String?> _saveFileToDownloads(Uint8List bytes, String fileName) async {
    try {
      // Get the downloads directory
      Directory? downloadsDir;
      
      if (Platform.isLinux) {
        // For Linux, try to get Downloads folder
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null) {
          downloadsDir = Directory('$homeDir/Downloads');
        }
      } else if (Platform.isWindows) {
        // For Windows
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsDir = Directory('$userProfile/Downloads');
        }
      } else if (Platform.isMacOS) {
        // For macOS
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null) {
          downloadsDir = Directory('$homeDir/Downloads');
        }
      }

      // Fallback to documents directory if Downloads not found
      downloadsDir ??= await getApplicationDocumentsDirectory();

      // Ensure directory exists
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create the file path
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      // Write the bytes to file
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  Widget _buildEditableDataCell(KhataEntry entry, String fieldName, String text, double width, TextStyle style) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEditing = _editingEntryId == entry.entryId && _editingField == fieldName;

    if (isEditing) {
      return Container(
        width: width,
        height: 50,
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: TextField(
          controller: _editingController,
          style: style,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          ),
          onSubmitted: (_) => _saveInlineEdit(),
          onTapOutside: (_) => _saveInlineEdit(),
          autofocus: true,
        ),
      );
    }

    return InkWell(
      onDoubleTap: () => _startInlineEdit(entry.entryId, fieldName, text == '-' ? '0' : text),
      child: Container(
        width: width,
        height: 50,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDarkMode
            ? const Color(0xFF1A3325).withValues(alpha: 0.5)  // Subtle green tint for calculated fields
            : const Color(0xFFE8F5E9).withValues(alpha: 0.5),
          border: Border.all(
            color: isDarkMode
              ? const Color(0xFF4A7C59).withValues(alpha: 0.3)
              : const Color(0xFF66BB6A).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          text,
          style: style.copyWith(
            color: isDarkMode
              ? const Color(0xFF7FC685)
              : const Color(0xFF2E7D57),
            fontStyle: FontStyle.italic, // Italic to indicate calculated field
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Show message to user
  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == Colors.green ? Icons.check_circle : 
                color == Colors.red ? Icons.error : Icons.info,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
                  final entry = context.read<KhataProvider>().entries
                      .firstWhere((e) => e.entryId == _selectedEntries.first);
                  _editEntry(entry);
                },
                icon: const Icon(Icons.edit, size: 20),
                label: BilingualText.bilingual(Translations.get('edit', currentLang), style: BilingualTextStyles.labelMedium(Translations.get('edit', currentLang))),
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
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final entry = context.read<KhataProvider>().entries
                      .firstWhere((e) => e.entryId == _selectedEntries.first);
                  _showPosReceiptDialog(entry);
                },
                icon: const Icon(Icons.receipt_long, size: 20),
                label: Text(
                  Translations.get('pos_receipt', currentLang),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final entry = context.read<KhataProvider>().entries
                      .firstWhere((e) => e.entryId == _selectedEntries.first);
                  _showReceiptDialog(entry);
                },
                icon: const Icon(Icons.receipt, size: 20),
                label: Text(
                  Translations.get('receipt', currentLang),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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

  // Inline editing methods for calculated fields
  void _startInlineEdit(String entryId, String field, String currentValue) {
    setState(() {
      _editingEntryId = entryId;
      _editingField = field;
      _editingController?.dispose();
      _editingController = TextEditingController(text: currentValue);
    });
  }

  void _cancelInlineEdit() {
    setState(() {
      _editingEntryId = null;
      _editingField = null;
      _editingController?.dispose();
      _editingController = null;
    });
  }

  Future<void> _saveInlineEdit() async {
    if (_editingEntryId == null || _editingField == null || _editingController == null) return;

    final newValue = _editingController!.text.trim();

    // If empty, just cancel
    if (newValue.isEmpty) {
      _cancelInlineEdit();
      return;
    }

    // Validate number format
    final doubleValue = double.tryParse(newValue);
    if (doubleValue == null) {
      _showMessage('Invalid number format', Colors.red);
      return;
    }

    // Store values before async operation
    final entryId = _editingEntryId!;
    final field = _editingField!;

    // Cancel editing immediately for responsive UI
    _cancelInlineEdit();

    try {
      final khataProvider = context.read<KhataProvider>();
      await khataProvider.updateCalculatedField(entryId, field, doubleValue);

      if (mounted) {
        _showMessage('Field updated successfully', const Color(0xFF0B5D3B));
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error updating field: $e', Colors.red);
      }
    }
  }

  bool _isCalculatedField(String fieldName) {
    return ['total', 'difference', 'sumValue', 'rtti', 'carat', 'masha'].contains(fieldName);
  }

  void _showAddEntryDialog(String currentLang) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const NewEntryForm(),
        ),
      ),
    ).then((_) {
      // Refresh the entries after the dialog closes (in case an entry was added)
      if (mounted) {
        context.read<KhataProvider>().loadEntriesByDate(widget.selectedDate);
      }
    });
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: BilingualText.bilingual(
          Translations.get('entries', currentLang),
          style: BilingualTextStyles.headlineMedium(
            Translations.get('entries', currentLang),
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0B5D3B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(currentLang),
        backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                  ? [const Color(0xFF2D2D2D), const Color(0xFF4A4A4A)]
                  : [const Color(0xFF0B5D3B), const Color(0xFF2E7D57)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B5D3B).withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: currentLang == 'ur' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('entries_for', currentLang),
                        textAlign: currentLang == 'ur' ? TextAlign.right : TextAlign.left,
                        style: BilingualTextStyles.bodyMedium(
                          Translations.get('entries_for', currentLang),
                          color: Colors.white70,
                        ).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.selectedDate.toIso8601String().substring(0, 10),
                        textAlign: currentLang == 'ur' ? TextAlign.right : TextAlign.left,
                        style: BilingualTextStyles.titleLarge(
                          widget.selectedDate.toIso8601String().substring(0, 10),
                          color: Colors.white,
                        ).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${khataProvider.entries.length} ${Translations.get('entries', currentLang)}',
                    style: BilingualTextStyles.bodyMedium(
                      '${khataProvider.entries.length} ${Translations.get('entries', currentLang)}',
                      color: Colors.white,
                    ).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Export button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _showExportDialog(context, currentLang),
                    icon: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: Translations.get('export', currentLang),
                  ),
                ),
              ],
            ),
          ),

          // Entries table
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8), // Reduced margin for more space
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
                  : khataProvider.entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                Translations.get('no_entries_found', currentLang),
                                style: BilingualTextStyles.bodyLarge(
                                  Translations.get('no_entries_found', currentLang),
                                  color: Colors.grey[600],
                                ).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildDataTable(khataProvider.entries, currentLang),
            ),
          ),

          // Action buttons
          _buildActionButtons(currentLang),
        ],
      ),
    );
  }
}