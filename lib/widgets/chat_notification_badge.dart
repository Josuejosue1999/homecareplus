import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatNotificationBadge extends StatelessWidget {
  final Widget child;
  final double? top;
  final double? right;
  final Color? badgeColor;
  final Color? textColor;

  const ChatNotificationBadge({
    Key? key,
    required this.child,
    this.top,
    this.right,
    this.badgeColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top ?? -5,
          right: right ?? -5,
          child: StreamBuilder<int>(
            stream: ChatService.getPatientUnreadConversationCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data! > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    snapshot.data! > 99 ? '99+' : snapshot.data!.toString(),
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
} 