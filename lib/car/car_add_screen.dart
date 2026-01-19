import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CarAddScreen extends StatefulWidget {
  const CarAddScreen({super.key});

  @override
  State<CarAddScreen> createState() => _CarAddScreenState();
}

class _CarAddScreenState extends State<CarAddScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // ================= JENIS KENDARAAN =================
  String _jenisKendaraan = "motor";
  final List<String> _jenisKendaraanOptions = ["motor", "mobil"];

  // ================= DATA KENDARAAN =================
  final _namaController = TextEditingController();
  final _platController = TextEditingController();
  final _tahunController = TextEditingController();
  final _warnaController = TextEditingController();
  final _odoController = TextEditingController();

  // ================= DATA BARU (RANGKA, MESIN, PAJAK) =================
  final _rangkaController = TextEditingController();
  final _mesinController = TextEditingController();
  DateTime? _pajakDate;

  // ================= SERVIS TERAKHIR =================
  final _serviceOdoController = TextEditingController();
  DateTime? _serviceDate;
  String _serviceType = "Ganti Oli";
  final _serviceTypes = ['Ganti Oli', 'Servis Rutin', 'Tune Up', 'Lainnya'];

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // ================= PICK DATE HELPERS =================
  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _serviceDate = picked);
  }

  Future<void> _pickPajakDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100), // Pajak bisa di masa depan
    );
    if (picked != null) setState(() => _pajakDate = picked);
  }

  // ================= UPLOAD IMAGE =================
  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return null;
    final uid = user!.uid;
    final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('vehicle_photos/$uid/$fileName');
    await ref.putData(
        _imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  // ================= SAVE DATA =================
  Future<void> _saveCar() async {
    if (_namaController.text.isEmpty ||
        _platController.text.isEmpty ||
        _odoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lengkapi data wajib"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final photoUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cars')
          .add({
        // ===== IDENTITAS =====
        'jenis_kendaraan': _jenisKendaraan,
        'nama_kendaraan': _namaController.text,
        'plat': _platController.text,
        'tahun': _tahunController.text,
        'warna': _warnaController.text,
        'odo': int.parse(_odoController.text),
        'photo_url': photoUrl,

        // ===== DATA BARU (Sesuai CarDetailScreen) =====
        'rangka': _rangkaController.text,
        'mesin': _mesinController.text,
        'pajak': _pajakDate != null ? Timestamp.fromDate(_pajakDate!) : null,
        'stnk_aktif': true, // Otomatis aktif saat buat baru

        // ===== SERVIS TERAKHIR =====
        'last_service_date':
            _serviceDate != null ? Timestamp.fromDate(_serviceDate!) : null,
        'last_service_odo': _serviceOdoController.text.isNotEmpty
            ? int.parse(_serviceOdoController.text)
            : null,
        'service_type': _serviceType,
        'prediksi_rul': 0.0, // Initial value untuk ML agar tidak error

        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Kendaraan berhasil ditambahkan"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Kendaraan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- BAGIAN FOTO YANG HILANG (SUDAH DITAMBAHKAN KEMBALI) ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border:
                        Border.all(color: const Color(0xFF5CB85C), width: 2),
                    borderRadius: BorderRadius.circular(15),
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 5),
                            Text("Upload Foto",
                                style: TextStyle(color: Colors.grey))
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 25),
            // -------------------------------------------------------------

            _buildDropdown(
                "Jenis Kendaraan",
                _jenisKendaraan,
                _jenisKendaraanOptions,
                (v) => setState(() => _jenisKendaraan = v!)),
            _buildInput("Nama Kendaraan (ex: Innova)", _namaController),
            _buildInput("Plat Nomor", _platController),
            _buildInput("Tahun", _tahunController, isNumber: true),
            _buildInput("Warna", _warnaController),
            _buildInput("Odometer Saat Ini", _odoController,
                isNumber: true, suffixText: "KM"),

            const Divider(height: 30),
            const Text("Detail Spesifikasi",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // INPUT BARU
            _buildInput("Nomor Rangka", _rangkaController),
            _buildInput("Nomor Mesin", _mesinController),

            // INPUT TANGGAL PAJAK
            GestureDetector(
              onTap: _pickPajakDate,
              child: AbsorbPointer(
                child: _buildInput(
                  _pajakDate == null
                      ? "Tanggal Jatuh Tempo Pajak"
                      : DateFormat('dd MMMM yyyy', 'id_ID').format(_pajakDate!),
                  TextEditingController(),
                ),
              ),
            ),

            const Divider(height: 40),
            const Text("Servis Terakhir",
                style: TextStyle(fontWeight: FontWeight.bold)),

            GestureDetector(
              onTap: _pickServiceDate,
              child: AbsorbPointer(
                child: _buildInput(
                  _serviceDate == null
                      ? "Tanggal Servis Terakhir"
                      : DateFormat('dd MMMM yyyy', 'id_ID')
                          .format(_serviceDate!),
                  TextEditingController(),
                ),
              ),
            ),

            _buildInput("Odometer Saat Servis", _serviceOdoController,
                isNumber: true, suffixText: "KM"),
            _buildDropdown("Jenis Servis", _serviceType, _serviceTypes,
                (v) => setState(() => _serviceType = v!)),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _saveCar,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Kendaraan"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _buildInput(String label, TextEditingController c,
      {bool isNumber = false, String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            suffixText: suffixText,
            border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
