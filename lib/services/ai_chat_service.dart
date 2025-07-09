import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AiChatService {
  // TODO: Replace with your actual OpenAI API key in production
  // For production, use environment variables or secure configuration
  static const String _apiKey = 'your-openai-api-key-here';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<String> sendMessage(String message, List<Map<String, String>> chatHistory) async {
    try {
      // Check if API key is configured
      if (_apiKey == 'your-openai-api-key-here') {
        return _getConfigurationMessage();
      }
      
      // Add typing simulation delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Prepare enhanced system prompt
      final systemPrompt = _buildSystemPrompt();
      
      // Prepare the messages for the API
      List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': systemPrompt
        },
        ...chatHistory,
        {
          'role': 'user',
          'content': message,
        }
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': 800,
          'temperature': 0.7,
          'top_p': 1.0,
          'frequency_penalty': 0.2,
          'presence_penalty': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'].toString().trim();
        
        // Post-process the response for better formatting
        aiResponse = _postProcessResponse(aiResponse);
        
        return aiResponse;
      } else if (response.statusCode == 429) {
        return _getRateLimitMessage();
      } else if (response.statusCode == 401) {
        return _getAuthErrorMessage();
      } else {
        print('OpenAI API Error: ${response.statusCode} - ${response.body}');
        return _getGenericErrorMessage();
      }
    } catch (e) {
      print('Error sending message to OpenAI: $e');
      return _getNetworkErrorMessage();
    }
  }

  static String _getConfigurationMessage() {
    return '''🔧 Configuration Required

The AI chat feature requires an OpenAI API key to function.

To enable this feature:
1. Get an API key from OpenAI
2. Configure it in the app settings
3. Restart the application

For now, you can use the regular chat features with healthcare providers.''';
  }

  static String _buildSystemPrompt() {
    return '''You are Dr. AI, a professional healthcare assistant integrated into HomeCare Plus, a comprehensive healthcare application. You are designed to provide evidence-based health information and guidance.

**Your Core Capabilities:**
• 🩺 Medical Information: Provide accurate, evidence-based health information
• 💊 Medication Guidance: Help understand medications, dosages, and interactions
• 🏥 Healthcare Navigation: Guide users through healthcare processes
• 📅 Appointment Assistance: Help with booking and managing appointments
• 🚨 Emergency Guidance: Provide appropriate emergency response information
• 💪 Wellness Coaching: Offer lifestyle and wellness recommendations
• 🧠 Mental Health Support: Provide empathetic mental health guidance

**Your Professional Standards:**
• Always prioritize patient safety and well-being
• Provide clear, actionable, and evidence-based advice
• Use professional medical terminology when appropriate, but explain complex terms
• Be empathetic and supportive, especially for sensitive topics
• Maintain confidentiality and respect patient privacy
• Encourage regular check-ups and professional medical care

**Important Limitations:**
• You cannot diagnose medical conditions - always recommend professional consultation
• You cannot prescribe medications or provide specific treatment plans
• For emergencies, always direct users to call emergency services immediately
• You cannot replace professional medical care or second opinions

**Communication Style:**
• Professional yet approachable and warm
• Use clear, structured responses with bullet points when helpful
• Include relevant emojis sparingly for better readability
• Ask follow-up questions to better understand patient needs
• Provide actionable next steps when appropriate

**Safety Protocols:**
• For any serious symptoms, immediately recommend professional care
• For mental health crises, provide crisis resources and encourage immediate help
• For medication questions, always recommend consulting with pharmacists/doctors
• For emergency situations, prioritize immediate action over detailed explanations

Remember: You are a helpful healthcare companion, not a replacement for professional medical care. Always encourage users to consult with qualified healthcare providers for serious medical concerns.''';
  }

  static String _postProcessResponse(String response) {
    // Format the response for better readability
    response = response.replaceAll('**', '');
    response = response.replaceAll('*', '•');
    
    // Ensure proper spacing
    response = response.replaceAll('\n\n', '\n');
    response = response.replaceAll('\n•', '\n\n•');
    
    return response.trim();
  }

  static String _getRateLimitMessage() {
    final messages = [
      "I'm currently experiencing high demand. Please try again in a few moments.",
      "Too many requests right now. Give me a moment to catch up, then try again.",
      "I'm busy helping other patients. Please try again shortly.",
    ];
    return messages[Random().nextInt(messages.length)];
  }

  static String _getAuthErrorMessage() {
    return "I'm experiencing authentication issues. Please contact support if this persists.";
  }

  static String _getGenericErrorMessage() {
    final messages = [
      "I'm experiencing technical difficulties. Please try again in a moment.",
      "Something went wrong on my end. Let me try to reconnect...",
      "I'm having trouble processing your request. Please try again shortly.",
    ];
    return messages[Random().nextInt(messages.length)];
  }

  static String _getNetworkErrorMessage() {
    return "I'm having trouble connecting to my servers. Please check your internet connection and try again.";
  }

  // Message de bienvenue court et efficace - VERSION COURTE
  static String getWelcomeMessage() {
    return '''Hello! I'm Dr. AI, your health assistant.

I can help with health questions, medications, appointments, and wellness tips.

How can I help you today?''';
  }

  // Enhanced quick responses with better categorization
  static List<String> getQuickResponses() {
    return [
      '💊 Tell me about my medications',
      '📅 How do I book an appointment?',
      '🤒 I\'m feeling unwell, what should I do?',
      '🏥 Find a nearby hospital',
      '💤 Tips for better sleep',
      '🧠 I need mental health support',
      '🚨 This is an emergency',
      '💪 Healthy lifestyle advice',
      '🩺 Understanding my symptoms',
      '📋 Preparing for a doctor visit',
    ];
  }

  // Get contextual responses based on user input
  static List<String> getContextualSuggestions(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('pain') || lowerMessage.contains('hurt')) {
      return [
        '🩺 Describe your pain level (1-10)',
        '⏰ When did the pain start?',
        '📍 Where exactly does it hurt?',
        '💊 What have you tried for relief?',
      ];
    }
    
    if (lowerMessage.contains('medication') || lowerMessage.contains('medicine')) {
      return [
        '💊 What medication are you taking?',
        '⚠️ Are you experiencing side effects?',
        '🕐 When do you take your medication?',
        '❓ Questions about dosage?',
      ];
    }
    
    if (lowerMessage.contains('appointment') || lowerMessage.contains('book')) {
      return [
        '📅 What type of appointment?',
        '🏥 Preferred hospital or clinic?',
        '⏰ When would you like to schedule?',
        '📋 Any specific requirements?',
      ];
    }
    
    if (lowerMessage.contains('emergency') || lowerMessage.contains('urgent')) {
      return [
        '🚨 Call emergency services immediately',
        '🏥 Go to the nearest hospital',
        '📞 Contact your doctor now',
        '⚠️ This requires immediate attention',
      ];
    }
    
    if (lowerMessage.contains('mental') || lowerMessage.contains('stress') || lowerMessage.contains('anxiety')) {
      return [
        '🧠 How are you feeling mentally?',
        '💭 What\'s causing you stress?',
        '🤝 Would you like to talk about it?',
        '📞 Crisis support resources',
      ];
    }
    
    // Default general suggestions
    return [
      '💊 Ask about medications',
      '🏥 Find healthcare providers',
      '📅 Schedule an appointment',
      '🩺 Health information',
      '🧠 Mental health support',
      '🚨 Emergency guidance',
    ];
  }

  // Get emergency response based on urgency
  static String getEmergencyResponse(String message) {
    final urgentKeywords = ['emergency', 'urgent', 'chest pain', 'can\'t breathe', 'bleeding', 'suicide'];
    final lowerMessage = message.toLowerCase();
    
    for (String keyword in urgentKeywords) {
      if (lowerMessage.contains(keyword)) {
        return '''🚨 EMERGENCY ALERT 🚨

This sounds like a medical emergency. Please:

1. 📞 Call emergency services immediately (911, 999, or your local emergency number)
2. 🏥 Go to the nearest emergency room
3. 📱 Contact someone to be with you
4. 💊 If you have prescribed emergency medication, take it as directed

DO NOT wait for a response from me. Seek immediate professional medical help.

If you're having thoughts of self-harm, please contact:
• Crisis Text Line: Text HOME to 741741
• National Suicide Prevention Lifeline: 988
• Emergency Services: 911

Your life is valuable and help is available. Please reach out to emergency services now.''';
      }
    }
    
    return '';
  }

  // Professional disclaimer
  static String getDisclaimerMessage() {
    return '''⚠️ Important Disclaimer:

I am an AI assistant designed to provide general health information and support. I am not a substitute for professional medical advice, diagnosis, or treatment.

• Always consult with qualified healthcare providers for medical concerns
• In emergencies, call your local emergency services immediately
• For serious symptoms, seek professional medical care
• Never delay or disregard professional medical advice based on AI responses

This service is provided for informational purposes only and should not be relied upon as medical advice.''';
  }
} 