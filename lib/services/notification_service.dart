import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import 'hive_service.dart';
import 'api_client.dart';

class NotificationService {
  final HiveService _hiveService = HiveService();
  final ApiClient _api = ApiClient();
  final Uuid _uuid = const Uuid();

  /// Fetch notifications from backend API, with local Hive fallback.
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final data = await _api.get('/notifications/');
      if (data != null && data is List) {
        final notifications = data.map((n) => AppNotification(
          id: n['id'].toString(),
          userId: userId,
          type: n['type'] ?? 'system',
          title: n['title'] ?? '',
          message: n['message'] ?? '',
          isRead: n['is_read'] ?? false,
          createdAt: n['created_at'] != null
              ? DateTime.tryParse(n['created_at']) ?? DateTime.now()
              : DateTime.now(),
        )).toList();

        // Cache in Hive
        for (var notif in notifications) {
          await _hiveService.putItem(HiveService.boxNotifications, notif.id, notif.toMap());
        }

        return notifications;
      }
    } catch (e) {
      // Fall back to local cache
    }

    // Hive fallback
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
    // Try backend first
    try {
      await _api.put('/notifications/$notificationId/read', {});
    } catch (_) {}

    // Update local cache
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
    // Try backend first
    try {
      await _api.put('/notifications/read-all', {});
    } catch (_) {}

    // Update local cache
    final items = await getUserNotifications(userId);
    for (var n in items) {
      if (!n.isRead) {
        await markAsRead(n.id);
      }
    }
  }

  Future<void> clearAll(String userId) async {
    // Try backend first
    try {
      await _api.delete('/notifications/clear');
    } catch (_) {}

    // Clear local cache
    final raw = _hiveService.getAllItems(HiveService.boxNotifications);
    for (var map in raw) {
      if (map['userId'] == userId) {
        await _hiveService.deleteItem(HiveService.boxNotifications, map['id'] ?? '');
      }
    }
  }
}
