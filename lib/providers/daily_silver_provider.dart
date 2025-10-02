import 'package:flutter/material.dart';
import '../models/daily_silver.dart';
import '../services/daily_silver_service.dart';

class DailySilverProvider extends ChangeNotifier {
  DailySilver? _currentDaySilver;
  bool _isLoading = false;
  String? _error;

  // Getters
  DailySilver? get currentDaySilver => _currentDaySilver;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get silver values for current day
  double get remainingSilver => _currentDaySilver?.remainingSilver ?? 0.0;
  double get newSilver => _currentDaySilver?.newSilver ?? 0.0;
  double get presentSilver => _currentDaySilver?.presentSilver ?? 0.0;
  double get totalSilverFromEntries => _currentDaySilver?.totalSilverFromEntries ?? 0.0;

  // Initialize provider for today's date
  Future<void> initialize() async {
    await loadDailySilverForDate(DateTime.now());
  }

  // Load daily silver data for a specific date
  Future<void> loadDailySilverForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentDaySilver = await DailySilverService.getOrCreateDailySilverForDate(date);
    } catch (e) {
      _error = 'Failed to load silver data: $e';
      debugPrint('Error loading daily silver: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update new silver value for current day
  Future<bool> updateNewSilver(double newSilverValue) async {
    if (_currentDaySilver == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await DailySilverService.updateNewSilver(
        _currentDaySilver!.date,
        newSilverValue,
      );

      if (updated != null) {
        _currentDaySilver = updated;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update new silver value';
        return false;
      }
    } catch (e) {
      _error = 'Error updating new silver: $e';
      debugPrint('Error updating new silver: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh calculations when entries are added/updated
  Future<void> refreshCalculations({DateTime? forDate}) async {
    final date = forDate ?? _currentDaySilver?.date ?? DateTime.now();

    try {
      await DailySilverService.updateCalculationsForDate(date);

      // Reload current data if it's for the same date
      if (_currentDaySilver != null &&
          _currentDaySilver!.date.year == date.year &&
          _currentDaySilver!.date.month == date.month &&
          _currentDaySilver!.date.day == date.day) {
        await loadDailySilverForDate(date);
      }
    } catch (e) {
      _error = 'Failed to refresh calculations: $e';
      debugPrint('Error refreshing calculations: $e');
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get formatted string for remaining silver
  String get formattedRemainingSilver {
    return remainingSilver.toStringAsFixed(4);
  }

  // Get formatted string for new silver
  String get formattedNewSilver {
    return newSilver.toStringAsFixed(4);
  }

  // Get formatted string for present silver
  String get formattedPresentSilver {
    return presentSilver.toStringAsFixed(4);
  }

  // Check if current day has any data
  bool get hasData => _currentDaySilver != null;

  // Get current date being displayed
  DateTime get currentDate => _currentDaySilver?.date ?? DateTime.now();
}