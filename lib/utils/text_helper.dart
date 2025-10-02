import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';

/// Helper class to easily create translated text widgets with appropriate bilingual styling
class TextHelper {
  /// Creates a translated Text widget with bilingual font styling
  static Widget translatedText(
    BuildContext context,
    String translationKey, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translatedText = Translations.get(translationKey, languageProvider.currentLanguage);
    
    return BilingualText.bilingual(
      translatedText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  
  /// Creates a heading text widget with appropriate bilingual styling
  static Widget heading(
    BuildContext context,
    String translationKey, {
    Color? color,
    TextAlign? textAlign,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translatedText = Translations.get(translationKey, languageProvider.currentLanguage);
    
    return BilingualText.bilingual(
      translatedText,
      style: BilingualTextStyles.displayMedium(translatedText, color: color),
      textAlign: textAlign,
    );
  }
  
  /// Creates a title text widget with appropriate bilingual styling
  static Widget title(
    BuildContext context,
    String translationKey, {
    Color? color,
    TextAlign? textAlign,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translatedText = Translations.get(translationKey, languageProvider.currentLanguage);
    
    return BilingualText.bilingual(
      translatedText,
      style: BilingualTextStyles.headlineMedium(translatedText, color: color),
      textAlign: textAlign,
    );
  }
  
  /// Creates a body text widget with appropriate bilingual styling
  static Widget body(
    BuildContext context,
    String translationKey, {
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translatedText = Translations.get(translationKey, languageProvider.currentLanguage);
    
    return BilingualText.bilingual(
      translatedText,
      style: BilingualTextStyles.bodyLarge(translatedText, color: color),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
  
  /// Creates a label text widget with appropriate bilingual styling
  static Widget label(
    BuildContext context,
    String translationKey, {
    Color? color,
    TextAlign? textAlign,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translatedText = Translations.get(translationKey, languageProvider.currentLanguage);
    
    return BilingualText.bilingual(
      translatedText,
      style: BilingualTextStyles.labelLarge(translatedText, color: color),
      textAlign: textAlign,
    );
  }
  
  /// Creates a text widget for displaying numbers/currency (always uses English font)
  static Widget number(
    String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: BilingualTextStyles.number(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
    );
  }
  
  /// Creates a rich text widget for mixed content (text with numbers)
  static Widget richText(
    String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
  }) {
    return RichText(
      text: TextSpan(
        children: BilingualTextStyles.mixedContent(
          text,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}