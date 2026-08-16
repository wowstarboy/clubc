import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/story_picker.dart';
import 'dart:math' as math;

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        children: [
          // 1. DUA LA "CREATE STORY" (HALIBADILIKI)
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: _CreateStoryWidget(),
          ),

          // 2. ORODHA YA HADITHI ZOTE ZILIZOPO
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirestoreCollections.users)
                .where('hasActiveStory', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final usersWithStories = snapshot.data!.docs;

              // Panga orodha ili mtumiaji wa sasa awe wa kwanza
              usersWithStories.sort((a, b) {
                if (a.id == currentUser?.uid) return -1;
                if (b.id == currentUser?.uid) return 1;
                // Hapa unaweza kupanga kwa timestamp kama unapenda
                return 0;
              });

              return Row(
                children: usersWithStories.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _StoryItem(userDoc: doc),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// WIDGET YA "CREATE STORY" PEKEE
class _CreateStoryWidget extends StatelessWidget {
  const _CreateStoryWidget();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        ImageProvider? backgroundImage;
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final photoPath = userData[FirestoreCollections.profilePhotoUrl];
          if (photoPath != null && photoPath.isNotEmpty) {
            backgroundImage = NetworkImage(MediaManager().getUrl(photoPath));
          }
        }

        return SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoryPicker())),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: backgroundImage,
                      child: backgroundImage == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), spreadRadius: 2, blurRadius: 5)
                          ]),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Create Story', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

// WIDGET YA KUONYESHA HADITHI ILIYOPO
class _StoryItem extends StatefulWidget {
  final DocumentSnapshot userDoc;

  const _StoryItem({required this.userDoc});

  @override
  State<_StoryItem> createState() => _StoryItemState();
}

class _StoryItemState extends State<_StoryItem> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userDoc.data() as Map<String, dynamic>;
    final mediaManager = MediaManager();
    final photoPath = userData[FirestoreCollections.profilePhotoUrl];
    ImageProvider? backgroundImage = (photoPath != null && photoPath.isNotEmpty) ? NetworkImage(mediaManager.getUrl(photoPath)) : null;

    final username = userData[FirestoreCollections.username] ?? '';
    final isVerified = userData[FirestoreCollections.isVerified] ?? false;
    final isUploading = userData['isUploadingStory'] ?? false;

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // Logic ya kufungua story itakuja hapa
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(130, 130),
                      painter: StoryBorderPainter(isUploading: isUploading, rotation: _rotationController.value),
                    );
                  },
                ),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: backgroundImage,
                  child: backgroundImage == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(username, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ),
              if (isVerified)
                const Padding(padding: EdgeInsets.only(left: 4.0), child: Icon(Icons.verified, color: Colors.blue, size: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

// CUSTOM PAINTER (HAIJABADILISHWA)
class StoryBorderPainter extends CustomPainter {
  final bool isUploading;
  final double rotation;

  StoryBorderPainter({required this.isUploading, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double strokeWidth = 3.5;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final gradient = SweepGradient(
      colors: [Colors.blue.shade900, Colors.blue.shade400, Colors.cyanAccent, Colors.blue.shade900],
      stops: const [0.0, 0.4, 0.7, 1.0],
      transform: GradientRotation(rotation * 2 * math.pi),
    );

    paint.shader = gradient.createShader(rect);

    if (isUploading) {
      double startAngle = -math.pi / 2;
      double sweepAngle = 2 * math.pi * 0.7;
      canvas.drawArc(rect, startAngle + (rotation * 2 * math.pi), sweepAngle, false, paint);
    } else {
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StoryBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.isUploading != isUploading;
  }
}
