 import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/providers/story_provider.dart';
import 'package:jamiiclub/providers/cache_provider.dart';

class StoryViewPage extends StatefulWidget {
  final DocumentSnapshot userDoc;

  const StoryViewPage({super.key, required this.userDoc});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> {
  final PageController _pageController = PageController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).startStory(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // LOGIC YA MARK AS SEEN
  Future<void> _markStoryAsSeen(String storyId) async {
    if (currentUserId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.stories)
        .doc(storyId)
        .update({
      'viewers': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // LOGIC YA VIEWER LIST SHEET
  void _showViewerList(BuildContext context, List<dynamic> viewerIds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Story Views", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: viewerIds.isEmpty
                  ? const Center(child: Text("No views yet", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: viewerIds.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(viewerIds[index]).snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox.shrink();
                            var uData = snap.data!.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                backgroundImage: NetworkImage(MediaManager().getUrl(uData[FirestoreCollections.profilePhotoUrl] ?? '')),
                              ),
                              title: Text(uData[FirestoreCollections.username] ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupVideo(String url, StoryProvider provider) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();
    _videoController!.play();
    provider.updateVideoController(_videoController);
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userDoc.data() as Map<String, dynamic>;
    final bool isOwner = currentUserId == widget.userDoc.id;
    final cacheProvider = Provider.of<CacheProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: cacheProvider.getStream<QuerySnapshot>(
          key: 'stories_${widget.userDoc.id}',
          streamBuilder: () => FirebaseFirestore.instance
              .collection(FirestoreCollections.stories)
              .where(FirestoreCollections.authorId, isEqualTo: widget.userDoc.id)
              .orderBy(FirestoreCollections.createdAt, descending: false)
              .snapshots(),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blue));
          final stories = snapshot.data!.docs;
          if (stories.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
            return const SizedBox.shrink();
          }

          return Consumer<StoryProvider>(
            builder: (context, provider, child) {
              if (provider.currentIndex >= stories.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
                return const SizedBox.shrink();
              }

              final storyDoc = stories[provider.currentIndex];
              final storyData = storyDoc.data() as Map<String, dynamic>;
              final List mediaUrls = storyData[FirestoreCollections.mediaUrls] ?? [];
              final List viewers = storyData['viewers'] ?? [];
              final String type = storyData[FirestoreCollections.mediaType] ?? 'image';
              final String url = MediaManager().getUrl(mediaUrls.first);

              // Mark as seen automatic
              if (!isOwner && !viewers.contains(currentUserId)) {
                _markStoryAsSeen(storyDoc.id);
              }

              return GestureDetector(
                onTapDown: (details) => _handleTap(details, stories.length, provider),
                onLongPress: () => provider.pause(),
                onLongPressUp: () => provider.resume(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMediaContent(url, type, provider),
                    _buildProgressBars(stories.length, provider.percent, provider.currentIndex),
                    _buildHeader(userData),
                    isOwner ? _buildOwnerBottom(viewers) : _buildVisitorBottom(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMediaContent(String url, String type, StoryProvider provider) {
    if (type == 'video') {
      return FutureBuilder(
        future: _setupVideo(url, provider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _videoController != null) {
            return Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)));
          }
          return const Center(child: CircularProgressIndicator(color: Colors.blue));
        },
      );
    }
    return Image.network(url, fit: BoxFit.cover, loadingBuilder: (context, child, lp) => lp == null ? child : const Center(child: CircularProgressIndicator(color: Colors.blue)));
  }

  void _handleTap(TapDownDetails details, int total, StoryProvider provider) {
    final double width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width / 3) {
      if (provider.currentIndex > 0) {
        provider.previousStory();
      }
    } else {
      if (provider.currentIndex < total - 1) {
        provider.nextStory();
      } else {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildProgressBars(int count, double percent, int currentIndex) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10, right: 10,
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              child: index < currentIndex
                  ? Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)))
                  : index == currentIndex
                      ? FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: percent, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))))
                      : const SizedBox.shrink(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> userData) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 25,
      left: 15, right: 15,
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(MediaManager().getUrl(userData[FirestoreCollections.profilePhotoUrl] ?? ''))),
          const SizedBox(width: 10),
          Text(userData[FirestoreCollections.username] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildVisitorBottom() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 10,
      left: 15, right: 15,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(border: Border.all(color: Colors.white38), borderRadius: BorderRadius.circular(25)),
              child: const TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Send message...', hintStyle: TextStyle(color: Colors.white60), border: InputBorder.none)),
            ),
          ),
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildOwnerBottom(List<dynamic> viewerIds) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 0, right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -100) _showViewerList(context, viewerIds);
        },
        onTap: () => _showViewerList(context, viewerIds),
        child: Column(
          children: [
            const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            Text('${viewerIds.length} Viewers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
