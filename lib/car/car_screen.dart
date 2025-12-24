import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'car_detail_screen.dart';

class CarScreen extends StatelessWidget {
  const CarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "PILIH KENDARAAN",
          style: TextStyle(
            color: Color(0xFF5CB85C),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return _emptyState();
          }

          final cars = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final doc = cars[index];
              final data = doc.data() as Map<String, dynamic>;

              return _carCard(
                context: context,
                docId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_filled_outlined,
              size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            "Belum ada kendaraan\nSilakan tambahkan kendaraan",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ================= CARD KENDARAAN =================
  Widget _carCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final String jenis = data['jenis_kendaraan'] ?? "motor";
    final String nama = data['nama_kendaraan'] ?? data['merk'] ?? "-";
    final String plat = data['plat'] ?? "-";

    final int odo =
        int.tryParse(data['odo']?.toString() ?? "0") ?? 0;

    final String? photoUrl = data['photo_url'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF5CB85C).withOpacity(0.15),
          backgroundImage:
              photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(
                  jenis == "motor"
                      ? Icons.motorcycle
                      : Icons.directions_car,
                  color: const Color(0xFF5CB85C),
                )
              : null,
        ),
        title: Text(
          nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("$plat • $odo KM"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // PILIH KENDARAAN → DETAIL
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarDetailScreen(
                docId: docId,
                initialData: data,
              ),
            ),
          );
        },
      ),
    );
  }
}
