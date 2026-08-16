import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollProvider with ChangeNotifier {
  bool _isVisible = true;
  bool get isVisible => _isVisible;

  // Method to attach the listener to a scroll controller
  void attachScrollController(ScrollController controller) {
    // Remove any existing listener first to avoid duplicates
    controller.removeListener(_scrollListener); 
    
    // Assign the new controller and add the listener
    _scrollController = controller;
    _scrollController.addListener(_scrollListener);
  }

  late ScrollController _scrollController;

  void _scrollListener() {
    // If scrolling down, hide the bars
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isVisible) {
        _isVisible = false;
        notifyListeners();
      }
    } 
    // If scrolling up, show the bars
    else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isVisible) {
        _isVisible = true;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }
}
