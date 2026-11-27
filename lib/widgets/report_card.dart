import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/widgets/status_badge.dart';

enum _ReportCardVariant { compact, overdue, activity }

/// Kartu ringkasan laporan bergaya ringkas (compact) yang seragam di seluruh halaman:
/// - `ReportCard(...)`: daftar laporan umum (Kelola Laporan, Riwayat, Tugas)
/// - `ReportCard.overdue(...)`: peringatan Overdue SLA di Dashboard
/// - `ReportCard.activity(...)`: aktivitas terbaru di Dashboard
///
/// Struktur 4 baris konsisten di semua varian:
/// 1. Badge status/tag (kiri) + Waktu (kanan atas)
/// 2. Nama Aset (1 baris tebal) + Panah (kanan)
/// 3. Ikon & Lokasi (1 baris) + SLA singkat (jika aktif pada mode daftar)
/// 4. Ringkasan kontekstual (deskripsi / teknisi / log aktivitas terbaru)
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

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day$month, $hour:$minute';
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

  DateTime get _headerTime {
    if (_variant == _ReportCardVariant.activity &&
        report.riwayatStatus.isNotEmpty) {
      return report.riwayatStatus.last.timestamp;
    }
    return report.createdAt;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER: Badge (kiri) + Waktu (kanan atas)
              _buildHeaderRow(),
              const SizedBox(height: 8),

              // 2. NAMA ASET (terpisah dari lokasi agar tidak terpotong) + Panah
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.assetNama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
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
              const SizedBox(height: 3),

              // 3. LOKASI + Indikator SLA singkat (mode daftar)
              _buildLocationRow(),
              const SizedBox(height: 6),

              // 4. RINGKASAN KONTEKSTUAL (tanpa nama pelapor)
              _buildFooterContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final badges = switch (_variant) {
      _ReportCardVariant.compact => <Widget>[
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
      _ReportCardVariant.overdue => <Widget>[
          ReportBadgeChip(
            label: _overdueLabel(report.deadlineAt),
            icon: Icons.access_time_filled_rounded,
            backgroundColor: AppColors.statusRejectedBg,
            foregroundColor: AppColors.statusRejectedText,
          ),
          StatusBadge(status: report.status),
        ],
      _ReportCardVariant.activity => <Widget>[
          StatusBadge(status: report.status),
          if (report.isAwaitingConfirmation)
            const ReportBadgeChip(
              label: 'Perlu Konfirmasi',
              backgroundColor: AppColors.statusProcessBg,
              foregroundColor: AppColors.statusProcessText,
              fontSize: 9.5,
            ),
        ],
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            children: badges,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _formatShortDate(_headerTime),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    final slaText =
        _variant == _ReportCardVariant.compact ? _slaShortText() : '';

    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 13.5,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            report.assetLokasi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
    );
  }

  Widget _buildFooterContent() {
    final hasTeknisi =
        report.teknisiNama != null && report.teknisiNama!.trim().isNotEmpty;

    switch (_variant) {
      case _ReportCardVariant.compact:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (hasTeknisi) ...[
              const SizedBox(height: 5),
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
                      'Teknisi: ${report.teknisiNama}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );

      case _ReportCardVariant.overdue:
        return Row(
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
        );

      case _ReportCardVariant.activity:
        final latestLog =
            report.riwayatStatus.isNotEmpty ? report.riwayatStatus.last : null;
        final subtitleText =
            (latestLog != null && latestLog.catatan.trim().isNotEmpty)
                ? latestLog.catatan.trim()
                : report.deskripsi;

        return Text(
          subtitleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        );
    }
  }
}