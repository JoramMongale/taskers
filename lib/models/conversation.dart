import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String taskId;
  final String posterId;
  final String taskerId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? taskData; // Cached task info for quick display

  Conversation({
    required this.id,
    required this.taskId,
    required this.posterId,
    required this.taskerId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.unreadCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.taskData,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      posterId: json['posterId'] ?? '',
      taskerId: json['taskerId'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessageSenderId: json['lastMessageSenderId'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      taskData: json['taskData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'posterId': posterId,
      'taskerId': taskerId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'taskData': taskData,
    };
  }

  Conversation copyWith({
    String? id,
    String? taskId,
    String? posterId,
    String? taskerId,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? taskData,
  }) {
    return Conversation(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      posterId: posterId ?? this.posterId,
      taskerId: taskerId ?? this.taskerId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taskData: taskData ?? this.taskData,
    );
  }

  // Helper methods
  String getOtherUserId(String currentUserId) {
    return currentUserId == posterId ? taskerId : posterId;
  }

  bool isUnreadBy(String userId) {
    return lastMessageSenderId != userId && unreadCount > 0;
  }
}
