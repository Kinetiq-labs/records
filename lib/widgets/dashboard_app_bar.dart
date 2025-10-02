import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../screens/settings_screen.dart';
import 'profile_avatar.dart';

class DashboardAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final bool showHomeButton;
  final VoidCallback? onHomePressed;

  const DashboardAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.showHomeButton = false,
    this.onHomePressed,
  });

  @override
  State<DashboardAppBar> createState() => _DashboardAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(55);
}

class _DashboardAppBarState extends State<DashboardAppBar> {
  // Brand palette (greens only)
  static const Color background = Color(0xFFF0FFF0); // Honeydew
  static const Color deepGreen = Color(0xFF0B5D3B);  // Premium deep green
  static const Color lightGreenFill = Color(0xFFE8F5E9); // Very light green fill
  static const Color borderGreen = Color(0xFF66BB6A); // For borders/focus

  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date, String languageCode) {
    final monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    final weekdayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    
    final weekday = Translations.get(weekdayKeys[date.weekday - 1], languageCode);
    final month = Translations.get(monthKeys[date.month - 1], languageCode);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    // Use theme-aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: widget.backgroundColor ?? (isDarkMode ? const Color(0xFF1E1E1E) : background),
      foregroundColor: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
      elevation: 4,
      shadowColor: deepGreen.withOpacity(0.2),
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home button (when enabled)
          if (widget.showHomeButton)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF7FC685) : deepGreen).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: widget.onHomePressed ?? () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.home_rounded,
                  color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                  size: 24,
                ),
                tooltip: Translations.get('home', currentLang),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ),
          
          // Left: Profile with User Name and Dropdown
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              offset: const Offset(0, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDarkMode ? const Color(0xFF2D2D2D) : deepGreen,
              elevation: 8,
              shadowColor: deepGreen.withOpacity(0.3),
              onSelected: (String value) async {
                // Handle menu selection
                switch (value) {
                  case 'settings':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    break;
                  case 'theme':
                    // Cycle through theme modes (system -> light -> dark -> system)
                    final themeProvider = context.read<ThemeProvider>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    await themeProvider.cycleThemeMode();

                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${Translations.get('theme_toggle', currentLang)}: ${themeProvider.getThemeModeDisplayName(currentLang)}',
                        ),
                        backgroundColor: deepGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    break;
                  case 'language':
                    // Toggle language
                    context.read<LanguageProvider>().toggleLanguage();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(Translations.get('language_toggle', context.read<LanguageProvider>().currentLanguage)),
                        backgroundColor: deepGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    break;
                  case 'logout':
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(Translations.get('logged_out', currentLang)),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Translations.get('settings', currentLang),
                        style: BilingualTextStyles.labelLarge(
                          Translations.get('settings', currentLang),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Row(
                        children: [
                          Icon(
                            themeProvider.getThemeModeIcon(),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Translations.get('dark_light_mode', currentLang),
                                style: BilingualTextStyles.labelLarge(
                                  Translations.get('dark_light_mode', currentLang),
                                  color: Colors.white,
                                ),
                              ),
                              BilingualText.bilingual(
                                themeProvider.getThemeModeDisplayName(currentLang),
                                style: BilingualTextStyles.bodySmall(
                                  themeProvider.getThemeModeDisplayName(currentLang),
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'language',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Translations.get('english_urdu', currentLang),
                        style: BilingualTextStyles.labelLarge(
                          Translations.get('english_urdu', currentLang),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Translations.get('log_out', currentLang),
                        style: BilingualTextStyles.labelLarge(
                          Translations.get('log_out', currentLang),
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A3325) : lightGreenFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SmallProfileAvatar(),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentUser?.firstName ?? 'User',
                            style: BilingualTextStyles.getTextStyle(
                              text: currentUser?.firstName ?? 'User',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: (isDarkMode ? const Color(0xFF7FC685) : deepGreen).withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Center: Real-time Clock
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : deepGreen,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: (isDarkMode ? const Color(0xFF2D2D2D) : deepGreen).withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Translations.get('current_time', currentLang),
                    style: BilingualTextStyles.labelMedium(
                      Translations.get('current_time', currentLang),
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    _formatTime(_currentTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Right: Current Date
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A3325) : lightGreenFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Translations.get('today', currentLang),
                    style: BilingualTextStyles.labelMedium(
                      Translations.get('today', currentLang),
                      color: (isDarkMode ? const Color(0xFF7FC685) : deepGreen).withOpacity(0.7),
                    ),
                  ),
                  BilingualText.bilingual(
                    _formatDate(_currentTime, currentLang),
                    style: BilingualTextStyles.bodySmall(
                      _formatDate(_currentTime, currentLang),
                      color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(0),
        ),
      ),
    );
  }
}