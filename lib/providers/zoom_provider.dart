import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZoomProvider extends ChangeNotifier {
  static const String _zoomLevelKey = 'zoom_level';
  static const double _defaultZoomLevel = 1.0;
  static const double _minZoomLevel = 0.5;
  static const double _maxZoomLevel = 2.0;
  static const double _zoomIncrement = 0.1;

  double _zoomLevel = _defaultZoomLevel;
  SharedPreferences? _prefs;

  double get zoomLevel => _zoomLevel;
  double get minZoomLevel => _minZoomLevel;
  double get maxZoomLevel => _maxZoomLevel;

  /// Initialize zoom provider and load saved zoom level
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _zoomLevel = _prefs?.getDouble(_zoomLevelKey) ?? _defaultZoomLevel;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing zoom provider: $e');
      _zoomLevel = _defaultZoomLevel;
    }
  }

  /// Zoom in by one increment
  void zoomIn() {
    final newZoomLevel = (_zoomLevel + _zoomIncrement).clamp(_minZoomLevel, _maxZoomLevel);
    _setZoomLevel(newZoomLevel);
  }

  /// Zoom out by one increment
  void zoomOut() {
    final newZoomLevel = (_zoomLevel - _zoomIncrement).clamp(_minZoomLevel, _maxZoomLevel);
    _setZoomLevel(newZoomLevel);
  }

  /// Set specific zoom level
  void setZoomLevel(double level) {
    final clampedLevel = level.clamp(_minZoomLevel, _maxZoomLevel);
    _setZoomLevel(clampedLevel);
  }

  /// Reset zoom to default level
  void resetZoom() {
    _setZoomLevel(_defaultZoomLevel);
  }

  /// Internal method to set zoom level and persist it
  void _setZoomLevel(double level) {
    if (_zoomLevel != level) {
      _zoomLevel = level;
      _saveZoomLevel();
      notifyListeners();
    }
  }

  /// Save zoom level to shared preferences
  Future<void> _saveZoomLevel() async {
    try {
      await _prefs?.setDouble(_zoomLevelKey, _zoomLevel);
    } catch (e) {
      debugPrint('Error saving zoom level: $e');
    }
  }

  /// Get zoom level as percentage string for display
  String get zoomPercentage => '${(_zoomLevel * 100).round()}%';
}