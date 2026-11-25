import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/screens/teknisi/daftar_tugas_screen.dart';
import 'package:tubes_pemob/screens/teknisi/teknisi_home_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/widgets/bottom_navbar.dart';

class TeknisiMainScreen extends StatefulWidget {
  final String? currentUserUid;
  final String? technicianName;
  final List<TechnicianTaskItem> tasks;

  const TeknisiMainScreen({
    super.key,
    this.currentUserUid,
    this.technicianName,
    this.tasks = const [],
  });

  @override
  State<TeknisiMainScreen> createState() => _TeknisiMainScreenState();
}

class _TeknisiMainScreenState extends State<TeknisiMainScreen> {
  int _selectedIndex = 0;

  String get _uid =>
      widget.currentUserUid ?? AuthService.instance.currentUser?.uid ?? '';

  String get _name =>
      widget.technicianName ??
      AuthService.instance.currentUser?.displayName ??
      'Teknisi';

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onScanQrPressed() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Fitur pemindaian QR belum tersedia.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
          TeknisiHomeScreen(
            currentUserUid: _uid,
            technicianName: _name,
            tasks: widget.tasks,
            onViewAllTasksPressed: () => _onTabSelected(1),
          ),
          DaftarTugasScreen(
            currentUserUid: _uid,
            tasks: widget.tasks,
            showBackButton: false,
          ),
          const _TeknisiRiwayatPlaceholderScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        role: UserRole.teknisi,
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabSelected,
        onCenterPressed: _onScanQrPressed,
      ),
    );
  }
}

class _TeknisiRiwayatPlaceholderScreen extends StatelessWidget {
  const _TeknisiRiwayatPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Halaman Riwayat Pekerjaan belum tersedia.',
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