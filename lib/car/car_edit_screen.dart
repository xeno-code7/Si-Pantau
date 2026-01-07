import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CarEditScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const CarEditScreen({
    super.key,
    required this.docId,
    required this.currentData,
  });

  @override
  State<CarEditScreen> createState() => _CarEditScreenState();
}

class _CarEditScreenState extends State<CarEditScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // --- CONTROLLER ---
  final _namaController = TextEditingController();
  final _platController = TextEditingController();
  final _tahunController = TextEditingController();
  final _warnaController = TextEditingController();
  final _odoController = TextEditingController();
  final _rangkaController = TextEditingController();
  final _mesinController = TextEditingController();
  
  // Controller khusus untuk menampilkan tanggal
  final _pajakController = TextEditingController();
  final _serviceDateController = TextEditingController();
  final _serviceOdoController = TextEditingController();

  String _jenisKendaraan = "motor";
  final List<String> _jenisOptions = ["motor", "mobil"];
  
  DateTime? _pajakDate;
  DateTime? _serviceDate;
  String _serviceType = "Ganti Oli";
  final _serviceOptions = ['Ganti Oli', 'Servis Rutin', 'Tune Up', 'Lainnya'];

  final String _transmisiTetap = "Matic";
  final String _bahanBakarTetap = "Bensin";

  Uint8List? _imageBytes;
  String? _oldPhotoUrl;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadInitialData();
  }

  void _loadInitialData() {
    final d = widget.currentData;
    _jenisKendaraan = d['jenis_kendaraan'] ?? "motor";
    _namaController.text = d['nama_kendaraan'] ?? "";
    _platController.text = d['plat'] ?? "";
    _tahunController.text = d['tahun']?.toString() ?? "";
    _warnaController.text = d['warna'] ?? "";
    _odoController.text = d['odo']?.toString() ?? "";
    _rangkaController.text = d['rangka'] ?? "";
    _mesinController.text = d['mesin'] ?? "";

    // Load Pajak & Format ke Controller
    if (d['pajak'] is Timestamp) {
      _pajakDate = (d['pajak'] as Timestamp).toDate();
      _pajakController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(_pajakDate!);
    }

    // Load Service & Format ke Controller
    _serviceOdoController.text = d['last_service_odo']?.toString() ?? "";
    if (d['last_service_date'] is Timestamp) {
      _serviceDate = (d['last_service_date'] as Timestamp).toDate();
      _serviceDateController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(_serviceDate!);
    }

    _serviceType = d['service_type'] ?? "Ganti Oli";
    _oldPhotoUrl = d['photo_url'];
  }

  // --- FUNGSI PICK DATE YANG ROBUST ---
  Future<void> _pickDate({
    required DateTime? initial,
    required Function(DateTime) onPicked,
    required TextEditingController controller,
    required DateTime lastDate,
  }) async {
    // Pastikan initial date tidak melampaui lastDate agar tidak crash
    DateTime safeInitial = initial ?? DateTime.now();
    if (safeInitial.isAfter(lastDate)) safeInitial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: DateTime(2000),
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        onPicked(picked);
        controller.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _oldPhotoUrl;
    final ref = FirebaseStorage.instance.ref('car_photos/${user!.uid}/car_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> _updateCar() async {
    if (_namaController.text.isEmpty || _platController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi data wajib")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final photoUrl = await _uploadImage();
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('cars').doc(widget.docId).update({
        'nama_kendaraan': _namaController.text,
        'plat': _platController.text,
        'tahun': _tahunController.text,
        'warna': _warnaController.text,
        'odo': int.tryParse(_odoController.text) ?? 0,
        'rangka': _rangkaController.text,
        'mesin': _mesinController.text,
        'photo_url': photoUrl,
        'pajak': _pajakDate != null ? Timestamp.fromDate(_pajakDate!) : null,
        'last_service_date': _serviceDate != null ? Timestamp.fromDate(_serviceDate!) : null,
        'last_service_odo': int.tryParse(_serviceOdoController.text) ?? 0,
        'service_type': _serviceType,
        'transmisi': _transmisiTetap,
        'bahan_bakar': _bahanBakarTetap,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Kendaraan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE PICKER
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150, width: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF5CB85C)),
                    borderRadius: BorderRadius.circular(15),
                    image: _imageBytes != null
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : _oldPhotoUrl != null ? DecorationImage(image: NetworkImage(_oldPhotoUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: _imageBytes == null && _oldPhotoUrl == null ? const Icon(Icons.camera_alt, size: 50) : null,
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("Informasi Utama"),
            _buildInput("Nama Kendaraan", _namaController),
            _buildInput("Plat Nomor", _platController),
            _buildInput("Odometer", _odoController, suffix: "KM", isNumber: true),

            const Divider(height: 40),
            _buildSectionTitle("Detail & Legalitas"),
            _buildInput("Nomor Rangka", _rangkaController),
            _buildInput("Nomor Mesin", _mesinController),

            // --- PICKER PAJAK (Bisa Masa Depan sampai 2100) ---
            GestureDetector(
              onTap: () => _pickDate(
                initial: _pajakDate,
                onPicked: (d) => _pajakDate = d,
                controller: _pajakController,
                lastDate: DateTime(2100), 
              ),
              child: AbsorbPointer(
                child: _buildInput("Tanggal Pajak", _pajakController, icon: Icons.calendar_today),
              ),
            ),

            const Divider(height: 40),
            _buildSectionTitle("Riwayat Servis"),
            _buildInput("Odometer Servis Terakhir", _serviceOdoController, suffix: "KM", isNumber: true),
            
            // --- PICKER SERVIS (Hanya Masa Lalu) ---
            GestureDetector(
              onTap: () => _pickDate(
                initial: _serviceDate,
                onPicked: (d) => _serviceDate = d,
                controller: _serviceDateController,
                lastDate: DateTime.now(),
              ),
              child: AbsorbPointer(
                child: _buildInput("Tanggal Servis Terakhir", _serviceDateController, icon: Icons.history),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5CB85C), foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _updateCar,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SIMPAN PERUBAHAN"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5CB85C))));
  
  Widget _buildInput(String label, TextEditingController c, {String? suffix, IconData? icon, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}