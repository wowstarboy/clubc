
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String storyId;
  final String authorId;
  final String mediaUrl;
  final String mediaType; // e.g., 'image', 'video'
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final List<String> viewers;

  StoryModel({
    required this.storyId,
    required this.authorId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    required this.viewers,
  });

  // Convert a StoryModel object into a Map
  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'authorId': authorId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'viewers': viewers,
      };

  // Create a StoryModel from a DocumentSnapshot
  static StoryModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return StoryModel(
      storyId: snapshot['storyId'],
      authorId: snapshot['authorId'],
      mediaUrl: snapshot['mediaUrl'],
      mediaType: snapshot['mediaType'],
      createdAt: snapshot['createdAt'],
      expiresAt: snapshot['expiresAt'],
      viewers: List<String>.from(snapshot['viewers'] ?? []),
    );
  }
}
