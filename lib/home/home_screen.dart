import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// [1] IMPORT UTILS
import '../utils/reminder_manager.dart';
import '../home/notification_screen.dart';

// --- IMPORT HALAMAN-HALAMAN ---
import '../car/car_detail_screen.dart';
import '../car/car_add_screen.dart';
import '../profile/profile_screen.dart';
import 'fuel_car_selection_screen.dart';
import '../expense/expense_screen.dart';
import '../report/report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // [2] INIT STATE: MENJALANKAN PENGECEKAN NOTIFIKASI OTOMATIS
  @override
  void initState() {
    super.initState();
    _initAutomatedReminders();
  }

  Future<void> _initAutomatedReminders() async {
    // Beri jeda 3 detik agar aplikasi loading UI dulu baru hitung notifikasi background
    await Future.delayed(const Duration(seconds: 3));
    await ReminderManager.setupAutomatedReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String username = "Fauzi";
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? "Fauzi";
            photoUrl = data['photo_url'];
          }

          photoUrl = photoUrl ?? user?.photoURL;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text("SIPANTAU",
                  style: GoogleFonts.sansita(
                      color: const Color(0xFF5CB85C),
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 35,
                      letterSpacing: 1.5)),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: textColor),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationScreen()));
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF5CB85C),
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                )
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BAGIAN FIXED (ATAS) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Selamat datang, $username👋",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 16),

                      // TEXT FIELD PENCARIAN
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchText = "";
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          hintText: "Cari plat nomor... (Contoh: H)",
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: cardColor,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text("Menu Informasi",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMenuItem(
                            Icons.local_gas_station,
                            "Bahan Bakar",
                            Colors.indigo,
                            textColor,
                            cardColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const FuelCarSelectionScreen()),
                              );
                            },
                          ),
                          _buildMenuItem(
                            Icons.monetization_on,
                            "Pengeluaran",
                            Colors.red,
                            textColor,
                            cardColor,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ExpenseScreen()));
                            },
                          ),
                          _buildMenuItem(
                            Icons.description,
                            "Laporan",
                            Colors.blue,
                            textColor,
                            cardColor,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ReportScreen()));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Header Daftar Mobil
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Informasi Kendaraan",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CarAddScreen()));
                            },
                            child: const Icon(Icons.add_circle,
                                color: Colors.orange, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- BAGIAN SCROLL (BAWAH) - DAFTAR MOBIL ---
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('cars')
                          .orderBy('created_at', descending: true)
                          .snapshots(),
                      builder: (context, carSnapshot) {
                        if (carSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!carSnapshot.hasData ||
                            carSnapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined,
                                    size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text("Belum ada kendaraan",
                                    style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          );
                        }

                        // LOGIKA FILTER PENCARIAN
                        final allCars = carSnapshot.data!.docs;
                        final filteredCars = allCars.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final plat =
                              (data['plat'] ?? "").toString().toLowerCase();
                          final merk =
                              (data['merk'] ?? "").toString().toLowerCase();
                          return plat.contains(_searchText.toLowerCase()) ||
                              merk.contains(_searchText.toLowerCase());
                        }).toList();

                        if (filteredCars.isEmpty) {
                          return Center(
                              child: Text(
                                  "Tidak ditemukan kendaraan dengan plat '$_searchText'",
                                  style: TextStyle(color: Colors.grey[500])));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          itemCount: filteredCars.length,
                          itemBuilder: (context, index) {
                            final doc = filteredCars[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildCarCard(
                                context, doc.id, data, textColor, cardColor);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  // --- WIDGET ITEM MENU (KOTAK WARNA-WARNI) ---
  Widget _buildMenuItem(IconData icon, String label, Color color,
      Color textColor, Color cardColor,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KARTU MOBIL ---
  Widget _buildCarCard(BuildContext context, String docId,
      Map<String, dynamic> data, Color textColor, Color cardColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    CarDetailScreen(docId: docId, initialData: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            // FOTO MOBIL
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                image: data['photo_url'] != null
                    ? DecorationImage(
                        image: NetworkImage(data['photo_url']),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: data['photo_url'] == null
                  ? Icon(Icons.directions_car,
                      size: 40, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 16),

            // INFO MOBIL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['nama_kendaraan'] ?? "Tanpa Nama",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(data['plat'] ?? "-",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.7))),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
