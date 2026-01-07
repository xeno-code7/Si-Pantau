import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class JourneyScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const JourneyScreen({
    super.key, 
    required this.vehicleId, 
    required this.vehicleData
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  
  bool _isTracking = false;
  bool _showHistory = false; 
  double _totalDistance = 0.0;

  // URL Hugging Face Space kamu
  final String _apiUrl = "https://sann2935-sipantau-api.hf.space/predict"; 

  @override
  void initState() {
    super.initState();
    // Langsung cari lokasi saat halaman dibuka agar peta tidak "nyasar"
    _setInitialLocation(); 
  }

  // Fungsi untuk mendeteksi lokasi awal secara otomatis
  Future<void> _setInitialLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Ambil posisi terakhir yang diketahui agar lebih cepat muncul
    Position? position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (mounted) {
      setState(() {
        _lastPosition = position;
      });
      // Geser peta ke lokasi user secara otomatis
      _mapController.move(LatLng(position!.latitude, position.longitude), 15);
    }
  }

  void _startJourney() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      _isTracking = true;
      _showHistory = false; 
      _totalDistance = 0.0;
      // _lastPosition tidak di-reset agar pinpoint biru tetap terlihat
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 10
      ),
    ).listen((Position position) {
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude
        );
        setState(() {
          _totalDistance += (distance / 1000); 
        });
      }
      _lastPosition = position;
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    });
  }

  Future<void> _stopJourney() async {
    await _positionStream?.cancel();
    setState(() => _isTracking = false);

    int oldOdo = int.tryParse(widget.vehicleData['odo']?.toString() ?? "0") ?? 0;
    int newOdo = oldOdo + _totalDistance.toInt();

    // Update Odometer di Firestore secara real-time
    await FirebaseFirestore.instance
        .collection('users').doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cars').doc(widget.vehicleId)
        .update({'odo': newOdo});

    _fetchMLPrediction(newOdo);
  }

  Future<void> _fetchMLPrediction(int odoBaru) async {
    try {
      int lastOdo = int.tryParse(widget.vehicleData['last_service_odo']?.toString() ?? "0") ?? 0;
      dynamic rawDate = widget.vehicleData['last_service_date'];
      DateTime lastDate = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
      int daysSince = DateTime.now().difference(lastDate).inDays;
      if (daysSince <= 0) daysSince = 1;

      // Kirim data ke model Random Forest (MAE 1.16 km)
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jenis_kendaraan": widget.vehicleData['jenis_kendaraan'] == "mobil" ? 1 : 0,
          "odometer_km": odoBaru,
          "km_since_last_service": odoBaru - lastOdo,
          "days_since_last_service": daysSince,
          "km_per_day": (odoBaru - lastOdo) / daysSince,
          "target_km_interval": widget.vehicleData['jenis_kendaraan'] == "mobil" ? 8000 : 3000,
          "target_days_interval": widget.vehicleData['jenis_kendaraan'] == "mobil" ? 180 : 75
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        double prediction = result['rul_km'];

        final historyRef = FirebaseFirestore.instance
            .collection('users').doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('cars').doc(widget.vehicleId)
            .collection('history');

        // Simpan Riwayat
        await historyRef.add({
          'tanggal': DateTime.now(),
          'jarak_tempuh': _totalDistance,
          'prediksi_akhir': prediction,
        });

        // LOGIKA FIFO: Maksimal 3 riwayat perjalanan untuk menghemat kuota
        final snapshots = await historyRef.orderBy('tanggal', descending: true).get();
        if (snapshots.docs.length > 3) {
          for (int i = 3; i < snapshots.docs.length; i++) {
            await historyRef.doc(snapshots.docs[i].id).delete();
          }
        }

        // Simpan hasil prediksi terbaru ke dokumen utama mobil
        await FirebaseFirestore.instance
            .collection('users').doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('cars').doc(widget.vehicleId)
            .update({'prediksi_rul': prediction});

        _showResult(prediction);
      }
    } catch (e) {
      debugPrint("Gagal panggil ML: $e");
    }
  }

  void _showResult(double rulKm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("Prediksi Servis (ML)", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Berdasarkan pola berkendara Anda, sisa umur servis adalah ${rulKm.toStringAsFixed(1)} KM lagi."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            }, 
            child: const Text("OK")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking: ${widget.vehicleData['nama_kendaraan']}"),
        backgroundColor: const Color(0xFF5CB85C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(-6.9826, 110.4092), // Default Udinus Semarang
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sipantau',
                ),
                // PINPOINT LOKASI BIRU
                if (_lastPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_lastPosition!.latitude, _lastPosition!.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_history,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                if (!_isTracking) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showHistory = !_showHistory),
                          icon: Icon(_showHistory ? Icons.map : Icons.history),
                          label: Text(_showHistory ? "Tutup" : "Riwayat"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5CB85C),
                            side: const BorderSide(color: Color(0xFF5CB85C)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _startJourney,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CB85C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Mulai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  if (_showHistory) _buildHistoryList(),
                ] else ...[
                  Text("Jarak Tempuh", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    "${_totalDistance.toStringAsFixed(2)} KM",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF5CB85C)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _stopJourney,
                      child: const Text("SELESAI PERJALANAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('cars').doc(widget.vehicleId)
            .collection('history').orderBy('tanggal', descending: true).limit(3).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada riwayat."));

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              DateTime tgl = (doc['tanggal'] as Timestamp).toDate();
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Color(0xFF5CB85C)),
                  title: Text("${doc['jarak_tempuh'].toStringAsFixed(2)} KM"),
                  subtitle: Text(DateFormat('dd MMM, HH:mm').format(tgl)),
                  trailing: Text("AI: ${doc['prediksi_akhir'].toStringAsFixed(1)} KM", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}