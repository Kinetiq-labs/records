import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthHelper {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // Create a simple email-based authentication for sync
  static Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Sign up new user for sync
  static Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Simple anonymous-like authentication using a generated email
  static Future<AuthResponse?> signInAnonymously() async {
    try {
      // Generate a unique email for this device using a valid domain
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      final email = 'sync$deviceId@recordsapp.com';
      final password = 'RecordsSync$deviceId!';

      // Try to sign in first
      var response = await signInWithEmail(email: email, password: password);

      // If sign in fails, create the account
      if (response == null || response.user == null) {
        response = await signUpWithEmail(email: email, password: password);
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Sign out
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Sign out error handled silently
    }
  }
}