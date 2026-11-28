import 'package:flutter/material.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/pelapor/history_laporan_screen.dart';
import 'package:tubes_pemob/screens/pelapor/pelapor_home_screen.dart';
import 'package:tubes_pemob/screens/shared/notification_screen.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/widgets/bottom_navbar.dart';
import 'package:tubes_pemob/screens/shared/scan_qr_screen.dart';

class PelaporMainScreen extends StatefulWidget {
  const PelaporMainScreen({super.key});

  @override
  State<PelaporMainScreen> createState() => _PelaporMainScreenState();
}

class _PelaporMainScreenState extends State<PelaporMainScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreateReportPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(mode: ScanQrMode.asset),
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
          PelaporHomeScreen(onSwitchTab: _onTabSelected),
          RiwayatLaporanPage(onBackToHome: () => _onTabSelected(0)),
          const NotificationScreen(userRole: UserRole.pelapor),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        role: UserRole.pelapor,
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabSelected,
        onCenterPressed: _onCreateReportPressed,
      ),
    );
  }
}