import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/conversation.dart';
import '../models/chat_user.dart';
import '../services/messaging_service.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final otherUserId = conversation.getOtherUserId(currentUser.uid);
    final isUnread = conversation.isUnreadBy(currentUser.uid);

    return FutureBuilder<ChatUser?>(
      future: MessagingService.getChatUser(otherUserId),
      builder: (context, snapshot) {
        final chatUser = snapshot.data;
        final userName = chatUser?.displayName ?? 'User';
        final userInitials = chatUser?.initials ?? 'U';

        return Container(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF00A651),
                        backgroundImage: chatUser?.photoUrl != null
                            ? NetworkImage(chatUser!.photoUrl!)
                            : null,
                        child: chatUser?.photoUrl == null
                            ? Text(
                                userInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      if (chatUser?.isOnline == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeago.format(conversation.lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnread
                                    ? const Color(0xFF00A651)
                                    : Colors.grey[500],
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isUnread
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontWeight: isUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A651),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        if (conversation.taskData != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A651).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Task: ${conversation.taskData!['title'] ?? 'Unknown Task'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00A651),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
