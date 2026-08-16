
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// Extension to add the bcp47Code property back to TranslateLanguage for compatibility
extension Bcp47CodeExtension on TranslateLanguage {
  /// Returns the BCP-47 code for the given language.
  String get bcp47Code {
    switch (this) {
      case TranslateLanguage.afrikaans:
        return 'af';
      case TranslateLanguage.albanian:
        return 'sq';
      case TranslateLanguage.arabic:
        return 'ar';
      case TranslateLanguage.belarusian:
        return 'be';
      case TranslateLanguage.bengali:
        return 'bn';
      case TranslateLanguage.bulgarian:
        return 'bg';
      case TranslateLanguage.catalan:
        return 'ca';
      case TranslateLanguage.chinese:
        return 'zh';
      case TranslateLanguage.croatian:
        return 'hr';
      case TranslateLanguage.czech:
        return 'cs';
      case TranslateLanguage.danish:
        return 'da';
      case TranslateLanguage.dutch:
        return 'nl';
      case TranslateLanguage.english:
        return 'en';
      case TranslateLanguage.esperanto:
        return 'eo';
      case TranslateLanguage.estonian:
        return 'et';
      case TranslateLanguage.finnish:
        return 'fi';
      case TranslateLanguage.french:
        return 'fr';
      case TranslateLanguage.galician:
        return 'gl';
      case TranslateLanguage.georgian:
        return 'ka';
      case TranslateLanguage.german:
        return 'de';
      case TranslateLanguage.greek:
        return 'el';
      case TranslateLanguage.gujarati:
        return 'gu';
      case TranslateLanguage.haitian:
        return 'ht';
      case TranslateLanguage.hebrew:
        return 'he';
      case TranslateLanguage.hindi:
        return 'hi';
      case TranslateLanguage.hungarian:
        return 'hu';
      case TranslateLanguage.icelandic:
        return 'is';
      case TranslateLanguage.indonesian:
        return 'id';
      case TranslateLanguage.irish:
        return 'ga';
      case TranslateLanguage.italian:
        return 'it';
      case TranslateLanguage.japanese:
        return 'ja';
      case TranslateLanguage.kannada:
        return 'kn';
      case TranslateLanguage.korean:
        return 'ko';
      case TranslateLanguage.latvian:
        return 'lv';
      case TranslateLanguage.lithuanian:
        return 'lt';
      case TranslateLanguage.macedonian:
        return 'mk';
      case TranslateLanguage.malay:
        return 'ms';
      case TranslateLanguage.maltese:
        return 'mt';
      case TranslateLanguage.marathi:
        return 'mr';
      case TranslateLanguage.norwegian:
        return 'no';
      case TranslateLanguage.persian:
        return 'fa';
      case TranslateLanguage.polish:
        return 'pl';
      case TranslateLanguage.portuguese:
        return 'pt';
      case TranslateLanguage.romanian:
        return 'ro';
      case TranslateLanguage.russian:
        return 'ru';
      case TranslateLanguage.slovak:
        return 'sk';
      case TranslateLanguage.slovenian:
        return 'sl';
      case TranslateLanguage.spanish:
        return 'es';
      case TranslateLanguage.swahili:
        return 'sw';
      case TranslateLanguage.swedish:
        return 'sv';
      case TranslateLanguage.tagalog:
        return 'tl';
      case TranslateLanguage.tamil:
        return 'ta';
      case TranslateLanguage.telugu:
        return 'te';
      case TranslateLanguage.thai:
        return 'th';
      case TranslateLanguage.turkish:
        return 'tr';
      case TranslateLanguage.ukrainian:
        return 'uk';
      case TranslateLanguage.urdu:
        return 'ur';
      case TranslateLanguage.vietnamese:
        return 'vi';
      case TranslateLanguage.welsh:
        return 'cy';
    }
  }
}


// New LanguageProvider class to manage the selected language state
class LanguageProvider with ChangeNotifier {
  TranslateLanguage _selectedLanguage = TranslateLanguage.english;

