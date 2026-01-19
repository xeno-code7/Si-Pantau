import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FuelAddScreen extends StatefulWidget {
  final String carId;
  final String carName;

  const FuelAddScreen({super.key, required this.carId, required this.carName});

  @override
  State<FuelAddScreen> createState() => _FuelAddScreenState();
}

class _FuelAddScreenState extends State<FuelAddScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _odoController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedFuelType = 'Pertalite';
  final List<String> _fuelTypes = [
    'Pertalite',
    'Pertamax',
    'Pertamax Turbo',
    'Solar',
    'Dexlite',
    'Pertamina Dex',
    'Shell Super',
    'Shell V-Power',
    'Lainnya'
  ];

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
  }

  Future<void> _pickImageFromGallery() async {
    final returnedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (returnedImage == null) return;

    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  Future<void> _saveFuelLog() async {
    // 1. Validasi Form (Input Teks)
    if (!_formKey.currentState!.validate()) return;

    // [BARU] 2. Validasi Gambar (Wajib Ada)
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wajib upload bukti nota/foto BBM!"), // Pesan Error
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop proses, jangan lanjut ke bawah
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final int odo = int.parse(
          _odoController.text.replaceAll(',', '').replaceAll('.', ''));
      final double liters =
          double.parse(_litersController.text.replaceAll(',', '.'));
      final double totalPrice = double.parse(
          _priceController.text.replaceAll(',', '').replaceAll('.', ''));

      // Upload Gambar ke Firebase Storage
      String? imageUrl;
      final String fileName =
          '${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('fuel_receipts').child(fileName);

      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection('fuel_logs').add({
        'userId': user.uid,
        'carId': widget.carId,
        'carName': widget.carName,
        'odometer': odo,
        'liters': liters,
        'totalPrice': totalPrice,
        'fuelType': _selectedFuelType,
        'notaUrl': imageUrl, // Pasti ada isinya sekarang
        'date': Timestamp.fromDate(_selectedDate),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update Odometer Mobil
      final carRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cars')
          .doc(widget.carId);
      final carSnapshot = await carRef.get();
      if (carSnapshot.exists) {
        final currentOdo = carSnapshot.data()?['odo'] ?? 0;
        if (odo > currentOdo) {
          await carRef.update({'odo': odo});
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Data BBM Berhasil Disimpan"),
              backgroundColor: Color(0xFF5CB85C)),
        );
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance
          .recordError(e, stackTrace, reason: 'Gagal Simpan BBM');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Isi BBM: ${widget.carName}",
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5CB85C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput("Odometer Saat Ini", _odoController,
                  isNumber: true, suffix: "KM"),
              _buildInput("Jumlah Liter", _litersController,
                  isNumber: true, suffix: "Liter"),
              _buildInput("Total Harga", _priceController,
                  isNumber: true, suffix: "Rp"),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: InputDecoration(
                    labelText: "Jenis BBM",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _fuelTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFuelType = val!),
                ),
              ),

              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text =
                          DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildInput("Tanggal Pengisian", _dateController,
                      suffixIcon: Icons.calendar_today),
                ),
              ),

              // [UBAH UI] Menandakan Wajib
              Row(
                children: const [
                  Text("Bukti Nota BBM ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("(Wajib)*",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      // [UBAH UI] Border Merah jika belum ada gambar (biar notice)
                      border: Border.all(
                          color: _selectedImage == null
                              ? Colors.redAccent.withOpacity(0.5)
                              : Colors.grey[300]!,
                          width: _selectedImage == null ? 1.5 : 1),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover)
                          : null),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate,
                                color: Color(0xFF5CB85C), size: 40),
                            SizedBox(height: 8),
                            Text("Ketuk untuk upload Nota",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold)),
                            Text("*Wajib diisi",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 10)),
                          ],
                        )
                      : null,
                ),
              ),

              if (_selectedImage != null)
                Center(
                  child: TextButton.icon(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Hapus Foto",
                          style: TextStyle(color: Colors.red))),
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveFuelLog,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Simpan Data",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {bool isNumber = false, String? suffix, IconData? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (val) => val == null || val.isEmpty ? "Wajib diisi" : null,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
