import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/sync_models.dart';
import '../models/khata_entry.dart';
import '../models/customer.dart';
import '../services/auth_helper.dart';
import 'khata_database_service.dart';

class SupabaseSyncService extends ChangeNotifier {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal();

  final KhataDatabaseService _localDb = KhataDatabaseService();
  SupabaseClient? _supabase;

  // Sync state
  SyncProgress _currentProgress = const SyncProgress(
    status: SyncStatus.idle,
    type: SyncType.full,
  );

  SyncStatistics? _lastSyncStats;
  StreamSubscription? _syncSubscription;

  // Getters
  SyncProgress get currentProgress => _currentProgress;
  SyncStatistics? get lastSyncStats => _lastSyncStats;
  bool get isAuthenticated {
    try {
      return _supabase != null && AuthHelper.isAuthenticated;
    } catch (e) {
      return false;
    }
  }
  String? get currentUserId {
    try {
      return AuthHelper.currentUserId;
    } catch (e) {
      return null;
    }
  }

  // Initialize Supabase
  Future<void> initialize() async {
    try {
      await SupabaseConfig.initialize();
      _supabase = SupabaseConfig.client;
      notifyListeners();
    } catch (e) {
      _supabase = null;
      notifyListeners();
      // Error handled silently - UI will show appropriate state
    }
  }

  // Sign in anonymously for backup functionality
  Future<bool> signInAnonymously() async {
    try {
      // Try anonymous authentication first
      if (_supabase != null) {
        final response = await _supabase!.auth.signInAnonymously();
        if (response.user != null) {
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      // If anonymous auth fails, try the email-based approach
      try {
        final response = await AuthHelper.signInAnonymously();
        if (response != null && response.user != null) {
          notifyListeners();
          return true;
        }
      } catch (emailError) {
        // Both authentication methods failed
        // Error will be shown in UI with helpful message
      }

      return false;
    }
  }

  // Sign in with email and password credentials
  Future<bool> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting Supabase authentication...');
      print('📧 Email: $email');
      print('🔗 Supabase URL: ${SupabaseConfig.supabaseUrl}');

      // Initialize Supabase if not already done
      if (_supabase == null) {
        print('⚡ Initializing Supabase client...');
        await initialize();
      }

      // Authenticate with user credentials
      print('🔑 Signing in with credentials...');
      final response = await AuthHelper.signInWithEmail(
        email: email,
        password: password,
      );

      if (response != null && response.user != null) {
        print('✅ Authentication successful!');
        print('👤 User ID: ${response.user!.id}');
        print('📧 User Email: ${response.user!.email}');
        print('⏰ Last Sign In: ${response.user!.lastSignInAt}');

        _updateProgress(
          _currentProgress.copyWith(
            status: SyncStatus.idle,
            currentOperation: 'Connected to sync service',
          ),
        );
        notifyListeners();
        return true;
      } else {
        print('❌ Authentication failed: No user returned');
        return false;
      }
    } catch (e) {
      print('🚨 Authentication error: $e');
      print('📋 Error type: ${e.runtimeType}');

      _updateProgress(
        _currentProgress.copyWith(
          status: SyncStatus.failed,
          currentOperation: 'Authentication failed: ${e.toString()}',
        ),
      );
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await AuthHelper.signOut();
      notifyListeners();
    } catch (e) {
      // Sign out error handled silently
    }
  }

