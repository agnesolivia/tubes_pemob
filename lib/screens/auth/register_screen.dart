import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/screens/auth/login_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState> _confirmPasswordFieldKey =
    GlobalKey<FormFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool get _isAnyLoading => _isEmailLoading || _isGoogleLoading;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.statusRejectedText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama lengkap wajib diisi.';
    if (text.length < 5) return 'Nama lengkap minimal 5 karakter.';
    if (text.length > 60) return 'Nama lengkap maksimal 60 karakter.';
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\.\'\-]+$");
    if (!nameRegex.hasMatch(text)) {
      return 'Nama hanya boleh berisi huruf dan spasi.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi.';
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(text)) return 'Format email tidak valid.';
    return null;
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSymbol =>
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(_passwordController.text);

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Kata sandi wajib diisi.';
    if (!_hasMinLength ||
        !_hasUppercase ||
        !_hasLowercase ||
        !_hasNumber ||
        !_hasSymbol) {
      return 'Kata sandi belum memenuhi semua syarat.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
    if (text != _passwordController.text) {
      return 'Konfirmasi kata sandi tidak cocok.';
    }
    return null;
  }

  bool get _isFormValid =>
      _validateName(_nameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _validateConfirmPassword(_confirmPasswordController.text) == null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    final nama = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);
    try {
      await AuthService.instance.registerWithEmail(
        nama: nama,
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showMessage('Email sudah terdaftar. Silakan masuk.');
      } else if (e.code == 'invalid-email') {
        _showMessage('Format email tidak valid.');
      } else if (e.code == 'weak-password') {
        _showMessage('Kata sandi terlalu lemah (minimal 8 karakter).');
      } else if (e.code == 'network-request-failed') {
        _showMessage('Koneksi internet bermasalah.');
      } else if (e.code == 'too-many-requests') {
        _showMessage('Terlalu banyak percobaan. Coba lagi beberapa saat.');
      } else {
        _showMessage(e.message ?? 'Pendaftaran gagal (${e.code}).');
      }
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _onGoogleRegisterPressed() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential == null) return;
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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

  void _navigateToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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
                      size.height * 0.024,
                      28,
                      size.height * 0.026,
                    ),
                    child: Image.asset(
                      'assets/images/snafix_logo.png',
                      width: size.width * 0.30,
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
                        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                          child: Form(
                            key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Judul "Buat akun"
                                  Text(
                                    'Buat akun',
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
                                    'Daftar untuk mulai melaporkan kerusakan\nfasilitas.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  // 1. Label & Input Nama Lengkap
                                  _buildFieldLabel('Nama lengkap'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    textCapitalization: TextCapitalization.words,
                                    style: _inputTextStyle(),
                                    validator: _validateName,
                                    decoration: _pillInputDecoration(
                                      hintText: 'Masukkan nama lengkap',
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // 2. Label & Input Email
                                  _buildFieldLabel('Email'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    keyboardType: TextInputType.emailAddress,
                                    style: _inputTextStyle(),
                                    validator: _validateEmail,
                                    decoration: _pillInputDecoration(
                                      hintText: 'nama@gmail.com',
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // 3. Label & Input Kata Sandi
                                  _buildFieldLabel('Kata Sandi'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    obscureText: _obscurePassword,
                                    style: _inputTextStyle(),
                                    onChanged: (_) {
                                      if (_confirmPasswordController.text.isNotEmpty) {
                                        _confirmPasswordFieldKey.currentState?.validate();
                                      }
                                    },
                                    validator: _validatePassword,
                                    decoration: _pillInputDecoration(
                                      hintText: 'Minimal 8 karakter',
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
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.primaryBlue,
                                            size: 21,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  if (_passwordController.text.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _buildPasswordChecklist(),
                                  ],
                                  const SizedBox(height: 15),

                                  // 4. Label & Input Konfirmasi Kata Sandi
                                  _buildFieldLabel('Konfirmasi kata Sandi'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: _confirmPasswordFieldKey,
                                    controller: _confirmPasswordController,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    obscureText: _obscureConfirmPassword,
                                    style: _inputTextStyle(),
                                    validator: _validateConfirmPassword,
                                    decoration: _pillInputDecoration(
                                      hintText: 'Masukkan kata sandi',
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.primaryBlue,
                                            size: 21,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Tombol Utama "Daftar"
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: _isFormValid
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primaryBlue
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 14,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: (_isAnyLoading || !_isFormValid)
                                          ? null
                                          : _onRegisterPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: AppColors.white,
                                        disabledBackgroundColor:
                                            const Color(0xFFCBD5E1),
                                        disabledForegroundColor:
                                            AppColors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
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
                                        'Daftar',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
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

                                  const SizedBox(height: 18),

                                  // Tombol "Lanjutkan dengan Google"
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: _isGoogleLoading
                                          ? null
                                          : _onGoogleRegisterPressed,
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

                                  const SizedBox(height: 22),

                                  // Teks Bawah "Sudah punya akun? Masuk"
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sudah punya akun? ',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _navigateToLogin,
                                        child: Text(
                                          'Masuk',
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
                          )
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

  Widget _buildPasswordChecklist() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7FA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCheckItem('Min. 8 karakter', _hasMinLength),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCheckItem('Huruf besar (A-Z)', _hasUppercase),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCheckItem('Huruf kecil (a-z)', _hasLowercase),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCheckItem('Angka (0-9)', _hasNumber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCheckItem('Simbol (@#!\$)', _hasSymbol),
              ),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isMet) {
    final color = isMet ? const Color(0xFF16A34A) : const Color(0xFF64748B);
    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0A0D14),
      ),
    );
  }

  TextStyle _inputTextStyle() {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF0A0D14),
    );
  }

  InputDecoration _pillInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF8A94A6),
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 15,
      ),
      suffixIcon: suffixIcon,
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
    );
  }
}