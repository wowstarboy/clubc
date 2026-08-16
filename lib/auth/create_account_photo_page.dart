 
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/auth/follow_suggestions_page.dart';
import 'package:provider/provider.dart';

import 'package:jamiiclub/translation/global.dart';
import '../services/media_manager.dart';

class CreateAccountPhotoPage extends StatefulWidget {
  final String uid;
  const CreateAccountPhotoPage({super.key, required this.uid});

  @override
  State<CreateAccountPhotoPage> createState() => _CreateAccountPhotoPageState();
}

class _CreateAccountPhotoPageState extends State<CreateAccountPhotoPage> with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  final TranslationService _translationService = TranslationService();
  final MediaManager _mediaManager = MediaManager();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isUploading = false;

  String _title = "Add a profile picture";
  String _instruction = "Add a photo so your friends know it's you.";
  String _buttonText = 'Upload Photo';
  String _continueText = 'Continue';
  String _skipButtonText = 'Skip for now';

  @override
  void initState() {
    super.initState();
    Provider.of<LanguageProvider>(context, listen: false).addListener(_languageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translateAllTexts(Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  @override
  void dispose() {
    _animationController.dispose();
    Provider.of<LanguageProvider>(context, listen: false).removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    _translateAllTexts(Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      "Add a profile picture",
      "Add a photo so your friends know it's you.",
      'Upload Photo',
      'Continue',
      'Skip for now',
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
        _buttonText = translatedTexts[2];
        _continueText = translatedTexts[3];
        _skipButtonText = translatedTexts[4];
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _navigateToFollowSuggestions() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FollowSuggestionsPage(uid: widget.uid),
      ),
    );
  }
  Future<void> _handleUpload() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Jaribu ku-compress na ku-upload
      String? fileName = await _mediaManager.uploadMedia(_imageFile!, isVideo: false);

      if (fileName != null) {
        // 2. Kama picha imefika S3, update Firestore
        try {
          await _firestore.collection('users').doc(widget.uid).update({
            'profilePhotoUrl': fileName,
          });
          
          if (mounted) _navigateToFollowSuggestions();
        } catch (firestoreError) {
          _showErrorSnackBar("Firestore Error: Hakuna ruhusa ya ku-update user profile.");
          print("Firestore Error: $firestoreError");
        }
      } else {
        // Kama MediaManager imerudisha null
        _showErrorSnackBar("S3 Upload Failed: Angalia AWS CORS au Bucket Policy.");
      }
    } catch (e) {
      // Hapa tunakamata makosa yasiyotarajiwa
      _showErrorSnackBar("Kosa lisilojulikana: ${e.toString()}");
      print("General Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Helper function ya kuonyesha Error
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: "Sawa", textColor: Colors.white, onPressed: () {}),
      ),
    );
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
              onPressed: _navigateToFollowSuggestions,
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
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                            child: _imageFile == null
                                ? Icon(Icons.person, size: 80, color: isDarkMode ? Colors.grey[600] : Colors.grey[400])
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _isUploading ? null : (_imageFile == null ? _pickImage : _handleUpload),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isUploading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                            : Text(_imageFile == null ? _buttonText : _continueText),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _navigateToFollowSuggestions,
                        child: Text(
                          _skipButtonText,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
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
