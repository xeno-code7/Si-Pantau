import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../car/car_detail_screen.dart';
import 'workshop_screen.dart';
import 'service_dashboard_screen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  bool _isSelectingVehicle = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Jika sedang mode pilih kendaraan, tampilkan halaman seleksi
    if (_isSelectingVehicle) {
      return _buildVehicleSelection();
    }

    // Default: Tampilkan daftar monitoring servis
    return _isSelectingVehicle
        ? _buildVehicleSelection()
        : _buildServiceList(user, isDarkMode, textColor);
  }

  Widget _buildServiceList(User? user, bool isDarkMode, Color textColor) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MONITORING SERVIS",
            style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
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
            return _buildEmptyState(textColor);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isSelectingVehicle = true;
          });
        },
        backgroundColor: const Color(0xFF5CB85C),
        icon: const Icon(Icons.build, color: Colors.white),
        label: const Text("Dashboard Servis",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text("Pilih Kendaraan",
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
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
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5CB85C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Data kendaraan tidak ditemukan."));
          }

          // Filter data berdasarkan input di Search Bar (MENGGUNAKAN NAMA KENDARAAN)
          var filteredDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // FIX: Menggunakan 'nama_kendaraan' bukan 'merk'
            String nama =
                (data['nama_kendaraan'] ?? "").toString().toLowerCase();
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
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
