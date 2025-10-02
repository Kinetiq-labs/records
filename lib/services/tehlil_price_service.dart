import '../models/khata_entry.dart';
import '../models/user.dart';

class TehlilPriceService {
  // Private constructor
  TehlilPriceService._();

  // Singleton instance
  static final TehlilPriceService _instance = TehlilPriceService._();
  static TehlilPriceService get instance => _instance;

  /// Get the tehlil price from user preferences (default 100.0)
  double getTehlilPrice(User? user) {
    if (user?.preferences == null) return 100.0;
    return (user!.preferences!['tehlil_price'] as num?)?.toDouble() ?? 100.0;
  }

  /// Calculate pending amount for a list of entries
  /// Only counts entries with status 'Pending' or null (empty)
  /// Applies discount percentage if available
  double calculatePendingAmount(List<KhataEntry> entries, User? user) {
    final tehlilPrice = getTehlilPrice(user);

    // Calculate total for pending entries (status is 'Pending' or null/empty)
    double totalAmount = 0.0;

    for (final entry in entries) {
      if (entry.status == null ||
          entry.status!.isEmpty ||
          entry.status!.toLowerCase() == 'pending') {

        double entryAmount = tehlilPrice;

        // Apply discount if available
        if (entry.discountPercent != null && entry.discountPercent! > 0) {
          final discountAmount = tehlilPrice * (entry.discountPercent! / 100);
          entryAmount = tehlilPrice - discountAmount;
        }

        totalAmount += entryAmount;
      }
    }

    // Note: Silver prices are NOT included in pending amounts
    // They are only counted in earnings when silverPaid is true

    // Return only Tehlil income for pending amounts
    return totalAmount;
  }

  /// Calculate pending amount for status panel (matches status count logic exactly)
  /// Only counts entries with exact 'Pending' status to match getTodayStatusCounts
  /// Applies discount percentage if available
  double calculatePendingAmountForStatus(List<KhataEntry> entries, User? user) {
    final tehlilPrice = getTehlilPrice(user);

    // Calculate total for pending entries (only exact 'Pending' status to match status count)
    double totalAmount = 0.0;
    double totalSilverPrice = 0.0;

    for (final entry in entries) {
      if (entry.status == 'Pending') {
        double entryAmount = tehlilPrice;

        // Apply discount if available
        if (entry.discountPercent != null && entry.discountPercent! > 0) {
          final discountAmount = tehlilPrice * (entry.discountPercent! / 100);
          entryAmount = tehlilPrice - discountAmount;
        }

        totalAmount += entryAmount;

        // Add silver price income only if silver is marked as paid
        if (entry.silverSold != null && entry.silverPaid) {
          totalSilverPrice += entry.silverSold!;
        }
      }
    }

    // Return combined revenue: Tehlil income + Silver price income
    return totalAmount + totalSilverPrice;
  }

  /// Calculate earned amount for status panel (matches status count logic exactly)
  /// Only counts entries with exact 'Paid' status to match getTodayStatusCounts
  /// Applies discount percentage if available
  double calculateEarnedAmountForStatus(List<KhataEntry> entries, User? user) {
    final tehlilPrice = getTehlilPrice(user);

    // Calculate total for paid entries (only exact 'Paid' status to match status count)
    double totalAmount = 0.0;
    double totalSilverPrice = 0.0;

    for (final entry in entries) {
      // Include Tehlil amount only for paid entries
      if (entry.status == 'Paid') {
        double entryAmount = tehlilPrice;

        // Apply discount if available
        if (entry.discountPercent != null && entry.discountPercent! > 0) {
          final discountAmount = tehlilPrice * (entry.discountPercent! / 100);
          entryAmount = tehlilPrice - discountAmount;
        }

        totalAmount += entryAmount;
      }

      // Include silver price income independently - whenever silver is marked as paid, regardless of entry status
      if (entry.silverSold != null && entry.silverPaid) {
        totalSilverPrice += entry.silverSold!;
      }
    }

    // Return combined revenue: Tehlil income + Silver price income
    return totalAmount + totalSilverPrice;
  }

  /// Calculate pending amount for entries in a specific date range
  double calculatePendingAmountForDateRange(
    List<KhataEntry> allEntries,
    DateTime startDate,
    DateTime endDate,
    User? user
  ) {
    // Filter entries by date range
    final entriesInRange = allEntries.where((entry) {
      final entryDate = entry.entryDate;
      return entryDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             entryDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    return calculatePendingAmount(entriesInRange, user);
  }

  /// Calculate pending amount for entries by a specific customer
  double calculatePendingAmountForCustomer(
    List<KhataEntry> allEntries,
    String customerName,
    User? user,
    {DateTime? startDate, DateTime? endDate}
  ) {
    // Filter entries by customer name
    var customerEntries = allEntries.where((entry) =>
      entry.name.toLowerCase() == customerName.toLowerCase()
    ).toList();

    // If date range is specified, filter by dates
    if (startDate != null && endDate != null) {
      customerEntries = customerEntries.where((entry) {
        final entryDate = entry.entryDate;
        return entryDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               entryDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    return calculatePendingAmount(customerEntries, user);
  }

  /// Get count of pending entries
  int getPendingEntriesCount(List<KhataEntry> entries) {
    return entries.where((entry) =>
      entry.status == null ||
      entry.status!.isEmpty ||
      entry.status!.toLowerCase() == 'pending'
    ).length;
  }

  /// Get count of paid entries
  int getPaidEntriesCount(List<KhataEntry> entries) {
    return entries.where((entry) =>
      entry.status != null &&
      entry.status!.toLowerCase() == 'paid'
    ).length;
  }

  /// Format amount as currency string
  String formatAmount(double amount, {String currency = 'Rs.'}) {
    if (amount == 0) return '$currency 0';
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Format amount as currency string without decimals for whole numbers
  String formatAmountCompact(double amount, {String currency = 'Rs.'}) {
    if (amount == 0) return '$currency 0';
    if (amount % 1 == 0) {
      return '$currency ${amount.toStringAsFixed(0)}';
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}