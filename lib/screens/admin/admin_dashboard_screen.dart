import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/kelola_aset_screen.dart';
import 'package:tubes_pemob/screens/admin/kelola_laporan_screen.dart';
import 'package:tubes_pemob/screens/admin/kelola_teknisi_screen.dart';
import 'package:tubes_pemob/screens/admin/widgets/dashboard_hero_illustration.dart';
import 'package:tubes_pemob/screens/shared/detail_laporan_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';
import 'package:tubes_pemob/widgets/report_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  final ValueChanged<String>? onOpenTicketsWithFilter;

  const AdminDashboardScreen({
    super.key,
    this.onSwitchTab,
    this.onOpenTicketsWithFilter,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const int _resolvedWindowDays = 30;

  late final Stream<List<ReportModel>> _reportsStream;
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    _reportsStream = ReportService.instance.streamAllReports();
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _userStream = AuthService.instance.streamUserData(uid);
    }
  }

  void _onManageAssetsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KelolaAsetScreen()),
    );
  }

  void _onManageTechniciansPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KelolaTeknisiScreen()),
    );
  }

  void _openTickets({
    String statusFilter = KelolaLaporanScreen.allStatusKey,
  }) {
    if (widget.onOpenTicketsWithFilter != null) {
      widget.onOpenTicketsWithFilter!(statusFilter);
      return;
    }
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(1);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KelolaLaporanScreen(
          showBackButton: true,
          initialStatusFilter: statusFilter,
        ),
      ),
    );
  }

  void _onProfilePressed() {
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(3);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Halaman Profil Admin hanya tersedia dari navigasi utama.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openReportDetail(ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailLaporanScreen(
          reportId: report.id,
          initialReport: report,
          userRole: UserRole.admin,
        ),
      ),
    );
  }

  DateTime _latestActivityTime(ReportModel report) {
    if (report.riwayatStatus.isNotEmpty) {
      return report.riwayatStatus.last.timestamp;
    }
    return report.createdAt;
  }

  bool _isResolvedWithinWindow(ReportModel report, DateTime cutoff) {
    if (report.status != ReportStatus.resolved) return false;
    final resolvedTime = report.resolvedAt ?? report.createdAt;
    return !resolvedTime.isBefore(cutoff);
  }

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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave_top.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildPinnedAppBar(size),
                _buildHeroSection(size),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFBFD),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickActionsBar(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 115),
                          child: _buildDashboardStreamBody(),
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

  SliverAppBar _buildPinnedAppBar(Size size) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primaryBlue,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: 22,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/snafix_logo.png',
            width: size.width * 0.28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              'SnaFix',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.45),
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
                      style: GoogleFonts.plusJakartaSans(
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
                      color: AppColors.white.withValues(alpha: 0.4),
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
                    stream: _userStream,
                    builder: (context, snapshot) {
                      final nama = snapshot.data?.nama ??
                          AuthService.instance.currentUser?.displayName ??
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
    );
  }

  SliverToBoxAdapter _buildHeroSection(Size size) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard\nPantauan',
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
                    'Pantau laporan,\npenanganan fasilitas,\ndan status SLA.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 46,
              child: DashboardHeroIllustration(height: size.height * 0.165),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(bottom: BorderSide(color: Color(0xFFEEF2F7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _onManageTechniciansPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12.5,
                  ),
                  side: const BorderSide(color: Color(0xFFFFB800), width: 1.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.engineering_rounded, size: 18),
                label: Flexible(
                  child: Text(
                    'Kelola Teknisi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _onManageAssetsPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12.5,
                ),
                side: BorderSide(
                  color: AppColors.primaryBlue.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Flexible(
                child: Text(
                  'Kelola Aset',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStreamBody() {
    return StreamBuilder<List<ReportModel>>(
      stream: _reportsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return _EmptyStateCard(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat data pantauan',
            description: '${snapshot.error}',
            iconColor: AppColors.statusRejectedText,
            backgroundColor: AppColors.statusRejectedBg,
          );
        }

        final allReports = snapshot.data ?? const <ReportModel>[];
        final resolvedCutoff = DateTime.now().subtract(
          const Duration(days: _resolvedWindowDays),
        );

        // Pola Hybrid:
        // - Dilaporkan & Diproses: seluruh tiket aktif saat ini (tanpa batas waktu)
        // - Selesai: dibatasi 30 hari terakhir agar angka tidak menumpuk
        final reportedCount =
            allReports.where((r) => r.status == ReportStatus.reported).length;
        final processingCount = allReports
            .where(
              (r) =>
                  r.status == ReportStatus.verified ||
                  r.status == ReportStatus.assigned ||
                  r.status == ReportStatus.inProgress,
            )
            .length;
        final resolvedRecentCount = allReports
            .where((r) => _isResolvedWithinWindow(r, resolvedCutoff))
            .length;

        final overdueReports = allReports.where((r) => r.isOverdue).toList()
          ..sort((a, b) {
            if (a.deadlineAt == null && b.deadlineAt == null) return 0;
            if (a.deadlineAt == null) return 1;
            if (b.deadlineAt == null) return -1;
            return a.deadlineAt!.compareTo(b.deadlineAt!);
          });

        final recentReports = List<ReportModel>.from(allReports)
          ..sort(
            (a, b) =>
                _latestActivityTime(b).compareTo(_latestActivityTime(a)),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummarySection(
              totalTickets: allReports.length,
              reportedCount: reportedCount,
              processingCount: processingCount,
              resolvedRecentCount: resolvedRecentCount,
            ),
            const SizedBox(height: 22),
            _buildOverdueSection(overdueReports),
            const SizedBox(height: 22),
            _buildRecentActivitySection(recentReports.take(5).toList()),
          ],
        );
      },
    );
  }

  Widget _buildSummarySection({
    required int totalTickets,
    required int reportedCount,
    required int processingCount,
    required int resolvedRecentCount,
  }) {
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
              onTap: () => _openTickets(),
              child: Text(
                'Total $totalTickets Tiket',
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
        Row(
          children: [
            Expanded(
              child: _SummaryTicketCard(
                badgeText: 'Dilaporkan',
                badgeBgColor: AppColors.statusProcessBg,
                badgeTextColor: AppColors.statusProcessText,
                count: '$reportedCount',
                periodLabel: 'Aktif',
                icon: Icons.campaign_outlined,
                onTap: () =>
                    _openTickets(statusFilter: ReportStatus.reported.value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTicketCard(
                badgeText: 'Diproses',
                badgeBgColor: AppColors.statusDoneBg,
                badgeTextColor: AppColors.primaryBlue,
                count: '$processingCount',
                periodLabel: 'Aktif',
                icon: Icons.handyman_outlined,
                onTap: () => _openTickets(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTicketCard(
                badgeText: 'Selesai',
                badgeBgColor: AppColors.statusSuccessBg,
                badgeTextColor: AppColors.statusSuccessText,
                count: '$resolvedRecentCount',
                periodLabel: '$_resolvedWindowDays hari',
                icon: Icons.check_circle_outline_rounded,
                onTap: () =>
                    _openTickets(statusFilter: ReportStatus.resolved.value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverdueSection(List<ReportModel> overdueReports) {
    final visibleOverdue = overdueReports.take(5).toList();

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
                  'Overdue SLA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A0D14),
                  ),
                ),
                if (overdueReports.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${overdueReports.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (overdueReports.isNotEmpty)
              GestureDetector(
                onTap: () => _openTickets(
                  statusFilter: KelolaLaporanScreen.overdueStatusKey,
                ),
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
        if (overdueReports.isEmpty)
          const _EmptyStateCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Tidak ada tiket Overdue SLA',
            description:
                'Seluruh tiket aktif masih berada dalam batas waktu SLA.',
            iconColor: Color(0xFF16A36A),
            backgroundColor: Color(0xFFF0FBF5),
          )
        else
          for (int i = 0; i < visibleOverdue.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ReportCard.overdue(
              report: visibleOverdue[i],
              onTap: () => _openReportDetail(visibleOverdue[i]),
            ),
          ],
      ],
    );
  }

  Widget _buildRecentActivitySection(List<ReportModel> recentReports) {
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
              onTap: () => _openTickets(),
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
        if (recentReports.isEmpty)
          const _EmptyStateCard(
            icon: Icons.history_rounded,
            title: 'Belum ada aktivitas terbaru',
            description:
                'Aktivitas laporan dan penanganan fasilitas akan ditampilkan di sini.',
            iconColor: AppColors.primaryBlue,
            backgroundColor: Color(0xFFF2F7FF),
          )
        else
          for (int i = 0; i < recentReports.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ReportCard.activity(
              report: recentReports[i],
              onTap: () => _openReportDetail(recentReports[i]),
            ),
          ],
      ],
    );
  }
}

class _SummaryTicketCard extends StatelessWidget {
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String count;
  final String periodLabel;
  final IconData icon;
  final VoidCallback? onTap;

  const _SummaryTicketCard({
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.count,
    required this.periodLabel,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBF0F7)),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
              const SizedBox(height: 9),
              Icon(icon, size: 22, color: badgeTextColor),
              const SizedBox(height: 4),
              Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0A0D14),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                periodLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBF0F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 23),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
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
