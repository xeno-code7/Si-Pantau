import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'rul_helper.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  // ================= SHOW NOTIFICATION =================
  static Future<void> showRulNotification(
    BuildContext context,
    RulResult rul,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'service_channel',
      'Service Reminder',
      channelDescription: 'Pengingat servis kendaraan',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Pengingat Servis Kendaraan',
      _buildMessage(rul),
      details,
    );
  }

  // ================= MESSAGE =================
  static String _buildMessage(RulResult rul) {
    if (rul.status == "HARUS SERVIS") {
      return "Segera lakukan servis! Sisa ${rul.sisaKm} KM / ${rul.sisaHari} hari";
    }
    if (rul.status == "MENDEKATI SERVIS") {
      return "Servis akan datang. Sisa ${rul.sisaKm} KM / ${rul.sisaHari} hari";
    }
    return "Kendaraan dalam kondisi aman";
  }
}
