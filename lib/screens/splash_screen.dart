import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Color _backgroundColor = Color(0xFFF0FFF0); // Honeydew
  static const Color _titleColor = Color(0xFF0B5D3B); // Deep premium green

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fade = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize database service with sample data for demo
      await DatabaseService.instance.initialize(createSampleData: true);

      // Optional: small delay to let the animation be visible
      await Future.delayed(const Duration(milliseconds: 1000));
    } catch (e) {
      // If something goes wrong, still proceed to app (could show an error screen instead)
      debugPrint('Initialization error: $e');
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Text(
                    'Records',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _titleColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      shadows: const [
                        Shadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(_titleColor),
                  backgroundColor: _titleColor.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}