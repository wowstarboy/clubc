
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorId;
  final String mediaUrl;
  final String mediaType; // e.g., 'image', 'video'
  final String caption;
  final int likeCount;
  final int commentsCount;
  final Timestamp createdAt;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.likeCount,
    required this.commentsCount,
    required this.createdAt,
  });

  // Convert a PostModel object into a Map
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'authorId': authorId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'caption': caption,
        'likeCount': likeCount,
        'commentsCount': commentsCount,
        'createdAt': createdAt,
      };

  // Create a PostModel from a DocumentSnapshot
  static PostModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return PostModel(
      postId: snapshot['postId'],
      authorId: snapshot['authorId'],
      mediaUrl: snapshot['mediaUrl'],
      mediaType: snapshot['mediaType'],
      caption: snapshot['caption'],
      likeCount: snapshot['likeCount'] ?? 0,
      commentsCount: snapshot['commentsCount'] ?? 0,
      createdAt: snapshot['createdAt'],
    );
  }
}
