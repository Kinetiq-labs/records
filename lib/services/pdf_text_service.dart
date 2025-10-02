import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import 'package:dartarabic/dartarabic.dart';

/// Represents a segment of text with language information
class TextSegment {
  final String text;
  final bool isUrdu;

  TextSegment({required this.text, required this.isUrdu});

  @override
  String toString() => 'TextSegment(text: "$text", isUrdu: $isUrdu)';
}

class PdfTextService {
  static PdfTextService? _instance;
  static PdfTextService get instance => _instance ??= PdfTextService._();
  PdfTextService._();

  pw.Font? _urduFont;
  pw.Font? _englishFont;
  pw.Font? _englishBoldFont;

  // Separate fallback fonts for font fallback system
  pw.Font? _englishFallback;

  bool _fontsLoaded = false;

  /// Initialize fonts using Scheherazade New - complete Urdu+English support with Arabic Presentation Forms
  Future<void> initializeFonts() async {
    if (_fontsLoaded) return;

    try {
      debugPrint('=== Loading Scheherazade New (Arabic Presentation Forms) ===');

      pw.Font? unifiedFont;
      pw.Font? unifiedBoldFont;

      try {
        debugPrint('Loading Scheherazade New fonts with Arabic Presentation Forms support...');

        // Load Scheherazade New font - has complete Arabic Presentation Forms coverage
        final scheherazadeFontData = await rootBundle.load("fonts/ScheherazadeNew-Regular.ttf");
        final scheherazadeFont = pw.Font.ttf(scheherazadeFontData);
        debugPrint('✅ Scheherazade New Regular loaded: ${scheherazadeFontData.lengthInBytes} bytes');

        // Load Scheherazade New Bold
        final scheherazadeBoldFontData = await rootBundle.load("fonts/ScheherazadeNew-Bold.ttf");
        final scheherazadeBoldFont = pw.Font.ttf(scheherazadeBoldFontData);
        debugPrint('✅ Scheherazade New Bold loaded: ${scheherazadeBoldFontData.lengthInBytes} bytes');

        // Load Roboto for English fallback (for better Latin character rendering)
        final englishFontData = await rootBundle.load("fonts/Roboto-Regular.ttf");
        final englishFont = pw.Font.ttf(englishFontData);
        debugPrint('✅ Roboto fonts loaded for English fallback');

        // Set up font system - Scheherazade New can handle both Arabic Presentation Forms and English
        unifiedFont = scheherazadeFont;      // Primary: Scheherazade New (supports reshaped Arabic)
        unifiedBoldFont = scheherazadeBoldFont;

        // Store fallback fonts for additional English support
        _englishFallback = englishFont;

      } catch (e) {
        debugPrint('❌ Failed to load fonts: $e');

        // Emergency fallback to system fonts
        debugPrint('⚠️ Using system fonts as fallback');
        unifiedFont = pw.Font.helvetica();
        unifiedBoldFont = pw.Font.helveticaBold();
      }

      // Set up SCHEHERAZADE NEW FONT system
      _urduFont = unifiedFont;         // Primary: Scheherazade New (supports Arabic Presentation Forms)
      _englishFont = _englishFallback ?? unifiedFont;  // Enhanced: Roboto for English
      _englishBoldFont = unifiedBoldFont;

      _fontsLoaded = true;
      debugPrint('✅ SCHEHERAZADE NEW FONT SYSTEM: Arabic Presentation Forms + English support');
      debugPrint('Primary: ${unifiedFont == pw.Font.helvetica() ? "Helvetica (fallback)" : "Scheherazade New (supports reshaped Arabic)"}');
      debugPrint('Fallback: ${_englishFallback != null ? "Roboto for enhanced English" : "Scheherazade New handles all"}');

    } catch (e) {
      debugPrint('💥 Critical error in font loading: $e');
      // Emergency fallback
      _urduFont = pw.Font.helvetica();
      _englishFont = pw.Font.helvetica();
      _englishBoldFont = pw.Font.helveticaBold();
      _fontsLoaded = true;
    }
  }

