import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'fcmToken': fcmToken,
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email.split('@')[0];
    return 'User';
  }

  String get initials {
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}
