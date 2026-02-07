import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Translation Service using Google ML Kit
/// Supports 10+ Indian languages for offline translation
class TranslationService extends ChangeNotifier {
  OnDeviceTranslator? _translator;
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.hindi;
  bool _isModelDownloaded = false;
  bool _isDownloading = false;
  String? _downloadError;

  // Supported Indian languages
  static final Map<String, TranslateLanguage> supportedLanguages = {
    'en': TranslateLanguage.english,
    'hi': TranslateLanguage.hindi,
    'bn': TranslateLanguage.bengali,
    'ta': TranslateLanguage.tamil,
    'te': TranslateLanguage.telugu,
    'mr': TranslateLanguage.marathi,
    'gu': TranslateLanguage.gujarati,
    'kn': TranslateLanguage.kannada,
    'ml': TranslateLanguage.malayalam,
    'pa': TranslateLanguage.punjabi,
    'ur': TranslateLanguage.urdu,
  };

  // Language names for UI
  static final Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'bn': 'বাংলা (Bengali)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'ur': 'اردو (Urdu)',
  };

  bool get isModelDownloaded => _isModelDownloaded;
  bool get isDownloading => _isDownloading;
  String? get downloadError => _downloadError;
  String get sourceLanguageCode => supportedLanguages.entries
      .firstWhere(
        (e) => e.value == _sourceLanguage,
        orElse: () => const MapEntry('en', TranslateLanguage.english),
      )
      .key;
  String get targetLanguageCode => supportedLanguages.entries
      .firstWhere(
        (e) => e.value == _targetLanguage,
        orElse: () => const MapEntry('hi', TranslateLanguage.hindi),
      )
      .key;

  /// Initialize translator with source and target languages
  Future<void> initialize({
    String sourceCode = 'en',
    String targetCode = 'hi',
  }) async {
    _sourceLanguage =
        supportedLanguages[sourceCode] ?? TranslateLanguage.english;
    _targetLanguage = supportedLanguages[targetCode] ?? TranslateLanguage.hindi;

    _translator?.close();
    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
    );

    await _checkAndDownloadModel();
    notifyListeners();
  }

  /// Change target language
  Future<void> setTargetLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;

    _targetLanguage = supportedLanguages[languageCode]!;
    _translator?.close();
    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
    );

    await _checkAndDownloadModel();
    notifyListeners();
  }

  /// Check if model is downloaded, download if needed
  Future<void> _checkAndDownloadModel() async {
    final modelManager = OnDeviceTranslatorModelManager();

    try {
      _isModelDownloaded = await modelManager.isModelDownloaded(
        _targetLanguage.bcpCode,
      );

      if (!_isModelDownloaded) {
        _isDownloading = true;
        _downloadError = null;
        notifyListeners();

        final success = await modelManager.downloadModel(
          _targetLanguage.bcpCode,
        );
        _isModelDownloaded = success;
        _isDownloading = false;

        if (!success) {
          _downloadError = 'Failed to download language model';
        }
        notifyListeners();
      }
    } catch (e) {
      _isDownloading = false;
      _downloadError = e.toString();
      debugPrint('Error downloading model: $e');
      notifyListeners();
    }
  }

  /// Translate text
  Future<String> translate(String text) async {
    if (_translator == null) {
      await initialize();
    }

    if (!_isModelDownloaded) {
      return text; // Return original if model not ready
    }

    try {
      return await _translator!.translateText(text);
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  /// Translate multiple texts
  Future<List<String>> translateBatch(List<String> texts) async {
    final results = <String>[];
    for (final text in texts) {
      results.add(await translate(text));
    }
    return results;
  }

  /// Get all supported language codes
  List<String> getSupportedLanguageCodes() {
    return supportedLanguages.keys.toList();
  }

  /// Get language name by code
  String getLanguageName(String code) {
    return languageNames[code] ?? code;
  }

  /// Delete a downloaded model to free space
  Future<bool> deleteModel(String languageCode) async {
    final lang = supportedLanguages[languageCode];
    if (lang == null) return false;

    final modelManager = OnDeviceTranslatorModelManager();
    try {
      return await modelManager.deleteModel(lang.bcpCode);
    } catch (e) {
      debugPrint('Error deleting model: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _translator?.close();
    super.dispose();
  }
}
