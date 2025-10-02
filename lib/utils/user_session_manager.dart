import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../providers/khata_provider.dart';

/// Manages user session and tenant initialization
class UserSessionManager {
  /// Generate a unique tenant ID for a user
  static String _generateTenantId(User user) {
    // Special case for demo user - always use the existing tenant ID
    if (user.email == 'demo@records.app') {
      return 'tenant_2_demo_records_app';
    }

    final input = '${user.email}_${user.id ?? 0}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return 'tenant_${digest.toString().substring(0, 16)}';
  }


  /// Initialize khata provider for a specific user
  static Future<void> initializeUserSession(
    User user,
    KhataProvider khataProvider,
  ) async {
    final tenantId = _generateTenantId(user);
    await khataProvider.initialize(tenantId);
  }

  /// Initialize khata provider for demo user (when not logged in)
  static Future<void> initializeDemoSession(
    KhataProvider khataProvider,
  ) async {
    // Use the existing tenant ID for demo user
    const tenantId = 'tenant_2_demo_records_app';
    await khataProvider.initialize(tenantId);
  }

  /// Get tenant ID for a user
  static String getTenantId(User? user) {
    if (user != null) {
      return _generateTenantId(user);
    } else {
      // Return the existing tenant ID for demo user
      return 'tenant_2_demo_records_app';
    }
  }

  /// Get user context string for display
  static String getUserContext(User? user) {
    if (user != null) {
      return '${user.fullName} (${user.email})';
    } else {
      return 'Demo User (demo@records.app)';
    }
  }
}