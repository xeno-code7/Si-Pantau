import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
// Pastikan import ini sesuai dengan nama file dashboard kamu
import 'service_dashboard_screen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  // Flag untuk berpindah antara tampilan awal dan daftar kendaraan
  bool _isSelectingVehicle = false;

  // Controller dan variabel untuk fitur search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika tombol 'Pilih Kendaraan' ditekan, tampilkan daftar pemilih
    return _isSelectingVehicle ? _buildVehicleSelection() : _buildEmptyState();
  }

  // --- 1. TAMPILAN AWAL (EMPTY STATE) ---
  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SERVICE",
            style: TextStyle(
                color: Color(0xFF5CB85C),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text("Tidak ada kendaraan yang\nsedang dipilih",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSelectingVehicle = true;
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CB85C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Pilih Kendaraan", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // --- 2. TAMPILAN DAFTAR KENDARAAN (WITH SEARCH) ---
  Widget _buildVehicleSelection() {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () {
            setState(() {
              _isSelectingVehicle = false;
              _searchQuery = "";
              _searchController.clear();
            });
          },
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: const InputDecoration(
              hintText: "Cari Nama atau Plat",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5CB85C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Data kendaraan tidak ditemukan."));
          }

          // Filter data berdasarkan input di Search Bar (MENGGUNAKAN NAMA KENDARAAN)
          var filteredDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // FIX: Menggunakan 'nama_kendaraan' bukan 'merk'
            String nama = (data['nama_kendaraan'] ?? "").toString().toLowerCase();
            String plat = (data['plat'] ?? "").toString().toLowerCase();
            return nama.contains(_searchQuery) || plat.contains(_searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(child: Text("Kendaraan tidak ditemukan."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var data = filteredDocs[index].data() as Map<String, dynamic>;
              String docId = filteredDocs[index].id;
              return _buildVehicleCard(docId, data);
            },
          );
        },
      ),
    );
  }

  // --- 3. WIDGET KARTU KENDARAAN ---
  Widget _buildVehicleCard(String id, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.directions_car, size: 28, color: Colors.red),
                const SizedBox(height: 4),
                // FIX: Typo 'Text(x' dihapus dan ganti field jadi 'nama_kendaraan'
                Text(
                  data['nama_kendaraan'] ?? 'Tanpa Nama',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data['plat'] ?? '-',
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 100,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      // PINDAH KE HALAMAN DASHBOARD SERVICE
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDashboardScreen(
                            carId: id,
                            carData: data,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF67C97F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text("Pilih",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: data['photo_url'] != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                data['photo_url'],
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 50),
              ),
            )
                : const Icon(Icons.image, size: 80, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}