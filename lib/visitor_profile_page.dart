 import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jamiiclub/models/user_model.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/services/post_provider.dart';
import 'package:jamiiclub/widget/more_options_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/chat_page.dart';
import 'followers_page.dart';
import 'auth/collections.dart';
import 'services/profile_stream_model.dart';
import 'visitor_profile_controller.dart';

class VisitorProfilePage extends StatefulWidget {
  final String userId;
  const VisitorProfilePage({super.key, required this.userId});

  @override
  State<VisitorProfilePage> createState() => _VisitorProfilePageState();
}

class _VisitorProfilePageState extends State<VisitorProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VisitorProfileController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = VisitorProfileController(visitorUserId: widget.userId);
    _controller.checkFollowStatus(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.initStreams(Provider.of<CacheProvider>(context, listen: false));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    final ButtonStyle greyButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      foregroundColor: theme.textTheme.bodyLarge?.color,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return StreamBuilder<ProfileData>(
      stream: _controller.combinedStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue)));
        }
        if (!snapshot.hasData) return const Scaffold(body: Center(child: Text("User not found")));

        final data = snapshot.data!;
        final userData = data.userDoc.data() as Map<String, dynamic>? ?? {};
        final photoPath = userData[FirestoreCollections.profilePhotoUrl];
        
        ImageProvider? backgroundImage;
        if (photoPath != null && photoPath.isNotEmpty) {
          backgroundImage = NetworkImage(_controller.mediaManager.getUrl(photoPath));
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userData[FirestoreCollections.displayName] ?? 'User Name', 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                if (userData[FirestoreCollections.isVerified] ?? false) 
                  const Padding(padding: EdgeInsets.only(left: 4.0), child: Icon(Icons.verified, color: Colors.blue, size: 18)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 28),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const MoreOptionsBottomSheet(),
                ),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(count: data.followersSnapshot.docs.length.toString(), label: 'Followers', initialTabIndex: 0, profileOwnerUserId: widget.userId),
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey,
                          backgroundImage: backgroundImage,
                          child: backgroundImage == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
                        ),
                        _StatColumn(count: data.followingSnapshot.docs.length.toString(), label: 'Following', initialTabIndex: 1, profileOwnerUserId: widget.userId),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(userData[FirestoreCollections.username] ?? '@username', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: _controller.isFollowing
                                  ? greyButtonStyle
                                  : greyButtonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.blue), foregroundColor: WidgetStateProperty.all(Colors.white)),
                              onPressed: () => _controller.toggleFollow(() => setState(() {})),
                              child: Text(_controller.isFollowing ? 'Unfollow' : (_controller.isFollowedBy ? 'Follow Back' : 'Follow')),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(style: greyButtonStyle, onPressed: () {
                              final user = UserModel(
                                uid: widget.userId,
                                username: userData[FirestoreCollections.username] ?? '',
                                displayName: userData[FirestoreCollections.displayName] ?? '',
                                email: userData[FirestoreCollections.email] ?? '',
                                bio: userData[FirestoreCollections.bio],
                                profilePhotoUrl: userData[FirestoreCollections.profilePhotoUrl],
                                website: userData[FirestoreCollections.website],
                                isVerified: userData[FirestoreCollections.isVerified] ?? false,
                                createdAt: userData[FirestoreCollections.createdAt] ?? Timestamp.now(),
                              );
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(user: user)));
                            }, child: const Text('Message')),
                            const SizedBox(width: 8),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  foregroundColor: theme.textTheme.bodyLarge?.color,
                                  elevation: 0,
                                  padding: const EdgeInsets.all(14), // Makes it square-ish
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {},
                                child: const Icon(Icons.person_add_outlined),
                            ),
                          ],
                        ),
                        if (userData[FirestoreCollections.bio] != null) ...[const SizedBox(height: 8), Text(userData[FirestoreCollections.bio], textAlign: TextAlign.center)],
                        if (userData[FirestoreCollections.website] != null) ...[const SizedBox(height: 8), Text(userData[FirestoreCollections.website], textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue))],
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: isDarkMode ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2.0, color: isDarkMode ? Colors.white : Colors.black),
                  insets: const EdgeInsets.symmetric(horizontal: 80.0),
                ),
                dividerColor: Colors.transparent,
                tabs: const [Tab(icon: Icon(Icons.grid_on, size: 28)), Tab(icon: Icon(Icons.slow_motion_video, size: 28))],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProfilePostsGrid(
                      postStream: postProvider.getUserPostsStream(
                          widget.userId, 'image'),
                    ),
                    _ProfilePostsGrid(
                      postStream: postProvider.getUserPostsStream(
                          widget.userId, 'video'),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String count;
  final String label;
  final int initialTabIndex;
  final String profileOwnerUserId;

  const _StatColumn({required this.count, required this.label, required this.initialTabIndex, required this.profileOwnerUserId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => FollowersPage(initialTabIndex: initialTabIndex, profileOwnerUserId: profileOwnerUserId))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ]),
    );
  }
}

class _ProfilePostsGrid extends StatelessWidget {
  final Stream<QuerySnapshot> postStream;

  const _ProfilePostsGrid({required this.postStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: postStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts yet.'));
        }

        final posts = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostTile(post: post);
          },
        );
      },
    );
  }
}

class _PostTile extends StatefulWidget {
  final DocumentSnapshot post;

  const _PostTile({required this.post});

  @override
  State<_PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<_PostTile> {
  VideoPlayerController? _videoController;
  late MediaManager _mediaManager;

  @override
  void initState() {
    super.initState();
    _mediaManager = MediaManager();
    final postData = widget.post.data() as Map<String, dynamic>;
    final mediaType = postData['mediaType'];

    if (mediaType == 'video') {
      final videoUrl = _mediaManager.getUrl(postData['mediaUrls'][0]);
      _videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
               _videoController?.setLooping(true);
            });
          }
        });
    }
  }

 @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.post.data() as Map<String, dynamic>;
    final mediaType = postData['mediaType'];
    final thumbnailUrl = _mediaManager.getUrl(postData['mediaUrls'][0]);

    return GestureDetector(
       onTap: () {
        if (mediaType == 'video') {
          _togglePlayPause();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
        ),
        child: mediaType == 'video'
            ? (_videoController != null && _videoController!.value.isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      if (!_videoController!.value.isPlaying)
                         Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                        ),
                         const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.slow_motion_video, color: Colors.white, size: 16),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Stack(
              fit: StackFit.expand,
              children:[
                Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                   errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
                 if (postData['mediaUrls'].length > 1)
                 const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.collections, color: Colors.white, size: 16),
                      ),
              ]
            ),
      ),
    );
  }
}
