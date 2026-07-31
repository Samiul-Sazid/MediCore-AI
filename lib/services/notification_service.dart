import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import 'hive_service.dart';

class NotificationService {
  final HiveService _hiveService = HiveService();
  final Uuid _uuid = const Uuid();

  List<AppNotification> getUserNotifications(String userId) {
    final raw = _hiveService.getAllItems(HiveService.boxNotifications);
    final items = raw
        .where((map) => map['userId'] == userId)
        .map((map) => AppNotification.fromMap(map))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<AppNotification> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    final notif = AppNotification(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _hiveService.putItem(HiveService.boxNotifications, notif.id, notif.toMap());
    return notif;
  }

  Future<void> markAsRead(String notificationId) async {
    final map = _hiveService.getItem(HiveService.boxNotifications, notificationId);
    if (map != null) {
      final notif = AppNotification.fromMap(map);
      final updated = AppNotification(
        id: notif.id,
        userId: notif.userId,
        type: notif.type,
        title: notif.title,
        message: notif.message,
        isRead: true,
        createdAt: notif.createdAt,
      );
      await _hiveService.putItem(HiveService.boxNotifications, updated.id, updated.toMap());
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final items = getUserNotifications(userId);
    for (var n in items) {
      if (!n.isRead) {
        await markAsRead(n.id);
      }
    }
  }

  Future<void> clearAll(String userId) async {
    final items = getUserNotifications(userId);
    for (var n in items) {
      await _hiveService.deleteItem(HiveService.boxNotifications, n.id);
    }
  }
}
