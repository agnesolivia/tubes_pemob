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
          const KelolaLaporanScreen(),
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
