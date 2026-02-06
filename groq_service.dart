import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey =
      "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";
  static const String _baseUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  // --- Generic Chat ---
  Future<String?> chat(String message, {String? systemPrompt}) async {
    try {
      debugPrint("Groq Request: $_baseUrl");
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama3-8b-8192", // Fast & Good
          "messages": [
            if (systemPrompt != null)
              {"role": "system", "content": systemPrompt},
            {"role": "user", "content": message},
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'];
      } else {
        debugPrint("Groq Error: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Groq Exception: $e");
      return null;
    }
  }

  // --- Translation ---
  Future<String?> translate(String text, String targetLang) async {
    final systemPrompt =
        """
You are a professional multilingual translation engine optimized for text-to-speech.
Task: Translate the user's text to $targetLang.
Rules:
1. Keep sentences short and natural for speech.
2. Avoid symbols, emojis, or abbreviations.
3. Use commonly spoken words.
4. Maintain respectful and formal tone.
5. Do not include English words inside Indian language translations.
Output ONLY the translated text, no preamble.
""";
    return await chat(text, systemPrompt: systemPrompt);
  }

  // --- Scheme Explanation ---
  Future<String?> explainScheme(
    String schemeName,
    String description,
    String benefits,
    String lang,
  ) async {
    final systemPrompt =
        """
You are a warm, helpful government officer (Gram Sevak) in rural India. 
Explain the scheme '$schemeName' to a villager in $lang language.
Be conversational, simple, respectful. 
Mention: what it is, benefits ('$benefits'), and encourage them to apply.
Keep it under 60 words. Spoken style.
""";
    return await chat("Explain: $description", systemPrompt: systemPrompt);
  }
}
