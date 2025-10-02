import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/khata_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../models/khata_entry.dart';
import '../models/customer.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../widgets/entry_tile.dart';

class CustomerSearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const CustomerSearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<CustomerSearchResultsScreen> createState() => _CustomerSearchResultsScreenState();
}

class _CustomerSearchResultsScreenState extends State<CustomerSearchResultsScreen> {
  List<Customer> _matchedCustomers = [];
  Map<String, List<KhataEntry>> _customerEntries = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customerProvider = context.read<CustomerProvider>();
      final khataProvider = context.read<KhataProvider>();

      // Search for matching customers
      final allCustomers = customerProvider.customers;
      final query = widget.searchQuery.toLowerCase();

      _matchedCustomers = allCustomers
          .where((customer) => customer.name.toLowerCase().contains(query))
          .toList();

      // Get entries for each matched customer
      _customerEntries.clear();
      for (final customer in _matchedCustomers) {
        try {
          final entries = await khataProvider.getEntriesByCustomerName(customer.name);
          _customerEntries[customer.name] = entries;
        } catch (e) {
          debugPrint('Error loading entries for ${customer.name}: $e');
          _customerEntries[customer.name] = [];
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isRtl = languageProvider.textDirection == TextDirection.rtl;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: languageProvider.textDirection,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: BilingualText.bilingual(
            '${Translations.get('search_results', currentLang)}: "${widget.searchQuery}"',
            style: BilingualTextStyles.getTextStyle(
              text: '${Translations.get('search_results', currentLang)}: "${widget.searchQuery}"',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF0B5D3B),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: isRtl ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: isRtl ? [
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] : null,
        ),
        body: _buildBody(isDarkMode, currentLang, isRtl),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode, String currentLang, bool isRtl) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B5D3B)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDarkMode ? Colors.red[300] : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('error_loading_data', currentLang),
              style: BilingualTextStyles.getTextStyle(
                text: Translations.get('error_loading_data', currentLang),
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5D3B),
                foregroundColor: Colors.white,
              ),
              child: Text(Translations.get('retry', currentLang)),
            ),
          ],
        ),
      );
    }

    if (_matchedCustomers.isEmpty) {
      return _buildNoResults(isDarkMode, currentLang, isRtl);
    }

    return _buildSearchResults(isDarkMode, currentLang, isRtl);
  }

  Widget _buildNoResults(bool isDarkMode, String currentLang, bool isRtl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDarkMode ? Colors.white54 : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            Translations.get('no_customers_found', currentLang),
            style: BilingualTextStyles.getTextStyle(
              text: Translations.get('no_customers_found', currentLang),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Translations.get('search_query', currentLang)}: "${widget.searchQuery}"',
            style: BilingualTextStyles.getTextStyle(
              text: '${Translations.get('search_query', currentLang)}: "${widget.searchQuery}"',
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDarkMode, String currentLang, bool isRtl) {
    return CustomScrollView(
      slivers: [
        // Summary header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.3),
              ),
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Translations.get('found_customers', currentLang)}: ${_matchedCustomers.length}',
                        style: BilingualTextStyles.getTextStyle(
                          text: '${Translations.get('found_customers', currentLang)}: ${_matchedCustomers.length}',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${Translations.get('search_query', currentLang)}: "${widget.searchQuery}"',
                        style: BilingualTextStyles.getTextStyle(
                          text: '${Translations.get('search_query', currentLang)}: "${widget.searchQuery}"',
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Customer results
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final customer = _matchedCustomers[index];
              final entries = _customerEntries[customer.name] ?? [];

              return _buildCustomerSection(customer, entries, isDarkMode, currentLang, isRtl);
            },
            childCount: _matchedCustomers.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection(
    Customer customer,
    List<KhataEntry> entries,
    bool isDarkMode,
    String currentLang,
    bool isRtl,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.3),
        ),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0B5D3B) : const Color(0xFF0B5D3B).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.white24 : Colors.white,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: BilingualTextStyles.getTextStyle(
                          text: customer.name,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0B5D3B),
                        ),
                      ),
                      Text(
                        '${entries.length} ${Translations.get('entries', currentLang)}',
                        style: BilingualTextStyles.getTextStyle(
                          text: '${entries.length} ${Translations.get('entries', currentLang)}',
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : const Color(0xFF0B5D3B).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Entries list
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                Translations.get('no_entries_found', currentLang),
                style: BilingualTextStyles.getTextStyle(
                  text: Translations.get('no_entries_found', currentLang),
                  fontSize: 14,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
              ),
            )
          else
            Column(
              children: entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: EntryTile(
                    entry: entry,
                    onTap: () {
                      // Handle entry tap if needed
                    },
                    currentLang: currentLang,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}