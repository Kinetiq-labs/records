import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/khata_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/daily_silver_provider.dart';
import '../providers/user_provider.dart';
import '../services/analytics_service.dart';
import '../models/daily_silver.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../widgets/charts/revenue_line_chart.dart';
import '../widgets/charts/payment_status_pie_chart.dart';
import '../widgets/charts/customer_bar_chart.dart';
import '../widgets/charts/silver_consumption_chart.dart';
import '../widgets/charts/activity_heatmap_chart.dart';

class DataAnalyticsScreen extends StatefulWidget {
  final String currentLang;

  const DataAnalyticsScreen({
    super.key,
    required this.currentLang,
  });

  @override
  State<DataAnalyticsScreen> createState() => _DataAnalyticsScreenState();
}

class _DataAnalyticsScreenState extends State<DataAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.get('data_analytics', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('data_analytics', widget.currentLang),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        elevation: isDarkMode ? 0 : 1,
        shadowColor: isDarkMode ? null : Colors.black.withOpacity(0.1),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                Translations.get('revenue_analytics', widget.currentLang),
                style: BilingualTextStyles.getTextStyle(
                  text: Translations.get('revenue_analytics', widget.currentLang),
                  fontSize: 14,
                ),
              ),
            ),
            Tab(
              child: Text(
                Translations.get('customer_silver_analytics', widget.currentLang),
                style: BilingualTextStyles.getTextStyle(
                  text: Translations.get('customer_silver_analytics', widget.currentLang),
                  fontSize: 14,
                ),
              ),
            ),
            Tab(
              child: Text(
                Translations.get('advanced_analytics', widget.currentLang),
                style: BilingualTextStyles.getTextStyle(
                  text: Translations.get('advanced_analytics', widget.currentLang),
                  fontSize: 14,
                ),
              ),
            ),
          ],
          labelColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey[700],
          indicatorColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          indicatorWeight: 3,
          dividerColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
        ),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Consumer4<KhataProvider, CustomerProvider, DailySilverProvider, UserProvider>(
        builder: (context, khataProvider, customerProvider, silverProvider, userProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRevenueAnalytics(
                khataProvider,
                userProvider,
                isDarkMode,
              ),
              _buildCustomerSilverAnalytics(
                khataProvider,
                silverProvider,
                userProvider,
                isDarkMode,
              ),
              _buildAdvancedAnalytics(
                khataProvider,
                userProvider,
                isDarkMode,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevenueAnalytics(
    KhataProvider khataProvider,
    UserProvider userProvider,
    bool isDarkMode,
  ) {
    final user = userProvider.currentUser;

    // Use Consumer to listen to khataProvider changes for real-time updates
    return Consumer<KhataProvider>(
      builder: (context, khataProviderWatch, child) {
        return FutureBuilder<List<KhataEntry>>(
          future: khataProvider.getAllEntriesForAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading analytics data: ${snapshot.error}'),
              );
            }

            final entries = snapshot.data ?? [];

            // Get analytics data with validation
            final revenueData = AnalyticsService.instance.getDailyRevenue(entries, user, days: 30);
            final paymentStatusData = AnalyticsService.instance.getPaymentStatusDistribution(entries);
            final revenueGrowth = AnalyticsService.instance.getRevenueGrowth(entries, user);

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(revenueGrowth, isDarkMode),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    RevenueLineChart(
                      data: revenueData,
                      currentLang: widget.currentLang,
                    ),
                    isDarkMode,
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    PaymentStatusPieChart(
                      data: paymentStatusData,
                      currentLang: widget.currentLang,
                    ),
                    isDarkMode,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerSilverAnalytics(
    KhataProvider khataProvider,
    DailySilverProvider silverProvider,
    UserProvider userProvider,
    bool isDarkMode,
  ) {
    final user = userProvider.currentUser;
    return Consumer<KhataProvider>(
      builder: (context, khataProviderWatch, child) {
        return FutureBuilder<List<KhataEntry>>(
          future: khataProvider.getAllEntriesForAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading analytics data: ${snapshot.error}'),
              );
            }

            final entries = snapshot.data ?? [];

            // Note: Currently only current day silver data is available
            // TODO: Implement historical silver data retrieval when needed
            final silverData = silverProvider.currentDaySilver != null
                ? [silverProvider.currentDaySilver!]
                : <DailySilver>[];

            // Get analytics data with validation
            final topCustomers = AnalyticsService.instance.getTopCustomers(entries, user, limit: 10);
            final silverAnalytics = AnalyticsService.instance.getSilverAnalytics(silverData, days: 30);
            final silverInventory = AnalyticsService.instance.getSilverInventoryStatus(silverData);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSilverInventoryCards(silverInventory, isDarkMode),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    CustomerBarChart(
                      data: topCustomers,
                      currentLang: widget.currentLang,
                    ),
                    isDarkMode,
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    SilverConsumptionChart(
                      data: silverAnalytics,
                      currentLang: widget.currentLang,
                    ),
                    isDarkMode,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvancedAnalytics(
    KhataProvider khataProvider,
    UserProvider userProvider,
    bool isDarkMode,
  ) {
    return Consumer<KhataProvider>(
      builder: (context, khataProviderWatch, child) {
        return FutureBuilder<List<KhataEntry>>(
          future: khataProvider.getAllEntriesForAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading analytics data: ${snapshot.error}'),
              );
            }

            final entries = snapshot.data ?? [];

            // Get analytics data
            final peakHours = AnalyticsService.instance.getPeakHoursAnalysis(entries);
            final productivity = AnalyticsService.instance.getProductivityMetrics(entries, days: 30);
            final customerActivity = AnalyticsService.instance.getCustomerActivityByWeekday(entries);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductivityCards(productivity, isDarkMode),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    ActivityHeatmapChart(
                      hourlyData: peakHours,
                      currentLang: widget.currentLang,
                    ),
                    isDarkMode,
                  ),
                  const SizedBox(height: 24),
                  _buildWeekdayActivityCard(customerActivity, isDarkMode),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewCards(Map<String, double> revenueGrowth, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            Translations.get('this_month_revenue', widget.currentLang),
            revenueGrowth['thisMonth']?.toStringAsFixed(0) ?? '0',
            Icons.trending_up,
            const Color(0xFF4CAF50),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            Translations.get('last_month_revenue', widget.currentLang),
            revenueGrowth['lastMonth']?.toStringAsFixed(0) ?? '0',
            Icons.history,
            const Color(0xFF2196F3),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            Translations.get('growth_rate', widget.currentLang),
            '${revenueGrowth['growth']?.toStringAsFixed(1) ?? '0'}%',
            revenueGrowth['growth']! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            revenueGrowth['growth']! >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildSilverInventoryCards(Map<String, double> inventory, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            Translations.get('current_silver', widget.currentLang),
            '${inventory['current']?.toStringAsFixed(1) ?? '0'}g',
            Icons.inventory,
            const Color(0xFFFF9800),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            Translations.get('daily_consumption', widget.currentLang),
            '${inventory['averageDaily']?.toStringAsFixed(1) ?? '0'}g',
            Icons.trending_down,
            const Color(0xFF9C27B0),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            Translations.get('days_remaining', widget.currentLang),
            inventory['daysRemaining']?.toStringAsFixed(0) ?? '0',
            Icons.schedule,
            inventory['daysRemaining']! > 30 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityCards(Map<String, double> productivity, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            Translations.get('total_entries', widget.currentLang),
            productivity['totalEntries']?.toStringAsFixed(0) ?? '0',
            Icons.list_alt,
            const Color(0xFF2196F3),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            Translations.get('daily_average', widget.currentLang),
            productivity['averageDaily']?.toStringAsFixed(1) ?? '0',
            Icons.today,
            const Color(0xFF4CAF50),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            Translations.get('completion_rate', widget.currentLang),
            '${productivity['completionRate']?.toStringAsFixed(1) ?? '0'}%',
            Icons.check_circle,
            productivity['completionRate']! >= 80 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: BilingualTextStyles.getTextStyle(
              text: value,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: BilingualTextStyles.getTextStyle(
              text: title,
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Widget chart, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: chart,
    );
  }

  Widget _buildWeekdayActivityCard(Map<String, int> weekdayActivity, bool isDarkMode) {
    final maxValue = weekdayActivity.values.isNotEmpty
        ? weekdayActivity.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                Translations.get('weekday_activity', widget.currentLang),
                style: BilingualTextStyles.getTextStyle(
                  text: Translations.get('weekday_activity', widget.currentLang),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...weekdayActivity.entries.map((entry) {
            final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key,
                      style: BilingualTextStyles.getTextStyle(
                        text: entry.key,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 40,
                    child: Text(
                      entry.value.toString(),
                      style: BilingualTextStyles.getTextStyle(
                        text: entry.value.toString(),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}