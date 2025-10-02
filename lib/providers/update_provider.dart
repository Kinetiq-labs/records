import 'package:flutter/material.dart';
import '../services/app_update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  installing,
  error,
  upToDate,
}

class UpdateProvider extends ChangeNotifier {
  final AppUpdateService _updateService = AppUpdateService();

  UpdateStatus _status = UpdateStatus.idle;
  String? _currentVersion;
  String? _latestVersion;
  String? _releaseNotes;
  String? _downloadUrl;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  bool _autoCheckEnabled = true;

  UpdateStatus get status => _status;
  String? get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
  String? get releaseNotes => _releaseNotes;
  String? get downloadUrl => _downloadUrl;
  String? get errorMessage => _errorMessage;
  double get downloadProgress => _downloadProgress;
  bool get autoCheckEnabled => _autoCheckEnabled;

  bool get hasUpdate => _status == UpdateStatus.updateAvailable;
  bool get isWorking => _status == UpdateStatus.checking ||
                       _status == UpdateStatus.downloading ||
                       _status == UpdateStatus.installing;

  Future<void> initialize() async {
    try {
      _currentVersion = await _updateService.getCurrentVersion();
      notifyListeners();

      // Check for updates on initialization if auto-check is enabled
      // Skip during development (when no proper update server is available)
      if (_autoCheckEnabled && _currentVersion != '1.0.0+1') {
        // Only check if a valid update URL is configured
        final updateUrl = await getUpdateUrl();
        if (updateUrl.isNotEmpty) {
          await checkForUpdates();
        }
      }
    } catch (e) {
      debugPrint('Error initializing UpdateProvider: $e');
    }
  }

  Future<void> checkForUpdates({bool force = false}) async {
    if (_status == UpdateStatus.checking) return;

    try {
      _status = UpdateStatus.checking;
      _errorMessage = null;
      notifyListeners();

      // Check if we should skip checking due to delay or recent check
      if (!force && !await _updateService.shouldCheckForUpdates()) {
        _status = UpdateStatus.idle;
        notifyListeners();
        return;
      }

      final updateInfo = await _updateService.checkForUpdates();

      if (updateInfo == null) {
        _status = UpdateStatus.idle;
        notifyListeners();
        return;
      }

      _currentVersion = updateInfo['current_version'];
      _latestVersion = updateInfo['latest_version'];
      _releaseNotes = updateInfo['release_notes'] ?? '';
      _downloadUrl = updateInfo['download_url'];

      if (updateInfo['has_update'] == true) {
        _status = UpdateStatus.updateAvailable;
      } else {
        _status = UpdateStatus.upToDate;
      }

      notifyListeners();
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('Error checking for updates: $e');
    }
  }

  Future<void> downloadAndInstallUpdate() async {
    if (_downloadUrl == null || _status != UpdateStatus.updateAvailable) {
      return;
    }

    try {
      _status = UpdateStatus.downloading;
      _downloadProgress = 0.0;
      _errorMessage = null;
      notifyListeners();

      // Simulate download progress updates
      final success = await _updateService.downloadAndInstallUpdate(
        _downloadUrl!,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      if (success) {
        _status = UpdateStatus.installing;
        notifyListeners();

        // The app should exit and restart after successful installation
        // This code might not be reached if the app restarts
      } else {
        _status = UpdateStatus.error;
        _errorMessage = 'Failed to download or install update';
        notifyListeners();
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('Error downloading/installing update: $e');
    }
  }

  Future<void> delayUpdate() async {
    try {
      await _updateService.delayUpdateFor24Hours();
      _status = UpdateStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('Error delaying update: $e');
    }
  }

  Future<void> setUpdateUrl(String url) async {
    try {
      await _updateService.setUpdateUrl(url);
    } catch (e) {
      debugPrint('Error setting update URL: $e');
    }
  }

  Future<String> getUpdateUrl() async {
    try {
      return await _updateService.getUpdateUrl();
    } catch (e) {
      debugPrint('Error getting update URL: $e');
      return AppUpdateService.defaultUpdateUrl ?? '';
    }
  }

  void setAutoCheckEnabled(bool enabled) {
    _autoCheckEnabled = enabled;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == UpdateStatus.error) {
      _status = UpdateStatus.idle;
    }
    notifyListeners();
  }

  void reset() {
    _status = UpdateStatus.idle;
    _currentVersion = null;
    _latestVersion = null;
    _releaseNotes = null;
    _downloadUrl = null;
    _errorMessage = null;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  Future<void> clearDelayedUpdate() async {
    try {
      await _updateService.clearDelayedUpdate();
    } catch (e) {
      debugPrint('Error clearing delayed update: $e');
    }
  }

  // Method to manually trigger update check (for settings or manual refresh)
  Future<void> forceCheckForUpdates() async {
    await checkForUpdates(force: true);
  }

}