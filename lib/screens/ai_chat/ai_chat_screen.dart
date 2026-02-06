import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../services/openai_service.dart';
import '../../services/offline_ai_brain.dart';

/// AI Chat Screen - Sathi AI Financial Assistant with Voice
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final OpenAIService _openAIService = OpenAIService();
  
  // Voice features
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isOnline = true;
  bool _speechEnabled = false;
  bool _ttsEnabled = true;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _addWelcomeMessage();
  }

  Future<void> _initializeServices() async {
    // Initialize speech to text
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        debugPrint('Speech error: $error');
      },
    );
    
    // Initialize TTS
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = !connectivity.contains(ConnectivityResult.none);
    });
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOnline = !results.contains(ConnectivityResult.none);
        });
      }
    });
    
    _isInitialized = true;
  }
  
  // ... (keep _addWelcomeMessage, get it from context if needed or just minimal changes)

  // ... (keep dispose, _startListening, _stopListening, _speak)

  /// Send message and get response
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    final language = isHindi ? 'hi' : 'en';

    // Add user message
    setState(() {
      _messages.add({
        'isUser': true,
        'message': message,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Get AI response
    String response;
    
    if (_isOnline) {
      // Use OpenAI API with history
      // Convert UI messages to OpenAI format history
      final history = _messages
          .where((m) => m['isUser'] != null) // Simple check
          .map<Map<String, dynamic>>((m) => {
                'role': m['isUser'] ? 'user' : 'assistant',
                'content': m['message'],
              })
          .toList();
          
      // Remove the last user message we just added from history to avoid duplication if service handles it, 
      // but here we are sending history + new message.
      // Actually OpenAIService.getResponse takes history separately. 
      // Let's pass previous messages as history.
      final previousHistory = history.sublist(0, history.length - 1);
          
      response = await _openAIService.getResponse(message, history: previousHistory);
    } else {
      // Use comprehensive offline AI brain
      await Future.delayed(const Duration(milliseconds: 800));
      response = OfflineAiBrain.getResponse(
        message: message,
        language: language,
        userOccupation: userProvider.user?.occupation,
      );
    }

    if (mounted) {
      setState(() {
        _messages.add({
          'isUser': false,
          'message': response,
          'time': DateTime.now(),
        });
        _isLoading = false;
      });

      _scrollToBottom();
      
      // Speak the response
      _speak(response);
      
      // Award XP for using AI
      userProvider.addXP(5);
    }
  }

  void _addWelcomeMessage() {
    final userProvider = context.read<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    final userName = userProvider.user?.name ?? 'Friend';

    _messages.add({
      'isUser': false,
      'message': isHindi
          ? '🐻 नमस्ते $userName!\n\nमैं साथी हूं, आपका वित्तीय मित्र।\n\n🎤 बोलें या लिखें, मैं सुन रहा हूं!\n\nमैं मदद कर सकता हूं:\n• 💰 बचत योजना\n• 🏛️ सरकारी योजनाएं\n• 📚 पैसों की जानकारी\n• 💼 व्यापार सुझाव\n\n${_isOnline ? "🟢 Online" : "📴 Offline Mode"}'
          : '🐻 Hello $userName!\n\nI\'m Sathi, your financial friend.\n\n🎤 Speak or type, I\'m listening!\n\nI can help with:\n• 💰 Savings plans\n• 🏛️ Government schemes\n• 📚 Money knowledge\n• 💼 Business ideas\n\n${_isOnline ? "🟢 Online" : "📴 Offline Mode"}',
      'time': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  /// Start voice input
  Future<void> _startListening() async {
    if (!_speechEnabled) {
      _showSnackBar('Voice input not available');
      return;
    }
    
    final userProvider = context.read<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    
    setState(() {
      _isListening = true;
      _lastWords = '';
    });
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          _messageController.text = _lastWords;
        });
        
        if (result.finalResult && _lastWords.isNotEmpty) {
          _stopListening();
          _sendMessage();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: isHindi ? 'hi_IN' : 'en_IN',
    );
  }

  /// Stop voice input
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  /// Speak response using TTS
  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    
    final userProvider = context.read<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    
    await _tts.setLanguage(isHindi ? 'hi-IN' : 'en-IN');
    
    // Clean text for TTS (remove emojis and markdown)
    final cleanText = text
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F।,.!?₹%\-:;\n]'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'\n+'), '. ');
    
    await _tts.speak(cleanText);
  }



  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isHindi = userProvider.language == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🐻', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sathi AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOnline 
                            ? (isHindi ? 'ऑनलाइन' : 'Online')
                            : (isHindi ? 'ऑफलाइन' : 'Offline'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // TTS toggle
          IconButton(
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (!_ttsEnabled) _tts.stop();
            },
          ),
          // Clear chat
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline mode banner
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHindi 
                          ? 'ऑफलाइन मोड - मैं फिर भी आपकी मदद कर सकता हूं!' 
                          : 'Offline mode - I can still help you!',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _TypingIndicator();
                }
                return _MessageBubble(
                  message: _messages[index]['message'],
                  isUser: _messages[index]['isUser'],
                  time: _messages[index]['time'],
                  onSpeak: () => _speak(_messages[index]['message']),
                );
              },
            ),
          ),

          // Quick suggestions
          if (_messages.length <= 2)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickSuggestion(
                    text: isHindi ? '💰 बचत कैसे करें?' : '💰 How to save?',
                    onTap: () {
                      _messageController.text = isHindi 
                          ? 'मुझे बचत करना सिखाओ'
                          : 'Teach me how to save money';
                      _sendMessage();
                    },
                  ),
                  _QuickSuggestion(
                    text: isHindi ? '🏛️ योजनाएं' : '🏛️ Schemes',
                    onTap: () {
                      _messageController.text = isHindi 
                          ? 'मेरे लिए कौन सी सरकारी योजनाएं हैं?'
                          : 'What government schemes are for me?';
                      _sendMessage();
                    },
                  ),
                  _QuickSuggestion(
                    text: isHindi ? '💳 लोन' : '💳 Loan',
                    onTap: () {
                      _messageController.text = isHindi 
                          ? 'मुझे लोन की जानकारी चाहिए'
                          : 'I need loan information';
                      _sendMessage();
                    },
                  ),
                  _QuickSuggestion(
                    text: isHindi ? '🏪 व्यापार' : '🏪 Business',
                    onTap: () {
                      _messageController.text = isHindi 
                          ? 'कम पैसों में कौन सा व्यापार करूं?'
                          : 'What business can I start with low investment?';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice button
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? Colors.red.shade100 
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: _isListening 
                          ? Border.all(color: Colors.red, width: 2)
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isListening 
                          ? (isHindi ? 'सुन रहा हूं...' : 'Listening...')
                          : (isHindi ? 'बोलें या लिखें...' : 'Speak or type...'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Send button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime time;
  final VoidCallback? onSpeak;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.time,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🐻', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: !isUser ? onSpeak : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: isUser ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 4),
                        Text(
                          '🔊 Long press to hear',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
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

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🐻', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(delay: 0),
                  const SizedBox(width: 4),
                  _Dot(delay: 150),
                  const SizedBox(width: 4),
                  _Dot(delay: 300),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3 + _animation.value * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickSuggestion({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
