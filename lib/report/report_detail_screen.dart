import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// [1] IMPORT EXPENSE SCREEN
import '../expense/expense_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> carData;

  const ReportDetailScreen(
      {super.key, required this.docId, required this.carData});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final data = widget.carData;
    final String nama = data['nama_kendaraan'] ?? "-";
    final String plat = data['plat'] ?? "-";
    final String tahun = data['tahun']?.toString() ?? "-";
    final String warna = data['warna'] ?? "-";
    final int odo = data['odo'] ?? 0;
    final String? photoUrl = data['photo_url'];

    String pajakStr = "-";
    if (data['pajak'] is Timestamp) {
      pajakStr = DateFormat('dd MMMM yyyy', 'id_ID')
          .format((data['pajak'] as Timestamp).toDate());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Detail Laporan",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            _buildSectionTitle("Informasi Umum"),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.stars, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        Text("KENDARAAN",
                            style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ]),
                      Text(plat,
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(nama,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("$tahun $warna",
                          style: GoogleFonts.poppins(
                              color: Colors.grey[600], fontSize: 12)),
                      Text("Odometer: ${NumberFormat("#,###").format(odo)} KM",
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("Pajak berlaku s/d : $pajakStr",
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(photoUrl, fit: BoxFit.cover))
                      : const Icon(Icons.directions_car,
                          size: 80, color: Colors.grey),
                )
              ],
            ),

            const SizedBox(height: 25),

            // --- RIWAYAT SERVICE ---
            _buildSectionTitle("Riwayat Service"),
            const SizedBox(height: 10),
            _buildServiceHistoryTable(),

            const SizedBox(height: 25),

            // --- RIWAYAT KERUSAKAN ---
            _buildSectionTitle("Riwayat Kerusakan"),
            const SizedBox(height: 10),
            _buildDamageHistoryTable(),

            const SizedBox(height: 25),

            // --- RIWAYAT BBM ---
            _buildSectionTitle("Riwayat Bahan Bakar"),
            const SizedBox(height: 10),
            _buildFuelHistoryTable(),

            const SizedBox(height: 30),

            // [2] TOMBOL LIHAT SELENGKAPNYA
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  // Navigasi ke Expense Screen dengan filter ID Mobil ini
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ExpenseScreen(carIdFilter: widget.docId)));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Lihat Selengkapnya",
                        style: GoogleFonts.poppins(
                            color: Colors.orange, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_forward,
                        color: Colors.orange, size: 18)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET TABLES ---

  // 1. UPDATE TABEL SERVICE
  Widget _buildServiceHistoryTable() {
    return _buildStreamTable(
      collection: 'expenses',
      queryModifier: (q) => q
          .where('carId', isEqualTo: widget.docId)
          .where('category', isEqualTo: 'Servis Rutin') // <--- SUDAH DIUPDATE
          .limit(3),
      headers: ["Tanggal", "Jenis Service", "Deskripsi"],
      builder: (data) {
        DateTime date = (data['date'] as Timestamp).toDate();
        return [
          DateFormat('d MMM yy', 'id_ID').format(date),
          "Servis Rutin",
          data['note'] ?? data['title'] ?? "-",
        ];
      },
    );
  }

  // 2. UPDATE TABEL KERUSAKAN
  Widget _buildDamageHistoryTable() {
    return _buildStreamTable(
      collection: 'expenses',
      queryModifier: (q) => q
          .where('carId', isEqualTo: widget.docId)
          .where('category',
              isEqualTo: 'Perbaikan / Kerusakan') // <--- SUDAH DIUPDATE
          .limit(3),
      headers: ["Tanggal", "Kerusakan", "Status"],
      builder: (data) {
        DateTime date = (data['date'] as Timestamp).toDate();
        return [
          DateFormat('d MMM yy', 'id_ID').format(date),
          data['title'] ?? "Perbaikan",
          "Selesai",
        ];
      },
    );
  }

  Widget _buildFuelHistoryTable() {
    return _buildStreamTable(
      collection: 'fuel_logs',
      queryModifier: (q) => q
          .where('carId', isEqualTo: widget.docId)
          .orderBy('date', descending: true)
          .limit(3),
      headers: ["Tanggal", "BBM", "Liter"],
      builder: (data) {
        DateTime date = (data['date'] as Timestamp).toDate();
        return [
          DateFormat('d MMM yy', 'id_ID').format(date),
          data['fuelType'] ?? "-",
          "${data['liters']} L",
        ];
      },
    );
  }

  Widget _buildStreamTable({
    required String collection,
    required Query Function(Query) queryModifier,
    required List<String> headers,
    required List<String> Function(Map<String, dynamic>) builder,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: queryModifier(FirebaseFirestore.instance.collection(collection))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8)),
            child: Text("Tidak ada data",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          );
        }
        return Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8))),
                child: Row(
                  children: headers
                      .map((h) => Expanded(
                          child: Text(h,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                              textAlign: TextAlign.center)))
                      .toList(),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              ...snapshot.data!.docs.map((doc) {
                final rowData = builder(doc.data() as Map<String, dynamic>);
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: rowData
                        .map((cell) => Expanded(
                            child: Text(cell,
                                style: GoogleFonts.poppins(fontSize: 11),
                                textAlign: TextAlign.center)))
                        .toList(),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(
            color: const Color(0xFF5CB85C),
            fontSize: 16,
            fontWeight: FontWeight.bold));
  }
}
