 import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/collections.dart'; 
import '../services/media_manager.dart'; 

class StoryDetailPage extends StatefulWidget {
  final List<AssetEntity> selectedAssets;

  const StoryDetailPage({super.key, required this.selectedAssets});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  late PageController _mainPageController;
  late ScrollController _thumbScrollController;
  int _currentIndex = 0;
  
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _mainPageController = PageController();
    _thumbScrollController = ScrollController();
    _initializeController(0);
  }

  Future<void> _initializeController(int index) async {
    final asset = widget.selectedAssets[index];
    if (asset.type == AssetType.video && !_controllers.containsKey(index)) {
      final file = await asset.file;
      if (file != null) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        controller.setLooping(true);
        controller.play();
        
        controller.addListener(() {
          if (controller.value.position >= const Duration(minutes: 1)) {
            controller.seekTo(Duration.zero);
          }
        });

        setState(() {
          _controllers[index] = controller;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _initializeController(index);
    _controllers.forEach((key, controller) {
      if (key != index) controller.pause();
    });
    if (_controllers.containsKey(index)) _controllers[index]!.play();

    _thumbScrollController.animateTo(
      index * 70.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // FUNCTION YA KU-SHARE STORY (Imeongezewa logic ya Upload Indicators)
  Future<void> _handleShareStory() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    // 1. Anza animation ya duara kule Home
    await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(currentUserId).update({
      'isUploadingStory': true,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    try {
      List<String> uploadedMediaPaths = [];

      for (var asset in widget.selectedAssets) {
        File? file = await asset.file;
        if (file != null) {
          bool isVideo = asset.type == AssetType.video;
          
          String? path = await MediaManager().uploadMedia(
            file, 
            isVideo: isVideo, 
            isStory: true
          );

          if (path != null) {
            uploadedMediaPaths.add(path);
          }
        }
      }

      if (uploadedMediaPaths.isNotEmpty) {
        final String storyId = FirebaseFirestore.instance.collection(FirestoreCollections.stories).doc().id;
        
        await FirebaseFirestore.instance.collection(FirestoreCollections.stories).doc(storyId).set({
          FirestoreCollections.storyId: storyId,
          FirestoreCollections.authorId: currentUserId,
          FirestoreCollections.mediaUrls: uploadedMediaPaths,
          FirestoreCollections.mediaType: widget.selectedAssets.first.type == AssetType.video ? 'video' : 'image',
          FirestoreCollections.createdAt: FieldValue.serverTimestamp(),
          FirestoreCollections.expiresAt: Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
          FirestoreCollections.viewers: [],
        });

        // 2. Maliza animation na weka duara la blue lililotulia
        await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(currentUserId).update({
          'isUploadingStory': false,
          'hasActiveStory': true,
        });

        if (mounted) {
          Navigator.of(context).pop(); // Funga loading
          Navigator.of(context).pop(); // Funga Page na kurudi nyuma
        }
      }
    } catch (e) {
      // Kama ikifeli, zima indicator ya upload
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(currentUserId).update({
        'isUploadingStory': false,
      });
      if (mounted) Navigator.of(context).pop();
      debugPrint("Error sharing story: $e");
    }
  }

  @override
  void dispose() {
    _mainPageController.dispose();
    _thumbScrollController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _mainPageController,
            itemCount: widget.selectedAssets.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final asset = widget.selectedAssets[index];
              if (asset.type == AssetType.video) {
                final controller = _controllers[index];
                return controller != null && controller.value.isInitialized
                    ? Center(child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)))
                    : const Center(child: CircularProgressIndicator(color: Colors.blue));
              } else {
                return FutureBuilder<File?>(
                  future: asset.file,
                  builder: (context, snap) {
                    if (snap.hasData) return Image.file(snap.data!, fit: BoxFit.cover);
                    return const Center(child: CircularProgressIndicator());
                  },
                );
              }
            },
          ),

          _buildTopControls(),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                controller: _thumbScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.selectedAssets.length,
                itemBuilder: (context, index) {
                  final asset = widget.selectedAssets[index];
                  final isSelected = _currentIndex == index;

                  return GestureDetector(
                    onTap: () {
                      _mainPageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AssetThumbnail(asset: asset),
                            if (asset.type == AssetType.video)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Text(
                                  "${asset.duration ~/ 60}:${(asset.duration % 60).toString().padLeft(2, '0')}",
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          _buildShareButton(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Row(
            children: [
              _topIcon(Icons.music_note_rounded),
              const SizedBox(width: 15),
              _topIcon(Icons.text_fields_rounded, label: "Aa"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: _handleShareStory, 
        icon: const Icon(Icons.send_rounded),
        label: const Text("Share", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _topIcon(IconData icon, {String? label}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
      child: label != null ? Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;
  const AssetThumbnail({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
      builder: (context, snapshot) {
        if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
        return Container(color: Colors.grey[900]);
      },
    );
  }
}
