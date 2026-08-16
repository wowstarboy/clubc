import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/services/follower_manager.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:provider/provider.dart';

class FollowSuggestionsPage extends StatefulWidget {
  final String uid;
  const FollowSuggestionsPage({super.key, required this.uid});

  @override
  State<FollowSuggestionsPage> createState() => _FollowSuggestionsPageState();
}

class _FollowSuggestionsPageState extends State<FollowSuggestionsPage> {
  final TranslationService _translationService = TranslationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FollowerManager _followerManager = FollowerManager();

  bool _isLoading = true;
  int _followedCount = 0;
  final int _requiredFollows = 5;

  String _title = 'Suggestions for you';
  String _instruction = 'Follow at least 5 people to continue';
  String _continueText = 'Continue';
  String _followText = 'Follow';
  String _followingText = 'Following';

  List<Map<String, dynamic>> _suggestedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestedUsers();
    Provider.of<LanguageProvider>(context, listen: false).addListener(_languageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translateAllTexts(Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  @override
  void dispose() {
    Provider.of<LanguageProvider>(context, listen: false).removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    _translateAllTexts(Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  Future<void> _fetchSuggestedUsers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.users)
          .where(FieldPath.documentId, isNotEqualTo: widget.uid)
          .limit(15)
          .get();
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'username': data[FirestoreCollections.displayName] ?? 'No Name',
          'handle': data[FirestoreCollections.username] ?? 'no.handle',
          'isVerified': data[FirestoreCollections.isVerified] ?? false,
        };
      }).toList();
      if (mounted) setState(() => _suggestedUsers = users);
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      'Suggestions for you',
      'Follow at least 5 people to continue',
      'Continue',
      'Follow',
      'Following',
    ];

    final List<String> translatedTexts = [];
    for (String text in originalTexts) {
      final translatedText = await _translationService.translate(
        text: text,
        from: TranslateLanguage.english,
        to: targetLanguage,
      );
      translatedTexts.add(translatedText);
    }

    if (mounted) {
      setState(() {
        _title = translatedTexts[0];
        _instruction = translatedTexts[1];
        _continueText = translatedTexts[2];
        _followText = translatedTexts[3];
        _followingText = translatedTexts[4];
      });
    }
  }

  void _onFollowChanged(bool isFollowing) {
    setState(() => _followedCount += isFollowing ? 1 : -1);
  }

  void _navigateToMainApp() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final canContinue = _followedCount >= _requiredFollows;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    '$_instruction ($_followedCount/$_requiredFollows)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 15),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: _suggestedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _suggestedUsers[index];
                      return _SuggestedUserListItem(
                        currentUserId: widget.uid,
                        targetUserId: user['id'],
                        username: user['username'],
                        handle: user['handle'],
                        isVerified: user['isVerified'],
                        onFollowChanged: _onFollowChanged,
                        followText: _followText,
                        followingText: _followingText,
                        followerManager: _followerManager,
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20.0),
        color: theme.scaffoldBackgroundColor,
        child: ElevatedButton(
          onPressed: canContinue ? _navigateToMainApp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            disabledBackgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          child: Text(_continueText),
        ),
      ),
    );
  }
}

class _SuggestedUserListItem extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String username;
  final String handle;
  final bool isVerified;
  final ValueChanged<bool> onFollowChanged;
  final String followText;
  final String followingText;
  final FollowerManager followerManager;

  const _SuggestedUserListItem({
    required this.currentUserId,
    required this.targetUserId,
    required this.username,
    required this.handle,
    required this.isVerified,
    required this.onFollowChanged,
    required this.followText,
    required this.followingText,
    required this.followerManager,
  });

  @override
  State<_SuggestedUserListItem> createState() => _SuggestedUserListItemState();
}

class _SuggestedUserListItemState extends State<_SuggestedUserListItem> {
  bool _isFollowing = false;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _checkInitialFollowingState();
  }

  Future<void> _checkInitialFollowingState() async {
    final isFollowing = await widget.followerManager.isFollowing(widget.currentUserId, widget.targetUserId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isProcessing = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_isFollowing) {
        await widget.followerManager.unfollowUser(widget.currentUserId, widget.targetUserId);
        widget.onFollowChanged(false);
      } else {
        await widget.followerManager.followUser(widget.currentUserId, widget.targetUserId);
        widget.onFollowChanged(true);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      print("Failed to toggle follow: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtextColor = theme.textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (widget.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.verified, color: Colors.blue, size: 15),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(widget.handle, style: TextStyle(color: subtextColor, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing
                  ? (theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300])
                  : Colors.blue,
              foregroundColor: _isFollowing ? theme.textTheme.bodyLarge?.color : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: _isFollowing ? BorderSide(color: Colors.grey.shade600, width: 0.5) : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(_isFollowing ? widget.followingText : widget.followText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
