class TextTranslationService {
  static final TextTranslationService _instance = TextTranslationService._internal();
  factory TextTranslationService() => _instance;
  TextTranslationService._internal();

  // Urdu to English number translation
  static const Map<String, String> _urduToEnglishNumbers = {
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  };


  // Common Urdu words/phrases that might be used in names or details
  static const Map<String, String> _urduToEnglishWords = {
    // Common names and terms
    'احمد': 'Ahmad',
    'علی': 'Ali', 
    'محمد': 'Muhammad',
    'حسن': 'Hassan',
    'حسین': 'Hussain',
    'فاطمہ': 'Fatima',
    'عائشہ': 'Ayesha',
    'خدیجہ': 'Khadija',
    'زینب': 'Zainab',
    'مریم': 'Maryam',
    
    // Business terms
    'کاروبار': 'Business',
    'دکان': 'Shop',
    'گاہک': 'Customer',
    'خریدار': 'Buyer',
    'بیچنے والا': 'Seller',
    'لین دین': 'Transaction',
    'ادھار': 'Credit',
    'نقد': 'Cash',
    'قرض': 'Debt',
    'رقم': 'Amount',
    
    // Gold/Silver terms
    'سونا': 'Gold',
    'چاندی': 'Silver',
    'زیور': 'Jewelry',
    'انگوٹھی': 'Ring',
    'ہار': 'Necklace',
    'کنگن': 'Bracelet',
    'بالیاں': 'Earrings',
    'چین': 'Chain',
    
    // Weights and measures
    'تولہ': 'Tola',
    'گرام': 'Gram',
    'کلو': 'Kilo',
    'پونڈ': 'Pound',
    'اونس': 'Ounce',
    
    // Common words
    'نام': 'Name',
    'پتہ': 'Address',
    'فون': 'Phone',
    'نمبر': 'Number',
    'تاریخ': 'Date',
    'وقت': 'Time',
    'دن': 'Day',
    'مہینہ': 'Month',
    'سال': 'Year',
    'آج': 'Today',
    'کل': 'Tomorrow',
    'گذشتہ': 'Previous',
    'اگلا': 'Next',
    
    // Status terms
    'مکمل': 'Complete',
    'ادھورا': 'Incomplete',
    'بقایا': 'Pending',
    'ادا شدہ': 'Paid',
    'واپس': 'Return',
    'نیا': 'New',
    'پرانا': 'Old',
    'موجودہ': 'Current',
    
    // Description terms
    'تفصیل': 'Detail',
    'وضاحت': 'Description',
    'نوٹ': 'Note',
    'یاد داشت': 'Memo',
    'تبصرہ': 'Comment',
  };

  // English to Urdu words (for display purposes)
  static final Map<String, String> _englishToUrduWords = 
      _urduToEnglishWords.map((urdu, english) => MapEntry(english, urdu));

  /// Convert Urdu text to English for database storage
  String translateToEnglish(String text, String currentLanguage) {
    if (currentLanguage != 'ur') {
      return text; // Already in English or other language
    }

    String result = text;

    // 1. Convert Urdu/Arabic numerals to English numerals
    _urduToEnglishNumbers.forEach((urdu, english) {
      result = result.replaceAll(urdu, english);
    });

    // 2. Translate common Urdu words to English
    _urduToEnglishWords.forEach((urdu, english) {
      // Use word boundary regex to avoid partial matches
      final regex = RegExp(r'\b' + RegExp.escape(urdu) + r'\b');
      result = result.replaceAll(regex, english);
    });

    // 3. Handle mixed content (keep English parts as is)
    // This preserves any English text that might be mixed with Urdu

    return result.trim();
  }

  /// Convert English text to Urdu for display purposes
  String translateToUrdu(String text, String currentLanguage) {
    if (currentLanguage != 'ur') {
      return text; // Don't translate if not in Urdu mode
    }

    String result = text;

    // Numbers always stay in English format (0-9) - NEVER convert to Urdu numerals
    // This ensures all numbers display in English regardless of UI language
    
    // Translate only words, not numbers
    _englishToUrduWords.forEach((english, urdu) {
      final regex = RegExp(r'\b' + RegExp.escape(english) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, urdu);
    });

    return result;
  }

  /// Clean and normalize text input
  String normalizeText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF\u0750-\u077F.]'), '') // Keep only letters, numbers, spaces, and basic punctuation
        .trim();
  }

  /// Check if text contains Urdu characters
  bool containsUrdu(String text) {
    // Check for Arabic/Urdu Unicode ranges
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(text);
  }

  /// Check if text contains only numbers (in any script)
  bool isNumericOnly(String text) {
    // Remove spaces and check if all characters are numeric (English or Urdu)
    final cleanText = text.replaceAll(' ', '');
    return RegExp(r'^[\d۰-۹٠-٩.]+$').hasMatch(cleanText);
  }

  /// Convert numeric string from any script to English numbers
  String normalizeNumbers(String text) {
    String result = text;
    _urduToEnglishNumbers.forEach((urdu, english) {
      result = result.replaceAll(urdu, english);
    });
    return result;
  }

  /// Validate and convert input based on field type
  String processFieldInput(String input, String fieldType, String currentLanguage) {
    String processed = normalizeText(input);
    
    switch (fieldType) {
      case 'name':
      case 'detail':
        // For text fields, translate Urdu to English for storage
        return translateToEnglish(processed, currentLanguage);
        
      case 'number':
      case 'weight':
      case 'return_weight_1':
      case 'first_weight':
      case 'silver':
      case 'return_weight_2':
      case 'nalki':
        // For numeric fields, only convert numbers
        return normalizeNumbers(processed);
        
      default:
        return processed;
    }
  }

  /// Get display text (translate from English to current language)
  String getDisplayText(String storedText, String currentLanguage) {
    if (currentLanguage == 'ur') {
      return translateToUrdu(storedText, currentLanguage);
    }
    return storedText;
  }

  /// Add new translation mappings (for admin customization)
  void addTranslation(String urdu, String english) {
    // This could be extended to allow dynamic translation additions
    // For now, translations are static but this provides extension point
  }

  /// Get translation statistics
  Map<String, int> getTranslationStats() {
    return {
      'total_urdu_words': _urduToEnglishWords.length,
      'total_number_mappings': _urduToEnglishNumbers.length,
    };
  }

  /// Validate translation quality (for debugging)
  Map<String, dynamic> validateTranslation(String original, String translated, String language) {
    return {
      'original': original,
      'translated': translated,
      'language': language,
      'contains_urdu': containsUrdu(original),
      'is_numeric': isNumericOnly(original),
      'length_difference': (original.length - translated.length).abs(),
    };
  }
}