import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'dart:collection';

class CacheProvider with ChangeNotifier {
  final Map<String, BehaviorSubject<dynamic>> _cache = {};
  final Map<String, VideoPlayerController> _videoControllerCache = LinkedHashMap();

  static const int _maxVideoCacheSize = 50;

  Stream<T> getStream<T>({
    required String key,
    required Stream<T> Function() streamBuilder,
  }) {
    if (_cache.containsKey(key)) {
      return _cache[key]!.stream as Stream<T>;
    }

    final subject = BehaviorSubject<T>();
    _cache[key] = subject;

    streamBuilder().listen(
      (data) => subject.add(data),
      onError: (error, stack) => subject.addError(error, stack),
      onDone: () => subject.close(),
    );

    return subject.stream;
  }

  VideoPlayerController getVideoController(String videoUrl) {
    if (_videoControllerCache.containsKey(videoUrl)) {
      final controller = _videoControllerCache.remove(videoUrl)!;
      _videoControllerCache[videoUrl] = controller;
      return controller;
    } else {
      final controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          if (_videoControllerCache.containsKey(videoUrl)) {
            notifyListeners();
          }
        });

      _videoControllerCache[videoUrl] = controller;
      _enforceVideoCacheLimit();
      return controller;
    }
  }

  void _enforceVideoCacheLimit() {
    if (_videoControllerCache.length > _maxVideoCacheSize) {
      final oldestUrl = _videoControllerCache.keys.first;
      final controllerToRemove = _videoControllerCache.remove(oldestUrl);
      controllerToRemove?.dispose();
    }
  }

  void clearCache() {
    for (var subject in _cache.values) {
      subject.close();
    }
    _cache.clear();

    for (var controller in _videoControllerCache.values) {
      controller.dispose();
    }
    _videoControllerCache.clear();

    notifyListeners();
  }

  void clear(String key) {
    if (_cache.containsKey(key)) {
      _cache[key]?.close();
      _cache.remove(key);
    }
    if (_videoControllerCache.containsKey(key)) {
      final controller = _videoControllerCache.remove(key);
      controller?.dispose();
    }
    notifyListeners();
  }

  void pauseAllVideos() {
    for (var controller in _videoControllerCache.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
