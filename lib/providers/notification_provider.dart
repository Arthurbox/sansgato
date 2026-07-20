import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = true,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  Timer? _pollingTimer;

  @override
  NotificationState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    Future.microtask(() => fetchNotifications());
    _startPolling();
    return NotificationState();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      fetchNotifications(isPolling: true);
    });
  }

  Future<void> fetchNotifications({bool isPolling = false}) async {
    if (!isPolling) state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await NotificationService.fetchNotifications();
      state = state.copyWith(
        notifications: data['notifications'],
        unreadCount: data['unread_count'],
        isLoading: false,
      );
    } catch (e) {
      if (!isPolling) state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await NotificationService.markAsRead(id);
      // Optimistic UI update
      final updatedNotifs = state.notifications.map((n) {
        if (n.id == id && !n.estLu) {
          return AppNotification(
            id: n.id,
            titre: n.titre,
            message: n.message,
            type: n.type,
            estLu: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifs,
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
