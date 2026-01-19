import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (e) {
      debugPrint("Gagal set lokasi timezone: $e");
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  // MANUAL SERVIS
  static Future<void> sendServiceReminder({
    required String nama,
    required String plat,
    required int sisaKm,
    required int sisaHari,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_service_id',
      'Pengingat Servis',
      channelDescription: 'Notifikasi untuk jadwal servis kendaraan',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF5CB85C),
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Waktunya Servis! 🛠️',
      '$nama ($plat) sisa $sisaKm KM lagi atau $sisaHari hari lagi.',
      platformDetails,
    );
  }

  // MANUAL PAJAK
  static Future<void> sendTaxReminder({
    required String nama,
    required String plat,
    required String tanggalPajak,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_tax_id',
      'Pengingat Pajak',
      channelDescription: 'Notifikasi untuk jatuh tempo pajak kendaraan',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.orange,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1,
      'Pajak Segera Habis! 📄',
      'Pajak $nama ($plat) jatuh tempo pada $tanggalPajak. Segera perpanjang STNK!',
      platformDetails,
    );
  }

  // OTOMATIS JADWAL
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final scheduledTime = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      8,
      0,
    );

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_reminder_id',
          'Pengingat Otomatis',
          channelDescription: 'Notifikasi jadwal otomatis',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF5CB85C),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Hapus parameter uiLocalNotificationDateInterpretation
      // Karena default-nya sudah absoluteTime
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
