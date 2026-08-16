 import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'create_page_logic.dart';
import 'post_detail_page.dart'; // Hakikisha umeimport file la pili hapa

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> with CreatePageLogic {
  // PageController kwa ajili ya swipe preview
  final PageController _pageController = PageController();
  int _currentPreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    setupLogic();
  }

  @override
  void dispose() {
    _pageController.dispose();
    disposeLogic();
    super.dispose();
  }

  // Preview Section iliyoboreshwa kwa ajili ya Swipe na Namba
  Widget _buildPreview() {
    if (selectedAssets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: selectedAssets.length,
          onPageChanged: (index) {
            setState(() => _currentPreviewIndex = index);
            // Tunabadilisha video controller kulingana na picha iliyopo mbele
            updateActivePreview(selectedAssets[index]);
          },
          itemBuilder: (context, index) {
            final asset = selectedAssets[index];
            if (asset.type == AssetType.video) {
              return videoController != null && videoController!.value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: videoController!.value.aspectRatio,
                        child: VideoPlayer(videoController!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator());
            } else {
              // Preview ya picha
              return FutureBuilder<Uint8List?>(
                future: asset.originBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              );
            }
          },
        ),
        // Swipe Indicator (Namba ya kila swipe mfano: 1/5)
        if (selectedAssets.length > 1)
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${_currentPreviewIndex + 1}/${selectedAssets.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue, size: 32),
            onPressed: () {
              // Logic ya kuendelea na chapisho - Inatuma media kwenda page ya pili
              if (selectedAssets.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailPage(selectedMedia: selectedAssets),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tafadhali chagua picha au video kwanza")),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview Section yenye Swipe Indicator
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
              child: _buildPreview(),
            ),
          ),
          
          Expanded(
            child: mediaList.isEmpty && isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    controller: scrollController,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 1.5,
                      mainAxisSpacing: 1.5,
                    ),
                    itemCount: mediaList.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == mediaList.length) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                      }

                      final AssetEntity asset = mediaList[index];
                      final int selectedIndex = selectedAssets.indexOf(asset);
                      final bool isSelected = selectedIndex != -1;

                      return GestureDetector(
                        onTap: () {
                          toggleSelection(asset);
                          // Kama ni picha mpya, scroll preview hadi mwisho
                          if (!isSelected && selectedAssets.length < 10) {
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (_pageController.hasClients) {
                                _pageController.jumpToPage(selectedAssets.length - 1);
                              }
                            });
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MediaThumbnail(
                              asset: asset,
                              isSelected: isSelected,
                            ),
                            
                            // Blue Circle yenye Namba (kama Story Picker)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                height: 22,
                                width: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.blue : Colors.black.withOpacity(0.3),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Center(
                                  child: isSelected 
                                    ? Text(
                                        "${selectedIndex + 1}",
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ) 
                                    : const SizedBox.shrink(),
                                ),
                              ),
                            ),

                            if (asset.type == AssetType.video)
                              Positioned(
                                left: 5,
                                bottom: 5,
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                                    Text(
                                      formatDuration(asset.duration),
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold,
                                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MediaThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  const MediaThumbnail({super.key, required this.asset, required this.isSelected});

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<Uint8List?>(
      future: widget.asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Opacity(
            opacity: widget.isSelected ? 0.6 : 1.0,
            child: Image.memory(
              snapshot.data!, 
              fit: BoxFit.cover, 
              gaplessPlayback: true,
            ),
          );
        }
        return Container(color: isDarkMode ? Colors.grey[900] : Colors.grey[300]);
      },
    );
  }
}
