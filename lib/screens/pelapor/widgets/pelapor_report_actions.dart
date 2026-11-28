import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/widgets/resolution_action_bar.dart';
import 'package:tubes_pemob/services/report_service.dart';

/// Bagian tombol aksi khusus role Pelapor pada `DetailLaporanScreen`.
/// Mode saat ini masih UI-only (belum terhubung ke proses tulis Firestore).
class PelaporReportActions extends StatelessWidget {
  final ReportModel report;

  /// Menandakan apakah user saat ini adalah pembuat laporan.
  /// Pelapor lain yang membuka tiket hanya memiliki akses baca (read-only).
  final bool isReportOwner;

  final VoidCallback? onCancelReport;
  final VoidCallback? onConfirmResolution;
  final ValueChanged<String>? onReopenReport;

  const PelaporReportActions({
    super.key,
    required this.report,
    this.isReportOwner = true,
    this.onCancelReport,
    this.onConfirmResolution,
    this.onReopenReport,
  });

  void _showPreviewSnackBar(BuildContext context, String message) {
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
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Batalkan Laporan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Laporan kerusakan pada "${report.assetNama}" akan dihapus secara permanen. Lanjutkan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Tidak',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejectedText,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (onCancelReport != null) {
    onCancelReport!();
    return;
  }

  try {
    await ReportService.instance.cancelReport(report.id);
    if (!context.mounted) return;
      _showPreviewSnackBar(
        context,
        'Laporan "${report.assetNama}" berhasil dibatalkan.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showPreviewSnackBar(context, 'Gagal membatalkan: $msg');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isReportOwner) return const SizedBox.shrink();

    Widget? content;

    if (report.status == ReportStatus.reported) {
      content = SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmCancel(context),
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          label: Text(
            'Batalkan Laporan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.statusRejectedText,
            side: const BorderSide(color: AppColors.statusRejectedText),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );
    } else if (report.isAwaitingConfirmation) {
      content = ResolutionActionBar(
        report: report,
        onConfirm: onConfirmResolution,
        onReopen: onReopenReport,
      );
    }

    if (content == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}
