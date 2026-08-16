
import 'package:flutter/material.dart';

/// A reusable, theme-aware loading screen widget.
///
/// This widget displays a centered CircularProgressIndicator on a Scaffold
/// whose background color automatically adapts to the current application theme
/// (light or dark mode). It is intended to be used as a consistent placeholder
/// screen during data fetching or initialization processes, such as the initial
/// authentication state check.
class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the scaffoldBackgroundColor from the current theme to ensure
      // the loading screen's background matches the rest of the app.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
