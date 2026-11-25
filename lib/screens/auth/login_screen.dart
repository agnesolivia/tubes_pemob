import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/screens/auth/register_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool get _isAnyLoading => _isEmailLoading || _isGoogleLoading;

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.statusRejectedText : AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _mapEmailAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau kata sandi tidak sesuai.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Koneksi internet bermasalah.';
        default:
          return error.message ?? 'Login gagal (${error.code}).';
      }
    }
    return 'Login gagal: $error';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      // AuthWrapper otomatis mengarahkan sesuai role di Firestore
    } catch (e) {
      _showMessage(_mapEmailAuthError(e));
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _onForgotPasswordPressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Masukkan email terlebih dahulu untuk reset kata sandi.');
      return;
    }
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      _showMessage('Tautan reset kata sandi dikirim ke $email.', isError: false);
    } catch (e) {
      _showMessage(_mapEmailAuthError(e));
    }
  }

  Future<void> _onGoogleLoginPressed() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential == null) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Google gagal: $e'),
          backgroundColor: AppColors.statusRejectedText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: Stack(
          children: [
            // 1. Background Gelombang Biru Atas
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave_top.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),

            // 2. Tata Letak Utama (Header Logo Kiri + Kartu Putih Form)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian Atas: Logo Snafix rata kiri
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      size.height * 0.032,
                      28,
                      size.height * 0.035,
                    ),
                    child: Image.asset(
                      'assets/images/snafix_logo.png',
                      width: size.width * 0.31,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Bagian Bawah: Kartu Putih Rounded
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(34),
                        topRight: Radius.circular(34),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(26, 32, 26, 24),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Judul "Masuk"
                              Text(
                                'Masuk',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0A0D14),
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subjudul
                              Text(
                                'Masuk untuk akses kerusakan fasilitas kampus\ndengan mudah.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),

                              const SizedBox(height: 26),

                              // Label Email
                              Text(
                                'Email',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0D14),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Input Field Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0A0D14),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return 'Email wajib diisi.';
                                  final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
                                  if (!emailRegex.hasMatch(text)) return 'Format email tidak valid.';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'nama@gmail.com',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF8A94A6),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.inputFill,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5DFEF),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryBlue,
                                      width: 1.4,
                                    ),
                                  ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: AppColors.statusRejectedText,
                                    width: 1.2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: AppColors.statusRejectedText,
                                    width: 1.4,
                                  ),                                
                                ),
                              ),
                            ),

                              const SizedBox(height: 18),

                              // Label Kata Sandi
                              Text(
                                'Kata Sandi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0D14),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Input Field Kata Sandi
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0A0D14),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Kata sandi wajib diisi.';
                                  if (value.length < 6) return 'Kata sandi minimal 6 karakter.';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Masukkan kata sandi',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF8A94A6),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.inputFill,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF88A1D8),
                                        size: 21,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5DFEF),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryBlue,
                                      width: 1.4,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: AppColors.statusRejectedText,
                                    width: 1.2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: AppColors.statusRejectedText,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),

                              const SizedBox(height: 10),

                              // Tautan Lupa Kata Sandi?
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _isAnyLoading ? null : _onForgotPasswordPressed,
                                  child: Text(
                                    'Lupa Kata Sandi?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 26),

                              // Tombol Utama "Masuk"
                              Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isAnyLoading ? null : _onLoginPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: AppColors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isEmailLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(
                                        'Masuk',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Pembatas "atau"
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: AppColors.border,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'atau',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF8A94A6),
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: AppColors.border,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),
                            // Tombol "Lanjutkan dengan Google"
                              SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _isGoogleLoading
                                    ? null
                                    : _onGoogleLoginPressed,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: const Color(0xFF0A0D14),
                                  side: const BorderSide(
                                    color: Color(0xFF1E293B),
                                    width: 1.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isGoogleLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/google_logo.png',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Lanjutkan dengan Google',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0A0D14),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          
                            
                              const SizedBox(height: 26),

                              // Teks Bawah "Belum punya akun? Daftar"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun? ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Daftar',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

