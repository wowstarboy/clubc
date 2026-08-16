
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:jamiiclub/translation/global.dart';

class LanguageBottomSheet extends StatelessWidget {
  final Function(TranslateLanguage) onLanguageSelected;

  const LanguageBottomSheet({super.key, required this.onLanguageSelected});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ListView.builder(
        itemCount: TranslationService.supportedLanguages.length,
        itemBuilder: (context, index) {
          final language = TranslationService.supportedLanguages[index];
          final languageName = TranslationService.getLanguageName(language);

          return ListTile(
            title: Text(
              languageName,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            onTap: () {
              onLanguageSelected(language);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
