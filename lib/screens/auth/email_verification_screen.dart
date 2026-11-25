import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;

  const EmailVerificationScreen({
    super.key,
    this.onVerified,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _autoCheckTimer;
  Timer? _cooldownTimer;

  int _resendCooldown = 0;
  bool _isChecking = false;
  bool _isResending = false;
  bool _isSigningOut = false;

  bool get _isAnyLoading => _isChecking || _isResending || _isSigningOut;

  @override
  void initState() {
    super.initState();
    _startAutoCheckTimer();
    _startCooldownTimer(60);
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheckTimer() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerificationStatus(isManual: false),
    );
  }

  void _startCooldownTimer([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            isError ? AppColors.statusRejectedText : AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkVerificationStatus({required bool isManual}) async {
    if (_isChecking) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _autoCheckTimer?.cancel();
      return;
    }

    if (isManual) {
      setState(() => _isChecking = true);
    }

    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        _autoCheckTimer?.cancel();
        _cooldownTimer?.cancel();
        if (!mounted) return;

        _showMessage('Email berhasil diverifikasi!', isError: false);

        if (widget.onVerified != null) {
          widget.onVerified!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      if (isManual) {
        _showMessage(
          'Email belum terverifikasi. Silakan klik tautan di kotak masuk atau folder Spam.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (isManual) {
        _showMessage(e.message ?? 'Gagal memeriksa status (${e.code}).');
      }
    } catch (e) {
      if (isManual) {
        _showMessage('Gagal memeriksa status: $e');
      }
    } finally {
      if (isManual && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _onResendPressed() async {
    if (_resendCooldown > 0 || _isAnyLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sesi akun tidak ditemukan. Silakan masuk ulang.');
      return;
    }

    setState(() => _isResending = true);
    try {
      await user.sendEmailVerification();
      _startCooldownTimer(60);
      _showMessage(
        'Tautan verifikasi baru telah dikirim ke ${user.email}.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _showMessage(
          'Terlalu banyak permintaan. Tunggu beberapa saat sebelum mengirim ulang.',
        );
      } else {
        _showMessage(e.message ?? 'Gagal mengirim ulang email (${e.code}).');
      }
    } catch (e) {
      _showMessage('Gagal mengirim ulang email: $e');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _onBackToLoginPressed() async {
    if (_isSigningOut) return;

    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    setState(() => _isSigningOut = true);

    try {
      await AuthService.instance.signOut();
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showMessage('Gagal keluar dari akun: $e');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'email@students.usu.ac.id';

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

            // 2. Tata Letak Utama (Header Logo Kiri + Kartu Putih)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Kartu Putih Rounded
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ikon Amplop Verifikasi
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFD5DFEF),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_outlined,
                                color: AppColors.primaryBlue,
                                size: 28,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Judul "Verifikasi email"
                            Text(
                              'Verifikasi email',
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
                              'Kami telah mengirimkan tautan verifikasi ke alamat email di bawah ini. Silakan buka pesan tersebut untuk mengaktifkan akunmu.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Kotak Pill Alamat Email Tujuan
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFD5DFEF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 20,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      email,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0A0D14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Kartu Langkah Singkat
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStepRow(
                                    '1',
                                    'Buka kotak masuk (atau folder Spam) pada email kamu.',
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStepRow(
                                    '2',
                                    'Klik tautan verifikasi akun dari SnaFix.',
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStepRow(
                                    '3',
                                    'Kembali ke halaman ini atau tekan tombol verifikasi di bawah.',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Status Pengecekan Otomatis
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Menunggu konfirmasi otomatis...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Tombol Utama "Saya Sudah Verifikasi"
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isAnyLoading
                                    ? null
                                    : () => _checkVerificationStatus(
                                          isManual: true,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isChecking
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(
                                        'Saya Sudah Verifikasi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Tombol Sekunder "Kirim Ulang Email"
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: (_resendCooldown > 0 || _isAnyLoading)
                                    ? null
                                    : _onResendPressed,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: const Color(0xFF0A0D14),
                                  side: BorderSide(
                                    color: _resendCooldown > 0
                                        ? const Color(0xFFD5DFEF)
                                        : const Color(0xFF1E293B),
                                    width: 1.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isResending
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                    : Text(
                                        _resendCooldown > 0
                                            ? 'Kirim ulang dalam ${_resendCooldown}d'
                                            : 'Kirim ulang email verifikasi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _resendCooldown > 0
                                              ? const Color(0xFF8A94A6)
                                              : const Color(0xFF0A0D14),
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Teks Bawah "Salah email? Keluar"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Salah alamat email? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isAnyLoading
                                      ? null
                                      : _onBackToLoginPressed,
                                  child: Text(
                                    'Ganti akun',
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}