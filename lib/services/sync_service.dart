import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sync_models.dart';
import '../models/khata_entry.dart';
import '../models/customer.dart';
import '../utils/database_helper.dart';
import '../services/khata_database_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SyncConfig? _config;
  SyncProgress _progress = const SyncProgress(
    status: SyncStatus.idle,
    type: SyncType.full,
  );

  // Getters
  SyncConfig? get config => _config;
  SyncProgress get progress => _progress;
  bool get isConfigured => _config != null && _config!.apiKey.isNotEmpty;
  bool get isSyncing => _progress.status == SyncStatus.uploading || _progress.status == SyncStatus.downloading;

  /// Initialize sync service with user configuration
  Future<void> initialize(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('sync_config_$userId');

    if (configJson != null) {
      try {
        _config = SyncConfig.fromJson(jsonDecode(configJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading sync config: $e');
      }
    }
  }

  /// Configure sync settings
  Future<void> configure(SyncConfig config) async {
    _config = config;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_config_${config.userId}', jsonEncode(config.toJson()));

    notifyListeners();
  }

  /// Update sync progress
  void _updateProgress(SyncProgress progress) {
    _progress = progress;
    notifyListeners();
  }

  /// Backup user data to server
  Future<SyncResult> backup() async {
    if (!isConfigured) {
      return SyncResult(
        success: false,
        error: 'Sync not configured',
        type: SyncType.backup,
        timestamp: DateTime.now(),
      );
    }

    try {
      _updateProgress(SyncProgress(
        status: SyncStatus.uploading,
        type: SyncType.backup,
        progress: 0.0,
        currentOperation: 'Preparing data...',
      ));

      // Collect all user data
      final dataPackage = await _collectUserData();

      _updateProgress(_progress.copyWith(
        progress: 0.3,
        currentOperation: 'Compressing data...',
      ));

      // Upload to server
      final response = await _uploadData(dataPackage);

      if (response.success) {
        // Update last sync time
        final updatedConfig = SyncConfig(
          userId: _config!.userId,
          serverUrl: _config!.serverUrl,
          apiKey: _config!.apiKey,
          autoSync: _config!.autoSync,
          syncInterval: _config!.syncInterval,
          lastSyncAt: DateTime.now(),
        );
        await configure(updatedConfig);

        _updateProgress(SyncProgress(
          status: SyncStatus.completed,
          type: SyncType.backup,
          progress: 1.0,
          currentOperation: 'Backup completed',
        ));

        // Reset to idle after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          _updateProgress(SyncProgress(
            status: SyncStatus.idle,
            type: SyncType.backup,
          ));
        });

        return SyncResult(
          success: true,
          type: SyncType.backup,
          timestamp: DateTime.now(),
          uploadedRecords: dataPackage.khataData['entries']?.length ?? 0,
          serverResponse: response.message,
        );
      } else {
        _updateProgress(SyncProgress(
          status: SyncStatus.failed,
          type: SyncType.backup,
          currentOperation: 'Backup failed: ${response.message}',
        ));

        return SyncResult(
          success: false,
          error: response.message,
          type: SyncType.backup,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _updateProgress(SyncProgress(
        status: SyncStatus.failed,
        type: SyncType.backup,
        currentOperation: 'Error: $e',
      ));

      return SyncResult(
        success: false,
        error: e.toString(),
        type: SyncType.backup,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Restore user data from server
  Future<SyncResult> restore() async {
    if (!isConfigured) {
      return SyncResult(
        success: false,
        error: 'Sync not configured',
        type: SyncType.restore,
        timestamp: DateTime.now(),
      );
    }

    try {
      _updateProgress(SyncProgress(
        status: SyncStatus.downloading,
        type: SyncType.restore,
        progress: 0.0,
        currentOperation: 'Downloading data...',
      ));

      // Download data from server
      final dataPackage = await _downloadData();

      if (dataPackage != null) {
        _updateProgress(_progress.copyWith(
          progress: 0.5,
          currentOperation: 'Restoring data...',
        ));

        // Restore data to local database
        await _restoreUserData(dataPackage);

        _updateProgress(SyncProgress(
          status: SyncStatus.completed,
          type: SyncType.restore,
          progress: 1.0,
          currentOperation: 'Restore completed',
        ));

        // Reset to idle after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          _updateProgress(SyncProgress(
            status: SyncStatus.idle,
            type: SyncType.restore,
          ));
        });

        return SyncResult(
          success: true,
          type: SyncType.restore,
          timestamp: DateTime.now(),
          downloadedRecords: dataPackage.khataData['entries']?.length ?? 0,
        );
      } else {
        _updateProgress(SyncProgress(
          status: SyncStatus.failed,
          type: SyncType.restore,
          currentOperation: 'No data found on server',
        ));

        return SyncResult(
          success: false,
          error: 'No backup data found',
          type: SyncType.restore,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _updateProgress(SyncProgress(
        status: SyncStatus.failed,
        type: SyncType.restore,
        currentOperation: 'Error: $e',
      ));

      return SyncResult(
        success: false,
        error: e.toString(),
        type: SyncType.restore,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Collect all user data for backup
  Future<UserDataPackage> _collectUserData() async {
    _updateProgress(_progress.copyWith(
      progress: 0.1,
      currentOperation: 'Collecting user data...',
    ));

    // Get user data
    final users = await DatabaseHelper.instance.getAllUsers();
    final userData = users.map((user) => user.toMap()).toList();

    _updateProgress(_progress.copyWith(
      progress: 0.15,
      currentOperation: 'Collecting khata entries...',
    ));

    // Get khata entries
    final khataDatabaseService = KhataDatabaseService();
    final allEntries = await khataDatabaseService.getAllEntriesForSync();
    final khataData = {
      'entries': allEntries.map((entry) => entry.toMap()).toList(),
    };

    _updateProgress(_progress.copyWith(
      progress: 0.2,
      currentOperation: 'Collecting customers...',
    ));

    // Get customers
    final customers = await khataDatabaseService.getAllCustomers();
    final customerData = customers.map((customer) => customer.toMap()).toList();

    _updateProgress(_progress.copyWith(
      progress: 0.25,
      currentOperation: 'Collecting settings...',
    ));

    // Get app settings
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('app_') || key.startsWith('user_') || key.startsWith('theme_')) {
        final value = prefs.get(key);
        if (value != null) settings[key] = value;
      }
    }

    return UserDataPackage(
      userId: _config!.userId,
      timestamp: DateTime.now(),
      userData: {'users': userData},
      khataData: khataData,
      customers: {'customers': customerData},
      settings: settings,
      appVersion: '1.0.0', // TODO: Get from package info
    );
  }

  /// Upload data to server
  Future<ApiResponse> _uploadData(UserDataPackage dataPackage) async {
    try {
      final uri = Uri.parse('${_config!.serverUrl}/api/sync/backup');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiKey}',
          'X-User-ID': _config!.userId,
        },
        body: dataPackage.toJsonString(),
      );

      _updateProgress(_progress.copyWith(
        progress: 0.8,
        currentOperation: 'Processing server response...',
      ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.fromJson(responseData);
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Download data from server
  Future<UserDataPackage?> _downloadData() async {
    try {
      final uri = Uri.parse('${_config!.serverUrl}/api/sync/restore');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey}',
          'X-User-ID': _config!.userId,
        },
      );

      _updateProgress(_progress.copyWith(
        progress: 0.3,
        currentOperation: 'Processing downloaded data...',
      ));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return UserDataPackage.fromJson(responseData['data']);
        }
      } else if (response.statusCode == 404) {
        return null; // No backup found
      }

      throw Exception('Failed to download data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Restore data to local database
  Future<void> _restoreUserData(UserDataPackage dataPackage) async {
    final khataDatabaseService = KhataDatabaseService();

    _updateProgress(_progress.copyWith(
      progress: 0.6,
      currentOperation: 'Restoring khata entries...',
    ));

    // Clear existing data (optional - you might want to merge instead)
    // await khataDatabaseService.clearAllData();

    // Restore khata entries
    if (dataPackage.khataData['entries'] != null) {
      final entries = (dataPackage.khataData['entries'] as List)
          .map((json) => KhataEntry.fromMap(json))
          .toList();

      for (final entry in entries) {
        await khataDatabaseService.addEntry(entry);
      }
    }

    _updateProgress(_progress.copyWith(
      progress: 0.8,
      currentOperation: 'Restoring customers...',
    ));

    // Restore customers
    if (dataPackage.customers['customers'] != null) {
      final customers = (dataPackage.customers['customers'] as List)
          .map((json) => Customer.fromMap(json))
          .toList();

      for (final customer in customers) {
        await khataDatabaseService.addCustomer(customer);
      }
    }

    _updateProgress(_progress.copyWith(
      progress: 0.9,
      currentOperation: 'Restoring settings...',
    ));

    // Restore settings
    final prefs = await SharedPreferences.getInstance();
    for (final entry in dataPackage.settings.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      }
    }
  }

  /// Check if auto-sync should run
  bool shouldAutoSync() {
    if (!isConfigured || !_config!.autoSync || _config!.lastSyncAt == null) {
      return false;
    }

    final nextSync = _config!.lastSyncAt!.add(_config!.syncInterval);
    return DateTime.now().isAfter(nextSync);
  }

  /// Get sync status text
  String getStatusText() {
    switch (_progress.status) {
      case SyncStatus.idle:
        if (_config?.lastSyncAt != null) {
          final lastSync = _config!.lastSyncAt!;
          final now = DateTime.now();
          final difference = now.difference(lastSync);

          if (difference.inDays > 0) {
            return 'Last sync: ${difference.inDays} days ago';
          } else if (difference.inHours > 0) {
            return 'Last sync: ${difference.inHours} hours ago';
          } else {
            return 'Last sync: ${difference.inMinutes} minutes ago';
          }
        }
        return 'Never synced';
      case SyncStatus.uploading:
        return 'Uploading data...';
      case SyncStatus.downloading:
        return 'Downloading data...';
      case SyncStatus.completed:
        return 'Sync completed successfully';
      case SyncStatus.failed:
        return 'Sync failed';
    }
  }
}