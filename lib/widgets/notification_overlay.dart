import 'package:flutter/material.dart';
import 'custom_notification.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.child,
  });

  static NotificationOverlayState of(BuildContext context) {
    final state = context.findAncestorStateOfType<NotificationOverlayState>();
    assert(state != null, 'No NotificationOverlay found in context');
    return state!;
  }

  @override
  NotificationOverlayState createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay> {
  final List<_NotificationEntry> _notifications = [];

  void showNotification({
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    final key = UniqueKey();
    final notification = CustomNotification(
      message: message,
      type: type,
      duration: duration,
      onDismiss: () {
        if (mounted) {
          _removeNotificationByKey(key);
        }
      },
    );

    final entry = _NotificationEntry(
      key: key,
      notification: notification,
    );

    setState(() {
      _notifications.add(entry);
    });

    // Automatically dismiss after the duration
    Future.delayed(duration, () {
      if (mounted) {
        _removeNotificationByKey(key);
      }
    });
  }

  void _removeNotificationByKey(Key key) {
    if (!mounted) return;
    
    setState(() {
      _notifications.removeWhere((entry) => entry.key == key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: _notifications.map((entry) => entry.notification).toList(),
          ),
        ),
      ],
    );
  }
}

class _NotificationEntry {
  final Key key;
  final CustomNotification notification;

  _NotificationEntry({
    required this.key,
    required this.notification,
  });
}
