import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../models/khata_entry.dart';
import '../models/user.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../services/pdf_text_service.dart';

class PosReceiptDialog extends StatefulWidget {
  final KhataEntry entry;
  final User? user;
  final String currentLang;

  const PosReceiptDialog({
    super.key,
    required this.entry,
    required this.user,
    required this.currentLang,
  });

  @override
  State<PosReceiptDialog> createState() => _PosReceiptDialogState();
}

class _PosReceiptDialogState extends State<PosReceiptDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        height: 600,
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
                    Icons.receipt_long,
                    color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Translations.get('pos_receipt', widget.currentLang),
                    style: BilingualTextStyles.getTextStyle(
                      text: Translations.get('pos_receipt', widget.currentLang),
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

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _downloadReceipt,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 20),
                      label: Text(
                        Translations.get('download', widget.currentLang),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoNastaliqUrdu',
                        ),
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
                ],
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

    // Get shop info from user settings
    final shopName = user?.shopName ?? 'گولڈ لیب';
    final primaryPhone = user?.primaryPhone ?? '03000885418';
    final secondaryPhone = user?.secondaryPhone ?? '03138609197';
    final ptclNumber = user?.preferences?['ptcl_number'] as String? ?? '048-${entry.number.toString().padLeft(7, '0')}';

    return SingleChildScrollView(
      child: Container(
        width: 300, // 80mm width approximation
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          children: [
            // Row 1: Shop Name and Lab Name (3 row height equivalent)
            _buildReceiptRow(
              height: 60,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'سعید مارکیٹ\nصرافہ بازار\nسرگودہا',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoNastaliqUrdu',
                        height: 1.2,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoNastaliqUrdu',
                        height: 1.2,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Row 2: Contact Numbers
            _buildReceiptRow(
              height: 25,
              child: Text(
                '$primaryPhone - $secondaryPhone',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Row 3: Receipt Number (Green) and Time
            _buildReceiptRow(
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ptclNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      _formatCurrentTime(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Row 4: Entry Date (Black background, white text)
            _buildReceiptRow(
              height: 30,
              backgroundColor: Colors.black,
              child: Text(
                _formatEntryDateUrdu(entry.entryDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Row 5: Customer Name and Detail
            _buildReceiptRow(
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.detail ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Row 6: Weight Label and Value
            _buildReceiptRow(
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.weight?.toStringAsFixed(3) ?? '0.000',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'وصول وزن',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoNastaliqUrdu',
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Row 7: Processing Time Notice (Black background, white text)
            _buildReceiptRow(
              height: 25,
              backgroundColor: Colors.black,
              child: Text(
                'تحلیل کے لیے 1 گھنٹے کا وقت درکار ہے',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Row 8: Receipt Warning (Black background, white text)
            _buildReceiptRow(
              height: 25,
              backgroundColor: Colors.black,
              child: Text(
                'رسید کے بغیر رزلٹ نہیں ملے گا',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontFamily: 'NotoNastaliqUrdu',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow({
    required double height,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Center(child: child),
    );
  }


  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }


  String _formatEntryDateUrdu(DateTime date) {
    final urduMonths = [
      'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
      'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
    ];

    final urduWeekdays = [
      'پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'
    ];

    final weekday = urduWeekdays[date.weekday - 1];
    final month = urduMonths[date.month - 1];
    return 'بعتہ، ${date.day} $month $weekday، ${date.year}';
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
      final pdfData = await _generatePDF();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'POS_Receipt_${widget.entry.entryIndex}',
        format: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          80 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
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

  Future<void> _downloadReceipt() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('💾 Starting PDF download process');

      final pdfData = await _generatePDF();
      debugPrint('✅ PDF data generated, size: ${pdfData.length} bytes');

      if (pdfData.isEmpty) {
        throw Exception('PDF generation returned empty data');
      }

      // Get downloads directory
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'POS_Receipt_${widget.entry.entryIndex}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      debugPrint('💾 Saving to: ${file.path}');
      await file.writeAsBytes(pdfData);

      // Verify file was created successfully
      final fileExists = await file.exists();
      final fileSize = await file.length();

      debugPrint('✅ File saved successfully: exists=$fileExists, size=$fileSize bytes');

      _showMessage(
        'ڈاؤن لوڈ مکمل',
        'رسید کامیابی سے محفوظ ہوگئی: ${file.path}',
        false,
      );

    } catch (e, stackTrace) {
      debugPrint('💥 Error in download process: $e');
      debugPrint('Stack trace: $stackTrace');

      _showMessage(
        'ڈاؤن لوڈ خرابی',
        'فائل محفوظ کرتے وقت خرابی: ${e.toString()}',
        true,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<Uint8List> _generatePDF() async {
    try {
      debugPrint('🔥 Starting POS receipt PDF generation');

      // Initialize PDF text service for mixed text support
      await PdfTextService.instance.initializeFonts();
      debugPrint('✅ PDF fonts initialized for POS receipt');

      final pdf = pw.Document();
      final entry = widget.entry;
      final user = widget.user;

      // Get shop info from user settings - sanitize text to prevent PDF errors
      final shopName = _sanitizeText(user?.shopName ?? 'گولڈ لیب');
      final primaryPhone = _sanitizeText(user?.primaryPhone ?? '03000885418');
      final secondaryPhone = _sanitizeText(user?.secondaryPhone ?? '03138609197');
      final ptclNumber = _sanitizeText(user?.preferences?['ptcl_number'] as String? ?? '048-${entry.number.toString().padLeft(7, '0')}');

      debugPrint('🏪 Shop info: $shopName, phones: $primaryPhone-$secondaryPhone');

      pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          120 * PdfPageFormat.mm,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              children: [
                // Row 1: Shop Name and Lab Name
                pw.Container(
                  height: 20 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            _sanitizeText('سعید مارکیٹ صرافہ بازار سرگودہا'),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 1,
                        height: 20 * PdfPageFormat.mm,
                        color: PdfColors.black,
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            shopName,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 2: Contact Numbers
                pw.Container(
                  height: 8 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Center(
                    child: PdfTextService.instance.createStyledText(
                      '$primaryPhone - $secondaryPhone',
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),

                // Row 3: Receipt Number and Time
                pw.Container(
                  height: 10 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            ptclNumber,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 1,
                        height: 10 * PdfPageFormat.mm,
                        color: PdfColors.black,
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            _formatCurrentTime(),
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 4: Entry Date (Black background)
                pw.Container(
                  height: 10 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Center(
                    child: PdfTextService.instance.createStyledText(
                      _formatEntryDateUrdu(entry.entryDate),
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),

                // Row 5: Customer Name and Detail
                pw.Container(
                  height: 10 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            _sanitizeText(entry.detail ?? ''),
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 1,
                        height: 10 * PdfPageFormat.mm,
                        color: PdfColors.black,
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            _sanitizeText(entry.name),
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 6: Weight Label and Value
                pw.Container(
                  height: 10 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            entry.weight?.toStringAsFixed(3) ?? '0.000',
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 1,
                        height: 10 * PdfPageFormat.mm,
                        color: PdfColors.black,
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          child: PdfTextService.instance.createStyledText(
                            _sanitizeText('وصول وزن'),
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 7: Processing Time Notice (Black background)
                pw.Container(
                  height: 8 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Center(
                    child: PdfTextService.instance.createStyledText(
                      _sanitizeText('تحلیل کے لیے 1 گھنٹے کا وقت درکار ہے'),
                      fontSize: 9,
                      color: PdfColors.white,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),

                // Row 8: Receipt Warning (Black background)
                pw.Container(
                  height: 8 * PdfPageFormat.mm,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  child: pw.Center(
                    child: PdfTextService.instance.createStyledText(
                      _sanitizeText('رسید کے بغیر رزلٹ نہیں ملے گا'),
                      fontSize: 9,
                      color: PdfColors.white,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      );

      debugPrint('📄 PDF page structure built, attempting to save...');
      final pdfBytes = await pdf.save();
      debugPrint('✅ PDF successfully generated, ${pdfBytes.length} bytes');

      return pdfBytes;

    } catch (e, stackTrace) {
      debugPrint('💥 Error generating PDF: $e');
      debugPrint('Stack trace: $stackTrace');

      // Create a simple fallback PDF if the main one fails
      debugPrint('🚨 Attempting to create fallback PDF');
      return _generateFallbackPDF();
    }
  }

  /// Create a simple fallback PDF when the main generation fails
  Future<Uint8List> _generateFallbackPDF() async {
    try {
      debugPrint('🔧 Creating emergency fallback PDF');

      final pdf = pw.Document();
      final entry = widget.entry;

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            100 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Simple header
                pw.Text(
                  'POS Receipt',
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 16,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 10),

                // Entry details using system fonts only
                pw.Text(
                  'Entry #${entry.entryIndex}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 12),
                ),

                pw.Text(
                  'Customer: ${entry.name}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10),
                ),

                pw.Text(
                  'Weight: ${entry.weight?.toStringAsFixed(3) ?? '0.000'}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10),
                ),

                pw.Text(
                  'Date: ${entry.entryDate.toString().substring(0, 10)}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'This is a fallback receipt due to font rendering issues.',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      final fallbackBytes = await pdf.save();
      debugPrint('✅ Fallback PDF created successfully, ${fallbackBytes.length} bytes');
      return fallbackBytes;

    } catch (e) {
      debugPrint('💀 Even fallback PDF failed: $e');
      // Return minimal PDF data
      return Uint8List.fromList([]);
    }
  }

  /// Sanitize text to prevent PDF generation errors
  String _sanitizeText(String text) {
    return text
        .replaceAll('\n', ' ')          // Replace newlines with spaces
        .replaceAll('\r', ' ')          // Replace carriage returns
        .replaceAll('\t', ' ')          // Replace tabs with spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();                        // Remove leading/trailing spaces
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
            child: Text(
              'ٹھیک ہے',
              style: const TextStyle(fontFamily: 'NotoNastaliqUrdu'),
            ),
          ),
        ],
      ),
    );
  }
}