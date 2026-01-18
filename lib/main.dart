import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
// [1] IMPORT WAJIB: Tambahkan ini untuk format tanggal Indonesia
import 'package:intl/date_symbol_data_local.dart';

import 'utils/notification_helper.dart';
import 'login_screen.dart';
import 'main_navigation.dart';
import 'profile/profile_screen.dart'; // Pastikan import ini ada untuk themeNotifier

// Variabel Global Theme (Pastikan ini ada jika dipakai di file lain)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [2] Inisialisasi format tanggal Indonesia (Global)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Notifikasi
  await NotificationHelper.init();

  // Konfigurasi Firebase (Sesuaikan dengan data kamu)
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

// [CATATAN]: Fungsi checkAllVehiclesMaintenance SUDAH DIHAPUS
// karena tugasnya sudah diambil alih oleh ReminderManager di HomeScreen.

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
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5CB85C),
                brightness: Brightness.light),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF5CB85C),
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5CB85C),
                brightness: Brightness.dark),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData) {
                // [PENTING] Langsung ke MainNavigation
                // Pengecekan notifikasi otomatis sudah dijalankan di dalam HomeScreen (via MainNavigation)
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
