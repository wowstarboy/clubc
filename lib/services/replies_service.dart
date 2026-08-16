import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:uuid/uuid.dart';

class RepliesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a reply to a comment
  Future<void> addReply(String postId, String commentId, String replyText) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null || replyText.trim().isEmpty) {
      return; // Or throw an error
    }

    String replyId = const Uuid().v1();

    final DocumentReference commentRef = _firestore.collection(FirestoreCollections.posts).doc(postId).collection(FirestoreCollections.comments).doc(commentId);
    final DocumentReference replyRef = commentRef.collection(FirestoreCollections.replies).doc(replyId);

    await _firestore.runTransaction((transaction) async {
      // Add the reply
      transaction.set(replyRef, {
        FirestoreCollections.replyId: replyId,
        FirestoreCollections.authorId: userId,
        FirestoreCollections.commentText: replyText, // Using commentText field for consistency
        FirestoreCollections.createdAt: Timestamp.now(),
        FirestoreCollections.commentLikeCount: 0, // Initialize like count for the reply
      });

      // Update the reply count on the parent comment
      transaction.update(commentRef, {
        FirestoreCollections.replyCount: FieldValue.increment(1),
      });
    });
  }

  // Get a stream of replies for a comment
  Stream<QuerySnapshot> getReplies(String postId, String commentId) {
    return _firestore
        .collection(FirestoreCollections.posts)
        .doc(postId)
        .collection(FirestoreCollections.comments)
        .doc(commentId)
        .collection(FirestoreCollections.replies)
        .orderBy(FirestoreCollections.createdAt, descending: true)
        .snapshots();
  }
}
