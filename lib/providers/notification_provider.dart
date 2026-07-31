import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _notifications = _service.getUserNotifications(userId);

    // Initial default notifications if empty
    if (_notifications.isEmpty) {
      await _service.createNotification(
        userId: userId,
        type: 'medication',
        title: 'Medication Reminder',
        message: 'Remember to take your Lisinopril 10mg morning dose with water.',
      );
      await _service.createNotification(
        userId: userId,
        type: 'system',
        title: 'Welcome to MediCore AI',
        message: 'Your health dashboard is ready. Configure your Claude API key in Settings to activate AI Consultations.',
      );
      _notifications = _service.getUserNotifications(userId);
    }

    notifyListeners();
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
    await loadNotifications(userId);
  }
}
