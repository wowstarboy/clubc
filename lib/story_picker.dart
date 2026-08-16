import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:jamiiclub/live_stream_page.dart';
import 'package:jamiiclub/template_story_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:developer' as developer;
import 'story_detail_page.dart'; // Hakikisha path hii ni sahihi

class StoryPicker extends StatefulWidget {
  const StoryPicker({super.key});

  @override
  State<StoryPicker> createState() => _StoryPickerState();
}

class _StoryPickerState extends State<StoryPicker> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0; // Kwa ajili ya kugeuza kamera
  bool _isPhotoMode = true; // Kwa ajili ya kubadili mode

  final DraggableScrollableController _scrollController = DraggableScrollableController();

  // Variables for pagination
  final List<AssetEntity> _assets = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  final ScrollController _galleryScrollController = ScrollController();

  // Selection variables
  final List<AssetEntity> _selectedAssets = [];
  final int _maxSelection = 10;

  @override
  void initState() {
    super.initState();
    _initializeCamera(cameraIndex: _selectedCameraIndex);
    _galleryScrollController.addListener(() {
      if (_galleryScrollController.position.extentAfter < 200 && !_isLoading && _hasMore) {
        _loadMoreAssets();
      }
    });
    _loadMoreAssets();
  }

  Future<void> _initializeCamera({int cameraIndex = 0}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      developer.log('No cameras found on this device.');
      return;
    }
    
    // Chagua kamera kulingana na index
    _selectedCameraIndex = cameraIndex;
    _cameraController = CameraController(_cameras[_selectedCameraIndex], ResolutionPreset.high);

    await _cameraController.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _galleryScrollController.dispose();
    super.dispose();
  }
  
  void _flipCamera() {
    if (_cameras.length < 2) return; // Hakuna cha kugeuza
    final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _initializeCamera(cameraIndex: newIndex);
  }

  void _toggleCameraMode() {
    setState(() {
      _isPhotoMode = !_isPhotoMode;
    });
  }

  void _toggleFlash() {
    if (_cameraController.value.flashMode == FlashMode.torch) {
      _cameraController.setFlashMode(FlashMode.off);
      setState(() => _isFlashOn = false);
    } else {
      _cameraController.setFlashMode(FlashMode.torch);
      setState(() => _isFlashOn = true);
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else if (_selectedAssets.length < _maxSelection) {
        _selectedAssets.add(asset);
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized)
            Positioned.fill(child: CameraPreview(_cameraController))
          else
            const Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            )),
          
          _buildControlsAndGallery(),

          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          Positioned(
            top: 40,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 28),
                  onPressed: _toggleFlash,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TemplateStoryPage()),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.blue, Colors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LiveStreamPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Go Live',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedAssets.isNotEmpty)
            Positioned(
              bottom: 110,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryDetailPage(selectedAssets: _selectedAssets),
                    ),
                  );
                },
                child: const Icon(Icons.done, color: Colors.white, size: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsAndGallery() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      controller: _scrollController,
      builder: (BuildContext context, ScrollController sheetScrollController) {
        sheetScrollController.addListener(() {
          if (sheetScrollController.position.extentAfter < 200 && !_isLoading && _hasMore) {
            _loadMoreAssets();
          }
        });

        return Container(
          color: Colors.black.withOpacity(0.3),
          child: Column(
            children: [
              _buildCaptureControls(),
              Expanded(
                child: _buildGallery(sheetScrollController), 
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptureControls() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(_isPhotoMode ? Icons.videocam_outlined : Icons.camera_alt_outlined, color: Colors.white, size: 30),
            onPressed: _toggleCameraMode,
          ),
          GestureDetector(
            onTap: () async {
              // Hapa itawekwa logic ya kupiga picha au kurekodi video
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 3),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
            onPressed: _flipCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(ScrollController scrollController) {
    if (_assets.isEmpty && _isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          )
        );
    }
    
    if (_assets.isEmpty && !_hasMore) {
      return const Center(
        child: Text(
          'No media found on this device.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController, 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _assets.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _assets.length) {
          return const Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ));
        }

        final asset = _assets[index];
        final isSelected = _selectedAssets.contains(asset);
        final selectIndex = _selectedAssets.indexOf(asset) + 1;

        return GestureDetector(
          onTap: () => _toggleSelection(asset),
          child: Stack(
            children: [
              Positioned.fill(
                child: FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes == null) return Container(color: Colors.grey[800]);
                    return Image.memory(bytes, fit: BoxFit.cover);
                  },
                ),
              ),
              
              if (asset.type == AssetType.video)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                      Text(
                        _formatDuration(asset.duration),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blue : Colors.black26,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: isSelected 
                      ? Text('$selectIndex', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                      : null,
                  ),
                ),
              ),

              if (isSelected)
                Positioned.fill(child: Container(color: Colors.white24)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadMoreAssets() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

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
          final List<AssetEntity> newAssets = await albums.first.getAssetListPaged(page: _currentPage, size: 20);
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (newAssets.isEmpty) {
                _hasMore = false;
              } else {
                _assets.addAll(newAssets);
                _currentPage++;
              }
            });
          }
        } else {
          if (mounted) setState(() { _isLoading = false; _hasMore = false; });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; _hasMore = false; });
      }
    } catch (e, stack) {
      developer.log('Critical error in _loadMoreAssets: $e', error: e, stackTrace: stack);
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
