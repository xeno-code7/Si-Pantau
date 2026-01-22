import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Tambahan untuk hapus foto
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

  // --- LOGIKA HAPUS KENDARAAN ---
  Future<void> _deleteCar(BuildContext context, String? photoUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Tampilkan Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // 2. Hapus Foto dari Storage (Jika ada)
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(photoUrl).delete();
        } catch (e) {
          debugPrint("Gagal hapus foto (mungkin sudah hilang): $e");
        }
      }

      // 3. Hapus Data dari Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cars')
          .doc(docId)
          .delete();

      if (context.mounted) {
        // Tutup Loading
        Navigator.pop(context);
        // Tutup Halaman Detail (Kembali ke List)
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Kendaraan berhasil dihapus"),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
    }
  }

  // --- DIALOG KONFIRMASI ---
  void _showDeleteConfirmation(
      BuildContext context, String nama, String? photoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Hapus Kendaraan?"),
          content: Text(
              "Anda yakin ingin menghapus $nama? Data yang dihapus tidak bisa dikembalikan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Tutup dialog konfirmasi
                _deleteCar(context, photoUrl); // Jalankan fungsi hapus
              },
              child: const Text("Hapus",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

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
        // Cek jika data sudah terhapus (misal dihapus dari device lain)
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text("Detail Kendaraan")),
            body: const Center(
                child: Text("Data kendaraan tidak ditemukan / sudah dihapus")),
          );
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;

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

        final bool isExpired =
            pajakDate != null && DateTime.now().isAfter(pajakDate);
        final bool displayAktif = manualStnkAktif && !isExpired;

        // --- 4. LOGIKA COUNTDOWN SERVIS ---
        final double sisaKmML =
            double.tryParse(data['prediksi_rul']?.toString() ?? "0.0") ?? 0.0;
        final rawDate = data['last_service_date'];
        DateTime? lastServiceDate =
            (rawDate is Timestamp) ? rawDate.toDate() : null;

        final int lastServiceOdo =
            int.tryParse(data['last_service_odo']?.toString() ?? "0") ?? 0;
        final String serviceType = data['service_type'] ?? "-";

        int sisaHariBaru = 0;
        if (lastServiceDate != null) {
          int bulanTambahan =
              (data['jenis_kendaraan']?.toString().toLowerCase() == "mobil")
                  ? 6
                  : 2;
          DateTime targetDate = DateTime(lastServiceDate.year,
              lastServiceDate.month + bulanTambahan, lastServiceDate.day);
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
            actions: [
              // Opsi Hapus Cepat di Pojok Kanan Atas (Opsional, icon sampah)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    _showDeleteConfirmation(context, namaKendaraan, photoUrl),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                photoUrl != null
                    ? Image.network(photoUrl, height: 180, fit: BoxFit.contain)
                    : const Icon(Icons.directions_car,
                        size: 100, color: Colors.grey),

                const SizedBox(height: 15),

                Text(plat,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: textColor)),
                Text(namaKendaraan,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey)),

                const SizedBox(height: 25),
                const Divider(),

                // BOX COUNTDOWN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("COUNTDOWN SERVIS: ",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          "Sisa: ${sisaKmML.toStringAsFixed(1)} KM atau $sisaHariBaru hari lagi",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // INFORMASI DETAIL
                _buildDetailRow("Tahun", tahun, textColor),
                _buildDetailRow("Odometer",
                    "${NumberFormat("#,###").format(odoNow)} KM", textColor),
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
                      Text("Pajak dan STNK",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: displayAktif
                              ? const Color(0xFF8CC67E).withOpacity(0.2)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayAktif ? "Aktif" : "Tidak Aktif",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: displayAktif
                                  ? const Color(0xFF5CB85C)
                                  : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),
                const SizedBox(height: 10),

                // RIWAYAT SERVIS
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Riwayat Service",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                          decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 12),
                lastServiceDate == null
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Belum ada data servis"))
                    : Column(
                        children: [
                          _buildDetailRow(
                              DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(lastServiceDate),
                              serviceType,
                              textColor),
                          _buildDetailRow("Odo Terakhir Servis",
                              "$lastServiceOdo KM", textColor),
                        ],
                      ),

                const SizedBox(height: 40),

                // --- TOMBOL EDIT ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8CC67E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CarEditScreen(
                                  docId: docId, currentData: data)));
                    },
                    child: const Text("Edit Data",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // --- TOMBOL HAPUS (BARU) ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showDeleteConfirmation(
                        context, namaKendaraan, photoUrl),
                    child: const Text("Hapus Kendaraan",
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        ],
      ),
    );
  }
}
