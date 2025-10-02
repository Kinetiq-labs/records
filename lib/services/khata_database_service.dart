import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/khata_entry.dart';
import '../models/business_date.dart';
import '../models/customer.dart';

class KhataDatabaseService {
  static final KhataDatabaseService _instance = KhataDatabaseService._internal();
  factory KhataDatabaseService() => _instance;
  KhataDatabaseService._internal();

  static Database? _database;
  String? _currentTenantId;

  // Cache for frequently accessed data
  final Map<String, List<KhataEntry>> _entryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  void setTenant(String tenantId) {
    _currentTenantId = tenantId;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final documentsDirectory = Directory.current.path;
    final path = join(documentsDirectory, 'khata_records.db');
    
    return await openDatabase(
      path,
      version: 8,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for entry_time and status
      await db.execute('ALTER TABLE khata_entries ADD COLUMN entry_time TEXT');
      await db.execute('ALTER TABLE khata_entries ADD COLUMN status TEXT');
    }
    if (oldVersion < 3) {
      // Add customers table
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id TEXT UNIQUE NOT NULL,
          tenant_id TEXT NOT NULL,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');

      // Create indexes for customers table
      await db.execute('CREATE INDEX idx_customers_tenant ON customers (tenant_id)');
      await db.execute('CREATE INDEX idx_customers_name ON customers (name)');
      await db.execute('CREATE INDEX idx_customers_active ON customers (is_active)');

      // Add customer_name column to khata_entries for linking
      await db.execute('ALTER TABLE khata_entries ADD COLUMN customer_name TEXT');
      await db.execute('CREATE INDEX idx_khata_customer_name ON khata_entries (customer_name)');
    }
    if (oldVersion < 4) {
      // Add return_weight_1_display column for storing original format
      await db.execute('ALTER TABLE khata_entries ADD COLUMN return_weight_1_display TEXT');
    }
    if (oldVersion < 5) {
      // Add silver_sold and silver_amount columns
      await db.execute('ALTER TABLE khata_entries ADD COLUMN silver_sold REAL');
      await db.execute('ALTER TABLE khata_entries ADD COLUMN silver_amount REAL');
    }
    if (oldVersion < 6) {
      // Add discount_percent columns to both entries and customers
      await db.execute('ALTER TABLE khata_entries ADD COLUMN discount_percent REAL');
      await db.execute('ALTER TABLE customers ADD COLUMN discount_percent REAL');
    }
    if (oldVersion < 7) {
      // Add silver_paid column to track silver sales independently
      await db.execute('ALTER TABLE khata_entries ADD COLUMN silver_paid INTEGER DEFAULT 0');
    }
    if (oldVersion < 8) {
      // Add financial tracking columns to customers table
      await db.execute('ALTER TABLE customers ADD COLUMN previous_arrears REAL DEFAULT 0');
      await db.execute('ALTER TABLE customers ADD COLUMN received REAL DEFAULT 0');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Business Years Table
    await db.execute('''
      CREATE TABLE business_years (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year_id TEXT UNIQUE NOT NULL,
        tenant_id TEXT NOT NULL,
        year_number INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        total_entries INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // Business Months Table
    await db.execute('''
      CREATE TABLE business_months (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_id TEXT UNIQUE NOT NULL,
        year_id TEXT NOT NULL,
        month_number INTEGER NOT NULL,
        month_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        total_entries INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (year_id) REFERENCES business_years (year_id)
      )
    ''');

    // Business Days Table
    await db.execute('''
      CREATE TABLE business_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_id TEXT UNIQUE NOT NULL,
        month_id TEXT NOT NULL,
        day_date TEXT NOT NULL,
        day_name TEXT NOT NULL,
        total_entries INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (month_id) REFERENCES business_months (month_id)
      )
    ''');

    // Main Khata Entries Table
    await db.execute('''
      CREATE TABLE khata_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id TEXT UNIQUE NOT NULL,
        day_id TEXT NOT NULL,
        tenant_id TEXT NOT NULL,
        entry_index INTEGER NOT NULL,
        entry_date TEXT NOT NULL,
        
        -- INPUT FIELDS (11 fields)
        name TEXT NOT NULL,
        weight REAL,
        detail TEXT,
        number INTEGER NOT NULL,
        return_weight_1 INTEGER,
        first_weight INTEGER,
        silver INTEGER,
        return_weight_2 INTEGER,
        nalki INTEGER,
        silver_sold REAL,
        silver_amount REAL,
        silver_paid INTEGER DEFAULT 0,
        
        -- COMPUTED FIELDS (6 fields)
        total REAL,
        difference REAL,
        sum_value REAL,
        rtti REAL,
        carat REAL,
        masha REAL,
        
        -- Computation Status
        is_computed INTEGER DEFAULT 0,
        computation_errors TEXT,
        
        -- New Fields
        entry_time TEXT,
        status TEXT,
        customer_name TEXT,
        discount_percent REAL,

        -- Sync & Metadata
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        
        FOREIGN KEY (day_id) REFERENCES business_days (day_id)
      )
    ''');

    // Create Indexes for Performance
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Date-based queries optimization
    await db.execute('CREATE INDEX idx_entry_date ON khata_entries(entry_date)');
    await db.execute('CREATE INDEX idx_entry_day ON khata_entries(day_id)');
    await db.execute('CREATE INDEX idx_entry_tenant_date ON khata_entries(tenant_id, entry_date)');
    
    // Name-based searches
    await db.execute('CREATE INDEX idx_entry_name ON khata_entries(name)');
    await db.execute('CREATE INDEX idx_entry_name_date ON khata_entries(name, entry_date)');
    
    // Sync optimization
    await db.execute('CREATE INDEX idx_sync_status ON khata_entries(sync_status)');
    await db.execute('CREATE INDEX idx_tenant_sync ON khata_entries(tenant_id, sync_status)');
    
    // Daily entry indexing
    await db.execute('CREATE INDEX idx_daily_entries ON khata_entries(day_id, entry_index)');
    
    // Date hierarchy indexes
    await db.execute('CREATE INDEX idx_year_tenant ON business_years(tenant_id, year_number)');
    await db.execute('CREATE INDEX idx_month_year ON business_months(year_id, month_number)');
    await db.execute('CREATE INDEX idx_day_month ON business_days(month_id, day_date)');

    // Customer name index
    await db.execute('CREATE INDEX idx_khata_customer_name ON khata_entries (customer_name)');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT UNIQUE NOT NULL,
        tenant_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        notes TEXT,
        discount_percent REAL,
        previous_arrears REAL DEFAULT 0,
        received REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Create indexes for customers table
    await db.execute('CREATE INDEX idx_customers_tenant ON customers (tenant_id)');
    await db.execute('CREATE INDEX idx_customers_name ON customers (name)');
    await db.execute('CREATE INDEX idx_customers_active ON customers (is_active)');
  }

  // ==================== UTILITY FUNCTIONS ====================

  String _generateUUID() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  // ==================== DATE HIERARCHY MANAGEMENT ====================

  Future<String> ensureYearExists(int year, String tenantId) async {
    final db = await database;
    // Make year_id unique per tenant to avoid constraint conflicts
    final yearId = '${tenantId}_$year';

    // Check if year exists
    final existing = await db.query(
      'business_years',
      where: 'year_id = ?',
      whereArgs: [yearId],
    );

    if (existing.isNotEmpty) {
      return yearId;
    }

    // Create new year
    final businessYear = BusinessYear(
      yearId: yearId,
      tenantId: tenantId,
      yearNumber: year,
      startDate: DateTime(year, 1, 1),
      endDate: DateTime(year, 12, 31),
      isActive: year == DateTime.now().year,
      createdAt: DateTime.now(),
    );

    await db.insert('business_years', businessYear.toMap());
    return yearId;
  }

  Future<String> ensureMonthExists(int year, int month, String tenantId) async {
    final db = await database;
    final yearId = await ensureYearExists(year, tenantId);
    // Make month_id tenant-specific for consistency
    final monthId = '${tenantId}_$year-${month.toString().padLeft(2, '0')}';

    // Check if month exists
    final existing = await db.query(
      'business_months',
      where: 'month_id = ?',
      whereArgs: [monthId],
    );

    if (existing.isNotEmpty) {
      return monthId;
    }

    // Create new month
    final businessMonth = BusinessMonth(
      monthId: monthId,
      yearId: yearId,
      monthNumber: month,
      monthName: _getMonthName(month),
      startDate: DateTime(year, month, 1),
      endDate: DateTime(year, month + 1, 0),
      createdAt: DateTime.now(),
    );

    await db.insert('business_months', businessMonth.toMap());
    return monthId;
  }

  Future<String> ensureDayExists(DateTime date, String tenantId) async {
    final db = await database;
    final monthId = await ensureMonthExists(date.year, date.month, tenantId);
    // Make day_id tenant-specific for consistency
    final dayId = '${tenantId}_${date.toIso8601String().substring(0, 10)}';

    // Check if day exists
    final existing = await db.query(
      'business_days',
      where: 'day_id = ?',
      whereArgs: [dayId],
    );

    if (existing.isNotEmpty) {
      return dayId;
    }

    // Create new day
    final businessDay = BusinessDay(
      dayId: dayId,
      monthId: monthId,
      dayDate: date,
      dayName: _getWeekdayName(date.weekday),
      createdAt: DateTime.now(),
    );

    await db.insert('business_days', businessDay.toMap());
    return dayId;
  }

  Future<int> getNextEntryIndex(String dayId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(entry_index) as max_index FROM khata_entries WHERE day_id = ? AND is_deleted = 0',
      [dayId],
    );
    
    final maxIndex = result.first['max_index'] as int?;
    return (maxIndex ?? 0) + 1;
  }

  // ==================== KHATA ENTRY CRUD OPERATIONS ====================

  Future<KhataEntry> createEntry({
    required String name,
    required int number,
    double? weight,
    String? detail,
    int? returnWeight1,
    String? returnWeight1Display,
    int? firstWeight,
    int? silver,
    int? returnWeight2,
    int? nalki,
    double? silverSold,
    double? silverAmount,
    DateTime? entryDate,
    DateTime? entryTime,
    String? status,
    double? discountPercent,
  }) async {
    if (_currentTenantId == null) {
      throw Exception('Tenant ID not set. Call setTenant() first.');
    }

    final db = await database;
    final date = entryDate ?? DateTime.now();
    
    // Ensure date hierarchy exists
    final dayId = await ensureDayExists(date, _currentTenantId!);
    
    // Get next entry index for the day
    final entryIndex = await getNextEntryIndex(dayId);
    
    // Create entry with computed fields
    final entryId = _generateUUID();
    final now = DateTime.now();
    
    final entry = KhataEntry(
      entryId: entryId,
      dayId: dayId,
      tenantId: _currentTenantId!,
      entryIndex: entryIndex,
      entryDate: date,
      name: name,
      weight: weight,
      detail: detail,
      number: number,
      returnWeight1: returnWeight1,
      returnWeight1Display: returnWeight1Display,
      firstWeight: firstWeight,
      silver: silver,
      returnWeight2: returnWeight2,
      nalki: nalki,
      silverSold: silverSold,
      silverAmount: silverAmount,
      entryTime: entryTime ?? now, // Set current time if not provided
      status: status, // Can be null (empty by default)
      discountPercent: discountPercent,
      createdAt: now,
      updatedAt: now,
      syncStatus: 1, // Pending sync
    );
    
    // Compute calculated fields
    final computedEntry = entry.computeFields();

    // Insert into database with customer_name set to name for linking
    final entryMap = computedEntry.toMap();
    entryMap['customer_name'] = name;  // Link entry to customer by name
    await db.insert('khata_entries', entryMap);

    // Update day entry count
    await _updateDayEntryCount(dayId);

    // Invalidate cache for this date
    _invalidateCache(affectedDate: date);

    return computedEntry;
  }

  Future<void> _updateDayEntryCount(String dayId) async {
    final db = await database;
    
    // Update business_days count
    await db.rawUpdate('''
      UPDATE business_days 
      SET total_entries = (
        SELECT COUNT(*) FROM khata_entries 
        WHERE day_id = ? AND is_deleted = 0
      )
      WHERE day_id = ?
    ''', [dayId, dayId]);
    
    // Update business_months count
    await db.rawUpdate('''
      UPDATE business_months 
      SET total_entries = (
        SELECT COUNT(*) FROM khata_entries ke
        JOIN business_days bd ON ke.day_id = bd.day_id
        WHERE bd.month_id = business_months.month_id AND ke.is_deleted = 0
      )
      WHERE month_id = (
        SELECT month_id FROM business_days WHERE day_id = ?
      )
    ''', [dayId]);
    
    // Update business_years count
    await db.rawUpdate('''
      UPDATE business_years 
      SET total_entries = (
        SELECT COUNT(*) FROM khata_entries ke
        JOIN business_days bd ON ke.day_id = bd.day_id
        JOIN business_months bm ON bd.month_id = bm.month_id
        WHERE bm.year_id = business_years.year_id AND ke.is_deleted = 0
      )
      WHERE year_id = (
        SELECT bm.year_id FROM business_days bd
        JOIN business_months bm ON bd.month_id = bm.month_id
        WHERE bd.day_id = ?
      )
    ''', [dayId]);
  }

  Future<KhataEntry> updateEntry(String entryId, Map<String, dynamic> updates) async {
    final db = await database;
    
    // Get current entry
    final current = await getEntryById(entryId);
    if (current == null) {
      throw Exception('Entry not found');
    }
    
    // Create updated entry
    final updatedEntry = KhataEntry.fromMap({
      ...current.toMap(),
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 1, // Mark as pending sync
    });
    
    // Recompute fields
    final computedEntry = updatedEntry.computeFields();
    
    // Update in database
    await db.update(
      'khata_entries',
      computedEntry.toMap(),
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );

    // Invalidate cache for this entry's date
    _invalidateCache(affectedDate: current.entryDate);

    return computedEntry;
  }

  Future<KhataEntry> updateCalculatedField(String entryId, Map<String, dynamic> updates) async {
    final db = await database;

    // Get current entry
    final current = await getEntryById(entryId);
    if (current == null) {
      throw Exception('Entry not found');
    }

    // Create updated entry WITHOUT recomputing fields
    final updatedEntry = KhataEntry.fromMap({
      ...current.toMap(),
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 1, // Mark as pending sync
    });

    // Update in database - NO computeFields() call here!
    await db.update(
      'khata_entries',
      updatedEntry.toMap(),
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );

    // Invalidate cache for this entry's date
    _invalidateCache(affectedDate: current.entryDate);

    return updatedEntry;
  }

  Future<void> deleteEntry(String entryId) async {
    final db = await database;

    // Get entry before deletion for cache invalidation
    final entry = await getEntryById(entryId);

    await db.update(
      'khata_entries',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );

    // Update counts and invalidate cache
    if (entry != null) {
      await _updateDayEntryCount(entry.dayId);
      _invalidateCache(affectedDate: entry.entryDate);
    }
  }

  Future<KhataEntry?> getEntryById(String entryId) async {
    final db = await database;
    final results = await db.query(
      'khata_entries',
      where: 'entry_id = ? AND is_deleted = 0',
      whereArgs: [entryId],
    );
    
    if (results.isEmpty) return null;
    return KhataEntry.fromMap(results.first);
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch load multiple dates for better performance
  Future<Map<String, List<KhataEntry>>> batchLoadDates(List<DateTime> dates) async {
    final db = await database;
    final results = <String, List<KhataEntry>>{};

    // Convert dates to strings for efficient querying
    final dateStrings = dates.map((d) => d.toIso8601String().substring(0, 10)).toSet().toList();

    if (dateStrings.isEmpty) return results;

    // Single query for all dates
    final dbResults = await db.query(
      'khata_entries',
      where: 'entry_date IN (${List.filled(dateStrings.length, '?').join(',')}) AND tenant_id = ? AND is_deleted = 0',
      whereArgs: [...dateStrings, _currentTenantId],
      orderBy: 'entry_date DESC, entry_index ASC',
    );

    // Group results by date
    for (final row in dbResults) {
      final dateKey = row['entry_date'] as String;
      final entry = KhataEntry.fromMap(row);

      results.putIfAbsent(dateKey, () => <KhataEntry>[]);
      results[dateKey]!.add(entry);
    }

    // Update cache for all loaded dates
    for (final dateStr in dateStrings) {
      final entries = results[dateStr] ?? <KhataEntry>[];
      final cacheKey = '${_currentTenantId}_day_$dateStr';
      _entryCache[cacheKey] = List<KhataEntry>.from(entries);
      _cacheTimestamps[cacheKey] = DateTime.now();
    }

    return results;
  }

  // ==================== QUERY FUNCTIONS ====================

  Future<List<KhataEntry>> getEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    final cacheKey = '${_currentTenantId}_range_${startDate.toIso8601String().substring(0, 10)}_${endDate.toIso8601String().substring(0, 10)}';

    // Check cache first
    if (_entryCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheValidDuration) {
        return List<KhataEntry>.from(_entryCache[cacheKey]!);
      }
    }

    final db = await database;
    final results = await db.query(
      'khata_entries',
      where: 'entry_date BETWEEN ? AND ? AND tenant_id = ? AND is_deleted = 0',
      whereArgs: [
        startDate.toIso8601String().substring(0, 10),
        endDate.toIso8601String().substring(0, 10),
        _currentTenantId,
      ],
      orderBy: 'entry_date DESC, entry_index DESC',
    );

    final entries = results.map((map) => KhataEntry.fromMap(map)).toList();

    // Update cache
    _entryCache[cacheKey] = List<KhataEntry>.from(entries);
    _cacheTimestamps[cacheKey] = DateTime.now();

    return entries;
  }

  Future<List<KhataEntry>> getEntriesByYear(int year) async {
    return await getEntriesByDateRange(
      DateTime(year, 1, 1),
      DateTime(year, 12, 31),
    );
  }

  Future<List<KhataEntry>> getEntriesByMonth(int year, int month) async {
    return await getEntriesByDateRange(
      DateTime(year, month, 1),
      DateTime(year, month + 1, 0),
    );
  }

  Future<List<KhataEntry>> getEntriesByDay(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final cacheKey = '${_currentTenantId}_day_$dateStr';

    // Check cache first (shorter cache time for daily data since it changes frequently)
    if (_entryCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      // Use shorter cache for today's entries, longer for past entries
      final cacheValidity = _isToday(date) ? const Duration(minutes: 1) : _cacheValidDuration;
      if (DateTime.now().difference(cacheTime) < cacheValidity) {
        return List<KhataEntry>.from(_entryCache[cacheKey]!);
      }
    }

    final db = await database;
    final results = await db.query(
      'khata_entries',
      where: 'entry_date = ? AND tenant_id = ? AND is_deleted = 0',
      whereArgs: [dateStr, _currentTenantId],
      orderBy: 'entry_index ASC',
    );

    final entries = results.map((map) => KhataEntry.fromMap(map)).toList();

    // Update cache
    _entryCache[cacheKey] = List<KhataEntry>.from(entries);
    _cacheTimestamps[cacheKey] = DateTime.now();

    return entries;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  /// Clear cache for entries that might be affected by changes
  void _invalidateCache({DateTime? affectedDate}) {
    if (affectedDate != null) {
      final dateStr = affectedDate.toIso8601String().substring(0, 10);
      final dayKey = '${_currentTenantId}_day_$dateStr';
      _entryCache.remove(dayKey);
      _cacheTimestamps.remove(dayKey);

      // Also clear month, range, and year caches that might include this date
      // This is especially important for analytics that use yearly data
      final keysToRemove = <String>[];
      for (final key in _entryCache.keys) {
        if (key.startsWith('${_currentTenantId}_range_') ||
            key.startsWith('${_currentTenantId}_month_') ||
            key.startsWith('${_currentTenantId}_year_')) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        _entryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    } else {
      // Clear all cache
      _entryCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Clear all cache - use when major data changes occur
  void clearCache() {
    _invalidateCache();
  }

  Future<List<KhataEntry>> searchEntriesByName(String name) async {
    final db = await database;
    final results = await db.query(
      'khata_entries',
      where: 'name LIKE ? AND tenant_id = ? AND is_deleted = 0',
      whereArgs: ['%$name%', _currentTenantId],
      orderBy: 'entry_date DESC, entry_index DESC',
    );
    
    return results.map((map) => KhataEntry.fromMap(map)).toList();
  }

  // ==================== BUSINESS SUMMARY FUNCTIONS ====================

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    
    final results = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN total IS NOT NULL THEN total ELSE 0 END) as total_sum,
        AVG(CASE WHEN carat IS NOT NULL THEN carat ELSE 0 END) as avg_carat,
        SUM(CASE WHEN weight IS NOT NULL THEN weight ELSE 0 END) as total_weight
      FROM khata_entries 
      WHERE entry_date = ? AND tenant_id = ? AND is_deleted = 0
    ''', [dateStr, _currentTenantId]);
    
