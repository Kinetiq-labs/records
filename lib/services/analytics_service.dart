import '../models/khata_entry.dart';
import '../models/daily_silver.dart';
import '../models/user.dart';
import 'tehlil_price_service.dart';

class AnalyticsData {
  final double value;
  final String label;
  final DateTime date;
  final String? additionalInfo;

  AnalyticsData({
    required this.value,
    required this.label,
    required this.date,
    this.additionalInfo,
  });
}

class CustomerAnalyticsData {
  final String customerName;
  final int totalEntries;
  final double totalAmount;
  final int paidEntries;
  final int pendingEntries;
  final double conversionRate;

  CustomerAnalyticsData({
    required this.customerName,
    required this.totalEntries,
    required this.totalAmount,
    required this.paidEntries,
    required this.pendingEntries,
    required this.conversionRate,
  });
}

class PaymentStatusData {
  final String status;
  final int count;
  final double amount;
  final double percentage;

  PaymentStatusData({
    required this.status,
    required this.count,
    required this.amount,
    required this.percentage,
  });
}

class SilverAnalyticsData {
  final DateTime date;
  final double newSilver;
  final double usedSilver;
  final double remainingSilver;
  final double efficiency;

  SilverAnalyticsData({
    required this.date,
    required this.newSilver,
    required this.usedSilver,
    required this.remainingSilver,
    required this.efficiency,
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;
  AnalyticsService._();

  // ==================== REVENUE ANALYTICS ====================

  /// Get daily revenue data for the specified period
  List<AnalyticsData> getDailyRevenue(List<KhataEntry> entries, User? user, {int days = 30}) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day); // Normalize to start of day
    final startDate = endDate.subtract(Duration(days: days - 1)); // Include today

    // Group entries by date using normalized date keys
    final Map<String, List<KhataEntry>> entriesByDate = {};

    for (final entry in entries) {
      // Normalize entry date to start of day for accurate comparison
      final entryDateNormalized = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);

      // Check if entry falls within the date range (inclusive)
      if ((entryDateNormalized.isAfter(startDate) || entryDateNormalized.isAtSameMomentAs(startDate)) &&
          (entryDateNormalized.isBefore(endDate) || entryDateNormalized.isAtSameMomentAs(endDate))) {
        final dateKey = _formatDate(entryDateNormalized);
        entriesByDate[dateKey] ??= [];
        entriesByDate[dateKey]!.add(entry);
      }
    }

    // Calculate daily revenue
    final List<AnalyticsData> revenueData = [];
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = _formatDate(date);
      final dayEntries = entriesByDate[dateKey] ?? [];

      final totalEntries = dayEntries.length; // Show total entries, not just paid
      final revenue = TehlilPriceService.instance.calculateEarnedAmountForStatus(dayEntries, user);

