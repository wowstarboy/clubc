 import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/services/post_provider.dart';
import 'package:jamiiclub/visitor_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class RecentSearchItem {
  final String userId;
  final String displayName;
  final String username;
  final String? profilePhotoUrl;

  RecentSearchItem({
    required this.userId,
    required this.displayName,
    required this.username,
    this.profilePhotoUrl,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'username': username,
        'profilePhotoUrl': profilePhotoUrl,
      };

  factory RecentSearchItem.fromJson(Map<String, dynamic> json) => RecentSearchItem(
        userId: json['userId'],
        displayName: json['displayName'],
        username: json['username'],
        profilePhotoUrl: json['profilePhotoUrl'],
      );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<RecentSearchItem> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches_list';

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> searchesJson = prefs.getStringList(_recentSearchesKey) ?? [];
    if (mounted) {
      setState(() {
        _recentSearches = searchesJson
            .map((json) => RecentSearchItem.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  Future<void> _addRecentSearch(RecentSearchItem item) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.removeWhere((search) => search.userId == item.userId);
    _recentSearches.insert(0, item);
    if (_recentSearches.length > 20) {
      _recentSearches = _recentSearches.sublist(0, 20);
    }
    final List<String> searchesJson = _recentSearches.map((search) => jsonEncode(search.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, searchesJson);
    setState(() {});
  }

  Future<void> _removeRecentSearch(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.removeWhere((search) => search.userId == userId);
    final List<String> searchesJson = _recentSearches.map((search) => jsonEncode(search.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, searchesJson);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isSearching ? _buildSearchView() : _buildExploreView();
  }

  Widget _buildExploreView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final searchBackgroundColor = isDarkMode 
    ? const Color(0xFF0D1015).withBlue(25).withRed(20).withGreen(20) // Inapauka kidogo kitalamu
    : Colors.grey[100];
   final postProvider = Provider.of<PostProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = true;
                });
              },
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for inspiration...',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
                    filled: true,
                    fillColor: searchBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: postProvider.getCachedPostStream(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts found.'));
                }

                final posts = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _PostTile(post: post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    // HAPA: Nimebadilisha rangi i-match body (scaffoldBackgroundColor)
    appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black),
        onPressed: () {
          setState(() {
            _isSearching = false;
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search users or #tags',
          border: InputBorder.none,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
            },
          ),
      ],
    ),

      body: _searchQuery.isEmpty
          ? (_recentSearches.isEmpty
              ? const Center(child: Text('Search for users to see recent history.'))
              : ListView.builder(
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    final item = _recentSearches[index];
                    final mediaManager = MediaManager();
                    ImageProvider? backgroundImage;
                    if (item.profilePhotoUrl != null && item.profilePhotoUrl!.isNotEmpty) {
                      backgroundImage = NetworkImage(mediaManager.getUrl(item.profilePhotoUrl!));
                    }

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitorProfilePage(userId: item.userId),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey,
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null ? const Icon(Icons.person_outline, size: 30, color: Colors.white) : null,
                      ),
                      title: Text(item.displayName),
                      subtitle: Text('@${item.username}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _removeRecentSearch(item.userId),
                      ),
                    );
                  },
                ))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirestoreCollections.users)
                  .where(FirestoreCollections.username, isGreaterThanOrEqualTo: _searchQuery)
                  .where(FirestoreCollections.username, isLessThan: '$_searchQuery\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final mediaManager = MediaManager();

                    ImageProvider? backgroundImage;
                    final photoPath = userData[FirestoreCollections.profilePhotoUrl];
                    if (photoPath != null && photoPath.isNotEmpty) {
                      backgroundImage = NetworkImage(mediaManager.getUrl(photoPath));
                    }

                    return ListTile(
                      onTap: () {
                        final recentItem = RecentSearchItem(
                          userId: userDoc.id,
                          displayName: userData[FirestoreCollections.displayName] ?? '',
                          username: userData[FirestoreCollections.username] ?? '',
                          profilePhotoUrl: userData[FirestoreCollections.profilePhotoUrl],
                        );
                        _addRecentSearch(recentItem);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisitorProfilePage(userId: userDoc.id),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey,
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
                      ),
                      title: Text(userData[FirestoreCollections.displayName] ?? ''),
                      subtitle: Text('@${userData[FirestoreCollections.username] ?? ''}'),
                    );
                  },
                );
              },
            ),
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
  late CacheProvider _cacheProvider;

  @override
  void initState() {
    super.initState();
    _mediaManager = MediaManager();
    _cacheProvider = Provider.of<CacheProvider>(context, listen: false);
    final postData = widget.post.data() as Map<String, dynamic>;
    final mediaType = postData['mediaType'];
    if (mediaType == 'video') {
      final videoUrl = _mediaManager.getUrl(postData['mediaUrls'][0]);
      _videoController = _cacheProvider.getVideoController(videoUrl);
      if (!_videoController!.value.isInitialized) {
        _videoController!.initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.setLooping(true);
            _videoController?.play();
          }
        });
      } else {
        if (mounted) {
          setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        }
      }
    }
  }

  @override
  void dispose() {
    _videoController?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.post.data() as Map<String, dynamic>;
    final mediaType = postData['mediaType'];
    final thumbnailUrl = _mediaManager.getUrl(postData['mediaUrls'][0]);
    
    // HAPA: Rangi ya placeholder inayofuata muundo wako wa rangi iliyopauka
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDarkMode 
        ? const Color(0xFF0D1015).withBlue(25).withRed(20).withGreen(20)
        : Colors.grey[100];

    return Container(
      decoration: BoxDecoration(
        color: placeholderColor, // Imetumia rangi ya placeholder hapa
      ),
      child: mediaType == 'video'
          ? (_videoController != null && _videoController!.value.isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                )
              : Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.white24 : Colors.black12)))
          : Stack(
            fit: StackFit.expand,
            children:[
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  // Wakati picha inapakia, inatumia placeholderColor yetu
                  return progress == null ? child : Container(color: placeholderColor);
                },
              ),
               if (postData['mediaUrls'].length > 1)
               const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.collections, color: Colors.white, size: 16),
                      ),
                    ),
            ]
          ),
    );
  }
}
