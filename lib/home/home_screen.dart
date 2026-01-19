import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// [1] IMPORT UTILS
import '../utils/reminder_manager.dart';
import '../utils/notification_helper.dart'; // Pastikan ini di-import agar tombol lonceng jalan

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
                // [3] TOMBOL LONCENG (SUDAH DIPERBAIKI)
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: textColor),
                  onPressed: () {
                    // Panggil Notifikasi Test
                    NotificationHelper.sendServiceReminder(
                      nama: "Test Lonceng Home",
                      plat: "H 9999 TES",
                      sisaKm: 500,
                      sisaHari: 7,
                    );

                    // Tampilkan pesan konfirmasi di bawah
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Test Notifikasi dikirim! Cek Status Bar HP."),
                        backgroundColor: Color(0xFF5CB85C),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
                          final String plat =
                              (data['plat'] ?? "").toString().toLowerCase();
                          final String nama = (data['nama_kendaraan'] ?? "")
                              .toString()
                              .toLowerCase();

                          final String searchLower = _searchText.toLowerCase();

                          return plat.contains(searchLower) ||
                              nama.contains(searchLower);
                        }).toList();

                        if (filteredCars.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text("Kendaraan tidak ditemukan",
                                    style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 4),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredCars.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final carData = filteredCars[index].data()
                                      as Map<String, dynamic>;
                                  final docId = filteredCars[index].id;

                                  return _buildCarCard(
                                    context,
                                    carData,
                                    docId,
                                    textColor,
                                    cardColor,
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
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

  // WIDGET HELPER MENU ITEM
  Widget _buildMenuItem(IconData icon, String label, Color iconColor,
      Color textColor, Color bgColor,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, size: 35, color: iconColor),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12, color: textColor))
        ]),
      ),
    );
  }

  // WIDGET HELPER KARTU MOBIL
  Widget _buildCarCard(BuildContext context, Map<String, dynamic> carData,
      String docId, Color textColor, Color cardColor) {
    String plat = carData['plat'] ?? "No Plat";
    String merk = carData['nama_kendaraan'] ?? carData['merk'] ?? "No Merk";
    String? photoUrl = carData['photo_url'];

    return Container(
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: photoUrl != null
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Icon(Icons.directions_car_filled,
                      size: 60, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 8),
          Text(plat,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(merk,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarDetailScreen(
                      docId: docId,
                      initialData: carData,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFF5CB85C),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}
