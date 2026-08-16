import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/services/comment_service.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/services/replies_service.dart';
import 'package:jamiiclub/widgets/comment_skeleton.dart';
import 'dart:ui';


class CommentSheet extends StatefulWidget {
  final String postId;

  const CommentSheet({super.key, required this.postId});

  @override
  _CommentSheetState createState() => _CommentSheetState();
}
class _CommentSheetState extends State<CommentSheet> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController(); // Hii ndio controller yako
  final currentUser = FirebaseAuth.instance.currentUser;
  
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = _commentService.getComments(widget.postId);
    
    // HAPA NDIPO PALIKUWA NA ERROR:
    // Tusiweke listener ya '_canPost' hapa kwani iko ndani ya '_CommentInputField'
    // Acha hapa pawe na stream tu.
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        child: Column(
          children: [
            // Glass Header
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Hii inahitaji import 'dart:ui'
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0D1015).withOpacity(0.7) : Colors.white.withOpacity(0.7),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        width: 40, height: 5,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text('Comments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Comments List
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _commentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) => const CommentSkeleton(),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No comments yet. Be the first to comment!', style: TextStyle(color: Colors.grey)));
                    }
                    var comments = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var comment = comments[index].data() as Map<String, dynamic>;
                        return _CommentTile(commentData: comment);
                      },
                    );
                  },
                ),
              ),
            ),

            // Input Field Section
            _CommentInputField(
              controller: _commentController, // Kutumia controller sahihi
              onPost: () {
                _commentService.addComment(widget.postId, _commentController.text);
                _commentController.clear();
              },
              currentUser: currentUser,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

// NIMEIBADILISHA HII KUWA STATEFUL WIDGET, KAMA TULIVYOKUBALIANA
class _CommentTile extends StatefulWidget {
  final Map<String, dynamic> commentData;

  const _CommentTile({required this.commentData});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    // CODE ZOTE ZIMERUDI HAPA BILA MABADILIKO, ILA SASA ZIKO NDANI YA STATE
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(widget.commentData[FirestoreCollections.authorId]).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox(height: 70);
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String username = userData[FirestoreCollections.username] ?? 'User';
        String profilePhoto = userData[FirestoreCollections.profilePhotoUrl] ?? '';
        int likeCount = widget.commentData.containsKey(FirestoreCollections.commentLikeCount) ? widget.commentData[FirestoreCollections.commentLikeCount] : 0;

        return ListTile(
          isThreeLine: true,
          leading: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: profilePhoto.isNotEmpty ? NetworkImage(MediaManager().getUrl(profilePhoto)) : null,
              child: profilePhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(widget.commentData[FirestoreCollections.createdAt]),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.commentData[FirestoreCollections.commentText] ?? ''),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Reply', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  Text('See translation', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_outline, size: 20),
              if (likeCount > 0)
                Text(likeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        );
      },
    );
  }
}



class _CommentInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onPost;
  final User? currentUser;
  final bool isDarkMode;

  const _CommentInputField({
    required this.controller,
    required this.onPost,
    required this.currentUser,
    required this.isDarkMode,
  });

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  String profilePhoto = "";
  bool _canPost = false;
  final FocusNode _focusNode = FocusNode();

   @override
  void dispose() {
    _focusNode.dispose(); // Hakikisha unaifuta ikimaliza kazi
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _canPost = widget.controller.text.isNotEmpty;
      });
    });

    if (widget.currentUser != null) {
      FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(widget.currentUser!.uid)
          .get()
          .then((snapshot) {
        if (snapshot.exists && mounted) {
          var userData = snapshot.data() as Map<String, dynamic>;
          setState(() {
            profilePhoto = userData[FirestoreCollections.profilePhotoUrl] ?? "";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> emojis = ['🔥', '🤣', '🙌', '😂', '😡', '🙏', '❤', '😮', '😥'];

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
  // 1. Inafuata rangi ya body yako (iwe ni dark au light)
  color: Theme.of(context).scaffoldBackgroundColor, 
  
  border: Border(
    top: BorderSide(
      // 2. Inatumia opacity badala ya black10 kuzuia error
      color: widget.isDarkMode 
          ? Colors.white.withOpacity(0.1) 
          : Colors.black.withOpacity(0.1),
      width: 0.5,
    ),
  ),
),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: emojis.map((emoji) {
                return InkWell(
                  onTap: () {
                     _focusNode.requestFocus(); 
                    final controller = widget.controller;
                    final text = controller.text;
                    final selection = controller.selection;
                    final newText = text.replaceRange(selection.start, selection.end, emoji);
                    controller.text = newText;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: selection.start + emoji.length),
                    );
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: profilePhoto.isNotEmpty ? NetworkImage(MediaManager().getUrl(profilePhoto)) : null,
                child: profilePhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
  child: TextField(
    controller: widget.controller,
    focusNode: _focusNode, // Hakikisha umeongeza hii hapa
    decoration: InputDecoration(
      hintText: 'Add a comment...',
      border: InputBorder.none,
    ),
  ),
),

              if (_canPost)
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: widget.onPost,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                )
            ],
          ),
        ],
      ),
    );
  }
}
