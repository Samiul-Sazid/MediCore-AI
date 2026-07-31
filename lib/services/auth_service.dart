import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/user_account.dart';
import '../models/user_profile.dart';
import 'hive_service.dart';

class AuthService {
  final HiveService _hiveService = HiveService();
  final Uuid _uuid = const Uuid();

  static const String _keyCurrentUserId = 'current_user_id';
  static const String _keySavedAccountIds = 'saved_account_ids';

  // Generate random salt
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Hash password with salt using SHA-256
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserAccount?> getCurrentUser() async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    final currentId = box.get(_keyCurrentUserId);
    if (currentId == null || currentId.toString().isEmpty) return null;

    final accountMap = _hiveService.getItem(HiveService.boxAccounts, currentId.toString());
    if (accountMap == null) return null;

    return UserAccount.fromMap(accountMap);
  }

  Future<UserAccount> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    DateTime? dob,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Check if email already exists
    final accounts = _hiveService.getAllItems(HiveService.boxAccounts);
    final existing = accounts.any((a) => (a['email'] ?? '').toString().toLowerCase() == normalizedEmail);
    if (existing) {
      throw Exception('An account with this email address already exists.');
    }

    final id = _uuid.v4();
    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final now = DateTime.now();

    final account = UserAccount(
      id: id,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalizedEmail,
      passwordHash: passwordHash,
      salt: salt,
      dob: dob,
      createdAt: now,
    );

    // Save account
    await _hiveService.putItem(HiveService.boxAccounts, id, account.toMap());

    // Create default profile
    final defaultProfile = UserProfile(
      userId: id,
      phone: '+1 (555) 019-2834',
      bloodType: 'O+',
      conditions: ['Hypertension'],
      drugAllergies: ['Penicillin'],
      foodAllergies: ['Peanuts'],
    );
    await _hiveService.putItem(HiveService.boxProfiles, id, defaultProfile.toMap());

    // Save to quick login accounts list
    await _addSavedAccount(id);

    // Set current session
    await _setCurrentSession(id);

    return account;
  }

  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = _hiveService.getAllItems(HiveService.boxAccounts);

    final accountMap = accounts.firstWhere(
      (a) => (a['email'] ?? '').toString().toLowerCase() == normalizedEmail,
      orElse: () => {},
    );

    if (accountMap.isEmpty) {
      throw Exception('No account found with this email address.');
    }

    final account = UserAccount.fromMap(accountMap);
    final inputHash = _hashPassword(password, account.salt);

    if (inputHash != account.passwordHash) {
      throw Exception('Incorrect password. Please try again.');
    }

    await _addSavedAccount(account.id);
    await _setCurrentSession(account.id);

    return account;
  }

  Future<UserAccount> quickLogin({
    required String userId,
    required String password,
  }) async {
    final accountMap = _hiveService.getItem(HiveService.boxAccounts, userId);
    if (accountMap == null) {
      throw Exception('Account not found.');
    }

    final account = UserAccount.fromMap(accountMap);
    final inputHash = _hashPassword(password, account.salt);

    if (inputHash != account.passwordHash) {
      throw Exception('Incorrect password.');
    }

    await _setCurrentSession(account.id);
    return account;
  }

  Future<void> logout() async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    await box.delete(_keyCurrentUserId);
  }

  Future<List<UserAccount>> getSavedAccounts() async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    final savedIds = List<String>.from(box.get(_keySavedAccountIds) ?? []);
    
    final List<UserAccount> list = [];
    for (var id in savedIds) {
      final map = _hiveService.getItem(HiveService.boxAccounts, id);
      if (map != null) {
        list.add(UserAccount.fromMap(map));
      }
    }
    return list;
  }

  Future<void> _setCurrentSession(String userId) async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    await box.put(_keyCurrentUserId, userId);
  }

  Future<void> _addSavedAccount(String userId) async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    final savedIds = List<String>.from(box.get(_keySavedAccountIds) ?? []);
    if (!savedIds.contains(userId)) {
      savedIds.add(userId);
      await box.put(_keySavedAccountIds, savedIds);
    }
  }

  Future<void> deleteAccount(String userId) async {
    // Delete account & profile
    await _hiveService.deleteItem(HiveService.boxAccounts, userId);
    await _hiveService.deleteItem(HiveService.boxProfiles, userId);

    // Remove from saved accounts
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    final savedIds = List<String>.from(box.get(_keySavedAccountIds) ?? []);
    savedIds.remove(userId);
    await box.put(_keySavedAccountIds, savedIds);

    // Clear session if active
    final currentId = box.get(_keyCurrentUserId);
    if (currentId == userId) {
      await box.delete(_keyCurrentUserId);
    }
  }
}
