import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en'; // Default to English
  
  String get currentLanguage => _currentLanguage;
  bool get isUrdu => _currentLanguage == 'ur';
  bool get isEnglish => _currentLanguage == 'en';

  // Initialize language from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  // Toggle between English and Urdu
  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'en' ? 'ur' : 'en';
    
    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    
    notifyListeners();
  }

  // Set specific language
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _currentLanguage) {
      _currentLanguage = languageCode;
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _currentLanguage);
      
      notifyListeners();
    }
  }

  // Get text direction for Urdu (right-to-left)
  TextDirection get textDirection {
    return _currentLanguage == 'ur' ? TextDirection.rtl : TextDirection.ltr;
  }

  // Get locale for the current language
  Locale get locale {
    return Locale(_currentLanguage);
  }
}