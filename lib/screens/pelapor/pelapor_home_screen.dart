import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/screens/pelapor/form_pengaduan_screen.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';

class PelaporHomeScreen extends StatefulWidget {
  const PelaporHomeScreen({super.key});

  @override
  State<PelaporHomeScreen> createState() => _PelaporHomeScreenState();
}

class _PelaporHomeScreenState extends State<PelaporHomeScreen> {
  int _selectedNavIndex = 0;

  void _onCreateReportPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateReportScreen(),
      ),
    );
  }

  void _onViewAllReportsPressed() {
    // Hubungkan ke halaman Riwayat Laporan di sini
    setState(() {
      _selectedNavIndex = 1;
    });
  }

  void _openProfileScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen()
      ),
    );
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
        extendBody: true,
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

            // 2. Konten Utama (Header Hero + Sheet Putih)
            Column(
              children: [
                // Bagian Header Atas
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                    child: Column(
                      children: [
                        // Baris Logo Snafix & Avatar Profil 'R'
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/images/snafix_logo.png',
                              width: size.width * 0.28,
                              fit: BoxFit.contain,
                            ),
                            GestureDetector(
                              onTap: _openProfileScreen,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B5CE6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        AppColors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: StreamBuilder<UserModel?>(
                                  stream: AuthService.instance.currentUser == null
                                      ? null
                                      : AuthService.instance.streamUserData(
                                          AuthService.instance.currentUser!.uid,
                                        ),
                                  builder: (context, snapshot) {
                                    final nama = snapshot.data?.nama ??
                                        AuthService
                                            .instance.currentUser?.displayName ??
                                        'U';
                                    final initial = nama.trim().isEmpty
                                        ? 'U'
                                        : nama.trim()[0].toUpperCase();
                                    return Text(
                                      initial,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Hero Teks Kiri & Ilustrasi 3D Kanan
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 54,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ada fasilitas\nyang rusak?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                      height: 1.2,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Foto, lapor, dan pantau\nperbaikannya.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.white
                                          .withValues(alpha: 0.9),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 46,
                              child: Image.asset(
                                'assets/images/home_hero.png',
                                height: size.height * 0.165,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return SizedBox(height: size.height * 0.165);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bagian Bawah: Container Putih Melengkung
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFBFD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Area Fixed Atas: Tombol "+ Buat Laporan Baru"
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFBFD),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFEEF2F7),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.24),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _onCreateReportPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 12.5,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFFFB800),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(
                                  'Buat Laporan Baru',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Area Scrollable: Ringkasan & Pantau Laporan Aktif
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 105),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section: Ringkasan Laporan Kamu
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ringkasan Laporan Kamu',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0A0D14),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _onViewAllReportsPressed,
                                      child: Text(
                                        'Total 7 Laporan',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // 3 Kartu Ringkasan Status
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _SummaryStatusCard(
                                        badgeText: 'Menunggu',
                                        badgeBgColor: Color(0xFFFEF3C7),
                                        badgeTextColor: Color(0xFFA16207),
                                        count: '1',
                                        subtitle: 'Menunggu verifikasi',
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _SummaryStatusCard(
                                        badgeText: 'Diproses',
                                        badgeBgColor: Color(0xFFDCFCE7),
                                        badgeTextColor: Color(0xFF15803D),
                                        count: '2',
                                        subtitle: 'Sedang jalan',
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _SummaryStatusCard(
                                        badgeText: 'Selesai',
                                        badgeBgColor: Color(0xFFDBEAFE),
                                        badgeTextColor: Color(0xFF1D4ED8),
                                        count: '4',
                                        subtitle: 'Telah diperbaiki',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 22),

                                // Header Section: Pantau Laporan Aktif
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pantau Laporan Aktif',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0A0D14),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _onViewAllReportsPressed,
                                      child: Text(
                                        'Lihat Semua',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Kartu Laporan Aktif
                                const _ActiveReportCard(
                                  ticketId: '#SNF-2026-089',
                                  statusText: 'Sedang Diperbaiki',
                                  title: 'AC Ruang Kelas D-104 Bocor',
                                  location:
                                      'Fakultas Ilmu Komputer dan Teknologi Informasi • Lantai 1 (R. D-104)',
                                  stageText:
                                      'Tahap 4/5: Teknisi sedang memperbaiki',
                                  progressPercent: '80%',
                                  completedSegments: 4,
                                  totalSegments: 5,
                                  feedbackText:
                                      'Teknisi sedang memperbaiki pipa pembuangan AC di Ruang D-104.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 3. Bottom Navigation Bar + Tombol Kamera Melayang
        bottomNavigationBar: _PelaporBottomNavBar(
          selectedIndex: _selectedNavIndex,
          onItemTapped: (index) {
            if (index == 3) {
              _openProfileScreen();
              return;
            }
            setState(() {
              _selectedNavIndex = index;
            });
          },
          onCameraPressed: _onCreateReportPressed,
        ),
      ),
    );
  }
}

/// Kartu Ringkasan Status (Menunggu / Diproses / Selesai)
class _SummaryStatusCard extends StatelessWidget {
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String count;
  final String subtitle;

  const _SummaryStatusCard({
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.count,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBF0F7), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A0D14),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B8798),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu Pemantauan Laporan Aktif
class _ActiveReportCard extends StatelessWidget {
  final String ticketId;
  final String statusText;
  final String title;
  final String location;
  final String stageText;
  final String progressPercent;
  final int completedSegments;
  final int totalSegments;
  final String feedbackText;

  const _ActiveReportCard({
    required this.ticketId,
    required this.statusText,
    required this.title,
    required this.location,
    required this.stageText,
    required this.progressPercent,
    required this.completedSegments,
    required this.totalSegments,
    required this.feedbackText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF6), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Ikon Fasilitas + ID & Judul + Badge Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kotak Ikon AC
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFDCE7FA)),
                ),
                alignment: Alignment.center,
                child: const _AcFacilityIcon(),
              ),
              const SizedBox(width: 12),

              // Detail ID, Judul, dan Lokasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ticketId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8A94A6),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0A0D14),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 13,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Baris Progress: Tahap & Persentase
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progressPercent,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar 5 Segmen
          Row(
            children: List.generate(totalSegments, (index) {
              final bool isDone = index < completedSegments;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == totalSegments - 1 ? 0 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primaryBlue
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Kotak Feedback Admin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Feedback Admin: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextSpan(text: feedbackText),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikon AC Split untuk kartu laporan aktif
class _AcFacilityIcon extends StatelessWidget {
  const _AcFacilityIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _AcIconPainter(),
    );
  }
}

class _AcIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Bodi unit AC atas
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 4, size.width - 4, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, paint);

    // Garis kisi ventilasi
    canvas.drawLine(
      const Offset(5, 11),
      Offset(size.width - 5, 11),
      paint,
    );

    // 3 gelombang hembusan udara di bawah AC
    for (final x in [7.5, 12.0, 16.5]) {
      final wavePath = Path()
        ..moveTo(x, 16)
        ..quadraticBezierTo(x - 1.5, 18, x, 20);
      canvas.drawPath(wavePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom Navigation Bar dengan Tombol Kamera Bulat di Tengah
class _PelaporBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onCameraPressed;

  const _PelaporBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onCameraPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 78 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bar Putih Utama
          Container(
            height: 64 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                _NavBarItem(
                  icon: Icons.assignment_outlined,
                  label: 'Riwayat',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),
                const SizedBox(width: 64), // Ruang untuk tombol kamera tengah
                _NavBarItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                ),
                _NavBarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                ),
              ],
            ),
          ),

          // Tombol Kamera Bulat Biru dengan Border Kuning di Tengah
          Positioned(
            top: 0,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onCameraPressed,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB800),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryBlue : const Color(0xFF8A94A6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}