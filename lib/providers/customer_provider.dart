import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/khata_entry.dart';
import '../services/khata_database_service.dart';

class CustomerProvider extends ChangeNotifier {
  final KhataDatabaseService _dbService = KhataDatabaseService();

  List<Customer> _customers = [];
  List<KhataEntry> _customerEntries = [];
  Customer? _selectedCustomer;
  Map<String, dynamic> _customerStats = {};

  bool _isLoading = false;
  String? _error;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  // Getters
  List<Customer> get customers => _customers;
  List<KhataEntry> get customerEntries => _customerEntries;
  Customer? get selectedCustomer => _selectedCustomer;
  Map<String, dynamic> get customerStats => _customerStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedStartDate => _selectedStartDate;
  DateTime get selectedEndDate => _selectedEndDate;

  // Initialize the provider with tenant ID
  Future<void> initialize(String tenantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dbService.setTenant(tenantId);
      await loadCustomers();

    } catch (e) {
      _error = e.toString();
      debugPrint('CustomerProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final customer = await _dbService.createCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        discountPercent: discountPercent,
      );

      // Refresh customers list
      await loadCustomers();

      return customer;
    } catch (e) {
      _error = e.toString();
      debugPrint('Create customer error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(String customerId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateCustomer(customerId, updates);

      // Refresh customers list
      await loadCustomers();

      // Update selected customer if it's the one being updated
      if (_selectedCustomer?.customerId == customerId) {
        _selectedCustomer = _customers.firstWhere(
          (c) => c.customerId == customerId,
          orElse: () => _selectedCustomer!,
        );
      }

    } catch (e) {
      _error = e.toString();
      debugPrint('Update customer error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteCustomer(customerId);

      // Clear selected customer if it's the one being deleted
      if (_selectedCustomer?.customerId == customerId) {
        _selectedCustomer = null;
        _customerEntries.clear();
        _customerStats.clear();
      }

      // Refresh customers list
      await loadCustomers();

    } catch (e) {
      _error = e.toString();
      debugPrint('Delete customer error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadCustomers() async {
    try {
      _customers = await _dbService.getAllCustomers();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Load customers error: $e');
    }
  }

  Future<void> selectCustomer(Customer customer) async {
    _selectedCustomer = customer;
    notifyListeners();

    // Load initial data for the customer (last 30 days)
    await loadCustomerEntriesByDateRange(
      customer.customerId,
      _selectedStartDate,
      _selectedEndDate,
    );
  }

  Future<void> loadCustomerEntriesByMonth(String customerId, int year, int month) async {
    try {
      _isLoading = true;
      notifyListeners();

      _customerEntries = await _dbService.getCustomerEntriesByMonth(customerId, year, month);
      await _loadCustomerStats(customerId, year, month);

    } catch (e) {
      _error = e.toString();
      debugPrint('Load customer entries by month error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCustomerEntriesByDateRange(String customerId, DateTime startDate, DateTime endDate) async {
    try {
      _isLoading = true;
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
      notifyListeners();

      _customerEntries = await _dbService.getCustomerEntriesByDateRange(customerId, startDate, endDate);
      await _loadCustomerStatsByDateRange(customerId, startDate, endDate);

    } catch (e) {
      _error = e.toString();
      debugPrint('Load customer entries by date range error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCustomerStats(String customerId, int year, int month) async {
    try {
      _customerStats = await _dbService.getCustomerStatsByMonth(customerId, year, month);
    } catch (e) {
      debugPrint('Load customer stats error: $e');
    }
  }

  Future<void> _loadCustomerStatsByDateRange(String customerId, DateTime startDate, DateTime endDate) async {
    try {
      _customerStats = await _dbService.getCustomerStatsByDateRange(customerId, startDate, endDate);
    } catch (e) {
      debugPrint('Load customer stats by date range error: $e');
    }
  }

  // ==================== SEARCH & FILTER ====================

  Future<void> searchCustomers(String query) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (query.trim().isEmpty) {
        await loadCustomers();
      } else {
        _customers = await _dbService.searchCustomers(query);
      }

    } catch (e) {
      _error = e.toString();
      debugPrint('Search customers error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UTILITY FUNCTIONS ====================

  void setDateRange(DateTime startDate, DateTime endDate) {
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    _customerEntries.clear();
    _customerStats.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get customer by name
  Customer? getCustomerByName(String name) {
    try {
      return _customers.firstWhere((customer) => customer.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Get customer entries count
  int get customerEntriesCount => _customerEntries.length;

  // Get customer status counts for selected period
  Map<String, int> getCustomerStatusCounts() {
    return {
      'paid': _customerEntries.where((e) => e.status == 'Paid').length,
      'pending': _customerEntries.where((e) => e.status == 'Pending').length,
      'gold': _customerEntries.where((e) => e.status == 'Gold').length,
      'recheck': _customerEntries.where((e) => e.status == 'Recheck').length,
      'card': _customerEntries.where((e) => e.status == 'Card').length,
    };
  }

  @override
  void dispose() {
    _dbService.close();
    super.dispose();
  }
}