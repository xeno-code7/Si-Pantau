import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Import halaman Riwayat (FuelScreen)
import 'fuel_screen.dart';

class FuelCarSelectionScreen extends StatefulWidget {
  const FuelCarSelectionScreen({super.key});

  @override
  State<FuelCarSelectionScreen> createState() => _FuelCarSelectionScreenState();
}

class _FuelCarSelectionScreenState extends State<FuelCarSelectionScreen> {
  // [1] Variabel Pencarian
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Pilih Kendaraan",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // [2] KOLOM PENCARIAN
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Cari nama atau plat nomor...",
                hintStyle:
                    GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: Color(0xFF5CB85C), width: 1),
                ),
              ),
            ),
          ),

          // [3] LIST KENDARAAN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('cars')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF5CB85C)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car_outlined,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Belum ada kendaraan",
                            style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // [4] LOGIKA FILTER LIST
                var allCars = snapshot.data!.docs;
                var filteredCars = allCars.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = (data['nama_kendaraan'] ?? data['merk'] ?? "")
                      .toString()
                      .toLowerCase();
                  String plat = (data['plat'] ?? "").toString().toLowerCase();
                  String query = _searchText.toLowerCase();

                  return nama.contains(query) || plat.contains(query);
                }).toList();

                if (filteredCars.isEmpty) {
                  return Center(
                    child: Text("Kendaraan tidak ditemukan",
                        style: GoogleFonts.poppins(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredCars.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredCars[index].data() as Map<String, dynamic>;
                    String docId = filteredCars[index].id;

                    String nama =
                        data['nama_kendaraan'] ?? data['merk'] ?? "Tanpa Nama";
                    String plat = data['plat'] ?? "No Plat";
                    String? photoUrl = data['photo_url'];

                    return GestureDetector(
                      onTap: () {
                        // Navigasi ke FuelScreen (Riwayat & Statistik)
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    FuelScreen(carId: docId, carName: nama)));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Row(
                          children: [
                            // Foto Mobil
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[200],
                                  image: photoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(photoUrl),
                                          fit: BoxFit.cover)
                                      : null),
                              child: photoUrl == null
                                  ? const Icon(Icons.directions_car,
                                      color: Colors.grey, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            // Info Mobil
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nama,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(plat,
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 14)),
                                ],
                              ),
                            ),

                            // Panah
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
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
}
