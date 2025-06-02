import 'package:flutter/material.dart';
import 'package:pet_smart/services/push_notification_service.dart';
import 'package:pet_smart/services/notification_service.dart';

/// Debug page to test push notifications functionality
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _lastTestResults;
  final PushNotificationService _pushService = PushNotificationService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Tests'),
        backgroundColor: const Color(0xFF233A63),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Push Notification Testing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF233A63),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these tests to verify your push notification setup is working correctly.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            _buildTestButton(
              'Test Local Notification',
              'Send a test local notification',
              Icons.notifications,
              Colors.green,
              () => _runTest(_testLocalNotification),
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              'Test Push Service',
              'Initialize push notification service',
              Icons.token,
              Colors.blue,
              () => _runTest(_testPushService),
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              'Test Database Notification',
              'Create notification in database',
              Icons.storage,
              Colors.orange,
              () => _runTest(_testDatabaseNotification),
            ),

            const SizedBox(height: 24),

            // Results Section
            if (_lastTestResults != null) ...[
              const Text(
                'Last Test Results:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A63),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _lastTestResults!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${entry.key}:',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: TextStyle(
                                    color: entry.key == 'error' ? Colors.red : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF233A63),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Future<void> _runTest(Future<Map<String, dynamic>> Function() testFunction) async {
    setState(() {
      _isLoading = true;
      _lastTestResults = null;
    });

    try {
      final results = await testFunction();
      setState(() {
        _lastTestResults = results;
      });

      // Show success/error snackbar
      if (mounted) {
        final isSuccess = results['success'] == true || results['error'] == null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess ? 'Test completed successfully!' : 'Test failed: ${results['error']}',
            ),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastTestResults = {'error': e.toString()};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test Methods
  Future<Map<String, dynamic>> _testLocalNotification() async {
    try {
      await _pushService.sendTestNotification();
      return {
        'success': true,
        'message': 'Local notification sent successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _testPushService() async {
    try {
      await _pushService.initialize();
      final isInitialized = _pushService.isInitialized;

      return {
        'success': isInitialized,
        'initialized': isInitialized,
        'local_notifications': 'Enabled',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _testDatabaseNotification() async {
    try {
      final success = await _notificationService.createNotification(
        title: 'Test Notification',
        message: 'This is a test notification created from the debug page.',
        type: 'system',
        data: {'test': true, 'source': 'debug_page'},
      );

      return {
        'success': success,
        'message': success ? 'Notification created in database' : 'Failed to create notification',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
