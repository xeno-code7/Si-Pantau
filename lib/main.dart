import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'utils/notification_helper.dart';
import 'login_screen.dart';
import 'main_navigation.dart';
import 'profile/profile_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationHelper.init();

  const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyBFGKtYHdRsTf_g_J_o9fMboiziQrXx7xs",
    authDomain: "test-sipantau.firebaseapp.com",
    projectId: "test-sipantau",
    storageBucket: "test-sipantau.firebasestorage.app",
    messagingSenderId: "313304355828",
    appId: "1:313304355828:web:30efd9dc9ce5a4ba009fa1",
    measurementId: "G-80JJR4DSY5",
  );

  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const SipantauApp());
}

Future<void> checkAllVehiclesMaintenance(String uid) async {
  if (!notificationNotifier.value) return;

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cars')
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final String nama = data['nama_kendaraan'] ?? "Kendaraan";
      final String plat = data['plat'] ?? "-";
      final String jenis = data['jenis_kendaraan'] ?? "motor";
      
      // --- LOGIKA NOTIFIKASI SERVIS ---
      final double sisaKmRaw = double.tryParse(data['prediksi_rul']?.toString() ?? "0") ?? 0;
      int sisaHariServis = 0;
      final rawServiceDate = data['last_service_date'];
      
      if (rawServiceDate != null) {
        DateTime lastDate = (rawServiceDate is Timestamp) ? rawServiceDate.toDate() : DateTime.now();
        int bulanTambahan = (jenis.toLowerCase() == "mobil") ? 5 : 2;
        
        // PERBAIKAN: Menggunakan lastDate yang sudah didefinisikan
        DateTime targetDate = DateTime(lastDate.year, lastDate.month + bulanTambahan, lastDate.day);
        sisaHariServis = targetDate.difference(DateTime.now()).inDays;
      }

      bool triggerServis = (jenis.toLowerCase() == "mobil") 
          ? (sisaKmRaw <= 1000 || sisaHariServis <= 7) 
          : (sisaKmRaw <= 100 || sisaHariServis <= 7);

      if (triggerServis) {
        NotificationHelper.sendServiceReminder(
          nama: nama,
          plat: plat,
          sisaKm: sisaKmRaw.round(), 
          sisaHari: sisaHariServis,
        );
      }

      // --- LOGIKA NOTIFIKASI PAJAK (H-7) ---
      final rawPajak = data['pajak'];
      if (rawPajak != null && rawPajak is Timestamp) {
        DateTime pajakDate = rawPajak.toDate();
        DateTime today = DateTime.now();
        
        DateTime todayPure = DateTime(today.year, today.month, today.day);
        DateTime pajakPure = DateTime(pajakDate.year, pajakDate.month, pajakDate.day);
        
        int selisihHariPajak = pajakPure.difference(todayPure).inDays;
        
        if (selisihHariPajak == 7) {
          NotificationHelper.sendTaxReminder(
            nama: nama,
            plat: plat,
            tanggalPajak: DateFormat('dd MMMM yyyy', 'id_ID').format(pajakDate),
          );
        }
      }
    }
  } catch (e) {
    debugPrint("Gagal cek kendaraan: $e");
  }
}

class SipantauApp extends StatelessWidget {
  const SipantauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'SIPANTAU',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF5CB85C),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5CB85C), brightness: Brightness.light),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF5CB85C),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5CB85C), brightness: Brightness.dark),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData) {
                checkAllVehiclesMaintenance(snapshot.data!.uid);
                return const MainNavigation();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}