import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/widgets/admin_report_actions.dart';
import 'package:tubes_pemob/screens/pelapor/widgets/pelapor_report_actions.dart';
import 'package:tubes_pemob/screens/shared/history_aset_screen.dart';
import 'package:tubes_pemob/screens/teknisi/form_penyelesaian_screen.dart';
import 'package:tubes_pemob/screens/teknisi/widgets/teknisi_report_actions.dart';
import 'package:tubes_pemob/services/report_service.dart';

// ============================================================
// DETAIL LAPORAN SCREEN (STRUKTUR INTI LINTAS ROLE — UI RINGKAS)
// ============================================================

class DetailLaporanScreen extends StatefulWidget {
  /// Mode utama lintas role (`ReportModel` / `reportId`):
  final String? reportId;
  final ReportModel? initialReport;
  final UserRole userRole;

  /// Jika `true`, menekan tombol "Lihat Riwayat Aset" langsung `Navigator.pop()`
  /// agar tidak terjadi loop navigasi (Riwayat -> Detail -> Riwayat).
  final bool fromAssetHistory;

  /// Mode kompatibilitas sementara untuk layar Teknisi yang masih mengirim
  /// `TechnicianTaskItem`.
  final TechnicianTaskItem? task;
  final ValueChanged<ReportStatus>? onStatusChanged;
  final VoidCallback? onHistoryPressed;
  final CompletionSubmitCallback? onCompletionSubmit;

  const DetailLaporanScreen({
    super.key,
    this.reportId,
    this.initialReport,
    this.userRole = UserRole.pelapor,
    this.fromAssetHistory = false,
    this.task,
    this.onStatusChanged,
    this.onHistoryPressed,
    this.onCompletionSubmit,
  }) : assert(
         reportId != null || initialReport != null || task != null,
         'Minimal salah satu dari reportId, initialReport, atau task harus diisi.',
       );

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  Stream<ReportModel?>? _reportStream;
  late ReportStatus _legacyStatus;

  bool get _isReportMode =>
      widget.reportId != null || widget.initialReport != null;

  @override
  void initState() {
    super.initState();
    _legacyStatus = widget.task?.status ?? ReportStatus.reported;

    // Jika hanya reportId yang dikirim (misal dari Notifikasi), baca via stream.
    final id = widget.reportId ?? widget.initialReport?.id;
    if (_isReportMode && id != null && id.isNotEmpty) {
      _reportStream = ReportService.instance.streamReportById(id);
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  Uint8List? _decodeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final cleaned = raw.contains(',')
          ? raw.split(',').last.trim()
          : raw.trim();
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  _StatusVisual _statusVisual(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return const _StatusVisual(
          color: AppColors.textSecondary,
          background: AppColors.inputFill,
          icon: Icons.schedule_rounded,
        );
      case ReportStatus.verified:
        return const _StatusVisual(
          color: AppColors.primaryBlue,
          background: Color(0xFFE3EEFF),
          icon: Icons.verified_outlined,
        );
      case ReportStatus.assigned:
        return const _StatusVisual(
          color: AppColors.primaryBlue,
          background: Color(0xFFE3EEFF),
          icon: Icons.assignment_outlined,
        );
      case ReportStatus.inProgress:
        return const _StatusVisual(
          color: Color(0xFFC2410C),
          background: Color(0xFFFFF1E3),
          icon: Icons.build_rounded,
        );
      case ReportStatus.resolved:
        return const _StatusVisual(
          color: Color(0xFF15803D),
          background: Color(0xFFE1F7E9),
          icon: Icons.check_circle_outline_rounded,
        );
      case ReportStatus.rejected:
        return const _StatusVisual(
          color: AppColors.statusRejectedText,
          background: AppColors.statusRejectedBg,
          icon: Icons.cancel_outlined,
        );
    }
  }

  String _slaLabel({
    required ReportStatus status,
    required DateTime? deadlineAt,
    required bool isOverdue,
  }) {
    if (status == ReportStatus.resolved) return 'Selesai';
    if (status == ReportStatus.rejected) return 'Ditolak';
    if (deadlineAt == null) return 'Belum ditetapkan';

    final now = DateTime.now();
    if (isOverdue) {
      final diff = now.difference(deadlineAt);
      if (diff.inDays >= 1) return 'Terlambat ${diff.inDays} hari';
      if (diff.inHours >= 1) return 'Terlambat ${diff.inHours} jam';
      return 'Terlambat <1 jam';
    }

    final diff = deadlineAt.difference(now);
    if (diff.inDays >= 1) {
      final hours = diff.inHours % 24;
      return hours > 0
          ? 'Sisa ${diff.inDays} hari $hours jam'
          : 'Sisa ${diff.inDays} hari';
    }
    if (diff.inHours >= 1) return 'Sisa ${diff.inHours} jam';
    return 'Sisa <1 jam';
  }

  void _openAssetHistory({
    required String? assetId,
    required String assetNama,
    required String assetLokasi,
  }) {
    if (widget.fromAssetHistory) {
      Navigator.pop(context);
      return;
    }
    if (widget.onHistoryPressed != null) {
      widget.onHistoryPressed!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryAssetScreen(
          assetId: assetId,
          fallbackNama: assetNama,
          fallbackLokasi: assetLokasi,
          userRole: widget.userRole,
        ),
      ),
    );
  }

