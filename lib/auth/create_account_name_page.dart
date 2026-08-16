 import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:provider/provider.dart';

// Hakikisha unaimport page ya picha hapa
import 'create_account_photo_page.dart'; 

class CreateAccountNamePage extends StatefulWidget {
  final String uid;
  const CreateAccountNamePage({super.key, required this.uid});

  @override
  State<CreateAccountNamePage> createState() => _CreateAccountNamePageState();
}

class _CreateAccountNamePageState extends State<CreateAccountNamePage> with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  final TranslationService _translationService = TranslationService();
  final _nameController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  String _title = "What's your name?";
  String _instruction = "Add your full name so your friends can find you.";
  String _nameLabel = 'Full Name';
  String _buttonText = 'Save';
  String _skipButtonText = 'Skip';

  @override
  void initState() {
    super.initState();
    Provider.of<LanguageProvider>(context, listen: false)
        .addListener(_languageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translateAllTexts(
        Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  @override
  void dispose() {
    _animationController.dispose();
    Provider.of<LanguageProvider>(context, listen: false)
        .removeListener(_languageChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _languageChanged() {
    _translateAllTexts(
        Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      "What's your name?",
      "Add your full name so your friends can find you.",
      'Full Name',
      'Save',
      'Skip',
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
        _nameLabel = translatedTexts[2];
        _buttonText = translatedTexts[3];
        _skipButtonText = translatedTexts[4];
      });
    }
  }

  void _skipToPhotoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccountPhotoPage(uid: widget.uid),
      ),
    );
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .update({'displayName': _nameController.text.trim()});
      
      if(mounted){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAccountPhotoPage(uid: widget.uid),
          ),
        );
      }
    } catch (e) {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  color: isDarkMode ? const Color(0xFF181818) : Colors.white,
                  child: CustomPaint(
                    painter: BackgroundPainter(animation: _animationController),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            right: 15,
            child: TextButton(
              onPressed: _skipToPhotoPage,
              child: Text(
                _skipButtonText,
                style: const TextStyle(color: Colors.blue, fontSize: 16),
              ),
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
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LobsterTwo',
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _instruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: _nameLabel,
                      floatingLabelStyle: const TextStyle(color: Colors.blue),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) 
                        : Text(_buttonText),
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
  final Animation<double> animation;

  BackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
        color: Colors.grey.withOpacity(0.1),
        fontSize: 80,
        fontWeight: FontWeight.bold,
        fontFamily: 'LobsterTwo');

    final textSpan = TextSpan(
      text: 'JamiiClub',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final offset = animation.value * 300;

    for (double y = -100; y < size.height + 100; y += 150) {
      for (double x = -300; x < size.width + 300; x += 300) {
        canvas.save();
        canvas.translate(x + offset, y);
        canvas.rotate(pi / 4);
        textPainter.layout();
        textPainter.paint(canvas, const Offset(0, 0));
        canvas.restore();

        canvas.save();
        canvas.translate(x + 150 - offset, y + 75);
        canvas.rotate(-pi / 6);
        textPainter.layout();
        textPainter.paint(canvas, const Offset(0, 0));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
