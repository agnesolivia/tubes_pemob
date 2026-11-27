import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';

/// Komponen tombol tindak lanjut hasil perbaikan (status `resolved` & belum dikonfirmasi).
/// Dipakai bersama oleh Pelapor (pembuat laporan) dan Admin (supervisor override).
///
/// Secara default langsung terhubung ke [ReportService.confirmResolution] dan
/// [ReportService.reopenReport]. Callback opsional [onConfirm] & [onReopen]
/// tetap disediakan apabila pemanggil ingin menangani aksi secara kustom.
class ResolutionActionBar extends StatefulWidget {
  final ReportModel report;
  final VoidCallback? onConfirm;
  final ValueChanged<String>? onReopen;

  const ResolutionActionBar({
    super.key,
    required this.report,
    this.onConfirm,
    this.onReopen,
  });

  @override
  State<ResolutionActionBar> createState() => _ResolutionActionBarState();
}

class _ResolutionActionBarState extends State<ResolutionActionBar> {
  bool _isConfirming = false;
  bool _isReopening = false;

  bool get _isBusy => _isConfirming || _isReopening;

  Future<UserModel> _resolveCurrentUser() async {
    final firebaseUser = AuthService.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan masuk kembali.');
    }

    final user = await AuthService.instance.getUserData(firebaseUser.uid);
    if (user == null) {
      throw Exception('Data profil pengguna tidak ditemukan.');
    }
    return user;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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
          backgroundColor: isError
              ? AppColors.statusRejectedText
              : const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openConfirmDialog() async {
    if (_isBusy) return;

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
          'Pastikan hasil perbaikan pada "${widget.report.assetNama}" sudah sesuai. Setelah dikonfirmasi, laporan tidak dapat diajukan ulang.',
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

    if (confirmed != true || !mounted) return;

    if (widget.onConfirm != null) {
      widget.onConfirm!();
      return;
    }

    setState(() => _isConfirming = true);
    try {
      final actor = await _resolveCurrentUser();
      await ReportService.instance.confirmResolution(
        report: widget.report,
        actor: actor,
      );
      _showSnackBar('Perbaikan berhasil dikonfirmasi selesai.');
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(cleanMsg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _openReopenDialog() async {
    if (_isBusy) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReopenReasonDialog(),
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    if (widget.onReopen != null) {
      widget.onReopen!(reason);
      return;
    }

    setState(() => _isReopening = true);
    try {
      final actor = await _resolveCurrentUser();
      await ReportService.instance.reopenReport(
        report: widget.report,
        actor: actor,
        alasan: reason,
      );
      _showSnackBar('Laporan diajukan ulang agar diperbaiki kembali.');
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(cleanMsg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isReopening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : _openReopenDialog,
            icon: _isReopening
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.statusProcessText,
                    ),
                  )
                : const Icon(Icons.replay_rounded, size: 19),
            label: Text(
              _isReopening ? 'Memproses...' : 'Belum Beres',
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
            onPressed: _isBusy ? null : _openConfirmDialog,
            icon: _isConfirming
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_rounded, size: 19),
            label: Text(
              _isConfirming ? 'Menyimpan...' : 'Konfirmasi Selesai',
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
