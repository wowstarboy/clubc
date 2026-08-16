
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String? bio;
  final String? profilePhotoUrl;
  final String? website;
  final bool isVerified;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.bio,
    this.profilePhotoUrl,
    this.website,
    required this.isVerified,
    required this.createdAt,
  });

  // Convert a UserModel object into a Map that can be stored in Firestore
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'profilePhotoUrl': profilePhotoUrl,
        'website': website,
        'isVerified': isVerified,
        'createdAt': createdAt,
      };

  // Create a UserModel object from a Firestore DocumentSnapshot
  static UserModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return UserModel(
      uid: snapshot['uid'],
      username: snapshot['username'],
      displayName: snapshot['displayName'],
      email: snapshot['email'],
      bio: snapshot['bio'],
      profilePhotoUrl: snapshot['profilePhotoUrl'],
      website: snapshot['website'],
      isVerified: snapshot['isVerified'] ?? false,
      createdAt: snapshot['createdAt'],
    );
  }
}
