import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart'; // Import ThemeProvider

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // --- CHANGED ICON TO IOS STYLE ---
          icon: const Icon(Icons.arrow_back_ios), 
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Menu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Account'),
          _MenuListItem(
            title: 'JamiiAi',
            icon: Icons.auto_awesome,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Profile Management',
            icon: Icons.person_outline,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Saved',
            icon: Icons.bookmark_border,
            onTap: () {},
          ),
            _MenuListItem(
            title: 'Request Verification',
            icon: Icons.verified_user_outlined,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Blocks',
            icon: Icons.block,
            onTap: () {},
          ),
         
          const Divider(),
          const _SectionHeader(title: 'Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
          const _SectionHeader(title: 'About & Support'),
          _MenuListItem(
            title: 'About',
            icon: Icons.info_outline,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Privacy',
            icon: Icons.shield_outlined,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Terms',
            icon: Icons.description_outlined,
            onTap: () {},
          ),
           _MenuListItem(
            title: 'Community Standards',
            icon: Icons.group_outlined,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Report an Issue',
            icon: Icons.flag_outlined,
            onTap: () {},
          ),
          _MenuListItem(
            title: 'Contact',
            icon: Icons.mail_outline,
            onTap: () {},
          ),
          const Divider(),
          const _SectionHeader(title: 'Login'),
          _MenuListItem(
            title: 'Log Out',
            icon: Icons.logout,
            color: Colors.red,
            onTap: () {},
          ),
          // --- CHANGED COLOR TO BLUE ---
          _MenuListItem(
            title: 'Add Account',
            icon: Icons.add_circle_outline,
            color: Colors.blue,
            onTap: () {},
          ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MenuListItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MenuListItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).iconTheme.color),
      title: Text(title, style: TextStyle(color: color, fontSize: 16)),
      onTap: onTap,
    );
  }
}
