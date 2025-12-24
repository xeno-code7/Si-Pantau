import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'car_edit_screen.dart';

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

        // --- 1. DATA IDENTITAS ---
        final String namaKendaraan = data['nama_kendaraan'] ?? "-";
        final String plat = data['plat'] ?? "-";
        final String? photoUrl = data['photo_url'];
        
        // --- 2. DATA ATRIBUT ---
        final String tahun = data['tahun']?.toString() ?? "-";
        final int odoNow = int.tryParse(data['odo']?.toString() ?? "0") ?? 0;
        final String transmisi = data['transmisi'] ?? "Matic";
        final String bahanBakar = data['bahan_bakar'] ?? "Bensin";
        final String nomorRangka = data['rangka'] ?? "-"; 
        final String nomorMesin = data['mesin'] ?? "-";

        // --- 3. LOGIKA PAJAK & STNK OTOMATIS ---
        final bool manualStnkAktif = data['stnk_aktif'] ?? true;
        DateTime? pajakDate;
        String pajakStr = "-";
        final rawPajak = data['pajak'];

        if (rawPajak is Timestamp) {
          pajakDate = rawPajak.toDate();
          pajakStr = DateFormat('dd MMMM yyyy', 'id_ID').format(pajakDate);
        }

        final bool isExpired = pajakDate != null && DateTime.now().isAfter(pajakDate);
        final bool displayAktif = manualStnkAktif && !isExpired;

        // --- 4. LOGIKA COUNTDOWN SERVIS ---
        final double sisaKmML = double.tryParse(data['prediksi_rul']?.toString() ?? "0.0") ?? 0.0;
        final rawDate = data['last_service_date'];
        DateTime? lastServiceDate = (rawDate is Timestamp) ? rawDate.toDate() : null;
        
        // Data Tambahan Riwayat Servis
        final int lastServiceOdo = int.tryParse(data['last_service_odo']?.toString() ?? "0") ?? 0;
        final String serviceType = data['service_type'] ?? "-";
        
        int sisaHariBaru = 0;
        if (lastServiceDate != null) {
          int bulanTambahan = (data['jenis_kendaraan']?.toString().toLowerCase() == "mobil") ? 5 : 2;
          DateTime targetDate = DateTime(lastServiceDate.year, lastServiceDate.month + bulanTambahan, lastServiceDate.day);
          sisaHariBaru = targetDate.difference(DateTime.now()).inDays;
        }

        Color statusColor = const Color(0xFF5CB85C); 
        if (sisaKmML <= 200 || sisaHariBaru <= 7) {
          statusColor = Colors.red;
        } else if (sisaKmML <= 1000 || sisaHariBaru <= 14) {
          statusColor = Colors.orange;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                photoUrl != null
                    ? Image.network(photoUrl, height: 180, fit: BoxFit.contain)
                    : const Icon(Icons.directions_car, size: 100, color: Colors.grey),
                
                const SizedBox(height: 15),
                Text(plat, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: textColor)),
                Text(namaKendaraan, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                
                const SizedBox(height: 25),
                const Divider(),

                // BOX COUNTDOWN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("COUNTDOWN SERVIS: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Sisa: ${sisaKmML.toStringAsFixed(1)} KM atau $sisaHariBaru hari lagi",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // INFORMASI DETAIL
                _buildDetailRow("Tahun", tahun, textColor),
                _buildDetailRow("Odometer", "${NumberFormat("#,###").format(odoNow)} KM", textColor),
                _buildDetailRow("Pajak", pajakStr, textColor),
                _buildDetailRow("Jenis transmisi", transmisi, textColor),
                _buildDetailRow("Jenis bahan bakar", bahanBakar, textColor),
                _buildDetailRow("Nomor Rangka", nomorRangka, textColor),
                _buildDetailRow("Nomor Mesin", nomorMesin, textColor),

                // STATUS PAJAK DAN STNK
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Pajak dan STNK", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: displayAktif ? const Color(0xFF8CC67E).withOpacity(0.2) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayAktif ? "Aktif" : "Tidak Aktif",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: displayAktif ? const Color(0xFF5CB85C) : Colors.red
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- BAGIAN RIWAYAT SERVIS (DITAMBAHKAN) ---
                const Divider(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Riwayat Service", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: textColor, 
                      decoration: TextDecoration.underline
                    )
                  ),
                ),
                const SizedBox(height: 12),
                lastServiceDate == null
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Belum ada data servis")
                      )
                    : Column(
                        children: [
                          _buildDetailRow(
                            DateFormat('dd MMM yyyy', 'id_ID').format(lastServiceDate), 
                            serviceType, 
                            textColor
                          ),
                          _buildDetailRow("Odo Terakhir Servis", "$lastServiceOdo KM", textColor),
                        ],
                      ),
                // ------------------------------------------

                const SizedBox(height: 30),

                // TOMBOL EDIT
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8CC67E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CarEditScreen(docId: docId, currentData: data)));
                    },
                    child: const Text("Edit Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        ],
      ),
    );
  }
}