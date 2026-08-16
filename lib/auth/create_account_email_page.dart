
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/auth/create_account_password_page.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:provider/provider.dart';

class CreateAccountEmailPage extends StatefulWidget {
  final String username;

  const CreateAccountEmailPage({super.key, required this.username});

  @override
  State<CreateAccountEmailPage> createState() => _CreateAccountEmailPageState();
}

class _CreateAccountEmailPageState extends State<CreateAccountEmailPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  final TranslationService _translationService = TranslationService();
  final _emailController = TextEditingController();
  Timer? _debounce;
  bool _isEmailValid = false;
  String? _emailErrorText;

  String _title = "What's your email?";
  String _instruction =
      'Enter your email. No one will see this on your profile.';
  String _emailLabel = 'Email Address';
  String _buttonText = 'Continue';
  String _invalidEmailError = 'Please enter a valid email address.';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
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
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _debounce?.cancel();
    Provider.of<LanguageProvider>(context, listen: false)
        .removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    _translateAllTexts(
        Provider.of<LanguageProvider>(context, listen: false).selectedLanguage);
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      "What's your email?",
      'Enter your email. No one will see this on your profile.',
      'Email Address',
      'Continue',
      'Please enter a valid email address.'
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
        _invalidEmailError = translatedTexts[4];
      });
    }
  }

  void _onEmailChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _validateEmail();
    });
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _isEmailValid = false;
        _emailErrorText = null;
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isValid = emailRegex.hasMatch(email);

    setState(() {
      _isEmailValid = isValid;
      if (!isValid) {
        _emailErrorText = _invalidEmailError;
      } else {
        _emailErrorText = null;
      }
    });
  }

  void _continueToNextStep() {
    if (_isEmailValid) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CreateAccountPasswordPage(
                  username: widget.username,
                  email: _emailController.text.trim())));
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
                    controller: _emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: _emailLabel,
                        floatingLabelStyle: const TextStyle(color: Colors.blue),
                        errorText: _emailErrorText,
                        suffixIcon: _emailController.text.isNotEmpty && _isEmailValid
                            ? const Icon(Icons.check, color: Colors.green)
                            : _emailController.text.isNotEmpty && !_isEmailValid
                                ? const Icon(Icons.close, color: Colors.red)
                                : null,
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: _emailController.text.isNotEmpty && _isEmailValid
                                ? Colors.green
                                : Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isEmailValid ? _continueToNextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.5),
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
