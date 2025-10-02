import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/khata_provider.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/dashboard_app_bar.dart';
import 'entries_screen.dart';

class MonthlyEntriesScreen extends StatefulWidget {
  const MonthlyEntriesScreen({super.key});

  @override
  State<MonthlyEntriesScreen> createState() => _MonthlyEntriesScreenState();
}

class _MonthlyEntriesScreenState extends State<MonthlyEntriesScreen> {
  late DateTime _selectedMonth;
  final Map<int, int> _dailyEntryCounts = {};
  bool _isLoading = false;

  // Brand palette (greens)
  static const Color deepGreen = Color(0xFF0B5D3B);
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthlyData();
    });
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final khataProvider = context.read<KhataProvider>();
      
      // Load entries for the selected month
      await khataProvider.loadEntriesByMonth(_selectedMonth.year, _selectedMonth.month);
      
      // Calculate daily entry counts
      final entries = khataProvider.entries;
      _calculateDailyEntryCounts(entries);
      
    } catch (e) {
      debugPrint('Error loading monthly data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateDailyEntryCounts(List<KhataEntry> entries) {
    _dailyEntryCounts.clear();
    
    for (var entry in entries) {
      final day = entry.entryDate.day;
      _dailyEntryCounts[day] = (_dailyEntryCounts[day] ?? 0) + 1;
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadMonthlyData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadMonthlyData();
  }

  void _previousYear() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
    });
    _loadMonthlyData();
  }

  void _nextYear() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
    });
    _loadMonthlyData();
  }

  void _onDateRowDoubleClick(int day) {
    final selectedDate = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntriesScreen(selectedDate: selectedDate),
      ),
    );
  }

  String _getMonthName(int month, String currentLang) {
    const monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return Translations.get(monthKeys[month - 1], currentLang);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DashboardAppBar(
        title: Translations.get('monthly_entries', currentLang),
        showHomeButton: true,
        onHomePressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      body: ResponsiveContainer(
        child: Column(
          children: [
            // Month/Year Navigation Header
            Container(
              width: double.infinity,
              padding: ResponsiveUtils.getResponsivePadding(context),
              margin: ResponsiveUtils.getResponsiveMargin(context),
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
                  color: const Color(0xFF0B5D3B).withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                // Year Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousYear,
                      icon: const Icon(Icons.keyboard_double_arrow_left, color: Colors.white),
                      iconSize: 28,
                    ),
                    ResponsiveText(
                      _selectedMonth.year.toString(),
                      baseFontSize: 24,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextYear,
                      icon: const Icon(Icons.keyboard_double_arrow_right, color: Colors.white),
                      iconSize: 28,
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Month Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
                      iconSize: 32,
                    ),
                    BilingualText.bilingual(
                      _getMonthName(_selectedMonth.month, currentLang),
                      style: BilingualTextStyles.headlineMedium(
                        _getMonthName(_selectedMonth.month, currentLang),
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white),
                      iconSize: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Daily Entries List
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                      ),
                    )
                  : _dailyEntryCounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              BilingualText.bilingual(
                                Translations.get('no_entries_found', currentLang),
                                style: BilingualTextStyles.headlineMedium(
                                  Translations.get('no_entries_found', currentLang),
                                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Header
                            Container(
                              padding: ResponsiveUtils.getResponsivePadding(context),
                              decoration: BoxDecoration(
                                color: lightGreenFill.withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                children: [
                                  Expanded(
                                    child: BilingualText.bilingual(
                                      Translations.get('date', currentLang),
                                      style: BilingualTextStyles.titleMedium(
                                        Translations.get('date', currentLang),
                                        color: const Color(0xFF0B5D3B),
                                      ),
                                      textAlign: currentLang == 'ur' ? TextAlign.right : TextAlign.left,
                                    ),
                                  ),
                                  Expanded(
                                    child: BilingualText.bilingual(
                                      Translations.get('entries', currentLang),
                                      style: BilingualTextStyles.titleMedium(
                                        Translations.get('entries', currentLang),
                                        color: const Color(0xFF0B5D3B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Data Rows
                            Expanded(
                              child: ListView.builder(
                                itemCount: _dailyEntryCounts.keys.length,
                                itemBuilder: (context, index) {
                                  final sortedDays = _dailyEntryCounts.keys.toList()..sort();
                                  final day = sortedDays[index];
                                  final entryCount = _dailyEntryCounts[day]!;
                                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                                  
                                  return GestureDetector(
                                    onDoubleTap: () => _onDateRowDoubleClick(day),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
                                        vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        color: index.isEven
                                            ? (isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50])
                                            : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
                                      ),
                                      child: Row(
                                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: (isDarkMode ? const Color(0xFF7FC685) : deepGreen).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: (isDarkMode ? const Color(0xFF7FC685) : deepGreen).withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      day.toString(),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: currentLang == 'ur' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                                  children: [
                                                    BilingualText.bilingual(
                                                      '${_getMonthName(date.month, currentLang)} $day, ${date.year}',
                                                      style: BilingualTextStyles.bodyMedium(
                                                        '${_getMonthName(date.month, currentLang)} $day, ${date.year}',
                                                        color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
                                                      ).copyWith(fontWeight: FontWeight.w600),
                                                    ),
                                                    BilingualText.bilingual(
                                                      _getDayName(date.weekday, currentLang),
                                                      style: BilingualTextStyles.bodySmall(
                                                        _getDayName(date.weekday, currentLang),
                                                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                                      ).copyWith(fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: deepGreen.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                entryCount.toString(),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          
          // Bottom instruction
          Container(
            margin: ResponsiveUtils.getResponsiveMargin(context),
            padding: ResponsiveUtils.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: lightGreenFill.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: deepGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BilingualText.bilingual(
                    currentLang == 'ur'
                        ? 'کسی تاریخ پر ڈبل کلک کریں اس دن کے اندراجات دیکھنے کے لیے'
                        : 'Double-click on any date to view entries for that day',
                    style: BilingualTextStyles.bodySmall(
                      currentLang == 'ur'
                          ? 'کسی تاریخ پر ڈبل کلک کریں اس دن کے اندراجات دیکھنے کے لیے'
                          : 'Double-click on any date to view entries for that day',
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ).copyWith(fontWeight: FontWeight.w500),
                    textAlign: currentLang == 'ur' ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _getDayName(int weekday, String currentLang) {
    const dayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 
      'friday', 'saturday', 'sunday'
    ];
    return Translations.get(dayKeys[weekday - 1], currentLang);
  }
}