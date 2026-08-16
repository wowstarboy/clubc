import 'package:cloud_firestore/cloud_firestore.dart';

class FollowModel {
  final String followerId;
  final String followingId;
  final Timestamp createdAt;

  FollowModel({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory FollowModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FollowModel(
      followerId: data['followerId'],
      followingId: data['followingId'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt,
    };
  }
}
