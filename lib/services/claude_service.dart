import '../models/user_profile.dart';
import '../models/medication.dart';
import '../models/watch_reading.dart';
import 'api_client.dart';

/// AI Health Advisor service — routes all requests through the backend server.
/// The API key is stored server-side; users don't need to configure anything.
class ClaudeService {
  final ApiClient _api = ApiClient();

  /// Send a message to the AI advisor via the backend proxy.
  Future<String> sendMessage({
    required String userPrompt,
    required List<Map<String, String>> messageHistory,
    required UserProfile profile,
    required List<Medication> activeMedications,
    WatchReading? currentVitals,
  }) async {
    try {
      final response = await _api.post('/chat', {
        'message': userPrompt,
        'history': messageHistory,
      });

      if (response != null && response['reply'] != null) {
        return response['reply'];
      }
      return 'No response received from AI advisor. Please try again.';
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');

      // If backend is unreachable, return a helpful message
      if (errorStr.contains('Connection') ||
          errorStr.contains('timeout') ||
          errorStr.contains('SocketException')) {
        return '''I'm currently unable to connect to the AI service. This can happen if:

• The backend server is not running
• Your internet connection is interrupted

Please ensure the MediCore backend server is running and try again.''';
      }

      return 'Error communicating with AI advisor: $errorStr';
    }
  }
}
