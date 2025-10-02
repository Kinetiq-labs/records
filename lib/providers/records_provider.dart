import 'package:flutter/foundation.dart';
import '../models/record.dart';
import '../utils/database_helper.dart';

class RecordsProvider with ChangeNotifier {
  List<Record> _records = [];
  bool _isLoading = false;
  String? _error;

  List<Record> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all records from database
  Future<void> loadRecords() async {
    _setLoading(true);
    try {
      _records = await DatabaseHelper.instance.getAllRecords();
      _error = null;
    } catch (e) {
      _error = 'Failed to load records: $e';
      debugPrint('Error loading records: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new record
  Future<bool> addRecord(Record record) async {
    try {
      final id = await DatabaseHelper.instance.insertRecord(record);
      if (id > 0) {
        final newRecord = record.copyWith(id: id);
        _records.insert(0, newRecord); // Add to beginning of list
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add record: $e';
      debugPrint('Error adding record: $e');
      notifyListeners();
      return false;
    }
  }

  // Update an existing record
  Future<bool> updateRecord(Record record) async {
    if (record.id == null) return false;
    
    try {
      final updatedRecord = record.copyWith(updatedAt: DateTime.now());
      final success = await DatabaseHelper.instance.updateRecord(updatedRecord);
      
      if (success) {
        final index = _records.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          _records[index] = updatedRecord;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update record: $e';
      debugPrint('Error updating record: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete a record
  Future<bool> deleteRecord(int id) async {
    try {
      final success = await DatabaseHelper.instance.deleteRecord(id);
      if (success) {
        _records.removeWhere((record) => record.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete record: $e';
      debugPrint('Error deleting record: $e');
      notifyListeners();
      return false;
    }
  }

  // Get records by category
  List<Record> getRecordsByCategory(String category) {
    return _records.where((record) => record.category == category).toList();
  }

  // Get unique categories
  List<String> getCategories() {
    final categories = _records.map((record) => record.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Search records
  List<Record> searchRecords(String query) {
    if (query.isEmpty) return _records;
    
    final lowercaseQuery = query.toLowerCase();
    return _records.where((record) {
      return record.title.toLowerCase().contains(lowercaseQuery) ||
             record.description.toLowerCase().contains(lowercaseQuery) ||
             record.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get record count
  int get recordCount => _records.length;

  // Get records count by category
  Map<String, int> getCategoryCount() {
    final Map<String, int> categoryCount = {};
    for (final record in _records) {
      categoryCount[record.category] = (categoryCount[record.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  // Sort records by different criteria
  void sortRecords(RecordSortBy sortBy, {bool ascending = true}) {
    switch (sortBy) {
      case RecordSortBy.title:
        _records.sort((a, b) => ascending 
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case RecordSortBy.category:
        _records.sort((a, b) => ascending 
            ? a.category.compareTo(b.category)
            : b.category.compareTo(a.category));
        break;
      case RecordSortBy.createdAt:
        _records.sort((a, b) => ascending 
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case RecordSortBy.updatedAt:
        _records.sort((a, b) => ascending 
            ? a.updatedAt.compareTo(b.updatedAt)
            : b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    notifyListeners();
  }
}

enum RecordSortBy {
  title,
  category,
  createdAt,
  updatedAt,
}