 
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jamiiclub/auth/collections.dart';
import 'package:jamiiclub/providers/cache_provider.dart';
import 'package:jamiiclub/providers/scroll_provider.dart';
import 'package:jamiiclub/services/media_manager.dart';
import 'package:jamiiclub/services/post_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/login_page.dart';
import 'firebase_options.dart';
import 'translation/global.dart';

import 'home_page.dart';
import 'search_page.dart';
import 'create_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'loading_page.dart';
import 'splash_page.dart'; // 1. IMPORT SPLASH PAGE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => CacheProvider()),
        ChangeNotifierProvider(create: (context) => PostProvider()),
        ChangeNotifierProvider(create: (context) => ScrollProvider()),

      ],
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appBarTitleStyle = GoogleFonts.lobsterTwo(
      fontWeight: FontWeight.bold,
      fontSize: 28,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              titleTextStyle: appBarTitleStyle.copyWith(color: Colors.black),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontSize: 0),
              unselectedLabelStyle: TextStyle(fontSize: 0),
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D1015),
            appBarTheme: AppBarTheme(
              titleTextStyle: appBarTitleStyle.copyWith(color: Colors.white),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontSize: 0),
              unselectedLabelStyle: TextStyle(fontSize: 0),
              elevation: 0,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const AppController(), // 4. TUMIA APP CONTROLLER HAPA
        );
      },
    );
  }
}

// 2. APP CONTROLLER KUSIMAMIA SPLASH
class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Weka timer ya sekunde 3
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Onyesha Splash au nenda kwenye Auth Wrapper
    return _showSplash ? const SplashPage() : const AuthWrapper();
  }
}

// 3. AUTH WRAPPER INABeba LOGIC YAKO YA AWALI
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }
        if (snapshot.hasData) {
          return const MyHomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Attach the scroll controller to our provider
    // We use listen: false because we are in initState
    Provider.of<ScrollProvider>(context, listen: false)
        .attachScrollController(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final _mediaManager = MediaManager();


    final List<Widget> widgetOptions = <Widget>[
      HomePage(onAddPost: () => _onItemTapped(2), scrollController: _scrollController),
      const SearchPage(),
      const CreatePage(),
      const NotificationsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: widgetOptions.elementAt(_selectedIndex),
       bottomNavigationBar: Consumer<ScrollProvider>(
        builder: (context, scrollProvider, child) {
          // HII NDIO KODI MPYA (SAHIHI)
return AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  height: scrollProvider.isVisible ? 45.0 : 0,
  child: SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(), // Zuia user asiscroll
    child: child!,
  ),
);
        },
        child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 45.0,
            decoration: BoxDecoration(
             color: isDarkMode 
        ? const Color(0xFF0D1015).withOpacity(0.7) // Badilisha hapa badala ya Colors.black
        : Colors.white.withOpacity(0.7), 
           ),
            child: BottomNavigationBar(
              iconSize: 24,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: _selectedIndex == 0
                      ? SvgPicture.asset(
                          'assets/icons/house-blank.svg',
                          colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/icons/house-blank (1).svg',
                           colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        ),
                  label: '',
                ),
                BottomNavigationBarItem(
                   icon: _selectedIndex == 1
                      ? SvgPicture.asset(
                          'assets/icons/search.svg',
                          colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/icons/search (1).svg',
                           colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                          'assets/icons/create.svg',
                           colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        ),
                  label: '',
                ),
                BottomNavigationBarItem(
                   icon: _selectedIndex == 3
                      ? SvgPicture.asset(
                          'assets/icons/heart.svg',
                          colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/icons/heart (1).svg',
                           colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(_currentUserId).snapshots(),
                    builder: (context, snapshot) {
                      ImageProvider? backgroundImage;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final photoPath = userData[FirestoreCollections.profilePhotoUrl];
                        if (photoPath != null && photoPath.isNotEmpty) {
                          backgroundImage = NetworkImage(_mediaManager.getUrl(photoPath));
                        }
                      }
                      return CircleAvatar(
                        radius: 15,
                        backgroundColor: _selectedIndex == 4
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : Colors.transparent,
                        child: CircleAvatar(
                          radius: _selectedIndex == 4 ? 13 : 15,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: backgroundImage,
                           child: backgroundImage == null
                              ? SvgPicture.asset(
                                'assets/icons/user (1).svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white, 
                                  BlendMode.srcIn,
                                ),
                                height: 18,
                              )
                              : null,
                        ),
                      );
                    },
                  ),
                  label: '',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    ), 
    );
  }
}
