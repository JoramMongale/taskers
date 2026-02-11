import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/chat_user.dart';
import '../models/task.dart';

class MessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';
  static const String _usersCollection = 'users';

  // Start a conversation (when tasker contacts poster about a task)
  static Future<String> startConversation({
    required String taskId,
    required String posterId,
    required String taskerId,
    required String initialMessage,
    Map<String, dynamic>? taskData,
  }) async {
    try {
      print('💬 Starting conversation for task: $taskId');

      // Check if conversation already exists
      final existingConversation =
          await getConversationByTask(taskId, posterId, taskerId);
      if (existingConversation != null) {
        print('✅ Conversation already exists: ${existingConversation.id}');
        return existingConversation.id;
      }

      // Create new conversation
      final conversationId =
          _firestore.collection(_conversationsCollection).doc().id;
      final now = DateTime.now();

      final conversation = Conversation(
        id: conversationId,
        taskId: taskId,
        posterId: posterId,
        taskerId: taskerId,
        lastMessage: initialMessage,
        lastMessageTime: now,
        lastMessageSenderId: taskerId, // Tasker usually initiates
        unreadCount: 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        taskData: taskData,
      );

      // Save conversation
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .set(conversation.toJson());

      // Send initial message
      await sendMessage(
        conversationId: conversationId,
        receiverId: posterId,
        content: initialMessage,
        type: MessageType.text,
      );

      print('✅ Conversation started successfully: $conversationId');
      return conversationId;
    } catch (e) {
      print('❌ Error starting conversation: $e');
      throw Exception('Failed to start conversation: $e');
    }
  }

  // Send a message
  static Future<String> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    required MessageType type,
    String? fileUrl,
    String? fileName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      print('📤 Sending message to conversation: $conversationId');

      final messageId = _firestore.collection(_messagesCollection).doc().id;
      final now = DateTime.now();

      final message = Message(
        id: messageId,
        conversationId: conversationId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        content: content,
        type: type,
        status: MessageStatus.sending,
        timestamp: now,
        fileUrl: fileUrl,
        fileName: fileName,
        metadata: metadata,
      );

      // Save message
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .set(message.toJson());

      // Update conversation with last message
      await _updateConversationLastMessage(
        conversationId: conversationId,
        lastMessage: type == MessageType.text ? content : _getTypeLabel(type),
        senderId: currentUser.uid,
        timestamp: now,
      );

      // Update message status to sent
      await _updateMessageStatus(messageId, MessageStatus.sent);

      print('✅ Message sent successfully: $messageId');
      return messageId;
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get conversations for current user
  static Stream<List<Conversation>> getUserConversations() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    print('📖 Streaming conversations for user: ${currentUser.uid}');

    return _firestore
        .collection(_conversationsCollection)
        .where('isActive', isEqualTo: true)
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Conversation.fromJson(data);
      }).toList();
    });
  }

  // Alternative query for conversations (if participants field doesn't exist)
  static Stream<List<Conversation>> getUserConversationsAlternative() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    print(
        '📖 Streaming conversations for user (alternative): ${currentUser.uid}');

    // Get conversations where user is either poster or tasker
    return _firestore
        .collection(_conversationsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Conversation.fromJson(data);
          })
          .where((conversation) =>
              conversation.posterId == currentUser.uid ||
              conversation.taskerId == currentUser.uid)
          .toList();
    });
  }

  // Get messages for a conversation
  static Stream<List<Message>> getConversationMessages(String conversationId) {
    print('📖 Streaming messages for conversation: $conversationId');

    return _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 messages for performance
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Message.fromJson(data);
      }).toList();
    });
  }

  // Mark conversation as read
  static Future<void> markConversationAsRead(String conversationId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      print('👁️ Marking conversation as read: $conversationId');

      // Update conversation unread count
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark messages as read
      final messagesQuery = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isNotEqualTo: 'read')
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.toString().split('.').last,
        });
      }
      await batch.commit();

      print('✅ Conversation marked as read');
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
    }
  }

  // Get user info for chat
  static Future<ChatUser?> getChatUser(String userId) async {
    try {
      print('👤 Fetching chat user: $userId');

      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final chatUser = ChatUser(
          id: userId,
          name: data['displayName'] ?? '',
          email: data['email'] ?? '',
          photoUrl: data['profileImageUrl'],
          isOnline: data['isOnline'] ?? false,
          lastSeen: data['lastSeen'] != null
              ? (data['lastSeen'] as Timestamp).toDate()
              : null,
          fcmToken: data['fcmToken'],
        );

        print('✅ Chat user found: ${chatUser.name}');
        return chatUser;
      } else {
        print('❌ Chat user not found: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching chat user: $e');
      return null;
    }
  }

  // Get conversation by task and participants
  static Future<Conversation?> getConversationByTask(
    String taskId,
    String posterId,
    String taskerId,
  ) async {
    try {
      print('🔍 Looking for existing conversation for task: $taskId');

      final query = await _firestore
          .collection(_conversationsCollection)
          .where('taskId', isEqualTo: taskId)
          .where('posterId', isEqualTo: posterId)
          .where('taskerId', isEqualTo: taskerId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        final conversation = Conversation.fromJson(data);
        print('✅ Found existing conversation: ${conversation.id}');
        return conversation;
      }

      print('❌ No existing conversation found');
      return null;
    } catch (e) {
      print('❌ Error finding conversation: $e');
      return null;
    }
  }

  // Update user online status
  static Future<void> updateUserOnlineStatus(bool isOnline) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      print('✅ Updated online status: $isOnline');
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  // Delete conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      print('🗑️ Deleting conversation: $conversationId');

      // Mark conversation as inactive instead of deleting
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Conversation deleted successfully');
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Private helper methods
  static Future<void> _updateConversationLastMessage({
    required String conversationId,
    required String lastMessage,
    required String senderId,
    required DateTime timestamp,
  }) async {
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .update({
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(timestamp),
      'lastMessageSenderId': senderId,
      'unreadCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _updateMessageStatus(
      String messageId, MessageStatus status) async {
    await _firestore.collection(_messagesCollection).doc(messageId).update({
      'status': status.toString().split('.').last,
    });
  }

  static String _getTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.system:
        return 'System message';
      default:
        return 'Message';
    }
  }

  // Get total unread messages count
  static Stream<int> getUnreadMessagesCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return getUserConversationsAlternative().map((conversations) {
      return conversations
          .where((conv) => conv.isUnreadBy(currentUser.uid))
          .length;
    });
  }
}
