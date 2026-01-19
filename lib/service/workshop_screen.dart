import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkshopScreen extends StatefulWidget {
  // Hapus 'const' di sini jika menyebabkan masalah di versi flutter lama,
  // tapi biasanya ini aman. Yang masalah adalah saat dipanggil dengan 'const'.
  const WorkshopScreen({super.key});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  final MapController _mapController = MapController();

  // Default lokasi sementara (Semarang)
  LatLng _currentLocation = const LatLng(-6.9932, 110.4203);
  bool _isLoading = true;

  // Data Dummy Bengkel
  final List<Map<String, dynamic>> _workshops = [
    {
      "name": "Bengkel Sipantau Pusat",
      "loc": const LatLng(-6.9830, 110.4100),
      "type": "bengkel"
    },
    {
      "name": "SPKLU PLN Pemuda",
      "loc": const LatLng(-6.9800, 110.4150),
      "type": "spklu"
    },
    {
      "name": "Astra Service Station",
      "loc": const LatLng(-6.9850, 110.4050),
      "type": "bengkel"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // Cek apakah user mengizinkan lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Jika diizinkan/dibiarkan, coba ambil lokasi
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5));

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _isLoading = false;
          });
          _mapController.move(_currentLocation, 14);
        }
      } else {
        // Jika ditolak, pakai lokasi default dan matikan loading
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal ambil lokasi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Peta Bengkel",
            style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        // PERHATIKAN: TIDAK ADA 'actions: []' DISINI AGAR TIDAK ERROR
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sipantau',
              ),
              MarkerLayer(
                markers: [
                  // Lokasi Saya
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location,
                        color: Colors.blue, size: 30),
                  ),
                  // Lokasi Bengkel
                  ..._workshops.map((ws) => Marker(
                        point: ws['loc'],
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showInfo(ws),
                          child: Icon(
                            ws['type'] == 'spklu'
                                ? Icons.ev_station
                                : Icons.car_repair,
                            color: ws['type'] == 'spklu'
                                ? Colors.green
                                : Colors.red,
                            size: 40,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Mencari Lokasi..."),
                ),
              ),
            )
        ],
      ),
    );
  }

  void _showInfo(Map<String, dynamic> data) {
    showModalBottomSheet(
        context: context,
        builder: (context) => Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'],
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                      data['type'] == 'spklu'
                          ? "SPKLU (Listrik)"
                          : "Bengkel Umum",
                      style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("Tutup",
                            style: TextStyle(color: Colors.white))),
                  )
                ],
              ),
            ));
  }
}
