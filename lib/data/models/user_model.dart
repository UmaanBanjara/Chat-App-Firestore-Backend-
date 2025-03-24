import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isOnline;
  final Timestamp lastSeen;
  final Timestamp createdAt;
  final String? fcmToken;
  final List<String> blockedUsers;

  // Constructor
  UserModel({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.isOnline = false,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    this.fcmToken,
    List<String>? blockedUsers,
  })  : lastSeen = lastSeen ?? Timestamp.now(),
        createdAt = createdAt ?? Timestamp.now(),
        blockedUsers = blockedUsers ?? [];

  // CopyWith method to create a copy of the user model with updated values
  UserModel copyWith({
    String? uid,
    String? username,
    String? fullName,
    String? email,
    String? phoneNumber,
    bool? isOnline,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    String? fcmToken,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  // Factory method to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      print("UserModel.fromFirestore: doc.data() is null for doc ID ${doc.id}");
      return UserModel(
        uid: doc.id,
        username: "",
        fullName: "",
        email: "",
        phoneNumber: "",
        lastSeen: Timestamp.now(),
        createdAt: Timestamp.now(),
        blockedUsers: [],
      );
    }

    // Ensure 'blockedUsers' is a valid list or default to an empty list
    List<String> blockedUsers = [];
    if (data["blockedUsers"] != null && data["blockedUsers"] is List) {
      blockedUsers = List<String>.from(data["blockedUsers"]);
    }

    return UserModel(
      uid: doc.id,
      username: data["username"] ?? "",
      fullName: data["fullName"] ?? "",
      email: data["email"] ?? "",
      phoneNumber: data["phoneNumber"] ?? "",
      fcmToken: data["fcmToken"],
      lastSeen: data["lastSeen"] is Timestamp ? data["lastSeen"] : Timestamp.now(),
      createdAt: data["createdAt"] is Timestamp ? data["createdAt"] : Timestamp.now(),
      blockedUsers: blockedUsers,
    );
  }

  // Method to convert the UserModel to a map (useful for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
      'blockedUsers': blockedUsers,
      'fcmToken': fcmToken,
    };
  }
}
