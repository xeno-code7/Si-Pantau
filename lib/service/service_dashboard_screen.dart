import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

          // --- 1. LOGIKA IDENTIFIKASI KENDARAAN ---
          String type = (data['type'] ?? 'mobil').toString().toLowerCase();

          // --- 2. LOGIKA ESTIMASI WAKTU (BULAN) ---
          DateTime lastServiceDate = (data['last_service_date'] as Timestamp).toDate();
          int intervalMonth = (type == 'motor') ? 2 : 6;
          DateTime nextServiceDate = DateTime(lastServiceDate.year, lastServiceDate.month + intervalMonth, lastServiceDate.day);
          bool isTimeOverdue = DateTime.now().isAfter(nextServiceDate);

          // --- 3. LOGIKA SARAN BERDASARKAN ODOMETER (KM) ---
          int currentOdo = data['odometer'] ?? 0; // Odometer saat ini (dari input journey/fuel)
          int lastServiceOdo = data['last_service_odo'] ?? 0; // Odometer saat servis terakhir
          int odoDiff = currentOdo - lastServiceOdo;

          // Ambang batas ganti oli (Motor: 3000km, Mobil: 10000km)
          int oilThreshold = (type == 'motor') ? 3000 : 10000;
          bool isOdoOverdue = odoDiff >= oilThreshold;

          // --- 4. PENENTUAN STATUS & SARAN ---
          String statusBadge = "Jadwal Aman";
          Color statusColor = Colors.green;
          String saranUtama = "Perawatan Rutin";
          List<String> checkList = [];

          if (isTimeOverdue || isOdoOverdue) {
            statusBadge = isTimeOverdue ? "Lewat Waktu" : "Limit KM Tercapai";
            statusColor = Colors.red;
            saranUtama = "WAKTUNYA GANTI OLI"; // Saran berubah jadi Ganti Oli jika limit tercapai
            checkList = (type == 'motor')
                ? ["Ganti Oli Mesin", "Cek Rantai", "Cek Rem"]
                : ["Ganti Oli Mesin", "Filter Oli", "Cek General"];
          } else {
            checkList = (type == 'motor')
                ? ["Cek Tekanan Ban", "Pembersihan"]
                : ["Cek Air Radiator", "Cek Wiper"];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data),
                const SizedBox(height: 24),

                // --- BAGIAN ESTIMASI & SARAN ---
                _buildEstimationCard(nextServiceDate, statusBadge, statusColor, saranUtama, checkList, odoDiff, oilThreshold),

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

  // --- UI KARTU ESTIMASI & SARAN ---
  Widget _buildEstimationCard(DateTime nextDate, String badge, Color color, String saran, List<String> tags, int diff, int limit) {
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
            title: Text(data['last_service_type'] ?? "Servis Awal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text("${DateFormat('dd MMM yyyy').format(lastDate)} • $lastOdo KM"),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildHeader(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon((data['type'] == 'motor') ? Icons.motorcycle : Icons.directions_car, color: Colors.red[700], size: 40),

            // FIX: Menggunakan 'nama_kendaraan' agar tidak muncul "Unit"
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