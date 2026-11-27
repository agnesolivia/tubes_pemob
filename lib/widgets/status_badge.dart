import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';

/// Pasangan warna latar & teks untuk badge status atau prioritas.
class BadgeColors {
  final Color background;
  final Color foreground;

  const BadgeColors({
    required this.background,
    required this.foreground,
  });
}

/// Helper warna terpusat agar seluruh halaman memakai warna status/prioritas
/// yang konsisten.
BadgeColors reportStatusColors(ReportStatus status) {
  switch (status) {
    case ReportStatus.reported:
      return const BadgeColors(
        background: AppColors.inputFill,
        foreground: AppColors.textSecondary,
      );
    case ReportStatus.verified:
    case ReportStatus.assigned:
      return const BadgeColors(
        background: AppColors.statusDoneBg,
        foreground: AppColors.primaryBlue,
      );
    case ReportStatus.inProgress:
      return const BadgeColors(
        background: AppColors.statusProcessBg,
        foreground: AppColors.statusProcessText,
      );
    case ReportStatus.resolved:
      return const BadgeColors(
        background: AppColors.statusSuccessBg,
        foreground: AppColors.statusSuccessText,
      );
    case ReportStatus.rejected:
      return const BadgeColors(
        background: AppColors.statusRejectedBg,
        foreground: AppColors.statusRejectedText,
      );
  }
}

BadgeColors reportPriorityColors(ReportPriority priority) {
  switch (priority) {
    case ReportPriority.tinggi:
      return const BadgeColors(
        background: AppColors.statusRejectedBg,
        foreground: AppColors.statusRejectedText,
      );
    case ReportPriority.sedang:
      return const BadgeColors(
        background: AppColors.statusProcessBg,
        foreground: AppColors.statusProcessText,
      );
    case ReportPriority.rendah:
      return const BadgeColors(
        background: AppColors.statusSuccessBg,
        foreground: AppColors.statusSuccessText,
      );
  }
}

/// Pill badge serbaguna untuk status, prioritas, SLA, atau label konfirmasi.
class ReportBadgeChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final double fontSize;

  const ReportBadgeChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label badge otomatis sesuai [ReportStatus].
class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = reportStatusColors(status);
    return ReportBadgeChip(
      label: status.label,
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      fontSize: fontSize,
    );
  }
}

/// Label badge otomatis sesuai [ReportPriority].
class PriorityBadge extends StatelessWidget {
  final ReportPriority priority;
  final double fontSize;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = reportPriorityColors(priority);
    return ReportBadgeChip(
      label: priority.label,
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      fontSize: fontSize,
    );
  }
}
