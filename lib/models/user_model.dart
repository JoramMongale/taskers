class UserModel {
  String? uid;
  String? email;
  String? displayName;
  String? phoneNumber;
  String? profileImageUrl;
  List<String>? userTypes; // ["poster", "tasker", "both"]
  String? currentRole; // "poster" or "tasker"

  // Location info
  String? address;
  double? latitude;
  double? longitude;

  // Account status
  String? status; // "active", "suspended", "pending"
  bool? isVerified;
  DateTime? createdAt;
  DateTime? lastLogin;

  UserModel({
    this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.profileImageUrl,
    this.userTypes,
    this.currentRole,
    this.address,
    this.latitude,
    this.longitude,
    this.status,
    this.isVerified,
    this.createdAt,
    this.lastLogin,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    email = json['email'];
    displayName = json['displayName'];
    phoneNumber = json['phoneNumber'];
    profileImageUrl = json['profileImageUrl'];
    userTypes = List<String>.from(json['userTypes'] ?? []);
    currentRole = json['currentRole'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    status = json['status'];
    isVerified = json['isVerified'];
    createdAt = json['createdAt']?.toDate();
    lastLogin = json['lastLogin']?.toDate();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['email'] = email;
    data['displayName'] = displayName;
    data['phoneNumber'] = phoneNumber;
    data['profileImageUrl'] = profileImageUrl;
    data['userTypes'] = userTypes;
    data['currentRole'] = currentRole;
    data['address'] = address;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['status'] = status;
    data['isVerified'] = isVerified;
    data['createdAt'] = createdAt;
    data['lastLogin'] = lastLogin;
    return data;
  }
}
