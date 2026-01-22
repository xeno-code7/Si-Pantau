import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sipantau/utils/rul_helper.dart';

class ServiceDashboardScreen extends StatelessWidget {
  final String carId;
  final Map<String, dynamic> carData;

  const ServiceDashboardScreen({super.key, required this.carId, required this.carData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("SERVICE",
            style: GoogleFonts.poppins(color: const Color(0xFF5CB85C), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('cars').doc(carId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;

          // --- 1. AMBIL DATA DASAR ---
          // Mendukung field 'type' atau 'jenis_kendaraan' agar sinkron dengan CarAddScreen
          String type = (data['jenis_kendaraan'] ?? data['type'] ?? 'mobil').toString().toLowerCase(); 
          int currentOdo = data['odo'] ?? 0;
          int lastServiceOdo = data['last_service_odo'] ?? 0;
          DateTime lastServiceDate = (data['last_service_date'] as Timestamp).toDate();

          // --- 2. LOGIKA HYBRID METHOD ---
          
          // A. LOGIKA KM: Mengambil hasil prediksi Random Forest dari Hugging Face yang tersimpan di Firestore [cite: 1253, 1361]
          double sisaKmAI = double.tryParse(data['prediksi_rul']?.toString() ?? "0.0") ?? 0.0;

          // B. LOGIKA HARI: Countdown manual berdasarkan servis terakhir (Mobil: 6 bulan, Motor: 2 bulan) [cite: 360, 1469]
          int intervalBulan = (type == 'motor') ? 2 : 6;
          DateTime nextServiceDate = DateTime(lastServiceDate.year, lastServiceDate.month + intervalBulan, lastServiceDate.day);
          int sisaHariManual = nextServiceDate.difference(DateTime.now()).inDays;

          // --- 3. PENENTUAN STATUS & WARNA UI ---
          Color statusColor;
          String statusBadge;
          String saranUtama;
          List<String> checkList;

          // Threshold Hybrid: Jika salah satu parameter (KM AI atau Hari) terpenuhi
          if (sisaKmAI <= 200 || sisaHariManual <= 7) {
            statusColor = Colors.red;
            statusBadge = "HARUS SERVIS";
            saranUtama = "WAKTUNYA GANTI OLI";
            checkList = (type == 'motor')
                ? ["Ganti Oli Mesin", "Cek Rantai", "Cek Rem"]
                : ["Ganti Oli Mesin", "Filter Oli", "Cek General"];
          } else if (sisaKmAI <= 1000 || sisaHariManual <= 14) {
            statusColor = Colors.orange;
            statusBadge = "MENDEKATI SERVIS";
            saranUtama = "PERSIAPKAN SERVIS";
            checkList = (type == 'motor')
                ? ["Cek Rem", "Cek Busi"]
                : ["Cek Air Radiator", "Cek Aki"];
          } else {
            statusColor = Colors.green;
            statusBadge = "KENDARAAN PRIMA";
            saranUtama = "KENDARAAN PRIMA";
            checkList = (type == 'motor')
                ? ["Cek Tekanan Ban", "Pembersihan"]
                : ["Cek Air Radiator", "Cek Wiper"];
          }

          // Hitung pemakaian KM untuk tampilan card
          int odoDiff = currentOdo - lastServiceOdo;
          int limitKm = (type == 'motor') ? 3000 : 8000;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data),
                const SizedBox(height: 24),

                // Menampilkan status sisa hari (Manual) dan sisa KM (AI Random Forest)
                _buildEstimationCard(
                    nextServiceDate,
                    statusBadge,
                    statusColor,
                    saranUtama,
                    checkList,
                    odoDiff,
                    limitKm,
                    sisaKmAI.toInt(),
                    sisaHariManual
                ),

                const SizedBox(height: 20),
                _buildRiwayatCard(data, lastServiceDate, lastServiceOdo),
                const SizedBox(height: 20),
                _buildWorkshopCTA(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI KARTU ESTIMASI ---
  Widget _buildEstimationCard(DateTime nextDate, String badge, Color color, String saran, List<String> tags, int diff, int limit, int sisaKm, int sisaHari) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Estimasi Servis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFFFFF9F2), borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRowDetail("Tgl Estimasi", ": ${DateFormat('dd MMMM yyyy').format(nextDate)}"),
                _buildRowDetail("Pemakaian", ": $diff / $limit KM"),
                _buildRowDetail("Sisa Umur", ": ${sisaKm > 0 ? sisaKm : 0} KM / ${sisaHari > 0 ? sisaHari : 0} Hari"),
                const SizedBox(height: 12),
                Text("SARAN:", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                Text(saran, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: tags.map((t) => _buildTag(t)).toList(),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- UI KARTU RIWAYAT ---
  Widget _buildRiwayatCard(Map<String, dynamic> data, DateTime lastDate, int lastOdo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Riwayat Terakhir", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.history, color: Colors.blue)),
            title: Text(data['last_service_type'] ?? data['service_type'] ?? "Servis Awal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text("${DateFormat('dd MMM yyyy').format(lastDate)} • $lastOdo KM"),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildHeader(Map<String, dynamic> data) {
    String type = (data['jenis_kendaraan'] ?? data['type'] ?? 'mobil').toString().toLowerCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon((type == 'motor') ? Icons.motorcycle : Icons.directions_car, color: Colors.red[700], size: 40),
            Text(data['nama_kendaraan'] ?? "Tanpa Nama", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(data['plat'] ?? "-", style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
        if (data['photo_url'] != null)
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(data['photo_url'], width: 140, height: 90, fit: BoxFit.contain))
        else
          const Icon(Icons.image, size: 80, color: Colors.grey),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200));

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13))),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Widget _buildTag(String text) => Container(
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFE8FDF0), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(color: Color(0xFF5CB85C), fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _buildWorkshopCTA() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text("Cari Bengkel Terdekat", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );
}