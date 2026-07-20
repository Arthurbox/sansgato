import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/notification.dart';
import '../config/api_config.dart';

class NotificationService {
  static Future<Map<String, dynamic>> fetchNotifications() async {
    final token = AuthService.accessToken;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.notifications}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> notifList = data['notifications'];
      return {
        'unread_count': data['unread_count'],
        'notifications': notifList.map((n) => AppNotification.fromJson(n)).toList(),
      };
    } else {
      throw Exception('Failed to fetch notifications');
    }
  }

  static Future<void> markAsRead(int id) async {
    final token = AuthService.accessToken;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.notificationRead(id)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }
}
