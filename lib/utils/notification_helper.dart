import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Inisialisasi Ikon (Wajib pakai ic_launcher agar tidak error resource)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // 2. BUAT CHANNEL (Wajib untuk Android 8.0 ke atas agar notifikasi muncul)

    // --- Channel untuk Servis ---
    const AndroidNotificationChannel serviceChannel =
        AndroidNotificationChannel(
      'sipantau_service_channel',
      'Notifikasi Servis SIPANTAU',
      description: 'Saluran untuk pengingat servis kendaraan AI',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // --- Channel untuk Pajak (Baru) ---
    const AndroidNotificationChannel taxChannel = AndroidNotificationChannel(
      'sipantau_tax_channel',
      'Notifikasi Pajak SIPANTAU',
      description: 'Saluran untuk pengingat jatuh tempo pajak kendaraan',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Daftarkan kedua channel ke sistem Android
      await androidPlugin.createNotificationChannel(serviceChannel);
      await androidPlugin.createNotificationChannel(taxChannel);

      // Minta izin pop-up ke user (Android 13+)
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // --- LOGIC PENJADWALAN (AGAR MUNCUL SAAT APLIKASI DITUTUP) ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Konversi waktu ke Zona Waktu Lokal HP
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduleTime = tz.TZDateTime.from(scheduledDate, tz.local);

      // Jika waktu sudah lewat, jangan dijadwalkan (atau jadwalkan untuk tahun depan jika perlu)
      if (scheduleTime.isBefore(now)) {
        debugPrint("Waktu jadwal sudah lewat, notifikasi tidak dijadwalkan.");
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sipantau_service_channel',
            'Notifikasi Terjadwal',
            channelDescription: 'Notifikasi yang berjalan di background',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("Notifikasi Berhasil Dijadwalkan: $title pada $scheduleTime");
    } catch (e) {
      debugPrint("Gagal Menjadwalkan Notifikasi: $e");
    }
  }

  // Fungsi untuk membatalkan semua jadwal (misal saat logout)
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