  TranslateLanguage get selectedLanguage => _selectedLanguage;

  void setLanguage(TranslateLanguage language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      notifyListeners(); // Notify listeners about the change
    }
  }
}

class TranslationService {
  // A map to cache translator instances to avoid creating them repeatedly.
  final Map<String, OnDeviceTranslator> _translators = {};

  // List of popular languages supported by the app
  static final List<TranslateLanguage> supportedLanguages = [
    TranslateLanguage.english,
    TranslateLanguage.spanish,
    TranslateLanguage.french,
    TranslateLanguage.german,
    TranslateLanguage.chinese,
    TranslateLanguage.japanese,
    TranslateLanguage.korean,
    TranslateLanguage.russian,
    TranslateLanguage.portuguese,
    TranslateLanguage.italian,
    TranslateLanguage.dutch,
    TranslateLanguage.arabic,
    TranslateLanguage.hindi,
    TranslateLanguage.bengali,
    TranslateLanguage.turkish,
    TranslateLanguage.swahili,
    TranslateLanguage.indonesian,
    TranslateLanguage.vietnamese,
    TranslateLanguage.thai,
    TranslateLanguage.polish,
  ];

  // Function to get a user-friendly name for a language
  static String getLanguageName(TranslateLanguage language) {
    // A map to get user-friendly names from the TranslateLanguage enum
    final names = {
      TranslateLanguage.english: 'English',
      TranslateLanguage.spanish: 'Spanish',
      TranslateLanguage.french: 'French',
      TranslateLanguage.german: 'German',
      TranslateLanguage.chinese: 'Chinese',
      TranslateLanguage.japanese: 'Japanese',
      TranslateLanguage.korean: 'Korean',
      TranslateLanguage.russian: 'Russian',
      TranslateLanguage.portuguese: 'Portuguese',
      TranslateLanguage.italian: 'Italian',
      TranslateLanguage.dutch: 'Dutch',
      TranslateLanguage.arabic: 'Arabic',
      TranslateLanguage.hindi: 'Hindi',
      TranslateLanguage.bengali: 'Bengali',
      TranslateLanguage.turkish: 'Turkish',
      TranslateLanguage.swahili: 'Swahili',
      TranslateLanguage.indonesian: 'Indonesian',
      TranslateLanguage.vietnamese: 'Vietnamese',
      TranslateLanguage.thai: 'Thai',
      TranslateLanguage.polish: 'Polish',
    };
    // Fallback to the bcp47Code if the name is not in the map
    return names[language] ?? language.bcp47Code;
  }

  // Method to download a language model
  Future<bool> downloadModel(String languageCode) async {
    // Use the bcp47Code from the enum, which is now available
    final modelManager = OnDeviceTranslatorModelManager();
    if (await modelManager.isModelDownloaded(languageCode)) {
      log('Model for $languageCode is already available.');
      return true;
    }
    
    log('Downloading model for $languageCode...');
    try {
      await modelManager.downloadModel(languageCode);
      log('Model for $languageCode downloaded successfully.');
      return true;
    } catch (e) {
      log('Error downloading model for $languageCode: $e');
      return false;
    }
  }

  Future<String> translate({
    required String text,
    required TranslateLanguage from,
    required TranslateLanguage to,
  }) async {
    // Ensure both models are downloaded before attempting translation
    await downloadModel(from.bcp47Code);
    await downloadModel(to.bcp47Code);

    final translatorKey = '${from.bcp47Code}-${to.bcp47Code}';
    
    // Get or create the translator instance
    final translator = _translators.putIfAbsent(
      translatorKey,
      () => OnDeviceTranslator(sourceLanguage: from, targetLanguage: to),
    );

    try {
      final translatedText = await translator.translateText(text);
      return translatedText;
    } catch (e) {
      log('Error translating text: $e');
      return text; // Return original text on error
    }
  }

  // Dispose all cached translators when the service is no longer needed
  void dispose() {
    for (var translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
    log('TranslationService disposed.');
  }
}
