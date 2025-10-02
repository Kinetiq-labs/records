import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Brand palette (greens only)
  static const Color background = Color(0xFFF0FFF0); // Honeydew
  static const Color deepGreen = Color(0xFF0B5D3B);  // Premium deep green
  static const Color midGreen = Color(0xFF2E7D32);   // Medium green
  static const Color lightGreenFill = Color(0xFFE8F5E9); // Very light green fill
  static const Color borderGreen = Color(0xFF66BB6A); // For borders/focus

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();


  late final AnimationController _formController;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formFade;
  
  late final AnimationController _buttonController;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonGlow;

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();


    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _buttonGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final user = userProvider.currentUser;
      // Route to admin dashboard if user is admin, otherwise to home screen
      if (user != null && user.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: deepGreen),
      prefixIcon: Icon(icon, color: deepGreen),
      filled: true,
      fillColor: lightGreenFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGreen, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: midGreen, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.6),
      ),
      hintStyle: TextStyle(color: deepGreen.withOpacity(0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Brand circles distributed across the page using button color (deepGreen)
          // Top-left
          Positioned(
            top: -90,
            left: -60,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: deepGreen, // solid fill using button color
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Top-right
          Positioned(
            top: -70,
            right: -40,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Mid-left (inset)
          Positioned(
            top: 140,
            left: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Center-right (large)
          Positioned(
            top: 220,
            right: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom-left
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.88),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom-right (small accent)
          Positioned(
            bottom: 40,
            right: 60,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.95),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Records',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: deepGreen,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: _buildFormCard(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreenFill.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGreen.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: deepGreen, fontWeight: FontWeight.w600),
              decoration: _inputDecoration(
                label: 'Email',
                icon: Icons.email_rounded,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: deepGreen, fontWeight: FontWeight.w600),
              decoration: _inputDecoration(
                label: 'Password',
                icon: Icons.lock_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  color: deepGreen,
                  tooltip: _obscure ? 'Show' : 'Hide',
                ),
              ),
              obscureText: _obscure,
              validator: (value) {
                final v = value ?? '';
                if (v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Login button with animations
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTapDown: (_) => _buttonController.forward(),
                onTapUp: (_) => _buttonController.reverse(),
                onTapCancel: () => _buttonController.reverse(),
                child: AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScale.value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: deepGreen.withValues(alpha: 0.3 + (_buttonGlow.value * 0.3)),
                              blurRadius: 8 + (_buttonGlow.value * 8),
                              spreadRadius: _buttonGlow.value * 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deepGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: borderGreen, width: 1),
                            ),
                            elevation: 4 + (_buttonGlow.value * 4),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isLoading
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    key: ValueKey('login'),
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}