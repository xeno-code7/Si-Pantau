import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'car_edit_screen.dart';
import '../utils/rul_helper.dart';
import '../utils/notification_helper.dart';

class CarDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic>? initialData;

  const CarDetailScreen({
    super.key,
    required this.docId,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    initializeDateFormatting('id_ID', null);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cars')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data = initialData ?? {};

        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        }

        // ================= DATA KENDARAAN =================
        final String namaKendaraan = data['nama_kendaraan'] ?? "-";
        final String plat = data['plat'] ?? "-";
        final String tahun = data['tahun'] ?? "-";
        final String warna = data['warna'] ?? "-";
        final String jenisKendaraan = data['jenis_kendaraan'] ?? "motor";
        final String? photoUrl = data['photo_url'];

        final int odoNow =
            int.tryParse(data['odo']?.toString() ?? "0") ?? 0;

        final String pajakStr = data['pajak_date'] ?? "-";

        // ================= DATA SERVIS TERAKHIR =================
        final int lastServiceOdo =
            int.tryParse(data['last_service_odo']?.toString() ?? "0") ?? 0;

        final String serviceType = data['service_type'] ?? "-";

        // === PARSING TANGGAL SERVIS (STRING / TIMESTAMP) ===
        DateTime? lastServiceDate;
        final rawDate = data['last_service_date'];

        try {
          if (rawDate is Timestamp) {
            // FORMAT BARU (Firestore Timestamp)
            lastServiceDate = rawDate.toDate();
          } else if (rawDate is String && rawDate.isNotEmpty) {
            // FORMAT LAMA (String)
            lastServiceDate =
                DateFormat('dd MMMM yyyy', 'id_ID').parse(rawDate);
          }
        } catch (_) {
          lastServiceDate = null;
        }

        // ================= HITUNG RUL =================
        RulResult? rul;
        if (lastServiceDate != null && lastServiceOdo > 0) {
          rul = RulHelper.hitungRul(
            jenisKendaraan: jenisKendaraan,
            odoSekarang: odoNow,
            odoTerakhirServis: lastServiceOdo,
            tanggalTerakhirServis: lastServiceDate,
          );

          // === NOTIFIKASI (TIDAK SPAM) ===
          if (rul.status != "AMAN") {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationHelper.showRulNotification(context, rul!);
            });
          }
        }

        // ================= STATUS PAJAK =================
        bool isPajakActive = false;
        if (pajakStr.isNotEmpty && pajakStr != "-") {
          try {
            final pajakDate =
                DateFormat('dd MMMM yyyy', 'id_ID').parse(pajakStr);
            final today = DateTime.now();
            isPajakActive =
                !pajakDate.isBefore(
                    DateTime(today.year, today.month, today.day));
          } catch (_) {}
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Color(0xFF5CB85C)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= FOTO =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      photoUrl != null
                          ? Image.network(photoUrl,
                              height: 150, fit: BoxFit.contain)
                          : const Icon(Icons.directions_car,
                              size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        namaKendaraan,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        plat,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= STATUS SERVIS (RUL) =================
                if (rul != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: rul.status == "HARUS SERVIS"
                          ? Colors.red
                          : rul.status == "MENDEKATI SERVIS"
                              ? Colors.orange
                              : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status Servis",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sisa ${rul.sisaKm} KM atau ${rul.sisaHari} hari",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                _buildDetailRow("Jenis Kendaraan", jenisKendaraan, textColor),
                _buildDetailRow("Tahun", tahun, textColor),
                _buildDetailRow("Warna", warna, textColor),
                _buildDetailRow("Odometer", "$odoNow KM", textColor),
                _buildDetailRow("Pajak", pajakStr, textColor),

                // ================= STATUS PAJAK =================
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Status Pajak",
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPajakActive
                              ? const Color(0xFF5CB85C)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPajakActive ? "Aktif" : "Non Aktif",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),

                const Divider(),
                const SizedBox(height: 10),

                // ================= SERVIS TERAKHIR =================
                Text(
                  "Servis Terakhir",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: textColor),
                ),
                const SizedBox(height: 16),

                lastServiceDate == null
                    ? const Text("Belum ada data servis")
                    : Column(
                        children: [
                          _buildDetailRow(
                            "Tanggal Servis",
                            DateFormat('dd MMMM yyyy', 'id_ID')
                                .format(lastServiceDate),
                            textColor,
                          ),
                          _buildDetailRow(
                              "Jenis Servis", serviceType, textColor),
                          _buildDetailRow(
                              "Odometer Servis",
                              "$lastServiceOdo KM",
                              textColor),
                        ],
                      ),

                const SizedBox(height: 40),

                // ================= BUTTON EDIT =================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CB85C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarEditScreen(
                            docId: docId,
                            currentData: data,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Edit Data",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
