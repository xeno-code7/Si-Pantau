import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'fuel_add_screen.dart';

class FuelScreen extends StatefulWidget {
  final String carId;
  final String carName;

  const FuelScreen({super.key, required this.carId, required this.carName});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  DateTimeRange? _selectedDateRange;

  // Fungsi Pilih Tanggal
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF5CB85C), onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  void _resetDateFilter() => setState(() => _selectedDateRange = null);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text("Riwayat BBM",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87)),
            Text(widget.carName,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month,
                color: _selectedDateRange != null
                    ? const Color(0xFF5CB85C)
                    : Colors.grey),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fuel_logs')
            .where('carId', isEqualTo: widget.carId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5CB85C)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var allDocs = snapshot.data!.docs;
          var filteredDocs = allDocs;

          // LOGIKA FILTER TANGGAL
          if (_selectedDateRange != null) {
            filteredDocs = allDocs.where((doc) {
              DateTime date = (doc['date'] as Timestamp).toDate();
              return date.isAfter(_selectedDateRange!.start
                      .subtract(const Duration(days: 1))) &&
                  date.isBefore(
                      _selectedDateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }

          if (filteredDocs.isEmpty) return _buildEmptyState(isFiltered: true);

          // [STATISTIK DIHITUNG DISINI]
          double totalCost = 0;
          double totalLiters = 0;
          int fillCount = filteredDocs.length;

          for (var doc in filteredDocs) {
            totalCost += (doc['totalPrice'] as num).toDouble();
            totalLiters += (doc['liters'] as num).toDouble();
          }

          String dateLabel = "Semua Riwayat";
          if (_selectedDateRange != null) {
            dateLabel =
                "${DateFormat('d MMM').format(_selectedDateRange!.start)} - ${DateFormat('d MMM').format(_selectedDateRange!.end)}";
          }

          return Column(
            children: [
              // Indikator Tanggal
              if (_selectedDateRange != null)
                Container(
                  color: const Color(0xFF5CB85C).withOpacity(0.1),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter: $dateLabel",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF5CB85C))),
                      GestureDetector(
                          onTap: _resetDateFilter,
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFF5CB85C)))
                    ],
                  ),
                ),

              // [KARTU STATISTIK HIJAU] - Pastikan bagian ini ada di kodemu
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5CB85C), Color(0xFF4CAE4C)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF5CB85C).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                        "Total Biaya",
                        currencyFormatter.format(totalCost),
                        Icons.monetization_on),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _buildStatItem(
                        "Total Liter",
                        "${totalLiters.toStringAsFixed(1)} L",
                        Icons.water_drop),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _buildStatItem(
                        "Frekuensi", "$fillCount Kali", Icons.history),
                  ],
                ),
              ),

              // DAFTAR RIWAYAT
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    DateTime date = (data['date'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF5CB85C).withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.local_gas_station,
                              color: Color(0xFF5CB85C)),
                        ),
                        title: Text(
                            currencyFormatter.format(data['totalPrice']),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                            "${DateFormat('dd MMM yyyy').format(date)} • ${data['liters']} Liter",
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5CB85C),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FuelAddScreen(carId: widget.carId, carName: widget.carName),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_gas_station_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
              isFiltered
                  ? "Tidak ada data pada tanggal ini"
                  : "Belum ada riwayat BBM",
              style: GoogleFonts.poppins(color: Colors.grey)),
          if (!isFiltered) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FuelAddScreen(
                        carId: widget.carId, carName: widget.carName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CB85C),
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
              label: const Text("Catat BBM"),
            )
          ]
        ],
      ),
    );
  }
}
