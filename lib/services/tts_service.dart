import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'groq_service.dart';

class TtsService with ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
  final GroqService _groqService = GroqService();

  String _currentLang = 'en';
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal() {
    _initTTS();
  }

  void _initTTS() async {
    flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
    });

    await _setLanguage(_currentLang);
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLang != langCode) {
      _currentLang = langCode;
      await _setLanguage(langCode);
    }
  }

  Future<void> _setLanguage(String langCode) async {
    final localeMap = {
      'en': 'en-US',
      'hi': 'hi-IN',
      'bn': 'bn-IN',
      'te': 'te-IN',
      'ta': 'ta-IN',
      'mr': 'mr-IN',
      'gu': 'gu-IN',
      'kn': 'kn-IN',
      'ur': 'ur-IN',
      'ml': 'ml-IN',
    };

    var lang = localeMap[langCode] ?? 'en-US';

    bool isAvailable =
        await flutterTts.isLanguageAvailable(lang) as bool? ?? false;
    if (!isAvailable) {
      // Fallback
      lang = 'en-US';
    }

    await flutterTts.setLanguage(lang);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text, {String? language}) async {
    if (language != null) {
      await setLanguage(language);
    }

    await stop(); // Stop any previous speech

    // Simple chunking for long text
    List<String> chunks = _chunkText(text);
    for (String chunk in chunks) {
      if (chunk.trim().isNotEmpty) {
        await flutterTts.speak(chunk);
        await flutterTts.awaitSpeakCompletion(true);
      }
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  List<String> _chunkText(String text) {
    if (text.length < 500) return [text];

    List<String> chunks = [];
    RegExp delimiter = RegExp(r'(?<=[.?!।])\s+|\n+');
    List<String> sentences = text.split(delimiter);

    String currentChunk = "";
    for (String sentence in sentences) {
      if ((currentChunk.length + sentence.length) > 500) {
        chunks.add(currentChunk);
        currentChunk = sentence;
      } else {
        currentChunk += " " + sentence;
      }
    }
    if (currentChunk.isNotEmpty) chunks.add(currentChunk);
    return chunks;
  }
}
