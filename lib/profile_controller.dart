 import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:provider/provider.dart';

import 'auth/collections.dart';
import 'services/media_manager.dart';
import 'services/profile_stream_model.dart';
import 'translation/global.dart';

class ProfileController {
  final BuildContext context;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final MediaManager mediaManager = MediaManager();
  final TranslationService translationService = TranslationService();

  Stream<ProfileData>? combinedStream;
  String followersText = 'Followers';
  String followingText = 'Following';
  bool isUploading = false;

  ProfileController(this.context);

  // Initializing Streams with Cache
  void initStreams(CacheProvider cacheProvider) {
    final userStream = cacheProvider.getStream<DocumentSnapshot>(
        key: 'user_data_$currentUserId',
        streamBuilder: () => FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(currentUserId).snapshots());

    final followersStream = cacheProvider.getStream<QuerySnapshot>(
        key: 'followers_count_$currentUserId',
        streamBuilder: () => FirebaseFirestore.instance
            .collection(FirestoreCollections.follows)
            .where(FirestoreCollections.followingId, isEqualTo: currentUserId)
            .snapshots());

    final followingStream = cacheProvider.getStream<QuerySnapshot>(
        key: 'following_count_$currentUserId',
        streamBuilder: () => FirebaseFirestore.instance
            .collection(FirestoreCollections.follows)
            .where(FirestoreCollections.followerId, isEqualTo: currentUserId)
            .snapshots());

    combinedStream ??= ProfileStreamService.getCombinedProfileStream(
      userStream,
      followersStream,
      followingStream,
    );
  }

  // Logic ya Tafsiri
  Future<void> translateTexts(TranslateLanguage targetLanguage, Function onUpdate) async {
    final translations = await Future.wait([
      translationService.translate(text: 'Followers', from: TranslateLanguage.english, to: targetLanguage),
      translationService.translate(text: 'Following', from: TranslateLanguage.english, to: targetLanguage),
    ]);

    followersText = translations[0];
    followingText = translations[1];
    onUpdate();
  }

  // Logic ya Kupandisha Picha
  Future<void> updatePhoto(Function onStateChange) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      isUploading = true;
      onStateChange();

      String? fileName = await mediaManager.uploadMedia(File(image.path), isVideo: false);

      if (fileName != null) {
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(currentUserId)
            .update({FirestoreCollections.profilePhotoUrl: fileName});
      }
      isUploading = false;
      onStateChange();
    }
  }
}
