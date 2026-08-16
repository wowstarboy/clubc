
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jamiiclub/auth/create_account_username_page.dart';
import 'package:jamiiclub/auth/language_bottom_sheet.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password_page.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  // Existing variables
  final TranslationService _translationService = TranslationService();
  TranslateLanguage _selectedLanguage = TranslateLanguage.english;
  String _usernameLabel = 'Username or Email';
  String _passwordLabel = 'Password';
  String _loginButton = 'Login';
  String _forgotPasswordButton = 'Forgot Password?';
  String _dontHaveAccount = "Don't have an account?";
  String _createAccountButton = 'Create new account';

  // Added for login functionality
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _animationController.dispose();
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // New login function
  Future<void> _performLogin() async {
    if (_emailOrUsernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Please provide both username/email and password.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String email;
      final input = _emailOrUsernameController.text.trim();
      final password = _passwordController.text.trim();

      if (input.contains('@')) {
        email = input; // Input is an email
      } else {
        // Input is a username, query Firestore for the email
        final userQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          email = userQuery.docs.first.data()['email'];
        } else {
          throw FirebaseAuthException(code: 'user-not-found');
        }
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // The StreamBuilder in main.dart will handle navigation automatically.
      // No need for Navigator.push here anymore.

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'Invalid username, email, or password.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Invalid username, email, or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email format is invalid.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog("An unexpected error occurred. Please check your connection.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Existing functions (Untouched) ---
  @override
  void initState() {
    super.initState();
  }

  Future<void> _translateAllTexts(TranslateLanguage targetLanguage) async {
    final List<String> originalTexts = [
      'Username or Email',
      'Password',
      'Login',
      'Forgot Password?',
      "Don't have an account?",
      'Create new account',
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
        _usernameLabel = translatedTexts[0];
        _passwordLabel = translatedTexts[1];
        _loginButton = translatedTexts[2];
        _forgotPasswordButton = translatedTexts[3];
        _dontHaveAccount = translatedTexts[4];
        _createAccountButton = translatedTexts[5];
        });
    }
  }

  void _onLanguageSelected(TranslateLanguage language) {
    context.read<LanguageProvider>().setLanguage(language);
    
    setState(() {
      _selectedLanguage = language;
    });
    _translateAllTexts(language);
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return LanguageBottomSheet(onLanguageSelected: _onLanguageSelected);
      },
    );
  }
  // --- End of untouched functions ---

 @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Define gradient here to be reused
    const gradient = LinearGradient(
      colors: [
        Color(0xFF1565C0), // Colors.blue.shade900
        Color(0xFF42A5F5), // Colors.blue.shade400
        Color(0xFF18FFFF), // Colors.cyanAccent
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- MABADILIKO YAPO HAPA ---
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => gradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      'JamiiClub', // This will not be translated
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LobsterTwo',
                        // Rangi hii inahitajika lakini itafunikwa na ShaderMask
                        color: Colors.white, 
                      ),
                    ),
                  ),
                  // --- MWISHO WA MABADILIKO ---
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailOrUsernameController, // Using the new controller
                    decoration: InputDecoration(
                      labelText: _usernameLabel,
                      border: InputBorder.none,
                      floatingLabelStyle: const TextStyle(color: Colors.blue),
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
                    keyboardType: TextInputType.text, // General text input
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController, // Using the new controller
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _passwordLabel,
                      border: InputBorder.none,
                      floatingLabelStyle: const TextStyle(color: Colors.blue),
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
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performLogin, // Using the new login function
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
                        : Text(_loginButton),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    child: Text(_forgotPasswordButton),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _dontHaveAccount,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateAccountUsernamePage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blue, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      _createAccountButton,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 40), // Nafasi
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => gradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/play-circle.svg',
                      height: 50,
                      width: 50,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
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
      fontFamily: 'LobsterTwo'
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
