import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../auth/collections.dart';
import '../post.dart';
import '../post_skelleton.dart';
import '../reels_skelleton.dart'; 
import '../providers/cache_provider.dart'; 

class PostProvider extends ChangeNotifier {
  final List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _hasNext = true;
  final int _documentLimit = 10;

  List<DocumentSnapshot> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasNext => _hasNext;

  Stream<QuerySnapshot> getUserPostsStream(String userId, String mediaType) {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.posts)
        .where('userId', isEqualTo: userId)
        .where('mediaType', isEqualTo: mediaType)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 1. Global Stream inayotumia CacheProvider (Optimization)
  Stream<QuerySnapshot> getCachedPostStream(BuildContext context) {
    final cache = Provider.of<CacheProvider>(context, listen: false);
    return cache.getStream<QuerySnapshot>(
      key: 'global_posts_stream',
      streamBuilder: () => FirebaseFirestore.instance
          .collection(FirestoreCollections.posts)
          .orderBy('createdAt', descending: true)
          .limit(_documentLimit)
          .snapshots(),
    );
  }

  // 2. Pagination Logic (Inabaki vilevile kwa ajili ya Lazy Loading)
  Future<void> fetchPosts() async {
    if (_isLoading || !_hasNext) return;

    _isLoading = true;
    notifyListeners();

    Query query = FirebaseFirestore.instance
        .collection(FirestoreCollections.posts)
        .orderBy('createdAt', descending: true)
        .limit(_documentLimit);

    if (_posts.isNotEmpty) {
      query = query.startAfterDocument(_posts.last);
    }

    try {
      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < _documentLimit) {
        _hasNext = false;
      }

      _posts.addAll(querySnapshot.docs);
    } catch (e) {
      debugPrint("Error fetching posts: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPosts(BuildContext context) async {
    _posts.clear();
    _hasNext = true;
    // Safisha cache ya stream pindi user anapovuta "Pull to Refresh"
    Provider.of<CacheProvider>(context, listen: false).clear('global_posts_stream');
    await fetchPosts();
  }
}

class GlobalPostStreamer extends StatefulWidget {
  final ScrollController? scrollController;
  final bool isScrollable;

  const GlobalPostStreamer({
    super.key, 
    this.scrollController, 
    this.isScrollable = false
  });

  @override
  State<GlobalPostStreamer> createState() => _GlobalPostStreamerState();
}

class _GlobalPostStreamerState extends State<GlobalPostStreamer> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PostProvider>(context, listen: false);
      if (provider.posts.isEmpty) {
        provider.fetchPosts();
      }
    });

    widget.scrollController?.addListener(() {
      if (widget.scrollController!.position.pixels >=
          widget.scrollController!.position.maxScrollExtent - 300) {
        Provider.of<PostProvider>(context, listen: false).fetchPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PostProvider>(context);

    if (provider.posts.isEmpty && provider.isLoading) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => const PostSkeleton(),
      );
    }

    if (provider.posts.isEmpty && !provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No posts yet", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      controller: widget.isScrollable ? widget.scrollController : null,
      shrinkWrap: true,
      physics: widget.isScrollable 
          ? const AlwaysScrollableScrollPhysics() 
          : const NeverScrollableScrollPhysics(),
      itemCount: provider.posts.length + (provider.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
          );
        }

        final postData = provider.posts[index].data() as Map<String, dynamic>;
        return PostCard(postData: postData);
      },
    );
  }
}
