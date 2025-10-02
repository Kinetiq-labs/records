import 'dart:convert';

/// Status of sync operations
enum SyncStatus {
  idle,
  uploading,
  downloading,
  completed,
  failed,
}

/// Types of sync operations
enum SyncType {
  backup,    // Upload local data to server
  restore,   // Download data from server
  full,      // Complete sync both ways
}

/// Sync configuration model
class SyncConfig {
  final String userId;
  final String serverUrl;
  final String apiKey;
  final bool autoSync;
  final Duration syncInterval;
  final DateTime? lastSyncAt;

  const SyncConfig({
    required this.userId,
    required this.serverUrl,
    required this.apiKey,
    this.autoSync = false,
    this.syncInterval = const Duration(hours: 24),
    this.lastSyncAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'serverUrl': serverUrl,
    'apiKey': apiKey,
    'autoSync': autoSync,
    'syncInterval': syncInterval.inHours,
    'lastSyncAt': lastSyncAt?.toIso8601String(),
  };

  factory SyncConfig.fromJson(Map<String, dynamic> json) => SyncConfig(
    userId: json['userId'] ?? '',
    serverUrl: json['serverUrl'] ?? '',
    apiKey: json['apiKey'] ?? '',
    autoSync: json['autoSync'] ?? false,
    syncInterval: Duration(hours: json['syncInterval'] ?? 24),
    lastSyncAt: json['lastSyncAt'] != null
        ? DateTime.parse(json['lastSyncAt'])
        : null,
  );
}

/// User data package for sync
class UserDataPackage {
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> khataData;
  final Map<String, dynamic> customers;
  final Map<String, dynamic> settings;
  final String appVersion;

  const UserDataPackage({
    required this.userId,
    required this.timestamp,
    required this.userData,
    required this.khataData,
    required this.customers,
    required this.settings,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'userData': userData,
    'khataData': khataData,
    'customers': customers,
    'settings': settings,
    'appVersion': appVersion,
    'dataVersion': '1.0',
  };

  factory UserDataPackage.fromJson(Map<String, dynamic> json) => UserDataPackage(
    userId: json['userId'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    userData: json['userData'] ?? {},
    khataData: json['khataData'] ?? {},
    customers: json['customers'] ?? {},
    settings: json['settings'] ?? {},
    appVersion: json['appVersion'] ?? '1.0.0',
  );

  String toJsonString() => jsonEncode(toJson());

  factory UserDataPackage.fromJsonString(String jsonString) =>
      UserDataPackage.fromJson(jsonDecode(jsonString));
}

/// Sync operation result
class SyncResult {
  final bool success;
  final String? error;
  final SyncType type;
  final DateTime timestamp;
  final int? uploadedRecords;
  final int? downloadedRecords;
  final String? serverResponse;

  const SyncResult({
    required this.success,
    this.error,
    required this.type,
    required this.timestamp,
    this.uploadedRecords,
    this.downloadedRecords,
    this.serverResponse,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'error': error,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'uploadedRecords': uploadedRecords,
    'downloadedRecords': downloadedRecords,
    'serverResponse': serverResponse,
  };

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
    success: json['success'] ?? false,
    error: json['error'],
    type: SyncType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => SyncType.full,
    ),
    timestamp: DateTime.parse(json['timestamp']),
    uploadedRecords: json['uploadedRecords'],
    downloadedRecords: json['downloadedRecords'],
    serverResponse: json['serverResponse'],
  );
}

/// Sync progress information
class SyncProgress {
  final SyncStatus status;
  final SyncType type;
  final double progress; // 0.0 to 1.0
  final String? currentOperation;
  final int? totalItems;
  final int? processedItems;

  const SyncProgress({
    required this.status,
    required this.type,
    this.progress = 0.0,
    this.currentOperation,
    this.totalItems,
    this.processedItems,
  });

