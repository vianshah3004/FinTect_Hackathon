import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/groq_service.dart';

class LanguageProvider extends ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
  final GroqService _groqService = GroqService();

  String _currentLang = 'en';
  Map<String, String> _localizedStrings = {};
  bool useOnlineVoice =
      true; // Still true conceptually for "Enhance Logic", but audio is now local

  // Complete Dictionary for UI - All 10 Languages
  final Map<String, Map<String, String>> _dictionaries = {
    'en': {
      'welcome': 'Welcome to Gramin Seva',
      'find': 'Find Schemes',
      'ask_age': 'Age',
      'ask_gender': 'Gender',
      'ask_occ': 'Occupation',
      'ask_state': 'State',
      'ask_land': 'Own Land?',
      'ask_income': 'Annual Income',
      'found': 'Schemes Found',
      'listen': 'Listen',
      'no_schemes': 'No schemes found',
      'description': 'Description',
      'benefits': 'Benefits',
      'documents': 'Documents Required',
      'how_to_apply': 'How to Apply',
      'nearest_office': 'Nearest Office',
      'based_on_profile': 'Based on your profile',
      'try_again': 'Try Again',
      'searching': 'Searching...',
    },
    'hi': {
      'welcome': 'ग्रामीण सेवा में आपका स्वागत है',
      'find': 'योजनाएं खोजें',
      'ask_age': 'उम्र',
      'ask_gender': 'लिंग',
      'ask_occ': 'व्यवसाय',
      'ask_state': 'राज्य',
      'ask_land': 'जमीन है?',
      'ask_income': 'वार्षिक आय',
      'found': 'योजनाएं मिलीं',
      'listen': 'सुनें',
      'no_schemes': 'कोई योजना नहीं मिली',
      'description': 'विवरण',
      'benefits': 'लाभ',
      'documents': 'आवश्यक दस्तावेज',
      'how_to_apply': 'आवेदन कैसे करें',
      'nearest_office': 'निकटतम कार्यालय',
      'based_on_profile': 'आपकी प्रोफ़ाइल के अनुसार',
      'try_again': 'पुनः प्रयास करें',
      'searching': 'खोज रहे हैं...',
    },
    'bn': {
      'welcome': 'গ্রামীণ সেবায় স্বাগতম',
      'find': 'প্রকল্প খুঁজুন',
      'ask_age': 'বয়স',
      'ask_gender': 'লিঙ্গ',
      'ask_occ': 'পেশা',
      'ask_state': 'রাজ্য',
      'ask_land': 'জমি আছে?',
      'ask_income': 'বার্ষিক আয়',
      'found': 'প্রকল্প পাওয়া গেছে',
      'listen': 'শুনুন',
      'no_schemes': 'কোনো প্রকল্প পাওয়া যায়নি',
      'description': 'বিবরণ',
      'benefits': 'সুবিধা',
      'documents': 'প্রয়োজনীয় নথি',
      'how_to_apply': 'আবেদন পদ্ধতি',
      'nearest_office': 'নিকটতম অফিস',
      'based_on_profile': 'আপনার প্রোফাইল অনুযায়ী',
      'try_again': 'আবার চেষ্টা করুন',
      'searching': 'খোঁজা হচ্ছে...',
    },
    'te': {
      'welcome': 'గ్రామీణ సేవకు స్వాగతం',
      'find': 'పథకాలను కనుగొనండి',
      'ask_age': 'వయస్సు',
      'ask_gender': 'లింగం',
      'ask_occ': 'వృత్తి',
      'ask_state': 'రాష్ట్రం',
      'ask_land': 'భూమి ఉందా?',
      'ask_income': 'వార్షిక ఆదాయం',
      'found': 'పథకాలు కనుగొనబడ్డాయి',
      'listen': 'వినండి',
      'no_schemes': 'పథకాలు కనుగొనబడలేదు',
      'description': 'వివరణ',
      'benefits': 'ప్రయోజనాలు',
      'documents': 'అవసరమైన పత్రాలు',
      'how_to_apply': 'దరఖాస్తు ఎలా చేయాలి',
      'nearest_office': 'సమీప కార్యాలయం',
      'based_on_profile': 'మీ ప్రొఫైల్ ఆధారంగా',
      'try_again': 'మళ్ళీ ప్రయత్నించండి',
      'searching': 'శోధిస్తోంది...',
    },
    'ta': {
      'welcome': 'கிராமப்புற சேவைக்கு வரவேற்கிறோம்',
      'find': 'திட்டங்களைக் கண்டறியுங்கள்',
      'ask_age': 'வயது',
      'ask_gender': 'பாலினம்',
      'ask_occ': 'தொழில்',
      'ask_state': 'மாநிலம்',
      'ask_land': 'நிலம் உள்ளதா?',
      'ask_income': 'ஆண்டு வருமானம்',
      'found': 'திட்டங்கள் கண்டறியப்பட்டன',
      'listen': 'கேளுங்கள்',
      'no_schemes': 'திட்டங்கள் இல்லை',
      'description': 'விளக்கம்',
      'benefits': 'பலன்கள்',
      'documents': 'தேவையான ஆவணங்கள்',
      'how_to_apply': 'விண்ணப்பிக்கும் முறை',
      'nearest_office': 'அருகிலுள்ள அலுவலகம்',
      'based_on_profile': 'உங்கள் சுயவிவரத்தின் அடிப்படையில்',
      'try_again': 'மீண்டும் முயற்சிக்கவும்',
      'searching': 'தேடுகிறது...',
    },
    'mr': {
      'welcome': 'ग्रामीण सेवा मध्ये स्वागत',
      'find': 'योजना शोधा',
      'ask_age': 'वय',
      'ask_gender': 'लिंग',
      'ask_occ': 'व्यवसाय',
      'ask_state': 'राज्य',
      'ask_land': 'जमीन आहे?',
      'ask_income': 'वार्षिक उत्पन्न',
      'found': 'योजना सापडल्या',
      'listen': 'ऐका',
      'no_schemes': 'योजना सापडल्या नाहीत',
      'description': 'वर्णन',
      'benefits': 'फायदे',
      'documents': 'आवश्यक कागदपत्रे',
      'how_to_apply': 'अर्ज कसा करावा',
      'nearest_office': 'जवळचे कार्यालय',
      'based_on_profile': 'तुमच्या प्रोफाइलनुसार',
      'try_again': 'पुन्हा प्रयत्न करा',
      'searching': 'शोधत आहे...',
    },
    'gu': {
      'welcome': 'ગ્રામીણ સેવામાં સ્વાગત છે',
      'find': 'યોજનાઓ શોધો',
      'ask_age': 'ઉંમર',
      'ask_gender': 'લિંગ',
      'ask_occ': 'વ્યવસાય',
      'ask_state': 'રાજ્ય',
      'ask_land': 'જમીન છે?',
      'ask_income': 'વાર્ષિક આવક',
      'found': 'યોજનાઓ મળી',
      'listen': 'સાંભળો',
      'no_schemes': 'કોઈ યોજના મળી નથી',
      'description': 'વર્ણન',
      'benefits': 'લાભો',
      'documents': 'જરૂરી દસ્તાવેજો',
      'how_to_apply': 'અરજી કેવી રીતે કરવી',
      'nearest_office': 'નજીકની ઓફિસ',
      'based_on_profile': 'તમારી પ્રોફાઇલ મુજબ',
      'try_again': 'ફરી પ્રયાસ કરો',
      'searching': 'શોધી રહ્યું છે...',
    },
    'kn': {
      'welcome': 'ಗ್ರಾಮೀಣ ಸೇವೆಗೆ ಸ್ವಾಗತ',
      'find': 'ಯೋಜನೆಗಳನ್ನು ಹುಡುಕಿ',
      'ask_age': 'ವಯಸ್ಸು',
      'ask_gender': 'ಲಿಂಗ',
      'ask_occ': 'ವೃತ್ತಿ',
      'ask_state': 'ರಾಜ್ಯ',
      'ask_land': 'ಭೂಮಿ ಇದೆಯೇ?',
      'ask_income': 'ವಾರ್ಷಿಕ ಆದಾಯ',
      'found': 'ಯೋಜನೆಗಳು ಕಂಡುಬಂದಿವೆ',
      'listen': 'ಕೇಳಿ',
      'no_schemes': 'ಯೋಜನೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
      'description': 'ವಿವರಣೆ',
      'benefits': 'ಪ್ರಯೋಜನಗಳು',
      'documents': 'ಅಗತ್ಯ ದಾಖಲೆಗಳು',
      'how_to_apply': 'ಅರ್ಜಿ ಹೇಗೆ ಸಲ್ಲಿಸುವುದು',
      'nearest_office': 'ಹತ್ತಿರದ ಕಚೇರಿ',
      'based_on_profile': 'ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ಆಧಾರದ ಮೇಲೆ',
      'try_again': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
      'searching': 'ಹುಡುಕುತ್ತಿದೆ...',
    },
    'ur': {
      'welcome': 'گرامین سیوا میں خوش آمدید',
      'find': 'اسکیمیں تلاش کریں',
      'ask_age': 'عمر',
      'ask_gender': 'جنس',
      'ask_occ': 'پیشہ',
      'ask_state': 'ریاست',
      'ask_land': 'زمین ہے؟',
      'ask_income': 'سالانہ آمدنی',
      'found': 'اسکیمیں ملیں',
      'listen': 'سنیں',
      'no_schemes': 'کوئی اسکیم نہیں ملی',
      'description': 'تفصیل',
      'benefits': 'فوائد',
      'documents': 'درکار دستاویزات',
      'how_to_apply': 'درخواست کیسے دیں',
      'nearest_office': 'قریبی دفتر',
      'based_on_profile': 'آپ کی پروفائل کے مطابق',
      'try_again': 'دوبارہ کوشش کریں',
      'searching': 'تلاش کر رہے ہیں...',
    },
  };

  String get currentLang => _currentLang;

  LanguageProvider() {
    _localizedStrings = _dictionaries['en']!;
    _initTTS();
  }

  void _initTTS() async {
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
    };
    var lang = localeMap[_currentLang] ?? 'en-US';

    // Check if language is available
    bool isAvailable =
        await flutterTts.isLanguageAvailable(lang) as bool? ?? false;
    if (!isAvailable) {
      debugPrint("TTS Language $lang not available, falling back to English");
      lang = 'en-US';
    }

    await flutterTts.setLanguage(lang);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.awaitSpeakCompletion(true); // Wait for completion
  }

  void setLanguage(String langCode) {
    if (_currentLang != langCode) {
      _currentLang = langCode;
      _localizedStrings = _dictionaries[langCode] ?? _dictionaries['en']!;
      _initTTS();
      notifyListeners();
    }
  }

  String t(String key) => _localizedStrings[key] ?? key;

  String _getFullLanguageName(String code) {
    final names = {
      'en': 'English',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'te': 'Telugu',
      'ta': 'Tamil',
      'mr': 'Marathi',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ur': 'Urdu',
      'ml': 'Malayalam',
    };
    return names[code] ?? 'English';
  }

  Future<void> speak(String text) async {
    // 1. Resolve Dictionary Keys
    if (_localizedStrings.containsKey(text)) {
      text = _localizedStrings[text]!;
    }

    // 2. Dynamic Translation if needed
    if (!_localizedStrings.containsValue(text) && _currentLang != 'en') {
      try {
        final translated = await _groqService.translate(
          text,
          _getFullLanguageName(_currentLang),
        );
        if (translated != null) {
          text = translated;
        }
      } catch (e) {
        debugPrint("Translation Failed: $e");
      }
    }

    // 3. Set Language
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
    await flutterTts.setLanguage(localeMap[_currentLang] ?? 'en-US');

    // 4. Chunked Speaking (Fix for long text cutoff)
    // Split by common sentence delimiters but keep meaningful blocks
    // Limit chunks to ~500 characters to be safe (Android buffer often ~4000 but safer is better)
    List<String> chunks = _chunkText(text);

    for (String chunk in chunks) {
      if (chunk.trim().isNotEmpty) {
        await flutterTts.speak(chunk);
      }
    }
  }

  List<String> _chunkText(String text) {
    List<String> chunks = [];
    // Split by full stop, question mark, exclamation, or newlines
    RegExp delimiter = RegExp(r'(?<=[.?!。])\s+|\n+');
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

  // Helper for UI text translation
  Future<String> translateText(String text) async {
    if (_currentLang == 'en') return text;

    // If we have a dictionary value (likely fallback), we can return it, but
    // for Schemes details which are dynamic, we want API.
    // Basic caching could go here but for now direct call.
    try {
      final result = await _groqService.translate(
        text,
        _getFullLanguageName(_currentLang),
      );
      return result ?? text;
    } catch (e) {
      return text;
    }
  }

  Future<void> explainScheme(dynamic scheme) async {
    final langName = _getFullLanguageName(_currentLang);

    // Use Groq for Intelligence
    final script = await _groqService.explainScheme(
      scheme.getName(_currentLang),
      scheme.getDescription(_currentLang),
      scheme.getBenefits(_currentLang),
      langName,
    );

    // Use Device TTS for Voice
    if (script != null) {
      await speak(script);
    } else {
      speak(
        "${scheme.getName(_currentLang)}. ${scheme.getDescription(_currentLang)}",
      );
    }
  }
}
