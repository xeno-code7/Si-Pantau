import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_helper.dart';

class ReminderManager {
  /// Fungsi ini dipanggil di HomeScreen untuk menjadwalkan notifikasi
  /// berdasarkan data kendaraan di Firestore.
  static Future<void> setupAutomatedReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Batalkan semua jadwal lama agar tidak duplikat saat data diupdate
      await NotificationHelper.cancelAll();

      // 2. Ambil data kendaraan user
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cars')
          .get();

      int notificationIdCounter = 100; // ID awal untuk notifikasi

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String nama = data['nama_kendaraan'] ?? "Kendaraan";
        final String plat = data['plat'] ?? "";
        final String jenis = data['jenis_kendaraan'] ?? "mobil";

        // --- A. JADWAL SERVIS BERDASARKAN WAKTU ---
        // Karena kita tidak bisa tracking KM di background secara realtime tanpa service khusus,
        // kita gunakan estimasi waktu (misal: Mobil 6 bulan, Motor 2 bulan dari servis terakhir).
        if (data['last_service_date'] != null) {
          DateTime lastService =
              (data['last_service_date'] as Timestamp).toDate();

          // Tentukan interval bulan
          int intervalBulan = (jenis.toLowerCase() == "mobil") ? 6 : 2;

          // Hitung tanggal servis berikutnya
          DateTime nextServiceDate = DateTime(
              lastService.year,
              lastService.month + intervalBulan,
              lastService.day,
              9,
              0 // Jam 9 Pagi
              );

          // Jadwalkan Notifikasi
          await NotificationHelper.scheduleNotification(
            id: notificationIdCounter++,
            title: "Waktunya Servis: $nama",
            body:
                "Sudah $intervalBulan bulan sejak servis terakhir. Cek kondisi $plat Anda.",
            scheduledDate: nextServiceDate,
          );
        }

        // --- B. JADWAL PAJAK (H-7) ---
        if (data['pajak'] != null) {
          DateTime pajakDate = (data['pajak'] as Timestamp).toDate();

          // Set H-7 jam 8 Pagi
          DateTime reminderDate = pajakDate.subtract(const Duration(days: 7));
          reminderDate = DateTime(
              reminderDate.year, reminderDate.month, reminderDate.day, 8, 0);

          await NotificationHelper.scheduleNotification(
            id: notificationIdCounter++,
            title: "Pajak Segera Habis!",
            body:
                "Pajak $nama ($plat) akan habis pada ${pajakDate.day}/${pajakDate.month}/${pajakDate.year}. Siapkan dananya!",
            scheduledDate: reminderDate,
          );
        }
      }
      debugPrint("Reminder otomatis berhasil dijadwalkan ulang.");
    } catch (e) {
      debugPrint("Gagal setup reminder otomatis: $e");
    }
  }
}
