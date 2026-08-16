 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:uuid/uuid.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a comment to a post
  Future<void> addComment(String postId, String commentText) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null || commentText.trim().isEmpty) {
      return; // Or throw an error
    }

    String commentId = const Uuid().v1();

    final DocumentReference postRef = _firestore.collection(FirestoreCollections.posts).doc(postId);
    final DocumentReference commentRef = postRef.collection(FirestoreCollections.comments).doc(commentId);

    await _firestore.runTransaction((transaction) async {
      // Add the comment
      transaction.set(commentRef, {
        FirestoreCollections.commentId: commentId,
        FirestoreCollections.authorId: userId,
        FirestoreCollections.commentText: commentText,
        FirestoreCollections.createdAt: Timestamp.now(),
      });

      // Update the comments count on the post
      transaction.update(postRef, {
        FirestoreCollections.commentsCount: FieldValue.increment(1),
      });
    });
  }

  // Get a stream of comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection(FirestoreCollections.posts)
        .doc(postId)
        .collection(FirestoreCollections.comments)
        .orderBy(FirestoreCollections.createdAt, descending: true)
        .snapshots();
  }
}
