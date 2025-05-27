// Try to import local config if it exists
// This file should NOT be committed to Git
import 'local_config.dart' as local_config;

class AppConfig {
  // These will be replaced during build process or loaded from secure storage
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Empty default - will be handled gracefully
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Empty default - will be handled gracefully
  );

  // Get configuration with fallbacks
  static String getSupabaseUrl() {
    // 1. Try environment variable first
    if (supabaseUrl.isNotEmpty) {
      return supabaseUrl;
    }

    // 2. Try local config file
    try {
      return local_config.LocalConfig.supabaseUrl;
    } catch (e) {
      // Local config doesn't exist or has issues
    }

    // 3. Return empty - app will handle gracefully
    return '';
  }

  static String getSupabaseAnonKey() {
    // 1. Try environment variable first
    if (supabaseAnonKey.isNotEmpty) {
      return supabaseAnonKey;
    }

    // 2. Try local config file
    try {
      return local_config.LocalConfig.supabaseAnonKey;
    } catch (e) {
      // Local config doesn't exist or has issues
    }

    // 3. Return empty - app will handle gracefully
    return '';
  }

  // Check if configuration is valid
  static bool isConfigured() {
    return getSupabaseUrl().isNotEmpty && getSupabaseAnonKey().isNotEmpty;
  }
}
