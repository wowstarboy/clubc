import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jamiiclub/create_page.dart';
import 'package:provider/provider.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/services/media_manager.dart';

import 'services/post_provider.dart';

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const GlobalReelStreamer(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Reels',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      fontFamily: 'LobsterTwo-Bold',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreatePage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalReelStreamer extends StatefulWidget {
  const GlobalReelStreamer({super.key});

  @override
  State<GlobalReelStreamer> createState() => _GlobalReelStreamerState();
}

class _GlobalReelStreamerState extends State<GlobalReelStreamer> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PostProvider>(context, listen: false);
      if (provider.posts.isEmpty) provider.fetchPosts();
    });

    _pageController.addListener(() {
      if (_pageController.position.pixels >= _pageController.position.maxScrollExtent - 500) {
        Provider.of<PostProvider>(context, listen: false).fetchPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PostProvider>(context);
    final videoPosts = provider.posts.where((post) {
      final data = post.data() as Map<String, dynamic>;
      return data['mediaType'] == 'video';
    }).toList();

    if (videoPosts.isEmpty && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videoPosts.isEmpty) {
      return const Center(child: Text("No video posts found.", style: TextStyle(color: Colors.white)));
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: videoPosts.length,
      itemBuilder: (context, index) {
        final postData = videoPosts[index].data() as Map<String, dynamic>;
        return ReelItem(postData: postData);
      },
    );
  }
}

class ReelItem extends StatefulWidget {
  final Map<String, dynamic> postData;
  const ReelItem({super.key, required this.postData});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  final PageController _horizontalController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> mediaUrls = widget.postData['mediaUrls'] ?? [];
    final int totalVideos = mediaUrls.length;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          itemCount: totalVideos,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white24, size: 80),
              ),
            );
          },
        ),
        if (totalVideos > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${_currentPage + 1}/$totalVideos',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        _ReelDetails(postData: widget.postData),
        Align(
          alignment: Alignment.bottomRight,
          child: _ReelActions(postData: widget.postData),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }
}

class _ReelDetails extends StatelessWidget {
  final Map<String, dynamic> postData;
  const _ReelDetails({required this.postData});

  Widget _buildPlaceholder() {
    return Row(
      children: [
        const CircleAvatar(radius: 18, backgroundColor: Colors.white24),
        const SizedBox(width: 10),
        Container(height: 15, width: 80, color: Colors.white24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String authorId = postData[FirestoreCollections.authorId] ?? '';
    if (authorId.isEmpty) return _buildPlaceholder();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(authorId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildPlaceholder(), const SizedBox(height: 120)],
            ),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: NetworkImage(MediaManager().getUrl(userData[FirestoreCollections.profilePhotoUrl] ?? '')),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    userData[FirestoreCollections.username] ?? 'user',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  if (userData['isVerified'] ?? false) const Icon(Icons.verified, color: Colors.blue, size: 14),
                  const SizedBox(width: 8),
                  _PostTimestamp(createdAt: postData[FirestoreCollections.createdAt]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                postData['caption'] ?? "",
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Text('See translation', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }
}

class _ReelActions extends StatelessWidget {
  final Map<String, dynamic> postData;
  const _ReelActions({required this.postData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0, right: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const _ActionButton(icon: Icons.favorite_border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/comment.svg',
                  height: 25,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ],
            ),
          ),
          const _ActionButton(icon: Icons.near_me_outlined),
          const SizedBox(height: 15),
          const Icon(Icons.more_horiz, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;

  const _ActionButton({required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

class _PostTimestamp extends StatelessWidget {
  final Timestamp? createdAt;

  const _PostTimestamp({this.createdAt});

  @override
  Widget build(BuildContext context) {
    String timeAgo = "now";
    if (createdAt != null) {
      final difference = DateTime.now().difference(createdAt!.toDate());
      if (difference.inMinutes < 60) {
        timeAgo = "${difference.inMinutes}m";
      } else if (difference.inHours < 24) {
        timeAgo = "${difference.inHours}h";
      } else {
        timeAgo = "${difference.inDays}d";
      }
    }
    return Text(timeAgo, style: const TextStyle(color: Colors.white70, fontSize: 12));
  }
}
