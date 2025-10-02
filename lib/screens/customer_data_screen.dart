import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/customer_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/tehlil_price_service.dart';
import '../models/customer.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../services/text_translation_service.dart';
import '../services/pdf_text_service.dart';
import 'entries_screen.dart';

class CustomerDataScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDataScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDataScreen> createState() => _CustomerDataScreenState();
}

class _CustomerDataScreenState extends State<CustomerDataScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextTranslationService _translationService = TextTranslationService();
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  DateTime _selectedWeek = DateTime.now(); // For weekly view navigation
  bool _weeklyDataLoaded = false; // Track if weekly data has been loaded
  List<KhataEntry> _weeklyEntries = []; // Separate storage for weekly data

  // Weekly calculation fields
  late double _previousArrears;
  late double _received;
  final Map<String, TextEditingController> _editingControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize financial fields from customer data
    _previousArrears = widget.customer.previousArrears ?? 0.0;
    _received = widget.customer.received ?? 0.0;

    // Listen to tab changes to load data only when needed
    _tabController.addListener(() {
      if (_tabController.index == 0) { // Monthly tab is index 0
        _loadMonthlyData();
      } else if (_tabController.index == 1 && !_weeklyDataLoaded) { // Weekly tab is index 1
        _loadWeeklyData();
        _weeklyDataLoaded = true;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerProvider = context.read<CustomerProvider>();
      customerProvider.selectCustomer(widget.customer);
      // Load monthly data initially since monthly tab is the default
      _loadMonthlyData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose text controllers
    for (var controller in _editingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectMonth() async {
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = _selectedDate.year;
        int selectedMonth = _selectedDate.month;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              title: BilingualText.bilingual(
                currentLang == 'en' ? 'Select Month & Year' : 'مہینہ اور سال منتخب کریں',
                style: BilingualTextStyles.titleLarge(
                  currentLang == 'en' ? 'Select Month & Year' : 'مہینہ اور سال منتخب کریں',
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: SizedBox(
                height: 200,
                width: 300,
                child: Column(
                  children: [
                    // Year Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BilingualText.bilingual(
                          currentLang == 'en' ? 'Year:' : 'سال:',
                          style: BilingualTextStyles.titleMedium(
                            currentLang == 'en' ? 'Year:' : 'سال:',
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  if (selectedYear > 2020) selectedYear--;
                                });
                              },
                              icon: Icon(
                                Icons.remove,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[100],
                              ),
                              child: Text(
                                selectedYear.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  if (selectedYear < DateTime.now().year + 1) selectedYear++;
                                });
                              },
                              icon: Icon(
                                Icons.add,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Month Selector
                    BilingualText.bilingual(
                      currentLang == 'en' ? 'Month:' : 'مہینہ:',
                      style: BilingualTextStyles.titleMedium(
                        currentLang == 'en' ? 'Month:' : 'مہینہ:',
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = month == selectedMonth;
                          final monthNames = currentLang == 'en'
                              ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
                              : ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
                                 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];

                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedMonth = month;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0B5D3B)
                                    : (isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0B5D3B)
                                      : (isDarkMode ? Colors.grey[600]! : Colors.grey[400]!),
                                ),
                              ),
                              child: Center(
                                child: BilingualText.bilingual(
                                  monthNames[index],
                                  style: BilingualTextStyles.labelMedium(
                                    monthNames[index],
                                    color: isSelected
                                        ? Colors.white
                                        : (isDarkMode ? Colors.white : Colors.black87),
                                  ).copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: BilingualText.bilingual(
                    currentLang == 'en' ? 'Cancel' : 'منسوخ',
                    style: BilingualTextStyles.labelMedium(
                      currentLang == 'en' ? 'Cancel' : 'منسوخ',
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, DateTime(selectedYear, selectedMonth, 1));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5D3B),
                    foregroundColor: Colors.white,
                  ),
                  child: BilingualText.bilingual(
                    currentLang == 'en' ? 'Select' : 'منتخب کریں',
                    style: BilingualTextStyles.labelMedium(
                      currentLang == 'en' ? 'Select' : 'منتخب کریں',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });

      if (mounted) {
        await _loadMonthlyData();
      }
    }
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Select Date Range',
    );

    if (dateRange != null) {
      setState(() {
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });

      if (mounted) {
        final customerProvider = context.read<CustomerProvider>();
        await customerProvider.loadCustomerEntriesByDateRange(
          widget.customer.customerId,
          dateRange.start,
          dateRange.end,
        );
      }
    }
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            BilingualText.bilingual(
              value,
              style: BilingualTextStyles.displaySmall(
                value,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            BilingualText.bilingual(
              title,
              style: BilingualTextStyles.bodySmall(
                title,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    final languageProvider = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Month selector
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualText.bilingual(
                      Translations.get('selected_month', currentLang),
                      style: BilingualTextStyles.bodyMedium(
                        Translations.get('selected_month', currentLang),
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    BilingualText.bilingual(
                      '${_selectedDate.month}/${_selectedDate.year}',
                      style: BilingualTextStyles.titleMedium(
                        '${_selectedDate.month}/${_selectedDate.year}',
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectMonth,
                icon: const Icon(Icons.edit_calendar, color: Colors.white),
                label: BilingualText.bilingual(
                  Translations.get('change_month', currentLang),
                  style: BilingualTextStyles.labelMedium(
                    Translations.get('change_month', currentLang),
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                ),
              ),
            ],
          ),
        ),

        // Stats summary
        if (customerProvider.customerStats.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    Translations.get('total_entries', currentLang),
                    '${customerProvider.customerStats['total_entries'] ?? 0}',
                    Icons.receipt,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildStatsCard(
                    Translations.get('total_silver', currentLang),
                    '${(customerProvider.customerStats['total_silver'] ?? 0).toStringAsFixed(4)}',
                    Icons.star,
                    const Color(0xFFFFD700),
                  ),
                ),
                Expanded(
                  child: _buildStatsCard(
                    Translations.get('avg_silver', currentLang),
                    '${(customerProvider.customerStats['average_silver_per_entry'] ?? 0).toStringAsFixed(4)}',
                    Icons.trending_up,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),

          // Pending Amount Row with Silver Subtotals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildPendingAmountCard(currentLang),
                ),
                Expanded(
                  child: _buildSilverPriceSubtotalCard(currentLang),
                ),
                Expanded(
                  child: _buildSilverAmountSubtotalCard(currentLang),
                ),
              ],
            ),
          ),
        ],

        // Entries list
        Expanded(
          child: _buildEntriesList(),
        ),
      ],
    );
  }

  Widget _buildWeeklyView() {
    final languageProvider = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final weekStart = _getWeekStart(_selectedWeek);
    final weekEnd = _getWeekEnd(weekStart);

    return Stack(
      children: [
        Column(
          children: [
            // Week selector
            Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.view_week,
                color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BilingualText.bilingual(
                  _formatWeekRange(weekStart, weekEnd),
                  style: BilingualTextStyles.headlineMedium(
                    _formatWeekRange(weekStart, weekEnd),
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _navigateToPreviousWeek,
                icon: const Icon(Icons.chevron_left, size: 28),
              ),
              IconButton(
                onPressed: _navigateToNextWeek,
                icon: const Icon(Icons.chevron_right, size: 28),
              ),
            ],
          ),
        ),
            // Weekly table
            Expanded(
              child: _buildWeeklyTable(customerProvider, currentLang, isDarkMode, weekStart, weekEnd),
            ),
          ],
        ),
        // WhatsApp share button at bottom right
        Positioned(
          bottom: 16,
          right: 16,
          child: Tooltip(
            message: currentLang == 'en'
              ? 'Share weekly report via WhatsApp'
              : 'واٹس ایپ کے ذریعے ہفتہ وار رپورٹ شیئر کریں',
            child: FloatingActionButton(
              onPressed: () => _shareWeeklyDataViaWhatsApp(weekStart, weekEnd, currentLang),
              backgroundColor: const Color(0xFF25D366), // WhatsApp green
              heroTag: "whatsapp_share_fab", // Unique hero tag
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeView() {
    final languageProvider = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Date range selector
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range,
                color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BilingualText.bilingual(
                      Translations.get('selected_range', currentLang),
                      style: BilingualTextStyles.bodyMedium(
                        Translations.get('selected_range', currentLang),
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    BilingualText.bilingual(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      style: BilingualTextStyles.titleMedium(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.edit_calendar, color: Colors.white),
                label: BilingualText.bilingual(
                  Translations.get('change_range', currentLang),
                  style: BilingualTextStyles.labelMedium(
                    Translations.get('change_range', currentLang),
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                ),
              ),
            ],
          ),
        ),

        // Stats summary
        if (customerProvider.customerStats.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    Translations.get('total_entries', currentLang),
                    '${customerProvider.customerStats['total_entries'] ?? 0}',
                    Icons.receipt,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildStatsCard(
                    Translations.get('total_silver', currentLang),
                    '${(customerProvider.customerStats['total_silver'] ?? 0).toStringAsFixed(4)}',
                    Icons.star,
                    const Color(0xFFFFD700),
                  ),
                ),
                Expanded(
                  child: _buildStatsCard(
                    Translations.get('avg_silver', currentLang),
                    '${(customerProvider.customerStats['average_silver_per_entry'] ?? 0).toStringAsFixed(4)}',
                    Icons.trending_up,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),

          // Pending Amount Row with Silver Subtotals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildPendingAmountCard(currentLang),
                ),
                Expanded(
                  child: _buildSilverPriceSubtotalCard(currentLang),
                ),
                Expanded(
                  child: _buildSilverAmountSubtotalCard(currentLang),
                ),
              ],
            ),
          ),
        ],

        // Entries list
        Expanded(
          child: _buildEntriesList(),
        ),
      ],
    );
  }

  Widget _buildEntriesList() {
    final customerProvider = context.watch<CustomerProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (customerProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
        ),
      );
    }

    if (customerProvider.customerEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            BilingualText.bilingual(
              Translations.get('no_entries_found', currentLang),
              style: BilingualTextStyles.titleMedium(
                Translations.get('no_entries_found', currentLang),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: customerProvider.customerEntries.isEmpty
        ? Center(
            child: Text(
              currentLang == 'en'
                ? 'No entries found for this month'
                : 'اس مہینے کے لیے کوئی انٹری نہیں ملی',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          )
        : ListView.builder(
            itemCount: customerProvider.customerEntries.length,
            itemBuilder: (context, index) {
              // Add safety check to prevent RangeError
              if (index >= customerProvider.customerEntries.length) {
                return const SizedBox.shrink();
              }
              final entry = customerProvider.customerEntries[index];
              return _buildEntryCard(entry, currentLang);
            },
          ),
    );
  }

  Widget _buildEntryCard(KhataEntry entry, String currentLang) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;

    switch (entry.status?.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.schedule;
        break;
      case 'gold':
        statusColor = const Color(0xFFFFD700);
        statusIcon = Icons.star;
        break;
      case 'recheck':
        statusColor = const Color(0xFF9C27B0);
        statusIcon = Icons.refresh;
        break;
      case 'card':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.credit_card;
        break;
    }

    return GestureDetector(
      onDoubleTap: () => _navigateToEntry(entry),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 1,
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Entry index
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#${entry.entryIndex}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Entry details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BilingualText.bilingual(
                          entry.entryDate.toIso8601String().substring(0, 10),
                          style: BilingualTextStyles.getTextStyle(
                            text: entry.entryDate.toIso8601String().substring(0, 10),
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (entry.entryTime != null)
                        Text(
                          _formatTime(entry.entryTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${Translations.get('number', currentLang)}: ${entry.number}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        ),
                      ),
                      if (entry.weight != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          '${Translations.get('weight', currentLang)}: ${entry.weight!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.detail != null && entry.detail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.detail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Silver amount
            if (entry.silver != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${entry.silver}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            // Silver Sold
            if (entry.silverSold != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BilingualText.bilingual(
                      Translations.get('silver_sold', currentLang),
                      style: BilingualTextStyles.getTextStyle(
                        text: Translations.get('silver_sold', currentLang),
                        fontSize: 10,
                        color: const Color(0xFF9C27B0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.silverSold!.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Color(0xFF9C27B0),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Silver Amount
            if (entry.silverAmount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BilingualText.bilingual(
                      Translations.get('silver_amount', currentLang),
                      style: BilingualTextStyles.getTextStyle(
                        text: Translations.get('silver_amount', currentLang),
                        fontSize: 10,
                        color: const Color(0xFF00BCD4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.silverAmount!.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Status
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    entry.status ?? '-',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _navigateToEntry(KhataEntry entry) {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EntriesScreen(
            selectedDate: entry.entryDate,
            highlightEntryId: entry.entryId,
          ),
        ),
      );
    }
  }

  // Week calculation utilities (Thursday to Wednesday)
  DateTime _getWeekStart(DateTime date) {
    // Find the Thursday of the week containing the given date
    // Thursday is weekday 4, so we need to go back (date.weekday - 4) days
    int daysFromThursday = (date.weekday - DateTime.thursday) % 7;
    return date.subtract(Duration(days: daysFromThursday));
  }

  DateTime _getWeekEnd(DateTime weekStart) {
    // Wednesday is 6 days after Thursday
    return weekStart.add(const Duration(days: 6));
  }

  String _formatWeekRange(DateTime weekStart, DateTime weekEnd) {
    // Format as "18-9-25 to 24-9-25" where 25 is the year (last 2 digits)
    final startYear = weekStart.year.toString().substring(2);
    final endYear = weekEnd.year.toString().substring(2);
    return '${weekStart.day}-${weekStart.month}-$startYear to ${weekEnd.day}-${weekEnd.month}-$endYear';
  }

  void _navigateToPreviousWeek() async {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
      _weeklyDataLoaded = false; // Reset flag to reload data for new week
    });
    await _loadWeeklyData();
    _weeklyDataLoaded = true;
  }

  void _navigateToNextWeek() async {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
      _weeklyDataLoaded = false; // Reset flag to reload data for new week
    });
    await _loadWeeklyData();
    _weeklyDataLoaded = true;
  }

  Future<void> _loadMonthlyData() async {
    if (mounted) {
      final customerProvider = context.read<CustomerProvider>();
      await customerProvider.loadCustomerEntriesByMonth(
        widget.customer.customerId,
        _selectedDate.year,
        _selectedDate.month,
      );
    }
  }

  Future<void> _loadWeeklyData() async {
    final weekStart = _getWeekStart(_selectedWeek);
    final weekEnd = _getWeekEnd(weekStart);

    // Load weekly data using the existing customer provider
    if (mounted) {
      final customerProvider = context.read<CustomerProvider>();
      await customerProvider.loadCustomerEntriesByDateRange(
        widget.customer.customerId,
        weekStart,
        weekEnd,
      );

      // Store weekly data separately
      setState(() {
        _weeklyEntries = customerProvider.customerEntries.toList(); // Create a copy
      });
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildWeeklyTable(CustomerProvider customerProvider, String currentLang, bool isDarkMode, DateTime weekStart, DateTime weekEnd) {
    final customerEntries = _weeklyEntries; // Use separate weekly data

    // Get entries for the week (excluding Friday)
    final weeklyEntries = <DateTime, List<KhataEntry>>{};
    double totalTehlil = 0;
    double totalSilver = 0;
    double totalSilverPrice = 0;

    // Generate days of the week (Thursday to Wednesday, excluding Friday)
    for (int i = 0; i < 7; i++) {
      final currentDay = weekStart.add(Duration(days: i));
      if (currentDay.weekday != DateTime.friday) { // Skip Friday
        final dayEntries = customerEntries.where((entry) {
          return entry.entryDate.year == currentDay.year &&
                 entry.entryDate.month == currentDay.month &&
                 entry.entryDate.day == currentDay.day;
        }).toList();

        weeklyEntries[currentDay] = dayEntries;

        // Calculate totals for this day
        for (var entry in dayEntries) {
          totalTehlil += 1; // each entry counts as 1 tehlil
          totalSilver += entry.silverAmount ?? 0; // Use silverAmount instead of silver
          totalSilverPrice += entry.silverSold ?? 0;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Expanded(
                  flex: 2,
                  child: BilingualText.bilingual(
                    Translations.get('date', currentLang),
                    style: BilingualTextStyles.titleMedium(
                      Translations.get('date', currentLang),
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: BilingualText.bilingual(
                    Translations.get('day', currentLang),
                    style: BilingualTextStyles.titleMedium(
                      Translations.get('day', currentLang),
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: BilingualText.bilingual(
                    Translations.get('tehlil', currentLang),
                    style: BilingualTextStyles.titleMedium(
                      Translations.get('tehlil', currentLang),
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: BilingualText.bilingual(
                    Translations.get('silver', currentLang),
                    style: BilingualTextStyles.titleMedium(
                      Translations.get('silver', currentLang),
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: BilingualText.bilingual(
                    Translations.get('silver_price', currentLang),
                    style: BilingualTextStyles.titleMedium(
                      Translations.get('silver_price', currentLang),
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: ListView.builder(
              itemCount: weeklyEntries.length + (widget.customer.discountPercent != null && widget.customer.discountPercent! > 0 ? 10 : 8), // +1 for subtotal row, +1 for spacer, +6 calculation fields (or +8 with discount)
              itemBuilder: (context, index) {
                if (index == weeklyEntries.length) {
                  // Subtotal row
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9F9F9),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Expanded(
                          flex: 2,
                          child: BilingualText.bilingual(
                            '',
                            style: BilingualTextStyles.bodyMedium('', color: Colors.transparent),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: BilingualText.bilingual(
                            Translations.get('subtotal', currentLang),
                            style: BilingualTextStyles.titleMedium(
                              Translations.get('subtotal', currentLang),
                              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: BilingualText.bilingual(
                            totalTehlil.toStringAsFixed(2),
                            style: BilingualTextStyles.titleMedium(
                              totalTehlil.toStringAsFixed(2),
                              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: BilingualText.bilingual(
                            totalSilver.toStringAsFixed(2),
                            style: BilingualTextStyles.titleMedium(
                              totalSilver.toStringAsFixed(2),
                              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: BilingualText.bilingual(
                            totalSilverPrice.toStringAsFixed(2),
                            style: BilingualTextStyles.titleMedium(
                              totalSilverPrice.toStringAsFixed(2),
                              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Spacer row after subtotal
                if (index == weeklyEntries.length + 1) {
                  return const SizedBox(height: 20);
                }

                // Calculation fields rows
                final hasDiscount = widget.customer.discountPercent != null && widget.customer.discountPercent! > 0;
                final maxFieldIndex = hasDiscount ? 9 : 7;

                if (index >= weeklyEntries.length + 2 && index <= weeklyEntries.length + maxFieldIndex) {
                  return _buildCalculationField(index - weeklyEntries.length - 2, totalTehlil, totalSilverPrice, currentLang, isDarkMode);
                }

                final day = weeklyEntries.keys.elementAt(index);
                final dayEntries = weeklyEntries[day]!;
                final dayNames = currentLang == 'en'
                  ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                  : ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
                final dayName = dayNames[day.weekday - 1];

                // Calculate totals for this day
                double dayTehlil = dayEntries.length.toDouble();
                double daySilver = dayEntries.fold(0, (sum, entry) => sum + (entry.silverAmount ?? 0));
                double daySilverPrice = dayEntries.fold(0, (sum, entry) => sum + (entry.silverSold ?? 0));

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Expanded(
                        flex: 2,
                        child: BilingualText.bilingual(
                          day.day.toString(),
                          style: BilingualTextStyles.bodyLarge(
                            day.day.toString(),
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: BilingualText.bilingual(
                          dayName,
                          style: BilingualTextStyles.bodyLarge(
                            dayName,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: BilingualText.bilingual(
                          dayTehlil.toStringAsFixed(2),
                          style: BilingualTextStyles.bodyLarge(
                            dayTehlil.toStringAsFixed(2),
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: BilingualText.bilingual(
                          daySilver.toStringAsFixed(2),
                          style: BilingualTextStyles.bodyLarge(
                            daySilver.toStringAsFixed(2),
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: BilingualText.bilingual(
                          daySilverPrice.toStringAsFixed(2),
                          style: BilingualTextStyles.bodyLarge(
                            daySilverPrice.toStringAsFixed(2),
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationField(int fieldIndex, double totalTehlil, double totalSilverPrice, String currentLang, bool isDarkMode) {
    final userProvider = context.read<UserProvider>();
    final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);

    // Calculate values
    double amount = totalTehlil * tehlilPrice;

    // Apply customer discount if available
    final customerDiscount = widget.customer.discountPercent;
    if (customerDiscount != null && customerDiscount > 0) {
      final discountAmount = amount * (customerDiscount / 100);
      amount = amount - discountAmount;
    }

    final generalTotal = amount + _previousArrears + totalSilverPrice;
    final outstandingBill = generalTotal - _received;

    String fieldName = '';
    String value = '';
    bool isEditable = false;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;

    final hasDiscount = widget.customer.discountPercent != null && widget.customer.discountPercent! > 0;
    final originalAmount = totalTehlil * tehlilPrice;
    final discountAmount = hasDiscount ? originalAmount * (widget.customer.discountPercent! / 100) : 0;

    switch (fieldIndex) {
      case 0: // Original Amount (if discount exists) or Amount
        if (hasDiscount) {
          fieldName = Translations.get('original_amount', currentLang);
          value = originalAmount.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF757575);
        } else {
          fieldName = Translations.get('amount', currentLang);
          value = amount.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFFFEB3B) : const Color(0xFFFF9800);
        }
        break;
      case 1: // Discount (if exists) or Previous Arrears
        if (hasDiscount) {
          fieldName = '${Translations.get('discount', currentLang)} (${widget.customer.discountPercent!.toStringAsFixed(1)}%)';
          value = discountAmount.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF7B1FA2);
        } else {
          fieldName = Translations.get('previous_arrears', currentLang);
          value = _previousArrears.toStringAsFixed(2);
          isEditable = true;
          textColor = isDarkMode ? const Color(0xFFE91E63) : const Color(0xFFD81B60);
        }
        break;
      case 2: // Final Amount (if discount exists) or Silver Price
        if (hasDiscount) {
          fieldName = Translations.get('amount', currentLang);
          value = amount.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFFFEB3B) : const Color(0xFFFF9800);
        } else {
          fieldName = currentLang == 'en' ? 'Silver Price' : 'چاندی کی قیمت';
          value = totalSilverPrice.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF616161);
        }
        break;
      case 3: // Silver Price (if discount exists) or Previous Arrears
        if (hasDiscount) {
          fieldName = currentLang == 'en' ? 'Silver Price' : 'چاندی کی قیمت';
          value = totalSilverPrice.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF616161);
        } else {
          fieldName = Translations.get('general_total', currentLang);
          value = generalTotal.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
        }
        break;
      case 4: // Previous Arrears (if discount exists) or Received
        if (hasDiscount) {
          fieldName = Translations.get('previous_arrears', currentLang);
          value = _previousArrears.toStringAsFixed(2);
          isEditable = true;
          textColor = isDarkMode ? const Color(0xFFE91E63) : const Color(0xFFD81B60);
        } else {
          fieldName = Translations.get('received', currentLang);
          value = _received.toStringAsFixed(2);
          isEditable = true;
          textColor = isDarkMode ? const Color(0xFF2196F3) : const Color(0xFF1976D2);
        }
        break;
      case 5: // General Total (if discount exists) or Outstanding Bill
        if (hasDiscount) {
          fieldName = Translations.get('general_total', currentLang);
          value = generalTotal.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
        } else {
          fieldName = Translations.get('outstanding_bill', currentLang);
          value = outstandingBill.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFFF5722) : const Color(0xFFD84315);
        }
        break;
      case 6: // Received (if discount exists)
        if (hasDiscount) {
          fieldName = Translations.get('received', currentLang);
          value = _received.toStringAsFixed(2);
          isEditable = true;
          textColor = isDarkMode ? const Color(0xFF2196F3) : const Color(0xFF1976D2);
        }
        break;
      case 7: // Outstanding Bill (if discount exists)
        if (hasDiscount) {
          fieldName = Translations.get('outstanding_bill', currentLang);
          value = outstandingBill.toStringAsFixed(2);
          textColor = isDarkMode ? const Color(0xFFFF5722) : const Color(0xFFD84315);
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            flex: 7, // Span across date, day, tehlil columns
            child: BilingualText.bilingual(
              fieldName,
              style: BilingualTextStyles.titleLarge(
                fieldName,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 5, // Span across silver and silver price columns
            child: isEditable
                ? _buildEditableField(fieldIndex, value, textColor, isDarkMode)
                : BilingualText.bilingual(
                    value,
                    style: BilingualTextStyles.titleLarge(
                      value,
                      color: textColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(int fieldIndex, String value, Color textColor, bool isDarkMode) {
    final fieldKey = 'field_$fieldIndex';

    if (!_editingControllers.containsKey(fieldKey)) {
      _editingControllers[fieldKey] = TextEditingController(text: value);
    }

    return GestureDetector(
      onDoubleTap: () => _startEditing(fieldIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: BilingualText.bilingual(
          value,
          style: BilingualTextStyles.titleLarge(
            value,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _startEditing(int fieldIndex) {
    // This will be implemented for Excel-like editing
    // For now, just show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Field'),
        content: TextField(
          controller: _editingControllers['field_$fieldIndex'],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _saveFieldValue(fieldIndex),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveFieldValue(int fieldIndex) async {
    final value = double.tryParse(_editingControllers['field_$fieldIndex']?.text ?? '0') ?? 0;
    final hasDiscount = widget.customer.discountPercent != null && widget.customer.discountPercent! > 0;

    setState(() {
      // Determine which field based on discount status (updated for new silver price field)
      if (hasDiscount) {
        // With discount: Previous Arrears = index 4, Received = index 6
        if (fieldIndex == 4) { // Previous Arrears
          _previousArrears = value;
        } else if (fieldIndex == 6) { // Received
          _received = value;
        }
      } else {
        // Without discount: Previous Arrears = index 1, Received = index 4
        if (fieldIndex == 1) { // Previous Arrears
          _previousArrears = value;
        } else if (fieldIndex == 4) { // Received
          _received = value;
        }
      }
    });

    // Save to database
    try {
      final customerProvider = context.read<CustomerProvider>();
      await customerProvider.updateCustomer(widget.customer.customerId, {
        'previous_arrears': _previousArrears,
        'received': _received,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Close dialog after successful save
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Show error to user and close dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _shareWeeklyDataViaWhatsApp(DateTime weekStart, DateTime weekEnd, String currentLang) async {
    try {
      final userProvider = context.read<UserProvider>();

      // Get customer phone number
      final customerPhone = widget.customer.phone;
      if (customerPhone == null || customerPhone.isEmpty) {
        _showErrorDialog(
          currentLang == 'en'
            ? 'Customer WhatsApp number not found. Please add customer phone number in customer details.'
            : 'کسٹمر کا واٹس ایپ نمبر نہیں ملا۔ براہ کرم کسٹمر کی تفصیلات میں فون نمبر شامل کریں۔'
        );
        return;
      }

      // Get primary phone number from settings (sender's WhatsApp)
      final primaryPhone = userProvider.currentUser?.primaryPhone;
      if (primaryPhone == null || primaryPhone.isEmpty) {
        _showErrorDialog(
          currentLang == 'en'
            ? 'Primary WhatsApp number not found in settings. Please add your primary phone number in user settings.'
            : 'ترتیبات میں بنیادی واٹس ایپ نمبر نہیں ملا۔ براہ کرم صارف کی ترتیبات میں اپنا بنیادی فون نمبر شامل کریں۔'
        );
        return;
      }

      // Ensure weekly data is loaded
      debugPrint('Current weekly entries count: ${_weeklyEntries.length}');
      if (_weeklyEntries.isEmpty) {
        debugPrint('Weekly entries is empty, loading data for the current week...');
        await _loadWeeklyData();
        debugPrint('After loading: ${_weeklyEntries.length} entries');
      }

      // Store context before async operations
      final buildContext = context;

      // Show loading indicator
      if (buildContext.mounted) {
        showDialog(
          context: buildContext,
          barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(currentLang == 'en' ? 'Generating PDF and opening WhatsApp...' : 'پی ڈی ایف بنایا جا رہا ہے اور واٹس ایپ کھولا جا رہا ہے...'),
            ],
          ),
        ),
      );
      }

      // Generate PDF file
      debugPrint('Starting PDF generation for weekly report...');
      final pdfFile = await _generateWeeklyPDF(weekStart, weekEnd, currentLang);
      debugPrint('PDF generation completed. File: ${pdfFile?.path}');

      // Close loading dialog
      if (buildContext.mounted) {
        Navigator.of(buildContext).pop();
      }

      if (pdfFile != null) {
        // Save PDF to Documents folder for easy access
        try {
          final documentsDir = Directory('/home/cipher/Documents');
          final sanitizedName = widget.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          final finalFileName = 'weekly_report_${sanitizedName}_${weekStart.day}_${weekStart.month}_${weekStart.year}.pdf';
          final finalFile = File('${documentsDir.path}/$finalFileName');

          // Copy from temp to Documents
          await pdfFile.copy(finalFile.path);

          // Prepare WhatsApp message
          final weekRange = _formatWeekRange(weekStart, weekEnd);
          final message = currentLang == 'en'
            ? 'Weekly Report for ${widget.customer.name}\nPeriod: $weekRange\nPlease find attached the weekly report.'
            : '${widget.customer.name} کی ہفتہ وار رپورٹ\nمدت: $weekRange\nبراہ کرم منسلک ہفتہ وار رپورٹ دیکھیں۔';

          // Clean phone number (remove spaces, dashes, etc.)
          final cleanCustomerPhone = customerPhone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

          // Add country code if not present (assuming Pakistan +92)
          String finalCustomerPhone = cleanCustomerPhone;
          if (!finalCustomerPhone.startsWith('+')) {
            if (finalCustomerPhone.startsWith('0')) {
              finalCustomerPhone = '+92${finalCustomerPhone.substring(1)}';
            } else if (finalCustomerPhone.startsWith('92')) {
              finalCustomerPhone = '+$finalCustomerPhone';
            } else {
              finalCustomerPhone = '+92$finalCustomerPhone';
            }
          }

          // Create WhatsApp URL
          final encodedMessage = Uri.encodeComponent(message);
          final whatsappUrl = 'https://wa.me/$finalCustomerPhone?text=$encodedMessage';

          debugPrint('Opening WhatsApp with URL: $whatsappUrl');

          // Open WhatsApp
          final Uri uri = Uri.parse(whatsappUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);

            if (buildContext.mounted) {
              ScaffoldMessenger.of(buildContext).showSnackBar(
                SnackBar(
                  content: Text(
                    currentLang == 'en'
                      ? 'WhatsApp opened. PDF saved to Documents/$finalFileName\nPlease manually attach the PDF file to WhatsApp.'
                      : 'واٹس ایپ کھل گیا۔ پی ڈی ایف Documents/$finalFileName میں محفوظ ہو گئی\nبراہ کرم پی ڈی ایف فائل کو واٹس ایپ میں دستی طور پر منسلک کریں۔',
                  ),
                  duration: const Duration(seconds: 7),
                  action: SnackBarAction(
                    label: currentLang == 'en' ? 'Open Folder' : 'فولڈر کھولیں',
                    onPressed: () {
                      // Open file manager to Documents folder
                      Process.run('xdg-open', [documentsDir.path]);
                    },
                  ),
                ),
              );
            }
          } else {
            throw 'Could not launch WhatsApp';
          }
        } catch (e) {
          debugPrint('Error opening WhatsApp: $e');
          if (buildContext.mounted) {
            _showErrorDialog(
              currentLang == 'en'
                ? 'Could not open WhatsApp. PDF saved to Documents. Please share manually.\nError: $e'
                : 'واٹس ایپ نہیں کھل سکا۔ پی ڈی ایف Documents میں محفوظ ہو گئی۔ براہ کرم دستی طور پر شیئر کریں۔\nخرابی: $e'
            );
          }
        }
      } else {
        _showErrorDialog(
          currentLang == 'en'
            ? 'Failed to generate PDF file. No data available for the selected week.'
            : 'پی ڈی ایف فائل بنانے میں ناکامی۔ منتخب ہفتے کے لیے کوئی ڈیٹا دستیاب نہیں۔'
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      final buildContext = context;
      if (buildContext.mounted && Navigator.of(buildContext).canPop()) {
        Navigator.of(buildContext).pop();
      }

      if (mounted) {
        _showErrorDialog(
          currentLang == 'en'
            ? 'Error sharing PDF via WhatsApp: $e'
            : 'واٹس ایپ کے ذریعے پی ڈی ایف شیئر کرنے میں خرابی: $e'
        );
      }
    }
  }

  Future<File?> _generateWeeklyPDF(DateTime weekStart, DateTime weekEnd, String currentLang) async {
    try {
      // Store context access before async operations
      final userProvider = context.read<UserProvider>();
      final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);
      debugPrint('TehlilPrice retrieved: $tehlilPrice');

      // Calculate all values for the weekly data
      final customerEntries = _weeklyEntries;
      debugPrint('Found ${customerEntries.length} weekly entries for PDF generation');

      final weeklyEntries = <DateTime, List<KhataEntry>>{};
      double totalTehlil = 0;
      double totalSilver = 0;
      double totalSilverPrice = 0;

      // Generate days of the week (Thursday to Wednesday, excluding Friday)
      for (int i = 0; i < 7; i++) {
        final currentDay = weekStart.add(Duration(days: i));
        if (currentDay.weekday != DateTime.friday) { // Skip Friday
          final dayEntries = customerEntries.where((entry) {
            return entry.entryDate.year == currentDay.year &&
                   entry.entryDate.month == currentDay.month &&
                   entry.entryDate.day == currentDay.day;
          }).toList();

          // Always add the day, even if it has no entries (for complete week view)
          weeklyEntries[currentDay] = dayEntries;

          // Calculate totals for this day
          for (var entry in dayEntries) {
            totalTehlil += 1;
            totalSilver += entry.silverAmount ?? 0;
            totalSilverPrice += entry.silverSold ?? 0;
          }
        }
      }

      debugPrint('Weekly entries map size: ${weeklyEntries.length}');
      debugPrint('Total entries processed: ${customerEntries.length}');

      // Calculate financial fields
      double amount = totalTehlil * tehlilPrice;

      // Apply customer discount if available
      final customerDiscount = widget.customer.discountPercent;
      if (customerDiscount != null && customerDiscount > 0) {
        final discountAmount = amount * (customerDiscount / 100);
        amount = amount - discountAmount;
      }

      final generalTotal = amount + _previousArrears + totalSilverPrice;
      final outstandingBill = generalTotal - _received;

      // Initialize PDF text service with mixed font support
      debugPrint('Initializing PDF fonts...');
      await PdfTextService.instance.initializeFonts();
      debugPrint('PDF fonts initialized successfully');

      debugPrint('Creating PDF document...');
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with customer name and week range
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      PdfTextService.instance.createStyledText(
                        currentLang == 'en'
                          ? 'Weekly Report'
                          : 'ہفتہ وار رپورٹ',
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      PdfTextService.instance.createStyledText(
                        currentLang == 'en'
                          ? 'Customer: ${widget.customer.name}'
                          : 'کسٹمر: ${widget.customer.name}',
                        fontSize: 16,
                      ),
                      pw.SizedBox(height: 5),
                      PdfTextService.instance.createStyledText(
                        _formatWeekRange(weekStart, weekEnd),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                // Table section with flexible height
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    children: [
                      // Table header
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  child: pw.Row(
                    children: currentLang == 'en' ? [
                      // LTR order for English: Date, Day, Tehlil, Silver, Silver Price
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          'Date',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          'Day',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          'Tehlil',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          'Silver (grams)',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          'Silver Price',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ] : [
                      // RTL order for Urdu: Silver Price, Silver, Tehlil, Day, Date (reversed)
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          'چاندی کی قیمت',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          'چاندی (گرام)',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          'تحلیل',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          'دن',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          'تاریخ',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Table rows - ensure we have data to display
                if (weeklyEntries.isNotEmpty)
                  ...weeklyEntries.entries.map((entry) {
                    final day = entry.key;
                    final dayEntries = entry.value;
                    final dayNames = currentLang == 'en'
                      ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                      : ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
                    final dayName = dayNames[day.weekday - 1];

                    double dayTehlil = dayEntries.length.toDouble();
                    double daySilver = dayEntries.fold(0, (sum, entry) => sum + (entry.silverAmount ?? 0));
                    double daySilverPrice = dayEntries.fold(0, (sum, entry) => sum + (entry.silverSold ?? 0));

                    return pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey),
                        ),
                      ),
                      child: pw.Row(
                        children: currentLang == 'en' ? [
                          // LTR order for English: Date, Day, Tehlil, Silver, Silver Price
                          pw.Expanded(
                            flex: 2,
                            child: PdfTextService.instance.createTableCell(
                              day.day.toString(),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: PdfTextService.instance.createTableCell(
                              dayName,
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: PdfTextService.instance.createTableCell(
                              dayTehlil.toStringAsFixed(0),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: PdfTextService.instance.createTableCell(
                              daySilver.toStringAsFixed(2),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: PdfTextService.instance.createTableCell(
                              daySilverPrice.toStringAsFixed(2),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ] : [
                          // RTL order for Urdu: Silver Price, Silver, Tehlil, Day, Date (reversed)
                          pw.Expanded(
                            flex: 3,
                            child: PdfTextService.instance.createTableCell(
                              daySilverPrice.toStringAsFixed(2),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: PdfTextService.instance.createTableCell(
                              daySilver.toStringAsFixed(2),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: PdfTextService.instance.createTableCell(
                              dayTehlil.toStringAsFixed(0),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: PdfTextService.instance.createTableCell(
                              dayName,
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: PdfTextService.instance.createTableCell(
                              day.day.toString(),
                              padding: const pw.EdgeInsets.all(8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  // Show "No data" row when there are no entries
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey),
                      ),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(16),
                      child: pw.Center(
                        child: PdfTextService.instance.createStyledText(
                          currentLang == 'en' ? 'No data available for this week' : 'اس ہفتے کے لیے کوئی ڈیٹا دستیاب نہیں',
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ),

                // Subtotal row
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Row(
                    children: currentLang == 'en' ? [
                      // LTR order for English: Date, Day, Tehlil, Silver, Silver Price
                      pw.Expanded(flex: 2, child: pw.Container()),
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          'Subtotal',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          totalTehlil.toStringAsFixed(0),
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          totalSilver.toStringAsFixed(2),
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          totalSilverPrice.toStringAsFixed(2),
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ] : [
                      // RTL order for Urdu: Silver Price, Silver, Tehlil, Day, Date (reversed)
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          totalSilverPrice.toStringAsFixed(2),
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          totalSilver.toStringAsFixed(2),
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: PdfTextService.instance.createTableCell(
                          totalTehlil.toStringAsFixed(0),
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: PdfTextService.instance.createTableCell(
                          'ذیلی کل',
                          fontWeight: pw.FontWeight.bold,
                          padding: const pw.EdgeInsets.all(8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(flex: 2, child: pw.Container()),
                    ],
                  ),
                ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 15),

                // Financial summary section
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border.symmetric(
                      horizontal: pw.BorderSide(color: PdfColors.grey),
                    ),
                  ),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // Essential financial summary (removed original amount and discount details)
                      _buildPdfSummaryRow(currentLang == 'en' ? 'Amount' : 'رقم', amount.toStringAsFixed(2), currentLang),
                      _buildPdfSummaryRow(currentLang == 'en' ? 'Silver Price' : 'چاندی کی قیمت', totalSilverPrice.toStringAsFixed(2), currentLang),
                      _buildPdfSummaryRow(currentLang == 'en' ? 'Previous Arrears' : 'سابقا بقایا', _previousArrears.toStringAsFixed(2), currentLang),
                      _buildPdfSummaryRow(currentLang == 'en' ? 'General Total' : 'کل رقم', generalTotal.toStringAsFixed(2), currentLang),
                      _buildPdfSummaryRow(currentLang == 'en' ? 'Received' : 'موصول', _received.toStringAsFixed(2), currentLang),
                      _buildPdfSummaryRow(currentLang == 'en' ? 'Outstanding Bill' : 'بقایا بل', outstandingBill.toStringAsFixed(2), currentLang),
                    ],
                  ),
                ),

                // Add some bottom spacing to ensure all content fits
                pw.SizedBox(height: 10),
              ],
            );
          },
        ),
      );

      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = widget.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final fileName = 'weekly_report_${sanitizedName}_${weekStart.day}_${weekStart.month}_${weekStart.year}.pdf';
      final file = File('${tempDir.path}/$fileName');
      debugPrint('Creating PDF file at: ${file.path}');

      debugPrint('Saving PDF document...');
      final pdfBytes = await pdf.save();
      debugPrint('Writing PDF to file: ${file.path}');
      await file.writeAsBytes(pdfBytes);
      debugPrint('PDF file saved successfully');

      return file;
    } catch (e, stackTrace) {
      debugPrint('Error generating PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, String currentLang) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: currentLang == 'en' ? [
          // LTR layout for English: Label on left, Value on right
          PdfTextService.instance.createStyledText(
            label,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.left,
          ),
          PdfTextService.instance.createStyledText(
            value,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.right,
          ),
        ] : [
          // RTL layout for Urdu: Value on left, Label on right
          PdfTextService.instance.createStyledText(
            value,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.left,
          ),
          PdfTextService.instance.createStyledText(
            label,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.read<LanguageProvider>().currentLanguage == 'en' ? 'Error' : 'خرابی',
          style: const TextStyle(color: Color(0xFF0B5D3B)),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.read<LanguageProvider>().currentLanguage == 'en' ? 'OK' : 'ٹھیک ہے',
              style: const TextStyle(color: Color(0xFF0B5D3B)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: BilingualText.bilingual(
          '${_translationService.getDisplayText(widget.customer.name, currentLang)} - ${Translations.get('data', currentLang)}',
          style: BilingualTextStyles.headlineMedium(
            '${_translationService.getDisplayText(widget.customer.name, currentLang)} - ${Translations.get('data', currentLang)}',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0B5D3B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Customer info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                  ? [const Color(0xFF2D2D2D), const Color(0xFF4A4A4A)]
                  : [const Color(0xFF0B5D3B), const Color(0xFF2E7D57)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B5D3B).withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer.name,
                        style: BilingualTextStyles.titleLarge(
                          widget.customer.name,
                          color: Colors.white,
                        ).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.customer.phone != null)
                        Text(
                          widget.customer.phone!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              unselectedLabelColor: Colors.grey,
              indicatorColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              tabs: [
                Tab(
                  icon: const Icon(Icons.calendar_month),
                  child: BilingualText.bilingual(
                    Translations.get('monthly_view', currentLang),
                    style: BilingualTextStyles.labelMedium(
                      Translations.get('monthly_view', currentLang),
                      color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    ),
                  ),
                ),
                Tab(
                  icon: const Icon(Icons.view_week),
                  child: BilingualText.bilingual(
                    Translations.get('weekly_view', currentLang),
                    style: BilingualTextStyles.labelMedium(
                      Translations.get('weekly_view', currentLang),
                      color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    ),
                  ),
                ),
                Tab(
                  icon: const Icon(Icons.date_range),
                  child: BilingualText.bilingual(
                    Translations.get('date_range_view', currentLang),
                    style: BilingualTextStyles.labelMedium(
                      Translations.get('date_range_view', currentLang),
                      color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyView(),
                _buildWeeklyView(),
                _buildDateRangeView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get pending amount for current customer entries
  Widget _buildPendingAmountCard(String currentLang) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Consumer<CustomerProvider>(
          builder: (context, customerProvider, _) {
            final customerEntries = customerProvider.customerEntries;

            // Calculate pending amount with customer discount applied correctly
            final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);

            // Count pending entries
            final pendingEntries = customerEntries.where((entry) =>
              entry.status == null ||
              entry.status!.isEmpty ||
              entry.status!.toLowerCase() == 'pending'
            ).toList();

            // Calculate base amount (number of entries × tehlil price)
            double pendingAmount = pendingEntries.length * tehlilPrice;

            // Apply customer discount percentage if available
            final customerDiscount = widget.customer.discountPercent;
            if (customerDiscount != null && customerDiscount > 0) {
              final discountAmount = pendingAmount * (customerDiscount / 100);
              pendingAmount = pendingAmount - discountAmount;
            }

            return _buildStatsCard(
              Translations.get('pending_amount', currentLang),
              TehlilPriceService.instance.formatAmountCompact(pendingAmount),
              Icons.account_balance_wallet,
              const Color(0xFFFF9800),
            );
          },
        );
      },
    );
  }

  Widget _buildSilverPriceSubtotalCard(String currentLang) {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, _) {
        final customerEntries = customerProvider.customerEntries;
        // Calculate silver price subtotal from current entries
        double silverPriceSubtotal = 0;
        for (final entry in customerEntries) {
          if (entry.silverSold != null) {
            silverPriceSubtotal += entry.silverSold!;
          }
        }
        return _buildStatsCard(
          Translations.get('silver_sold', currentLang),
          silverPriceSubtotal.toStringAsFixed(2),
          Icons.monetization_on,
          const Color(0xFF9C27B0),
        );
      },
    );
  }

  Widget _buildSilverAmountSubtotalCard(String currentLang) {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, _) {
        final customerEntries = customerProvider.customerEntries;
        // Calculate silver amount subtotal from current entries
        double silverAmountSubtotal = 0;
        for (final entry in customerEntries) {
          if (entry.silverAmount != null) {
            silverAmountSubtotal += entry.silverAmount!;
          }
        }
        return _buildStatsCard(
          Translations.get('silver_amount', currentLang),
          '${silverAmountSubtotal.toStringAsFixed(2)}g',
          Icons.scale,
          const Color(0xFF00BCD4),
        );
      },
    );
  }

}