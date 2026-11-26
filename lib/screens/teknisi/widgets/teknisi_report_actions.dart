import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';

/// Bagian tombol aksi khusus role Teknisi pada `DetailLaporanScreen`.
/// Mode saat ini masih UI-only: tombol "Mulai Kerjakan" dan "Selesaikan Tugas"
/// dapat dicoba langsung tanpa proses tulis backend.
class TeknisiReportActions extends StatelessWidget {
  final ReportStatus status;

  /// Menandakan apakah user saat ini adalah teknisi yang ditugaskan (PIC tiket).
  /// Teknisi lain yang membuka tiket hanya memiliki akses baca (read-only).
  final bool isAssignedTechnician;

  final VoidCallback? onStartWork;
  final VoidCallback? onCompleteWork;

  const TeknisiReportActions({
    super.key,
    required this.status,
    this.isAssignedTechnician = true,
    this.onStartWork,
    this.onCompleteWork,
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

  @override
  Widget build(BuildContext context) {
    if (!isAssignedTechnician) return const SizedBox.shrink();

    Widget? button;

    if (status == ReportStatus.assigned) {
      button = ElevatedButton.icon(
        onPressed: () {
          if (onStartWork != null) {
            onStartWork!();
          } else {
            // TODO: Sambungkan ke ReportService.instance.startWork(...)
            _showPreviewSnackBar(
              context,
              'UI Preview: Status tugas berubah menjadi Sedang Dikerjakan.',
            );
          }
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 23),
        label: Text(
          'Mulai Kerjakan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );
    } else if (status == ReportStatus.inProgress) {
      button = ElevatedButton.icon(
        onPressed: () {
          if (onCompleteWork != null) {
            onCompleteWork!();
          } else {
            // TODO: Navigasi ke FormPenyelesaianScreen
            _showPreviewSnackBar(
              context,
              'UI Preview: Membuka Form Penyelesaian Tugas.',
            );
          }
        },
        icon: const Icon(Icons.check_rounded, size: 22),
        label: Text(
          'Selesaikan Tugas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF15803D),
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );
    } else if (status == ReportStatus.resolved) {
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

    if (button == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(width: double.infinity, child: button),
      ),
    );
  }
}
