import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: notifState.isLoading && notifState.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A9C1)))
          : notifState.error != null && notifState.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[500]),
                      const SizedBox(height: 16),
                      Text('Erreur de chargement', style: TextStyle(color: textColor)),
                      TextButton(
                        onPressed: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                        child: const Text('Réessayer', style: TextStyle(color: Color(0xFF00A9C1))),
                      )
                    ],
                  ),
                )
              : notifState.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Aucune notification', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF00A9C1),
                      onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifState.notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = notifState.notifications[index];
                          return _buildNotificationCard(notif, isDark, ref);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif, bool isDark, WidgetRef ref) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

    IconData iconData;
    Color iconColor;
    
    switch (notif.type) {
      case 'commande':
        iconData = Icons.local_shipping;
        iconColor = const Color(0xFF00A9C1);
        break;
      case 'promo':
        iconData = Icons.local_offer;
        iconColor = const Color(0xFFFF3B30);
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        if (!notif.estLu) {
          ref.read(notificationProvider.notifier).markAsRead(notif.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: notif.estLu ? cardColor.withValues(alpha: 0.6) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: notif.estLu ? null : Border.all(color: const Color(0xFF00A9C1).withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            if (!isDark && !notif.estLu)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notif.estLu ? Colors.grey.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: notif.estLu ? Colors.grey : iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notif.estLu ? FontWeight.w500 : FontWeight.w700,
                            color: notif.estLu ? subColor : textColor,
                          ),
                        ),
                      ),
                      if (!notif.estLu)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A9C1),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: notif.estLu ? subColor : (isDark ? Colors.grey[300] : Colors.grey[800]),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
