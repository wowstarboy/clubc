import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jamiiclub/inbox_page.dart';
import 'package:jamiiclub/providers/scroll_provider.dart';
import 'package:jamiiclub/reels_page.dart';
import 'package:provider/provider.dart';

import 'stories.dart';
// Import file lako la provider hapa
import 'services/post_provider.dart'; 

// Hii ndio switch itakayopokea taarifa kutoka PostDetailPage
final ValueNotifier<bool> isUploadingGlobal = ValueNotifier<bool>(false);

class HomePage extends StatelessWidget {
  final VoidCallback onAddPost;
  final ScrollController scrollController;

  const HomePage({super.key, required this.onAddPost, required this.scrollController});

  Future<void> _handleRefresh() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerIconColor = isDarkMode ? Colors.white : Colors.black;

    // Define gradient here to be reused
    const gradient = LinearGradient(
      colors: [
        Color(0xFF1565C0), // Colors.blue.shade900
        Color(0xFF42A5F5), // Colors.blue.shade400
        Color(0xFF18FFFF), // Colors.cyanAccent
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight), // Keep original height
        child: Consumer<ScrollProvider>(
          builder: (context, scrollProvider, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: scrollProvider.isVisible ? kToolbarHeight + MediaQuery.of(context).padding.top : 0,
              child: child, // The actual AppBar content
            );
          },
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                automaticallyImplyLeading: false,
                title: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => gradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: const Text(
                    'JamiiClub',
                    style: TextStyle(
                      fontFamily: 'LobsterTwo',
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/clapperboard-play.svg',
                      height: 24,
                      colorFilter: ColorFilter.mode(headerIconColor, BlendMode.srcIn),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReelsPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/paper-plane (1).svg',
                      height: 24,
                      colorFilter: ColorFilter.mode(headerIconColor, BlendMode.srcIn),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InboxPage()),
                      );
                    },
                  ),
                ],
                backgroundColor: isDarkMode ? const Color(0xFF0D1015).withOpacity(0.7) : Colors.white.withOpacity(0.7),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: isDarkMode ? Colors.white : Colors.black,
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        child: ListView(
            controller: scrollController,
            children: [
              const StorySection(),
              
              ValueListenableBuilder<bool>(
                valueListenable: isUploadingGlobal,
                builder: (context, isUploading, child) {
                  if (!isUploading) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  );
                },
              ),

              const GlobalPostStreamer(),
            ],
          ),
        ),
    );
  }
}
