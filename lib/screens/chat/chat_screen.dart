import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/chat_user.dart';
import '../../services/messaging_service.dart';
import '../../widgets/taskrabbit_text_field.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  late ChatUser? otherUser;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    final otherUserId = widget.conversation.getOtherUserId(currentUser.uid);
    otherUser = await MessagingService.getChatUser(otherUserId);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _markAsRead() async {
    await MessagingService.markConversationAsRead(widget.conversation.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Task Info Card (if available)
          if (widget.conversation.taskData != null) _buildTaskCard(),

          // Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: MessagingService.getConversationMessages(
                  widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.uid;
                    final showTime = _shouldShowTime(messages, index);

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      showTime: showTime,
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF00A651),
            backgroundImage: otherUser?.photoUrl != null
                ? NetworkImage(otherUser!.photoUrl!)
                : null,
            child: otherUser?.photoUrl == null
                ? Text(
                    otherUser?.initials ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (otherUser?.isOnline == true)
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Color(0xFF00A651),
                      fontSize: 12,
                    ),
                  )
                else if (otherUser?.lastSeen != null)
                  Text(
                    'Last seen ${timeago.format(otherUser!.lastSeen!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: _showChatOptions,
        ),
      ],
    );
  }

  Widget _buildTaskCard() {
    final taskData = widget.conversation.taskData!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.task_alt,
              color: Color(0xFF00A651),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskData['title'] ?? 'Task',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (taskData['budgetAmount'] != null)
                  Text(
                    'R${taskData['budgetAmount']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showComingSoon('View Task'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00A651),
              side: const BorderSide(color: Color(0xFF00A651)),
            ),
            child: const Text('View Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Colors.grey[600],
            onPressed: () => _showComingSoon('Attach File'),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF00A651),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      _messageController.clear();

      final otherUserId = widget.conversation.getOtherUserId(currentUser.uid);

      await MessagingService.sendMessage(
        conversationId: widget.conversation.id,
        receiverId: otherUserId,
        content: message,
        type: MessageType.text,
      );

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  bool _shouldShowTime(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    final timeDiff = currentMessage.timestamp.difference(nextMessage.timestamp);
    return timeDiff.inMinutes > 5;
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Task Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('View Task Details');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Block User');
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title:
                    const Text('Report', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Report User');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF00A651),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
