 
 import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamiiclub/services/like_service.dart';
import 'package:jamiiclub/comment_sheet.dart';
import 'services/media_manager.dart';
import 'models/post_model.dart';
import 'auth/collections.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostCard({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final subtleTextColor = Theme.of(context).textTheme.bodySmall?.color;
    
    final String caption = postData['caption'] ?? "";
    final bool hasCaption = caption.trim().isNotEmpty;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            authorId: postData['authorId'],
            createdAt: postData['createdAt'],
            isDarkMode: isDarkMode, 
            iconColor: iconColor, 
            textColor: textColor, 
            subtleTextColor: subtleTextColor
          ),

          // HAPA: Kila kitu kinachohusu caption na translation 
          // kimefungwa hapa ili kisilete gap kama caption haipo.
          if (hasCaption) ...[
            const SizedBox(height: 3),
            _PostCaption(
              caption: caption,
              textColor: textColor, 
              subtleTextColor: subtleTextColor
            ),
            const SizedBox(height: 8), 
            _TranslatedText(textColor: textColor, subtleTextColor: subtleTextColor),
          ],
          
          // Hii itatoa nafasi TU kati ya (Header/Caption) na Media
          const SizedBox(height: 10),
          
          _PostMedia(
            mediaUrls: List<String>.from(postData['mediaUrls'] ?? []),
            isDarkMode: isDarkMode
          ),

          _PostActions(
            postId: postData[FirestoreCollections.postId],
            iconColor: iconColor, 
            textColor: textColor,
            likeCount: postData[FirestoreCollections.likeCount] ?? 0,
            commentsCount: postData[FirestoreCollections.commentsCount] ?? 0,
          ),

          const SizedBox(height: 1),
          _PostStats(
              likeCount: postData[FirestoreCollections.likeCount] ?? 0,
              commentsCount: postData[FirestoreCollections.commentsCount] ?? 0,
              textColor: textColor,
              subtleTextColor: subtleTextColor,
              onCommentTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CommentSheet(postId: postData[FirestoreCollections.postId]),
                );
              },
            ),
        ],
      ),
    );
  }
}


class _PostHeader extends StatelessWidget {
  final String authorId;
  final Timestamp? createdAt;
  final bool isDarkMode;
  final Color? iconColor;
  final Color textColor;
  final Color? subtleTextColor;

  const _PostHeader({
    required this.authorId,
    this.createdAt,
    required this.isDarkMode, 
    this.iconColor, 
    required this.textColor, 
    this.subtleTextColor
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(authorId).get(),
      builder: (context, snapshot) {
        String username = "loading...";
        String profilePhoto = "";
        
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          username = userData[FirestoreCollections.username] ?? "user";
          profilePhoto = userData[FirestoreCollections.profilePhotoUrl] ?? "";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: profilePhoto.isNotEmpty 
                    ? NetworkImage(MediaManager().getUrl(profilePhoto)) 
                    : null,
                child: profilePhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(username, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  _PostTimestamp(createdAt: createdAt, subtleTextColor: subtleTextColor),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Follow', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              IconButton(icon: Icon(Icons.more_horiz, color: iconColor), onPressed: () {}),
            ],
          ),
        );
      }
    );
  }
}

class _PostMedia extends StatefulWidget {
  final List<String> mediaUrls;
  final bool isDarkMode;

  const _PostMedia({super.key, required this.mediaUrls, required this.isDarkMode});

