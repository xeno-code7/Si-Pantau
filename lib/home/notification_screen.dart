import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pusat Notifikasi",
            style: GoogleFonts.poppins(
                color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('cars')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Generate List Notifikasi berdasarkan kondisi kendaraan
          List<Widget> notificationList = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String nama = data['nama_kendaraan'] ?? "Kendaraan";
            final String plat = data['plat'] ?? "";
            final String jenis = data['jenis_kendaraan'] ?? "mobil";

            // --- 1. CEK SERVIS (Berdasarkan KM atau Waktu) ---
            // Logika KM
            double rul =
                double.tryParse(data['prediksi_rul']?.toString() ?? "0") ?? 0;
            bool urgentService = rul <= 200;
            bool warningService = rul <= 1000;

            // Logika Waktu (Estimasi sederhana jika KM tidak update)
            bool timeServiceDue = false;
            if (data['last_service_date'] != null) {
              DateTime lastService =
                  (data['last_service_date'] as Timestamp).toDate();
              int intervalBulan = (jenis.toLowerCase() == "mobil") ? 6 : 2;
              DateTime nextService = DateTime(lastService.year,
                  lastService.month + intervalBulan, lastService.day);

              // Jika hari ini sudah melewati (H-7) dari jadwal servis
              if (DateTime.now()
                  .isAfter(nextService.subtract(const Duration(days: 7)))) {
                timeServiceDue = true;
              }
            }

            if (urgentService || warningService || timeServiceDue) {
              notificationList.add(_buildNotificationTile(
                context,
                title: "Waktunya Servis: $nama",
                message: urgentService
                    ? "Kondisi KRITIS! Sisa RUL ${rul.toInt()} KM. Segera bawa ke bengkel."
                    : "Persiapan servis. Sisa RUL ${rul.toInt()} KM atau jadwal bulanan sudah dekat.",
                time: "Sekarang",
                icon: Icons.build_circle,
                color: urgentService ? Colors.red : Colors.orange,
                isDark: isDarkMode,
              ));
            }

            // --- 2. CEK PAJAK (H-30) ---
            if (data['pajak'] != null) {
              DateTime pajakDate = (data['pajak'] as Timestamp).toDate();
              int daysUntilTax = pajakDate.difference(DateTime.now()).inDays;

              if (daysUntilTax <= 30 && daysUntilTax >= 0) {
                notificationList.add(_buildNotificationTile(
                  context,
                  title: "Pajak Segera Habis: $nama",
                  message:
                      "Pajak kendaraan $plat habis dalam $daysUntilTax hari lagi (${DateFormat('dd MMM yyyy').format(pajakDate)}).",
                  time: "Penting",
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  isDark: isDarkMode,
                ));
              } else if (daysUntilTax < 0) {
                notificationList.add(_buildNotificationTile(
                  context,
                  title: "Pajak Terlewat: $nama",
                  message:
                      "Pajak kendaraan $plat sudah lewat ${daysUntilTax.abs()} hari! Segera urus.",
                  time: "Terlewat",
                  icon: Icons.warning,
                  color: Colors.red,
                  isDark: isDarkMode,
                ));
              }
            }
          }

          if (notificationList.isEmpty) {
            return _buildEmptyState(
                message: "Tidak ada notifikasi baru.\nSemua kendaraan aman!");
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: notificationList,
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Text(time,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String message = "Belum ada notifikasi"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}
