import 'dart:async';
import 'package:flutter/material.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> with SingleTickerProviderStateMixin {
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showSplash
          ? _buildSplashAnimation(bgColor)
          : _buildReportForm(context, isDarkMode, bgColor),
    );
  }

  Widget _buildSplashAnimation(Color bgColor) {
    const Color reportColor = Colors.yellow;

    return Scaffold(
      key: const ValueKey('splash_report'),
      backgroundColor: bgColor,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: reportColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: reportColor.withOpacity(0.4),
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
              child: const Icon(Icons.flag, color: Colors.black, size: 100), // Changed icon and color
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportForm(BuildContext context, bool isDarkMode, Color bgColor) {
    const Color reportColor = Colors.yellow;
    String? _selectedIssueType;
    final List<String> issueTypes = ['Bug/Error', 'Harassment/Bullying', 'Spam', 'Account Security', 'Other'];

    return Scaffold(
      key: const ValueKey('form_report'),
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: reportColor,
              child: Icon(Icons.flag, color: Colors.black, size: 40), // Changed icon and color
            ),
            const SizedBox(height: 16),
            const Text(
              'Submit an Issue Report',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your feedback is important to us. Please provide as much detail as possible so we can address the issue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Dropdown for issue type
            _buildDropdown(issueTypes, (value) {
              _selectedIssueType = value;
            }, isDarkMode),

            const SizedBox(height: 20),

            // Text field for details
            _buildModernTextField(controller: TextEditingController(), label: 'Detailed Description', maxLines: 8, isDarkMode: isDarkMode),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: reportColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
  // Dropdown Form Field
  Widget _buildDropdown(List<String> items, void Function(String?) onChanged, bool isDarkMode) {
    final fillColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Type of Issue',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      hint: const Text('Select an issue type'),
    );
  }

  // Reusable text field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    required bool isDarkMode,
  }) {
    final fillColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true, // Aligns label to the top for multiline fields
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
      ),
    );
  }
}
