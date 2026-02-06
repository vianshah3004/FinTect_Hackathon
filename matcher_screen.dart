import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import '../providers/language_provider.dart';
import '../models/scheme_model.dart';
import '../services/groq_service.dart';
import 'text_conversion_screen.dart';

class MatcherScreen extends StatefulWidget {
  const MatcherScreen({super.key});

  @override
  State<MatcherScreen> createState() => _MatcherScreenState();
}

class _MatcherScreenState extends State<MatcherScreen> {
  final _formKey = GlobalKey<FormState>();
  final SchemeMatcher _matcher = SchemeMatcher();

  // Data
  int? age = 25;
  String gender = "male";
  String occupation = "farmer";
  String state = "Maharashtra";
  bool ownsLand = true;
  int? income = 50000;

  bool _loading = false;
  List<Scheme> _results = [];
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _matcher.loadSchemes();
  }

  void _findSchemes() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _loading = true;
        _searched = true;
        _results = [];
      });

      await Future.delayed(Duration(milliseconds: 1000));

      final userProfile = UserProfile(
        age: age ?? 0,
        gender: gender,
        occupation: occupation,
        income: income ?? 0,
        state: state,
        ownsLand: ownsLand,
      );

      final matches = _matcher.match(userProfile);

      if (mounted) {
        setState(() {
          _loading = false;
          _results = matches;
          if (_results.isNotEmpty) {
            lang.speak(
              lang.t('found') + " ${_results.length} " + lang.t('schemes'),
            );
          } else {
            lang.speak(lang.t('no_schemes'));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFF1B8D50), // Classic Green
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: _loading
                          ? _buildLoading(lang)
                          : _searched
                          ? _buildResults(lang)
                          : _buildForm(lang),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => VoiceAssistantSheet(),
          );
        },
        backgroundColor: Colors.white,
        icon: Icon(Icons.mic, color: Color(0xFF1B8D50)),
        label: Text(
          "Assistant",
          style: TextStyle(
            color: Color(0xFF1B8D50),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: Color(0xFF1B8D50),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Gramin Seva",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.translate, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TextConversionScreen(),
                        ),
                      );
                    },
                    tooltip: "Text Tool",
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: lang.currentLang,
                        dropdownColor: Color(0xFF1B8D50),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 18,
                        ),
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (val) => lang.setLanguage(val!),
                        items: [
                          DropdownMenuItem(value: 'en', child: Text("EN")),
                          DropdownMenuItem(value: 'hi', child: Text("हिं")),
                          DropdownMenuItem(value: 'bn', child: Text("বাং")),
                          DropdownMenuItem(value: 'te', child: Text("తె")),
                          DropdownMenuItem(value: 'ta', child: Text("த")),
                          DropdownMenuItem(value: 'mr', child: Text("मरा")),
                          DropdownMenuItem(value: 'gu', child: Text("ગુ")),
                          DropdownMenuItem(value: 'kn', child: Text("ಕ")),
                          DropdownMenuItem(value: 'ur', child: Text("اردو")),
                          DropdownMenuItem(value: 'ml', child: Text("മല")),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Simple Welcome
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('welcome'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => lang.speak('welcome'),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              lang.t('listen'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.support_agent, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(LanguageProvider lang) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 50),
          CircularProgressIndicator(color: Color(0xFF1B8D50)),
          SizedBox(height: 20),
          Text(lang.t('searching')),
        ],
      ),
    );
  }

  Widget _buildForm(LanguageProvider lang) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCard(
            child: Column(
              children: [
                _buildInputRow(
                  lang,
                  'ask_age',
                  Icons.cake,
                  TextFormField(
                    initialValue: "25",
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSaved: (val) => age = int.tryParse(val ?? "25") ?? 25,
                  ),
                ),
                Divider(),
                _buildInputRow(
                  lang,
                  'ask_gender',
                  Icons.person,
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    items: ["male", "female"]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => gender = val!),
                  ),
                ),
                Divider(),
                _buildInputRow(
                  lang,
                  'ask_occ',
                  Icons.work,
                  DropdownButtonFormField<String>(
                    value: occupation,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    items: ["farmer", "student", "shopkeeper", "worker"]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => occupation = val!),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          _buildCard(
            child: Column(
              children: [
                _buildInputRow(
                  lang,
                  'ask_state',
                  Icons.location_on,
                  DropdownButtonFormField<String>(
                    value: state,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    items:
                        [
                              "Maharashtra",
                              "Gujarat",
                              "Karnataka",
                              "West Bengal",
                              "Tamil Nadu",
                              "Andhra Pradesh",
                              "Uttar Pradesh",
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => state = val!),
                  ),
                ),
                Divider(),
                _buildInputRow(
                  lang,
                  'ask_land',
                  Icons.landscape,
                  Row(
                    children: [
                      Expanded(
                        child: _toggleButton(
                          "YES",
                          ownsLand,
                          () => setState(() => ownsLand = true),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _toggleButton(
                          "NO",
                          !ownsLand,
                          () => setState(() => ownsLand = false),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                _buildInputRow(
                  lang,
                  'ask_income',
                  Icons.currency_rupee,
                  TextFormField(
                    initialValue: "50000",
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSaved: (val) => income = int.tryParse(val ?? "50000"),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _findSchemes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B8D50),
              ),
              child: Text(
                lang.t('find'),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputRow(
    LanguageProvider lang,
    String labelKey,
    IconData icon,
    Widget input,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF1B8D50), size: 18),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.t(labelKey),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              input,
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Color(0xFF1B8D50) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(LanguageProvider lang) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 50),
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            Text(lang.t('no_schemes')),
            TextButton(
              onPressed: () => setState(() => _searched = false),
              child: Text(lang.t('try_again')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1B8D50)),
            SizedBox(width: 8),
            Text(
              "${_results.length} ${lang.t('found')}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B8D50),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => setState(() => _searched = false),
            ),
          ],
        ),
        SizedBox(height: 10),
        ...List.generate(
          _results.length,
          (i) => _buildSchemeCard(_results[i], lang, i),
        ),
      ],
    );
  }

  Widget _buildSchemeCard(Scheme scheme, LanguageProvider lang, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Text(
              "${index + 1}",
              style: TextStyle(color: Color(0xFF1B8D50)),
            ),
          ),
          title: Text(
            scheme.getName(lang.currentLang),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: GestureDetector(
            onTap: () => lang.speak(scheme.getName(lang.currentLang)),
            child: Icon(Icons.volume_up, color: Color(0xFF1B8D50)),
          ),
          childrenPadding: EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                _buildDetailSection(
                  "📋 ${lang.t('description')}",
                  scheme.getDescription(lang.currentLang),
                  lang,
                ),
                SizedBox(height: 12),

                // Benefits
                _buildDetailSection(
                  "🎁 ${lang.t('benefits')}",
                  scheme.getBenefits(lang.currentLang),
                  lang,
                ),
                SizedBox(height: 12),

                // Documents Required
                _buildDetailSection(
                  "📝 ${lang.t('documents')}",
                  scheme.documents.join("\n• "),
                  lang,
                ),
                SizedBox(height: 12),

                // How to Apply
                _buildDetailSection(
                  "📝 ${lang.t('how_to_apply')}",
                  scheme.getHowToApply(lang.currentLang),
                  lang,
                ),
                SizedBox(height: 12),

                // Nearest Office
                _buildDetailSection(
                  "🏢 ${lang.t('nearest_office')}",
                  scheme.nearestOffice,
                  lang,
                ),
                SizedBox(height: 16),

                // Listen Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => lang.explainScheme(scheme),
                    icon: Icon(Icons.record_voice_over, color: Colors.white),
                    label: Text(
                      lang.t('listen'),
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B8D50),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    LanguageProvider lang,
  ) {
    return TranslateAndSpeakSection(title: title, content: content, lang: lang);
  }
}

class TranslateAndSpeakSection extends StatefulWidget {
  final String title;
  final String content;
  final LanguageProvider lang;

  const TranslateAndSpeakSection({
    required this.title,
    required this.content,
    required this.lang,
    super.key,
  });

  @override
  State<TranslateAndSpeakSection> createState() =>
      _TranslateAndSpeakSectionState();
}

class _TranslateAndSpeakSectionState extends State<TranslateAndSpeakSection> {
  String? _translatedContent;
  String _currentLang = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkTranslation();
  }

  @override
  void didUpdateWidget(TranslateAndSpeakSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkTranslation();
  }

  void _checkTranslation() {
    final newLang = widget.lang.currentLang;
    if (_currentLang != newLang || _translatedContent == null) {
      _currentLang = newLang;
      if (newLang == 'en') {
        if (mounted) setState(() => _translatedContent = widget.content);
      } else {
        // Fetch translation
        widget.lang.translateText(widget.content).then((val) {
          if (mounted) setState(() => _translatedContent = val);
        });
      }
    }
  }

  Future<void> _speak() async {
    final textToSpeak = _translatedContent ?? widget.content;
    await widget.lang.speak(textToSpeak);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B8D50),
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: _speak,
              child: Icon(Icons.volume_up, size: 16, color: Color(0xFF1B8D50)),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          _translatedContent ?? widget.content, // Show original while loading
          style: TextStyle(color: Colors.grey[800], height: 1.4),
        ),
      ],
    );
  }
}

