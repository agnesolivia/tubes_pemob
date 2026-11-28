import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/pelapor/form_pengaduan_screen.dart';
import 'package:tubes_pemob/screens/pelapor/history_laporan_screen.dart';
import 'package:tubes_pemob/screens/shared/detail_laporan_screen.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/services/report_service.dart';
import 'package:tubes_pemob/services/storage_service.dart';

class PelaporHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;

  const PelaporHomeScreen({
    super.key,
    this.onSwitchTab,
  });

  void _onCreateReportPressed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateReportScreen(),
      ),
    );
  }

  void _onViewAllReportsPressed(BuildContext context) {
    if (onSwitchTab != null) {
      onSwitchTab!(1);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RiwayatLaporanPage(),
      ),
    );
  }

  void _openProfileScreen(BuildContext context) {
    if (onSwitchTab != null) {
      onSwitchTab!(3);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  ({int step, String percent, String stageText}) _progressFromStatus(
    ReportStatus status,
  ) {
    switch (status) {
      case ReportStatus.reported:
        return (
          step: 1,
          percent: '20%',
          stageText: 'Tahap 1/5: Menunggu verifikasi Admin',
        );
      case ReportStatus.verified:
        return (
          step: 2,
          percent: '40%',
          stageText: 'Tahap 2/5: Diverifikasi, menunggu teknisi',
        );
      case ReportStatus.assigned:
        return (
          step: 3,
          percent: '60%',
          stageText: 'Tahap 3/5: Teknisi telah ditugaskan',
        );
      case ReportStatus.inProgress:
        return (
          step: 4,
          percent: '80%',
          stageText: 'Tahap 4/5: Teknisi sedang memperbaiki',
        );
      case ReportStatus.resolved:
        return (
          step: 5,
          percent: '100%',
          stageText: 'Tahap 5/5: Perbaikan selesai',
        );
      case ReportStatus.rejected:
        return (
          step: 1,
          percent: '0%',
          stageText: 'Laporan ditolak Admin',
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
                        // Baris Logo SnaFix & Avatar Profil
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/images/snafix_logo.png',
                              width: size.width * 0.28,
                              fit: BoxFit.contain,
                            ),
                            GestureDetector(
                              onTap: () => _openProfileScreen(context),
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
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: StreamBuilder<UserModel?>(
                                  stream:
                                      AuthService.instance.currentUser == null
                                          ? null
                                          : AuthService.instance.streamUserData(
                                              AuthService
                                                  .instance.currentUser!.uid,
                                            ),
                                            
                                  builder: (context, snapshot) {
                                    final user = snapshot.data;
                                    final nama = user?.nama ??
                                        AuthService.instance.currentUser
                                            ?.displayName ??
                                        'U';
                                    final initial = nama.trim().isEmpty
                                        ? 'U'
                                        : nama.trim()[0].toUpperCase();

                                    final bytes = StorageService.instance
                                        .base64ToBytes(user?.photoBase64);
                                    if (bytes != null) {
                                      return ClipOval(
                                        child: Image.memory(
                                          bytes,
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }

                                    final photoUrl = AuthService
                                        .instance.currentUser?.photoURL;
                                    if (photoUrl != null &&
                                        photoUrl.isNotEmpty) {
                                      return ClipOval(
                                        child: Image.network(
                                          photoUrl,
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Text(
                                            initial,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

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
                                onPressed: () =>
                                    _onCreateReportPressed(context),
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
                          child: StreamBuilder<List<ReportModel>>(
                            stream: AuthService.instance.currentUser == null
                                ? null
                                : ReportService.instance.streamReportsByPelapor(
                                    AuthService.instance.currentUser!.uid,
                                  ),
                            builder: (context, snapshot) {
                              final reports = snapshot.data ?? [];
                              final menunggu = reports
                                  .where(
                                      (r) => r.status == ReportStatus.reported)
                                  .length;
                              final diproses = reports
                                  .where((r) =>
                                      r.status == ReportStatus.verified ||
                                      r.status == ReportStatus.assigned ||
                                      r.status == ReportStatus.inProgress)
                                  .length;
                              final selesai = reports
                                  .where(
                                      (r) => r.status == ReportStatus.resolved)
                                  .length;
                              final activeReports =
                                  reports.where((r) => !r.isClosed).toList();

                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 105),
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
                                          onTap: () =>
                                              _onViewAllReportsPressed(context),
                                          child: Text(
                                            'Total ${reports.length} Laporan',
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
                                          child: _SummaryStatusCard(
                                            badgeText: 'Menunggu',
                                            badgeBgColor:
                                                const Color(0xFFFEF3C7),
                                            badgeTextColor:
                                                const Color(0xFFA16207),
                                            count: '$menunggu',
                                            subtitle: 'Menunggu verifikasi',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _SummaryStatusCard(
                                            badgeText: 'Diproses',
                                            badgeBgColor:
                                                const Color(0xFFDCFCE7),
                                            badgeTextColor:
                                                const Color(0xFF15803D),
                                            count: '$diproses',
                                            subtitle: 'Sedang jalan',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _SummaryStatusCard(
                                            badgeText: 'Selesai',
                                            badgeBgColor:
                                                const Color(0xFFDBEAFE),
                                            badgeTextColor:
                                                const Color(0xFF1D4ED8),
                                            count: '$selesai',
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
                                          onTap: () =>
                                              _onViewAllReportsPressed(context),
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

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (activeReports.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                              color: const Color(0xFFE8EEF6)),
                                        ),
                                        child: Text(
                                          'Belum ada laporan aktif saat ini.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    else
                                      ...activeReports.take(3).map((report) {
                                        final prog =
                                            _progressFromStatus(report.status);
                                        final shortId = report.id.length > 8
                                            ? report.id
                                                .substring(0, 8)
                                                .toUpperCase()
                                            : report.id.toUpperCase();
                                        final latestNote = report
                                                .riwayatStatus.isNotEmpty
                                            ? report.riwayatStatus.last.catatan
                                            : report.deskripsi;

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      DetailLaporanScreen(
                                                    reportId: report.id,
                                                    initialReport: report,
                                                    userRole: UserRole.pelapor,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: _ActiveReportCard(
                                              ticketId: '#$shortId',
                                              statusText: report.status.label,
                                              title: report.assetNama,
                                              location: report.assetLokasi,
                                              stageText: prog.stageText,
                                              progressPercent: prog.percent,
                                              completedSegments: prog.step,
                                              totalSegments: 5,
                                              feedbackText: latestNote,
                                              fotoSebelum: report.fotoSebelum,
                                            ),
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              );
                            },
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
  final String fotoSebelum;

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
    required this.fotoSebelum,
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
              // Foto Sebelum Kerusakan
              Builder(
                builder: (_) {
                  final photoBytes =
                      StorageService.instance.base64ToBytes(fotoSebelum);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7FF),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFDCE7FA)),
                      ),
                      alignment: Alignment.center,
                      child: photoBytes != null
                          ? Image.memory(
                              photoBytes,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: AppColors.primaryBlue,
                              size: 22,
                            ),
                    ),
                  );
                },
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