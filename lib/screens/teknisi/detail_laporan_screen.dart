import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';

import 'package:tubes_pemob/screens/teknisi/form_penyelesaian_screen.dart';

// ============================================================
// DETAIL LAPORAN SCREEN
// ============================================================

class DetailLaporanScreen extends StatefulWidget {
  final TechnicianTaskItem task;

  // Callback perubahan status.
  final ValueChanged<ReportStatus>? onStatusChanged;

  // Callback menuju riwayat servis aset.
  final VoidCallback? onHistoryPressed;

  // Callback penyimpanan hasil perbaikan.
  final CompletionSubmitCallback? onCompletionSubmit;

  const DetailLaporanScreen({
    super.key,
    required this.task,
    this.onStatusChanged,
    this.onHistoryPressed,
    this.onCompletionSubmit,
  });

  @override
  State<DetailLaporanScreen> createState() =>
      _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  late ReportStatus _currentStatus;

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.task.status;
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color get _statusColor {
    switch (_currentStatus) {
      case ReportStatus.assigned:
        return AppColors.primaryBlue;

      case ReportStatus.inProgress:
        return const Color(0xFFC2410C);

      case ReportStatus.resolved:
        return const Color(0xFF15803D);

      default:
        return AppColors.textSecondary;
    }
  }

  Color get _statusBackground {
    switch (_currentStatus) {
      case ReportStatus.assigned:
        return const Color(0xFFE3EEFF);

      case ReportStatus.inProgress:
        return const Color(0xFFFFF1E3);

      case ReportStatus.resolved:
        return const Color(0xFFE1F7E9);

      default:
        return AppColors.background;
    }
  }

  // ==========================================================
  // SLA INFORMATION
  // ==========================================================

  bool get _isOverdue {
    return _currentStatus != ReportStatus.resolved &&
        widget.task.isOverdue;
  }

  String get _slaLabel {
    if (_currentStatus == ReportStatus.resolved) {
      return 'Selesai';
    }

    final now = DateTime.now();
    final deadline = widget.task.deadlineAt;

    if (_isOverdue) {
      final difference = now.difference(deadline);

      if (difference.inDays >= 1) {
        return 'Terlambat ${difference.inDays} hari';
      }

      if (difference.inHours >= 1) {
        return 'Terlambat ${difference.inHours} jam';
      }

      return 'Terlambat <1 jam';
    }

    final difference = deadline.difference(now);

    if (difference.inDays >= 1) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;

      if (hours > 0) {
        return 'Sisa $days hari $hours jam';
      }

      return 'Sisa $days hari';
    }

    if (difference.inHours >= 1) {
      return 'Sisa ${difference.inHours} jam';
    }

