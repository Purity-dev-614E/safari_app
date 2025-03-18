import 'package:flutter/material.dart';

class CustomNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const CustomNotification({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class _CustomNotificationState extends State<CustomNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return Colors.green.shade50;
      case NotificationType.error:
        return Colors.red.shade50;
      case NotificationType.warning:
        return Colors.orange.shade50;
      case NotificationType.info:
        return Colors.blue.shade50;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case NotificationType.success:
        return Colors.green.shade700;
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.warning:
        return Colors.orange.shade700;
      case NotificationType.info:
        return Colors.blue.shade700;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getTextColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _controller.reverse().then((_) {
                      if (mounted) {
                        widget.onDismiss?.call();
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 