class VoiceAssistantSheet extends StatefulWidget {
  const VoiceAssistantSheet({super.key});
  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Tap mic to speak...";
  final GroqService _groqService = GroqService();
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && status == 'notListening')
          setState(() => _isListening = false);
      },
      onError: (val) => setState(() => _text = "Error: $val"),
    );
    if (available)
      _listen();
    else
      setState(() => _text = "Voice unavailable");
  }

  void _listen() {
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (val) {
        if (mounted) {
          setState(() => _text = val.recognizedWords);
          if (val.finalResult) {
            Future.delayed(Duration(seconds: 1), () => _process(_text));
          }
        }
      },
      localeId: _getLoc(),
    );
  }

  String _getLoc() {
    final map = {'en': 'en_US', 'hi': 'hi_IN', 'ml': 'ml_IN'};
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return map[lang.currentLang] ?? 'en_US';
  }

  void _process(String q) async {
    setState(() {
      _isListening = false;
      _isThinking = true;
    });
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final resp = await _groqService.chat(
      q,
      systemPrompt: "Answer in ${lang.currentLang}. Short.",
    );
    if (mounted) {
      setState(() {
        _isThinking = false;
        _text = resp ?? "Error";
      });
      if (resp != null) lang.speak(resp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Voice Assistant",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B8D50),
            ),
          ),
          SizedBox(height: 20),
          Text(
            _text,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          if (_isThinking) CircularProgressIndicator(color: Color(0xFF1B8D50)),
          if (!_isThinking && !_isListening)
            FloatingActionButton(
              onPressed: _listen,
              backgroundColor: Color(0xFF1B8D50),
              child: Icon(Icons.mic),
            )
          else if (_isListening)
            AvatarGlow(
              animate: true,
              glowColor: Colors.red,
              duration: Duration(milliseconds: 2000),
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 30,
                child: Icon(Icons.mic, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