  // Main sync function
  Future<SyncResult> syncData({
    required String tenantId,
    SyncType type = SyncType.full,
    ConflictResolution conflictResolution = ConflictResolution.localWins,
  }) async {
    if (_supabase == null || !isAuthenticated) {
      return SyncResult(
        success: false,
        error: 'Sync service not initialized or user not authenticated',
        type: type,
        timestamp: DateTime.now(),
      );
    }

    final syncStats = SyncStatistics(syncStartTime: DateTime.now());
    _lastSyncStats = syncStats;

    try {
      _updateProgress(SyncProgress(
        status: SyncStatus.uploading,
        type: type,
        currentOperation: 'Starting sync...',
      ));

      int uploadedRecords = 0;
      int downloadedRecords = 0;
      final List<String> errors = [];

      // Define table sync order (dependencies first)
      final tablesToSync = [
        'business_years',
        'business_months',
        'business_days',
        'customers',
        'khata_entries',
      ];

      for (int i = 0; i < tablesToSync.length; i++) {
        final tableName = tablesToSync[i];

        _updateProgress(SyncProgress(
          status: type == SyncType.restore ? SyncStatus.downloading : SyncStatus.uploading,
          type: type,
          progress: i / tablesToSync.length,
          currentOperation: 'Syncing $tableName...',
          totalItems: tablesToSync.length,
          processedItems: i,
        ));

        try {
          switch (type) {
            case SyncType.backup:
              final uploaded = await _uploadTableData(tableName, tenantId);
              uploadedRecords += uploaded;
              break;
            case SyncType.restore:
              final downloaded = await _downloadTableData(tableName, tenantId);
              downloadedRecords += downloaded;
              break;
            case SyncType.full:
              // First upload, then download
              final uploaded = await _uploadTableData(tableName, tenantId);
              uploadedRecords += uploaded;
              final downloaded = await _downloadTableData(tableName, tenantId);
              downloadedRecords += downloaded;
              break;
          }

          // Update sync metadata
          await _updateSyncMetadata(tableName, tenantId, type.name);

        } catch (e) {
          errors.add('$tableName: $e');
        }
      }

      _updateProgress(SyncProgress(
        status: SyncStatus.completed,
        type: type,
        progress: 1.0,
        currentOperation: 'Sync completed',
        totalItems: tablesToSync.length,
        processedItems: tablesToSync.length,
      ));

      _lastSyncStats = syncStats.copyWith(
        syncEndTime: DateTime.now(),
        totalTables: tablesToSync.length,
        completedTables: tablesToSync.length - errors.length,
        uploadedRecords: uploadedRecords,
        downloadedRecords: downloadedRecords,
        errors: errors,
      );

      return SyncResult(
        success: errors.isEmpty,
        error: errors.isNotEmpty ? errors.join('; ') : null,
        type: type,
        timestamp: DateTime.now(),
        uploadedRecords: uploadedRecords,
        downloadedRecords: downloadedRecords,
      );

    } catch (e) {
      _updateProgress(SyncProgress(
        status: SyncStatus.failed,
        type: type,
        currentOperation: 'Sync failed: $e',
      ));

      return SyncResult(
        success: false,
        error: e.toString(),
        type: type,
        timestamp: DateTime.now(),
      );
    }
  }

  // Upload local data to Supabase
  Future<int> _uploadTableData(String tableName, String tenantId) async {
    switch (tableName) {
      case 'customers':
        return await _uploadCustomers(tenantId);
      case 'khata_entries':
        return await _uploadKhataEntries(tenantId);
      case 'business_years':
        return await _uploadBusinessYears(tenantId);
      case 'business_months':
        return await _uploadBusinessMonths(tenantId);
      case 'business_days':
        return await _uploadBusinessDays(tenantId);
      default:
        return 0;
    }
  }

  // Download remote data from Supabase
  Future<int> _downloadTableData(String tableName, String tenantId) async {
    switch (tableName) {
      case 'customers':
        return await _downloadCustomers(tenantId);
      case 'khata_entries':
        return await _downloadKhataEntries(tenantId);
      case 'business_years':
        return await _downloadBusinessYears(tenantId);
      case 'business_months':
        return await _downloadBusinessMonths(tenantId);
      case 'business_days':
        return await _downloadBusinessDays(tenantId);
      default:
        return 0;
    }
  }

  // Upload customers to Supabase
  Future<int> _uploadCustomers(String tenantId) async {
    _localDb.setTenant(tenantId);
    final customers = await _localDb.getAllCustomers();
    int uploadCount = 0;

    for (final customer in customers) {
      try {
        final customerData = customer.toMap();
        customerData['user_id'] = currentUserId;
        customerData.remove('id'); // Remove local ID, let Supabase generate UUID

        await _supabase!
            .from(SupabaseConfig.customersTable)
            .upsert(customerData);

        uploadCount++;
      } catch (e) {
        // Skip failed uploads, continue with next customer
      }
    }

    return uploadCount;
  }

