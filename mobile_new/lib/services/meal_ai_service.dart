import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final mealAiServiceProvider = Provider((ref) => MealAiService());

class MealAiService {
  // ⚠️ NOTE: For production, store this in an environment variable or secure backend.
  // For university demo, using placeholder logic to show how it connects.
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? ""; 
  
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    if (_apiKey.isEmpty) {
       return _errorResponse('MISSING API KEY', 'Please add your GEMINI_API_KEY to the .env file.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // Upgraded to latest fast model
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, 
        ),
      );

      final imageBytes = await imageFile.readAsBytes();
      
      // improved mime type detection
      String mimeType = 'image/jpeg';
      final path = imageFile.path.toLowerCase();
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (path.endsWith('.heic')) {
        mimeType = 'image/heic';
      }

      final prompt = """
        TASK: Identify the primary object in the image with high precision.
        
        CRITICAL LOGIC:
        1. Determine if the object is FOOD/DRINK or a NON-LIVING GENERAL OBJECT.
        2. If FOOD/DRINK: 
           - Provide nutritional breakdown (calories, protein, carbs, fats).
           - Estimate portion weight.
           - Assign a health_score (1-10).
           - Provide 'ai_insight' for a student.
        3. If NON-FOOD OBJECT: 
           - Identify the item clearly.
           - Set 'is_food' to false.
           - Set calories to 0 and macros to "0g".
           - Provide 'ai_insight' about how this object relates to university life.

        JSON SCHEMA:
        {
          "is_food": boolean,
          "item": "Name of object",
          "description": "Specific details about what you see",
          "portion_estimate": "Weight/Size or 'N/A'",
          "calories": number,
          "protein": "string with g",
          "carbs": "string with g",
          "fats": "string with g",
          "health_score": number or 0,
          "ai_insight": "Contextual tip for university life",
          "proven_source": "USDA, Nutritionix, or Web Search",
          "confidence": number
        }
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await model.generateContent(content).timeout(
        const Duration(seconds: 15), // Reduced timeout for faster fallback
        onTimeout: () => throw Exception('Connection timed out'),
      );
      
      String text = response.text ?? "{}";
      print("🔍 MealAI Raw Response: $text");
      
      String cleanJson = text.trim();
      if (cleanJson.contains("```json")) {
        cleanJson = cleanJson.split("```json").last.split("```").first.trim();
      } else if (cleanJson.contains("```")) {
        cleanJson = cleanJson.split("```").last.split("```").first.trim();
      } else if (cleanJson.contains("{")) {
        final startIndex = cleanJson.indexOf("{");
        final endIndex = cleanJson.lastIndexOf("}") + 1;
        cleanJson = cleanJson.substring(startIndex, endIndex);
      }

      final decoded = json.decode(cleanJson);
      
      return {
        'is_food': decoded['is_food'] ?? true,
        'item': decoded['item'] ?? 'Unknown Item',
        'description': decoded['description'] ?? 'No description.',
        'portion_estimate': decoded['portion_estimate'] ?? 'N/A',
        'calories': decoded['calories'] ?? 0,
        'protein': decoded['protein'] ?? '0g',
        'carbs': decoded['carbs'] ?? '0g',
        'fats': decoded['fats'] ?? '0g',
        'health_score': decoded['health_score'] ?? 5,
        'ai_insight': decoded['ai_insight'] ?? 'No insight available.',
        'proven_source': decoded['proven_source'] ?? 'General Knowledge',
        'confidence': decoded['confidence'] ?? 0.5,
      };
    } catch (e) {
      print("❌ MealAI Exception Detail: $e");
      
      String errorTitle = 'Detection Failed';
      String errorMsg = e.toString();
      
      if (errorMsg.contains('api_key') || errorMsg.contains('API key') || errorMsg.contains('403') || errorMsg.contains('401')) {
        errorTitle = 'API KEY ERROR';
        errorMsg = 'The Gemini API Key is invalid or has been disabled. Please verify your key in Google AI Studio.';
      } else if (errorMsg.contains('safety')) {
        errorTitle = 'BLOCKED CONTENT';
        errorMsg = 'This image was flagged by safety filters. Try a different angle or lighting.';
      } else if (errorMsg.contains('quota') || errorMsg.contains('429')) {
        errorTitle = 'QUOTA EXCEEDED';
        errorMsg = 'You have reached the free tier limit for today. Try again later.';
      } else {
        errorMsg = 'Connection issue. Please check your internet and try again.';
      }

      return _errorResponse(errorTitle, errorMsg);
    }
  }

  Future<Map<String, dynamic>> moderateText(String text) async {
    if (_apiKey.isEmpty) {
       print("⚠️ AI Moderation Skipped: No API Key.");
       // Fail safe: If no API key, let it pass but log warning.
       return {'is_safe': true, 'reason': 'No API Key provided.'};
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.0,
        ),
      );

      final prompt = """
        TASK: STRICT CONTENT MODERATION & QUALITY CHECK
        Analyze the following text for:
        1. SAFETY: Check for sexually abusive, explicit, illegal, violent, or hate speech content.
        2. QUALITY: Check if the text is gibberish, random key-mashing (e.g. "asdfg"), or nonsensical. It must be a GENUINE task request.
        
        STRICT ZERO TOLERANCE POLICY FOR:
        - Sexual violence, harassment, or strictly adult content.
        - Illegal acts (drugs, weapons, scams, hacking).
        - Hate speech or severe profanity.
        - RANDOM/GIBBERISH text or meaningless strings (e.g. "dhjdjd", "testing 123" without context).
        
        TEXT TO ANALYZE (can be in Hindi, English, Hinglish, etc.):
        "$text"

        JSON RESPONSE SCHEMA:
        {
          "is_safe": boolean, 
          "reason": "Short explanation for user if blocked", 
          "flagged_content": "The specific words or phrases that triggered the block, or 'Gibberish'"
        }
      """;

      final content = [Content.text(prompt)];

      final response = await model.generateContent(content).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Moderation timed out'),
      );

      String cleanJson = response.text?.trim() ?? "{}";
      if (cleanJson.contains("```json")) {
        cleanJson = cleanJson.split("```json").last.split("```").first.trim();
      } else if (cleanJson.contains("```")) {
        cleanJson = cleanJson.split("```").last.split("```").first.trim();
      }

      final decoded = json.decode(cleanJson);
      return {
        'is_safe': decoded['is_safe'] ?? true, // Default to safe if unsure? Or block? Let's default true to avoid false positives blocking.
        'reason': decoded['reason'] ?? 'Content flagged by AI.',
        'flagged_content': decoded['flagged_content'] ?? '',
      };

    } catch (e) {
      print("❌ AI Moderation Error: $e");
      // Allow on error to avoid blocking users due to tech issues
      return {'is_safe': true, 'reason': 'AI Check Failed: $e'}; 
    }
  }

  Map<String, dynamic> _errorResponse(String title, String message) {
    return {
      'is_food': false,
      'item': title,
      'description': message,
      'calories': 0,
      'protein': '0g',
      'carbs': '0g',
      'fats': '0g',
      'health_score': 0,
      'ai_insight': 'Technical issue detected. ${message.contains("API") ? "Update the key in .env" : "Try again later."}',
      'proven_source': 'System Error',
      'confidence': 0.0,
    };
  }
}
