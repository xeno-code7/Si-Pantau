import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_detail_screen.dart'; // Kita akan buat file ini setelahnya

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu terang
      appBar: AppBar(
        title: Text(
          "Laporan",
          style: GoogleFonts.poppins(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('cars')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5CB85C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child:
                    Text("Belum ada kendaraan", style: GoogleFonts.poppins()));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildCarReportCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCarReportCard(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final String nama = data['nama_kendaraan'] ?? "Kendaraan";
    final String plat = data['plat'] ?? "-";
    final String? photoUrl = data['photo_url'];
    // Ambil brand dari nama (misal "Toyota Innova" -> "TOYOTA")
    final String brand = nama.split(" ")[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KOLOM KIRI (INFO & TOMBOL) ---
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Brand (Simulasi Text karena tidak ada aset logo)
                Row(
                  children: [
                    const Icon(Icons.stars,
                        color: Colors.red, size: 16), // Placeholder logo
                    const SizedBox(width: 4),
                    Text(brand,
                        style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),

                // Nama Mobil
                Text(nama,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                // Plat Nomor
                Text(plat,
                    style:
                        GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),

                const SizedBox(height: 16),

                // Tombol Lihat Laporan
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF5CB85C), // Warna Hijau sesuai desain
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReportDetailScreen(docId: docId, carData: data),
                        ),
                      );
                    },
                    child: Text("Lihat Laporan",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          ),

          // --- KOLOM KANAN (GAMBAR MOBIL) ---
          Expanded(
            flex: 5,
            child: photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        Image.network(photoUrl, height: 80, fit: BoxFit.cover),
                  )
                : Image.asset('assets/car_placeholder.png',
                    height: 80,
                    errorBuilder: (c, o, s) => const Icon(Icons.directions_car,
                        size: 80, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