  @override
  State<_PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<_PostMedia> {
  int _currentPage = 1; // Kwa ajili ya kuhesabu picha (1/2)

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // Sehemu ya Picha zinazo swipe
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 200, // Min height uliyotaka
            maxHeight: 600, // Max height uliyotaka
          ),
          child: Container(
            width: double.infinity,
            color: widget.isDarkMode ? Colors.black : Colors.grey[200],
            child: PageView.builder(
              itemCount: widget.mediaUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index + 1;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  MediaManager().getUrl(widget.mediaUrls[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      const Center(child: Icon(Icons.broken_image)),
                );
              },
            ),
          ),
        ),

        // Count Indicator (1/2) - Inatokea TU kama picha ni zaidi ya moja
        if (widget.mediaUrls.length > 1)
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$_currentPage/${widget.mediaUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class _PostActions extends StatefulWidget {
  final String postId;
  final Color? iconColor;
  final Color textColor;
  final int likeCount;      // Ongeza hii
  final int commentsCount;  // Ongeza hii

  const _PostActions({
    required this.postId, 
    this.iconColor, 
    required this.textColor,
    required this.likeCount,
    required this.commentsCount,
  });

  @override
  __PostActionsState createState() => __PostActionsState();
}

class __PostActionsState extends State<_PostActions> {
  final LikeService _likeService = LikeService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 1. Share Button
              Row(
                children: [
                  IconButton(
                      icon: Icon(Icons.near_me_outlined,
                          size: 28,
                          color: widget.iconColor),
                      onPressed: () {}),
                  // Kwa kuwa share hapa ni 0 (tuliweka placeholder), haitaonekana
                ],
              ),

              const SizedBox(width: 8),

              // 2. Comment Button na Count
              Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/comment.svg',
                      height: 25,
                      colorFilter:
                          ColorFilter.mode(widget.iconColor!, BlendMode.srcIn),
                    ),
                    onPressed: () {
                       showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommentSheet(postId: widget.postId),
                      );
                    },
                  ),
                  // Inatokea TU kama count ni zaidi ya 0
                  if (widget.commentsCount > 0)
                    Text('${widget.commentsCount}', 
                      style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(width: 8),

              // 3. Like Button na Count
              StreamBuilder<bool>(
                stream: _likeService.hasLikedPost(widget.postId),
                builder: (context, snapshot) {
                  bool isLiked = snapshot.data ?? false;
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 28,
                          color: isLiked ? Colors.red : widget.iconColor,
                        ),
                        onPressed: () {
                          if (isLiked) {
                            _likeService.unlikePost(widget.postId);
                          } else {
                            _likeService.likePost(widget.postId);
                          }
                        },
                      ),
                      // Inatokea TU kama count ni zaidi ya 0
                      if (widget.likeCount > 0)
                        Text('${widget.likeCount}', 
                          style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _PostStats extends StatelessWidget {
  final int likeCount;
  final int commentsCount;
  final Color textColor;
  final Color? subtleTextColor;
  final VoidCallback onCommentTap; 

  const _PostStats({
    required this.likeCount, 
    required this.commentsCount, 
    required this.textColor, 
    this.subtleTextColor,
    required this.onCommentTap
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sehemu ya Likes inabaki kama ilivyokuwa mwanzo bila mabadiliko
          if (likeCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '$likeCount likes', 
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
              ),
            ),
            
          // HAPA: Kama hakuna comments, tunarudisha SizedBox tupu kabisa (0 pixels)
          // Hii itafuta lile gap unaloona chini ya likeCount
          commentsCount > 0 
            ? GestureDetector(
                onTap: onCommentTap, 
                child: Text(
                  'View all $commentsCount comments', 
                  style: TextStyle(color: subtleTextColor)
                ),
              )
            : const SizedBox.shrink(), // Haichukui nafasi yoyote
        ],
      ),
    );
  }
}

class _PostCaption extends StatelessWidget {
  final String caption;
  final Color textColor;
  final Color? subtleTextColor;

  const _PostCaption({required this.caption, required this.textColor, this.subtleTextColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: textColor, height: 1.4),
          children: [
            TextSpan(text: caption),
          ],
        ),
      ),
    );
  }
}

// Hii imebaki kuwa simple maana sharti (if) limeshabeba mzigo kule juu
class _TranslatedText extends StatelessWidget {
  final Color textColor;
  final Color? subtleTextColor;
  const _TranslatedText({required this.textColor, this.subtleTextColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        'See translation', 
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: textColor, 
          fontSize: 12
        )
      ),
    );
  }
}

class _PostTimestamp extends StatelessWidget {
  final Timestamp? createdAt;
  final Color? subtleTextColor;

  const _PostTimestamp({this.createdAt, this.subtleTextColor});

  @override
  Widget build(BuildContext context) {
    String timeAgo = "now";
    if (createdAt != null) {
      final difference = DateTime.now().difference(createdAt!.toDate());
      if (difference.inMinutes < 60) timeAgo = "${difference.inMinutes}m";
      else if (difference.inHours < 24) timeAgo = "${difference.inHours}h";
      else timeAgo = "${difference.inDays}d";
    }
    return Text(timeAgo, style: TextStyle(color: subtleTextColor, fontSize: 14));
  }
}