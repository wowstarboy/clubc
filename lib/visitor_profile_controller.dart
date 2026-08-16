 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:jamiiclub/services/follower_manager.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/services/profile_stream_model.dart';
import 'package:jamiiclub/auth/collections.dart';

class VisitorProfileController {
  final String visitorUserId;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final MediaManager mediaManager = MediaManager();
  final FollowerManager followerManager = FollowerManager();

  Stream<ProfileData>? combinedStream;
  bool isFollowing = false;
  bool isFollowedBy = false;

  VisitorProfileController({required this.visitorUserId});

  void initStreams(CacheProvider cacheProvider) {
    final userStream = cacheProvider.getStream<DocumentSnapshot>(
        key: 'user_data_$visitorUserId',
        streamBuilder: () => FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(visitorUserId).snapshots());

    final followersStream = cacheProvider.getStream<QuerySnapshot>(
        key: 'followers_count_$visitorUserId',
        streamBuilder: () => FirebaseFirestore.instance
            .collection(FirestoreCollections.follows)
            .where(FirestoreCollections.followingId, isEqualTo: visitorUserId)
            .snapshots());

    final followingStream = cacheProvider.getStream<QuerySnapshot>(
        key: 'following_count_$visitorUserId',
        streamBuilder: () => FirebaseFirestore.instance
            .collection(FirestoreCollections.follows)
            .where(FirestoreCollections.followerId, isEqualTo: visitorUserId)
            .snapshots());

    combinedStream ??= ProfileStreamService.getCombinedProfileStream(
      userStream,
      followersStream,
      followingStream,
    );
  }

  Future<void> checkFollowStatus(Function onUpdate) async {
    isFollowing = await followerManager.isFollowing(currentUserId, visitorUserId);
    isFollowedBy = await followerManager.isFollowing(visitorUserId, currentUserId);
    onUpdate();
  }

  Future<void> toggleFollow(Function onUpdate) async {
    if (isFollowing) {
      await followerManager.unfollowUser(currentUserId, visitorUserId);
    } else {
      await followerManager.followUser(currentUserId, visitorUserId);
    }
    isFollowing = !isFollowing;
    onUpdate();
  }
}
