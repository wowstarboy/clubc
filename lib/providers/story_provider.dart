 import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryProvider extends ChangeNotifier {
  int _currentIndex = 0;
  double _percent = 0.0;
  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _isPaused = false;

  int get currentIndex => _currentIndex;
  double get percent => _percent;
  bool get isPaused => _isPaused;
  VideoPlayerController? get videoController => _videoController;

  // Muda wa picha (sekunde 5)
  static const Duration imageDuration = Duration(seconds: 5);

  // 1. ANZA STORY
  void startStory(int index, {VideoPlayerController? controller}) {
    _currentIndex = index;
    _percent = 0.0;
    _videoController = controller;
    _isPaused = false;
    _startTimer();
    notifyListeners();
  }

  // UPDATE MPYA: Inapokea video controller na kuanzisha timer upya
  void updateVideoController(VideoPlayerController? controller) {
    _videoController = controller;
    _percent = 0.0; // Reset progress kwa ajili ya media mpya
    _startTimer();
    notifyListeners();
  }

  // 2. LOGIC YA TIMER
  void _startTimer() {
    _timer?.cancel();
    
    // Kama ni Video, timer itafuata urefu wa video (max 60s)
    // Kama ni Picha, timer itachukua sekunde 5
    Duration duration = (_videoController != null && _videoController!.value.isInitialized)
        ? _videoController!.value.duration 
        : imageDuration;

    // Hakikisha video haizidi dakika moja kwenye progress bar
    if (duration > const Duration(minutes: 1)) {
      duration = const Duration(minutes: 1);
    }

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused) {
        // Kinga dhidi ya division by zero kama duration ni 0
        if (duration.inMilliseconds > 0) {
          _percent += 50 / duration.inMilliseconds;
        }
        
        if (_percent >= 1.0) {
          _percent = 1.0;
          _timer?.cancel();
          nextStory(); // Ikiisha, nenda inayofuata automatic
        }
        notifyListeners();
      }
    });
  }

  // 3. NENDA NEXT STORY
  void nextStory() {
    _percent = 0.0;
    _currentIndex++;
    _startTimer(); // Anza timer ya story inayofuata
    notifyListeners();
  }

  // 4. RUDI NYUMA
  void previousStory() {
    _percent = 0.0;
    if (_currentIndex > 0) {
      _currentIndex--;
      _startTimer(); // Anza timer ya story iliyopita
    }
    notifyListeners();
  }

  // 5. PAUSE/RESUME (User akikandamiza kidole)
  void pause() {
    _isPaused = true;
    _videoController?.pause();
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    _videoController?.play();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }
}
