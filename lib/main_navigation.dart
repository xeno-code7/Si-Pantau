import 'package:flutter/material.dart';
import 'service/trip_service.dart'; // Import TripService

// PASTIKAN ADA NAMA FOLDERNYA SEPERTI INI:
import 'home/home_screen.dart'; // Masuk folder home
import 'service/service_screen.dart'; // Masuk folder service
import 'car/car_screen.dart'; // Masuk folder car
import 'profile/profile_screen.dart'; // Masuk folder profile

class MainNavigation extends StatefulWidget {
  // ...
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _screens = [
    const HomeScreen(),
    const ServiceScreen(), // Panggil ServiceScreen dari foldernya
    const CarScreen(), // Panggil CarScreen dari foldernya
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Gunakan Stack agar Floating Widget bisa melayang di atas konten
      body: Stack(
        children: [
          // Layer 1: Halaman Utama (Home, Service, dll)
          _screens[_selectedIndex],

          // Layer 2: Floating Widget (Hanya muncul jika trip aktif)
          ValueListenableBuilder<bool>(
            valueListenable: TripService().isTripActive,
            builder: (context, isActive, child) {
              if (!isActive) return const SizedBox.shrink();

              final carData = TripService().activeCarData;
              final String carName = carData?['nama_kendaraan'] ?? "Kendaraan";
              final String plat = carData?['plat'] ?? "";

              return Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1E1E1E), // Warna Gelap Elegan
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFF5CB85C), width: 1),
                    ),
                    child: Row(
                      children: [
                        // Animasi Icon Berkedip (Simulasi tracking)
                        const Icon(Icons.directions_car,
                            color: Color(0xFF5CB85C), size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Sedang Berjalan: $carName",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text("$plat • Merekam Jarak...",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Logika Batalkan / Selesai
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Selesaikan Perjalanan?"),
                                content: const Text(
                                    "Apakah Anda ingin mengakhiri sesi berkendara ini?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Batal")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () {
                                      TripService().stopTrip();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text("Selesai",
                                        style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.stop_circle_outlined,
                              color: Colors.red, size: 32),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        indicatorColor: const Color(0xFF5CB85C).withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Service',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Car',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
