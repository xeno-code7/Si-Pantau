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

  // ===== JENIS KENDARAAN =====
  String _jenisKendaraan = "motor";
  final List<String> _jenisOptions = ["motor", "mobil"];

  // ===== DATA UTAMA =====
  final _namaController = TextEditingController();
  final _platController = TextEditingController();
  final _tahunController = TextEditingController();
  final _warnaController = TextEditingController();
  final _odoController = TextEditingController();

  // ===== SERVIS TERAKHIR =====
  final _serviceOdoController = TextEditingController();
  DateTime? _serviceDate;
  String _serviceType = "Ganti Oli";

  final _serviceOptions = [
    'Ganti Oli',
    'Servis Rutin',
    'Tune Up',
    'Lainnya'
  ];

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
    _tahunController.text = d['tahun'] ?? "";
    _warnaController.text = d['warna'] ?? "";
    _odoController.text = d['odo']?.toString() ?? "";

    _serviceOdoController.text =
        d['last_service_odo']?.toString() ?? "";

    if (d['last_service_date'] is Timestamp) {
      _serviceDate = (d['last_service_date'] as Timestamp).toDate();
    }

    _serviceType = d['service_type'] ?? "Ganti Oli";
    _oldPhotoUrl = d['photo_url'];
  }

  // ===== IMAGE =====
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      _imageBytes = await image.readAsBytes();
      setState(() {});
    }
  }

  // ===== DATE =====
  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _serviceDate = picked);
    }
  }

  // ===== UPLOAD =====
  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _oldPhotoUrl;

    final ref = FirebaseStorage.instance
        .ref('car_photos/${user!.uid}/car_${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putData(
      _imageBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }

  // ===== UPDATE =====
  Future<void> _updateCar() async {
    if (_namaController.text.isEmpty ||
        _platController.text.isEmpty ||
        _odoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi data wajib")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final photoUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cars')
          .doc(widget.docId)
          .update({
        'jenis_kendaraan': _jenisKendaraan,
        'nama_kendaraan': _namaController.text,
        'plat': _platController.text,
        'tahun': _tahunController.text,
        'warna': _warnaController.text,
        'odo': int.parse(_odoController.text),
        'photo_url': photoUrl,

        'last_service_date':
            _serviceDate != null ? Timestamp.fromDate(_serviceDate!) : null,
        'last_service_odo': _serviceOdoController.text.isNotEmpty
            ? int.parse(_serviceOdoController.text)
            : null,
        'service_type': _serviceType,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Kendaraan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  image: _imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : _oldPhotoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_oldPhotoUrl!),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: _imageBytes == null && _oldPhotoUrl == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            _buildDropdown("Jenis Kendaraan", _jenisKendaraan, _jenisOptions,
                (v) => setState(() => _jenisKendaraan = v!)),

            _buildInput("Nama Kendaraan", _namaController),
            _buildInput("Plat Nomor", _platController),
            _buildInput("Tahun", _tahunController),
            _buildInput("Warna", _warnaController),
            _buildInput("Odometer", _odoController, suffix: "KM"),

            const Divider(height: 40),

            _buildInput("Odometer Servis", _serviceOdoController, suffix: "KM"),

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

            _buildDropdown("Jenis Servis", _serviceType, _serviceOptions,
                (v) => setState(() => _serviceType = v!)),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _updateCar,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Simpan Perubahan"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController c,
      {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value,
      List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
