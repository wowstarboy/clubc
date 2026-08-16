import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'services/media_manager.dart';
import 'auth/collections.dart';
import 'tag_users_page.dart';
import 'location_selection_page.dart';
import 'music_selection_page.dart';
import 'create_poll_page.dart';

class PostDetailPage extends StatefulWidget {
  final List<AssetEntity> selectedMedia;
  const PostDetailPage({super.key, required this.selectedMedia});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late List<AssetEntity> _tempMedia;
  final TextEditingController _captionController = TextEditingController();
  int _currentMediaIndex = 0;
  final PageController _pageController = PageController();

  // Data za ziada kutoka kwenye page nyingine
  List<String> _taggedUserIds = [];
  String? _selectedLocation;
  String? _selectedMusicUrl;
  Map<String, dynamic>? _pollData;

  @override
  void initState() {
    super.initState();
    _tempMedia = List.from(widget.selectedMedia);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handlePostUpload() async {
    final String caption = _captionController.text.trim();
    final List<AssetEntity> mediaToUpload = List.from(_tempMedia);

    Navigator.pop(context);
    Navigator.pop(context);

    try {
      List<String> uploadedUrls = [];
      String finalMediaType = "image";

      for (var asset in mediaToUpload) {
        File? file = await asset.file;
        if (file != null) {
          bool isVideo = asset.type == AssetType.video;
          if (isVideo) finalMediaType = "video";

          String? url = await MediaManager().uploadMedia(file, isVideo: isVideo);
          if (url != null) uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isNotEmpty || _pollData != null) {
        String postId = const Uuid().v4();
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;

        // Tunajumuisha data zote mpya hapa
        Map<String, dynamic> postData = {
          'postId': postId,
          'authorId': currentUserId,
          'mediaUrls': uploadedUrls,
          'mediaType': mediaToUpload.length > 1 ? "mixed" : finalMediaType,
          'caption': caption,
          'taggedUsers': _taggedUserIds,
          'location': _selectedLocation,
          'musicUrl': _selectedMusicUrl,
          'poll': _pollData,
          'likeCount': 0,
          'commentsCount': 0,
          'createdAt': Timestamp.now(),
        };

        await FirebaseFirestore.instance
            .collection(FirestoreCollections.posts)
            .doc(postId)
            .set(postData);
      }
    } catch (e) {
      debugPrint("Error uploading post: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Post', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 4,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // Data Preview Section (Professional Layout)
                  _buildDataPreview(isDarkMode),

                  if (_tempMedia.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _tempMedia.length,
                            onPageChanged: (index) => setState(() => _currentMediaIndex = index),
                            itemBuilder: (context, index) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  MediaPreviewWidget(asset: _tempMedia[index]),
                                  // Tag Edit Icon (Bottom Left)
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TagUsersPage(initialTags: _taggedUserIds)));
                                        if (result != null) setState(() => _taggedUserIds = result);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                  if (_tempMedia.length > 1)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _tempMedia.removeAt(index);
                                            if (_currentMediaIndex >= _tempMedia.length) _currentMediaIndex = _tempMedia.length - 1;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (_tempMedia.length > 1)
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                                child: Text('${_currentMediaIndex + 1}/${_tempMedia.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildBottomControls(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDataPreview(bool isDarkMode) {
    if (_selectedLocation == null && _selectedMusicUrl == null && _pollData == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedLocation != null) _buildChip(Icons.location_on, _selectedLocation!, () => setState(() => _selectedLocation = null)),
          if (_selectedMusicUrl != null) _buildChip(Icons.music_note, "Music Added", () => setState(() => _selectedMusicUrl = null)),
          if (_pollData != null) _buildChip(Icons.ballot, "Poll: ${_pollData!['question']}", () => setState(() => _pollData = null)),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(width: 4),
          GestureDetector(onTap: onDelete, child: const Icon(Icons.cancel, size: 14, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _handlePostUpload(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Share Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: Icon(Icons.music_note, color: _selectedMusicUrl != null ? Colors.blue : Colors.grey), onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => MusicSelectionPage(initialMusic: _selectedMusicUrl)));
                if (result != null) setState(() => _selectedMusicUrl = result);
              }),
              IconButton(icon: const Icon(Icons.perm_media, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              IconButton(icon: Icon(Icons.location_on, color: _selectedLocation != null ? Colors.blue : Colors.grey), onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => LocationSelectionPage(initialLocation: _selectedLocation)));
                if (result != null) setState(() => _selectedLocation = result);
              }),
              IconButton(icon: Icon(Icons.person_add, color: _taggedUserIds.isNotEmpty ? Colors.blue : Colors.grey), onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TagUsersPage(initialTags: _taggedUserIds)));
                if (result != null) setState(() => _taggedUserIds = result);
              }),
              IconButton(icon: Icon(Icons.ballot_outlined, color: _pollData != null ? Colors.blue : Colors.grey), onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePollPage()));
                if (result != null) setState(() => _pollData = result);
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class MediaPreviewWidget extends StatelessWidget {
  final AssetEntity asset;
  const MediaPreviewWidget({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.type == AssetType.video ? asset.thumbnailData : asset.originBytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Stack(fit: StackFit.expand, children: [
            Image.memory(snapshot.data!, fit: BoxFit.cover),
            if (asset.type == AssetType.video) const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 60)),
          ]);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