      revenueData.add(AnalyticsData(
        value: revenue,
        label: _formatDateLabel(date),
        date: date,
        additionalInfo: '$totalEntries entries',
      ));
    }

    return revenueData;
  }

  /// Get payment status distribution
  List<PaymentStatusData> getPaymentStatusDistribution(List<KhataEntry> entries) {
    final totalEntries = entries.length;
    if (totalEntries == 0) return [];

    final statusCounts = <String, int>{};
    for (final entry in entries) {
      final status = entry.status ?? 'Pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return statusCounts.entries.map((entry) {
      final percentage = (entry.value / totalEntries) * 100;
      return PaymentStatusData(
        status: entry.key,
        count: entry.value,
        amount: 0, // Will be calculated by caller if needed
        percentage: percentage,
      );
    }).toList();
  }

  /// Get revenue growth comparison
  Map<String, double> getRevenueGrowth(List<KhataEntry> entries, User? user) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    final thisMonthEntries = entries.where((e) =>
      e.entryDate.isAfter(thisMonthStart.subtract(const Duration(days: 1)))
    ).toList();

    final lastMonthEntries = entries.where((e) =>
      e.entryDate.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
      e.entryDate.isBefore(lastMonthEnd.add(const Duration(days: 1)))
    ).toList();

    final thisMonthRevenue = TehlilPriceService.instance.calculateEarnedAmountForStatus(thisMonthEntries, user);
    final lastMonthRevenue = TehlilPriceService.instance.calculateEarnedAmountForStatus(lastMonthEntries, user);

    final growth = lastMonthRevenue > 0
        ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
        : 0.0;

    return {
      'thisMonth': thisMonthRevenue,
      'lastMonth': lastMonthRevenue,
      'growth': growth,
    };
  }

  // ==================== CUSTOMER ANALYTICS ====================

  /// Get top customers by performance
  List<CustomerAnalyticsData> getTopCustomers(List<KhataEntry> entries, User? user, {int limit = 10}) {
    final customerMap = <String, List<KhataEntry>>{};

    // Group entries by customer
    for (final entry in entries) {
      customerMap[entry.name] ??= [];
      customerMap[entry.name]!.add(entry);
    }

    // Calculate customer metrics
    final customerMetrics = customerMap.entries.map((entry) {
      final customerEntries = entry.value;
      final totalEntries = customerEntries.length;
      final paidEntries = customerEntries.where((e) => e.status == 'Paid').length;
      final pendingEntries = customerEntries.where((e) => e.status == null || e.status == 'Pending').length;
      // Calculate total amount for all entries (not just paid ones for better analytics visibility)
      // Apply discounts to get accurate total amounts
      final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(user);
      double totalAmount = 0.0;
      for (final entry in customerEntries) {
        double entryAmount = tehlilPrice;
        // Apply discount if available
        if (entry.discountPercent != null && entry.discountPercent! > 0) {
          final discountAmount = tehlilPrice * (entry.discountPercent! / 100);
          entryAmount = tehlilPrice - discountAmount;
        }
        totalAmount += entryAmount;
      }
      final conversionRate = totalEntries > 0 ? (paidEntries / totalEntries) * 100 : 0.0;


      return CustomerAnalyticsData(
        customerName: entry.key,
        totalEntries: totalEntries,
        totalAmount: totalAmount,
        paidEntries: paidEntries,
        pendingEntries: pendingEntries,
        conversionRate: conversionRate,
      );
    }).toList();

    // Sort by total amount and limit results
    customerMetrics.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return customerMetrics.take(limit).toList();
  }

  /// Get customer activity timeline for current week only
  Map<String, int> getCustomerActivityByWeekday(List<KhataEntry> entries) {
    final weekdayMap = <String, int>{
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    final now = DateTime.now();
    // Get start of current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekNormalized = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    // Get end of current week (Sunday)
    final endOfWeek = startOfWeekNormalized.add(const Duration(days: 6));

    // Filter entries for current week only
    for (final entry in entries) {
      final entryDateNormalized = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);

      // Check if entry falls within current week
      if ((entryDateNormalized.isAfter(startOfWeekNormalized) || entryDateNormalized.isAtSameMomentAs(startOfWeekNormalized)) &&
          (entryDateNormalized.isBefore(endOfWeek) || entryDateNormalized.isAtSameMomentAs(endOfWeek))) {
        final weekday = _getWeekdayName(entry.entryDate.weekday);
        weekdayMap[weekday] = (weekdayMap[weekday] ?? 0) + 1;
      }
    }

    return weekdayMap;
  }

  // ==================== SILVER ANALYTICS ====================

  /// Get silver consumption analytics
  List<SilverAnalyticsData> getSilverAnalytics(List<DailySilver> silverData, {int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return silverData
        .where((data) => data.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .map((data) {
      final efficiency = data.totalSilverFromEntries > 0
          ? (data.newSilver / data.totalSilverFromEntries) * 100
          : 0.0;

      return SilverAnalyticsData(
        date: data.date,
        newSilver: data.newSilver,
        usedSilver: data.totalSilverFromEntries / 100000, // Convert to proper units
        remainingSilver: data.remainingSilver,
        efficiency: efficiency,
      );
    }).toList();
  }

  /// Get silver inventory status
  Map<String, double> getSilverInventoryStatus(List<DailySilver> silverData) {
    if (silverData.isEmpty) {
      return {
        'current': 0.0,
        'averageDaily': 0.0,
        'daysRemaining': 0.0,
        'efficiency': 0.0,
      };
    }

    final latest = silverData.last;
    final averageDaily = silverData.length > 1
        ? silverData.map((e) => e.totalSilverFromEntries / 100000).reduce((a, b) => a + b) / silverData.length
        : 0.0;

    final daysRemaining = averageDaily > 0 ? latest.remainingSilver / averageDaily : 0.0;

    final totalNew = silverData.map((e) => e.newSilver).reduce((a, b) => a + b);
    final totalUsed = silverData.map((e) => e.totalSilverFromEntries / 100000).reduce((a, b) => a + b);
    final efficiency = totalUsed > 0 ? (totalNew / totalUsed) * 100 : 0.0;

    return {
      'current': latest.remainingSilver,
      'averageDaily': averageDaily,
      'daysRemaining': daysRemaining,
      'efficiency': efficiency,
    };
  }

  // ==================== TIME ANALYTICS ====================

  /// Get peak hours analysis for current day only
  Map<int, int> getPeakHoursAnalysis(List<KhataEntry> entries) {
    final hourlyMap = <int, int>{};
    final today = DateTime.now();
    final todayDateStr = _formatDate(today);

    // Initialize all hours
    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0;
    }

    // Filter entries for today only
    for (final entry in entries) {
      if (entry.entryTime != null && _formatDate(entry.entryDate) == todayDateStr) {
        final hour = entry.entryTime!.hour;
        hourlyMap[hour] = (hourlyMap[hour] ?? 0) + 1;
      }
    }

    return hourlyMap;
  }

  /// Get productivity metrics
  Map<String, double> getProductivityMetrics(List<KhataEntry> entries, {int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final recentEntries = entries.where((e) =>
      e.entryDate.isAfter(startDate.subtract(const Duration(days: 1)))
    ).toList();

    final totalEntries = recentEntries.length;
    final averageDaily = totalEntries / days;

    // Group by date to find peak day
    final entriesByDate = <String, int>{};
    for (final entry in recentEntries) {
      final dateKey = _formatDate(entry.entryDate);
      entriesByDate[dateKey] = (entriesByDate[dateKey] ?? 0) + 1;
    }

    final peakDay = entriesByDate.values.isNotEmpty
        ? entriesByDate.values.reduce((a, b) => a > b ? a : b)
        : 0;

    return {
      'totalEntries': totalEntries.toDouble(),
      'averageDaily': averageDaily,
      'peakDay': peakDay.toDouble(),
      'completionRate': _getCompletionRate(recentEntries),
    };
  }

  // ==================== HELPER METHODS ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  double _getCompletionRate(List<KhataEntry> entries) {
    if (entries.isEmpty) return 0.0;

    final completedEntries = entries.where((e) =>
      e.status == 'Paid' || e.status == 'Gold'
    ).length;

    return (completedEntries / entries.length) * 100;
  }
}