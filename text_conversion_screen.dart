import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class TextConversionScreen extends StatefulWidget {
  const TextConversionScreen({super.key});

  @override
  State<TextConversionScreen> createState() => _TextConversionScreenState();
}

class _TextConversionScreenState extends State<TextConversionScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _outputText = '';

  String _sourceLang = 'en';
  String _targetLang = 'hi';

  bool _isTranslating = false;

  final Map<String, String> languages = {
    'en': 'English',
    'hi': 'Hindi',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'bn': 'Bengali',
  };

  /* ===========================
     TRANSLATION LOGIC
  =========================== */
  Future<void> translateText() async {
    if (_inputController.text.trim().isEmpty) return;

    // Close keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isTranslating = true;
      _outputText = '';
    });

    try {
      final translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.values.firstWhere(
          (e) => e.bcpCode == _sourceLang,
        ),
        targetLanguage: TranslateLanguage.values.firstWhere(
          (e) => e.bcpCode == _targetLang,
        ),
      );

      final translatedText = await translator.translateText(
        _inputController.text,
      );

      await translator.close();

      setState(() {
        _outputText = translatedText;
      });
    } catch (e) {
      setState(() {
        _outputText = 'Translation failed: $e';
      });
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  /* ===========================
     UI
  =========================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Conversion (ML Kit)'),
        backgroundColor: Color(0xFF1B8D50),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INPUT TEXT
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Enter Text',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 15),

            // LANGUAGE SELECTION
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sourceLang,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                    items: languages.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _sourceLang = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _targetLang,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                    items: languages.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _targetLang = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // TRANSLATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTranslating ? null : translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B8D50),
                ),
                icon: _isTranslating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.translate, color: Colors.white),
                label: Text(
                  _isTranslating ? ' Translating...' : 'Convert Text',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // OUTPUT
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    // Allow copying
                    _outputText.isEmpty
                        ? 'Converted text will appear here'
                        : _outputText,
                    style: TextStyle(
                      fontSize: 18,
                      color: _outputText.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
