import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:jamiiclub/services/follower_manager.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:jamiiclub/visitor_profile_page.dart';
import 'package:provider/provider.dart';

class FollowersPage extends StatefulWidget {
  final String profileOwnerUserId;
  final int initialTabIndex;

  const FollowersPage({
    super.key,
    required this.profileOwnerUserId,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TranslationService _translationService = TranslationService();

  String _headerTitle = 'Followers';
  String _followersTabText = 'Followers';
  String _followingTabText = 'Following';
  String _searchText = 'Search';
  String _noUsersText = 'No users to display.';
  String _followButtonText = 'Follow';
  String _followingButtonText = 'Following';
  String _followBackButtonText = 'Follow Back';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _updateHeaderTitle(_tabController.index);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _updateHeaderTitle(_tabController.index);
    });
    Provider.of<LanguageProvider>(context, listen: false).addListener(_languageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translateAllTexts(Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    Provider.of<LanguageProvider>(context, listen: false).removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    _translateAllTexts(Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      'Followers',
      'Following',
      'Search',
      'No users to display.',
      'Follow',
      'Following',
      'Follow Back',
    ];

    final translated = <String>[];
    for (final text in originalTexts) {
      final translatedText = await _translationService.translate(
        text: text, from: TranslateLanguage.english, to: targetLanguage);
      translated.add(translatedText);
    }

    if (mounted) {
      setState(() {
        _followersTabText = translated[0];
        _followingTabText = translated[1];
        _searchText = translated[2];
        _noUsersText = translated[3];
        _followButtonText = translated[4];
        _followingButtonText = translated[5];
        _followBackButtonText = translated[6];
        _updateHeaderTitle(_tabController.index);
      });
    }
  }

  void _updateHeaderTitle(int index) {
    setState(() {
      _headerTitle = index == 0 ? _followersTabText : _followingTabText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_headerTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: Colors.grey,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white : Colors.black,
                width: 1.5,
              ),
            ),
          ),
          tabs: [
            Tab(text: _followersTabText),
            Tab(text: _followingTabText),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '$_searchText in $_headerTitle',
                hintStyle: const TextStyle(fontSize: 14.5),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UserListTab(
                  type: 'followers',
                  profileOwnerUserId: widget.profileOwnerUserId,
                  currentUserId: _currentUserId,
                  noUsersText: _noUsersText,
                  followButtonText: _followButtonText,
                  followingButtonText: _followingButtonText,
                  followBackButtonText: _followBackButtonText,
                ),
                _UserListTab(
                  type: 'following',
                  profileOwnerUserId: widget.profileOwnerUserId,
                  currentUserId: _currentUserId,
                  noUsersText: _noUsersText,
                  followButtonText: _followButtonText,
                  followingButtonText: _followingButtonText,
                  followBackButtonText: _followBackButtonText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListTab extends StatefulWidget {
  final String type;
  final String profileOwnerUserId;
  final String currentUserId;
  final String noUsersText;
  final String followButtonText;
  final String followingButtonText;
  final String followBackButtonText;

  const _UserListTab({
    required this.type,
    required this.profileOwnerUserId,
    required this.currentUserId,
    required this.noUsersText,
    required this.followButtonText,
    required this.followingButtonText,
    required this.followBackButtonText,
  });

  @override
  State<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<_UserListTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Stream<QuerySnapshot>? _userStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cacheProvider = Provider.of<CacheProvider>(context, listen: false);
    final streamKey = '${widget.type}_${widget.profileOwnerUserId}';

    _userStream ??= cacheProvider.getStream<QuerySnapshot>(
      key: streamKey,
      streamBuilder: () {
        Query query;
        if (widget.type == 'followers') {
          query = FirebaseFirestore.instance
              .collection(FirestoreCollections.follows)
              .where(FirestoreCollections.followingId, isEqualTo: widget.profileOwnerUserId);
        } else {
          query = FirebaseFirestore.instance
              .collection(FirestoreCollections.follows)
              .where(FirestoreCollections.followerId, isEqualTo: widget.profileOwnerUserId);
        }
        return query.snapshots();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Colors.blue,
          ));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(widget.noUsersText));
        }

        final userIds = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return widget.type == 'followers'
              ? data[FirestoreCollections.followerId]
              : data[FirestoreCollections.followingId];
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: userIds.length,
          itemBuilder: (context, index) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(userIds[index]).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final targetUserId = userSnapshot.data!.id;

                return _UserListItem(
                  currentUserId: widget.currentUserId,
                  targetUserId: targetUserId,
                  username: userData[FirestoreCollections.displayName] ?? 'N/A',
                  handle: userData[FirestoreCollections.username] ?? 'N/A',
                  isVerified: userData[FirestoreCollections.isVerified] ?? false,
                  followText: widget.followButtonText,
                  followingText: widget.followingButtonText,
                  followBackButtonText: widget.followBackButtonText,
                  isFollowersList: widget.type == 'followers',
                );
              },
            );
          },
        );
      },
    );
  }
}


class _UserListItem extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String username;
  final String handle;
  final bool isVerified;
  final String followText;
  final String followingText;
  final String followBackButtonText;
  final bool isFollowersList;

  const _UserListItem({
    required this.currentUserId,
    required this.targetUserId,
    required this.username,
    required this.handle,
    required this.isVerified,
    required this.followText,
    required this.followingText,
    required this.followBackButtonText,
    required this.isFollowersList,
  });

  @override
  _UserListItemState createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  final FollowerManager _followerManager = FollowerManager();
  bool _isFollowing = false;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    if (mounted) setState(() => _isProcessing = true);
    final isFollowing = await _followerManager.isFollowing(widget.currentUserId, widget.targetUserId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isProcessing = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      if (_isFollowing) {
        await _followerManager.unfollowUser(widget.currentUserId, widget.targetUserId);
      } else {
        await _followerManager.followUser(widget.currentUserId, widget.targetUserId);
      }
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
      }
    } catch (e) {
      print('Error toggling follow: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCurrentUserItem = widget.currentUserId == widget.targetUserId;
    final Color spinnerColor = _isFollowing
        ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisitorProfilePage(userId: widget.targetUserId),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (widget.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Icon(Icons.verified, color: Colors.blue, size: 15),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(widget.handle, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCurrentUserItem)
            ElevatedButton(
              onPressed: _isProcessing ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? (theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300]) : Colors.blue,
                foregroundColor: _isFollowing ? theme.textTheme.bodyLarge?.color : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: _isFollowing ? BorderSide(color: Colors.grey.shade600, width: 0.5) : BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                elevation: 0,
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                      ),
                    )
                  : Text(
                      _isFollowing ? widget.followingText : (widget.isFollowersList ? widget.followBackButtonText : widget.followText),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }
}
