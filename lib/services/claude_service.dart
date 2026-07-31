import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/medication.dart';
import '../models/watch_reading.dart';
import 'hive_service.dart';

class ClaudeService {
  final HiveService _hiveService = HiveService();
  static const String _apiKeySettingName = 'anthropic_api_key';

  // Get configured API Key
  String? getApiKey() {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    final key = box.get(_apiKeySettingName);
    if (key != null && key.toString().trim().isNotEmpty) {
      return key.toString().trim();
    }
    return null;
  }

  // Save API Key
  Future<void> saveApiKey(String apiKey) async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    await box.put(_apiKeySettingName, apiKey.trim());
  }

  // Clear API Key
  Future<void> clearApiKey() async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    await box.delete(_apiKeySettingName);
  }

  // Build System Prompt with complete medical context
  String buildSystemPrompt({
    required UserProfile profile,
    required List<Medication> activeMedications,
    WatchReading? currentVitals,
  }) {
    final activeMedsList = activeMedications.map((m) => '${m.drugName} (${m.dosage}, ${m.frequency})').join(', ');
    final allergies = [...profile.drugAllergies, ...profile.foodAllergies].join(', ');
    final conditions = profile.conditions.join(', ');

    return '''
You are MediCore AI, an advanced medical AI assistant created to assist patients with evidence-based health information and guidance.

PATIENT MEDICAL CONFLICT & SAFETY DATA:
- Gender: ${profile.gender}
- Blood Type: ${profile.bloodType}
- Weight / Height / BMI: ${profile.weightKg} kg, ${profile.heightCm} cm (BMI: ${profile.bmi.toStringAsFixed(1)})
- Known Conditions: ${conditions.isEmpty ? 'None reported' : conditions}
- Known Allergies: ${allergies.isEmpty ? 'None reported' : allergies}
- Active Medications: ${activeMedsList.isEmpty ? 'None currently' : activeMedsList}
${currentVitals != null ? '- Latest Vitals: HR ${currentVitals.heartRate} bpm, SpO2 ${currentVitals.oxygenLevel.toStringAsFixed(1)}%' : ''}

CRITICAL MANDATORY SAFETY RULES:
1. NEVER recommend medications or active ingredients that conflict with patient allergies: [${allergies}].
2. ALWAYS check potential interactions with current active medications: [${activeMedsList}].
3. EMERGENCY TRIGGER: If the user describes life-threatening symptoms (severe chest pain, sudden numbness/paralysis, shortness of breath, loss of consciousness, severe bleeding, anaphylaxis), your response MUST START with:
"⚠ THIS MAY BE AN EMERGENCY — Call 999 or 911 immediately."
4. Maintain a reassuring, empathetic, professional tone. Include actionable guidance and ALWAYS remind the patient that AI answers do not replace consultation with a licensed doctor.
''';
  }

  Future<String> sendMessage({
    required String userPrompt,
    required List<Map<String, String>> messageHistory, // [{role: 'user'|'assistant', content: '...'}]
    required UserProfile profile,
    required List<Medication> activeMedications,
    WatchReading? currentVitals,
  }) async {
    final apiKey = getApiKey();

    // System prompt with contextual safety rules
    final systemPrompt = buildSystemPrompt(
      profile: profile,
      activeMedications: activeMedications,
      currentVitals: currentVitals,
    );

    // Format conversation history for Claude API
    final messagesPayload = [
      ...messageHistory.map((m) => {
        'role': m['role'] == 'user' ? 'user' : 'assistant',
        'content': m['content'],
      }),
      {'role': 'user', 'content': userPrompt}
    ];

    if (apiKey == null || apiKey.isEmpty) {
      // Fallback simulated AI assistant if no key provided yet
      return _generateSimulatedResponse(userPrompt, profile, activeMedications);
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': messagesPayload,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentList = data['content'] as List;
        if (contentList.isNotEmpty) {
          return contentList[0]['text'] ?? 'No text response received from AI.';
        }
        return 'No response content returned.';
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? response.body;
        throw Exception('API Error (${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      if (e.toString().contains('API Error')) rethrow;
      // If network fails or key is invalid, fallback with clear notice
      return 'Notice: Unable to reach Claude API directly (${e.toString()}).\n\n' +
          _generateSimulatedResponse(userPrompt, profile, activeMedications);
    }
  }

  String _generateSimulatedResponse(String prompt, UserProfile profile, List<Medication> meds) {
    final p = prompt.toLowerCase();
    if (p.contains('chest pain') || p.contains('shortness of breath') || p.contains('heart attack')) {
      return '''⚠ THIS MAY BE AN EMERGENCY — Call 999 or 911 immediately.

Chest pain or severe shortness of breath can be signs of a cardiovascular event or pulmonary emergency. Please seek immediate emergency medical care or go to the nearest emergency department. Do not drive yourself.''';
    }

    if (p.contains('headache') || p.contains('migraine')) {
      return '''Based on your profile, here are some insights regarding your symptoms:

- **Hydration & Rest**: Ensure adequate water intake and rest in a quiet, dark room.
- **Medication Check**: You are currently taking ${meds.isEmpty ? 'no active medications' : meds.map((m) => m.drugName).join(', ')}. Please avoid taking OTC NSAIDs if you have allergies to them.
- **When to see a doctor**: If the headache is sudden, unusually severe ("thunderclap"), accompanied by fever, neck stiffness, or vision changes, consult a physician promptly.

*Note: Please configure your Anthropic API key in Settings to unlock full real-time Claude 3.5 Sonnet medical AI capabilities.*''';
    }

    return '''Hello! I'm your MediCore AI Assistant. I have evaluated your prompt with your health profile context:

- **Blood Type**: ${profile.bloodType}
- **Active Medications**: ${meds.isEmpty ? 'None' : meds.map((m) => m.drugName).join(', ')}
- **Known Allergies**: ${profile.drugAllergies.isEmpty ? 'None reported' : profile.drugAllergies.join(', ')}

To provide the most tailored guidance, what specific symptoms or concerns would you like to discuss today?

*Tip: Go to Settings to add your Anthropic Claude API key for live real-time AI consultations.*''';
  }
}
