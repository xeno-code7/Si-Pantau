import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// [1] IMPORT GOOGLE FONTS
import 'package:google_fonts/google_fonts.dart';

import '../service/trip_service.dart'; // Import TripService
// Import JourneyScreen
import '../service/journey_screen.dart';

class CarScreen extends StatefulWidget {
  const CarScreen({super.key});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen> {
  // [1] VARIABEL PENCARIAN
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // --- LOGIC DARK MODE ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Warna teks mengikuti tema (Hitam di Light Mode, Putih di Dark Mode)
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final fieldColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        // [2] UPDATE STYLE JUDUL DISINI (Samakan dengan ServiceScreen)
        title: Text(
          "PILIH KENDARAAN",
          style: GoogleFonts.poppins(
            color: textColor, // Menggunakan textColor (Hitam/Putih)
            fontWeight: FontWeight.w900, // Sangat Tebal
            fontStyle: FontStyle.italic, // Miring
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController, // [2] Controller
              style: TextStyle(color: textColor),
              // [3] Logika Update State saat mengetik
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Cari plat nomor atau nama...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // Tombol Clear (X)
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchText = "";
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: fieldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('cars')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("Belum ada kendaraan",
                        style: TextStyle(color: textColor)),
                  );
                }

                // [4] LOGIKA FILTER PENCARIAN (Sama dengan Home)
                final allCars = snapshot.data!.docs;

                final filteredCars = allCars.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String plat =
                      (data['plat'] ?? "").toString().toLowerCase();
                  final String nama =
                      (data['nama_kendaraan'] ?? "").toString().toLowerCase();
                  final String searchLower = _searchText.toLowerCase();

                  // Filter: Plat ATAU Nama mengandung teks pencarian
                  return plat.contains(searchLower) ||
                      nama.contains(searchLower);
                }).toList();

                // Jika hasil pencarian kosong
                if (filteredCars.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Kendaraan tidak ditemukan",
                            style: TextStyle(color: textColor)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount:
                      filteredCars.length, // Gunakan list yang sudah difilter
                  itemBuilder: (context, index) {
                    final doc = filteredCars[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _carCard(
                      context: context,
                      docId: doc.id,
                      data: data,
                      isDarkMode: isDarkMode,
                      textColor: textColor,
                      cardColor: cardColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _carCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
    required bool isDarkMode,
    required Color textColor,
    required Color cardColor,
  }) {
    final String nama = data['nama_kendaraan'] ?? "-";
    final String plat = data['plat'] ?? "-";
    final String? photoUrl = data['photo_url'];
    // [BARU] Cek status apakah sedang dipakai
    final bool isUsed = data['is_used'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: isDarkMode
                  ? Colors.black38
                  : Colors.black.withOpacity(
                      0.05), // Perbaikan withValues -> withOpacity untuk kompatibilitas
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.stars, color: Colors.red, size: 30),
                const SizedBox(height: 8),
                Text(nama,
                    maxLines: 2, // Batasi 2 baris
                    overflow:
                        TextOverflow.ellipsis, // Titik-titik jika kepanjangan
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text(plat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 100,
                  height: 35,
                  child: ElevatedButton(
                    // [BARU] Disable tombol jika sedang dipakai
                    onPressed: isUsed
                        ? null
                        : () {
                            // 1. Aktifkan Status Perjalanan Global
                            TripService().startTrip(docId, data);

                            // 2. Pindah ke halaman Journey
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JourneyScreen(
                                  vehicleId: docId,
                                  vehicleData: data,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      // Ubah warna jadi abu-abu jika disabled
                      backgroundColor:
                          isUsed ? Colors.grey : const Color(0xFF8CC67E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(isUsed ? "Dipakai" : "Pilih",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: photoUrl != null
                ? Image.network(photoUrl, fit: BoxFit.contain)
                : const Icon(Icons.directions_car,
                    size: 80, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
