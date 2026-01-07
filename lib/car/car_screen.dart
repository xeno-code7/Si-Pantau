import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import JourneyScreen
import '../service/journey_screen.dart'; 

class CarScreen extends StatelessWidget {
  const CarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // --- LOGIC DARK MODE ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final fieldColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg, // Dinamis mengikuti tema
      appBar: AppBar(
        title: const Text(
          "PILIH KENDARAAN",
          style: TextStyle(
            color: Color(0xFF5CB85C), // Tetap Hijau khas SIPANTAU
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
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
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Cari",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: fieldColor, // Warna input field dinamis
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
                    child: Text("Belum ada kendaraan", style: TextStyle(color: textColor)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _carCard(
                      context: context,
                      docId: doc.id,
                      data: data,
                      isDarkMode: isDarkMode, // Kirim status tema ke card
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor, // Dinamis: Putih (Light) atau Abu Gelap (Dark)
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black38 : Colors.black.withValues(alpha: 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 5)
          ),
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
                Text(
                  nama, 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
                ),
                Text(
                  plat, 
                  style: const TextStyle(color: Colors.grey)
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: 100,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
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
                      backgroundColor: const Color(0xFF8CC67E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Pilih", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: photoUrl != null 
                ? Image.network(photoUrl, fit: BoxFit.contain) 
                : const Icon(Icons.directions_car, size: 80, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}