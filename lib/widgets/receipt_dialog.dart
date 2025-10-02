import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/khata_entry.dart';
import '../models/user.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../services/pdf_text_service.dart';

class ReceiptDialog extends StatefulWidget {
  final KhataEntry entry;
  final User? user;
  final String currentLang;

  const ReceiptDialog({
    super.key,
    required this.entry,
    required this.user,
    required this.currentLang,
  });

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        height: 700,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt,
                    color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Translations.get('receipt', widget.currentLang),
                    style: BilingualTextStyles.getTextStyle(
                      text: Translations.get('receipt', widget.currentLang),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Receipt Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildReceiptPreview(),
              ),
            ),

            // Print Button
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _printReceipt,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print, size: 20),
                label: Text(
                  Translations.get('print', widget.currentLang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoNastaliqUrdu',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5D3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final entry = widget.entry;
    final user = widget.user;

    // Get dynamic info from user settings
    final shopNameUrdu = user?.shopName ?? 'قیصر گولڈ لیب';
    final shopNameEnglish = user?.preferences?['shop_name_english'] as String? ?? 'Qaisar Gold Lab';
    final ownerName = user?.fullName ?? 'QAISAR ABBAS';
    final primaryPhone = user?.primaryPhone ?? '03000885418';
    final secondaryPhone = user?.secondaryPhone ?? '03138609197';
    final ptclNumber = user?.preferences?['ptcl_number'] as String? ?? '048-${entry.number.toString().padLeft(7, '0')}';

    return SingleChildScrollView(
      child: Container(
        width: 400, // 14cm equivalent
        height: 310, // Further increased height to fix overflow issue
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1), // Reduced border width
        ),
        child: Column(
          children: [
            // Row 1: Shop name - no border, light sea green background
            Container(
              height: 40, // Increased height
              decoration: const BoxDecoration(
                color: Color(0xFF20B2AA), // Light sea green background
                border: Border(bottom: BorderSide(color: Colors.black, width: 1)), // Reduced border width
              ),
              child: Center(
                child: Row(
                  children: [
                    // Left side - English
                    Expanded(
                      child: Text(
                        shopNameEnglish,
                        style: const TextStyle(
                          fontSize: 24, // Much larger font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    // Right side - Urdu
                    Expanded(
                      child: Text(
                        shopNameUrdu,
                        style: const TextStyle(
                          fontSize: 24, // Much larger font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoNastaliqUrdu',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Row 2: User info and time statement (merged with blank space)
            Container(
              height: 55, // Increased height to fix overflow
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8DC), // Yellow background
                border: Border(bottom: BorderSide(color: Colors.black, width: 1)), // Reduced border width
              ),
              child: Row(
                children: [
                  // Left column - Time statement and PTCL number
                  Expanded(
                    child: Container(
                      color: const Color(0xFF90EE90), // Light green background
                      padding: const EdgeInsets.all(2), // Reduced padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Important: prevents overflow
                        children: [
                          // Time statement
                          Flexible( // Wrap in Flexible to prevent overflow
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 16, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Black text on light green background
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                                children: [
                                  const TextSpan(text: 'رات '),
                                  WidgetSpan(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getShopClosingTime(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' بجے تک تحلیل کی سہولت'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2), // Reduced spacing
                          // PTCL number
                          Flexible( // Wrap in Flexible to prevent overflow
                            child: Text(
                              'PTCL $ptclNumber',
                              style: const TextStyle(
                                fontSize: 16, // Further increased font size
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 55, color: Colors.black), // Reduced border width
                  // Right column - User name above contact numbers
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFF8DC), // Yellow background
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Important: prevents overflow
                          children: [
                            Flexible( // Wrap in Flexible to prevent overflow
                              child: Text(
                                ownerName.isNotEmpty ? ownerName : '--',
                                style: const TextStyle(
                                  fontSize: 18, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                                textAlign: TextAlign.center,
                                softWrap: true, // Enable text wrapping
                                overflow: TextOverflow.visible, // Allow text to wrap
                              ),
                            ),
                            Flexible( // Wrap in Flexible to prevent overflow
                              child: Text(
                                '${primaryPhone.isNotEmpty ? primaryPhone : '--'}  ${secondaryPhone.isNotEmpty ? secondaryPhone : '--'}',
                                style: const TextStyle(
                                  fontSize: 16, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                softWrap: true, // Enable text wrapping
                                overflow: TextOverflow.visible, // Allow text to wrap
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Blank row between 2nd and 3rd row (no borders) - increased to shift content down
            Container(
              height: 45, // Further increased height to shift rows 3-6 more down
              color: Colors.white,
            ),

            // Entry Detail, Entry Name, and Return Weight
            Container(
              height: 40, // Increased height
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                ), // Added top border as well
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFE4B5), // Light orange for Return Weight
                      child: Center(
                        child: Text(
                          entry.returnWeight1Display?.isNotEmpty == true ? entry.returnWeight1Display! : '--',
                          style: const TextStyle(
                            fontSize: 18, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.black),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFE4B5), // Light orange for Entry Detail
                      child: Center(
                        child: Text(
                          (entry.detail?.isNotEmpty == true) ? entry.detail! : '--',
                          style: const TextStyle(
                            fontSize: 18, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.black),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFE4B5), // Light orange for Entry Name
                      child: Center(
                        child: Text(
                          entry.name.isNotEmpty ? entry.name : '--',
                          style: const TextStyle(
                            fontSize: 18, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'NotoNastaliqUrdu',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Date and Weight
            Container(
              height: 35, // Increased height
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 1)), // Reduced border width
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: const Color(0xFFADD8E6), // Light blue background
                      child: Center(
                        child: Text(
                          _formatDate(entry.entryDate),
                          style: const TextStyle(
                            fontSize: 16, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Black text
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 35, color: Colors.black),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFADD8E6), // Light blue background
                      child: Center(
                        child: Text(
                          _getUrduDayName(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 16, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Black text
                            fontFamily: 'NotoNastaliqUrdu',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 35, color: Colors.black),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFADD8E6), // Light blue background
                      child: Center(
                        child: Text(
                          entry.weight != null ? entry.weight!.toStringAsFixed(3) : '--',
                          style: const TextStyle(
                            fontSize: 16, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Black text
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 35, color: Colors.black),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFADD8E6), // Light blue background
                      child: const Center(
                        child: Text(
                          'وزن وصول',
                          style: TextStyle(
                            fontSize: 16, // Further increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'NotoNastaliqUrdu',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Combined layout with merged right columns
            Container(
              height: 85, // Reduced to fit 9.5cm total (remaining space)
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 1)), // Reduced border width
              ),
              child: Row(
                children: [
                  // Left side columns (same as before)
                  Expanded(
                    child: Column(
                      children: [
                        // Row 5 left: Time
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white, // White background
                              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                            ),
                            child: Center(
                              child: Text(
                                _formatReceivedTime(),
                                style: const TextStyle(
                                  fontSize: 14, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue, // Blue text to match 'فی رتی'
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Row 6 left: RTTI value
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                            ),
                            child: Center(
                              child: Text(
                                entry.rtti != null ? '(${entry.rtti!.abs().toStringAsFixed(3)})' : '--',
                                style: const TextStyle(
                                  fontSize: 14, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Row 7 left: Masha value
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Text(
                                entry.masha != null ? '(${entry.masha!.abs().toStringAsFixed(3)})' : '--',
                                style: const TextStyle(
                                  fontSize: 14, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 85, color: Colors.black),

                  // Second column
                  Expanded(
                    child: Column(
                      children: [
                        // Row 5: وقت وصول
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white, // White background
                              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                            ),
                            child: const Center(
                              child: Text(
'وقت وصول', // Fixed spacing
                                style: TextStyle(
                                  fontSize: 14, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue, // Blue text to match 'فی رتی'
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        // Row 6: فی رتی
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                            ),
                            child: const Center(
                              child: Text(
                                'فی\nرتی',
                                style: TextStyle(
                                  fontSize: 14, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        // Row 7: فی تولہ
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: const Center(
                              child: Text(
                                'فی\nتولہ',
                                style: TextStyle(
                                  fontSize: 14, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 85, color: Colors.black),

                  // Third column (wider)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Row 5: Sum value
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                            ),
                            child: Center(
                              child: Text(
                                entry.sumValue != null ? entry.sumValue!.toStringAsFixed(2) : '--',
                                style: const TextStyle(
                                  fontSize: 16, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Rows 6-7: Merged carat value
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Text(
                                entry.carat != null ? entry.carat!.toStringAsFixed(2) : '--',
                                style: const TextStyle(
                                  fontSize: 16, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 85, color: Colors.black),

                  // Right column - merged grid
                  Expanded(
                    child: Column(
                      children: [
                        // Top cell: سم (row 5)
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6FFE6), // Light green
                              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                            ),
                            child: const Center(
                              child: Text(
                                'سم',
                                style: TextStyle(
                                  fontSize: 16, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Bottom merged cell: کیرٹ (rows 6-7 combined)
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: const Color(0xFFE6FFE6), // Light green
                            child: const Center(
                              child: Text(
                                'کیرٹ',
                                style: TextStyle(
                                  fontSize: 16, // Further increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  String _formatCurrentTime() {
    final entryDateTime = widget.entry.entryDate;
    final hour = entryDateTime.hour.toString().padLeft(2, '0');
    final minute = entryDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Method for received time with PM/AM
  String _formatReceivedTime() {
    final entryDateTime = widget.entry.entryDate;
    final hour = entryDateTime.hour == 0 ? 12 : (entryDateTime.hour > 12 ? entryDateTime.hour - 12 : entryDateTime.hour);
    final minute = entryDateTime.minute.toString().padLeft(2, '0');
    final period = entryDateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Method for PDF received time with PM/AM and proper text direction
  String _formatReceivedTimeForPDF() {
    final entryDateTime = widget.entry.entryDate;
    final hour = entryDateTime.hour == 0 ? 12 : (entryDateTime.hour > 12 ? entryDateTime.hour - 12 : entryDateTime.hour);
    final minute = entryDateTime.minute.toString().padLeft(2, '0');
    final period = entryDateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }


  String _getShopClosingTime() {
    final user = widget.user;
    final shopTimings = user?.shopTimings;

    if (shopTimings != null && shopTimings.isNotEmpty) {
      // Parse shop timings format like "9:00 AM - 6:00 PM"
      final parts = shopTimings.split(' - ');
      if (parts.length == 2) {
        String closingTime = parts[1].trim();
        // Remove PM/AM from the time
        closingTime = closingTime.replaceAll(RegExp(r'\s*(AM|PM|am|pm)\s*'), '');
        return closingTime;
      }
    }

    // Default fallback time without PM/AM
    return '22:00';
  }

  String _getUrduDayName(DateTime date) {
    const urduWeekdays = [
      'پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'
    ];
    return urduWeekdays[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _printReceipt() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check for available printers
      final printers = await Printing.listPrinters();

      if (printers.isEmpty) {
        _showMessage(
          'کوئی پرنٹر نہیں ملا',
          'کوئی پرنٹر منسلک نہیں ہے۔ براہ کرم بلوٹوتھ یا پورٹ کے ذریعے پرنٹر منسلک کریں۔',
          true,
        );
        return;
      }

      // Generate PDF and print
      final pdfData = await generatePDF();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'Receipt_${widget.entry.entryIndex}',
        format: const PdfPageFormat(
          140 * PdfPageFormat.mm, // 14cm width
          100 * PdfPageFormat.mm, // 10cm height
          marginAll: 5 * PdfPageFormat.mm,
        ),
      );

      _showMessage(
        'پرنٹ مکمل',
        'رسید کامیابی سے پرنٹ ہوگئی۔',
        false,
      );

    } catch (e) {
      _showMessage(
        'پرنٹ خرابی',
        'پرنٹ کرتے وقت خرابی: ${e.toString()}',
        true,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }



  Future<Uint8List> generatePDF() async {
    final pdf = pw.Document();
    final entry = widget.entry;
    final user = widget.user;

    // Get dynamic info from user settings
    final shopNameUrdu = user?.shopName ?? 'قیصر گولڈ لیب';
    final shopNameEnglish = user?.preferences?['shop_name_english'] as String? ?? 'Qaisar Gold Lab';
    final ownerName = user?.fullName ?? 'QAISAR ABBAS';
    final primaryPhone = user?.primaryPhone ?? '03000885418';
    final secondaryPhone = user?.secondaryPhone ?? '03138609197';
    final ptclNumber = user?.preferences?['ptcl_number'] as String? ?? '03025880033';

    // Initialize PDF text service for mixed font support
    await PdfTextService.instance.initializeFonts();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Remove all page margins
        build: (pw.Context context) {
          return pw.Positioned(
            top: 0, // Exact top-left corner with no margin
            left: 0,
            child: pw.Container(
              width: 150 * PdfPageFormat.mm, // 15cm width
              height: 95 * PdfPageFormat.mm, // 9.5cm height
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1), // Reduced border width
            ),
            child: pw.Column(
              children: [
                // Row 1: Shop name - no border, light sea green background
                pw.Container(
                  height: 20 * PdfPageFormat.mm,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#20B2AA'), // Light sea green background
                    border: const pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      left: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0), // Increased padding around shop name text
                    child: pw.Center(
                      child: pw.Row(
                        children: [
                        // Left side - English
                        pw.Expanded(
                          child: PdfTextService.instance.createStyledText(
                            shopNameEnglish,
                            fontSize: 18, // Increased font size
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.left,
                            color: PdfColors.white,
                          ),
                        ),
                        // Right side - Urdu
                        pw.Expanded(
                          child: PdfTextService.instance.createStyledText(
                            shopNameUrdu,
                            fontSize: 18, // Increased font size
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.right,
                            color: PdfColors.white,
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Row 2: User info and time statement (merged with blank space)
                pw.Container(
                  height: 20 * PdfPageFormat.mm, // Further increased height for better text spacing
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#90EE90'), // Light green background
                    border: const pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      left: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4.0), // Add padding around text
                    child: pw.Row(
                      children: [
                        // Left column - Time statement and PTCL number
                        pw.Expanded(
                          child: pw.Container(
                            color: PdfColor.fromHex('#90EE90'), // Light green background
                            child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              PdfTextService.instance.createStyledText(
                                'رات ${_getShopClosingTime()} بجے تک تحلیل کی سہولت',
                                fontSize: 10, // Further increased font size for better printing
                                fontWeight: pw.FontWeight.bold,
                                textAlign: pw.TextAlign.center,
                                color: PdfColors.black, // Black text on light green background
                              ),
                              pw.SizedBox(height: 2),
                              PdfTextService.instance.createStyledText(
                                'PTCL: $ptclNumber',
                                fontSize: 9, // Increased PTCL font size for better printing
                                fontWeight: pw.FontWeight.bold,
                                textAlign: pw.TextAlign.center,
                                color: PdfColors.black, // Black text on light green background
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right column - User name and contact
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#90EE90'), // Light green background
                          child: pw.Center(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                PdfTextService.instance.createStyledText(
                                  ownerName.isNotEmpty ? ownerName : '--',
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 2),
                                PdfTextService.instance.createStyledText(
                                  primaryPhone.isNotEmpty ? primaryPhone : '--',
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 2),
                                PdfTextService.instance.createStyledText(
                                  secondaryPhone.isNotEmpty ? secondaryPhone : '--',
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),

                // Blank row between 2nd and 3rd row (no borders) - increased to shift content down
                pw.Container(
                  height: 7 * PdfPageFormat.mm, // 0.7cm height to shift rows 3-6 down (space redistributed to 2nd row)
                  color: PdfColors.white,
                ),

                // Entry Detail, Entry Name, and Return Weight
                pw.Container(
                  height: 12 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 1),
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      left: pw.BorderSide(color: PdfColors.black, width: 1),
                    ), // Added top and left borders
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#FFE4B5'), // Light orange for Return Weight
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              entry.returnWeight1Display?.isNotEmpty == true ? entry.returnWeight1Display! : '--',
                              fontSize: 12, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                              color: PdfColors.black, // Black color
                            ),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#FFE4B5'), // Light orange for Entry Detail
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              (entry.detail?.isNotEmpty == true) ? entry.detail! : '--',
                              fontSize: 12, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#FFE4B5'), // Light orange for Entry Name
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              entry.name.isNotEmpty ? entry.name : '--',
                              fontSize: 12, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Date and Weight
                pw.Container(
                  height: 10 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      left: pw.BorderSide(color: PdfColors.black, width: 1),
                    ), // Added left border
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#ADD8E6'), // Light blue background
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              _formatDate(entry.entryDate),
                              fontSize: 11, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                              color: PdfColors.black, // Black text
                            ),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#ADD8E6'), // Light blue background
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              _getUrduDayName(entry.entryDate),
                              fontSize: 11, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                              color: PdfColors.black, // Black text
                            ),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#ADD8E6'), // Light blue background
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              entry.weight?.toStringAsFixed(3) ?? '--',
                              fontSize: 11, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                              color: PdfColors.black, // Black text
                            ),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#ADD8E6'), // Light blue background
                          child: pw.Center(
                            child: PdfTextService.instance.createStyledText(
                              'وزن وصول',
                              fontSize: 10, // Further increased font size for better printing
                              fontWeight: pw.FontWeight.bold,
                              textAlign: pw.TextAlign.center,
                              color: PdfColors.black, // Black text
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Combined complex layout
                pw.Container(
                  height: 25 * PdfPageFormat.mm, // Further reduced to eliminate empty space
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 1),
                      left: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // Left column: Time, RTTI, Masha values
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.white, // White background
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    _formatReceivedTimeForPDF(),
                                    style: pw.TextStyle(
                                      font: pw.Font.helvetica(),
                                      fontSize: 10, // Further increased font size for better printing
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.blue, // Blue text to match 'فی رتی'
                                    ),
                                    textAlign: pw.TextAlign.center,
                                    textDirection: pw.TextDirection.ltr,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.white,
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                                ),
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    entry.rtti != null ? '(${entry.rtti!.abs().toStringAsFixed(3)})' : '--',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                color: PdfColors.white,
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    entry.masha != null ? '(${entry.masha!.abs().toStringAsFixed(3)})' : '--',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 25 * PdfPageFormat.mm, color: PdfColors.black), // Reduced border width

                      // Second column: Labels
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#E6FFE6'), // Light green to match 'سم' cell
                                  border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                                ),
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    'وقت وصول', // Fixed spacing
                                    fontSize: 11, // Increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue, // Blue text to match 'فی رتی'
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#E6FFE6'), // Light green to match 'سم' cell
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                                ),
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    'فی\u00A0\nرتی',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                color: PdfColor.fromHex('#E6FFE6'), // Light green to match 'سم' cell
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    'فی\u00A0\nتولہ',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 25 * PdfPageFormat.mm, color: PdfColors.black), // Reduced border width

                      // Third column: Sum and Carat values
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.white,
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                                ),
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    entry.sumValue != null ? entry.sumValue!.toStringAsFixed(2) : '--',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            // Merged cells for carat value
                            pw.Expanded(
                              flex: 2,
                              child: pw.Container(
                                color: PdfColors.white,
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    entry.carat != null ? entry.carat!.toStringAsFixed(2) : '--',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(width: 1, height: 25 * PdfPageFormat.mm, color: PdfColors.black), // Reduced border width

                      // Right column: Labels
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#E6FFE6'), // Light green
                                  border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                                ),
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    'سم',
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            // Merged cell for کیرٹ
                            pw.Expanded(
                              flex: 2,
                              child: pw.Container(
                                height: 10 * PdfPageFormat.mm, // 1cm height for last row
                                color: PdfColor.fromHex('#E6FFE6'), // Light green
                                child: pw.Center(
                                  child: PdfTextService.instance.createStyledText(
                                    'کیرٹ', // Fixed spelling
                                    fontSize: 10, // Further increased font size for better printing
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  void _showMessage(String title, String message, bool isError) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            color: isError ? Colors.red : Colors.green,
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'NotoNastaliqUrdu'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ٹھیک ہے',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu'),
            ),
          ),
        ],
      ),
    );
  }
}