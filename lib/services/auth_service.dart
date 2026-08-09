import '../models/user_account.dart';
import 'hive_service.dart';
import 'api_client.dart';

class AuthService {
  final HiveService _hiveService = HiveService();
  final ApiClient _api = ApiClient();

  static const String _keyCurrentUserId = 'current_user_id';
  static const String _keySavedAccountIds = 'saved_account_ids';

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
    try {
      // Try backend registration first
      final response = await _api.post('/auth/register', {
        'name': '$firstName $lastName',
        'email': email,
        'password': password,
      });

      final token = response['token'];
      final userJson = response['user'];
      final id = userJson['id'].toString();

      final account = UserAccount(
        id: id,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: '',
        salt: '',
        dob: dob,
        createdAt: DateTime.now(),
      );

      final accountMap = account.toMap();
      accountMap['token'] = token;

      await _hiveService.putItem(HiveService.boxAccounts, 'session', accountMap);
      await _hiveService.putItem(HiveService.boxAccounts, id, accountMap);
      await _addSavedAccount(id);
      await _setCurrentSession(id);

      return account;
    } catch (e) {
      // If it's a known backend error (like duplicate email), rethrow
      final errorStr = e.toString();
      if (errorStr.contains('already exists') || errorStr.contains('409')) {
        rethrow;
      }
      // For connection errors, fall back to local-only registration
      return _registerLocal(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        dob: dob,
      );
    }
  }

  /// Fallback local registration when backend is unreachable.
  Future<UserAccount> _registerLocal({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    DateTime? dob,
  }) async {
    // Check local duplicates
    final savedIds = await _getSavedAccountIds();
    for (var id in savedIds) {
      final map = _hiveService.getItem(HiveService.boxAccounts, id);
      if (map != null && map['email'] == email.trim().toLowerCase()) {
        throw Exception('An account with this email already exists.');
      }
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final account = UserAccount(
      id: id,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: password, // Stored locally only
      salt: '',
      dob: dob,
      createdAt: DateTime.now(),
    );

    final accountMap = account.toMap();
    accountMap['token'] = 'local-session-$id';
    accountMap['localOnly'] = true;

    await _hiveService.putItem(HiveService.boxAccounts, 'session', accountMap);
    await _hiveService.putItem(HiveService.boxAccounts, id, accountMap);
    await _addSavedAccount(id);
    await _setCurrentSession(id);

    return account;
  }

  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final token = response['token'];
      final userJson = response['user'];
      final id = userJson['id'].toString();

      final nameParts = userJson['name'].split(' ');
      final account = UserAccount(
        id: id,
        firstName: nameParts.first,
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        email: userJson['email'],
        passwordHash: '',
        salt: '',
        createdAt: DateTime.now(),
      );

      final accountMap = account.toMap();
      accountMap['token'] = token;

      await _hiveService.putItem(HiveService.boxAccounts, 'session', accountMap);
      await _hiveService.putItem(HiveService.boxAccounts, id, accountMap);
      await _addSavedAccount(id);
      await _setCurrentSession(id);

      return account;
    } catch (e) {
      final errorStr = e.toString();
      // If it's a known auth error, rethrow
      if (errorStr.contains('Invalid') || errorStr.contains('401')) {
        rethrow;
      }
      // For connection errors, attempt local login
      return _loginLocal(email: email, password: password);
    }
  }

  /// Fallback local login when backend is unreachable.
  Future<UserAccount> _loginLocal({
    required String email,
    required String password,
  }) async {
    final savedIds = await _getSavedAccountIds();
    for (var id in savedIds) {
      final map = _hiveService.getItem(HiveService.boxAccounts, id);
      if (map != null && map['email'] == email.trim().toLowerCase()) {
        // For local accounts, check stored password
        if (map['localOnly'] == true && map['passwordHash'] == password) {
          final account = UserAccount.fromMap(map);
          await _hiveService.putItem(HiveService.boxAccounts, 'session', Map<String, dynamic>.from(map));
          await _setCurrentSession(id);
          return account;
        } else if (map['localOnly'] != true) {
          // Backend account cached locally — can't verify password offline
          throw Exception('Cannot verify credentials offline. Please ensure the backend server is running.');
        }
      }
    }
    throw Exception('Invalid email or password.');
  }

  Future<UserAccount> quickLogin({
    required String userId,
    required String password,
  }) async {
    final accountMap = _hiveService.getItem(HiveService.boxAccounts, userId);
    if (accountMap == null) throw Exception('Account not found.');

    final email = accountMap['email'];
    return login(email: email, password: password);
  }

  Future<void> logout() async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    await box.delete(_keyCurrentUserId);
    await _hiveService.deleteItem(HiveService.boxAccounts, 'session');
  }

  Future<List<UserAccount>> getSavedAccounts() async {
    final savedIds = await _getSavedAccountIds();
    final List<UserAccount> list = [];
    for (var id in savedIds) {
      final map = _hiveService.getItem(HiveService.boxAccounts, id);
      if (map != null) {
        list.add(UserAccount.fromMap(map));
      }
    }
    return list;
  }

  Future<List<String>> _getSavedAccountIds() async {
    final box = _hiveService.getBox(HiveService.boxAppSettings);
    return List<String>.from(box.get(_keySavedAccountIds) ?? []);
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
    await _hiveService.deleteItem(HiveService.boxAccounts, userId);
    await _hiveService.deleteItem(HiveService.boxProfiles, userId);

    final box = _hiveService.getBox(HiveService.boxAppSettings);
    final savedIds = List<String>.from(box.get(_keySavedAccountIds) ?? []);
    savedIds.remove(userId);
    await box.put(_keySavedAccountIds, savedIds);

    final currentId = box.get(_keyCurrentUserId);
    if (currentId == userId) {
      await box.delete(_keyCurrentUserId);
    }
  }
}
