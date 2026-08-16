 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; // Hakikisha umeongeza rxdart kwenye pubspec.yaml

class ProfileData {
  final DocumentSnapshot userDoc;
  final QuerySnapshot followersSnapshot;
  final QuerySnapshot followingSnapshot;

  ProfileData({
    required this.userDoc,
    required this.followersSnapshot,
    required this.followingSnapshot,
  });
}

class ProfileStreamService {
  static Stream<ProfileData> getCombinedProfileStream(
    Stream<DocumentSnapshot> userStream,
    Stream<QuerySnapshot> followersStream,
    Stream<QuerySnapshot> followingStream,
  ) {
    // Tunatumia CombineLatest3 kutoka rxdart kuunganisha stream zote tatu kuwa moja
    return CombineLatestStream.combine3(
      userStream,
      followersStream,
      followingStream,
      (DocumentSnapshot user, QuerySnapshot followers, QuerySnapshot following) {
        return ProfileData(
          userDoc: user,
          followersSnapshot: followers,
          followingSnapshot: following,
        );
      },
    );
  }
}
