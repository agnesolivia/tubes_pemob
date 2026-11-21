import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
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
            // 1. Gambar Gelombang Atas
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave_top.png',
                width: size.width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 2. Gambar Gelombang Bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave_bottom.png',
                width: size.width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 3. Konten Utama Splash Screen
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 22),

                    // Gambar 1: Ilustrasi 3D Tangan Memegang HP
                    Image.asset(
                      'assets/images/splash_hand.png',
                      height: size.height * 0.30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const _FallbackHandIllustration();
                      },
                    ),

                    const SizedBox(height: 14),

                    // Gambar 2: Logo Nama "Snafix"
                    Image.asset(
                      'assets/images/snafix_logo.png',
                      width: size.width * 0.57,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const _FallbackLogoText();
                      },
                    ),

                    const SizedBox(height: 22),

                    // Tagline (Plus Jakarta Sans)
                    Text(
                      'Snap it. Fix it.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const Spacer(flex: 18),

                    // Versi Aplikasi (Plus Jakarta Sans)
                    Text(
                      'V1.01',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const Spacer(flex: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback sementara jika file splash_hand.png belum terbaca
class _FallbackHandIllustration extends StatelessWidget {
  const _FallbackHandIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      height: 195,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF0284C7), width: 4.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.build_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue, width: 3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback sementara jika file snafix_logo.png belum terbaca
class _FallbackLogoText extends StatelessWidget {
  const _FallbackLogoText();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: const [
          TextSpan(
            text: 'Sna',
            style: TextStyle(color: AppColors.white),
          ),
          TextSpan(
            text: 'fix',
            style: TextStyle(color: AppColors.accentYellow),
          ),
        ],
      ),
    );
  }
}