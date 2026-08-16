
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import 'package:jamiiclub/translation/global.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TranslationService _translationService = TranslationService();

  String _title = 'Find Account';
  String _instruction = 'Enter the email associated with your account.';
  String _emailLabel = 'Email Address';
  String _buttonText = 'Continue';

  @override
  void initState() {
    super.initState();
    // Listen for language changes
    Provider.of<LanguageProvider>(context, listen: false)
        .addListener(_languageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial translation
    _translateAllTexts(
        Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  void _languageChanged() {
    _translateAllTexts(
        Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      'Find Account',
      'Enter the email associated with your account.',
      'Email Address',
      'Continue',
    ];

    final List<String> translatedTexts = [];
    for (String text in originalTexts) {
      final translatedText = await _translationService.translate(
        text: text,
        from: TranslateLanguage.english,
        to: targetLanguage,
      );
      translatedTexts.add(translatedText);
    }

    if (mounted) {
      setState(() {
        _title = translatedTexts[0];
        _instruction = translatedTexts[1];
        _emailLabel = translatedTexts[2];
        _buttonText = translatedTexts[3];
      });
    }
  }

  @override
  void dispose() {
    // Clean up the listener
    Provider.of<LanguageProvider>(context, listen: false)
        .removeListener(_languageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isDarkMode ? const Color(0xFF181818) : Colors.white,
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _instruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _emailLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(_buttonText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.grey.withOpacity(0.05),
      fontSize: 80,
      fontWeight: FontWeight.bold,
      fontFamily: 'LobsterTwo',
    );

    final textSpan = TextSpan(
      text: 'JamiiClub',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (double y = -100; y < size.height + 100; y += 150) {
      for (double x = -100; x < size.width + 100; x += 300) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(pi / 4);
        textPainter.layout();
        textPainter.paint(canvas, const Offset(0, 0));
        canvas.restore();

        canvas.save();
        canvas.translate(x + 150, y + 75);
        canvas.rotate(-pi / 6);
        textPainter.layout();
        textPainter.paint(canvas, const Offset(0, 0));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
