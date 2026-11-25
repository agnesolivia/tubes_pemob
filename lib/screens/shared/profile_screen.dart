import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/storage_service.dart';

class _ProfileColors {
  static const primary = AppColors.primaryBlue;
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const danger = Color(0xFFE53935);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifAktif = true;
  bool _isLoggingOut = false;

  String _getInitial(String nama) {
    final trimmed = nama.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError
            ? _ProfileColors.danger
            : _ProfileColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final base64Photo = await StorageService.instance.pickAndCompressImage(
        source: source,
      );
      if (base64Photo == null) return;

      await AuthService.instance.updateProfilePhoto(
        uid: uid,
        photoBase64: base64Photo,
      );
      _showSnackBar('Foto profil berhasil diperbarui.');
    } catch (e) {
      _showSnackBar('Gagal memperbarui foto: $e', isError: true);
    }
  }

  void _showPhotoPicker(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A0D14),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Pilih dari Galeri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0D14),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Buka Kamera',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0D14),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                if ((user.photoBase64?.isNotEmpty ?? false) ||
                  (AuthService.instance.currentUser?.photoURL?.isNotEmpty ??
                      false)) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: _ProfileColors.danger,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Hapus Foto',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ProfileColors.danger,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await AuthService.instance.updateProfilePhoto(
                        uid: user.uid,
                        photoBase64: null,
                      );
                      _showSnackBar('Foto profil dihapus.');
                    } catch (e) {
                      _showSnackBar('Gagal menghapus foto: $e',
                          isError: true);
                    }
                  },
                ),
              ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A0D14),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Ubah Nama Lengkap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0D14),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditNameDialog(user);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Ubah Foto Profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0D14),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPhotoPicker(user);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditNameDialog(UserModel user) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: user.nama),
    );

    if (newName == null || !mounted) return;

    try {
      await AuthService.instance.updateProfile(uid: user.uid, nama: newName);
      _showSnackBar('Nama berhasil diperbarui.');
    } catch (e) {
      _showSnackBar('Gagal memperbarui nama: $e', isError: true);
    }
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
        title: Text(
          'Keluar dari Akun?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Anda perlu masuk kembali untuk mengakses aplikasi.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ProfileColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
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
      return Scaffold(
        body: Center(
          child: Text(
            'Pengguna belum masuk.',
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: AuthService.instance.streamUserData(currentUser.uid),
      builder: (context, snapshot) {
        final user =
            snapshot.data ??
            UserModel(
              uid: currentUser.uid,
              nama: currentUser.displayName ?? 'Pengguna Kampus',
              email: currentUser.email ?? '-',
              role: UserRole.pelapor,
              createdAt: DateTime.now(),
            );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: AppColors.primaryBlue,
            body: Stack(
              children: [
                // 1. Gambar Gelombang Biru Atas
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/wave_top.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                // 2. Tata Letak Utama (Header + Konten Putih)
                Column(
                  children: [
                    _buildHeader(user),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: _ProfileColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 105),
                            children: [
                              _buildProfileCard(user),
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
              ],
            ),
          ),
        );
      },
    );
  }

  // HEADER
  Widget _buildHeader(UserModel user) {
    final subtitle = switch (user.role) {
      UserRole.pelapor => 'Informasi akun',
      UserRole.admin => 'Informasi akun & pengaturan admin',
      UserRole.teknisi => 'Informasi akun & pengaturan teknisi',
    };

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profil Saya',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _showEditNameDialog(user),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.white,
                    size: 19,
                  ),
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
          GestureDetector(
            onTap: () => _showPhotoPicker(user),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: _ProfileColors.primary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: () {
                    final bytes =
                        StorageService.instance.base64ToBytes(user.photoBase64);
                    if (bytes != null) {
                      return ClipOval(
                        child: Image.memory(
                          bytes,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      );
                    }

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
                            style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
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
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      size: 13,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ProfileColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: GoogleFonts.plusJakartaSans(
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

  // INFORMASI AKUN
  Widget _buildAccountInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Informasi Akun'),
        const SizedBox(height: 10),
        _card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _ProfileColors.textGrey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
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
    final (notifTitle, notifSubtitle) = switch (user.role) {
      UserRole.pelapor => (
        'Notifikasi Status Laporan',
        'Update progres & feedback Admin',
      ),
      UserRole.teknisi => (
        'Notifikasi Tugas Perbaikan',
        'Update penugasan tiket baru',
      ),
      UserRole.admin => (
        'Notifikasi Laporan Masuk',
        'Update laporan baru & peringatan SLA',
      ),
    };

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
                onTap: () => _showEditProfileSheet(user),
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
                title: notifTitle,
                subtitle: notifSubtitle,
                trailing: Switch(
                  value: _notifAktif,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: _ProfileColors.primary,
                  onChanged: (value) {
                    setState(() => _notifAktif = value);
                  },
                ),
              ),
              if (user.role != UserRole.admin) ...[
                const Divider(height: 1, color: _ProfileColors.border),
                _settingTile(
                  icon: Icons.info_outline,
                  title: 'Bantuan & Kontak Admin',
                  subtitle: 'Hubungi Admin jika terdapat kendala',
                  onTap: () {},
                ),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _ProfileColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ProfileColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _ProfileColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, color: _ProfileColors.textGrey),
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
        icon: const Icon(Icons.logout, size: 18, color: _ProfileColors.danger),
        label: Text(
          'Keluar',
          style: GoogleFonts.plusJakartaSans(
            color: _ProfileColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          side: const BorderSide(color: _ProfileColors.danger, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _ProfileColors.textDark,
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
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

class _EditNameDialog extends StatefulWidget {
  final String initialName;

  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final newName = _controller.text.trim();
    if (newName.length < 3) {
      setState(() => _errorText = 'Nama minimal 3 karakter.');
      return;
    }
    Navigator.of(context).pop(newName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Nama Profil',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.plusJakartaSans(),
        decoration: InputDecoration(
          hintText: 'Masukkan nama lengkap',
          hintStyle: GoogleFonts.plusJakartaSans(),
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('Simpan', style: GoogleFonts.plusJakartaSans()),
        ),
      ],
    );
  }
}
