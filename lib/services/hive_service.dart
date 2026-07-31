import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String boxAccounts = 'accounts';
  static const String boxProfiles = 'profiles';
  static const String boxMedications = 'medications';
  static const String boxDocuments = 'documents';
  static const String boxScanHistory = 'scanHistory';
  static const String boxChatSessions = 'chatSessions';
  static const String boxChatMessages = 'chatMessages';
  static const String boxHealthEvents = 'healthEvents';
  static const String boxNotifications = 'notifications';
  static const String boxWatchSettings = 'watchSettings';
  static const String boxWatchAlerts = 'watchAlerts';
  static const String boxAppSettings = 'appSettings';

  Future<void> init() async {
    await Hive.initFlutter();
    
    await Future.wait([
      Hive.openBox(boxAccounts),
      Hive.openBox(boxProfiles),
      Hive.openBox(boxMedications),
      Hive.openBox(boxDocuments),
      Hive.openBox(boxScanHistory),
      Hive.openBox(boxChatSessions),
      Hive.openBox(boxChatMessages),
      Hive.openBox(boxHealthEvents),
      Hive.openBox(boxNotifications),
      Hive.openBox(boxWatchSettings),
      Hive.openBox(boxWatchAlerts),
      Hive.openBox(boxAppSettings),
    ]);
  }

  Box getBox(String boxName) => Hive.box(boxName);

  // Helper CRUD methods
  Future<void> putItem(String boxName, String key, Map<String, dynamic> item) async {
    await getBox(boxName).put(key, item);
  }

  Map<dynamic, dynamic>? getItem(String boxName, String key) {
    final res = getBox(boxName).get(key);
    if (res is Map) return res;
    return null;
  }

  List<Map<String, dynamic>> getAllItems(String boxName) {
    final box = getBox(boxName);
    final List<Map<String, dynamic>> items = [];
    for (var key in box.keys) {
      final val = box.get(key);
      if (val is Map) {
        items.add(Map<String, dynamic>.from(val));
      }
    }
    return items;
  }

  Future<void> deleteItem(String boxName, String key) async {
    await getBox(boxName).delete(key);
  }

  Future<void> clearBox(String boxName) async {
    await getBox(boxName).clear();
  }
}
