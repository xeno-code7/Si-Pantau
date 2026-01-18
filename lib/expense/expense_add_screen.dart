import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExpenseAddScreen extends StatefulWidget {
  const ExpenseAddScreen({super.key});

  @override
  State<ExpenseAddScreen> createState() => _ExpenseAddScreenState();
}

class _ExpenseAddScreenState extends State<ExpenseAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  // Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCarId; // INI KUNCI UTAMANYA
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Kategori Pengeluaran
  final List<String> _categories = [
    'Servis Rutin', // <--- Ubah nama biar jelas
    'Perbaikan / Kerusakan', // <--- Tambah kategori baru ini
    'Pajak & STNK',
    'Cuci Kendaraan',
    'Parkir & Tol',
    'Aksesoris',
    'Asuransi',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi Wajib Pilih Mobil
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pilih kendaraan dulu")));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih kategori pengeluaran")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Ambil Nama Mobil untuk disimpan juga (biar gampang dibaca)
      final carDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cars')
          .doc(_selectedCarId)
          .get();

      final carData = carDoc.data() as Map<String, dynamic>;
      // Ambil nama dari berbagai kemungkinan field
      final String carName = carData['nama_kendaraan'] ??
          carData['merk'] ??
          carData['name'] ??
          "Kendaraan";
      final String plat = carData['plat'] ?? "";
      final String displayName = "$carName ($plat)";

      // 2. Simpan ke Database
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user!.uid,
        'carId': _selectedCarId, // <--- INI PENTING: ID MOBIL
        'carName': displayName, // <--- INI PENTING: NAMA MOBIL
        'title': _titleController.text,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text
            .replaceAll(',', '')
            .replaceAll('.', '')), // Bersihkan format angka
        'note': _noteController.text,
        'date': Timestamp.fromDate(_selectedDate),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Pengeluaran berhasil disimpan!"),
          backgroundColor: Color(0xFF5CB85C),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Catat Pengeluaran",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PILIH KENDARAAN (Dropdown dari Firebase)
              Text("Kendaraan",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('cars')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  List<DropdownMenuItem<String>> carItems = [];
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String nama =
                        data['nama_kendaraan'] ?? data['merk'] ?? "Kendaraan";
                    String plat = data['plat'] ?? "";

                    carItems.add(DropdownMenuItem(
                      value: doc.id, // Value adalah ID Document Mobil
                      child: Text("$nama ($plat)",
                          overflow: TextOverflow.ellipsis),
                    ));
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCarId,
                        isExpanded: true,
                        hint: const Text("Pilih Kendaraan"),
                        items: carItems,
                        onChanged: (val) =>
                            setState(() => _selectedCarId = val),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2. KATEGORI
              Text("Kategori",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text("Pilih Kategori"),
                    items: _categories
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. INPUT FORM LAINNYA
              _buildInput(
                  "Judul Pengeluaran", _titleController, "Contoh: Ganti Oli",
                  isNumber: false),
              _buildInput("Biaya (Rp)", _amountController, "0", isNumber: true),

              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text =
                          DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildInput("Tanggal", _dateController, "",
                      isReadOnly: true, suffixIcon: Icons.calendar_today),
                ),
              ),

              _buildInput("Catatan (Opsional)", _noteController,
                  "Keterangan tambahan...",
                  maxLines: 3),

              const SizedBox(height: 30),

              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CB85C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading ? null : _saveExpense,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Simpan Pengeluaran",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController controller, String hint,
      {bool isNumber = false,
      bool isReadOnly = false,
      int maxLines = 1,
      IconData? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: isReadOnly,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            validator: (val) =>
                (val == null || val.isEmpty) && !hint.contains("Opsional")
                    ? "Wajib diisi"
                    : null,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
