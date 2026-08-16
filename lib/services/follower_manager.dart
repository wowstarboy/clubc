import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamiiclub/auth/collections.dart';

class FollowerManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection(FirestoreCollections.follows).add({
        FirestoreCollections.followerId: currentUserId,
        FirestoreCollections.followingId: targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error following user: $e");
      rethrow;
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.follows)
          .where(FirestoreCollections.followerId, isEqualTo: currentUserId)
          .where(FirestoreCollections.followingId, isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection(FirestoreCollections.follows).doc(docId).delete();
      }
    } catch (e) {
      print("Error unfollowing user: $e");
      rethrow;
    }
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.follows)
          .where(FirestoreCollections.followerId, isEqualTo: currentUserId)
          .where(FirestoreCollections.followingId, isEqualTo: targetUserId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking following status: $e");
      return false;
    }
  }
}
