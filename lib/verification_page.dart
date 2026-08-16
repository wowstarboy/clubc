import 'dart:async';
import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Bouncy curve for scale and slide to give it a vibrating feel
    final curve = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero).animate(curve);

    // Start the animation
    _animationController.forward();

    // Hide splash and show form after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // AnimatedSwitcher will handle the transition between the splash and the form
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showSplash
          ? _buildSplashAnimation(bgColor)
          : _buildVerificationForm(context, isDarkMode, bgColor),
    );
  }

  // This widget builds the splash screen with the animated icon
  Widget _buildSplashAnimation(Color bgColor) {
    return Scaffold(
      key: const ValueKey('splash'),
      backgroundColor: bgColor, // IMPORTANT: Matching app background color
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                // 3D Shadow effect
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                   BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 10,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Icon(Icons.verified, color: Colors.white, size: 100),
            ),
          ),
        ),
      ),
    );
  }

  // This widget builds the main verification form page
  Widget _buildVerificationForm(BuildContext context, bool isDarkMode, Color bgColor) {
    final usernameController = TextEditingController(text: '@username'); // Placeholder
    final fullNameController = TextEditingController();
    final reasonController = TextEditingController();

    return Scaffold(
      key: const ValueKey('form'),
      backgroundColor: bgColor, // IMPORTANT: Matching app background color
      appBar: AppBar(
        // IMPORTANT: iOS style back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor, // Matching app background
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative badge as requested
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Icon(Icons.verified, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apply for JamiiClub Verification',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Verified accounts have blue checkmarks next to their names to show that JamiiClub has confirmed they are the real presence of the public figures and brands they represent.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildModernTextField(controller: usernameController, label: 'Username', readOnly: true, isDarkMode: isDarkMode),
            const SizedBox(height: 20),
            _buildModernTextField(controller: fullNameController, label: 'Full Name', isDarkMode: isDarkMode),
            const SizedBox(height: 20),
            _buildModernTextField(controller: reasonController, label: 'Reason for request (e.g., public figure, brand)', maxLines: 5, isDarkMode: isDarkMode),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement submission logic
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable modern text field widget
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    int maxLines = 1,
    required bool isDarkMode,
  }) {
    final fillColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }
}
