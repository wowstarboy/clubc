import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String blockerId;
  final String blockedId;
  final Timestamp createdAt;

  BlockModel({
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory BlockModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BlockModel(
      blockerId: data['blockerId'],
      blockedId: data['blockedId'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': createdAt,
    };
  }
}
