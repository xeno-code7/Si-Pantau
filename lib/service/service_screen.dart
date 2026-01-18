import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORT FILE LAIN ---
import '../car/car_detail_screen.dart';
import 'workshop_screen.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Cek Dark Mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Tentukan warna teks (Hitam di Light Mode, Putih di Dark Mode)
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("MONITORING SERVIS",
            style: GoogleFonts.poppins(
                // [UBAH DISINI] Jadi warna Hitam/Putih
                color: textColor,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            // [UBAH DISINI] Ikon juga mengikuti warna teks
            icon: Icon(Icons.map_outlined, color: textColor),
            tooltip: "Cari Bengkel Terdekat",
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const WorkshopScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('cars')
            .orderBy('prediksi_rul', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
                textColor); // Kirim warna teks ke fungsi empty state
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String docId = doc.id;

              return _buildServiceCard(context, docId, data, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isDark) {
    double rul = double.tryParse(data['prediksi_rul']?.toString() ?? "0") ?? 0;
    String jenis = data['jenis_kendaraan'] ?? "mobil";

    Color statusColor = Colors.green;
    String statusText = "AMAN";

    if (rul <= 200) {
      statusColor = Colors.red;
      statusText = "BAHAYA (SEGERA SERVIS)";
    } else if (rul <= 1000) {
      statusColor = Colors.orange;
      statusText = "PERSIAPAN SERVIS";
    }

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigasi ke Detail Mobil
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      CarDetailScreen(docId: docId, initialData: data)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      jenis.toLowerCase() == 'mobil'
                          ? Icons.directions_car
                          : Icons.two_wheeler,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['nama_kendaraan'] ?? "Tanpa Nama",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(data['plat'] ?? "No Plat",
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "${rul.toStringAsFixed(0)} KM lagi",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (rul / 5000).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ketuk untuk detail servis >",
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontStyle: FontStyle.italic)),
                  Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada data kendaraan",
              style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}
