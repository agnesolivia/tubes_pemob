import 'package:flutter/material.dart';

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
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.primary,
      body: Column(
        children: [
          _buildHeader(),
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
                    _buildProfileCard(),
                    const SizedBox(height: 18),
                    _buildSummarySection(),
                    const SizedBox(height: 18),
                    _buildAccountInfo(),
                    const SizedBox(height: 18),
                    _buildSettings(),
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
  }

  // HEADER
  Widget _buildHeader() {
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
              onTap: () {},
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
  Widget _buildProfileCard() {
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
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: _ProfileColors.primary,
                ),
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
                const Text(
                  'Haya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ProfileColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'NIM: 2*****030',
                  style: TextStyle(
                    fontSize: 13,
                    color: _ProfileColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                _chip(
                  'Mahasiswa Aktif',
                  const Color(0xFFE3EEFF),
                  _ProfileColors.primary,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Teknologi Informasi • Fasilkom-TI',
                  style: TextStyle(
                    fontSize: 12,
                    color: _ProfileColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RINGKASAN LAPORAN
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Ringkasan Laporan Kamu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ProfileColors.textDark,
                ),
              ),
              Text(
                'Total 7 Laporan',
                style: TextStyle(
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
              'Menunggu', '1', 'Menunggu verifikasi',
              const Color(0xFFFFF3D6), const Color(0xFFB7791F),
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Diproses', '1', 'Sedang jalan',
              const Color(0xFFD9F7E4), const Color(0xFF1E9E55),
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Selesai', '4', 'Telah diperbaiki',
              const Color(0xFFDDEBFF), _ProfileColors.primary,
            ),
          ],
        ),
      ],
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
  Widget _buildAccountInfo() {
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
              _infoRow('Nama lengkap', 'Haya'),
              const Divider(height: 1, color: _ProfileColors.border),
              _infoRow('NIM', '2*****030'),
              const Divider(height: 1, color: _ProfileColors.border),
              _infoRow('Email', 'Haya@gmail.com'),
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
  Widget _buildSettings() {
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
                onTap: () {},
              ),
              const Divider(height: 1, color: _ProfileColors.border),
              _settingTile(
                icon: Icons.lock_outline,
                title: 'Ubah Kata Sandi',
                subtitle: 'Keamanan akun SnaFix kamu',
                onTap: () {},
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
        onPressed: () {},
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
                  onTap: () {},
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
