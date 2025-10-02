import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';
import 'providers/records_provider.dart';
import 'providers/user_provider.dart';
import 'providers/language_provider.dart';
import 'providers/khata_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/daily_silver_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/zoom_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/update_provider.dart';
import 'services/supabase_sync_service.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'utils/app_themes.dart';
import 'widgets/zoom_wrapper.dart';
import 'widgets/update_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
    // Continue without sync functionality
  }

  // Configure window for desktop
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    fullScreen: false,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const RecordsApp());
  
  doWhenWindowReady(() {
    appWindow.minSize = const Size(800, 600);
    appWindow.title = "Records - Desktop Application";
    appWindow.show();
  });
}

class RecordsApp extends StatelessWidget {
  const RecordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => KhataProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider();
            provider.initialize(); // Initialize but don't wait, as we have defaults
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = DailySilverProvider();
            provider.initialize(); // Initialize for today's date
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ZoomProvider();
            provider.initialize(); // Initialize zoom level
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final syncService = SupabaseSyncService();
            // Initialize after a short delay to allow main initialization to complete
            Future.delayed(const Duration(milliseconds: 500), () {
              syncService.initialize();
            });
            return syncService;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = UpdateProvider();
            // Initialize update checking after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              provider.initialize();
            });
            return provider;
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ZoomKeyboardShortcuts(
                child: ZoomWrapper(
                  child: UpdateChecker(
                    child: MaterialApp(
                      title: 'Records',
                      debugShowCheckedModeBanner: false,
                      locale: languageProvider.locale,
                      theme: AppThemes.lightTheme,
                      darkTheme: AppThemes.darkTheme,
                      themeMode: themeProvider.systemThemeMode,
                      home: Directionality(
                        textDirection: languageProvider.textDirection,
                        child: const SplashScreen(),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}