  void _openPhotoPreview(Uint8List bytes, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy Teknisi callbacks (kompatibilitas layar teknisi lama)
  void _legacyStartWorking() {
    if (_legacyStatus != ReportStatus.assigned) return;
    setState(() => _legacyStatus = ReportStatus.inProgress);
    widget.onStatusChanged?.call(ReportStatus.inProgress);
  }

  Future<void> _legacyOpenCompletionForm() async {
    final task = widget.task;
    if (task == null || _legacyStatus != ReportStatus.inProgress) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPenyelesaianScreen(
          task: task,
          onSubmit: widget.onCompletionSubmit,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _legacyStatus = ReportStatus.resolved);
      widget.onStatusChanged?.call(ReportStatus.resolved);
    }
  }

  /// Konversi `TechnicianTaskItem` ke `ReportModel` agar memakai 1 tampilan UI yang sama.
  ReportModel _taskToReportModel(TechnicianTaskItem task) {
    return ReportModel(
      id: task.id,
      assetId: task.assetId,
      assetNama: task.assetNama,
      assetLokasi: task.assetLokasi,
      pelaporId: '',
      pelaporNama: task.pelaporNama,
      deskripsi: task.reportDescription ?? '',
      fotoSebelum: '',
      status: _legacyStatus,
      prioritas: task.priority,
      deadlineAt: task.deadlineAt,
      createdAt: task.reportedAt ?? DateTime.now(),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (!_isReportMode) {
      final task = widget.task!;
      final report = _taskToReportModel(task);
      return _buildDetailScaffold(
        report: report,
        beforeBytes: task.fotoSebelumBytes,
        afterBytes: null,
        headerIcon: task.assetIcon,
        bottomBar: TeknisiReportActions(
          status: _legacyStatus,
          onStartWork: _legacyStartWorking,
          onCompleteWork: _legacyOpenCompletionForm,
        ),
      );
    }

    return StreamBuilder<ReportModel?>(
      stream: _reportStream,
      initialData: widget.initialReport,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStateScaffold(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.statusRejectedText,
            message: 'Gagal memuat detail laporan: ${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingScaffold();
        }

        final report = snapshot.data;
        if (report == null) {
          return _buildStateScaffold(
            icon: Icons.description_outlined,
            iconColor: AppColors.textSecondary,
            message: 'Laporan tidak ditemukan atau telah dibatalkan.',
          );
        }

        return _buildDetailScaffold(
          report: report,
          beforeBytes: _decodeBase64(report.fotoSebelum),
          afterBytes: _decodeBase64(report.fotoSesudah),
          headerIcon: report.hasRegisteredAsset
              ? Icons.inventory_2_rounded
              : Icons.help_outline_rounded,
          bottomBar: _buildRoleBottomBar(report),
        );
      },
    );
  }

