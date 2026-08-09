import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _service.getUserNotifications(userId);
    } catch (e) {
      if (kDebugMode) print('Failed to load notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    await _service.markAsRead(notificationId);
    await loadNotifications(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
    await loadNotifications(userId);
  }

  Future<void> clearAll(String userId) async {
    await _service.clearAll(userId);
    _notifications = [];
    notifyListeners();
  }
}
