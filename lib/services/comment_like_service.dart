import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jamiiclub/auth/collections.dart';

class CommentLikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> toggleLike(String postId, String commentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return; // User not logged in

    final commentRef = _firestore
        .collection(FirestoreCollections.posts)
        .doc(postId)
        .collection(FirestoreCollections.comments)
        .doc(commentId);

    final likeRef = commentRef
        .collection(FirestoreCollections.commentLikes)
        .doc(currentUser.uid);

    return _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final commentDoc = await transaction.get(commentRef);

      if (!commentDoc.exists) {
        throw Exception("Comment does not exist!");
      }

      int currentLikes = (commentDoc.data() as Map<String, dynamic>)[FirestoreCollections.commentLikeCount] ?? 0;

      if (likeDoc.exists) {
        // User has liked, so unlike
        transaction.delete(likeRef);
        transaction.update(commentRef, {FirestoreCollections.commentLikeCount: currentLikes - 1});
      } else {
        // User has not liked, so like
        transaction.set(likeRef, {
          FirestoreCollections.userId: currentUser.uid,
          FirestoreCollections.createdAt: FieldValue.serverTimestamp(),
        });
        transaction.update(commentRef, {FirestoreCollections.commentLikeCount: currentLikes + 1});
      }
    });
  }

  Future<bool> isCommentLiked(String postId, String commentId) async {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final likeDoc = await _firestore
          .collection(FirestoreCollections.posts)
          .doc(postId)
          .collection(FirestoreCollections.comments)
          .doc(commentId)
          .collection(FirestoreCollections.commentLikes)
          .doc(currentUser.uid)
          .get();

      return likeDoc.exists;
  }
}
