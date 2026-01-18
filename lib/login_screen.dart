import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_navigation.dart'; // Pastikan file ini ada

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk menangkap input teks
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false; // Untuk efek loading
  bool _isObscure = true; // Untuk sembunyikan password

  // --- 1. LOGIKA LOGIN EMAIL ---
  Future<void> _loginEmail() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) _goToHome();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Email atau Password salah.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIKA LOGIN GOOGLE (WEB & ANDROID) ---
  Future<void> _loginGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Memicu popup login Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User membatalkan login (klik silang)
        setState(() => _isLoading = false);
        return;
      }

      // Mengambil detail otentikasi dari akun Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Membuat "kartu akses" untuk Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Masuk ke Firebase menggunakan kartu akses tersebut
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) _goToHome();
    } catch (e) {
      _showError("Gagal Login Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan LayoutBuilder agar responsif di Web & HP
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          // Membatasi lebar agar di layar komputer tampilannya tetap seperti HP
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- BAGIAN LOGO & JUDUL ---
                // Ikon Mobil Hijau (Placeholder mirip desain)
                const Icon(Icons.directions_car_filled_outlined,
                    size: 80, color: Color(0xFF5CB85C)),

                // Tulisan SIPANTAU (Miring, Tebal, Hijau)
                Text(
                  'SIPANTAU',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF5CB85C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Siap memantau kendaraan anda!',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87),
                ),

                const SizedBox(height: 40),

                // --- FORM INPUT ---
                // Input Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email atau Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF5CB85C), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF5CB85C), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),

                // Tombol Lupa Password (Merah)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Fitur reset password bisa ditambahkan nanti
                    },
                    child: const Text('Lupa Password?',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w500)),
                  ),
                ),

                const SizedBox(height: 10),

                // --- TOMBOL LOGIN ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF5CB85C), // Warna Hijau Sipantau
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _loginEmail,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Login',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- DIVIDER "ATAU" ---
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child:
                          Text("atau", style: TextStyle(color: Colors.black54)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),

                const SizedBox(height: 24),

                // --- TOMBOL GOOGLE (Sesuai Desain) ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE), // Abu-abu muda
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Google dari Internet (karena ini Web)
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          height: 24,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Icon(Icons.g_mobiledata,
                                color: Colors.blue, size: 24); // Placeholder
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata,
                                  color: Colors.blue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Masuk dengan Google',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- FOOTER DAFTAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Baru di sini? ",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: () {
                        // Arahkan ke halaman Register jika sudah dibuat
                      },
                      child: const Text(
                        "Daftar yuk!",
                        style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold), // Warna Kuning/Emas
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
