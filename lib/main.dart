import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/notification_helper.dart';


// Import halaman-halaman penting
import 'login_screen.dart';
import 'main_navigation.dart';

// 1. Variabel Global untuk Mengontrol Tema
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.init();
  runApp(const MyApp());

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          // PASTIKAN DATA INI TETAP SESUAI DENGAN FIREBASE ANDA
          apiKey: "AIzaSyBFGKtYHdRsTf_g_J_o9fMboiziQrXx7xs",
          authDomain: "test-sipantau.firebaseapp.com",
          projectId: "test-sipantau",
          storageBucket: "test-sipantau.firebasestorage.app",
          messagingSenderId: "313304355828",
          appId: "1:313304355828:web:30efd9dc9ce5a4ba009fa1",
          measurementId: "G-80JJR4DSY5"),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const SipantauApp());
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

          // Mengatur Mode saat ini (Light/Dark)
          themeMode: currentMode,

          // --- TEMA TERANG (LIGHT) ---
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF5CB85C),
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5CB85C),
                brightness: Brightness.light),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
            ),
          ),

          // --- TEMA GELAP (DARK) ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF5CB85C),
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5CB85C),
                brightness: Brightness.dark),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardColor: const Color(0xFF1E1E1E),
          ),

          // --- DISINI KUNCI PERBAIKANNYA ---
          // Jangan langsung ke LoginScreen(), tapi cek status dulu pakai StreamBuilder
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance
                .authStateChanges(), // Mendengarkan status login
            builder: (context, snapshot) {
              // 1. Jika sedang loading (koneksi lambat), tampilkan loading bulat
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // 2. Jika ada Data User (Artinya SUDAH LOGIN), langsung ke HOME
              if (snapshot.hasData) {
                return const MainNavigation();
              }

              // 3. Jika Tidak ada data (BELUM LOGIN / LOGOUT), ke LOGIN SCREEN
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

// flutter run -d cherome --web-browser-flag "--disable-web-security" 