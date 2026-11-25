import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/kelola_aset_screen.dart';
import 'package:tubes_pemob/screens/admin/kelola_teknisi_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';

// ============================================================
// ADMIN DASHBOARD SCREEN
// ============================================================

class AdminDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const AdminDashboardScreen({
    super.key,
    this.onSwitchTab,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Statistik akan diisi ketika backend sudah terintegrasi.
  final int _totalTickets = 0;
  final int _reportedCount = 0;
  final int _processingCount = 0;
  final int _resolvedCount = 0;
  final int _overdueCount = 0;

  // ==========================================================
  // NAVIGATION HANDLER
  // ==========================================================

  void _onManageAssetsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KelolaAsetScreen(),
      ),
    );
  }

  void _onManageTechniciansPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KelolaTeknisiScreen(),
      ),
    );
  }

  void _onViewAllTicketsPressed() {
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(1);
      return;
    }

    _showMessage('Halaman Kelola Laporan belum dihubungkan.');
  }

  void _onProfilePressed() {
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(3);
      return;
    }

    _showMessage('Halaman Profil Admin belum dihubungkan.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
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
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 2. Konten Utama
            Column(
              children: [
                // Header Dashboard Admin
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      18,
                    ),
                    child: Column(
                      children: [
                        // Logo SnaFix dan Avatar Admin
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/images/snafix_logo.png',
                              width: size.width * 0.28,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  'SnaFix',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                );
                              },
                            ),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.white
                                          .withValues(alpha: 0.45),
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 15,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Admin',
                                        style:
                                            GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                GestureDetector(
                                  onTap: _onProfilePressed,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B5CE6),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white
                                            .withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: StreamBuilder<UserModel?>(
                                      stream: AuthService.instance.currentUser ==
                                              null
                                          ? null
                                          : AuthService.instance.streamUserData(
                                              AuthService
                                                  .instance.currentUser!.uid,
                                            ),
                                      builder: (context, snapshot) {
                                        final nama = snapshot.data?.nama ??
                                            AuthService.instance.currentUser
                                                ?.displayName ??
                                            'A';
                                        final initial = nama.trim().isEmpty
                                            ? 'A'
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Hero Text dan Ilustrasi Dashboard
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 54,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dashboard\nPantauan',
                                    style:
                                        GoogleFonts.plusJakartaSans(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                      height: 1.2,
                                      letterSpacing: -0.4,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    'Pantau laporan,\npenanganan fasilitas,\ndan status SLA.',
                                    style:
                                        GoogleFonts.plusJakartaSans(
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
                              child: DashboardHeroIllustration(
                                height: size.height * 0.165,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Bagian Bawah: Container Putih
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

                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        22,
                        20,
                        115,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ringkasan Tiket
                          _buildSummarySection(),

                          const SizedBox(height: 24),

                          // Tombol Kelola Teknisi
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _onManageTechniciansPressed,
                              icon: const Icon(
                                Icons.engineering_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Kelola Teknisi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          // Tombol Kelola Aset
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _onManageAssetsPressed,
                              icon: const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                              ),
                              label: Text(
                                'Kelola Aset',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          // Peringatan Overdue SLA
                          _buildOverdueSection(),

                          const SizedBox(height: 24),

                          // Aktivitas Terbaru
                          _buildRecentActivitySection(),
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

  // ==========================================================
  // RINGKASAN TIKET
  // ==========================================================

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Tiket',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A0D14),
              ),
            ),

            GestureDetector(
              onTap: _onViewAllTicketsPressed,
              child: Text(
                'Total $_totalTickets Tiket',
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
          children: [
            Expanded(
              child: _SummaryTicketCard(
                badgeText: 'Dilaporkan',
                badgeBgColor: AppColors.statusProcessBg,
                badgeTextColor: AppColors.statusProcessText,
                count: _reportedCount.toString(),
                icon: Icons.campaign_outlined,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _SummaryTicketCard(
                badgeText: 'Diproses',
                badgeBgColor: AppColors.statusSuccessBg,
                badgeTextColor: AppColors.statusSuccessText,
                count: _processingCount.toString(),
                icon: Icons.handyman_outlined,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _SummaryTicketCard(
                badgeText: 'Selesai',
                badgeBgColor: AppColors.statusDoneBg,
                badgeTextColor: AppColors.statusDoneText,
                count: _resolvedCount.toString(),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // PERINGATAN OVERDUE SLA
  // ==========================================================

  Widget _buildOverdueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Color(0xFFDC2626),
                ),

                const SizedBox(width: 7),

                Text(
                  'Peringatan Overdue SLA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A0D14),
                  ),
                ),
              ],
            ),

            Text(
              '$_overdueCount Tiket',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Empty State
        const _EmptyStateCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Belum ada data Overdue SLA',
          description:
              'Tiket yang melewati batas waktu penyelesaian akan ditampilkan di sini.',
          iconColor: Color(0xFF16A36A),
          backgroundColor: Color(0xFFF0FBF5),
        ),
      ],
    );
  }

  // ==========================================================
  // AKTIVITAS TERBARU
  // ==========================================================

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A0D14),
              ),
            ),

            GestureDetector(
              onTap: _onViewAllTicketsPressed,
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

        // Empty State
        const _EmptyStateCard(
          icon: Icons.history_rounded,
          title: 'Belum ada aktivitas terbaru',
          description:
              'Aktivitas laporan dan penanganan fasilitas akan ditampilkan di sini.',
          iconColor: AppColors.primaryBlue,
          backgroundColor: Color(0xFFF2F7FF),
        ),
      ],
    );
  }
}

