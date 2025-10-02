import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/record.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

/// High-level database service that provides a clean API for database operations
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  DatabaseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============ INITIALIZATION ============

  /// Initialize the database and create sample data if needed
  Future<void> initialize({bool createSampleData = false}) async {
    await _dbHelper.database; // This will create/upgrade the database
    
    if (createSampleData) {
      final userCount = await getUserCount();
      if (userCount == 0) {
        await _dbHelper.insertSampleData();
      }
    }
  }

  // ============ USER OPERATIONS ============

  /// Create a new user account
  Future<User?> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User with email $email already exists');
      }

      final user = User(
        email: email,
        passwordHash: password,
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: preferences,
      );

      final userId = await _dbHelper.createUser(user);
      return user.copyWith(id: userId);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Authenticate user with email and password
  Future<User?> authenticateUser(String email, String password) async {
    return await _dbHelper.authenticateUser(email, password);
  }

  /// Get user by ID
  Future<User?> getUser(int id) async {
    return await _dbHelper.getUser(id);
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    return await _dbHelper.getUserByEmail(email);
  }

  /// Update user information
  Future<bool> updateUser(User user) async {
    return await _dbHelper.updateUser(user);
  }

  /// Change user password
  Future<bool> changeUserPassword(int userId, String newPassword) async {
    return await _dbHelper.updateUserPassword(userId, newPassword);
  }

  /// Get total number of active users
  Future<int> getUserCount() async {
    final stats = await _dbHelper.getDatabaseStats();
    return stats['users'] as int;
  }

  // ============ RECORD OPERATIONS ============

  /// Create a new record for a user
  Future<Record?> createRecord({
    required int userId,
    required String title,
    required String description,
    required String category,
    List<String>? tags,
    int priority = 0,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final record = Record(
        userId: userId,
        title: title,
        description: description,
        category: category,
        tags: tags,
        priority: priority,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final recordId = await _dbHelper.insertRecordForUser(record, userId);
      return record.copyWith(id: recordId);
    } catch (e) {
      throw Exception('Failed to create record: $e');
    }
  }

  /// Get all records for a user
  Future<List<Record>> getUserRecords(int userId, {bool includeArchived = false}) async {
    if (includeArchived) {
      final active = await _dbHelper.getRecordsForUser(userId);
      final archived = await _dbHelper.getArchivedRecordsForUser(userId);
      return [...active, ...archived];
    } else {
      return await _dbHelper.getRecordsForUser(userId);
    }
  }

  /// Get archived records for a user
  Future<List<Record>> getArchivedRecords(int userId) async {
    return await _dbHelper.getArchivedRecordsForUser(userId);
  }

  /// Search records with advanced filters
  Future<List<Record>> searchRecords({
    required int userId,
    String? query,
    String? category,
    int? priority,
    List<String>? tags,
    bool includeArchived = false,
    RecordSortOrder sortOrder = RecordSortOrder.updatedDesc,
  }) async {
    String? orderBy;
    switch (sortOrder) {
      case RecordSortOrder.titleAsc:
        orderBy = 'title ASC';
        break;
      case RecordSortOrder.titleDesc:
        orderBy = 'title DESC';
        break;
      case RecordSortOrder.createdAsc:
        orderBy = 'createdAt ASC';
        break;
      case RecordSortOrder.createdDesc:
        orderBy = 'createdAt DESC';
        break;
      case RecordSortOrder.updatedAsc:
        orderBy = 'updatedAt ASC';
        break;
      case RecordSortOrder.updatedDesc:
        orderBy = 'updatedAt DESC';
        break;
      case RecordSortOrder.priorityAsc:
        orderBy = 'priority ASC';
        break;
      case RecordSortOrder.priorityDesc:
        orderBy = 'priority DESC';
        break;
    }

    return await _dbHelper.searchRecordsAdvanced(
      userId: userId,
      query: query,
      category: category,
      priority: priority,
      includeArchived: includeArchived,
      orderBy: orderBy,
    );
  }

  /// Update a record
  Future<bool> updateRecord(Record record) async {
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());
    return await _dbHelper.updateRecord(updatedRecord);
  }

  /// Delete a record permanently
  Future<bool> deleteRecord(int recordId) async {
    return await _dbHelper.deleteRecord(recordId);
  }

  /// Archive or unarchive a record
  Future<bool> toggleRecordArchive(int recordId) async {
    return await _dbHelper.toggleRecordArchive(recordId);
  }

  /// Update record priority
  Future<bool> updateRecordPriority(int recordId, int priority) async {
    return await _dbHelper.updateRecordPriority(recordId, priority);
  }

  /// Get unique categories for a user
  Future<List<String>> getUserCategories(int userId) async {
    final records = await getUserRecords(userId);
    final categories = records.map((r) => r.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Get records count by category for a user
  Future<Map<String, int>> getCategoryStats(int userId) async {
    final records = await getUserRecords(userId);
    final Map<String, int> stats = {};
    
    for (final record in records) {
      stats[record.category] = (stats[record.category] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Get priority distribution for a user
  Future<Map<int, int>> getPriorityStats(int userId) async {
    final records = await getUserRecords(userId);
    final Map<int, int> stats = {};
    
    for (final record in records) {
      stats[record.priority] = (stats[record.priority] ?? 0) + 1;
    }
    
    return stats;
  }

  // ============ BACKUP AND EXPORT ============

  /// Export user data to JSON
  Future<Map<String, dynamic>> exportUserData(int userId) async {
    final user = await getUser(userId);
    final records = await getUserRecords(userId, includeArchived: true);
    
    return {
      'export_date': DateTime.now().toIso8601String(),
      'user': user?.toMap(),
      'records': records.map((r) => r.toMap()).toList(),
      'stats': {
        'total_records': records.length,
        'active_records': records.where((r) => !r.isArchived).length,
        'archived_records': records.where((r) => r.isArchived).length,
        'categories': await getUserCategories(userId),
        'category_stats': await getCategoryStats(userId),
        'priority_stats': await getPriorityStats(userId),
      }
    };
  }

  /// Export user data to JSON file
  Future<File> exportUserDataToFile(int userId, {String? fileName}) async {
    final data = await exportUserData(userId);
    final user = await getUser(userId);
    
    fileName ??= 'records_export_${user?.firstName ?? 'user'}_${DateTime.now().millisecondsSinceEpoch}.json';
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Get comprehensive database statistics
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    return await _dbHelper.getDatabaseStats();
  }

  /// Export entire database
  Future<Map<String, dynamic>> exportDatabase() async {
    return await _dbHelper.exportData();
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    try {
      final dbPath = await _dbHelper.database.then((db) => db.path);
      final file = File(dbPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Optimize database (vacuum)
  Future<void> optimizeDatabase() async {
    final db = await _dbHelper.database;
    await db.execute('VACUUM');
  }

  /// Close database connection
  Future<void> close() async {
    await _dbHelper.close();
  }

  // ============ UTILITY METHODS ============

  /// Check if database is healthy
  Future<bool> isDatabaseHealthy() async {
    try {
      final stats = await getDatabaseStatistics();
      return stats.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get database version
  Future<int> getDatabaseVersion() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('PRAGMA user_version');
    return result.first['user_version'] as int? ?? 2;
  }
}

/// Enum for record sorting options
enum RecordSortOrder {
  titleAsc,
  titleDesc,
  createdAsc,
  createdDesc,
  updatedAsc,
  updatedDesc,
  priorityAsc,
  priorityDesc,
}

/// Extension to get display names for sort orders
extension RecordSortOrderExtension on RecordSortOrder {
  String get displayName {
    switch (this) {
      case RecordSortOrder.titleAsc:
        return 'Title (A-Z)';
      case RecordSortOrder.titleDesc:
        return 'Title (Z-A)';
      case RecordSortOrder.createdAsc:
        return 'Created (Oldest)';
      case RecordSortOrder.createdDesc:
        return 'Created (Newest)';
      case RecordSortOrder.updatedAsc:
        return 'Updated (Oldest)';
      case RecordSortOrder.updatedDesc:
        return 'Updated (Newest)';
      case RecordSortOrder.priorityAsc:
        return 'Priority (Low to High)';
      case RecordSortOrder.priorityDesc:
        return 'Priority (High to Low)';
    }
  }
}