  SyncProgress copyWith({
    SyncStatus? status,
    SyncType? type,
    double? progress,
    String? currentOperation,
    int? totalItems,
    int? processedItems,
  }) => SyncProgress(
    status: status ?? this.status,
    type: type ?? this.type,
    progress: progress ?? this.progress,
    currentOperation: currentOperation ?? this.currentOperation,
    totalItems: totalItems ?? this.totalItems,
    processedItems: processedItems ?? this.processedItems,
  );
}

/// Server API response model
class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
    success: json['success'] ?? false,
    message: json['message'],
    data: json['data'],
    statusCode: json['statusCode'],
  );

  factory ApiResponse.success({String? message, Map<String, dynamic>? data}) =>
      ApiResponse(success: true, message: message, data: data);

  factory ApiResponse.error(String message, {int? statusCode}) =>
      ApiResponse(success: false, message: message, statusCode: statusCode);
}

/// Sync metadata for tracking last sync timestamps per table
class SyncMetadata {
  final String tableName;
  final String tenantId;
  final DateTime lastSyncAt;
  final String syncDirection; // 'upload', 'download', 'both'
  final int recordCount;

  const SyncMetadata({
    required this.tableName,
    required this.tenantId,
    required this.lastSyncAt,
    required this.syncDirection,
    this.recordCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'table_name': tableName,
    'tenant_id': tenantId,
    'last_sync_at': lastSyncAt.toIso8601String(),
    'sync_direction': syncDirection,
    'record_count': recordCount,
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory SyncMetadata.fromMap(Map<String, dynamic> map) => SyncMetadata(
    tableName: map['table_name'],
    tenantId: map['tenant_id'],
    lastSyncAt: DateTime.parse(map['last_sync_at']),
    syncDirection: map['sync_direction'],
    recordCount: map['record_count'] ?? 0,
  );
}

/// Conflict resolution strategy
enum ConflictResolution {
  localWins,      // Keep local changes
  remoteWins,     // Use remote changes
  mergeChanges,   // Attempt to merge both
  askUser,        // Prompt user to decide
}

/// Data conflict information
class DataConflict {
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localRecord;
  final Map<String, dynamic> remoteRecord;
  final DateTime localModified;
  final DateTime remoteModified;

  const DataConflict({
    required this.tableName,
    required this.recordId,
    required this.localRecord,
    required this.remoteRecord,
    required this.localModified,
    required this.remoteModified,
  });
}

/// Sync statistics
class SyncStatistics {
  final DateTime syncStartTime;
  final DateTime? syncEndTime;
  final int totalTables;
  final int completedTables;
  final int totalRecords;
  final int uploadedRecords;
  final int downloadedRecords;
  final int conflicts;
  final List<String> errors;

  const SyncStatistics({
    required this.syncStartTime,
    this.syncEndTime,
    this.totalTables = 0,
    this.completedTables = 0,
    this.totalRecords = 0,
    this.uploadedRecords = 0,
    this.downloadedRecords = 0,
    this.conflicts = 0,
    this.errors = const [],
  });

  double get progress => totalTables > 0 ? completedTables / totalTables : 0.0;

  bool get isComplete => syncEndTime != null;

  Duration get duration =>
    (syncEndTime ?? DateTime.now()).difference(syncStartTime);

  SyncStatistics copyWith({
    DateTime? syncStartTime,
    DateTime? syncEndTime,
    int? totalTables,
    int? completedTables,
    int? totalRecords,
    int? uploadedRecords,
    int? downloadedRecords,
    int? conflicts,
    List<String>? errors,
  }) => SyncStatistics(
    syncStartTime: syncStartTime ?? this.syncStartTime,
    syncEndTime: syncEndTime ?? this.syncEndTime,
    totalTables: totalTables ?? this.totalTables,
    completedTables: completedTables ?? this.completedTables,
    totalRecords: totalRecords ?? this.totalRecords,
    uploadedRecords: uploadedRecords ?? this.uploadedRecords,
    downloadedRecords: downloadedRecords ?? this.downloadedRecords,
    conflicts: conflicts ?? this.conflicts,
    errors: errors ?? this.errors,
  );
}