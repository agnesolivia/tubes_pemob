import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/pelapor/form_pengaduan_screen.dart';
import 'package:tubes_pemob/screens/pelapor/history_laporan_screen.dart';
import 'package:tubes_pemob/screens/shared/profile_screen.dart';
import 'package:tubes_pemob/screens/teknisi/daftar_tugas_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.label,
  });
}

class BottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final UserRole role;
  final ValueChanged<int>? onItemTapped;
  final VoidCallback? onCenterPressed;

  const BottomNavbar({
    super.key,
    required this.selectedIndex,
    this.role = UserRole.pelapor,
    this.onItemTapped,
    this.onCenterPressed,
  });

  List<_NavItemData> get _items {
    final secondItem = switch (role) {
      UserRole.pelapor => const _NavItemData(
          icon: Icons.assignment_outlined,
          label: 'Riwayat',
        ),
      UserRole.admin => const _NavItemData(
          icon: Icons.assignment_outlined,
          label: 'Tiket',
        ),
      UserRole.teknisi => const _NavItemData(
          icon: Icons.handyman_outlined,
          label: 'Tugas',
        ),
    };

    return [
      const _NavItemData(icon: Icons.home_rounded, label: 'Beranda'),
      secondItem,
      const _NavItemData(
        icon: Icons.notifications_none_rounded,
        label: 'Notifikasi',
      ),
      const _NavItemData(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];
  }

  IconData get _centerIcon {
    return role == UserRole.pelapor
        ? Icons.camera_alt_outlined
        : Icons.qr_code_scanner_rounded;
  }

  void _handleDefaultTap(BuildContext context, int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        if (role == UserRole.pelapor) {
          _navigateToTab(context, const RiwayatLaporanPage());
        } else if (role == UserRole.teknisi) {
          final uid = AuthService.instance.currentUser?.uid ?? '';
          _navigateToTab(context, DaftarTugasScreen(currentUserUid: uid));
        } else {
          _showUnavailableMessage(context, 'Halaman Daftar Tiket belum tersedia.');
        }
        break;
      case 2:
        _showUnavailableMessage(context, 'Halaman Notifikasi belum tersedia.');
        break;
      case 3:
        _navigateToTab(context, const ProfileScreen());
        break;
    }
  }

  void _showUnavailableMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _navigateToTab(BuildContext context, Widget destination) {
    final route = MaterialPageRoute(builder: (_) => destination);
    if (selectedIndex == 0) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  void _handleDefaultCenterPress(BuildContext context) {
    if (role == UserRole.pelapor) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateReportScreen()),
      );
      return;
    }

    _showUnavailableMessage(context, 'Fitur pemindaian QR belum tersedia.');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final items = _items;

    return SizedBox(
      height: 78 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 64 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: items[0].icon,
                  label: items[0].label,
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped != null
                      ? onItemTapped!(0)
                      : _handleDefaultTap(context, 0),
                ),
                _NavBarItem(
                  icon: items[1].icon,
                  label: items[1].label,
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped != null
                      ? onItemTapped!(1)
                      : _handleDefaultTap(context, 1),
                ),
                const SizedBox(width: 64),
                _NavBarItem(
                  icon: items[2].icon,
                  label: items[2].label,
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped != null
                      ? onItemTapped!(2)
                      : _handleDefaultTap(context, 2),
                ),
                _NavBarItem(
                  icon: items[3].icon,
                  label: items[3].label,
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemTapped != null
                      ? onItemTapped!(3)
                      : _handleDefaultTap(context, 3),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onCenterPressed ??
                    () => _handleDefaultCenterPress(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentYellow,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _centerIcon,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? AppColors.primaryBlue : const Color(0xFF8A94A6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}