  // Download customers from Supabase
  Future<int> _downloadCustomers(String tenantId) async {
    try {
      final response = await _supabase!
          .from(SupabaseConfig.customersTable)
          .select()
          .eq('tenant_id', tenantId)
          .eq('user_id', currentUserId!);

      int downloadCount = 0;

      for (final customerData in response) {
        try {
          // Convert Supabase data to local format
          final localCustomerData = Map<String, dynamic>.from(customerData);
          localCustomerData.remove('user_id'); // Remove user_id for local storage
          localCustomerData['id'] = null; // Let local DB assign ID

          final customer = Customer.fromMap(localCustomerData);
          await _localDb.addCustomer(customer);
          downloadCount++;
        } catch (e) {
          // Skip failed downloads, continue with next customer
        }
      }

      return downloadCount;
    } catch (e) {
      return 0;
    }
  }

  // Upload khata entries to Supabase
  Future<int> _uploadKhataEntries(String tenantId) async {
    _localDb.setTenant(tenantId);
    final entries = await _localDb.getAllEntriesForSync();
    int uploadCount = 0;

    for (final entry in entries) {
      try {
        final entryData = entry.toMap();
        entryData['user_id'] = currentUserId;
        entryData.remove('id'); // Remove local ID

        await _supabase!
            .from(SupabaseConfig.khataEntriesTable)
            .upsert(entryData);

        uploadCount++;
      } catch (e) {
        // Skip failed uploads, continue with next entry
      }
    }

    return uploadCount;
  }

  // Download khata entries from Supabase
  Future<int> _downloadKhataEntries(String tenantId) async {
    try {
      final response = await _supabase!
          .from(SupabaseConfig.khataEntriesTable)
          .select()
          .eq('tenant_id', tenantId)
          .eq('user_id', currentUserId!);

      int downloadCount = 0;

      for (final entryData in response) {
        try {
          final localEntryData = Map<String, dynamic>.from(entryData);
          localEntryData.remove('user_id');
          localEntryData['id'] = null;

          final entry = KhataEntry.fromMap(localEntryData);
          await _localDb.addEntry(entry);
          downloadCount++;
        } catch (e) {
          // Skip failed downloads, continue with next entry
        }
      }

      return downloadCount;
    } catch (e) {
      return 0;
    }
  }

  // Placeholder methods for business date objects (simplified for now)
  Future<int> _uploadBusinessYears(String tenantId) async {
    // Implementation depends on how you store business years locally
    return 0;
  }

  Future<int> _downloadBusinessYears(String tenantId) async {
    return 0;
  }

  Future<int> _uploadBusinessMonths(String tenantId) async {
    return 0;
  }

  Future<int> _downloadBusinessMonths(String tenantId) async {
    return 0;
  }

  Future<int> _uploadBusinessDays(String tenantId) async {
    return 0;
  }

  Future<int> _downloadBusinessDays(String tenantId) async {
    return 0;
  }

  // Update sync metadata
  Future<void> _updateSyncMetadata(String tableName, String tenantId, String syncDirection) async {
    try {
      final metadata = {
        'table_name': tableName,
        'tenant_id': tenantId,
        'user_id': currentUserId,
        'last_sync_at': DateTime.now().toIso8601String(),
        'sync_direction': syncDirection,
        'record_count': 0, // You can implement actual count if needed
      };

      await _supabase!
          .from(SupabaseConfig.syncMetadataTable)
          .upsert(metadata);
    } catch (e) {
      // Metadata update failed, continue sync
    }
  }

  // Get sync status for a table
  Future<SyncMetadata?> getSyncMetadata(String tableName, String tenantId) async {
    try {
      final response = await _supabase!
          .from(SupabaseConfig.syncMetadataTable)
          .select()
          .eq('table_name', tableName)
          .eq('tenant_id', tenantId)
          .eq('user_id', currentUserId!)
          .single();

      return SyncMetadata.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Get user statistics from Supabase
  Future<Map<String, dynamic>?> getUserStatistics(String tenantId) async {
    try {
      final response = await _supabase!
          .rpc('get_user_statistics', params: {
        'user_uuid': currentUserId,
        'tenant_id_param': tenantId,
      });

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Update progress and notify listeners
  void _updateProgress(SyncProgress progress) {
    _currentProgress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}