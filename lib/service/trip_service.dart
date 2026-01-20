import 'package:flutter/material.dart';

class TripService {
  // Singleton (Agar bisa diakses dari mana saja dengan satu instance yang sama)
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  // Notifier untuk memberitahu UI kalau ada perubahan status (Aktif/Tidak)
  final ValueNotifier<bool> isTripActive = ValueNotifier(false);

  // Data kendaraan yang sedang dipakai
  Map<String, dynamic>? activeCarData;
  String? activeCarId;

  // Fungsi Mulai Perjalanan
  void startTrip(String carId, Map<String, dynamic> carData) {
    activeCarId = carId;
    activeCarData = carData;
    isTripActive.value = true;
  }

  // Fungsi Stop Perjalanan
  void stopTrip() {
    isTripActive.value = false;
    activeCarData = null;
    activeCarId = null;
  }
}
