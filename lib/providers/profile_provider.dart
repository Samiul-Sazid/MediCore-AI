import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import '../services/api_client.dart';

class ProfileProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final ApiClient _api = ApiClient();
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    // Attempt backend fetch first
    try {
      final data = await _api.get('/patient/profile');
      if (data != null) {
        _profile = UserProfile(
          userId: userId,
          phone: data['phone'] ?? '',
          gender: data['gender'] ?? 'Not specified',
          bloodType: data['blood_type'] ?? data['blood_group'] ?? 'Unknown',
          weightKg: (data['weight_kg'] ?? 70.0).toDouble(),
          heightCm: (data['height_cm'] ?? 170.0).toDouble(),
          conditions: List<String>.from(data['conditions'] ?? []),
          drugAllergies: List<String>.from(data['drug_allergies'] ?? []),
          foodAllergies: List<String>.from(data['food_allergies'] ?? []),
          emergencyContactName: data['emergency_contact_name'] ?? '',
          emergencyContactPhone: data['emergency_contact_phone'] ?? '',
          emergencyContactRelation: data['emergency_contact_relation'] ?? '',
        );
        // Cache in Hive for offline access
        await _hiveService.putItem(HiveService.boxProfiles, userId, _profile!.toMap());
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load profile from backend: $e');
    }

    // Fallback to local cache
    if (_profile == null) {
      final map = _hiveService.getItem(HiveService.boxProfiles, userId);
      if (map != null) {
        _profile = UserProfile.fromMap(map);
      } else {
        // Create empty profile — no hardcoded defaults
        _profile = UserProfile(userId: userId);
        await _hiveService.putItem(HiveService.boxProfiles, userId, _profile!.toMap());
      }
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    _profile = updatedProfile;
    await _hiveService.putItem(HiveService.boxProfiles, updatedProfile.userId, updatedProfile.toMap());

    // Push to backend
    try {
      await _api.put('/patient/profile', {
        'phone': updatedProfile.phone,
        'gender': updatedProfile.gender,
        'blood_type': updatedProfile.bloodType,
        'weight_kg': updatedProfile.weightKg,
        'height_cm': updatedProfile.heightCm,
        'conditions': updatedProfile.conditions,
        'drug_allergies': updatedProfile.drugAllergies,
        'food_allergies': updatedProfile.foodAllergies,
        'emergency_contact_name': updatedProfile.emergencyContactName,
        'emergency_contact_phone': updatedProfile.emergencyContactPhone,
        'emergency_contact_relation': updatedProfile.emergencyContactRelation,
      });
    } catch (e) {
      if (kDebugMode) print('Failed to push profile update to backend: $e');
    }

    notifyListeners();
  }
}
