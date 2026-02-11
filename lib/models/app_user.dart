import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final bool emailVerified;
  final String displayName;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final bool phoneVerified;
  final String zipCode;
  final String profileImageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final bool isVerified;
  final List<String> userTypes;
  final String? currentRole;
  final String fcmToken;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? lastActive;

  AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.phoneVerified,
    required this.zipCode,
    required this.profileImageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isVerified,
    required this.userTypes,
    this.currentRole,
    required this.fcmToken,
    required this.pushNotificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.smsNotificationsEnabled,
    this.createdAt,
    this.lastLogin,
    this.lastActive,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      emailVerified: data['emailVerified'] ?? false,
      displayName: data['displayName'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      phoneVerified: data['phoneVerified'] ?? false,
      zipCode: data['zipCode'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'active',
      isVerified: data['isVerified'] ?? false,
      userTypes: List<String>.from(data['userTypes'] ?? []),
      currentRole: data['currentRole'],
      fcmToken: data['fcmToken'] ?? '',
      pushNotificationsEnabled: data['pushNotificationsEnabled'] ?? false,
      emailNotificationsEnabled: data['emailNotificationsEnabled'] ?? true,
      smsNotificationsEnabled: data['smsNotificationsEnabled'] ?? false,
      createdAt: data['createdAt']?.toDate(),
      lastLogin: data['lastLogin']?.toDate(),
      lastActive: data['lastActive']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'emailVerified': emailVerified,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'zipCode': zipCode,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'isVerified': isVerified,
      'userTypes': userTypes,
      'currentRole': currentRole,
      'fcmToken': fcmToken,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'smsNotificationsEnabled': smsNotificationsEnabled,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }

  bool get canPostTasks => userTypes.contains('poster');
  bool get canCompleteTasks => userTypes.contains('tasker');
  bool get hasMultipleRoles => userTypes.length > 1;
}
