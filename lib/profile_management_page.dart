import 'dart:async';
import 'package:flutter/material.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> with SingleTickerProviderStateMixin {
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

    final curve = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero).animate(curve);

    _animationController.forward();

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
    const Color pageColor = Colors.green;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showSplash
          ? _buildSplashAnimation(bgColor, pageColor)
          : _buildManagementForm(context, isDarkMode, bgColor, pageColor),
    );
  }

  Widget _buildSplashAnimation(Color bgColor, Color pageColor) {
    return Scaffold(
      key: const ValueKey('splash_manage'),
      backgroundColor: bgColor,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: pageColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pageColor.withOpacity(0.4),
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
              child: const Icon(Icons.manage_accounts, color: Colors.white, size: 100),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManagementForm(BuildContext context, bool isDarkMode, Color bgColor, Color pageColor) {
    return Scaffold(
      key: const ValueKey('form_manage'),
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile Management', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
             CircleAvatar(
              radius: 30,
              backgroundColor: pageColor,
              child: const Icon(Icons.manage_accounts, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            
            // Security Section
            _buildSectionHeader('Security Settings'),
            const SizedBox(height: 10),
            _buildInfoTile(isDarkMode, 'user.email@google.com', 'Google Account', 'assets/icons/google.svg'),
            const SizedBox(height: 10),
            _buildActionTile(isDarkMode, 'Add Phone Number', 'Add a fallback login method', Icons.phone_android, () {}),
            
            const SizedBox(height: 30),

            // Danger Zone Section
            _buildSectionHeader('Danger Zone'),
            const SizedBox(height: 10),
            _buildActionTile(isDarkMode, 'Disable Account', 'Temporarily hide your profile', Icons.visibility_off, () {}, color: Colors.orange),
            const SizedBox(height: 10),
            _buildActionTile(isDarkMode, 'Delete Account', 'Permanently delete your account', Icons.delete_forever, () {}, color: Colors.red),

          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoTile(bool isDarkMode, String title, String subtitle, String iconPath) {
    final tileColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.2);

    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, spreadRadius: 1)],
      ),
      child: ListTile(
        leading: Image.asset(iconPath, width: 24, height: 24), // Using Image.asset for SVG
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        enabled: false, // Makes it non-interactive
      ),
    );
  }

  Widget _buildActionTile(bool isDarkMode, String title, String subtitle, IconData icon, VoidCallback onTap, {Color? color}) {
    final tileColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.2);
    final iconColor = color ?? (isDarkMode ? Colors.white : Colors.black);

    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(15),
         boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, spreadRadius: 1)],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
