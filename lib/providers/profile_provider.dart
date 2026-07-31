import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';

class ProfileProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    final map = _hiveService.getItem(HiveService.boxProfiles, userId);
    if (map != null) {
      _profile = UserProfile.fromMap(map);
    } else {
      _profile = UserProfile(userId: userId);
      await _hiveService.putItem(HiveService.boxProfiles, userId, _profile!.toMap());
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    _profile = updatedProfile;
    await _hiveService.putItem(HiveService.boxProfiles, updatedProfile.userId, updatedProfile.toMap());
    notifyListeners();
  }
}
