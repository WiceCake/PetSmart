import 'package:flutter/material.dart';
import 'package:pet_smart/models/notification_preference.dart';
import 'package:pet_smart/services/notification_preferences_service.dart';

// Color constants matching the app theme
const Color primaryRed = Color(0xFFE57373);
const Color primaryBlue = Color(0xFF233A63);
const Color accentRed = Color(0xFFEF5350);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  List<NotificationPreference> _preferences = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize default preferences if they don't exist
      await _preferencesService.initializeDefaultPreferences();
      
      // Load user preferences
      final preferences = await _preferencesService.getUserPreferences();

      // Filter out promotional preferences (no longer supported)
      final filteredPreferences = preferences.where((pref) => pref.type != 'promotional').toList();

      setState(() {
        _preferences = filteredPreferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notification preferences';
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreference(String type, String method, bool value) async {
    try {
      bool success = false;
      
      switch (method) {
        case 'push':
          success = await _preferencesService.updatePreference(
            type: type,
            pushEnabled: value,
          );
          break;
        case 'email':
          success = await _preferencesService.updatePreference(
            type: type,
            emailEnabled: value,
          );
          break;
        case 'in_app':
          success = await _preferencesService.updatePreference(
            type: type,
            inAppEnabled: value,
          );
          break;
      }

      if (success) {
        // Reload preferences to reflect changes
        await _loadPreferences();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preference updated'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to update preference');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preference: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'appointment':
        return 'Appointments';
      case 'order':
        return 'Orders & Shopping';
      case 'messages':
        return 'Messages';
      case 'pet':
        return 'Pet Care';
      case 'system':
        return 'System Updates';
      default:
        return type;
    }
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'appointment':
        return 'Appointment confirmations, reminders, and status updates';
      case 'order':
        return 'Order confirmations, shipping updates, and delivery notifications';
      case 'messages':
        return 'New messages from customer support and chat notifications';
      case 'pet':
        return 'Pet health reminders, vaccination alerts, and care tips';
      case 'system':
        return 'App updates, security alerts, and maintenance notifications';
      default:
        return 'Notification settings for $type';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'order':
        return Icons.shopping_bag;
      case 'messages':
        return Icons.chat_bubble;
      case 'pet':
        return Icons.pets;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildPreferenceCard(NotificationPreference preference) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(preference.type),
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeDisplayName(preference.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTypeDescription(preference.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Notification method toggles
            _buildToggleRow(
              'Push Notifications',
              Icons.phone_android,
              preference.pushEnabled,
              (value) => _updatePreference(preference.type, 'push', value),
            ),
            const SizedBox(height: 8),
            _buildToggleRow(
              'Email Notifications',
              Icons.email,
              preference.emailEnabled,
              (value) => _updatePreference(preference.type, 'email', value),
            ),
            const SizedBox(height: 8),
            _buildToggleRow(
              'In-App Notifications',
              Icons.notifications,
              preference.inAppEnabled,
              (value) => _updatePreference(preference.type, 'in_app', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: primaryBlue,
          activeTrackColor: primaryBlue.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Customize how you receive notifications for different types of activities in your PetSmart app.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Notification preferences
                      ..._preferences.map((preference) => _buildPreferenceCard(preference)),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
