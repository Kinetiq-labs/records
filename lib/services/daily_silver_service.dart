import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:math';
import '../models/daily_silver.dart';
import '../utils/database_helper.dart';
import '../services/khata_database_service.dart';

class DailySilverService {
  static const String _tableName = 'daily_silver';
  static Database? _database;

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await DatabaseHelper.instance.database;
    await _createTable();
    return _database!;
  }

  // Create the daily_silver table
  static Future<void> _createTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        new_silver REAL NOT NULL DEFAULT 0.0,
        present_silver REAL NOT NULL DEFAULT 0.0,
        total_silver_from_entries REAL NOT NULL DEFAULT 0.0,
        remaining_silver REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index on date for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_daily_silver_date ON $_tableName (date)
    ''');
  }

  // Generate unique ID
  static String _generateId() {
    return 'ds_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  // Get daily silver data for a specific date
  static Future<DailySilver?> getDailySilverByDate(DateTime date) async {
    try {
      final db = await database;
      final dateStr = date.toIso8601String().substring(0, 10);

      final maps = await db.query(
        _tableName,
        where: 'date = ?',
        whereArgs: [dateStr],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return DailySilver.fromMap(maps.first);
    } catch (e) {
      print('Error getting daily silver by date: $e');
      return null;
    }
  }

  // Get or create daily silver data for a specific date
  static Future<DailySilver> getOrCreateDailySilverForDate(DateTime date) async {
    // First try to get existing data
    final existing = await getDailySilverByDate(date);
    if (existing != null) return existing;

    // If not found, create new record
    final previousDay = date.subtract(const Duration(days: 1));

    // Get previous day's remaining silver as present silver
    final previousDaySilver = await getDailySilverByDate(previousDay);
    final presentSilver = previousDaySilver?.remainingSilver ?? 0.0;

    // Get today's total silver from entries
    final totalSilverFromEntries = await _getTotalSilverFromEntriesForDate(date);

    // Calculate remaining silver (with default new silver = 0)
    final remainingSilver = DailySilver.calculateRemainingSilver(
      presentSilver: presentSilver,
      totalSilverFromEntries: totalSilverFromEntries,
      newSilver: 0.0,
    );

    final newRecord = DailySilver(
      id: _generateId(),
      date: date,
      newSilver: 0.0,
      presentSilver: presentSilver,
      totalSilverFromEntries: totalSilverFromEntries,
      remainingSilver: remainingSilver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await createDailySilver(newRecord);
    return newRecord;
  }

  // Create new daily silver record
  static Future<void> createDailySilver(DailySilver dailySilver) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        dailySilver.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error creating daily silver: $e');
      throw Exception('Failed to create daily silver record');
    }
  }

  // Update new silver value for a specific date
  static Future<DailySilver?> updateNewSilver(DateTime date, double newSilverValue) async {
    try {
      final existing = await getOrCreateDailySilverForDate(date);

      // Recalculate remaining silver with new value
      final remainingSilver = DailySilver.calculateRemainingSilver(
        presentSilver: existing.presentSilver,
        totalSilverFromEntries: existing.totalSilverFromEntries,
        newSilver: newSilverValue,
      );

      final updatedRecord = existing.copyWith(
        newSilver: newSilverValue,
        remainingSilver: remainingSilver,
        updatedAt: DateTime.now(),
      );

      final db = await database;
      await db.update(
        _tableName,
        updatedRecord.toMap(),
        where: 'id = ?',
        whereArgs: [updatedRecord.id],
      );

      // Update future days' calculations if needed
      await _recalculateFutureDays(date.add(const Duration(days: 1)));

      return updatedRecord;
    } catch (e) {
      print('Error updating new silver: $e');
      return null;
    }
  }

  // Update daily silver calculations when entries change
  static Future<void> updateCalculationsForDate(DateTime date) async {
    try {
      final existing = await getOrCreateDailySilverForDate(date);

      // Get updated total silver from entries
      final totalSilverFromEntries = await _getTotalSilverFromEntriesForDate(date);

      // Recalculate remaining silver
      final remainingSilver = DailySilver.calculateRemainingSilver(
        presentSilver: existing.presentSilver,
        totalSilverFromEntries: totalSilverFromEntries,
        newSilver: existing.newSilver,
      );

      final updatedRecord = existing.copyWith(
        totalSilverFromEntries: totalSilverFromEntries,
        remainingSilver: remainingSilver,
        updatedAt: DateTime.now(),
      );

      final db = await database;
      await db.update(
        _tableName,
        updatedRecord.toMap(),
        where: 'id = ?',
        whereArgs: [updatedRecord.id],
      );

      // Update future days' calculations
      await _recalculateFutureDays(date.add(const Duration(days: 1)));
    } catch (e) {
      print('Error updating calculations for date: $e');
    }
  }

  // Get total silver from entries for a specific date
  static Future<double> _getTotalSilverFromEntriesForDate(DateTime date) async {
    try {
      final khataService = KhataDatabaseService();
      final entries = await khataService.getEntriesByDay(date);

      double total = 0.0;
      for (final entry in entries) {
        if (entry.silver != null) {
          total += entry.silver!;
        }
      }

      return total;
    } catch (e) {
      print('Error getting total silver from entries: $e');
      return 0.0;
    }
  }

  // Recalculate future days when a past day's data changes
  static Future<void> _recalculateFutureDays(DateTime startDate) async {
    try {
      final db = await database;
      final today = DateTime.now();

      // Only recalculate up to today
      DateTime currentDate = startDate;
      while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
        final existing = await getDailySilverByDate(currentDate);
        if (existing != null) {
          // Get previous day's remaining silver
          final previousDay = currentDate.subtract(const Duration(days: 1));
          final previousDaySilver = await getDailySilverByDate(previousDay);
          final presentSilver = previousDaySilver?.remainingSilver ?? 0.0;

          // Get total silver from entries
          final totalSilverFromEntries = await _getTotalSilverFromEntriesForDate(currentDate);

          // Recalculate remaining silver
          final remainingSilver = DailySilver.calculateRemainingSilver(
            presentSilver: presentSilver,
            totalSilverFromEntries: totalSilverFromEntries,
            newSilver: existing.newSilver,
          );

          final updatedRecord = existing.copyWith(
            presentSilver: presentSilver,
            totalSilverFromEntries: totalSilverFromEntries,
            remainingSilver: remainingSilver,
            updatedAt: DateTime.now(),
          );

          await db.update(
            _tableName,
            updatedRecord.toMap(),
            where: 'id = ?',
            whereArgs: [updatedRecord.id],
          );
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }
    } catch (e) {
      print('Error recalculating future days: $e');
    }
  }

  // Get daily silver records for a date range
  static Future<List<DailySilver>> getDailySilverByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await database;
      final startDateStr = startDate.toIso8601String().substring(0, 10);
      final endDateStr = endDate.toIso8601String().substring(0, 10);

      final maps = await db.query(
        _tableName,
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'date ASC',
      );

      return maps.map((map) => DailySilver.fromMap(map)).toList();
    } catch (e) {
      print('Error getting daily silver by date range: $e');
      return [];
    }
  }

  // Delete daily silver record
  static Future<void> deleteDailySilver(String id) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting daily silver: $e');
      throw Exception('Failed to delete daily silver record');
    }
  }

  // Get the latest daily silver record
  static Future<DailySilver?> getLatestDailySilver() async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        orderBy: 'date DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return DailySilver.fromMap(maps.first);
    } catch (e) {
      print('Error getting latest daily silver: $e');
      return null;
    }
  }
}