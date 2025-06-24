import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final Color badgeColor;
  final Stream<int>? streamCount;

  const NotificationBadge({
    Key? key,
    required this.onPressed,
    this.size = 50,
    this.backgroundColor = Colors.white,
    this.iconColor = const Color(0xFF159BBD),
    this.badgeColor = Colors.red,
    this.streamCount,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bouton de notification principal
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: Icon(
                Icons.notifications,
                color: widget.iconColor,
                size: widget.size * 0.4,
              ),
            ),
          ),
        ),
        
        // Badge pour les notifications non lues
        Positioned(
          right: 0,
          top: 0,
          child: StreamBuilder<int>(
            stream: widget.streamCount ?? NotificationService.getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) {
                return const SizedBox.shrink();
              }
              
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.backgroundColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.badgeColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 