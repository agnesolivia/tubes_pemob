import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/scan_qr_screen.dart';

// ============================================================
// MODEL DATA SEMENTARA (UI-ONLY PREVIEW)
// Nantinya diganti dengan `UserModel` + `streamTechnicianActiveTaskCounts`.
// ============================================================

class TechnicianData {
  final String uid;
  final String name;
  final String email;
  final int assignedTicketCount;
  final int inProgressTicketCount;
  final String? photoUrl;

  const TechnicianData({
    required this.uid,
    required this.name,
    required this.email,
    this.assignedTicketCount = 0,
    this.inProgressTicketCount = 0,
    this.photoUrl,
  });

  /// Jumlah tiket aktif = assigned + inProgress (syarat cabut akses harus 0).
  int get activeTicketCount => assignedTicketCount + inProgressTicketCount;
}

class RegisteredUserData {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  UserRole role;

  RegisteredUserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });
}

// ============================================================
// KELOLA TEKNISI SCREEN (UI-ONLY MODE)
// ============================================================

class KelolaTeknisiScreen extends StatefulWidget {
  final List<TechnicianData>? technicians;
  final List<RegisteredUserData>? users;
  final ValueChanged<RegisteredUserData>? onRoleChanged;
  final ValueChanged<TechnicianData>? onTechnicianTap;

  const KelolaTeknisiScreen({
    super.key,
    this.technicians,
    this.users,
    this.onRoleChanged,
    this.onTechnicianTap,
  });

  @override
  State<KelolaTeknisiScreen> createState() => _KelolaTeknisiScreenState();
}

