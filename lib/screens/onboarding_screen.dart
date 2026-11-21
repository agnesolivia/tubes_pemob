import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      imagePath: 'assets/images/splash_hand.png',
      title: 'Selamat datang di\nSnaFix',
      subtitle: 'Laporkan kerusakan fasilitas kampus\ndengan sekali foto.',
    ),
    _OnboardingItem(
      imagePath: 'assets/images/splash_hand.png',
      title: 'Pantau Perbaikan\nSecara Real-Time',
      subtitle: 'Cek progres verifikasi hingga fasilitas\nselesai diperbaiki teknisi.',
    ),
  ];

void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            // 1. Gambar Gelombang Atas dari Assets
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

            // 2. Konten Utama (Ilustrasi Atas + Kartu Putih Bawah)
            Column(
              children: [
                // Bagian Atas: Ilustrasi 3D Tangan Memegang HP
                Expanded(
                  flex: 53,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Image.asset(
                          _pages[_currentPage].imagePath,
                          height: size.height * 0.30,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bagian Bawah: Kartu Putih Rounded (diturunkan sedikit)
                Expanded(
                  flex: 47,
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
                      child: Column(
                        children: [
                          // Teks Judul & Subjudul (digeser agak ke atas)
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _pages.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final item = _pages[index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0A0D14),
                                          height: 1.22,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        item.subtitle,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF64748B),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Indikator Halaman (Titik Biru + Pill Biru Muda)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pages.length, (index) {
                              final bool isDot = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                                width: isDot ? 7 : 24,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isDot
                                      ? AppColors.primaryBlue
                                      : const Color(0xFF75A4FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 22),

                          // Tombol Bulat Biru dengan Lengkung Progres Oranye
                          _CircularProgressNextButton(
                            progress: (_currentPage + 1) / _pages.length,
                            onTap: _onNextPressed,
                          ),

                          const SizedBox(height: 22),
                        ],
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

class _OnboardingItem {
  final String imagePath;
  final String title;
  final String subtitle;

  const _OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

/// Tombol bulat biru dengan lengkung indikator progres oranye di sisi kiri
class _CircularProgressNextButton extends StatelessWidget {
  final double progress;
  final VoidCallback onTap;

  const _CircularProgressNextButton({
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lengkung Oranye di tepi kiri tombol
          SizedBox(
            width: 65,
            height: 65,
            child: CustomPaint(
              painter: _LeftArcProgressPainter(
                progress: progress,
                arcColor: const Color(0xFFFFA800),
              ),
            ),
          ),

          // Lingkaran Utama Biru + Ikon Panah Diagonal
          Material(
            color: AppColors.primaryBlue,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 62,
                height: 62,
                child: Icon(
                  Icons.north_east_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftArcProgressPainter extends CustomPainter {
  final double progress;
  final Color arcColor;

  _LeftArcProgressPainter({
    required this.progress,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const startAngle = -math.pi / 2;
    final sweepAngle = -2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _LeftArcProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}