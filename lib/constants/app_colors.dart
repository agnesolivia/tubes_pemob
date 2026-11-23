import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Warna Utama Brand SnaFix
  static const Color primaryBlue = Color(0xFF0055F7);
  static const Color primaryBlueDark = Color(0xFF0045D1);
  static const Color primaryBlueLight = Color(0xFF0A63FF);
  static const Color accentYellow = Color(0xFFFFB800);
  static const Color accentOrange = Color(0xFFFFA800);

  // Warna Netral & Permukaan UI
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color inputFill = Color(0xFFEEF2FA);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Warna Badge Status Laporan
  static const Color statusProcessBg = Color(0xFFFEF3C7);
  static const Color statusProcessText = Color(0xFFD97706);

  static const Color statusDoneBg = Color(0xFFDBEAFE);
  static const Color statusDoneText = Color(0xFF0057FF);

  static const Color statusRejectedBg = Color(0xFFFEE2E2);
  static const Color statusRejectedText = Color(0xFFDC2626);

  // Warna Tambahan Dashboard Admin
  static const Color statusSuccessBg = Color(0xFFD9F8E9);
  static const Color statusSuccessText = Color(0xFF13B779);
}


// ======================================================
// SNAFIX COLORS - KOMPATIBILITAS DASHBOARD ADMIN
// Menggunakan warna dari AppColors agar tidak duplikat.
// ======================================================

class SnaFixColors {
  SnaFixColors._();

  static const primary = AppColors.primaryBlue;
  static const primaryDark = AppColors.primaryBlueDark;

  static const navy = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const border = AppColors.border;

  static const green = AppColors.statusSuccessText;
  static const greenSoft = AppColors.statusSuccessBg;

  static const yellow = AppColors.accentYellow;
  static const yellowSoft = AppColors.statusProcessBg;

  static const red = AppColors.statusRejectedText;
  static const redSoft = AppColors.statusRejectedBg;

  static const blueSoft = AppColors.statusDoneBg;
  static const surface = AppColors.white;
}