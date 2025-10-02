import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/language_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/khata_provider.dart';
import '../providers/user_provider.dart';
import '../models/khata_entry.dart';
import '../models/customer.dart';
import '../utils/translations.dart';
import '../services/tehlil_price_service.dart';
import '../services/pdf_text_service.dart';

class OverallWeeklyReportScreen extends StatefulWidget {
  const OverallWeeklyReportScreen({super.key});

  @override
  State<OverallWeeklyReportScreen> createState() => _OverallWeeklyReportScreenState();
}

class _OverallWeeklyReportScreenState extends State<OverallWeeklyReportScreen> {
  late DateTime _selectedWeek;
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _dataScrollController = ScrollController();
  final Map<DateTime, Map<Customer, List<KhataEntry>>> _weeklyData = {};
  bool _isLoading = false;
  bool _isScrollingSyncing = false;

  // Store previous arrears and received amounts for each customer
  final Map<Customer, double> _customerPreviousArrears = {};
  final Map<Customer, double> _customerReceived = {};

  // Brand palette (greens)
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _selectedWeek = _getStartOfWeek(DateTime.now());
    _setupScrollSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeeklyData();
    });
  }

  void _setupScrollSync() {
    _headerScrollController.addListener(() {
      if (!_isScrollingSyncing && _dataScrollController.hasClients) {
        _isScrollingSyncing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dataScrollController.hasClients && _headerScrollController.hasClients) {
            final targetOffset = _headerScrollController.offset.clamp(
              _dataScrollController.position.minScrollExtent,
              _dataScrollController.position.maxScrollExtent,
            );
            _dataScrollController.jumpTo(targetOffset);
          }
          _isScrollingSyncing = false;
        });
      }
    });

    _dataScrollController.addListener(() {
      if (!_isScrollingSyncing && _headerScrollController.hasClients) {
        _isScrollingSyncing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_headerScrollController.hasClients && _dataScrollController.hasClients) {
            final targetOffset = _dataScrollController.offset.clamp(
              _headerScrollController.position.minScrollExtent,
              _headerScrollController.position.maxScrollExtent,
            );
            _headerScrollController.jumpTo(targetOffset);
          }
          _isScrollingSyncing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _dataScrollController.dispose();
    super.dispose();
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Business week runs Thursday to Wednesday
    // Thursday = 4, Friday = 5, Saturday = 6, Sunday = 7, Monday = 1, Tuesday = 2, Wednesday = 3
    int daysToSubtract;
    switch (date.weekday) {
      case 1: // Monday - go back 4 days to Thursday
        daysToSubtract = 4;
        break;
      case 2: // Tuesday - go back 5 days to Thursday
        daysToSubtract = 5;
        break;
      case 3: // Wednesday - go back 6 days to Thursday
        daysToSubtract = 6;
        break;
      case 4: // Thursday - this is the start of the week
        daysToSubtract = 0;
        break;
      case 5: // Friday (holiday) - go back 1 day to Thursday
        daysToSubtract = 1;
        break;
      case 6: // Saturday - go back 2 days to Thursday
        daysToSubtract = 2;
        break;
      case 7: // Sunday - go back 3 days to Thursday
        daysToSubtract = 3;
        break;
      default:
        daysToSubtract = 0;
    }
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  Future<void> _loadWeeklyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = context.read<CustomerProvider>();
      final khataProvider = context.read<KhataProvider>();

      // Ensure customers are loaded
      await customerProvider.loadCustomers();

      _weeklyData.clear();

      // Clear and populate customer financial data
      _customerPreviousArrears.clear();
      _customerReceived.clear();

      for (final customer in customerProvider.customers) {
        _customerPreviousArrears[customer] = customer.previousArrears ?? 0.0;
        _customerReceived[customer] = customer.received ?? 0.0;
      }

      // Business week: Thursday to Wednesday, excluding Friday (holiday)
      final businessDays = [0, 2, 3, 4, 5, 6]; // Thu, Sat, Sun, Mon, Tue, Wed (skipping Fri=1)
      for (int i in businessDays) {
        final currentDay = _selectedWeek.add(Duration(days: i));
        _weeklyData[currentDay] = {};

        // Load entries for this day
        await khataProvider.loadEntriesByDate(currentDay);
        final entries = khataProvider.entries;

        // Group entries by saved customers only
        for (var entry in entries) {
          // Only include entries for customers that are saved in the customer screen
          // Use case-insensitive and trimmed comparison for better matching
          final customer = customerProvider.customers.where((c) =>
            c.name.trim().toLowerCase() == entry.name.trim().toLowerCase()
          ).firstOrNull;

          if (customer != null) {
            if (_weeklyData[currentDay]![customer] == null) {
              _weeklyData[currentDay]![customer] = [];
            }
            _weeklyData[currentDay]![customer]!.add(entry);
          }
          // If customer is not saved, skip this entry
        }
      }

    } catch (e) {
      debugPrint('Error loading weekly data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  String _getWeekRange(String currentLang) {
    final endOfWeek = _selectedWeek.add(const Duration(days: 6));
    final startDate = '${_selectedWeek.day}/${_selectedWeek.month}/${_selectedWeek.year}';
    final endDate = '${endOfWeek.day}/${endOfWeek.month}/${endOfWeek.year}';

    if (currentLang == 'ur') {
      return '$endDate - $startDate'; // RTL: end first, then start
    } else {
      return '$startDate - $endDate'; // LTR: start first, then end
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          Translations.get('overall_weekly_report', currentLang),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
          ),
        ),
        backgroundColor: const Color(0xFF0B5D3B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            currentLang == 'ur' ? Icons.arrow_back : Icons.arrow_forward,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: currentLang == 'ur' ? 'پرنٹ کریں' : 'Print Report',
            onPressed: () => _printWeeklyReport(currentLang, userProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigation Header
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
                  color: const Color(0xFF0B5D3B).withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousWeek,
                  icon: Icon(
                    currentLang == 'ur' ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),
                Column(
                  children: [
                    Text(
                      Translations.get('week', currentLang),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getWeekRange(currentLang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _nextWeek,
                  icon: Icon(
                    currentLang == 'ur' ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),
              ],
            ),
          ),

          // Weekly Data Table
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  : _buildWeeklyTable(currentLang, isDarkMode, userProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTable(String currentLang, bool isDarkMode, UserProvider userProvider) {
    // Use only saved customers from CustomerProvider
    final customerProvider = context.read<CustomerProvider>();
    final allCustomers = customerProvider.customers.toSet();

    if (allCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              currentLang == 'ur' ? 'کوئی صارف محفوظ نہیں ہے' : 'No customers saved',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightGreenFill.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
          ),
          child: Scrollbar(
            controller: _headerScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1140), // Ensure minimum table width (6 business days)
                child: Row(
                  textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                // Customer Name Column
                _buildHeaderCell(Translations.get('customer', currentLang), 150, currentLang),
                // Weekly Days Columns (Business week: Thu to Wed, excluding Fri)
                ...[0, 2, 3, 4, 5, 6].map((dayOffset) { // Thu, Sat, Sun, Mon, Tue, Wed
                  final day = _selectedWeek.add(Duration(days: dayOffset));

                  // Get the correct day name based on the actual weekday
                  String dayName;
                  if (currentLang == 'en') {
                    const dayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    dayName = dayNamesEn[day.weekday - 1];
                  } else {
                    const dayNamesUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
                    dayName = dayNamesUr[day.weekday - 1];
                  }

                  return _buildHeaderCell('$dayName\n${day.day}', 60, currentLang);
                }),
                // Calculation Fields Columns
                _buildHeaderCell(Translations.get('tehlil', currentLang), 80, currentLang),
                _buildHeaderCell(currentLang == 'ur' ? 'چاندی (گرام)' : 'Silver (grams)', 80, currentLang),
                _buildHeaderCell(Translations.get('silver_price', currentLang), 100, currentLang),
                _buildHeaderCell(Translations.get('amount', currentLang), 100, currentLang),
                _buildHeaderCell(Translations.get('previous_arrears', currentLang), 120, currentLang),
                _buildHeaderCell(Translations.get('general_total', currentLang), 120, currentLang),
                _buildHeaderCell(Translations.get('received', currentLang), 100, currentLang),
                _buildHeaderCell(Translations.get('outstanding_bill', currentLang), 120, currentLang),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Table Data
        Expanded(
          child: Scrollbar(
            controller: _dataScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _dataScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1140), // Same minimum width as header
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      // Customer Rows
                      ...allCustomers.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final customer = entry.value;
                        return _buildCustomerRow(customer, index, currentLang, isDarkMode, userProvider);
                      }),

                      // Grand Total Row
                      _buildGrandTotalRow(allCustomers, currentLang, isDarkMode, userProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _printWeeklyReport(String currentLang, UserProvider userProvider) async {
    try {
      final customerProvider = context.read<CustomerProvider>();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = await _generatePdf(format, currentLang, userProvider, customerProvider);
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint('Error printing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLang == 'ur' ? 'پرنٹ کرنے میں خرابی ہوئی' : 'Error printing report',
              style: TextStyle(
                fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdf(PdfPageFormat format, String currentLang, UserProvider userProvider, CustomerProvider customerProvider) async {
    // Initialize PDF text service for mixed text support
    debugPrint('🚀 Starting PDF generation for weekly report...');
    await PdfTextService.instance.initializeFonts();
    debugPrint('✅ PDF fonts initialized');

    final pdf = pw.Document();

    // Get customer data
    final allCustomers = customerProvider.customers.toList();

    debugPrint('📊 PDF Generation - Found ${allCustomers.length} customers');

    if (allCustomers.isEmpty) {
      debugPrint('⚠️ No customers found for PDF generation');
    } else {
      debugPrint('📋 Customers: ${allCustomers.map((c) => c.name).join(', ')}');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: currentLang == 'ur' ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
            children: [
              // Title with proper mixed text support
              PdfTextService.instance.createStyledText(
                currentLang == 'ur' ? 'مجموعی ہفتہ وار رپورٹ' : 'Overall Weekly Report',
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                textAlign: currentLang == 'ur' ? pw.TextAlign.right : pw.TextAlign.left,
              ),

              // Week range with proper mixed text support
              pw.SizedBox(height: 10),
              PdfTextService.instance.createStyledText(
                _getWeekRange(currentLang),
                fontSize: 14,
                textAlign: currentLang == 'ur' ? pw.TextAlign.right : pw.TextAlign.left,
              ),

              pw.SizedBox(height: 20),

              // Table with enhanced mixed text support
              _buildPdfTable(allCustomers, currentLang, userProvider),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfTable(List<Customer> customers, String currentLang, UserProvider userProvider) {
    final businessDays = [0, 2, 3, 4, 5, 6]; // Thu, Sat, Sun, Mon, Tue, Wed

    debugPrint('🏗️ Building PDF table for ${customers.length} customers');

    // Handle empty customer list
    if (customers.isEmpty) {
      debugPrint('⚠️ No customers to display in table');
      return pw.Text(
        currentLang == 'ur' ? 'کوئی صارف نہیں ملا' : 'No customers found',
        style: pw.TextStyle(
          font: pw.Font.helvetica(),
          fontSize: 14,
          color: PdfColors.grey,
        ),
        textAlign: pw.TextAlign.center,
      );
    }

    // Calculate column widths for better layout
    final isRTL = currentLang == 'ur';
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.5), // Customer name - wider for mixed text
      1: const pw.FlexColumnWidth(1),   // Day columns
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1),
      5: const pw.FlexColumnWidth(1),
      6: const pw.FlexColumnWidth(1),
      7: const pw.FlexColumnWidth(1.2), // Calculation columns
      8: const pw.FlexColumnWidth(1.2),
      9: const pw.FlexColumnWidth(1.2),
      10: const pw.FlexColumnWidth(1.2),
      11: const pw.FlexColumnWidth(1.2),
      12: const pw.FlexColumnWidth(1.2),
      13: const pw.FlexColumnWidth(1.2),
      14: const pw.FlexColumnWidth(1.2),
    };

    try {
      return pw.Table(
        columnWidths: columnWidths,
        border: pw.TableBorder.all(width: 0.5),
        children: [
          // Header row
          _buildPdfHeaderRow(businessDays, currentLang, isRTL),
          // Customer data rows
          ...customers.map((customer) => _buildPdfCustomerRow(customer, businessDays, currentLang, userProvider, isRTL)),
          // Grand total row
          _buildPdfGrandTotalRow(customers, businessDays, currentLang, userProvider, isRTL),
        ],
      );
    } catch (e) {
      debugPrint('💥 Error building PDF table: $e');
      return pw.Text(
        'Error generating table: $e',
        style: pw.TextStyle(
          font: pw.Font.helvetica(),
          fontSize: 12,
          color: PdfColors.red,
        ),
      );
    }
  }

  // Build header row with proper mixed text support
  pw.TableRow _buildPdfHeaderRow(List<int> businessDays, String currentLang, bool isRTL) {
    List<pw.Widget> headerCells = [];

    // Customer header
    final customerHeader = pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: PdfTextService.instance.createStyledText(
        currentLang == 'ur' ? 'صارف' : 'Customer',
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        textAlign: pw.TextAlign.center,
      ),
    );

    // Day headers
    List<pw.Widget> dayHeaders = [];
    for (int dayOffset in businessDays) {
      final day = _selectedWeek.add(Duration(days: dayOffset));
      String dayName;
      if (currentLang == 'en') {
        const dayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dayName = dayNamesEn[day.weekday - 1];
      } else {
        const dayNamesUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
        dayName = dayNamesUr[day.weekday - 1];
      }

      dayHeaders.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              PdfTextService.instance.createStyledText(
                dayName,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              PdfTextService.instance.createStyledText(
                day.day.toString(),
                fontSize: 8,
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculation headers
    final calculationHeaders = [
      currentLang == 'ur' ? 'تحلیل' : 'Tehlil',
      currentLang == 'ur' ? 'چاندی (گرام)' : 'Silver (grams)',
      currentLang == 'ur' ? 'چاندی کی قیمت' : 'Silver Price',
      currentLang == 'ur' ? 'رقم' : 'Amount',
      currentLang == 'ur' ? 'سابقا بقایا' : 'Previous Arrears',
      currentLang == 'ur' ? 'کل رقم' : 'General Total',
      currentLang == 'ur' ? 'موصول' : 'Received',
      currentLang == 'ur' ? 'باقی بل' : 'Outstanding Bill',
    ];

    List<pw.Widget> calculationHeaderWidgets = [];
    for (String header in calculationHeaders) {
      calculationHeaderWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: PdfTextService.instance.createStyledText(
            header,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Build headers in correct order based on RTL
    if (isRTL) {
      // RTL: Outstanding Bill, Received, General Total, etc., then Days, then Customer
      headerCells.addAll(calculationHeaderWidgets.reversed);
      headerCells.addAll(dayHeaders.reversed);
      headerCells.add(customerHeader);
    } else {
      // LTR: Customer, Days, then calculations
      headerCells.add(customerHeader);
      headerCells.addAll(dayHeaders);
      headerCells.addAll(calculationHeaderWidgets);
    }

    return pw.TableRow(children: headerCells);
  }

  // Build customer row with proper mixed text support
  pw.TableRow _buildPdfCustomerRow(Customer customer, List<int> businessDays, String currentLang, UserProvider userProvider, bool isRTL) {
    List<pw.Widget> rowCells = [];

    // Customer name with mixed text support
    pw.Widget customerNameWidget;
    try {
      customerNameWidget = PdfTextService.instance.createStyledText(
        customer.name,
        fontSize: 9,
        textAlign: isRTL ? pw.TextAlign.right : pw.TextAlign.left,
      );
      debugPrint('✅ Successfully created styled text for: ${customer.name}');
    } catch (e) {
      debugPrint('⚠️ Styled text failed for ${customer.name}, using fallback: $e');
      // Fallback to basic text that always works
      customerNameWidget = PdfTextService.instance.createFallbackText(
        customer.name,
        fontSize: 9,
        textAlign: isRTL ? pw.TextAlign.right : pw.TextAlign.left,
      );
    }

    final customerCell = pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: customerNameWidget,
    );

    // Calculate customer data
    int totalTehlil = 0;
    double totalSilver = 0;
    double totalSilverPrice = 0;

    // Daily counts
    List<pw.Widget> dayCells = [];
    for (int dayOffset in businessDays) {
      final day = _selectedWeek.add(Duration(days: dayOffset));
      final dayData = _weeklyData[day] ?? {};
      final customerEntries = dayData[customer] ?? [];
      final dayCount = customerEntries.length;
      totalTehlil += dayCount;

      // Calculate silver values
      for (var entry in customerEntries) {
        totalSilver += entry.silverAmount ?? 0;
        totalSilverPrice += entry.silverSold ?? 0;
      }

      dayCells.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: PdfTextService.instance.createStyledText(
            dayCount > 0 ? dayCount.toString() : '0',
            fontSize: 9,
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Get customer-specific values
    final previousArrears = _customerPreviousArrears[customer] ?? 0.0;
    final received = _customerReceived[customer] ?? 0.0;

    // Calculate field values with customer discount applied
    final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);
    double amount = totalTehlil * tehlilPrice;

    // Apply customer discount if available
    final customerDiscount = customer.discountPercent;
    if (customerDiscount != null && customerDiscount > 0) {
      final discountAmount = amount * (customerDiscount / 100);
      amount = amount - discountAmount;
    }

    final generalTotal = amount + previousArrears + totalSilverPrice;
    final outstandingBill = generalTotal - received;

    // Calculation fields
    final calculationValues = [
      totalTehlil.toString(),
      totalSilver.toStringAsFixed(2),
      totalSilverPrice.toStringAsFixed(2),
      amount.toStringAsFixed(2),
      previousArrears.toStringAsFixed(2),
      generalTotal.toStringAsFixed(2),
      received.toStringAsFixed(2),
      outstandingBill.toStringAsFixed(2),
    ];

    List<pw.Widget> calculationCells = [];
    for (String value in calculationValues) {
      calculationCells.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: PdfTextService.instance.createStyledText(
            value,
            fontSize: 9,
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Build row cells in correct order based on RTL
    if (isRTL) {
      // RTL: Calculations, Days, Customer
      rowCells.addAll(calculationCells.reversed);
      rowCells.addAll(dayCells.reversed);
      rowCells.add(customerCell);
    } else {
      // LTR: Customer, Days, Calculations
      rowCells.add(customerCell);
      rowCells.addAll(dayCells);
      rowCells.addAll(calculationCells);
    }

    return pw.TableRow(children: rowCells);
  }

  // Build grand total row for PDF
  pw.TableRow _buildPdfGrandTotalRow(List<Customer> customers, List<int> businessDays, String currentLang, UserProvider userProvider, bool isRTL) {
    List<pw.Widget> rowCells = [];

    // Calculate grand totals
    int grandTotalTehlil = 0;
    double grandTotalSilver = 0;
    double grandTotalAmount = 0;
    double grandTotalPreviousArrears = 0;
    double grandTotalSilverPrice = 0;
    double grandTotalReceived = 0;
    final List<int> dailyTotals = List.filled(businessDays.length, 0);

    for (final customer in customers) {
      int customerTehlil = 0;
      double customerSilver = 0;
      double customerSilverPrice = 0;

      for (int i = 0; i < businessDays.length; i++) {
        final dayOffset = businessDays[i];
        final day = _selectedWeek.add(Duration(days: dayOffset));
        final dayData = _weeklyData[day] ?? {};
        final customerEntries = dayData[customer] ?? [];
        final dayCount = customerEntries.length;

        dailyTotals[i] += dayCount;
        customerTehlil += dayCount;

        for (var entry in customerEntries) {
          customerSilver += entry.silverAmount ?? 0;
          customerSilverPrice += entry.silverSold ?? 0;
        }
      }

      // Calculate discounted amount for this customer
      final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);
      double customerAmount = customerTehlil * tehlilPrice;

      // Apply customer discount if available
      final customerDiscount = customer.discountPercent;
      if (customerDiscount != null && customerDiscount > 0) {
        final discountAmount = customerAmount * (customerDiscount / 100);
        customerAmount = customerAmount - discountAmount;
      }

      grandTotalTehlil += customerTehlil;
      grandTotalSilver += customerSilver;
      grandTotalSilverPrice += customerSilverPrice;
      grandTotalAmount += customerAmount; // Add discounted amount
      grandTotalPreviousArrears += _customerPreviousArrears[customer] ?? 0.0;
      grandTotalReceived += _customerReceived[customer] ?? 0.0;
    }

    final grandGeneralTotal = grandTotalAmount + grandTotalPreviousArrears + grandTotalSilverPrice;
    final grandOutstandingBill = grandGeneralTotal - grandTotalReceived;

    // Grand total label
    final grandTotalLabel = pw.Container(
      color: PdfColors.grey200,
      padding: const pw.EdgeInsets.all(4),
      child: PdfTextService.instance.createStyledText(
        currentLang == 'ur' ? 'کل رقم' : 'Grand Total',
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        textAlign: isRTL ? pw.TextAlign.right : pw.TextAlign.center,
      ),
    );

    // Daily totals
    List<pw.Widget> dailyTotalCells = [];
    for (int total in dailyTotals) {
      dailyTotalCells.add(
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.all(4),
          child: PdfTextService.instance.createStyledText(
            total.toString(),
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Calculation fields for grand total
    final grandTotalValues = [
      grandTotalTehlil.toString(),
      grandTotalSilver.toStringAsFixed(2),
      grandTotalSilverPrice.toStringAsFixed(2),
      grandTotalAmount.toStringAsFixed(2),
      grandTotalPreviousArrears.toStringAsFixed(2),
      grandGeneralTotal.toStringAsFixed(2),
      grandTotalReceived.toStringAsFixed(2),
      grandOutstandingBill.toStringAsFixed(2),
    ];

    List<pw.Widget> calculationCells = [];
    for (String value in grandTotalValues) {
      calculationCells.add(
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.all(4),
          child: PdfTextService.instance.createStyledText(
            value,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Build row cells in correct order based on RTL
    if (isRTL) {
      // RTL: Calculations, Days, Grand Total Label
      rowCells.addAll(calculationCells.reversed);
      rowCells.addAll(dailyTotalCells.reversed);
      rowCells.add(grandTotalLabel);
    } else {
      // LTR: Grand Total Label, Days, Calculations
      rowCells.add(grandTotalLabel);
      rowCells.addAll(dailyTotalCells);
      rowCells.addAll(calculationCells);
    }

    return pw.TableRow(children: rowCells);
  }

  Widget _buildHeaderCell(String title, double width, String currentLang) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0B5D3B),
          fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCustomerRow(Customer customer, int index, String currentLang, bool isDarkMode, UserProvider userProvider) {
    // Calculate weekly totals for this customer
    int totalTehlil = 0;
    double totalSilver = 0;
    double totalSilverPrice = 0;
    final List<int> dailyCounts = [];

    final businessDays = [0, 2, 3, 4, 5, 6]; // Thu, Sat, Sun, Mon, Tue, Wed (skipping Fri=1)
    for (int dayOffset in businessDays) {
      final day = _selectedWeek.add(Duration(days: dayOffset));
      final dayData = _weeklyData[day] ?? {};
      final customerEntries = dayData[customer] ?? [];
      final dayCount = customerEntries.length;
      dailyCounts.add(dayCount);
      totalTehlil += dayCount;

      // Calculate silver and silver price for this day
      for (var entry in customerEntries) {
        totalSilver += entry.silverAmount ?? 0;
        totalSilverPrice += entry.silverSold ?? 0;
      }
    }

    // Get or initialize customer-specific values
    final previousArrears = _customerPreviousArrears[customer] ?? 0.0;
    final received = _customerReceived[customer] ?? 0.0;

    // Calculate field values with customer discount applied
    final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);
    double amount = totalTehlil * tehlilPrice;

    // Apply customer discount if available
    final customerDiscount = customer.discountPercent;
    if (customerDiscount != null && customerDiscount > 0) {
      final discountAmount = amount * (customerDiscount / 100);
      amount = amount - discountAmount;
    }

    final generalTotal = amount + previousArrears + totalSilverPrice;
    final outstandingBill = generalTotal - received;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: index.isEven
            ? (isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50])
            : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1200), // Ensure minimum table width
          child: Row(
            textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Customer Name
              _buildDataCell(
              customer.name,
              150,
              isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
              FontWeight.w600,
              currentLang == 'ur' ? TextAlign.right : TextAlign.left,
              currentLang,
            ),

            // Daily Counts
            ...dailyCounts.map((count) => _buildDataCell(
              count > 0 ? count.toString() : '-',
              60,
              count > 0
                  ? (isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B))
                  : (isDarkMode ? Colors.grey[400]! : Colors.grey[500]!),
              FontWeight.w600,
              TextAlign.center,
              currentLang,
            )),

            // Tehlil Total
            _buildDataCell(
              totalTehlil.toString(),
              80,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            // Silver
            _buildDataCell(
              totalSilver.toStringAsFixed(2),
              80,
              isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF7B1FA2),
              FontWeight.w600,
              TextAlign.center,
              currentLang,
            ),

            // Silver Price
            _buildDataCell(
              totalSilverPrice.toStringAsFixed(2),
              100,
              isDarkMode ? const Color(0xFF607D8B) : const Color(0xFF455A64),
              FontWeight.w600,
              TextAlign.center,
              currentLang,
            ),

            // Amount
            _buildDataCell(
              amount.toStringAsFixed(2),
              100,
              isDarkMode ? const Color(0xFFFFEB3B) : const Color(0xFFFF9800),
              FontWeight.w600,
              TextAlign.center,
              currentLang,
            ),

            // Previous Arrears (Editable)
            _buildEditableDataCell(
              previousArrears.toStringAsFixed(2),
              120,
              isDarkMode ? const Color(0xFFE91E63) : const Color(0xFFD81B60),
              currentLang,
            ),

            // General Total
            _buildDataCell(
              generalTotal.toStringAsFixed(2),
              120,
              isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF388E3C),
              FontWeight.w600,
              TextAlign.center,
              currentLang,
            ),

            // Received (Editable)
            _buildEditableDataCell(
              received.toStringAsFixed(2),
              100,
              isDarkMode ? const Color(0xFF2196F3) : const Color(0xFF1976D2),
              currentLang,
            ),

            // Outstanding Bill
            _buildDataCell(
              outstandingBill.toStringAsFixed(2),
              120,
              isDarkMode ? const Color(0xFFFF5722) : const Color(0xFFD84315),
              FontWeight.w600,
              TextAlign.center,
              currentLang,
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String value, double width, Color color, FontWeight weight, TextAlign align, String currentLang) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: weight,
          color: color,
          fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildEditableDataCell(String value, double width, Color color, String currentLang) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: currentLang == 'ur' ? 'NotoNastaliqUrdu' : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.edit_outlined,
            size: 12,
            color: color.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalRow(Set<Customer> allCustomers, String currentLang, bool isDarkMode, UserProvider userProvider) {
    // Calculate grand totals
    int grandTotalTehlil = 0;
    double grandTotalSilver = 0;
    double grandTotalAmount = 0;
    double grandTotalPreviousArrears = 0;
    double grandTotalSilverPrice = 0;
    double grandTotalReceived = 0;
    final List<int> dailyTotals = List.filled(6, 0); // Only 6 business days

    for (final customer in allCustomers) {
      int customerTehlil = 0;
      double customerSilver = 0;
      double customerSilverPrice = 0;

      final businessDays = [0, 2, 3, 4, 5, 6]; // Thu, Sat, Sun, Mon, Tue, Wed
      for (int i = 0; i < businessDays.length; i++) {
        final dayOffset = businessDays[i];
        final day = _selectedWeek.add(Duration(days: dayOffset));
        final dayData = _weeklyData[day] ?? {};
        final customerEntries = dayData[customer] ?? [];
        final dayCount = customerEntries.length;

        dailyTotals[i] += dayCount;
        customerTehlil += dayCount;

        for (var entry in customerEntries) {
          customerSilver += entry.silverAmount ?? 0;
          customerSilverPrice += entry.silverSold ?? 0;
        }
      }

      // Calculate discounted amount for this customer
      final tehlilPrice = TehlilPriceService.instance.getTehlilPrice(userProvider.currentUser);
      double customerAmount = customerTehlil * tehlilPrice;

      // Apply customer discount if available
      final customerDiscount = customer.discountPercent;
      if (customerDiscount != null && customerDiscount > 0) {
        final discountAmount = customerAmount * (customerDiscount / 100);
        customerAmount = customerAmount - discountAmount;
      }

      grandTotalTehlil += customerTehlil;
      grandTotalSilver += customerSilver;
      grandTotalSilverPrice += customerSilverPrice;
      grandTotalAmount += customerAmount; // Add discounted amount
      grandTotalPreviousArrears += _customerPreviousArrears[customer] ?? 0.0;
      grandTotalReceived += _customerReceived[customer] ?? 0.0;
    }
    final grandGeneralTotal = grandTotalAmount + grandTotalPreviousArrears + grandTotalSilverPrice;
    final grandOutstandingBill = grandGeneralTotal - grandTotalReceived;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : lightGreenFill.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? const Color(0xFF4A7C59) : borderGreen,
            width: 2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1200), // Ensure minimum table width
          child: Row(
            textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Total Label
              _buildDataCell(
                Translations.get('total', currentLang),
              150,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              currentLang == 'ur' ? TextAlign.right : TextAlign.left,
              currentLang,
            ),

            // Daily Totals
            ...dailyTotals.map((total) => _buildDataCell(
              total > 0 ? total.toString() : '-',
              60,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            )),

            // Grand Totals for calculation fields
            _buildDataCell(
              grandTotalTehlil.toString(),
              80,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandTotalSilver.toStringAsFixed(2),
              80,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandTotalSilverPrice.toStringAsFixed(2),
              100,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandTotalAmount.toStringAsFixed(2),
              100,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandTotalPreviousArrears.toStringAsFixed(2),
              120,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandGeneralTotal.toStringAsFixed(2),
              120,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandTotalReceived.toStringAsFixed(2),
              100,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),

            _buildDataCell(
              grandOutstandingBill.toStringAsFixed(2),
              120,
              isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              FontWeight.w700,
              TextAlign.center,
              currentLang,
            ),
            ],
          ),
        ),
      ),
    );
  }
}