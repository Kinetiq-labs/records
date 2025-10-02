import 'package:flutter/foundation.dart';
import '../models/sync_models.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();

  // Getters
  SyncConfig? get config => _syncService.config;
  SyncProgress get progress => _syncService.progress;
  bool get isConfigured => _syncService.isConfigured;
  bool get isSyncing => _syncService.isSyncing;
  String get statusText => _syncService.getStatusText();

  SyncProvider() {
    _syncService.addListener(_onSyncServiceChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncServiceChanged);
    super.dispose();
  }

  void _onSyncServiceChanged() {
    notifyListeners();
  }

  /// Initialize sync for a user
  Future<void> initialize(String userId) async {
    await _syncService.initialize(userId);
    notifyListeners();
  }

  /// Configure sync settings
  Future<void> configure(SyncConfig config) async {
    await _syncService.configure(config);
    notifyListeners();
  }

  /// Backup data to server
  Future<SyncResult> backup() async {
    final result = await _syncService.backup();
    notifyListeners();
    return result;
  }

  /// Restore data from server
  Future<SyncResult> restore() async {
    final result = await _syncService.restore();
    notifyListeners();
    return result;
  }

  /// Check if auto-sync should run
  bool shouldAutoSync() => _syncService.shouldAutoSync();

  /// Update sync configuration
  Future<void> updateConfig({
    String? serverUrl,
    String? apiKey,
    bool? autoSync,
    Duration? syncInterval,
  }) async {
    if (config == null) return;

    final updatedConfig = SyncConfig(
      userId: config!.userId,
      serverUrl: serverUrl ?? config!.serverUrl,
      apiKey: apiKey ?? config!.apiKey,
      autoSync: autoSync ?? config!.autoSync,
      syncInterval: syncInterval ?? config!.syncInterval,
      lastSyncAt: config!.lastSyncAt,
    );

    await configure(updatedConfig);
  }

  /// Clear sync configuration
  Future<void> clearConfig() async {
    // This would require implementing clear functionality in SyncService
    notifyListeners();
  }
}