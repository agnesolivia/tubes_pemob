import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/widgets/status_badge.dart';

enum _ReportCardVariant { compact, overdue, activity }

/// Kartu ringkasan laporan bergaya ringkas (compact) yang dipakai lintas halaman:
/// - `ReportCard(...)`: daftar laporan umum (Kelola Laporan, Riwayat, Tugas)
/// - `ReportCard.overdue(...)`: peringatan Overdue SLA di Dashboard
/// - `ReportCard.activity(...)`: aktivitas terbaru di Dashboard
class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  final _ReportCardVariant _variant;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  }) : _variant = _ReportCardVariant.compact;

  const ReportCard.overdue({
    super.key,
    required this.report,
    required this.onTap,
  }) : _variant = _ReportCardVariant.overdue;

  const ReportCard.activity({
    super.key,
    required this.report,
    required this.onTap,
  }) : _variant = _ReportCardVariant.activity;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _formatShortDate(DateTime date, {bool includeYear = false}) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return includeYear
        ? '$day $month ${date.year}, $hour:$minute'
        : '$day $month, $hour:$minute';
  }

  String _overdueLabel(DateTime? deadlineAt) {
    if (deadlineAt == null) return 'Overdue';
    final diff = DateTime.now().difference(deadlineAt);
    if (diff.inDays >= 1) return 'Lewat ${diff.inDays} hari';
    if (diff.inHours >= 1) return 'Lewat ${diff.inHours} jam';
    return 'Lewat <1 jam';
  }

  String _slaShortText() {
    final deadline = report.deadlineAt;
    if (deadline == null || report.isClosed) return '';

    final now = DateTime.now();
    if (report.isOverdue) {
      final diff = now.difference(deadline);
      if (diff.inDays >= 1) return 'Lewat ${diff.inDays}h';
      if (diff.inHours >= 1) return 'Lewat ${diff.inHours}j';
      return 'Overdue';
    }

    final diff = deadline.difference(now);
    if (diff.inDays >= 1) return 'SLA ${diff.inDays}h';
    if (diff.inHours >= 1) return 'SLA ${diff.inHours}j';
    return 'SLA <1j';
  }

  @override
  Widget build(BuildContext context) {
    final isAlertBorder =
        _variant == _ReportCardVariant.overdue || report.isOverdue;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAlertBorder
                  ? AppColors.statusRejectedText.withValues(alpha: 0.35)
                  : const Color(0xFFE8EEF6),
            ),
            boxShadow: [
              BoxShadow(
                color: (isAlertBorder
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0F172A))
                    .withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: switch (_variant) {
            _ReportCardVariant.compact => _buildCompactContent(),
            _ReportCardVariant.overdue => _buildOverdueContent(),
            _ReportCardVariant.activity => _buildActivityContent(),
          },
        ),
      ),
    );
  }

  // ==========================================================
  // VARIANT 1: COMPACT LIST (KELOLA LAPORAN / DAFTAR TIKET)
  // ==========================================================

  Widget _buildCompactContent() {
    final slaText = _slaShortText();
    final hasTeknisi =
        report.teknisiNama != null && report.teknisiNama!.trim().isNotEmpty;
    final actorLabel = hasTeknisi
        ? '${report.pelaporNama} • ${report.teknisiNama}'
        : report.pelaporNama;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris 1: Status, Prioritas, & Tag Penting + Panah
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  StatusBadge(status: report.status),
                  if (report.prioritas != null)
                    PriorityBadge(priority: report.prioritas!),
                  if (report.isOverdue)
                    const ReportBadgeChip(
                      label: 'Overdue',
                      backgroundColor: AppColors.statusRejectedBg,
                      foregroundColor: AppColors.statusRejectedText,
                    ),
                  if (!report.hasRegisteredAsset)
                    const ReportBadgeChip(
                      label: 'Belum Terdaftar',
                      backgroundColor: AppColors.statusProcessBg,
                      foregroundColor: AppColors.statusProcessText,
                    ),
                  if (report.isConfirmed)
                    const ReportBadgeChip(
                      label: 'Terkonfirmasi',
                      backgroundColor: AppColors.inputFill,
                      foregroundColor: AppColors.primaryBlue,
                    )
                  else if (report.isAwaitingConfirmation)
                    const ReportBadgeChip(
                      label: 'Perlu Konfirmasi',
                      backgroundColor: AppColors.statusProcessBg,
                      foregroundColor: AppColors.statusProcessText,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Baris 2: Nama Aset • Lokasi + Indikator SLA singkat
        Row(
          children: [
            Expanded(
              child: Text(
                '${report.assetNama} • ${report.assetLokasi}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (slaText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.access_time_rounded,
                size: 12.5,
                color: report.isOverdue
                    ? AppColors.statusRejectedText
                    : AppColors.primaryBlue,
              ),
              const SizedBox(width: 3),
              Text(
                slaText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: report.isOverdue
                      ? AppColors.statusRejectedText
                      : AppColors.primaryBlue,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),

        // Baris 3: Deskripsi 1 baris agar tinggi kartu tetap padat
        Text(
          report.deskripsi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 7),

        // Baris 4: Pelapor • Teknisi & Tanggal
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 13.5,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                actorLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatShortDate(report.createdAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // VARIANT 2: OVERDUE SLA (DASHBOARD ADMIN)
  // ==========================================================

  Widget _buildOverdueContent() {
    final hasTeknisi =
        report.teknisiNama != null && report.teknisiNama!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReportBadgeChip(
              label: _overdueLabel(report.deadlineAt),
              icon: Icons.access_time_filled_rounded,
              backgroundColor: AppColors.statusRejectedBg,
              foregroundColor: AppColors.statusRejectedText,
            ),
            const SizedBox(width: 6),
            StatusBadge(status: report.status),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${report.assetNama} • ${report.assetLokasi}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.engineering_outlined,
              size: 13.5,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                hasTeknisi
                    ? 'Teknisi: ${report.teknisiNama}'
                    : 'Belum ada teknisi ditugaskan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasTeknisi
                      ? AppColors.textPrimary
                      : AppColors.statusProcessText,
                ),
              ),
            ),
            if (report.prioritas != null) ...[
              const SizedBox(width: 6),
              PriorityBadge(priority: report.prioritas!),
            ],
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // VARIANT 3: AKTIVITAS TERBARU (DASHBOARD ADMIN)
  // ==========================================================

  Widget _buildActivityContent() {
    final latestLog =
        report.riwayatStatus.isNotEmpty ? report.riwayatStatus.last : null;
    final activityTime = latestLog?.timestamp ?? report.createdAt;
    final subtitleText =
        (latestLog != null && latestLog.catatan.trim().isNotEmpty)
            ? latestLog.catatan.trim()
            : report.deskripsi;
    final actorName =
        (latestLog != null && latestLog.updatedBy.trim().isNotEmpty)
            ? latestLog.updatedBy.trim()
            : report.pelaporNama;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(status: report.status),
            if (report.isAwaitingConfirmation) ...[
              const SizedBox(width: 6),
              const ReportBadgeChip(
                label: 'Perlu Konfirmasi',
                backgroundColor: AppColors.statusProcessBg,
                foregroundColor: AppColors.statusProcessText,
                fontSize: 9.5,
              ),
            ],
            const Spacer(),
            Text(
              _formatShortDate(activityTime),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${report.assetNama} • ${report.assetLokasi}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Oleh $actorName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
