 import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import 'create_page.dart';

mixin CreatePageLogic on State<CreatePage> {
  final List<AssetEntity> mediaList = [];
  int currentPage = 0;
  bool hasMore = true;
  bool isLoading = false;
  final ScrollController scrollController = ScrollController();

  final List<AssetEntity> selectedAssets = []; 
  AssetEntity? selectedAsset;
  Uint8List? selectedImageBytes;
  VideoPlayerController? videoController;

  void setupLogic() {
    scrollController.addListener(() {
      if (scrollController.position.extentAfter < 200 && !isLoading && hasMore) {
        fetchMedia();
      }
    });
    fetchMedia();
  }

  void disposeLogic() {
    scrollController.dispose();
    videoController?.dispose();
  }

  String formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void toggleSelection(AssetEntity asset) {
    if (selectedAssets.contains(asset)) {
      if (mounted) {
        setState(() {
          selectedAssets.remove(asset);
          if (selectedAssets.isNotEmpty) {
            updateActivePreview(selectedAssets.last);
          } else {
            selectedAsset = null;
          }
        });
      }
    } else {
      // 1. LIMIT YA JUMLA: Vitu 10 tu
      if (selectedAssets.length < 10) {
        
        if (asset.type == AssetType.video) {
          // 2. LIMIT YA VIDEO: Max Video 3 tu kwa kila post
          int videoCount = selectedAssets.where((a) => a.type == AssetType.video).length;
          if (videoCount >= 3) {
            _showErrorSnackBar("Unaweza kupakia mwisho video 3 tu kwa kila chapisho.");
            return;
          }

          // 3. LIMIT YA MUDA: Max Dakika 5 (sekunde 300)
          if (asset.duration > 300) {
            _showErrorSnackBar("Video ni ndefu sana! Mwisho ni dakika 5 kwa ajili ya waandishi.");
            return;
          }
        }

        if (mounted) {
          setState(() {
            selectedAssets.add(asset);
            updateActivePreview(asset);
          });
        }
      } else {
        _showErrorSnackBar("Unaweza kuchagua picha/video mpaka 10 tu.");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> updateActivePreview(AssetEntity asset) async {
    if (mounted) {
      setState(() {
        selectedAsset = asset;
        selectedImageBytes = null;
        videoController?.dispose();
        videoController = null;
      });
    }

    if (asset.type == AssetType.video) {
      try {
        final file = await asset.file;
        if (file != null) {
          videoController = VideoPlayerController.file(file)
            ..initialize().then((_) {
              if (mounted) {
                setState(() {});
                videoController?.play();
                videoController?.setLooping(true);
              }
            });
        }
      } catch (e) {
        developer.log('Error loading video', error: e);
      }
    } else {
      try {
        final Uint8List? imageBytes = await asset.originBytes;
        if (mounted) {
          setState(() => selectedImageBytes = imageBytes);
        }
      } catch (e) {
        developer.log('Error loading image', error: e);
      }
    }
  }

  Future<void> fetchMedia() async {
    if (isLoading || !hasMore) return;
    if (mounted) setState(() => isLoading = true);

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.hasAccess) {
        final filter = FilterOptionGroup(
          createTimeCond: DateTimeCond(
            min: DateTime.now().subtract(const Duration(days: 90)),
            max: DateTime.now(),
          ),
          orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
        );

        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.all,
          filterOption: filter,
        );

        if (albums.isNotEmpty) {
          final List<AssetEntity> newAssets = await albums.first.getAssetListPaged(
            page: currentPage,
            size: 20,
          );

          if (mounted) {
            setState(() {
              isLoading = false;
              if (newAssets.isEmpty) {
                hasMore = false;
              } else {
                mediaList.addAll(newAssets);
                currentPage++;
                if (selectedAssets.isEmpty && mediaList.isNotEmpty) {
                  toggleSelection(mediaList.first);
                }
              }
            });
          }
        } else {
          if (mounted) setState(() { isLoading = false; hasMore = false; });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
        PhotoManager.openSetting();
      }
    } catch (e, s) {
      developer.log('Error fetching media', name: 'my_app.gallery', error: e, stackTrace: s);
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> selectAsset(AssetEntity asset) async {
    updateActivePreview(asset);
  }
}
