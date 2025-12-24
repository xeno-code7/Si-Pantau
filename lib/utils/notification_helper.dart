import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Inisialisasi Ikon (Wajib pakai ic_launcher agar tidak error resource)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // 2. BUAT CHANNEL (Wajib untuk Android 8.0 ke atas agar notifikasi muncul)
    
    // --- Channel untuk Servis ---
    const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
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

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Daftarkan kedua channel ke sistem Android
      await androidPlugin.createNotificationChannel(serviceChannel);
      await androidPlugin.createNotificationChannel(taxChannel);
      
      // Minta izin pop-up ke user (Android 13+)
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // --- LOGIC REMINDER SERVIS (TETAP) ---
  static Future<void> sendServiceReminder({
    required String nama,
    required String plat,
    required int sisaKm,
    required int sisaHari,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'sipantau_service_channel',
        'Notifikasi Servis SIPANTAU',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      final NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        DateTime.now().millisecond, 
        'Waktunya Servis: $nama',
        'Sisa $sisaKm KM atau $sisaHari hari lagi ($plat)',
        platformDetails,
      );
      debugPrint("Notifikasi Servis Berhasil Dikirim!");
    } catch (e) {
      debugPrint("Gagal Kirim Notifikasi Servis: $e");
    }
  }

  // --- LOGIC REMINDER PAJAK (BARU) ---
  static Future<void> sendTaxReminder({
    required String nama,
    required String plat,
    required String tanggalPajak,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'sipantau_tax_channel', // Menggunakan channel pajak yang baru dibuat
        'Notifikasi Pajak SIPANTAU',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      final NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      // Mengirim pesan notifikasi sesuai permintaan kamu
      await _notificationsPlugin.show(
        // ID Unik (ditambah 1 agar tidak bentrok dengan servis di milidetik yang sama)
        DateTime.now().millisecond + 1, 
        'Peringatan Pajak Kendaraan',
        'Kendaraan dengan merk $nama dan nopol $plat pajaknya akan habis pada tanggal $tanggalPajak.',
        platformDetails,
      );
      debugPrint("Notifikasi Pajak Berhasil Dikirim!");
    } catch (e) {
      debugPrint("Gagal Kirim Notifikasi Pajak: $e");
    }
  }
}