class _KelolaTeknisiScreenState extends State<KelolaTeknisiScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedTabIndex = 0;
  String _selectedWorkloadFilter = 'Semua';

  late List<TechnicianData> _technicians;
  late List<RegisteredUserData> _users;

  static const List<String> _workloadFilters = [
    'Semua',
    'Tersedia (0)',
    'Bertugas',
  ];

  // Data preview sementara agar seluruh skenario UI bisa langsung dilihat & diuji
  List<TechnicianData> _buildDummyTechnicians() => const [
        TechnicianData(
          uid: 'tech_01',
          name: 'Dedi Kurniawan',
          email: 'dedi.teknisi@snafix.id',
          assignedTicketCount: 0,
          inProgressTicketCount: 0,
        ),
        TechnicianData(
          uid: 'tech_02',
          name: 'Teknisi SnaFix',
          email: 'teknisi.utama@snafix.id',
          assignedTicketCount: 1,
          inProgressTicketCount: 1,
        ),
        TechnicianData(
          uid: 'tech_03',
          name: 'Andi Saputra',
          email: 'andi.saputra@snafix.id',
          assignedTicketCount: 2,
          inProgressTicketCount: 2,
        ),
      ];

  List<RegisteredUserData> _buildDummyUsers() => [
        RegisteredUserData(
          uid: 'pelapor_01',
          name: 'Budi Santoso',
          email: 'budi.staf.sarpras@campus.ac.id',
          role: UserRole.pelapor,
        ),
        // Sengaja dibuat nama sama untuk melihat pembeda unik lewat Email
        RegisteredUserData(
          uid: 'pelapor_02',
          name: 'Budi Santoso',
          email: 'budi.mahasiswa22@students.campus.ac.id',
          role: UserRole.pelapor,
        ),
        RegisteredUserData(
          uid: 'pelapor_03',
          name: 'Siti Rahmawati',
          email: 'siti.rahmawati@campus.ac.id',
          role: UserRole.pelapor,
        ),
        RegisteredUserData(
          uid: 'pelapor_04',
          name: 'Rizky Pratama',
          email: 'rizky.pratama@campus.ac.id',
          role: UserRole.pelapor,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _technicians = List<TechnicianData>.from(
      widget.technicians ?? _buildDummyTechnicians(),
    );
    _users = List<RegisteredUserData>.from(
      widget.users ?? _buildDummyUsers(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalTechnicians => _technicians.length;

  int get _totalActiveTickets => _technicians.fold(
        0,
        (total, technician) => total + technician.activeTicketCount,
      );

  List<TechnicianData> get _filteredTechnicians {
    final query = _searchController.text.trim().toLowerCase();

    final list = _technicians.where((tech) {
      final matchesSearch = query.isEmpty ||
          tech.name.toLowerCase().contains(query) ||
          tech.email.toLowerCase().contains(query);

      final matchesWorkload = switch (_selectedWorkloadFilter) {
        'Tersedia (0)' => tech.activeTicketCount == 0,
        'Bertugas' => tech.activeTicketCount > 0,
        _ => true,
      };

      return matchesSearch && matchesWorkload;
    }).toList();

    // Urutkan dari beban tugas paling ringan agar memudahkan acuan pembagian tugas
    list.sort((a, b) {
      final cmp = a.activeTicketCount.compareTo(b.activeTicketCount);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }

  List<RegisteredUserData> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesRole = user.role == UserRole.pelapor;
      final matchesSearch = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      return matchesRole && matchesSearch;
    }).toList();
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
      _searchController.clear();
      _selectedWorkloadFilter = 'Semua';
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: isError
              ? AppColors.statusRejectedText
              : const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openScanUserQr() async {
    final scannedUid = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(
          mode: ScanQrMode.user,
          role: UserRole.admin,
        ),
      ),
    );

    if (scannedUid == null || scannedUid.trim().isEmpty || !mounted) return;

    // TODO: Ganti dengan AuthService.instance.getUserData(scannedUid) saat integrasi BE
    _showMessage(
      'UI Preview: QR Pengguna terpindai (UID: $scannedUid). Siap disambungkan ke AuthService.',
    );
  }

  Future<void> _openTechnicianDetailSheet(TechnicianData technician) async {
    if (widget.onTechnicianTap != null) {
      widget.onTechnicianTap!(technician);
      return;
    }

    final shouldRevoke = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TechnicianDetailSheet(
        technician: technician,
        onRevokeTap: () => Navigator.pop(sheetContext, true),
      ),
    );

    if (shouldRevoke != true || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cabut Akses Teknisi?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text.rich(
          TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Kembalikan role '),
              TextSpan(
                text: technician.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: ' ('),
              TextSpan(
                text: technician.email,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: ') menjadi Pelapor?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejectedText,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: Text(
              'Cabut Akses',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // TODO: Cek ReportService.instance.countActiveTasksByTeknisi(uid) == 0
    // lalu panggil AuthService.instance.updateUserRole(uid: uid, newRole: UserRole.pelapor)
    setState(() {
      _technicians.removeWhere((t) => t.uid == technician.uid);
      final existingIndex = _users.indexWhere((u) => u.uid == technician.uid);
      if (existingIndex != -1) {
        _users[existingIndex].role = UserRole.pelapor;
      } else {
        _users.add(
          RegisteredUserData(
            uid: technician.uid,
            name: technician.name,
            email: technician.email,
            photoUrl: technician.photoUrl,
            role: UserRole.pelapor,
          ),
        );
      }
    });

    _showMessage(
      'UI Preview: Akses teknisi ${technician.name} dicabut (kembali ke Pelapor).',
    );
  }

  Future<void> _confirmTechnicianRole(RegisteredUserData user) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _RoleConfirmationSheet(
        user: user,
        onCancel: () => Navigator.pop(sheetContext, false),
        onConfirm: () => Navigator.pop(sheetContext, true),
      ),
    );

    if (confirmed != true || !mounted) return;

    // TODO: Sambungkan ke AuthService.instance.updateUserRole(uid: user.uid, newRole: UserRole.teknisi)
    setState(() {
      user.role = UserRole.teknisi;
      _technicians.add(
        TechnicianData(
          uid: user.uid,
          name: user.name,
          email: user.email,
          photoUrl: user.photoUrl,
          assignedTicketCount: 0,
          inProgressTicketCount: 0,
        ),
      );
      _searchController.clear();
      _selectedTabIndex = 0;
    });

    widget.onRoleChanged?.call(user);
    _showMessage('UI Preview: ${user.name} berhasil diaktifkan sebagai Teknisi.');
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Kelola Teknisi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              onPressed: _openScanUserQr,
              tooltip: 'Scan QR Profil Pengguna',
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildTabNavigation(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildTechnicianTab()
                      : _buildRegisterTechnicianTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TechnicianTabButton(
              label: 'Daftar Teknisi',
              icon: Icons.handyman_outlined,
              isSelected: _selectedTabIndex == 0,
              onTap: () => _onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TechnicianTabButton(
              label: 'Daftarkan Teknisi',
              icon: Icons.person_add_alt_1_rounded,
              isSelected: _selectedTabIndex == 1,
              onTap: () => _onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB 1: DAFTAR TEKNISI
  // ==========================================================

  Widget _buildTechnicianTab() {
    final technicians = _filteredTechnicians;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(hint: 'Cari nama atau email teknisi...'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildWorkloadFilterChips(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTechnicianSummary(),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Teknisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${technicians.length} Teknisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: technicians.isEmpty
              ? _EmptyState(
                  icon: Icons.engineering_outlined,
                  title: _technicians.isEmpty
                      ? 'Belum Ada Teknisi'
                      : 'Teknisi Tidak Ditemukan',
                  description: _technicians.isEmpty
                      ? 'Aktifkan akun petugas melalui tab Daftarkan Teknisi atau Scan QR Profil.'
                      : 'Coba ubah kata pencarian atau filter beban tugas.',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: technicians.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final technician = technicians[index];
                    return _TechnicianCard(
                      technician: technician,
                      onTap: () => _openTechnicianDetailSheet(technician),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkloadFilterChips() {
    return Row(
      children: _workloadFilters.map((filter) {
        final isSelected = _selectedWorkloadFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedWorkloadFilter = filter),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTechnicianSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.engineering_rounded,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Teknisi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_totalTechnicians',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Tiket Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_totalActiveTickets',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB 2: DAFTARKAN TEKNISI (SCAN QR PROFIL + SEARCH EMAIL/NAMA)
  // ==========================================================

  Widget _buildRegisterTechnicianTab() {
    final users = _filteredUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cara 1: Scan QR Profil Akun
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildScanQrCard(),
        ),
        const SizedBox(height: 14),

        // Cara 2: Pencarian Email / Nama (Jarak Jauh)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(
            hint: 'Cari nama atau email pelapor...',
          ),
        ),
        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Kandidat Pelapor',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${users.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: users.isEmpty
              ? const _EmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Pengguna Tidak Ditemukan',
                  description:
                      'Cari akun berdasarkan nama atau email. Hanya akun dengan role Pelapor yang dapat diangkat menjadi Teknisi.',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _RegisteredUserCard(
                      user: user,
                      onMakeTechnician: () => _confirmTechnicianRole(user),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScanQrCard() {
    return Material(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openScanUserQr,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan QR Profil Pengguna',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pindai QR dari halaman Profil calon teknisi untuk aktivasi cepat.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({required String hint}) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, size: 19),
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TECHNICIAN TAB BUTTON
// ============================================================

class _TechnicianTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TechnicianTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TECHNICIAN CARD
// ============================================================

class _TechnicianCard extends StatelessWidget {
  final TechnicianData technician;
  final VoidCallback onTap;

  const _TechnicianCard({
    required this.technician,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeTickets = technician.activeTicketCount;

    final Color badgeBackground;
    final Color badgeText;
    final String workloadNote;

    if (activeTickets >= 4) {
      badgeBackground = AppColors.statusRejectedBg;
      badgeText = AppColors.statusRejectedText;
      workloadNote = 'Beban tinggi';
    } else if (activeTickets >= 2) {
      badgeBackground = AppColors.statusProcessBg;
      badgeText = AppColors.statusProcessText;
      workloadNote = 'Sedang bertugas';
    } else if (activeTickets == 1) {
      badgeBackground = AppColors.statusDoneBg;
      badgeText = AppColors.primaryBlue;
      workloadNote = 'Sedang bertugas';
    } else {
      badgeBackground = AppColors.statusSuccessBg;
      badgeText = AppColors.statusSuccessText;
      workloadNote = 'Siap ditugaskan';
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEF6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _UserAvatar(
                name: technician.name,
                photoUrl: technician.photoUrl,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      technician.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: badgeText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          workloadNote,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 74,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '$activeTickets',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: badgeText,
                      ),
                    ),
                    Text(
                      'Tiket Aktif',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL & CABUT AKSES TEKNISI BOTTOM SHEET
// ============================================================

class _TechnicianDetailSheet extends StatelessWidget {
  final TechnicianData technician;
  final VoidCallback onRevokeTap;

  const _TechnicianDetailSheet({
    required this.technician,
    required this.onRevokeTap,
  });

  @override
  Widget build(BuildContext context) {
    final canRevoke = technician.activeTicketCount == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3ED),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _UserAvatar(
                  name: technician.name,
                  photoUrl: technician.photoUrl,
                  size: 56,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technician.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        technician.email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ringkasan Beban Kerja Teknisi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FD),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Ditugaskan',
                      value: '${technician.assignedTicketCount}',
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Dikerjakan',
                      value: '${technician.inProgressTicketCount}',
                      color: AppColors.statusProcessText,
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Total Aktif',
                      value: '${technician.activeTicketCount}',
                      color: canRevoke
                          ? AppColors.statusSuccessText
                          : AppColors.statusRejectedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Info syarat cabut akses (aktif == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: canRevoke
                    ? const Color(0xFFF0FBF5)
                    : AppColors.statusProcessBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    canRevoke
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 19,
                    color: canRevoke
                        ? AppColors.statusSuccessText
                        : AppColors.statusProcessText,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      canRevoke
                          ? 'Teknisi ini tidak memiliki tiket aktif. Akses teknisi dapat dicabut sewaktu-waktu jika petugas sudah tidak bertugas.'
                          : 'Akses teknisi tidak dapat dicabut selama masih memiliki ${technician.activeTicketCount} tiket aktif. Alihkan atau selesaikan semua tugasnya terlebih dahulu.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canRevoke ? onRevokeTap : null,
                icon: const Icon(Icons.person_remove_outlined, size: 19),
                label: Text(
                  'Cabut Akses (Kembalikan ke Pelapor)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusRejectedText,
                  disabledForegroundColor: AppColors.textSecondary,
                  side: BorderSide(
                    color: canRevoke
                        ? AppColors.statusRejectedText
                        : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// REGISTERED USER CARD (KANDIDAT PELAPOR)
// ============================================================

class _RegisteredUserCard extends StatelessWidget {
  final RegisteredUserData user;
  final VoidCallback onMakeTechnician;

  const _RegisteredUserCard({
    required this.user,
    required this.onMakeTechnician,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _UserAvatar(
            name: user.name,
            photoUrl: user.photoUrl,
            size: 54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusDoneBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.role.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onMakeTechnician,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size.zero,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz_rounded, size: 18),
                const SizedBox(height: 2),
                Text(
                  'Jadikan\nTeknisi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ROLE CONFIRMATION SHEET (PELAPOR -> TEKNISI)
// ============================================================

class _RoleConfirmationSheet extends StatelessWidget {
  final RegisteredUserData user;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _RoleConfirmationSheet({
    required this.user,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3ED),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.statusDoneBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Aktifkan Role Teknisi?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'Berikan akses sebagai teknisi kepada ',
                  ),
                  TextSpan(
                    text: user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: ' ('),
                  TextSpan(
                    text: user.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: ')?'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB45309),
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Pastikan nama dan email sudah sesuai dengan petugas teknisi resmi pemeliharaan fasilitas kampus.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _RoleBadge(
                    icon: Icons.person_outline_rounded,
                    label: UserRole.pelapor.label,
                    backgroundColor: AppColors.statusDoneBg,
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: _RoleBadge(
                    icon: Icons.engineering_rounded,
                    label: UserRole.teknisi.label,
                    backgroundColor: AppColors.statusSuccessBg,
                    foregroundColor: AppColors.statusSuccessText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      'Aktifkan Teknisi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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
  }
}

class _RoleBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _RoleBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: foregroundColor),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const _UserAvatar({
    required this.name,
    required this.photoUrl,
    required this.size,
  });

  String get _initial {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitial(),
            )
          : _buildInitial(),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        _initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.28,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: AppColors.statusDoneBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}