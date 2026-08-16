 import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/services/post_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_page.dart';
import 'edit_profile_page.dart';
import 'followers_page.dart';
import 'translation/global.dart';
import 'auth/collections.dart';
import 'services/profile_stream_model.dart';
import 'profile_controller.dart';
import 'menu_page.dart'; // Import added here

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = ProfileController(context);

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.addListener(_handleLanguageChange);
    _controller.translateTexts(languageProvider.selectedLanguage, () => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.initStreams(Provider.of<CacheProvider>(context, listen: false));
  }

  void _handleLanguageChange() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    _controller.translateTexts(languageProvider.selectedLanguage, () => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    Provider.of<LanguageProvider>(context, listen: false).removeListener(_handleLanguageChange);
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
        if (!snapshot.hasData) return const Scaffold(body: Center(child: Text("Error loading profile")));

        final data = snapshot.data!;
        final userData = data.userDoc.data() as Map<String, dynamic>? ?? {};
        final photoPath = userData[FirestoreCollections.profilePhotoUrl];
        final bio = userData[FirestoreCollections.bio];
        
        ImageProvider? backgroundImage;
        if (photoPath != null && photoPath.isNotEmpty) {
          backgroundImage = NetworkImage(_controller.mediaManager.getUrl(photoPath));
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            automaticallyImplyLeading: false,
            leading: IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePage())),
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
                icon: const Icon(Icons.tune, size: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPage())),
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
                        _StatColumn(count: data.followersSnapshot.docs.length.toString(), label: _controller.followersText, initialTabIndex: 0, profileOwnerUserId: _controller.currentUserId),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey,
                              backgroundImage: backgroundImage,
                              child: _controller.isUploading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : (backgroundImage == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null),
                            ),
                            GestureDetector(
                              onTap: () => _controller.updatePhoto(() => setState(() {})),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                                child: const Icon(Icons.photo_camera, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                        _StatColumn(count: data.followingSnapshot.docs.length.toString(), label: _controller.followingText, initialTabIndex: 1, profileOwnerUserId: _controller.currentUserId),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(userData[FirestoreCollections.username] ?? '@username', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(style: greyButtonStyle, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfilePage())), child: const Text('Edit Profile')),
                            const SizedBox(width: 8),
                            ElevatedButton(style: greyButtonStyle, onPressed: () {}, child: const Text('Share')),
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
                        const SizedBox(height: 8),
                        if (bio != null && bio.isNotEmpty)
                          Text(bio, textAlign: TextAlign.center)
                        else
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfilePage())),
                            child: Text(
                              'Tap to add bio',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        if (userData[FirestoreCollections.website] != null) ...[
                          const SizedBox(height: 8),
                          Text(userData[FirestoreCollections.website], textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: isDarkMode ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 2.0, color: isDarkMode ? Colors.white : Colors.black), insets: const EdgeInsets.symmetric(horizontal: 80.0)),
                dividerColor: Colors.transparent,
                tabs: const [Tab(icon: Icon(Icons.grid_on, size: 28)), Tab(icon: Icon(Icons.slow_motion_video, size: 28))],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProfilePostsGrid(
                      postStream: postProvider.getUserPostsStream(
                          _controller.currentUserId, 'image'),
                    ),
                    _ProfilePostsGrid(
                      postStream: postProvider.getUserPostsStream(
                          _controller.currentUserId, 'video'),
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
