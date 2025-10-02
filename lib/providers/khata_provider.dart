import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/khata_database_service.dart';
import '../services/tehlil_price_service.dart';
import '../models/khata_entry.dart';
import '../models/user.dart';

class KhataProvider extends ChangeNotifier {
  final KhataDatabaseService _dbService = KhataDatabaseService();
  
  List<KhataEntry> _entries = [];
  List<KhataEntry> _todayEntries = [];
  List<KhataEntry> _monthlyEntries = []; // Separate list for monthly calculations
  Map<String, dynamic> _dailySummary = {};
  Map<String, dynamic> _monthlySummary = {};
  Map<String, dynamic> _yearlySummary = {};
  
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  
  // Getters
  List<KhataEntry> get entries => _entries;
  List<KhataEntry> get todayEntries => _todayEntries;
  Map<String, dynamic> get dailySummary => _dailySummary;
  Map<String, dynamic> get monthlySummary => _monthlySummary;
  Map<String, dynamic> get yearlySummary => _yearlySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  // Get ALL entries for analytics (not filtered by selected date)
  Future<List<KhataEntry>> getAllEntriesForAnalytics() async {
    try {
      final currentYear = DateTime.now().year;
      return await _dbService.getEntriesByYear(currentYear);
    } catch (e) {
      debugPrint('Get all entries for analytics error: $e');
      return [];
    }
  }

  // Get entries by customer name for search functionality
  Future<List<KhataEntry>> getEntriesByCustomerName(String customerName) async {
    try {
      final allEntries = await getAllEntriesForAnalytics();
      return allEntries.where((entry) =>
        entry.name.toLowerCase().contains(customerName.toLowerCase())
      ).toList();
    } catch (e) {
      debugPrint('Get entries by customer name error: $e');
      return [];
    }
  }

