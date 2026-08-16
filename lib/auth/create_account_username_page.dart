
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jamiiclub/auth/create_account_email_page.dart';
import 'package:jamiiclub/translation/global.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class UsernameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // 1. Convert to lowercase
    text = text.toLowerCase();

    // 2. Replace spaces with underscores
    text = text.replaceAll(' ', '_');

    // 3. Filter out invalid characters (allow a-z, 0-9, _, .)
    text = text.replaceAll(RegExp(r'[^-z0-9_.]'), '');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CreateAccountUsernamePage extends StatefulWidget {
  const CreateAccountUsernamePage({super.key});

  @override
  _CreateAccountUsernamePageState createState() =>
      _CreateAccountUsernamePageState();
}

class _CreateAccountUsernamePageState extends State<CreateAccountUsernamePage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  // Translation variables
  final TranslationService _translationService = TranslationService();
  String _title = 'Choose Username';
  String _subtitle =
      'Pick a username for your new account. You can always change it later.';
  String _usernameLabel = 'Username';
  String _continueButton = 'Continue';
  String _usernameTakenError = 'Username is already taken';
  String _usernameLengthError = 'Username must be at least 3 characters';
  String _usernameCheckingError = 'Error checking username';
  String _suggestionsLabel = 'Some suggestions:';
  String _usernameInvalidEndCharError = 'Username cannot end with a period.';
  String _usernameInvalidStartCharError = 'Username cannot start with a period.';
  String _usernameInvalidCharsError =
      'Only letters, numbers, periods, and underscores are allowed.';
  String _usernameMaxLengthError = 'Username cannot be more than 20 characters.';

  // Username validation variables
  final _usernameController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  Timer? _debounce;
  bool _isLoading = false;
  bool _isUsernameAvailable = false;
  String? _usernameErrorText;
  List<String> _usernameSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
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
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
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
      'Choose Username',
      'Pick a username for your new account. You can always change it later.',
      'Username',
      'Continue',
      'Username is already taken',
      'Username must be at least 3 characters',
      'Error checking username',
      'Some suggestions:',
      'Username cannot end with a period.',
      'Username cannot start with a period.',
      'Only letters, numbers, periods, and underscores are allowed.',
      'Username cannot be more than 20 characters.'
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
        _subtitle = translatedTexts[1];
        _usernameLabel = translatedTexts[2];
        _continueButton = translatedTexts[3];
        _usernameTakenError = translatedTexts[4];
        _usernameLengthError = translatedTexts[5];
        _usernameCheckingError = translatedTexts[6];
        _suggestionsLabel = translatedTexts[7];
        _usernameInvalidEndCharError = translatedTexts[8];
        _usernameInvalidStartCharError = translatedTexts[9];
        _usernameInvalidCharsError = translatedTexts[10];
        _usernameMaxLengthError = translatedTexts[11];
      });
    }
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability();
    });
  }

  Future<bool> _isUsernameTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _generateUsernameSuggestions(String username) async {
    List<String> suggestions = [];
    for (int i = 0; i < 3; i++) {
      String newSuggestion;
      do {
        final randomSuffix = Random().nextInt(999);
        newSuggestion = '$username$randomSuffix';
      } while (await _isUsernameTaken(newSuggestion));
      suggestions.add(newSuggestion);
    }

    if (mounted) {
      setState(() {
        _usernameSuggestions = suggestions;
        _showSuggestions = true;
      });
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _isLoading = false;
        _isUsernameAvailable = false;
        _usernameErrorText = null;
        _showSuggestions = false;
        _usernameSuggestions.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _usernameErrorText = null;
      _showSuggestions = false;
    });

    try {
      if (username.startsWith('.')) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameErrorText = _usernameInvalidStartCharError;
        });
        return;
      }

      if (username.endsWith('.')) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameErrorText = _usernameInvalidEndCharError;
        });
        return;
      }

      if (RegExp(r'[^-z0-9_.]').hasMatch(username)) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameErrorText = _usernameInvalidCharsError;
        });
        return;
      }

      if (username.length < 3) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameErrorText = _usernameLengthError;
        });
        return;
      }

      if (username.length > 20) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameErrorText = _usernameMaxLengthError;
        });
        return;
      }

      final isTaken = await _isUsernameTaken(username);

      if (mounted) {
        setState(() {
          _isUsernameAvailable = !isTaken;
          if (isTaken) {
            _usernameErrorText = _usernameTakenError;
            _generateUsernameSuggestions(username);
          } else {
            _showSuggestions = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = false;
          _usernameErrorText = _usernameCheckingError;
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

  void _continueToNextStep() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CreateAccountEmailPage(
                username: _usernameController.text.trim())));
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
                  Text(_subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 16,
                      )),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    autofocus: true,
                    maxLength: 20,
                    inputFormatters: [UsernameInputFormatter()],
                    decoration: InputDecoration(
                      labelText: _usernameLabel,
                      floatingLabelStyle: const TextStyle(color: Colors.blue),
                      errorText: _usernameErrorText,
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ))
                          : _usernameController.text.isNotEmpty &&
                                  _isUsernameAvailable
                              ? const Icon(Icons.check, color: Colors.green)
                              : _usernameController.text.isNotEmpty &&
                                      !_isUsernameAvailable
                                  ? const Icon(Icons.close, color: Colors.red)
                                  : null,
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: _usernameController.text.isNotEmpty &&
                                  _isUsernameAvailable
                              ? Colors.green
                              : Colors.blue,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                  ),
                  if (_showSuggestions)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _suggestionsLabel,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _usernameSuggestions.map((suggestion) {
                              return ActionChip(
                                label: Text(suggestion),
                                labelStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                onPressed: () {
                                  _usernameController.text = suggestion;
                                  _usernameController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: _usernameController.text.length),
                                  );
                                  _checkUsernameAvailability();
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isUsernameAvailable &&
                            _usernameController.text.isNotEmpty &&
                            !_isLoading
                        ? _continueToNextStep
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                    ),
                    child: Text(_continueButton),
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
