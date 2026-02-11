import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTime;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.showTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) const SizedBox(width: 40),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF00A651) : Colors.white,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      if (message.type != MessageType.text) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getTypeLabel(message.type),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 40),
            ],
          ),
          if (showTime) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) const SizedBox(width: 40),
                Text(
                  timeago.format(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 40),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'File';
      case MessageType.system:
        return 'System message';
      default:
        return '';
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }
}