  // Initialize the provider with tenant ID
  Future<void> initialize(String tenantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dbService.setTenant(tenantId);
      await loadTodayEntries();
      await loadDailySummary(_selectedDate);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('KhataProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ENTRY MANAGEMENT ====================

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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final entry = await _dbService.createEntry(
        name: name,
        number: number,
        weight: weight,
        detail: detail,
        returnWeight1: returnWeight1,
        returnWeight1Display: returnWeight1Display,
        firstWeight: firstWeight,
        silver: silver,
        returnWeight2: returnWeight2,
        nalki: nalki,
        silverSold: silverSold,
        silverAmount: silverAmount,
        entryDate: entryDate,
        entryTime: entryTime,
        status: status,
        discountPercent: discountPercent,
      );

      // Refresh data
      await loadTodayEntries();
      await loadEntriesByDate(_selectedDate); // Also refresh current view
      await loadDailySummary(_selectedDate);
      
      return entry;
    } catch (e) {
      _error = e.toString();
      debugPrint('Create entry error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEntry(String entryId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateEntry(entryId, updates);
      
      // Refresh data
      await loadTodayEntries();
      await loadEntriesByDate(_selectedDate); // Also refresh current view
      await loadDailySummary(_selectedDate);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Update entry error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteEntry(entryId);
      
      // Refresh data
      await loadTodayEntries();
      await loadEntriesByDate(_selectedDate); // Also refresh current view
      await loadDailySummary(_selectedDate);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Delete entry error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update entry status without full page refresh
  Future<void> updateEntryStatus(String entryId, String newStatus) async {
    try {
      // Update in database first
      await _dbService.updateEntry(entryId, {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Update local entries list (current view)
      for (int i = 0; i < _entries.length; i++) {
        if (_entries[i].entryId == entryId) {
          _entries[i] = _entries[i].copyWith(status: newStatus);
          break;
        }
      }
      
      // Update today entries list if applicable
      for (int i = 0; i < _todayEntries.length; i++) {
        if (_todayEntries[i].entryId == entryId) {
          _todayEntries[i] = _todayEntries[i].copyWith(status: newStatus);
          break;
        }
      }
      
      // Update monthly entries list for summary calculations
      for (int i = 0; i < _monthlyEntries.length; i++) {
        if (_monthlyEntries[i].entryId == entryId) {
          _monthlyEntries[i] = _monthlyEntries[i].copyWith(status: newStatus);
          break;
        }
      }
      
      // Reload monthly entries in background for accurate monthly summary (don't affect current view)
      await _loadMonthlyEntriesForSummary();
      
      // Notify listeners to update UI
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Update entry status error: $e');
      rethrow;
    }
  }

  // Update silver paid status without full page refresh
  Future<void> updateSilverPaidStatus(String entryId, bool isPaid) async {
    try {
      // Update in database first
      await _dbService.updateEntry(entryId, {
        'silver_paid': isPaid ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1, // Mark for sync
      });

      // Update local entries list (current view)
      for (int i = 0; i < _entries.length; i++) {
        if (_entries[i].entryId == entryId) {
          _entries[i] = _entries[i].copyWith(silverPaid: isPaid);
          break;
        }
      }

      // Update today entries list if applicable
      for (int i = 0; i < _todayEntries.length; i++) {
        if (_todayEntries[i].entryId == entryId) {
          _todayEntries[i] = _todayEntries[i].copyWith(silverPaid: isPaid);
          break;
        }
      }

      // Update monthly entries list for summary calculations
      for (int i = 0; i < _monthlyEntries.length; i++) {
        if (_monthlyEntries[i].entryId == entryId) {
          _monthlyEntries[i] = _monthlyEntries[i].copyWith(silverPaid: isPaid);
          break;
        }
      }

      // Reload monthly entries in background for accurate monthly summary (don't affect current view)
      await _loadMonthlyEntriesForSummary();

      // Notify listeners to update UI
      notifyListeners();

    } catch (e) {
      debugPrint('Update silver paid status error: $e');
      rethrow;
    }
  }

  Future<void> updateCalculatedField(String entryId, String fieldName, double value) async {
    try {
      // Convert field name to database column name
      final dbFieldName = _getDbFieldName(fieldName);

      // Update in database first using special method that doesn't recompute fields
      await _dbService.updateCalculatedField(entryId, {
        dbFieldName: value,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update local entries list (current view)
      for (int i = 0; i < _entries.length; i++) {
        if (_entries[i].entryId == entryId) {
          _entries[i] = _updateEntryCalculatedField(_entries[i], fieldName, value);
          break;
        }
      }

      // Update today entries list if applicable
      for (int i = 0; i < _todayEntries.length; i++) {
        if (_todayEntries[i].entryId == entryId) {
          _todayEntries[i] = _updateEntryCalculatedField(_todayEntries[i], fieldName, value);
          break;
        }
      }

      // Update monthly entries list for summary calculations
      for (int i = 0; i < _monthlyEntries.length; i++) {
        if (_monthlyEntries[i].entryId == entryId) {
          _monthlyEntries[i] = _updateEntryCalculatedField(_monthlyEntries[i], fieldName, value);
          break;
        }
      }

      // Force UI update
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update calculated field: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Update calculated field error: $e');
      debugPrint('Field: $fieldName, Value: $value, EntryId: $entryId');
      rethrow;
    }
  }

  String _getDbFieldName(String fieldName) {
    switch (fieldName) {
      case 'sumValue':
        return 'sum_value';
      case 'discountPercent':
        return 'discount_percent';
      default:
        return fieldName; // total, difference, rtti, carat, masha are same in DB
    }
  }

  KhataEntry _updateEntryCalculatedField(KhataEntry entry, String fieldName, double value) {
    switch (fieldName) {
      case 'total':
        return entry.copyWith(total: value);
      case 'difference':
        return entry.copyWith(difference: value);
      case 'sumValue':
        return entry.copyWith(sumValue: value);
      case 'rtti':
        return entry.copyWith(rtti: value);
      case 'carat':
        return entry.copyWith(carat: value);
      case 'masha':
        return entry.copyWith(masha: value);
      case 'discountPercent':
        return entry.copyWith(discountPercent: value);
      default:
        return entry;
    }
  }

  // Private method to load monthly entries for summary calculations only
  Future<void> _loadMonthlyEntriesForSummary() async {
    try {
      final now = DateTime.now();
      _monthlyEntries = await _dbService.getEntriesByMonth(now.year, now.month);
    } catch (e) {
      debugPrint('Load monthly entries for summary error: $e');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear database cache - useful when data is modified externally
  void clearCache() {
    _dbService.clearCache();
  }

  /// Refresh current data by clearing cache and reloading
  Future<void> refreshCurrentData() async {
    clearCache();
    // Check if we're looking at today's date or a specific date
    final today = DateTime.now();
    if (_selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day) {
      await loadTodayEntries();
    } else {
      await loadEntriesByDate(_selectedDate);
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadTodayEntries() async {
    try {
      _isLoading = true;
      notifyListeners();

      _todayEntries = await _dbService.getEntriesByDay(DateTime.now());
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Load today entries error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntriesByDate(DateTime date) async {
    try {
      _isLoading = true;
      _selectedDate = date;
      notifyListeners();

      _entries = await _dbService.getEntriesByDay(date);
      _error = null;

      // Preload nearby dates in background for better navigation performance
      _preloadNearbyDates(date);

    } catch (e) {
      _error = e.toString();
      debugPrint('Load entries by date error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Preload nearby dates in background to improve navigation performance
  void _preloadNearbyDates(DateTime date) {
    // Don't wait for these - run in background
    Future.microtask(() async {
      try {
        // Preload previous and next 3 days
        final datesToPreload = <DateTime>[];
        for (int i = -3; i <= 3; i++) {
          if (i != 0) { // Skip current date as it's already loaded
            datesToPreload.add(date.add(Duration(days: i)));
          }
        }

        // Load dates with small delays to avoid blocking the UI
        for (final dateToPreload in datesToPreload) {
          await _dbService.getEntriesByDay(dateToPreload);
          // Small delay to avoid overwhelming the database
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        // Silent fail for preloading
        debugPrint('Preload error: $e');
      }
    });
  }

  Future<void> loadEntriesByMonth(int year, int month) async {
    try {
      _isLoading = true;
      notifyListeners();

      _entries = await _dbService.getEntriesByMonth(year, month);
      _error = null;

    } catch (e) {
      _error = e.toString();
      debugPrint('Load entries by month error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntriesByYear(int year) async {
    try {
      _isLoading = true;
      notifyListeners();

      _entries = await _dbService.getEntriesByYear(year);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Load entries by year error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      _isLoading = true;
      notifyListeners();

      _entries = await _dbService.getEntriesByDateRange(startDate, endDate);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Load entries by date range error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchEntriesByName(String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      _entries = await _dbService.searchEntriesByName(name);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Search entries error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SUMMARY DATA ====================

  Future<void> loadDailySummary(DateTime date) async {
    try {
      _dailySummary = await _dbService.getDailySummary(date);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Load daily summary error: $e');
    }
  }

  Future<void> loadMonthlySummary(int year, int month) async {
    try {
      _monthlySummary = await _dbService.getMonthlySummary(year, month);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Load monthly summary error: $e');
    }
  }

  Future<void> loadYearlySummary(int year) async {
    try {
      _yearlySummary = await _dbService.getYearlySummary(year);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Load yearly summary error: $e');
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearEntries() {
    _entries.clear();
    notifyListeners();
  }

  // Get entry by index for the selected date
  KhataEntry? getEntryByIndex(int index) {
    return _entries.where((e) => e.entryIndex == index).firstOrNull;
  }

  // Get total entries count for selected date
  int get entriesCount => _entries.length;

  // Get today's entries count
  int get todayEntriesCount => _todayEntries.length;

  // Check if any field computation failed
  bool hasComputationErrors() {
    return _entries.any((entry) => 
      entry.computationErrors != null && entry.computationErrors!.isNotEmpty
    );
  }

  // Get entries with computation errors
  List<KhataEntry> getEntriesWithErrors() {
    return _entries.where((entry) => 
      entry.computationErrors != null && entry.computationErrors!.isNotEmpty
    ).toList();
  }

  // ==================== STATUS SUMMARIES ====================
  
  // Get status counts for today
  Map<String, int> getTodayStatusCounts() {
    final today = DateTime.now();
    final todayEntries = _todayEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == today.year && 
             entryDate.month == today.month && 
             entryDate.day == today.day;
    }).toList();
    
    return {
      'paid': todayEntries.where((e) => e.status == 'Paid').length,
      'pending': todayEntries.where((e) => e.status == 'Pending').length,
      'gold': todayEntries.where((e) => e.status == 'Gold').length,
      'recheck': todayEntries.where((e) => e.status == 'Recheck').length,
      'card': todayEntries.where((e) => e.status == 'Card').length,
    };
  }
  
  // Get status counts for current month
  Map<String, int> getMonthlyStatusCounts() {
    final now = DateTime.now();
    
    // Use the dedicated _monthlyEntries list for accurate counts
    final monthlyEntries = _monthlyEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == now.year && entryDate.month == now.month;
    }).toList();
    
    // Debug information
    debugPrint('🗓️ Monthly Status Counts Debug:');
    debugPrint('Total _monthlyEntries: ${_monthlyEntries.length}');
    debugPrint('Current month entries found: ${monthlyEntries.length}');
    for (var entry in monthlyEntries) {
      debugPrint('Entry ${entry.entryIndex} on ${entry.entryDate.day}/${entry.entryDate.month}: ${entry.status}');
    }
    
    final counts = {
      'paid': monthlyEntries.where((e) => e.status == 'Paid').length,
      'pending': monthlyEntries.where((e) => e.status == 'Pending').length,
      'gold': monthlyEntries.where((e) => e.status == 'Gold').length,
      'recheck': monthlyEntries.where((e) => e.status == 'Recheck').length,
      'card': monthlyEntries.where((e) => e.status == 'Card').length,
    };
    
    debugPrint('Final monthly counts: $counts');
    return counts;
  }

  // Load monthly entries for status calculations
  Future<void> loadCurrentMonthEntries() async {
    try {
      final now = DateTime.now();
      _monthlyEntries = await _dbService.getEntriesByMonth(now.year, now.month);
    } catch (e) {
      debugPrint('Load current month entries error: $e');
    }
  }

  // ==================== PENDING AMOUNT CALCULATIONS ====================

  /// Get pending amount for today's entries
  double getTodayPendingAmount(User? user) {
    final today = DateTime.now();
    final todayEntries = _todayEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == today.year &&
             entryDate.month == today.month &&
             entryDate.day == today.day;
    }).toList();

    return TehlilPriceService.instance.calculatePendingAmount(todayEntries, user);
  }

  /// Get pending amount for current month entries
  double getMonthlyPendingAmount(User? user) {
    final now = DateTime.now();
    final monthlyEntries = _monthlyEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == now.year && entryDate.month == now.month;
    }).toList();

    return TehlilPriceService.instance.calculatePendingAmount(monthlyEntries, user);
  }

  /// Get pending amount for today's entries (for status panel - matches status count)
  double getTodayPendingAmountForStatus(User? user) {
    final today = DateTime.now();
    final todayEntries = _todayEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == today.year &&
             entryDate.month == today.month &&
             entryDate.day == today.day;
    }).toList();

    return _calculatePendingAmountWithCustomerDiscountsSync(todayEntries, user);
  }

  /// Get pending amount for current month entries (for status panel - matches status count)
  double getMonthlyPendingAmountForStatus(User? user) {
    final now = DateTime.now();
    final monthlyEntries = _monthlyEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == now.year && entryDate.month == now.month;
    }).toList();

    return _calculatePendingAmountWithCustomerDiscountsSync(monthlyEntries, user);
  }

  /// Get earned amount for today's entries (for status panel - matches status count)
  double getTodayEarnedAmountForStatus(User? user) {
    final today = DateTime.now();
    final todayEntries = _todayEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == today.year &&
             entryDate.month == today.month &&
             entryDate.day == today.day;
    }).toList();

    return TehlilPriceService.instance.calculateEarnedAmountForStatus(todayEntries, user);
  }

  /// Get earned amount for current month entries (for status panel - matches status count)
  double getMonthlyEarnedAmountForStatus(User? user) {
    final now = DateTime.now();
    final monthlyEntries = _monthlyEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.year == now.year && entryDate.month == now.month;
    }).toList();

    return TehlilPriceService.instance.calculateEarnedAmountForStatus(monthlyEntries, user);
  }

  /// Get pending amount for a specific customer in date range
  double getCustomerPendingAmount(String customerName, User? user, {DateTime? startDate, DateTime? endDate}) {
    return TehlilPriceService.instance.calculatePendingAmountForCustomer(
      _entries,
      customerName,
      user,
      startDate: startDate,
      endDate: endDate
    );
  }

  // ==================== SYNC STATUS ====================

  Future<List<KhataEntry>> getUnsyncedEntries() async {
    try {
      return await _dbService.getUnsyncedEntries();
    } catch (e) {
      debugPrint('Get unsynced entries error: $e');
      return [];
    }
  }

  Future<void> markAsSynced(String entryId) async {
    try {
      await _dbService.markAsSynced(entryId);
    } catch (e) {
      debugPrint('Mark as synced error: $e');
    }
  }

  // ==================== COMPUTED FIELD HELPERS ====================

  // Calculate field values manually (for preview/validation)
  Map<String, double?> calculateFields({
    int? firstWeight,
    int? silver,
    int? returnWeight2,
    int? nalki,
  }) {
    double? total;
    double? difference;
    double? sumValue;
    double? rtti;
    double? carat;
    double? masha;
    
    // 1. total = first_weight + silver
    if (firstWeight != null && silver != null) {
      total = (firstWeight + silver).toDouble();
    }
    
    // 2. difference = total - return_weight_2
    if (total != null && returnWeight2 != null) {
      difference = total - returnWeight2;
    }
    
    // 3. sum = nalki/first_weight * 1000
    if (nalki != null && firstWeight != null && firstWeight != 0) {
      sumValue = (nalki / firstWeight) * 1000;
    }
    
    // 4. rtti = sum/1000*96-96
    if (sumValue != null) {
      rtti = (sumValue / 1000 * 96) - 96;
    }
    
    // 5. carat = sum/1000*24 (CORRECTED SPELLING)
    if (sumValue != null) {
      carat = (sumValue / 1000) * 24;
    }
    
    // 6. masha = sum/1000*11.664-11.664
    if (sumValue != null) {
      masha = (sumValue / 1000 * 11.664) - 11.664;
    }

    return {
      'total': total,
      'difference': difference,
      'sum_value': sumValue,
      'rtti': rtti,
      'carat': carat,
      'masha': masha,
    };
  }

  /// Calculate pending amount with customer discounts applied (synchronous version)
  double _calculatePendingAmountWithCustomerDiscountsSync(List<KhataEntry> entries, User? user) {
    final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(user);

    // Group entries by customer name
    final Map<String, List<KhataEntry>> entriesByCustomer = {};

    for (final entry in entries) {
      // Only count pending entries (status is 'Pending' or null/empty)
      if (entry.status == 'Pending') {
        final customerName = entry.name;
        entriesByCustomer.putIfAbsent(customerName, () => []);
        entriesByCustomer[customerName]!.add(entry);
      }
    }

    double totalPendingAmount = 0.0;

    // Calculate pending amount for each customer with their discount
    for (final customerName in entriesByCustomer.keys) {
      final customerEntries = entriesByCustomer[customerName]!;

      // Calculate base Tehlil amount for this customer
      double customerTehlilAmount = customerEntries.length * tehlilPrice;

      // Calculate silver price income for this customer (only if silver is marked as paid)
      double customerSilverAmount = 0.0;
      for (final entry in customerEntries) {
        if (entry.silverSold != null && entry.silverPaid) {
          customerSilverAmount += entry.silverSold!;
        }
      }

      // Check if any entry has customer discount info (fallback method)
      // We'll use the first entry's discount as representative of the customer's discount
      final firstEntry = customerEntries.first;

      // Apply customer discount to Tehlil amount only (not silver price)
      // Note: This uses entry.discountPercent as a proxy for customer discount
      // In the future, we could improve this by caching customer data in the provider
      if (firstEntry.discountPercent != null && firstEntry.discountPercent! > 0) {
        final discountAmount = customerTehlilAmount * (firstEntry.discountPercent! / 100);
        customerTehlilAmount = customerTehlilAmount - discountAmount;
      }

      // Add both Tehlil income (with discount) and silver price income (no discount)
      totalPendingAmount += customerTehlilAmount + customerSilverAmount;
    }

    return totalPendingAmount;
  }

  @override
  void dispose() {
    _dbService.close();
    super.dispose();
  }
}