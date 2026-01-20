import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Ganti ke Google Maps
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
  GoogleMapController? _mapController; // Controller Google Maps

  // Default lokasi sementara (Semarang)
  LatLng _currentLocation = const LatLng(-6.9932, 110.4203);
  bool _isLoading = true;
  Set<Marker> _markers = {}; // Set Marker untuk Google Maps

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
            _generateMarkers(); // Buat marker setelah lokasi didapat
          });

          // Pindahkan kamera jika map sudah siap
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation, 15),
          );
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

  // Fungsi membuat Marker Google Maps
  void _generateMarkers() {
    _markers = _workshops.map((ws) {
      return Marker(
        markerId: MarkerId(ws['name']),
        position: ws['loc'],
        icon: BitmapDescriptor.defaultMarkerWithHue(
          ws['type'] == 'spklu'
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: ws['name'],
          snippet: ws['type'] == 'spklu'
              ? "Stasiun Pengisian Listrik"
              : "Bengkel Umum",
          onTap: () => _showInfo(ws),
        ),
      );
    }).toSet();
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true, // Menampilkan titik biru lokasi saya
            myLocationButtonEnabled: true, // Tombol kembali ke lokasi saya
            zoomControlsEnabled: false, // UI lebih bersih
            mapType: MapType.normal, // Tampilan standar Google Maps
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
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
        isScrollControlled: true, // Agar bisa menyesuaikan konten
        builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Tinggi mengikuti konten
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
                  const SizedBox(height: 20),
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