  /// Memilih widget aksi per role dari folder masing-masing.
  Widget _buildRoleBottomBar(ReportModel report) {
    switch (widget.userRole) {
      case UserRole.admin:
        return AdminReportActions(report: report);
      case UserRole.teknisi:
        return TeknisiReportActions(status: report.status);
      case UserRole.pelapor:
        return PelaporReportActions(report: report);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Detail Laporan',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildStateScaffold({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: iconColor),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailScaffold({
    required ReportModel report,
    required Uint8List? beforeBytes,
    required Uint8List? afterBytes,
    required IconData headerIcon,
    required Widget bottomBar,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER ASET
              _buildAssetHeader(report, headerIcon),
              const SizedBox(height: 13),

              // 2. STATUS, KONFIRMASI, & SLA
              _buildStatusSlaCard(report),

              // 3. ALASAN PENOLAKAN (JIKA DITOLAK)
              if (report.status == ReportStatus.rejected &&
                  report.rejectionReason != null &&
                  report.rejectionReason!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildRejectionCard(report.rejectionReason!.trim()),
              ],

              const SizedBox(height: 20),

              // 4. INFORMASI DETAIL LAPORAN
              _buildReportInformation(report),
              const SizedBox(height: 20),

              // 5. DESKRIPSI MASALAH
              _buildProblemDescription(report.deskripsi),
              const SizedBox(height: 20),

              // 6. FOTO SEBELUM PERBAIKAN
              _buildPhotoSection(
                title: 'Foto Sebelum Perbaikan',
                bytes: beforeBytes,
                emptyText: 'Foto sebelum perbaikan belum tersedia',
              ),

              // 7. HASIL PERBAIKAN (FOTO SESUDAH & CATATAN TEKNISI)
              // Hanya tampil saat status resolved agar foto & catatan lama
              // yang gagal tidak muncul ketika tiket sedang di-reopen.
              if (report.status == ReportStatus.resolved &&
                  (afterBytes != null ||
                      (report.catatanTeknisi != null &&
                          report.catatanTeknisi!.trim().isNotEmpty))) ...[
                const SizedBox(height: 20),
                _buildResolutionSection(
                  afterBytes: afterBytes,
                  catatanTeknisi: report.catatanTeknisi,
                ),
              ],

              const SizedBox(height: 16),

              // 8. TOMBOL RIWAYAT ASET (SERAGAM SEMUA ROLE)
              _buildAssetHistoryButton(report),

              // 9. TIMELINE RIWAYAT STATUS
              if (report.riwayatStatus.isNotEmpty) ...[
                const SizedBox(height: 22),
                _buildStatusTimeline(report.riwayatStatus),
              ],
            ],
          ),
        ),
        bottomNavigationBar: bottomBar,
      ),
    );
  }

  // ==========================================================
  // SECTIONS (SERAGAM UNTUK SEMUA ROLE)
  // ==========================================================

  Widget _buildAssetHeader(ReportModel report, IconData headerIcon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: report.hasRegisteredAsset
                  ? const Color(0xFFE8F1FF)
                  : AppColors.statusProcessBg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              headerIcon,
              size: 32,
              color: report.hasRegisteredAsset
                  ? AppColors.primaryBlue
                  : AppColors.statusProcessText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!report.hasRegisteredAsset) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusProcessBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Belum Terdaftar di Inventaris',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusProcessText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  report.assetNama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.assetLokasi,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        report.pelaporNama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (report.prioritas != null) ...[
            const SizedBox(width: 8),
            _PriorityBadge(priority: report.prioritas!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSlaCard(ReportModel report) {
    final visual = _statusVisual(report.status);
    final slaText = _slaLabel(
      status: report.status,
      deadlineAt: report.deadlineAt,
      isOverdue: report.isOverdue,
    );
    final slaBg = report.isOverdue
        ? AppColors.statusRejectedBg
        : report.status == ReportStatus.resolved
        ? const Color(0xFFE1F7E9)
        : report.deadlineAt == null
        ? AppColors.inputFill
        : const Color(0xFFFFE9E9);
    final slaColor = report.isOverdue
        ? AppColors.statusRejectedText
        : report.status == ReportStatus.resolved
        ? const Color(0xFF15803D)
        : report.deadlineAt == null
        ? AppColors.textSecondary
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: visual.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(visual.icon, size: 16, color: visual.color),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              report.status.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: visual.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 52, color: AppColors.border),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sisa SLA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: slaBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: slaColor,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              slaText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: slaColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.isConfirmed || report.isAwaitingConfirmation) ...[
            const SizedBox(height: 11),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  report.isConfirmed
                      ? Icons.verified_rounded
                      : Icons.hourglass_bottom_rounded,
                  size: 16,
                  color: report.isConfirmed
                      ? AppColors.primaryBlue
                      : AppColors.statusProcessText,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    report.isConfirmed
                        ? 'Terkonfirmasi — Hasil perbaikan sudah disetujui.'
                        : 'Menunggu konfirmasi selesai dari Pelapor atau Admin.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: report.isConfirmed
                          ? AppColors.primaryBlue
                          : AppColors.statusProcessText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusRejectedBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.statusRejectedText.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: AppColors.statusRejectedText,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alasan Penolakan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.statusRejectedText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportInformation(ReportModel report) {
    final hasTeknisi =
        report.teknisiNama != null && report.teknisiNama!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Detail Laporan'),
        const SizedBox(height: 10),
        _detailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal Lapor',
          value: _formatDate(report.createdAt),
        ),
        if (report.deadlineAt != null)
          _detailRow(
            icon: Icons.event_outlined,
            label: 'Batas SLA',
            value: _formatDate(report.deadlineAt),
          ),
        _detailRow(
          icon: Icons.apartment_rounded,
          label: 'Lokasi',
          value: report.assetLokasi,
        ),
        _detailRow(
          icon: Icons.inventory_2_outlined,
          label: 'Aset',
          value: report.hasRegisteredAsset
              ? report.assetNama
              : '${report.assetNama} (Belum terdaftar)',
        ),
        _detailRow(
          icon: Icons.flag_outlined,
          label: 'Prioritas',
          value: report.prioritas?.label ?? 'Belum ditetapkan',
        ),
        if (hasTeknisi)
          _detailRow(
            icon: Icons.engineering_outlined,
            label: 'Teknisi',
            value: report.teknisiNama!,
          ),
        if (report.resolvedAt != null)
          _detailRow(
            icon: Icons.task_alt_rounded,
            label: 'Selesai Pada',
            value: _formatDate(report.resolvedAt),
          ),
      ],
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Deskripsi Masalah'),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.textSecondary,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  description.trim().isEmpty
                      ? 'Deskripsi laporan belum tersedia.'
                      : description.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection({
    required String title,
    required Uint8List? bytes,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 11),
        _buildPhotoContainer(bytes: bytes, title: title, emptyText: emptyText),
      ],
    );
  }

  Widget _buildResolutionSection({
    required Uint8List? afterBytes,
    required String? catatanTeknisi,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Hasil Perbaikan'),
        const SizedBox(height: 11),
        if (afterBytes != null) ...[
          _buildPhotoContainer(
            bytes: afterBytes,
            title: 'Foto Sesudah Perbaikan',
            emptyText: 'Foto hasil perbaikan belum tersedia',
          ),
          const SizedBox(height: 12),
        ],
        if (catatanTeknisi != null && catatanTeknisi.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F7E9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.handyman_outlined,
                  color: Color(0xFF15803D),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Teknisi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        catatanTeknisi.trim(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoContainer({
    required Uint8List? bytes,
    required String title,
    required String emptyText,
  }) {
    return GestureDetector(
      onTap: bytes != null ? () => _openPhotoPreview(bytes, title) : null,
      child: Container(
        width: double.infinity,
        height: 170,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPhotoPlaceholder(emptyText),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Perbesar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _buildPhotoPlaceholder(emptyText),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.image_outlined,
          color: AppColors.textSecondary,
          size: 38,
        ),
        const SizedBox(height: 7),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetHistoryButton(ReportModel report) {
    return InkWell(
      onTap: () => _openAssetHistory(
        assetId: report.assetId,
        assetNama: report.assetNama,
        assetLokasi: report.assetLokasi,
      ),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.statusDoneBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lihat Riwayat Aset',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    report.hasRegisteredAsset
                        ? 'Lihat rekam jejak kerusakan & perbaikan aset ini'
                        : 'Cek status inventaris fasilitas ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(List<StatusHistoryItem> items) {
    final ordered = items.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Riwayat Status'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Column(
            children: List.generate(ordered.length, (index) {
              final item = ordered[index];
              final isLast = index == ordered.length - 1;
              final visual = _statusVisual(item.status);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: index == 0 ? visual.color : AppColors.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.status.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: index == 0
                                          ? visual.color
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(item.timestamp),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (item.catatan.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.catatan,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (item.updatedBy.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Oleh ${item.updatedBy}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _StatusVisual {
  final Color color;
  final Color background;
  final IconData icon;

  const _StatusVisual({
    required this.color,
    required this.background,
    required this.icon,
  });
}

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late Color background;
    late IconData icon;

    switch (priority) {
      case ReportPriority.tinggi:
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE9E9);
        icon = Icons.keyboard_double_arrow_up_rounded;
        break;
      case ReportPriority.sedang:
        color = const Color(0xFFC2410C);
        background = const Color(0xFFFFF1E3);
        icon = Icons.drag_handle_rounded;
        break;
      case ReportPriority.rendah:
        color = const Color(0xFF15803D);
        background = const Color(0xFFE1F7E9);
        icon = Icons.keyboard_double_arrow_down_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
