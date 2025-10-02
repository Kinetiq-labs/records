import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../screens/customer_search_results_screen.dart';

class SearchPopup extends StatefulWidget {
  const SearchPopup({super.key});

  @override
  State<SearchPopup> createState() => _SearchPopupState();
}

class _SearchPopupState extends State<SearchPopup> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Get customer suggestions
    final customerProvider = context.read<CustomerProvider>();
    final allCustomers = customerProvider.customers;

    final suggestions = allCustomers
        .where((customer) => customer.name.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .map((customer) => customer.name)
        .toList();

    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    Navigator.of(context).pop(); // Close the popup

    // Navigate to search results screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerSearchResultsScreen(searchQuery: query.trim()),
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isRtl = languageProvider.textDirection == TextDirection.rtl;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                          maxHeight: 500,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 8),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(isDarkMode, currentLang, isRtl),
                            _buildSearchField(isDarkMode, currentLang, isRtl),
                            if (_showSuggestions) _buildSuggestions(isDarkMode, currentLang, isRtl),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, String currentLang, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0B5D3B) : const Color(0xFF0B5D3B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (!isRtl) ...[
            const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              Translations.get('search_customer', currentLang),
              style: BilingualTextStyles.getTextStyle(
                text: Translations.get('search_customer', currentLang),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (isRtl) ...[
            const SizedBox(width: 12),
            const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ],
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDarkMode, String currentLang, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        style: BilingualTextStyles.getTextStyle(
          text: _searchController.text,
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: Translations.get('search_hint', currentLang),
          hintStyle: BilingualTextStyles.getTextStyle(
            text: Translations.get('search_hint', currentLang),
            fontSize: 16,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
          prefixIcon: !isRtl ? const Icon(Icons.search) : null,
          suffixIcon: isRtl ? const Icon(Icons.search) :
            (_searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                )
            ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF0B5D3B),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade100,
        ),
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildSuggestions(bool isDarkMode, String currentLang, bool isRtl) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: !isRtl ? const Icon(Icons.person_outline) : null,
            trailing: isRtl ? const Icon(Icons.person_outline) : const Icon(Icons.arrow_forward_ios, size: 14),
            title: Text(
              suggestion,
              style: BilingualTextStyles.getTextStyle(
                text: suggestion,
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }
}