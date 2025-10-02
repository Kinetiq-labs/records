import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/gold_price_widget.dart';
import '../widgets/silver_price_widget.dart';
import '../widgets/new_entry_form.dart';
import '../widgets/status_summary_panel.dart';
import 'monthly_entries_screen.dart';
import 'entries_screen.dart';
import '../providers/user_provider.dart';
import '../providers/khata_provider.dart';
import '../providers/daily_silver_provider.dart';
import '../providers/language_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/new_silver_dialog.dart';
import '../widgets/search_popup.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../utils/user_session_manager.dart';
import '../utils/responsive_utils.dart';
import 'customers_screen.dart';
import 'data_analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Brand palette (greens only)
  static const Color deepGreen = Color(0xFF0B5D3B);  // Premium deep green
  static const Color lightGreenFill = Color(0xFFE8F5E9); // Very light green fill
  static const Color borderGreen = Color(0xFF66BB6A); // For borders/focus

  late AnimationController _bottomOptionsController;
  late Animation<double> _bottomOptionsSlide;
  late Animation<double> _bottomOptionsFade;
  
  // Circle state animations
  late AnimationController _circleLiftController;
  late Animation<double> _circleLift;
  late Animation<double> _circleScale;
  late Animation<double> _optionsFade;
  late Animation<double> _optionsSlide;
  
  // Panel animations
  late AnimationController _panelController;
  late Animation<double> _panelSlide;
  late Animation<double> _panelFade;
  late Animation<double> _blurAnimation;
  
  // Entries panel animations
  late AnimationController _entriesPanelController;
  late Animation<double> _entriesPanelSlide;
  late Animation<double> _entriesPanelFade;
  
  bool _isCircleExpanded = false;
  bool _isPanelOpen = false;
  bool _isEntriesPanelOpen = false; // Track entries panel state
  
  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
    
    if (_isPanelOpen) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }
  
  void _toggleEntriesPanel() {
    setState(() {
      _isEntriesPanelOpen = !_isEntriesPanelOpen;
    });
    
    if (_isEntriesPanelOpen) {
      _entriesPanelController.forward();
    } else {
      _entriesPanelController.reverse();
    }
  }

  Future<void> _initializeProviders() async {
    try {
      final userProvider = context.read<UserProvider>();
      final khataProvider = context.read<KhataProvider>();
      final customerProvider = context.read<CustomerProvider>();

      final tenantId = UserSessionManager.getTenantId(userProvider.currentUser);
      if (userProvider.isLoggedIn && userProvider.currentUser != null) {
        debugPrint('🔄 Initializing providers for user: ${userProvider.currentUser!.email}');
        debugPrint('🏢 Tenant ID: $tenantId');
      } else {
        debugPrint('🔄 Initializing providers for demo user');
        debugPrint('🏢 Tenant ID: $tenantId');
      }

      // Initialize both providers
      await khataProvider.initialize(tenantId);
      await customerProvider.initialize(tenantId);

      // Load current month entries for status summary
      await khataProvider.loadCurrentMonthEntries();
      debugPrint('✅ Providers initialized successfully');

    } catch (e) {
      debugPrint('❌ Error initializing providers: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize providers for logged-in user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
    
    // Bottom options animations
    _bottomOptionsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Panel animations
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Entries panel animations
    _entriesPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bottomOptionsSlide = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _bottomOptionsController,
      curve: Curves.elasticOut,
    ));
    
    _bottomOptionsFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomOptionsController,
      curve: Curves.easeInOut,
    ));
    
    // Circle lift animations
    _circleLiftController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _circleLift = Tween<double>(
      begin: 0.0,
      end: -150.0, // Move left instead of right
    ).animate(CurvedAnimation(
      parent: _circleLiftController,
      curve: Curves.easeInOut,
    ));
    
    _circleScale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _circleLiftController,
      curve: Curves.easeInOut,
    ));
    
    _optionsFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _circleLiftController,
      curve: Curves.easeInOut,
    ));
    
    _optionsSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _circleLiftController,
      curve: Curves.easeInOut,
    ));
    
    // Panel slide animation
    _panelSlide = Tween<double>(
      begin: -350.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    ));
    
    _panelFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    ));
    
    // Entries panel animations - will be initialized in didChangeDependencies
    
    // Start animations
    _startAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize entries panel animations that require MediaQuery
    _entriesPanelSlide = Tween<double>(
      begin: MediaQuery.of(context).size.height,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entriesPanelController,
      curve: Curves.easeInOut,
    ));
    
    _entriesPanelFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entriesPanelController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _bottomOptionsController.forward();
    
  }
  
  void _toggleCircleState() {
    setState(() {
      _isCircleExpanded = !_isCircleExpanded;
    });
    
    if (_isCircleExpanded) {
      _circleLiftController.forward();
    } else {
      _circleLiftController.reverse();
    }
  }

  @override
  void dispose() {
    _bottomOptionsController.dispose();
    _circleLiftController.dispose();
    _panelController.dispose();
    _entriesPanelController.dispose();
    super.dispose();
  }

  void _onOptionTap(String option) {
    if (option == 'Customer') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CustomersScreen(),
        ),
      );
    } else if (option == 'Search') {
      _showSearchPopup();
    } else {
      // Handle other options
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$option selected'),
          backgroundColor: deepGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSearchPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SearchPopup();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }


  Widget _buildSilverOptions() {
    return AnimatedBuilder(
      animation: _circleLiftController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_optionsSlide.value, 0), // Slide from right
          child: Opacity(
            opacity: _optionsFade.value,
            child: SizedBox(
              height: 280, // Match circle height for vertical alignment
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remaining Silver - Larger size
                Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: deepGreen,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: deepGreen.withAlpha(76), // 0.3 * 255 = 76.5
                        offset: const Offset(0, 6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: lightGreenFill,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<LanguageProvider>(
                              builder: (context, languageProvider, child) {
                                final currentLang = languageProvider.currentLanguage;
                                return BilingualText.bilingual(
                                  Translations.get('remaining_silver', currentLang),
                                  style: BilingualTextStyles.labelLarge(
                                    Translations.get('remaining_silver', currentLang),
                                    color: lightGreenFill,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Consumer<DailySilverProvider>(
                              builder: (context, silverProvider, child) {
                                return Text(
                                  silverProvider.formattedRemainingSilver,
                                  style: BilingualTextStyles.number(
                                    color: lightGreenFill,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // New Silver and Current Silver - Larger side by side
                SizedBox(
                  width: 320,
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const NewSilverDialog(),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              decoration: BoxDecoration(
                                color: lightGreenFill,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderGreen.withAlpha(102)), // 0.4 * 255 = 102
                                boxShadow: [
                                  BoxShadow(
                                    color: deepGreen.withAlpha(25), // 0.1 * 255 = 25.5
                                    offset: const Offset(0, 6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.fiber_new,
                                        color: deepGreen,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Consumer<LanguageProvider>(
                                          builder: (context, languageProvider, child) {
                                            final currentLang = languageProvider.currentLanguage;
                                            return BilingualText.bilingual(
                                              Translations.get('new_silver', currentLang),
                                              style: BilingualTextStyles.labelMedium(
                                                Translations.get('new_silver', currentLang),
                                                color: deepGreen,
                                              ).copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Consumer<DailySilverProvider>(
                                    builder: (context, silverProvider, child) {
                                      return Text(
                                        silverProvider.formattedNewSilver,
                                        style: BilingualTextStyles.number(
                                          color: deepGreen,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            color: lightGreenFill,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderGreen.withAlpha(102)), // 0.4 * 255 = 102
                            boxShadow: [
                              BoxShadow(
                                color: deepGreen.withAlpha(25), // 0.1 * 255 = 25.5
                                offset: const Offset(0, 6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    color: deepGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Consumer<LanguageProvider>(
                                      builder: (context, languageProvider, child) {
                                        final currentLang = languageProvider.currentLanguage;
                                        return BilingualText.bilingual(
                                          Translations.get('present_silver', currentLang),
                                          style: BilingualTextStyles.labelMedium(
                                            Translations.get('present_silver', currentLang),
                                            color: deepGreen,
                                          ).copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Consumer<DailySilverProvider>(
                                builder: (context, silverProvider, child) {
                                  return Text(
                                    silverProvider.formattedPresentSilver,
                                    style: BilingualTextStyles.number(
                                      color: deepGreen,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
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
      },
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (delay * 200)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 70,
        height: 70,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          shadowColor: deepGreen.withAlpha(76), // 0.3 * 255 = 76.5
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    lightGreenFill,
                    Colors.white,
                    lightGreenFill,
                  ],
                ),
                border: Border.all(
                  color: borderGreen.withAlpha(102), // 0.4 * 255 = 102
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: deepGreen.withAlpha(127), // 0.5 * 255 = 127.5
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(127), // 0.5 * 255 = 127.5
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: deepGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: deepGreen.withAlpha(76), // 0.3 * 255 = 76.5
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: deepGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 350,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : lightGreenFill,
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? const Color(0xFF2D2D2D) : deepGreen).withAlpha(76), // 0.3 * 255 = 76.5
            offset: const Offset(2, 0),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Column(
        children: [
          // Add some top padding since we removed the toggle buttons
          SizedBox(height: 60),
          
          // Status Summary Panel
          const Expanded(
            child: StatusSummaryPanel(),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEntriesPanel() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 400, // Fixed height for the entries panel
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : lightGreenFill,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? const Color(0xFF2D2D2D) : deepGreen).withAlpha(102),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : deepGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Text(
              'Entries Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Options section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // New Entries option
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD), // Light blue background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2196F3).withAlpha(127)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withAlpha(76),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _toggleEntriesPanel();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => const NewEntryForm(),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFF1565C0), // Dark blue
                                  size: 32,
                                ),
                                SizedBox(width: 20),
                                Text(
                                  'New Entries',
                                  style: TextStyle(
                                    color: Color(0xFF1565C0), // Dark blue
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Today Entries option
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD), // Light yellow background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFC107).withAlpha(127)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withAlpha(76),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _toggleEntriesPanel();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EntriesScreen(
                                  selectedDate: DateTime.now(),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.today_outlined,
                                  color: Color(0xFF856404), // Dark yellow
                                  size: 32,
                                ),
                                SizedBox(width: 20),
                                Text(
                                  'Today Entries',
                                  style: TextStyle(
                                    color: Color(0xFF856404), // Dark yellow
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Monthly Entries option
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Light green background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50).withAlpha(127)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withAlpha(76),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _toggleEntriesPanel();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MonthlyEntriesScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: Color(0xFF2E7D32), // Dark green
                                  size: 32,
                                ),
                                SizedBox(width: 20),
                                Text(
                                  'Monthly Entries',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32), // Dark green
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_panelController, _entriesPanelController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Main Scaffold - disable interactions when any panel is open
            AbsorbPointer(
              absorbing: _isPanelOpen || _isEntriesPanelOpen,
              child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: const DashboardAppBar(title: 'Dashboard'),
              body: Stack(
                children: [

              // Main content
              Column(
                children: [
          // Center Area with Circle and Options
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.only(top: 80), // Add top padding to move circle down
              child: Center(
                child: AnimatedBuilder(
                animation: _circleLiftController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circle with glitter effect (moves to left when expanded)
                      Transform.translate(
                        offset: Offset(_circleLift.value, 0), // Move horizontally
                        child: Transform.scale(
                          scale: _circleScale.value,
                          child: 
                              // Main circle
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: _isCircleExpanded ? [
                                      lightGreenFill, // Light green center when expanded
                                      const Color(0xFFE8F5E9), // Lighter green middle
                                      borderGreen.withAlpha(76), // 0.3 * 255 = 76.5
                                    ] : [
                                      deepGreen, // Use time color from top bar
                                      deepGreen.withAlpha(204), // 0.8 * 255 = 204
                                      deepGreen.withAlpha(153), // 0.6 * 255 = 153
                                    ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: deepGreen.withAlpha(102), // 0.4 * 255 = 102
                                      offset: const Offset(0, 8),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: borderGreen.withAlpha(76), // 0.3 * 255 = 76.5
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleCircleState,
                                    borderRadius: BorderRadius.circular(140),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isCircleExpanded
                                              ? deepGreen.withAlpha(127) // 0.5 * 255 = 127.5
                                              : borderGreen.withAlpha(127), // 0.5 * 255 = 127.5
                                          width: 3,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _isCircleExpanded ? 'Hide Silver' : 'Show Silver',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: _isCircleExpanded 
                                                ? deepGreen // Dark green text when expanded
                                                : const Color(0xFFE0E0E0), // Light text when collapsed
                                            letterSpacing: 1.5,
                                            shadows: _isCircleExpanded ? [] : [
                                              const Shadow(
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                                color: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      
                      // Silver options on the right when expanded
                      if (_isCircleExpanded) ...[
                        const SizedBox(width: 30),
                        _buildSilverOptions(),
                      ],
                    ],
                  );
                },
              ),
            ),
            ),
          ),
          
          // Bottom Options
          SizedBox(
            height: 110, // Fixed height instead of flex
            child: AnimatedBuilder(
              animation: _bottomOptionsController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bottomOptionsSlide.value),
                  child: Opacity(
                    opacity: _bottomOptionsFade.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: deepGreen, // Use time color as background
                        boxShadow: [
                          BoxShadow(
                            color: deepGreen.withAlpha(76), // 0.3 * 255 = 76.5
                            offset: const Offset(0, -4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOptionCard(
                            title: 'Entries',
                            icon: Icons.list_alt_rounded,
                            onTap: () => _toggleEntriesPanel(),
                            delay: 0,
                          ),
                          _buildOptionCard(
                            title: 'Customer',
                            icon: Icons.people_outline_rounded,
                            onTap: () => _onOptionTap('Customer'),
                            delay: 1,
                          ),
                          _buildOptionCard(
                            title: 'Search',
                            icon: Icons.search_rounded,
                            onTap: () => _onOptionTap('Search'),
                            delay: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

              // Gold Price Widget (left side)
              const Positioned(
                top: 20,
                left: 20,
                child: GoldPriceWidget(),
              ),

              // Silver Price Widget (right side)
              const Positioned(
                top: 20,
                right: 20,
                child: const SilverPriceWidget(),
              ),

              // Data Analysis Button (bottom right corner)
              Positioned(
                bottom: 130, // Just above the bottom bar (110px height + 20px margin)
                right: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        deepGreen,
                        deepGreen.withAlpha(204), // 0.8 * 255 = 204
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deepGreen.withAlpha(102), // 0.4 * 255 = 102
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha(178), // 0.7 * 255 = 178
                        offset: const Offset(0, -2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataAnalyticsScreen(
                              currentLang: languageProvider.currentLanguage,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: const Center(
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

                ],
              ),
              ),
            ),

            // Full screen blur overlay when side panel is open
            if (_panelFade.value > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: GestureDetector(
                    onTap: _togglePanel,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1 * _panelFade.value),
                    ),
                  ),
                ),
              ),

            // Full screen blur overlay when entries panel is open
            if (_entriesPanelFade.value > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5.0 * _entriesPanelFade.value,
                    sigmaY: 5.0 * _entriesPanelFade.value,
                  ),
                  child: GestureDetector(
                    onTap: _toggleEntriesPanel,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1 * _entriesPanelFade.value),
                    ),
                  ),
                ),
              ),

            // Sliding Panel - now outside Scaffold to cover AppBar
            Positioned(
              left: _panelSlide.value,
              top: 0,
              child: Opacity(
                opacity: _panelFade.value,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: _buildSidePanel(),
                ),
              ),
            ),

            // Arrow Button for Panel - moved outside Scaffold
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: _panelSlide.value + 350,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _togglePanel,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: deepGreen.withAlpha(204), // 0.8 * 255 = 204
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: deepGreen.withAlpha(76), // 0.3 * 255 = 76.5
                          offset: const Offset(2, 0),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPanelOpen ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A3325) : lightGreenFill,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Entries Panel - slides up from bottom
            AnimatedBuilder(
              animation: _entriesPanelController,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: _entriesPanelSlide.value,
                  child: Opacity(
                    opacity: _entriesPanelFade.value,
                    child: _buildEntriesPanel(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
