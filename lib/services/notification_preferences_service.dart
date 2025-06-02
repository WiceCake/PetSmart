import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/models/notification_preference.dart';

class NotificationPreferencesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's notification preferences
  Future<List<NotificationPreference>> getUserPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('NotificationPreferencesService: User not authenticated');
        return [];
      }

      final response = await _supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', user.id)
          .order('type', ascending: true);

      return response
          .map((json) => NotificationPreference.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('NotificationPreferencesService: Error fetching preferences: $e');
      return [];
    }
  }

  /// Initialize default preferences for new user
  Future<bool> initializeDefaultPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('NotificationPreferencesService: User not authenticated');
        return false;
      }

      // Check if preferences already exist
      final existing = await _supabase
          .from('notification_preferences')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if (existing.isNotEmpty) {
        debugPrint('NotificationPreferencesService: Preferences already exist');
        return true;
      }

      // Create default preferences
      final defaultPrefs = DefaultNotificationPreferences.defaults
          .map((pref) => {
                ...pref,
                'user_id': user.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.from('notification_preferences').insert(defaultPrefs);
      debugPrint('NotificationPreferencesService: Default preferences created');
      return true;
    } catch (e) {
      debugPrint('NotificationPreferencesService: Error initializing preferences: $e');
      return false;
    }
  }

  /// Update notification preference
  Future<bool> updatePreference({
    required String type,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('NotificationPreferencesService: User not authenticated');
        return false;
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (pushEnabled != null) updateData['push_enabled'] = pushEnabled;
      if (emailEnabled != null) updateData['email_enabled'] = emailEnabled;
      if (inAppEnabled != null) updateData['in_app_enabled'] = inAppEnabled;

      await _supabase
          .from('notification_preferences')
          .update(updateData)
          .eq('user_id', user.id)
          .eq('type', type);

      debugPrint('NotificationPreferencesService: Preference updated for type: $type');
      return true;
    } catch (e) {
      debugPrint('NotificationPreferencesService: Error updating preference: $e');
      return false;
    }
  }

  /// Get preference for specific type
  Future<NotificationPreference?> getPreferenceByType(String type) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', user.id)
          .eq('type', type)
          .maybeSingle();

      if (response == null) return null;
      return NotificationPreference.fromJson(response);
    } catch (e) {
      debugPrint('NotificationPreferencesService: Error fetching preference: $e');
      return null;
    }
  }

  /// Check if notifications are enabled for a specific type and method
  Future<bool> isNotificationEnabled(String type, String method) async {
    try {
      final preference = await getPreferenceByType(type);
      if (preference == null) return false;

      switch (method.toLowerCase()) {
        case 'push':
          return preference.pushEnabled;
        case 'email':
          return preference.emailEnabled;
        case 'in_app':
          return preference.inAppEnabled;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('NotificationPreferencesService: Error checking notification enabled: $e');
      return false;
    }
  }

  /// Reset all preferences to default
  Future<bool> resetToDefaults() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Delete existing preferences
      await _supabase
          .from('notification_preferences')
          .delete()
          .eq('user_id', user.id);

      // Initialize defaults
      return await initializeDefaultPreferences();
    } catch (e) {
      debugPrint('NotificationPreferencesService: Error resetting preferences: $e');
      return false;
    }
  }
}
