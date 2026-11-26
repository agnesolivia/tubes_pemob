import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';

/// Komponen tombol tindak lanjut hasil perbaikan (status `resolved` & belum dikonfirmasi).
/// Dipakai bersama oleh Pelapor (pembuat laporan) dan Admin (supervisor override).
///
/// Mode saat ini masih UI-only: menyertakan dialog konfirmasi & dialog alasan
/// ajukan ulang. Nantinya cukup isi callback [onConfirm] dan [onReopen] dengan
/// pemanggilan `ReportService`.
class ResolutionActionBar extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onConfirm;
  final ValueChanged<String>? onReopen;

  const ResolutionActionBar({
    super.key,
    required this.report,
    this.onConfirm,
    this.onReopen,
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

  Future<void> _openConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Selesai?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Pastikan hasil perbaikan pada "${report.assetNama}" sudah sesuai. Setelah dikonfirmasi, laporan tidak dapat diajukan ulang.',
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
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: Text(
              'Konfirmasi',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (onConfirm != null) {
      onConfirm!();
    } else {
      // TODO: Sambungkan ke ReportService.instance.confirmResolution(...)
      _showPreviewSnackBar(
        context,
        'UI Preview: Perbaikan "${report.assetNama}" dikonfirmasi selesai.',
      );
    }
  }

  Future<void> _openReopenDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReopenReasonDialog(),
    );

    if (reason == null || reason.isEmpty || !context.mounted) return;

    if (onReopen != null) {
      onReopen!(reason);
    } else {
      // TODO: Sambungkan ke ReportService.instance.reopenReport(...)
      _showPreviewSnackBar(
        context,
        'UI Preview: Laporan diajukan ulang dengan alasan "$reason".',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openReopenDialog(context),
            icon: const Icon(Icons.replay_rounded, size: 19),
            label: Text(
              'Belum Beres',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusProcessText,
              side: const BorderSide(color: AppColors.statusProcessText),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openConfirmDialog(context),
            icon: const Icon(Icons.verified_rounded, size: 19),
            label: Text(
              'Konfirmasi Selesai',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReopenReasonDialog extends StatefulWidget {
  const _ReopenReasonDialog();

  @override
  State<_ReopenReasonDialog> createState() => _ReopenReasonDialogState();
}

class _ReopenReasonDialogState extends State<_ReopenReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Ajukan Ulang (Belum Beres)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jelaskan bagian yang masih bermasalah agar teknisi tahu apa yang perlu diperbaiki ulang.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: AC masih belum dingin setelah diperbaiki',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.4,
                  ),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Alasan wajib diisi.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusProcessText,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          child: Text(
            'Ajukan Ulang',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}