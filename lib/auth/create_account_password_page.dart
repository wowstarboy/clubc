
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/auth/create_account_name_page.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:provider/provider.dart';

class CreateAccountPasswordPage extends StatefulWidget {
  final String username;
  final String email;

  const CreateAccountPasswordPage(
      {super.key, required this.username, required this.email});

  @override
  State<CreateAccountPasswordPage> createState() =>
      _CreateAccountPasswordPageState();
}

class _CreateAccountPasswordPageState extends State<CreateAccountPasswordPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  final TranslationService _translationService = TranslationService();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorText;
  bool _isPasswordValid = false;

  String _title = "Set a password";
  String _instruction = "Create a password with at least 6 characters.";
  String _passwordLabel = 'Password';
  String _confirmPasswordLabel = 'Confirm Password';
  String _buttonText = 'Create Account';
  String _passwordMismatchError = 'Passwords do not match';
  String _emailInUseError = 'This email address is already in use.';
  String _networkError = 'Network error. Please try again.';
  String _weakPasswordError = 'Password is too weak.';
  String _unexpectedError = 'An unexpected error occurred.';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswords);
    _confirmPasswordController.addListener(_validatePasswords);
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
    _passwordController.removeListener(_validatePasswords);
    _confirmPasswordController.removeListener(_validatePasswords);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    Provider.of<LanguageProvider>(context, listen: false)
        .removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    _translateAllTexts(
        Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  void _validatePasswords() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (password.length >= 6 &&
          confirmPassword.length >= 6 &&
          password == confirmPassword) {
        _isPasswordValid = true;
        _errorText = null;
      } else {
        _isPasswordValid = false;
        if (password.isNotEmpty &&
            confirmPassword.isNotEmpty &&
            password != confirmPassword) {
          _errorText = _passwordMismatchError;
        } else {
          _errorText = null;
        }
      }
    });
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      "Set a password",
      "Create a password with at least 6 characters.",
      'Password',
      'Confirm Password',
      'Create Account',
      'Passwords do not match',
      'This email address is already in use.',
      'Network error. Please try again.',
      'Password is too weak.',
      'An unexpected error occurred.'
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
        _passwordLabel = translatedTexts[2];
        _confirmPasswordLabel = translatedTexts[3];
        _buttonText = translatedTexts[4];
        _passwordMismatchError = translatedTexts[5];
        _emailInUseError = translatedTexts[6];
        _networkError = translatedTexts[7];
        _weakPasswordError = translatedTexts[8];
        _unexpectedError = translatedTexts[9];
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_isPasswordValid) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: _passwordController.text,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'username': widget.username,
        'displayName': widget.username,
        'email': widget.email,
        'bio': null,
        'profilePhotoUrl': null,
        'website': null,
        'followers': [],
        'following': [],
        'isVerified': false,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        final uid = userCredential.user!.uid;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => CreateAccountNamePage(uid: uid)),
            (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'email-already-in-use') {
            _errorText = _emailInUseError;
          } else if (e.code == 'weak-password') {
            _errorText = _weakPasswordError;
          } else if (e.code == 'network-request-failed') {
            _errorText = _networkError;
          } else {
            _errorText = _unexpectedError;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _unexpectedError;
        });
      }
    } finally {
      if (mounted) {
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
            top: MediaQuery.of(context).padding.top,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black),
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
                    controller: _passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: _passwordLabel,
                      floatingLabelStyle: const TextStyle(color: Colors.blue),
                      errorText: _errorText,
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _confirmPasswordLabel,
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
                    onPressed: _isPasswordValid && !_isLoading ? _createAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.5),
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