    return results.first;
  }

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final endDate = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);
    
    final results = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN total IS NOT NULL THEN total ELSE 0 END) as total_sum,
        AVG(CASE WHEN carat IS NOT NULL THEN carat ELSE 0 END) as avg_carat,
        SUM(CASE WHEN weight IS NOT NULL THEN weight ELSE 0 END) as total_weight,
        COUNT(DISTINCT entry_date) as active_days
      FROM khata_entries 
      WHERE entry_date BETWEEN ? AND ? AND tenant_id = ? AND is_deleted = 0
    ''', [startDate, endDate, _currentTenantId]);
    
    return results.first;
  }

  Future<Map<String, dynamic>> getYearlySummary(int year) async {
    final db = await database;
    final startDate = DateTime(year, 1, 1).toIso8601String().substring(0, 10);
    final endDate = DateTime(year, 12, 31).toIso8601String().substring(0, 10);
    
    final results = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN total IS NOT NULL THEN total ELSE 0 END) as total_sum,
        AVG(CASE WHEN carat IS NOT NULL THEN carat ELSE 0 END) as avg_carat,
        SUM(CASE WHEN weight IS NOT NULL THEN weight ELSE 0 END) as total_weight,
        COUNT(DISTINCT entry_date) as active_days,
        COUNT(DISTINCT substr(entry_date, 1, 7)) as active_months
      FROM khata_entries 
      WHERE entry_date BETWEEN ? AND ? AND tenant_id = ? AND is_deleted = 0
    ''', [startDate, endDate, _currentTenantId]);
    
    return results.first;
  }

  // ==================== SYNC FUNCTIONS ====================

  Future<List<KhataEntry>> getUnsyncedEntries() async {
    final db = await database;
    final results = await db.query(
      'khata_entries',
      where: 'sync_status = 1 AND tenant_id = ?',
      whereArgs: [_currentTenantId],
      orderBy: 'updated_at ASC',
    );
    
    return results.map((map) => KhataEntry.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String entryId) async {
    final db = await database;
    await db.update(
      'khata_entries',
      {'sync_status': 0},
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  // ==================== CUSTOMER MANAGEMENT ====================

  Future<Customer> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? discountPercent,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final customerId = 'cust_${_currentTenantId}_${now.millisecondsSinceEpoch}';

    final customer = Customer(
      customerId: customerId,
      tenantId: _currentTenantId!,
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      discountPercent: discountPercent,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('customers', customer.toMap());

    // Update existing entries that match this customer's name to populate customer_name field
    await db.update(
      'khata_entries',
      {'customer_name': name},
      where: 'tenant_id = ? AND name = ? AND (customer_name IS NULL OR customer_name = "")',
      whereArgs: [_currentTenantId, name],
    );

    return customer;
  }

  Future<void> updateCustomer(String customerId, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();

    try {
      await db.update(
        'customers',
        updates,
        where: 'customer_id = ? AND tenant_id = ?',
        whereArgs: [customerId, _currentTenantId],
      );
    } catch (e) {
      // If columns don't exist, try to add them (fallback migration)
      if (e.toString().contains('no such column: previous_arrears')) {
        try {
          await db.execute('ALTER TABLE customers ADD COLUMN previous_arrears REAL DEFAULT 0');
          await db.execute('ALTER TABLE customers ADD COLUMN received REAL DEFAULT 0');
          // Retry the update
          await db.update(
            'customers',
            updates,
            where: 'customer_id = ? AND tenant_id = ?',
            whereArgs: [customerId, _currentTenantId],
          );
        } catch (fallbackError) {
          throw Exception('Failed to update customer after adding columns: $fallbackError');
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    final db = await database;

    // Soft delete - mark as inactive
    await db.update(
      'customers',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'customer_id = ? AND tenant_id = ?',
      whereArgs: [customerId, _currentTenantId],
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'tenant_id = ? AND is_active = 1',
      whereArgs: [_currentTenantId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'customer_id = ? AND tenant_id = ? AND is_active = 1',
      whereArgs: [customerId, _currentTenantId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final searchTerm = '%$query%';

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'tenant_id = ? AND is_active = 1 AND (name LIKE ? OR phone LIKE ? OR email LIKE ?)',
      whereArgs: [_currentTenantId, searchTerm, searchTerm, searchTerm],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<List<KhataEntry>> getCustomerEntriesByMonth(String customerId, int year, int month) async {
    final db = await database;

    // Get customer first
    final customer = await getCustomerById(customerId);
    if (customer == null) return [];

    // Get entries by customer name and month
    final startDate = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final endDate = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'khata_entries',
      where: 'tenant_id = ? AND (customer_name = ? OR name = ?) AND entry_date >= ? AND entry_date <= ? AND is_deleted = 0',
      whereArgs: [_currentTenantId, customer.name, customer.name, startDate, endDate],
      orderBy: 'entry_date ASC, entry_index ASC',
    );

    return List.generate(maps.length, (i) => KhataEntry.fromMap(maps[i]));
  }

  Future<List<KhataEntry>> getCustomerEntriesByDateRange(String customerId, DateTime startDate, DateTime endDate) async {
    final db = await database;

    // Get customer first
    final customer = await getCustomerById(customerId);
    if (customer == null) return [];

    final startDateStr = startDate.toIso8601String().substring(0, 10);
    final endDateStr = endDate.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'khata_entries',
      where: 'tenant_id = ? AND (customer_name = ? OR name = ?) AND entry_date >= ? AND entry_date <= ? AND is_deleted = 0',
      whereArgs: [_currentTenantId, customer.name, customer.name, startDateStr, endDateStr],
      orderBy: 'entry_date ASC, entry_index ASC',
    );

    return List.generate(maps.length, (i) => KhataEntry.fromMap(maps[i]));
  }

  Future<Map<String, dynamic>> getCustomerStatsByMonth(String customerId, int year, int month) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return {};

    final entries = await getCustomerEntriesByMonth(customerId, year, month);
    return _calculateCustomerStats(entries);
  }

  Future<Map<String, dynamic>> getCustomerStatsByDateRange(String customerId, DateTime startDate, DateTime endDate) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return {};

    final entries = await getCustomerEntriesByDateRange(customerId, startDate, endDate);
    return _calculateCustomerStats(entries);
  }

  // Sync-specific methods
  Future<List<KhataEntry>> getAllEntriesForSync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'khata_entries',
      where: 'tenant_id = ? AND is_deleted = 0',
      whereArgs: [_currentTenantId],
      orderBy: 'entry_date DESC, entry_index ASC',
    );

    return List.generate(maps.length, (i) => KhataEntry.fromMap(maps[i]));
  }

  Future<void> addEntry(KhataEntry entry) async {
    final db = await database;
    await db.insert(
      'khata_entries',
      entry.toMap(),
    );
  }

  Future<void> addCustomer(Customer customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('khata_entries', where: 'tenant_id = ?', whereArgs: [_currentTenantId]);
    await db.delete('customers', where: 'tenant_id = ?', whereArgs: [_currentTenantId]);
    await db.delete('business_dates', where: 'tenant_id = ?', whereArgs: [_currentTenantId]);
  }

  Map<String, dynamic> _calculateCustomerStats(List<KhataEntry> entries) {
    double totalSilver = 0;
    double totalWeight = 0;
    double totalSilverPrice = 0;
    double totalSilverAmount = 0;
    int totalEntries = entries.length;

    Map<String, int> statusCounts = {
      'paid': 0,
      'pending': 0,
      'gold': 0,
      'recheck': 0,
      'card': 0,
    };

    for (final entry in entries) {
      if (entry.silver != null) totalSilver += entry.silver!;
      if (entry.weight != null) totalWeight += entry.weight!;
      if (entry.silverSold != null) totalSilverPrice += entry.silverSold!;
      if (entry.silverAmount != null) totalSilverAmount += entry.silverAmount!;

      final status = entry.status?.toLowerCase();
      if (status != null && statusCounts.containsKey(status)) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    return {
      'total_entries': totalEntries,
      'total_silver': totalSilver,
      'total_weight': totalWeight,
      'total_silver_price': totalSilverPrice,
      'total_silver_amount': totalSilverAmount,
      'status_counts': statusCounts,
      'average_silver_per_entry': totalEntries > 0 ? totalSilver / totalEntries : 0,
      'average_weight_per_entry': totalEntries > 0 ? totalWeight / totalEntries : 0,
      'average_silver_price_per_entry': totalEntries > 0 ? totalSilverPrice / totalEntries : 0,
      'average_silver_amount_per_entry': totalEntries > 0 ? totalSilverAmount / totalEntries : 0,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}