// ============================================================
// KARTU RINGKASAN STATUS TIKET
// ============================================================

class _SummaryTicketCard extends StatelessWidget {
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String count;
  final IconData icon;

  const _SummaryTicketCard({
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEBF0F7),
          width: 1,
        ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Icon(
            icon,
            size: 23,
            color: badgeTextColor,
          ),

          const SizedBox(height: 5),

          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A0D14),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE CARD
// ============================================================

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color backgroundColor;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 19,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEBF0F7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7B8798),
                    height: 1.4,
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

// ============================================================
// ILUSTRASI DASHBOARD ADMIN
// ============================================================

class DashboardHeroIllustration extends StatelessWidget {
  final double height;

  const DashboardHeroIllustration({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kartu statistik
          Positioned(
            right: 3,
            top: 4,
            child: Container(
              width: 112,
              height: height * 0.82,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD8E7FF),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33002374),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      _IllustrationDot(color: Color(0xFFFF7777)),
                      SizedBox(width: 4),
                      _IllustrationDot(color: Color(0xFFFFC34D)),
                      SizedBox(width: 4),
                      _IllustrationDot(color: Color(0xFF5ACB9B)),
                      Spacer(),
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Laporan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _IllustrationBar(
                          height: 25,
                          color: Color(0xFF8EBBFF),
                        ),
                        _IllustrationBar(
                          height: 38,
                          color: Color(0xFF438DFF),
                        ),
                        _IllustrationBar(
                          height: 31,
                          color: Color(0xFF65A5FF),
                        ),
                        _IllustrationBar(
                          height: 46,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7EEF8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ilustrasi admin
          Positioned(
            left: 0,
            bottom: 5,
            child: Container(
              width: 67,
              height: height * 0.62,
              decoration: BoxDecoration(
                color: const Color(0xFFB9DAFF),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 53,
                color: Color(0xFF1767D8),
              ),
            ),
          ),

          // Laptop
          Positioned(
            left: 12,
            bottom: 0,
            child: Container(
              width: 88,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF274E85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.laptop_mac_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),

          // Notifikasi
          const Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFFC12F),
              size: 25,
            ),
          ),

          // Aksen
          const Positioned(
            left: 0,
            top: 18,
            child: Icon(
              Icons.cloud_rounded,
              color: Color(0xFFB9D9FF),
              size: 23,
            ),
          ),

          const Positioned(
            right: 0,
            bottom: 18,
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF9FD5FF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KOMPONEN ILUSTRASI
// ============================================================

class _IllustrationDot extends StatelessWidget {
  final Color color;

  const _IllustrationDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _IllustrationBar extends StatelessWidget {
  final double height;
  final Color color;

  const _IllustrationBar({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(4),
        ),
      ),
    );
  }
}