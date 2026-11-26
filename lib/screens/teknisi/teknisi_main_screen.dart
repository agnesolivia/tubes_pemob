import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/screens/shared/scan_qr_screen.dart';
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

  String _resolveTechnicianName(UserModel? userData) {
    final explicitName = widget.technicianName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    final firestoreName = userData?.nama.trim();
    if (firestoreName != null && firestoreName.isNotEmpty) {
      return firestoreName;
    }

    final authDisplayName =
        AuthService.instance.currentUser?.displayName?.trim();
    if (authDisplayName != null && authDisplayName.isNotEmpty) {
      return authDisplayName;
    }

    return 'Teknisi';
  }

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
          mode: ScanQrMode.asset,
          role: UserRole.teknisi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _uid.isEmpty ? null : AuthService.instance.streamUserData(_uid),
      builder: (context, snapshot) {
        final resolvedName = _resolveTechnicianName(snapshot.data);

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              TeknisiHomeScreen(
                currentUserUid: _uid,
                technicianName: resolvedName,
                tasks: widget.tasks,
                onViewAllTasksPressed: () => _onTabSelected(1),
              ),
              DaftarTugasScreen(
                currentUserUid: _uid,
                tasks: widget.tasks,
                showBackButton: false,
              ),
              // TODO: Ganti dengan const NotificationScreen() setelah screens/shared/notification_screen.dart dibuat
              const _TeknisiNotifikasiPlaceholderScreen(),
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
      },
    );
  }
}

class _TeknisiNotifikasiPlaceholderScreen extends StatelessWidget {
  const _TeknisiNotifikasiPlaceholderScreen();

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