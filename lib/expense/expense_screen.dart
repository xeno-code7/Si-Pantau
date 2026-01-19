import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'expense_add_screen.dart';

class ExpenseScreen extends StatefulWidget {
  final String? carIdFilter;

  const ExpenseScreen({super.key, this.carIdFilter});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Variabel Filter
  String? _selectedCarId;
  String _displayTitle = "Semua Pengeluaran";

  // Variabel Tanggal
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedCarId = widget.carIdFilter;
    if (_selectedCarId != null) {
      _displayTitle = "Riwayat Mobil Ini";
    }
  }

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
              primary: Color(0xFF5CB85C),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  // Fungsi Reset Tanggal
  void _resetDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  // [UPDATE TERBARU] Fungsi Filter Modal dengan PENCARIAN
  void _showFilterModal() {
    String localSearchQuery = ""; // Variabel lokal untuk pencarian

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Agar modal bisa lebih tinggi jika keyboard muncul
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // StatefulBuilder digunakan agar kita bisa update tampilan DI DALAM modal saja
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            height: 500, // Tinggi modal
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Filter Kendaraan",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // [BARU] Search Bar
                TextField(
                  onChanged: (value) {
                    setModalState(() {
                      // Update state modal
                      localSearchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Cari nama atau plat nomor...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('cars')
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      var allCars = snapshot.data!.docs;

                      // [LOGIKA FILTER PENCARIAN]
                      var filteredCars = allCars.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String carName =
                            (data['nama_kendaraan'] ?? "").toLowerCase();
                        String plat = (data['plat'] ?? "").toLowerCase();

                        return carName.contains(localSearchQuery) ||
                            plat.contains(localSearchQuery);
                      }).toList();

                      if (filteredCars.isEmpty && localSearchQuery.isNotEmpty) {
                        return Center(
                            child: Text("Tidak ditemukan",
                                style:
                                    GoogleFonts.poppins(color: Colors.grey)));
                      }

                      return ListView(
                        children: [
                          // OPSI SEMUA KENDARAAN (Hanya muncul jika tidak sedang mencari spesifik)
                          if (localSearchQuery.isEmpty)
                            ListTile(
                              leading:
                                  const Icon(Icons.apps, color: Colors.grey),
                              title: Text("Semua Kendaraan",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                              trailing: _selectedCarId == null
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF5CB85C))
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCarId = null;
                                  _displayTitle = "Semua Pengeluaran";
                                });
                                Navigator.pop(context);
                              },
                            ),
                          if (localSearchQuery.isEmpty) const Divider(),

                          // LOOP DAFTAR MOBIL
                          ...filteredCars.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            String carName = data['nama_kendaraan'] ??
                                data['merk'] ??
                                "Mobil";
                            String plat = data['plat'] ?? "-";

                            bool isSelected = _selectedCarId == doc.id;

                            return ListTile(
                              leading: Icon(Icons.directions_car,
                                  color: isSelected
                                      ? const Color(0xFF5CB85C)
                                      : Colors.grey),
                              title: Text(carName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(plat,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[600], fontSize: 12)),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF5CB85C))
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCarId = doc.id;
                                  _displayTitle = "$carName ($plat)";
                                });
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Query Database
    Query query = FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user?.uid);
    if (_selectedCarId != null) {
      query = query.where('carId', isEqualTo: _selectedCarId);
    }
    query = query.orderBy('date', descending: true);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            Text("Pengeluaran",
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(_displayTitle,
                style: GoogleFonts.poppins(
                    color: const Color(0xFF5CB85C), fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // TOMBOL FILTER MOBIL
          IconButton(
            icon: Icon(Icons.filter_alt_outlined,
                color: _selectedCarId != null ? Colors.orange : Colors.grey),
            onPressed: _showFilterModal,
          ),
          // TOMBOL FILTER TANGGAL
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
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5CB85C)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // [LOGIKA FILTER TANGGAL]
          var allDocs = snapshot.data!.docs;
          var filteredDocs = allDocs;

          if (_selectedDateRange != null) {
            filteredDocs = allDocs.where((doc) {
              DateTime date = (doc['date'] as Timestamp).toDate();
              return date.isAfter(_selectedDateRange!.start
                      .subtract(const Duration(days: 1))) &&
                  date.isBefore(
                      _selectedDateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Tidak ada data di tanggal ini",
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  TextButton(
                      onPressed: _resetDateFilter,
                      child: const Text("Reset Tanggal"))
                ],
              ),
            );
          }

          // HITUNG TOTAL
          double totalExpense = 0;
          for (var doc in filteredDocs) {
            final data = doc.data() as Map<String, dynamic>;
            double amount = (data['amount'] is num)
                ? (data['amount'] as num).toDouble()
                : 0.0;
            totalExpense += amount;
          }

          String dateLabel = "Total Keseluruhan";
          if (_selectedDateRange != null) {
            dateLabel =
                "${DateFormat('d MMM').format(_selectedDateRange!.start)} - ${DateFormat('d MMM yyyy').format(_selectedDateRange!.end)}";
          }

          return Column(
            children: [
              // INDIKATOR TANGGAL DIPILIH
              if (_selectedDateRange != null)
                Container(
                  color: Colors.orange.withOpacity(0.1),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter Aktif: $dateLabel",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange)),
                      GestureDetector(
                          onTap: _resetDateFilter,
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.orange))
                    ],
                  ),
                ),

              // KARTU TOTAL
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFEF5350)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateLabel,
                        style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(currencyFormatter.format(totalExpense),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("${filteredDocs.length} Transaksi",
                        style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12)),
                  ],
                ),
              ),

              // LIST TRANSAKSI
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    DateTime date = (data['date'] as Timestamp).toDate();
                    double amount = (data['amount'] is num)
                        ? (data['amount'] as num).toDouble()
                        : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: _getCategoryIcon(data['category'] ?? ''),
                        ),
                        title: Text(data['title'] ?? 'Pengeluaran',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(data['carName'] ?? 'Kendaraan',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600)),
                            Text(DateFormat('dd MMM yyyy').format(date),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[400])),
                          ],
                        ),
                        trailing: Text(currencyFormatter.format(amount),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Catat Baru",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (c) => const ExpenseAddScreen())),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Text("Belum ada data",
            style: GoogleFonts.poppins(color: Colors.grey)));
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    switch (category) {
      case 'Servis Rutin':
        icon = Icons.build;
        break;
      case 'Perbaikan / Kerusakan':
        icon = Icons.warning;
        break;
      case 'Pajak & STNK':
        icon = Icons.receipt_long;
        break;
      case 'Cuci Kendaraan':
        icon = Icons.local_car_wash;
        break;
      case 'Parkir & Tol':
        icon = Icons.local_parking;
        break;
      case 'Aksesoris':
        icon = Icons.shopping_bag;
        break;
      default:
        icon = Icons.attach_money;
        break;
    }
    return Icon(icon, color: Colors.red);
  }
}
