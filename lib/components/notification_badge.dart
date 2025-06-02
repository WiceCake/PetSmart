import 'package:flutter/material.dart';
import 'package:pet_smart/services/notification_service.dart';
import 'package:pet_smart/pages/notifications_list.dart';

class NotificationBadge extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;
  final bool showBadge;

  const NotificationBadge({
    super.key,
    this.iconColor,
    this.iconSize = 24.0,
    this.showBadge = true,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsListPage(),
      ),
    );

    // Refresh count when returning from notifications page
    if (result != null || mounted) {
      _loadUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _navigateToNotifications,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: widget.iconColor ?? Colors.black87,
              size: widget.iconSize,
            ),
            if (widget.showBadge && _unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Simple notification icon without badge for use in navigation bars
class SimpleNotificationIcon extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback? onTap;

  const SimpleNotificationIcon({
    super.key,
    this.iconColor,
    this.iconSize = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsListPage(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.notifications_outlined,
          color: iconColor ?? Colors.black87,
          size: iconSize,
        ),
      ),
    );
  }
}

// Notification counter widget for dashboard or other pages
class NotificationCounter extends StatefulWidget {
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const NotificationCounter({
    super.key,
    this.textStyle,
    this.backgroundColor,
    this.padding,
  });

  @override
  State<NotificationCounter> createState() => _NotificationCounterState();
}

class _NotificationCounterState extends State<NotificationCounter> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _unreadCount > 99 ? '99+ new notifications' : '$_unreadCount new notification${_unreadCount > 1 ? 's' : ''}',
        style: widget.textStyle ?? const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
