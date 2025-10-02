import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with your actual Supabase URL and anon key
  static const String supabaseUrl = 'https://rwxqgfgscnghwzpcnskw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eHFnZmdzY25naHd6cGNuc2t3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NjI5OTMsImV4cCI6MjA3NDUzODk5M30.B6e50AL7bgWj1ROzLbA81D5z7pCqCyOvPQbXPErirNI';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false, // Set to true for development
    );
  }

  // Table names - keep consistent with local database
  static const String businessYearsTable = 'business_years';
  static const String businessMonthsTable = 'business_months';
  static const String businessDaysTable = 'business_days';
  static const String khataEntriesTable = 'khata_entries';
  static const String customersTable = 'customers';
  static const String syncMetadataTable = 'sync_metadata';

  // Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;
}