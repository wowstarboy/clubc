
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDarkMode ? const Color(0xFF0D1015) : Colors.white,
      body: Stack(
        children: [
          // Logo
          Align(
            alignment: const Alignment(0.0, -0.4),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => gradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: SvgPicture.asset(
                'assets/icons/play-circle.svg',
                width: 90,
                height:90,
              ),
            ),
          ),
          // Maandishi
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => gradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Text(
                  'JamiiClub',
                  style: GoogleFonts.lobsterTwo(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Color is overridden by ShaderMask
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
