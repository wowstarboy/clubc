import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/loading_page.dart';

// 1. A builder function type that will build the UI once data is ready.
typedef UserDataBuilder = Widget Function(BuildContext context, DocumentSnapshot userSnapshot);

class UserDataProvider extends StatelessWidget {
  final String userId;
  final UserDataBuilder builder;

  const UserDataProvider({
    super.key,
    required this.userId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // 2. The StreamBuilder that fetches user data.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(userId).snapshots(),
      builder: (context, snapshot) {
        // 3. Show a loading page while waiting for data.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        // 4. Show an error message if the user is not found.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User not found.')),
          );
        }

        // 5. If data is available, call the builder function with the data.
        return builder(context, snapshot.data!);
      },
    );
  }
}
