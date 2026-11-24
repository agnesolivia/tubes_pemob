import 'package:flutter/material.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';

class _ProfileColors {
  static const primary = Color(0xFF0B63F6);
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const danger = Color(0xFFE53935);
  static const orange = Color(0xFFF5A623);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifAktif = true;
  bool _isLoggingOut = false;
  int _currentIndex = 3;

  String _getInitial(String nama) {
    final trimmed = nama.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? _ProfileColors.danger : _ProfileColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showEditNameDialog(UserModel user) async {
    final controller = TextEditingController(text: user.nama);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Nama Profil'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = controller.text.trim();
                          if (newName.length < 3) {
                            _showSnackBar('Nama minimal 3 karakter.',
                                isError: true);
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            await AuthService.instance.updateProfile(
                              uid: user.uid,
                              nama: newName,
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            _showSnackBar('Nama berhasil diperbarui.');
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showSnackBar('Gagal memperbarui nama: $e',
                                isError: true);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _sendResetPassword(String email) async {
    if (email.trim().isEmpty) {
      _showSnackBar('Email akun tidak ditemukan.', isError: true);
      return;
    }
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      _showSnackBar('Tautan ubah kata sandi telah dikirim ke $email.');
    } catch (e) {
      _showSnackBar('Gagal mengirim email reset: $e', isError: true);
    }
  }

  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda perlu masuk kembali untuk mengakses aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ProfileColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await AuthService.instance.signOut();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showSnackBar('Gagal logout: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Pengguna belum masuk.')),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: AuthService.instance.streamUserData(currentUser.uid),
      builder: (context, snapshot) {
        final user = snapshot.data ??
            UserModel(
              uid: currentUser.uid,
              nama: currentUser.displayName ?? 'Pengguna Kampus',
              email: currentUser.email ?? '-',
              role: UserRole.pelapor,
              createdAt: DateTime.now(),
            );

        return Scaffold(
          backgroundColor: _ProfileColors.primary,
          body: Column(
            children: [
              _buildHeader(user),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _ProfileColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        _buildProfileCard(user),
                        const SizedBox(height: 18),
                        _buildSummarySection(user.uid),
                        const SizedBox(height: 18),
                        _buildAccountInfo(user),
                        const SizedBox(height: 18),
                        _buildSettings(user),
                        const SizedBox(height: 22),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  // HEADER
  Widget _buildHeader(UserModel user) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Row(
          children: [
            const SizedBox(width: 40),
            const Expanded(
              child: Column(
                children: [
                  Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Informasi akun & ringkasan laporanmu',
                    style: TextStyle(
                      color: Color(0xFFD6E4FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _showEditNameDialog(user),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PROFILE CARD
  Widget _buildProfileCard(UserModel user) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _ProfileColors.primary,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: () {
                  final photoUrl = AuthService.instance.currentUser?.photoURL;
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    return ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          _getInitial(user.nama),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _ProfileColors.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  return Text(
                    _getInitial(user.nama),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _ProfileColors.primary,
                    ),
                  );
                }(),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _ProfileColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ProfileColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _ProfileColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                _chip(
                  user.role.label,
                  const Color(0xFFE3EEFF),
                  _ProfileColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RINGKASAN LAPORAN
  Widget _buildSummarySection(String uid) {
    return StreamBuilder<List<ReportModel>>(
      stream: ReportService.instance.streamReportsByPelapor(uid),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        final menunggu =
            reports.where((r) => r.status == ReportStatus.reported).length;
        final diproses = reports
            .where((r) =>
                r.status == ReportStatus.verified ||
                r.status == ReportStatus.assigned ||
                r.status == ReportStatus.inProgress)
            .length;
        final selesai =
            reports.where((r) => r.status == ReportStatus.resolved).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ringkasan Laporan Kamu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ProfileColors.textDark,
                    ),
                  ),
                  Text(
                    'Total ${reports.length} Laporan',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ProfileColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _summaryCard(
                  'Menunggu', '$menunggu', 'Menunggu verifikasi',
                  const Color(0xFFFFF3D6), const Color(0xFFB7791F),
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  'Diproses', '$diproses', 'Sedang jalan',
                  const Color(0xFFD9F7E4), const Color(0xFF1E9E55),
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  'Selesai', '$selesai', 'Telah diperbaiki',
                  const Color(0xFFDDEBFF), _ProfileColors.primary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String status,
    String count,
    String caption,
    Color chipBg,
    Color chipText,
  ) {
    return Expanded(
      child: _card(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 6,
        ),
        child: Column(
          children: [
            _chip(status, chipBg, chipText),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _ProfileColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: _ProfileColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // INFORMASI AKUN
  Widget _buildAccountInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Informasi Akun'),
        const SizedBox(height: 10),
        _card(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          child: Column(
            children: [
              _infoRow('Nama lengkap', user.nama),
              const Divider(height: 1, color: _ProfileColors.border),
              _infoRow('Peran (Role)', user.role.label),
              const Divider(height: 1, color: _ProfileColors.border),
              _infoRow('Email', user.email),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _ProfileColors.textGrey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ProfileColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PENGATURAN
  Widget _buildSettings(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pengaturan'),
        const SizedBox(height: 10),
        _card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingTile(
                icon: Icons.person_outline,
                title: 'Edit Profil',
                subtitle: 'Perbarui nama, foto, dan kontak',
                onTap: () => _showEditNameDialog(user),
              ),
              const Divider(height: 1, color: _ProfileColors.border),
              _settingTile(
                icon: Icons.lock_outline,
                title: 'Ubah Kata Sandi',
                subtitle: 'Keamanan akun SnaFix kamu',
                onTap: () => _sendResetPassword(user.email),
              ),
              const Divider(height: 1, color: _ProfileColors.border),
              _settingTile(
                icon: Icons.notifications_none,
                title: 'Notifikasi Status Laporan',
                subtitle: 'Update progres & feedback Admin',
                trailing: Switch(
                  value: _notifAktif,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _ProfileColors.primary,
                  onChanged: (value) {
                    setState(() => _notifAktif = value);
                  },
                ),
              ),
              const Divider(height: 1, color: _ProfileColors.border),
              _settingTile(
                icon: Icons.info_outline,
                title: 'Bantuan & Kontak Admin',
                subtitle: 'Hubungi Admin jika terdapat kendala',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: _ProfileColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ProfileColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _ProfileColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: _ProfileColors.textGrey,
                ),
          ],
        ),
      ),
    );
  }

  // LOGOUT
  Widget _buildLogoutButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _confirmAndLogout,
        icon: const Icon(
          Icons.logout,
          size: 18,
          color: _ProfileColors.danger,
        ),
        label: const Text(
          'Keluar',
          style: TextStyle(
            color: _ProfileColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: _ProfileColors.danger,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  _navItem(Icons.home_rounded, 'Beranda', 0),
                  _navItem(Icons.assignment_outlined, 'Riwayat', 1),
                  const Expanded(child: SizedBox()),
                  _navItem(Icons.notifications_none, 'Notifikasi', 2),
                  _navItem(Icons.person_outline, 'Profil', 3),
                ],
              ),
              Positioned(
                top: -28,
                child: GestureDetector(
                  onTap: () {
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _ProfileColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _ProfileColors.orange,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D0B63F6),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final aktif = _currentIndex == index;
    final color = aktif
        ? _ProfileColors.primary
        : _ProfileColors.textGrey;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 0 && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPERS
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _ProfileColors.textDark,
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfileColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