    return 'Sisa <1 jam';
  }

  Color get _slaColor {
    return _isOverdue
        ? AppColors.statusRejectedText
        : const Color(0xFFDC2626);
  }

  // ==========================================================
  // DATE FORMAT
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

    return '${date.day} ${months[date.month - 1]} '
        '${date.year}, $hour:$minute';
  }

  // ==========================================================
  // MULAI MENGERJAKAN TUGAS
  // ==========================================================

  void _startWorking() {
    if (_currentStatus != ReportStatus.assigned) return;

    setState(() {
      _currentStatus = ReportStatus.inProgress;
    });

    // Beritahu halaman pemanggil.
    // Backend nantinya menangani penyimpanan status
    // dan pengiriman notifikasi.
    widget.onStatusChanged?.call(
      ReportStatus.inProgress,
    );

    _showMessage('Tugas berhasil dimulai.');
  }

  // ==========================================================
  // BUKA FORM PENYELESAIAN
  // ==========================================================

  Future<void> _openCompletionForm() async {
    if (_currentStatus != ReportStatus.inProgress) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FormPenyelesaianScreen(
            task: widget.task,
            onSubmit: widget.onCompletionSubmit,
          );
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _currentStatus = ReportStatus.resolved;
      });

      widget.onStatusChanged?.call(
        ReportStatus.resolved,
      );

      _showMessage('Tugas berhasil diselesaikan.');
    }
  }

  // ==========================================================
  // RIWAYAT SERVIS ASET
  // ==========================================================

  void _openAssetHistory() {
    if (widget.onHistoryPressed != null) {
      widget.onHistoryPressed!();
      return;
    }

    _showMessage(
      'Halaman riwayat servis aset belum dihubungkan.',
    );
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),

      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
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
        ),

        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            22,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INFORMASI ASET
              _buildAssetHeader(),

              const SizedBox(height: 13),

              // STATUS DAN SLA
              _buildStatusSlaCard(),

              const SizedBox(height: 22),

              // DETAIL LAPORAN
              _buildReportInformation(),

              const SizedBox(height: 20),

              // DESKRIPSI MASALAH
              _buildProblemDescription(),

              const SizedBox(height: 20),

              // FOTO SEBELUM
              _buildBeforePhotoSection(),

              const SizedBox(height: 15),

              // RIWAYAT SERVIS ASET
              _buildAssetHistoryButton(),

              const SizedBox(height: 15),

              // INFORMATION BOX
              if (_currentStatus == ReportStatus.inProgress)
                const _TechnicianInformationBox(
                  message:
                      'Tugas sedang dikerjakan. Pastikan seluruh tindakan perbaikan telah dilakukan sebelum menyelesaikan tugas.',
                ),
            ],
          ),
        ),

        bottomNavigationBar: _buildBottomAction(),
      ),
    );
  }

  // ==========================================================
  // ASSET HEADER
  // ==========================================================

  Widget _buildAssetHeader() {
    final task = widget.task;

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: _cardDecoration(),

      child: Row(
        children: [
          Container(
            width: 75,
            height: 75,

            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(16),
            ),

            alignment: Alignment.center,

            child: Icon(
              task.assetIcon,
              size: 39,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.assetNama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  task.assetLokasi,
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
                        task.pelaporNama,
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

          _PriorityBadge(
            priority: task.priority,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS AND SLA
  // ==========================================================

  Widget _buildStatusSlaCard() {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: _cardDecoration(),

      child: Row(
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
                    color: _statusBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentStatus == ReportStatus.assigned
                            ? Icons.assignment_outlined
                            : _currentStatus == ReportStatus.inProgress
                                ? Icons.build_rounded
                                : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: _statusColor,
                      ),

                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          _currentStatus.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 52,
            color: AppColors.border,
          ),

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
                    color: _isOverdue
                        ? AppColors.statusRejectedBg
                        : const Color(0xFFFFE9E9),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: _slaColor,
                      ),

                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          _slaLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _slaColor,
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
    );
  }

  // ==========================================================
  // REPORT INFORMATION
  // ==========================================================

  Widget _buildReportInformation() {
    final task = widget.task;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Detail Laporan'),

        const SizedBox(height: 13),

        _detailRow(
          icon: Icons.confirmation_number_outlined,
          label: 'ID Laporan',
          value: '#${task.id}',
        ),

        _detailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal Lapor',
          value: _formatDate(task.reportedAt),
        ),

        _detailRow(
          icon: Icons.event_outlined,
          label: 'Batas SLA',
          value: _formatDate(task.deadlineAt),
        ),

        _detailRow(
          icon: Icons.apartment_rounded,
          label: 'Lokasi',
          value: task.assetLokasi,
        ),

        _detailRow(
          icon: Icons.inventory_2_outlined,
          label: 'Aset',
          value: task.assetId == null
              ? task.assetNama
              : '${task.assetNama} (${task.assetId})',
        ),

        _detailRow(
          icon: Icons.flag_outlined,
          label: 'Prioritas',
          value: task.priority.label,
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
          Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 105,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PROBLEM DESCRIPTION
  // ==========================================================

  Widget _buildProblemDescription() {
    final description = widget.task.reportDescription;

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
                  description == null || description.isEmpty
                      ? 'Deskripsi laporan belum tersedia.'
                      : description,

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
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

  // ==========================================================
  // FOTO SEBELUM
  // ==========================================================

  Widget _buildBeforePhotoSection() {
    final photoBytes = widget.task.fotoSebelumBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Foto Sebelum'),

        const SizedBox(height: 11),

        Container(
          width: double.infinity,
          height: 150,

          clipBehavior: Clip.antiAlias,

          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.border,
            ),
          ),

          child: photoBytes != null
              ? Image.memory(
                  photoBytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPhotoPlaceholder();
                  },
                )
              : _buildPhotoPlaceholder(),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
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
          'Foto sebelum perbaikan belum tersedia',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // HISTORY ASSET BUTTON
  // ==========================================================

  Widget _buildAssetHistoryButton() {
    return InkWell(
      onTap: _openAssetHistory,
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
                    'Riwayat Servis Aset',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Lihat riwayat perbaikan aset ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
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

  // ==========================================================
  // BOTTOM ACTION
  // ==========================================================

  Widget _buildBottomAction() {
    Widget button;

    if (_currentStatus == ReportStatus.assigned) {
      button = ElevatedButton.icon(
        onPressed: _startWorking,

        icon: const Icon(
          Icons.play_arrow_rounded,
          size: 23,
        ),

        label: Text(
          'Mulai Kerjakan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        style: _actionButtonStyle(
          AppColors.primaryBlue,
        ),
      );
    } else if (_currentStatus == ReportStatus.inProgress) {
      button = ElevatedButton.icon(
        onPressed: _openCompletionForm,

        icon: const Icon(
          Icons.check_rounded,
          size: 22,
        ),

        label: Text(
          'Selesaikan Tugas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        style: _actionButtonStyle(
          const Color(0xFF15803D),
        ),
      );
    } else {
      button = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),

        decoration: BoxDecoration(
          color: const Color(0xFFE1F7E9),
          borderRadius: BorderRadius.circular(13),
        ),

        child: Text(
          'Tugas Telah Diselesaikan',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF15803D),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        12,
      ),

      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),

      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: button,
        ),
      ),
    );
  }

  // ==========================================================
  // BUTTON STYLE
  // ==========================================================

  ButtonStyle _actionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: AppColors.white,
      elevation: 0,

      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

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

  // ==========================================================
  // CARD DECORATION
  // ==========================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: AppColors.border,
      ),
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

// ============================================================
// PRIORITY BADGE
// ============================================================

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;

  const _PriorityBadge({
    required this.priority,
  });

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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),

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

// ============================================================
// INFORMATION BOX
// ============================================================

class _TechnicianInformationBox extends StatelessWidget {
  final String message;

  const _TechnicianInformationBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryBlue,
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}