import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapsScreen extends StatefulWidget {
  const GoogleMapsScreen({super.key});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Lokasi Default (Monas, Jakarta) jika GPS belum aktif
  static const CameraPosition _kJakarta = CameraPosition(
    target: LatLng(-6.175392, 106.827153),
    zoom: 14.0,
  );

  // Marker untuk menandai lokasi
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Fungsi untuk mendapatkan lokasi saat ini
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Ambil posisi
    Position position = await Geolocator.getCurrentPosition();
    _goToPosition(LatLng(position.latitude, position.longitude));
  }

  Future<void> _goToPosition(LatLng pos) async {
    final GoogleMapController controller = await _controller.future;

    // Pindahkan kamera ke lokasi user
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: pos, zoom: 16.0),
    ));

    // Tambahkan marker
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Lokasi Saya'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lokasi Kendaraan"),
        backgroundColor: Colors.white,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kJakarta,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
        myLocationEnabled: true, // Menampilkan titik biru lokasi user
        myLocationButtonEnabled: true, // Tombol untuk kembali ke lokasi user
        zoomControlsEnabled: false, // Menyembunyikan tombol zoom +/- bawaan
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