  /// Check if a character is Urdu/Arabic
  bool _isUrduCharacter(String char) {
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||  // Arabic
           (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||  // Arabic Supplement
           (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||  // Arabic Presentation Forms-A
           (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF);    // Arabic Presentation Forms-B
  }

  /// Create text using unified NotoSans font - handles Urdu+English in one font
  pw.Widget createStyledText(
    String text, {
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    try {
      if (!_fontsLoaded) {
        throw Exception('Fonts not initialized. Call initializeFonts() first.');
      }

      debugPrint('🔤 Creating text with Scheherazade New font (Arabic Presentation Forms): "$text"');

      final cleanText = _cleanText(text);
      if (cleanText.isEmpty) {
        debugPrint('⚠️ Clean text is empty, returning container');
        return pw.Container();
      }

      // Check for RTL text direction
      final hasUrdu = cleanText.split('').any(_isUrduCharacter);
      debugPrint('📝 Text direction: ${hasUrdu ? "RTL (Urdu detected)" : "LTR (English)"}');

      // Create comprehensive fallback font list for additional support
      final fallbackFonts = <pw.Font>[
        if (_englishFallback != null) _englishFallback!,  // Roboto for enhanced Latin
        pw.Font.helvetica(),                              // System fallback
        pw.Font.courier(),                                // Additional fallback
      ];

      // Use Scheherazade New font system - handles reshaped Arabic Presentation Forms
      final primaryFont = fontWeight == pw.FontWeight.bold ? _englishBoldFont : _urduFont;

      return pw.Text(
        cleanText,
        style: pw.TextStyle(
          font: primaryFont,              // Primary: Scheherazade New (supports Arabic Presentation Forms)
          fontFallback: fallbackFonts,    // Enhanced: Roboto + system fonts
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: hasUrdu ? pw.TextAlign.right : textAlign,
        textDirection: hasUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      );

    } catch (e) {
      debugPrint('💥 Error in createStyledText: $e');
      debugPrint('🚨 Using emergency fallback for: "$text"');
      return createFallbackText(
        text,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        textAlign: textAlign,
      );
    }
  }

  /// Clean and shape Arabic/Urdu text for proper PDF rendering
  String _cleanText(String text) {
    // First clean control characters
    String cleanedText = text
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '') // Remove control chars
        .replaceAll(RegExp(r'[\uFEFF\u200B-\u200D\u061C]'), '') // Remove zero-width chars
        .trim();

    // Check if text contains Arabic/Urdu characters
    final hasUrdu = cleanedText.split('').any(_isUrduCharacter);

    if (hasUrdu) {
      try {
        debugPrint('🔤 Processing Arabic/Urdu text: "$cleanedText"');

        // Check if this is mixed content (Arabic + Latin)
        final hasLatin = cleanedText.split('').any((char) =>
            char.codeUnitAt(0) >= 0x0041 && char.codeUnitAt(0) <= 0x007A ||
            char.codeUnitAt(0) >= 0x0041 && char.codeUnitAt(0) <= 0x005A);

        String processedText = cleanedText;

        // Normalize Arabic text
        processedText = DartArabic.normalizeAlef(processedText);
        processedText = DartArabic.normalizeHamzaTasheel(processedText);
        processedText = DartArabic.normalizeLetters(processedText);
        processedText = DartArabic.normalizeLigature(processedText);

        if (hasLatin) {
          // For mixed content, don't apply bidi algorithm - let PDF handle it
          // The issue is that bidi.logicalToVisual reverses everything
          debugPrint('✅ Mixed content - using normalized text as-is: "$processedText"');
          return processedText;
        } else {
          // For pure Arabic/Urdu, return normalized text as-is
          debugPrint('✅ Pure Arabic text normalized: "$processedText"');
          return processedText;
        }

      } catch (e) {
        debugPrint('⚠️ Arabic processing failed, using original: $e');
        return cleanedText;
      }
    }

    return cleanedText;
  }

  /// Create table cell with text support
  pw.Widget createTableCell(
    String text, {
    double fontSize = 10,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
    pw.TextAlign textAlign = pw.TextAlign.left,
    pw.EdgeInsets padding = const pw.EdgeInsets.all(4),
  }) {
    return pw.Container(
      padding: padding,
      child: createStyledText(
        text,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        textAlign: textAlign,
      ),
    );
  }

  /// Get appropriate font for text content
  pw.Font? getFontForText(String text, {bool bold = false}) {
    if (!_fontsLoaded) return null;

    final hasUrdu = text.split('').any(_isUrduCharacter);
    if (hasUrdu) {
      return _urduFont;  // Scheherazade New for Urdu/Arabic text (supports Presentation Forms)
    }
    return _englishFallback ?? (bold ? _englishBoldFont : _englishFont);  // Roboto for enhanced English
  }

  /// Create simple fallback text that always works (emergency method)
  pw.Widget createFallbackText(
    String text, {
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    // Use only system fonts that are guaranteed to work
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: fontWeight == pw.FontWeight.bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      textDirection: pw.TextDirection.ltr,
    );
  }

  /// Force reinitialize fonts (for testing)
  void resetFonts() {
    _fontsLoaded = false;
    _urduFont = null;
    _englishFont = null;
    _englishBoldFont = null;
    _englishFallback = null;
  }
}