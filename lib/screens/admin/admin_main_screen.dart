import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/admin_dashboard_screen.dart';
import 'package:tubes_pemob/screens/admin/kelola_laporan_screen.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/screens/shared/scan_qr_screen.dart';
import 'package:tubes_pemob/widgets/bottom_navbar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onScanQrPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(
          mode: ScanQrMode.all,
          role: UserRole.admin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminDashboardScreen(onSwitchTab: _onTabSelected),
          const _AdminTiketTabScreen(),
          // TODO: Ganti dengan const NotificationScreen() setelah screens/shared/notification_screen.dart dibuat
          const _AdminNotifikasiPlaceholderScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        role: UserRole.admin,
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabSelected,
        onCenterPressed: _onScanQrPressed,
      ),
    );
  }
}

class _AdminTiketTabScreen extends StatelessWidget {
  const _AdminTiketTabScreen();

  void _openSampleKelolaLaporan(BuildContext context) {
    final sampleReport = KelolaLaporanData(
      id: 'SNF-2026-001',
      title: 'AC Ruang Kelas D-204 Tidak Dingin',
      location: 'Gedung D • Ruang D-204',
      description: 'AC hanya mengeluarkan angin dan meneteskan air.',
      reporterName: 'Mahasiswa Kampus',
      reporterRole: 'Pelapor',
      createdAt: DateTime.now(),
      icon: Icons.ac_unit_rounded,
      status: ReportStatus.reported,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KelolaLaporanScreen(
          report: sampleReport,
          technicians: const ['Budi Santoso', 'Andi Pratama'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Center(
                child: Text(
                  'Daftar Tiket Laporan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Halaman daftar semua tiket belum dibuat.\nGunakan tombol di bawah untuk menguji rute Kelola Laporan:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openSampleKelolaLaporan(context),
                    icon: const Icon(Icons.assignment_turned_in_rounded),
                    label: Text(
                      'Buka Kelola Laporan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNotifikasiPlaceholderScreen extends StatelessWidget {
  const _AdminNotifikasiPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
          child: Text(
            'Halaman Notifikasi belum tersedia.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}