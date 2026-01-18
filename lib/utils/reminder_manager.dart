import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_helper.dart';

class ReminderManager {
  // Fungsi Utama: Cek Database & Pasang Notifikasi
  static Future<void> setupAutomatedReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Bersihkan jadwal lama biar tidak duplikat
      await NotificationHelper.cancelAll();

      // 2. Ambil data mobil user
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cars')
          .get();

      int notificationId = 0; // ID unik untuk setiap notifikasi

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String namaMobil = data['nama_kendaraan'] ?? "Mobil";
        String plat = data['plat'] ?? "";

        // --- LOGIKA PAJAK ---
        if (data['tgl_pajak'] != null) {
          DateTime tglPajak = (data['tgl_pajak'] as Timestamp).toDate();

          // H-30 (Peringatan Santai)
          _scheduleIfFuture(
            id: notificationId++,
            title: "Pengingat Pajak 🗓️",
            body:
                "Pajak $namaMobil ($plat) jatuh tempo bulan depan. Siapkan dananya ya!",
            targetDate: tglPajak.subtract(const Duration(days: 30)),
          );

          // H-7 (Peringatan Mendesak)
          _scheduleIfFuture(
            id: notificationId++,
            title: "Pajak Segera Habis! 🚨",
            body:
                "Minggu depan pajak $namaMobil ($plat) habis! Segera bayar sekarang.",
            targetDate: tglPajak.subtract(const Duration(days: 7)),
          );
        }

        // --- LOGIKA SERVIS (Asumsi ada field 'next_service_date') ---
        // Jika di database kamu belum ada tanggal servis (karena pakainya KM),
        // Logika H-14 ini butuh estimasi tanggal.
        // Untuk sekarang kita cek jika ada field 'tgl_servis_berikutnya'
        if (data['tgl_servis_berikutnya'] != null) {
          DateTime tglServis =
              (data['tgl_servis_berikutnya'] as Timestamp).toDate();

          // H-14 (Booking Bengkel)
          _scheduleIfFuture(
            id: notificationId++,
            title: "Waktunya Servis 🛠️",
            body:
                "Jadwal servis $namaMobil ($plat) 2 minggu lagi. Yuk booking bengkel!",
            targetDate: tglServis.subtract(const Duration(days: 14)),
          );

          // H-7 (Mendesak)
          _scheduleIfFuture(
            id: notificationId++,
            title: "Servis Minggu Depan! ⚠️",
            body:
                "Jangan lupa servis $namaMobil ($plat) minggu depan agar performa tetap prima.",
            targetDate: tglServis.subtract(const Duration(days: 7)),
          );
        }
      }

      if (kDebugMode) {
        print("✅ Reminder Otomatis Berhasil Dijadwalkan");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Gagal setup reminder: $e");
      }
    }
  }

  // Helper kecil untuk memastikan tanggal belum lewat
  static void _scheduleIfFuture({
    required int id,
    required String title,
    required String body,
    required DateTime targetDate,
  }) {
    if (targetDate.isAfter(DateTime.now())) {
      NotificationHelper.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: targetDate,
      );
    }
  }
}
