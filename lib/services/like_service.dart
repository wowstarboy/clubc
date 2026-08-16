 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jamiiclub/auth/collections.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Like a post
  Future<void> likePost(String postId) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final DocumentReference postRef = _firestore.collection(FirestoreCollections.posts).doc(postId);
    final DocumentReference likeRef = _firestore.collection(FirestoreCollections.postLikes).doc('$postId\_$userId');

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) {
        throw Exception("Post does not exist!");
      }

      // Add the like
      transaction.set(likeRef, {
        FirestoreCollections.postId: postId,
        FirestoreCollections.userId: userId,
        FirestoreCollections.createdAt: Timestamp.now(),
      });

      // Update the like count
      transaction.update(postRef, {FirestoreCollections.likeCount: FieldValue.increment(1)});
    });
  }

  // Unlike a post
  Future<void> unlikePost(String postId) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final DocumentReference postRef = _firestore.collection(FirestoreCollections.posts).doc(postId);
    final DocumentReference likeRef = _firestore.collection(FirestoreCollections.postLikes).doc('$postId\_$userId');

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) {
        throw Exception("Post does not exist!");
      }

      // Remove the like
      transaction.delete(likeRef);

      // Update the like count
      transaction.update(postRef, {FirestoreCollections.likeCount: FieldValue.increment(-1)});
    });
  }

  // Check if a user has liked a post
  Stream<bool> hasLikedPost(String postId) {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection(FirestoreCollections.postLikes)
        .doc('$postId\_$userId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
