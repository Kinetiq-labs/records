import 'package:flutter/material.dart';

/// Utility class for handling bilingual text styles with appropriate fonts
/// Uses Noto Sans for English/Latin text and Noto Nastaliq Urdu for Urdu text
class BilingualTextStyles {
  // Font families
  static const String notoSans = 'NotoSans';
  static const String notoNastaliqUrdu = 'NotoNastaliqUrdu';
  static const String roboto = 'Roboto'; // Fallback
  
  /// Determines if text contains Urdu characters
  static bool containsUrdu(String text) {
    // Urdu Unicode ranges:
    // Arabic: U+0600-U+06FF
    // Arabic Supplement: U+0750-U+077F
    // Arabic Extended-A: U+08A0-U+08FF
    // Arabic Presentation Forms-A: U+FB50-U+FDFF
    // Arabic Presentation Forms-B: U+FE70-U+FEFF
    final urduRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return urduRegex.hasMatch(text);
  }
  
  /// Returns appropriate font family based on text content
  static String getFontFamily(String text) {
    return containsUrdu(text) ? notoNastaliqUrdu : notoSans;
  }
  
  /// Creates TextStyle with appropriate font and improved readability
  static TextStyle getTextStyle({
    required String text,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    final isUrdu = containsUrdu(text);

    return TextStyle(
      fontFamily: getFontFamily(text),
      fontSize: fontSize ?? (isUrdu ? 20.0 : 18.0), // Slightly larger for Urdu readability
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      letterSpacing: letterSpacing ?? (isUrdu ? 0.2 : 0.1), // Better spacing for Urdu
      height: height ?? (isUrdu ? 1.6 : 1.4), // Better line height for Urdu
      decoration: decoration ?? TextDecoration.none, // Prevent yellow underlines
    );
  }
  
  // Predefined styles for common use cases
  
  /// Display Large - for main headings
  static TextStyle displayLarge(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 36.0 : 32.0,
    fontWeight: FontWeight.bold,
    color: color,
    height: containsUrdu(text) ? 1.5 : 1.3,
  );
  
  /// Display Medium - for section headings
  static TextStyle displayMedium(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 32.0 : 28.0,
    fontWeight: FontWeight.bold,
    color: color,
    height: containsUrdu(text) ? 1.5 : 1.3,
  );
  
  /// Display Small - for subsection headings
  static TextStyle displaySmall(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 28.0 : 24.0,
    fontWeight: FontWeight.w600,
    color: color,
    height: containsUrdu(text) ? 1.5 : 1.3,
  );
  
  /// Headline Large - for card titles
  static TextStyle headlineLarge(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 26.0 : 22.0,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  /// Headline Medium - for dialog titles
  static TextStyle headlineMedium(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 24.0 : 20.0,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  /// Headline Small - for list item titles
  static TextStyle headlineSmall(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 22.0 : 18.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Title Large - for app bar titles
  static TextStyle titleLarge(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 24.0 : 20.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Title Medium - for button text
  static TextStyle titleMedium(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 22.0 : 18.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Title Small - for small button text
  static TextStyle titleSmall(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 20.0 : 16.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Body Large - for main content
  static TextStyle bodyLarge(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 22.0 : 18.0,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  /// Body Medium - for secondary content
  static TextStyle bodyMedium(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 20.0 : 16.0,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  /// Body Small - for captions and fine print
  static TextStyle bodySmall(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 18.0 : 14.0,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  /// Label Large - for form labels
  static TextStyle labelLarge(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 20.0 : 16.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Label Medium - for chip labels
  static TextStyle labelMedium(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 18.0 : 14.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Label Small - for very small labels
  static TextStyle labelSmall(String text, {Color? color}) => getTextStyle(
    text: text,
    fontSize: containsUrdu(text) ? 16.0 : 12.0,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  /// Special style for numbers and currency (always use English font)
  static TextStyle number({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) => TextStyle(
    fontFamily: notoSans,
    fontSize: fontSize ?? 18.0,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color,
    letterSpacing: 0.5, // Better spacing for numbers
    decoration: TextDecoration.none, // Prevent yellow underlines
  );
  
  /// Style for mixed content (text with numbers)
  static List<TextSpan> mixedContent(
    String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final spans = <TextSpan>[];
    final numberRegex = RegExp(r'[\d.,]+');
    
    int lastIndex = 0;
    for (final match in numberRegex.allMatches(text)) {
      // Add text before number
      if (match.start > lastIndex) {
        final textPart = text.substring(lastIndex, match.start);
        spans.add(TextSpan(
          text: textPart,
          style: getTextStyle(
            text: textPart,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ));
      }
      
      // Add number with English font
      spans.add(TextSpan(
        text: match.group(0),
        style: number(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      final textPart = text.substring(lastIndex);
      spans.add(TextSpan(
        text: textPart,
        style: getTextStyle(
          text: textPart,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ));
    }
    
    return spans;
  }
}

/// Extension to easily apply bilingual styles to Text widgets
extension BilingualText on Text {
  /// Creates a Text widget with appropriate bilingual styling
  static Text bilingual(
    String text, {
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    final defaultStyle = BilingualTextStyles.getTextStyle(text: text);
    final finalStyle = style != null 
        ? defaultStyle.merge(style.copyWith(fontFamily: BilingualTextStyles.getFontFamily(text)))
        : defaultStyle;
    
    return Text(
      text,
      key: key,
      style: finalStyle,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}