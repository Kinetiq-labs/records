import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import '../models/record.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'records.db');

    // Open the database
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        role INTEGER DEFAULT 0,
        preferences TEXT,
        profilePicturePath TEXT,
        primaryPhone TEXT,
        secondaryPhone TEXT,
        shopName TEXT,
        shopTimings TEXT
      )
    ''');

    // Create records table with user relationship
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        metadata TEXT,
        tags TEXT,
        priority INTEGER DEFAULT 0,
        isArchived INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create categories table for better organization
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        color TEXT,
        icon TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create database metadata table for versioning and migrations
    await db.execute('''
      CREATE TABLE database_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);

    // Insert initial metadata
    await db.insert('database_metadata', {
      'key': 'version',
      'value': version.toString(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await db.insert('database_metadata', {
      'key': 'created_at',
      'value': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _createIndexes(Database db) async {
    // Records indexes
    await db.execute('CREATE INDEX idx_records_category ON records(category)');
    await db.execute('CREATE INDEX idx_records_title ON records(title)');
    await db.execute('CREATE INDEX idx_records_user ON records(userId)');
    await db.execute('CREATE INDEX idx_records_created ON records(createdAt)');
    await db.execute('CREATE INDEX idx_records_updated ON records(updatedAt)');
    await db.execute('CREATE INDEX idx_records_priority ON records(priority)');
    await db.execute('CREATE INDEX idx_records_archived ON records(isArchived)');

    // Users indexes
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_active ON users(isActive)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');

    // Categories indexes
    await db.execute('CREATE INDEX idx_categories_name ON categories(name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user management and enhanced features
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          passwordHash TEXT NOT NULL,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          role INTEGER DEFAULT 0,
          preferences TEXT
        )
      ''');

      // Add new columns to records table
      await db.execute('ALTER TABLE records ADD COLUMN userId INTEGER');
      await db.execute('ALTER TABLE records ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE records ADD COLUMN priority INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE records ADD COLUMN isArchived INTEGER DEFAULT 0');
      
      // Add role column to existing users table (if upgrading from v1)
      try {
        await db.execute('ALTER TABLE users ADD COLUMN role INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
      }

      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          color TEXT,
          icon TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      // Create database metadata table
      await db.execute('''
        CREATE TABLE database_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      // Create new indexes
      await _createIndexes(db);

      // Update metadata
      await db.insert('database_metadata', {
        'key': 'version',
        'value': '2',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    
    if (oldVersion < 3) {
      // Add profile and business information fields to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profilePicturePath TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN primaryPhone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN secondaryPhone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN shopName TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN shopTimings TEXT');
      } catch (e) {
        debugPrint('Error adding new user columns: $e');
        // Columns might already exist, ignore error
      }
      
      // Update metadata for version 3
      await db.insert('database_metadata', {
        'key': 'version',
        'value': newVersion.toString(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Insert a new record
  Future<int> insertRecord(Record record) async {
    final db = await database;
    return await db.insert('records', record.toMap());
  }

  // Get all records
  Future<List<Record>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // Get a record by ID
  Future<Record?> getRecord(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Record.fromMap(maps.first);
    }
    return null;
  }

  // Update a record
  Future<bool> updateRecord(Record record) async {
    final db = await database;
    final count = await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return count > 0;
  }

  // Delete a record
  Future<bool> deleteRecord(int id) async {
    final db = await database;
    final count = await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  // Get records by category
  Future<List<Record>> getRecordsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // Search records
  Future<List<Record>> searchRecords(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'title LIKE ? OR description LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // Get unique categories
  Future<List<String>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM records ORDER BY category',
    );

    return maps.map((map) => map['category'] as String).toList();
  }

  // Get record count
  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM records');
    return result.first['count'] as int;
  }

  // Get record count by category
  Future<Map<String, int>> getCategoryCount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM records GROUP BY category',
    );

    final Map<String, int> categoryCount = {};
    for (final map in maps) {
      categoryCount[map['category'] as String] = map['count'] as int;
    }
    return categoryCount;
  }

  // Delete all records (for testing purposes)
  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete('records');
  }

  // Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ============ USER MANAGEMENT METHODS ============

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Create a new user
  Future<int> createUser(User user) async {
    final db = await database;
    final userWithHashedPassword = user.copyWith(
      passwordHash: _hashPassword(user.passwordHash),
    );
    return await db.insert('users', userWithHashedPassword.toMap());
  }

  // Authenticate user
  Future<User?> authenticateUser(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND passwordHash = ? AND isActive = 1',
      whereArgs: [email, hashedPassword],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Get user by ID
  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Update user
  Future<bool> updateUser(User user) async {
    final db = await database;
    final count = await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return count > 0;
  }

  // Update user password
  Future<bool> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    final hashedPassword = _hashPassword(newPassword);
    final count = await db.update(
      'users',
      {
        'passwordHash': hashedPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  // Deactivate user (soft delete)
  Future<bool> deactivateUser(int userId) async {
    final db = await database;
    final count = await db.update(
      'users',
      {
        'isActive': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  // Delete user permanently
  Future<bool> deleteUser(int userId) async {
    final db = await database;
    final count = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  // ============ ENHANCED RECORD METHODS ============

  // Insert record with user association
  Future<int> insertRecordForUser(Record record, int userId) async {
    final db = await database;
    final recordMap = record.toMap();
    recordMap['userId'] = userId;
    return await db.insert('records', recordMap);
  }

  // Get records for specific user
  Future<List<Record>> getRecordsForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'userId = ? AND isArchived = 0',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // Get archived records for user
  Future<List<Record>> getArchivedRecordsForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'userId = ? AND isArchived = 1',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // Archive/Unarchive record
  Future<bool> toggleRecordArchive(int recordId) async {
    final db = await database;
    
    // Get current archive status
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      columns: ['isArchived'],
      where: 'id = ?',
      whereArgs: [recordId],
    );

    if (maps.isEmpty) return false;

    final currentStatus = maps.first['isArchived'] as int;
    final newStatus = currentStatus == 0 ? 1 : 0;

    final count = await db.update(
      'records',
      {
        'isArchived': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
    return count > 0;
  }

  // Update record priority
  Future<bool> updateRecordPriority(int recordId, int priority) async {
    final db = await database;
    final count = await db.update(
      'records',
      {
        'priority': priority,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
    return count > 0;
  }

  // Search records with advanced filters
  Future<List<Record>> searchRecordsAdvanced({
    required int userId,
    String? query,
    String? category,
    int? priority,
    bool includeArchived = false,
    String? orderBy,
  }) async {
    final db = await database;
    
    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (!includeArchived) {
      whereClause += ' AND isArchived = 0';
    }

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND (title LIKE ? OR description LIKE ? OR tags LIKE ?)';
      whereArgs.addAll(['%$query%', '%$query%', '%$query%']);
    }

    if (category != null && category.isNotEmpty) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (priority != null) {
      whereClause += ' AND priority = ?';
      whereArgs.add(priority);
    }

    final orderByClause = orderBy ?? 'updatedAt DESC';

    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderByClause,
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // ============ BACKUP AND EXPORT METHODS ============

  // Export all data to JSON
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    
    final users = await db.query('users');
    final records = await db.query('records');
    final categories = await db.query('categories');
    final metadata = await db.query('database_metadata');

    return {
      'export_date': DateTime.now().toIso8601String(),
      'database_version': 2,
      'users': users,
      'records': records,
      'categories': categories,
      'metadata': metadata,
    };
  }

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final userCount = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE isActive = 1');
    final recordCount = await db.rawQuery('SELECT COUNT(*) as count FROM records WHERE isArchived = 0');
    final archivedCount = await db.rawQuery('SELECT COUNT(*) as count FROM records WHERE isArchived = 1');
    final categoryCount = await db.rawQuery('SELECT COUNT(*) as count FROM categories');

    final categoryStats = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM records
      WHERE isArchived = 0
      GROUP BY category
      ORDER BY count DESC
    ''');

    final priorityStats = await db.rawQuery('''
      SELECT priority, COUNT(*) as count
      FROM records
      WHERE isArchived = 0
      GROUP BY priority
      ORDER BY priority
    ''');

    return {
      'users': userCount.first['count'],
      'records': recordCount.first['count'],
      'archived_records': archivedCount.first['count'],
      'categories': categoryCount.first['count'],
      'category_breakdown': categoryStats,
      'priority_breakdown': priorityStats,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // ============ ADMIN MANAGEMENT METHODS ============

  // Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role.index],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Get all records (admin only)
  Future<List<Record>> getAllRecordsForAdmin() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Record.fromMap(maps[i]);
    });
  }

  // Create admin user
  Future<int> createAdminUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    UserRole role = UserRole.admin,
  }) async {
    final adminUser = User(
      email: email,
      passwordHash: password, // Will be hashed automatically
      firstName: firstName,
      lastName: lastName,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await createUser(adminUser);
  }

  // Update user role (admin only)
  Future<bool> updateUserRole(int userId, UserRole role) async {
    final db = await database;
    final count = await db.update(
      'users',
      {
        'role': role.index,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  // Create sample data for testing
  Future<void> insertSampleData() async {
    // Create admin user first
    try {
      final existingAdmin = await getUserByEmail('admin@records.app');
      if (existingAdmin == null) {
        await createAdminUser(
          email: 'admin@records.app',
          password: 'root123',
          firstName: 'System',
          lastName: 'Administrator',
          role: UserRole.admin,
        );
      }
    } catch (e) {
      debugPrint('Error creating admin user: $e');
    }

    // Create sample regular user
    try {
      final existingDemo = await getUserByEmail('demo@records.app');
      if (existingDemo == null) {
        final sampleUser = User(
          email: 'demo@records.app',
          passwordHash: 'user1234', // Will be hashed automatically
          firstName: 'Demo',
          lastName: 'User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final userId = await createUser(sampleUser);

        final sampleRecords = [
          Record(
            title: 'Meeting Notes',
            description: 'Notes from the weekly team meeting discussing project progress and upcoming deadlines.',
            category: 'Work',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          Record(
            title: 'Recipe: Chocolate Cake',
            description: 'Delicious chocolate cake recipe with step-by-step instructions.',
            category: 'Personal',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Record(
            title: 'Book Recommendations',
            description: 'List of recommended books for software development and personal growth.',
            category: 'Learning',
            createdAt: DateTime.now().subtract(const Duration(days: 7)),
            updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        for (final record in sampleRecords) {
          await insertRecordForUser(record, userId);
        }
      }
    } catch (e) {
      debugPrint('Error creating demo user: $e');
    }
  }
}