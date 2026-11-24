import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tubes_pemob/constants/app_colors.dart';

// ============================================================
// MODEL DATA TEKNISI
// ============================================================

class TechnicianData {
  final String uid;
  final String name;
  final String email;
  final List<String> buildings;
  final int assignedTicketCount;
  final int inProgressTicketCount;
  final String? photoUrl;

  const TechnicianData({
    required this.uid,
    required this.name,
    required this.email,
    required this.buildings,
    this.assignedTicketCount = 0,
    this.inProgressTicketCount = 0,
    this.photoUrl,
  });

  // Jumlah tiket aktif = assigned + inProgress
  int get activeTicketCount =>
      assignedTicketCount + inProgressTicketCount;
}

// ============================================================
// MODEL DATA PENGGUNA TERDAFTAR
// ============================================================

enum UserRole {
  pelapor,
  teknisi,
  admin,
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
// KELOLA TEKNISI SCREEN
// ============================================================

class KelolaTeknisiScreen extends StatefulWidget {
  final List<TechnicianData> technicians;
  final List<RegisteredUserData> users;

  final ValueChanged<RegisteredUserData>? onRoleChanged;

  final ValueChanged<TechnicianData>? onTechnicianTap;

  const KelolaTeknisiScreen({
    super.key,
    this.technicians = const [],
    this.users = const [],
    this.onRoleChanged,
    this.onTechnicianTap,
  });

  @override
  State<KelolaTeknisiScreen> createState() =>
      _KelolaTeknisiScreenState();
}

class _KelolaTeknisiScreenState extends State<KelolaTeknisiScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ==========================================================
  // STATE
  // ==========================================================

  int _selectedTabIndex = 0;

  String _selectedBuilding = 'Semua Gedung';

  late List<TechnicianData> _technicians;

  late List<RegisteredUserData> _users;

  @override
  void initState() {
    super.initState();

    // Data diterima dari halaman pemanggil.
    // Tidak menggunakan data dummy.
    _technicians = List<TechnicianData>.from(
      widget.technicians,
    );

    _users = List<RegisteredUserData>.from(
      widget.users,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // TOTAL TECHNICIAN
  // ==========================================================

  int get _totalTechnicians => _technicians.length;

  // ==========================================================
  // TOTAL ACTIVE TICKETS
  // ==========================================================

  int get _totalActiveTickets {
    return _technicians.fold(
      0,
      (total, technician) =>
          total + technician.activeTicketCount,
    );
  }

  // ==========================================================
  // BUILDING OPTIONS
  // ==========================================================

  List<String> get _buildingOptions {
    final buildings = _technicians
        .expand((technician) => technician.buildings)
        .toSet()
        .toList()
      ..sort();

    return [
      'Semua Gedung',
      ...buildings,
    ];
  }

  // ==========================================================
  // FILTER TECHNICIANS
  // ==========================================================

  List<TechnicianData> get _filteredTechnicians {
    final query = _searchController.text.toLowerCase();

    return _technicians.where((technician) {
      final matchesSearch =
          technician.name.toLowerCase().contains(query) ||
          technician.email.toLowerCase().contains(query);

      final matchesBuilding =
          _selectedBuilding == 'Semua Gedung' ||
          technician.buildings.contains(_selectedBuilding);

      return matchesSearch && matchesBuilding;
    }).toList();
  }

  // ==========================================================
  // SEARCH REGISTERED USERS
  // ==========================================================

  List<RegisteredUserData> get _filteredUsers {
    final query = _searchController.text.toLowerCase();

    return _users.where((user) {
      final matchesRole = user.role == UserRole.pelapor;

      final matchesSearch =
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);

      return matchesRole && matchesSearch;
    }).toList();
  }

  // ==========================================================
  // SWITCH TAB
  // ==========================================================

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;

      _searchController.clear();

      _selectedBuilding = 'Semua Gedung';
    });
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,

        // APP BAR
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
              onPressed: () => _onTabChanged(1),
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 23,
              ),
            ),

            const SizedBox(width: 5),
          ],
        ),

        // MAIN CONTENT
        body: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),

            child: Column(
              children: [
                // TAB NAVIGATION
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    0,
                  ),
                  child: _buildTabNavigation(),
                ),

                const SizedBox(height: 16),

                // TAB CONTENT
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

  // ==========================================================
  // TAB NAVIGATION
  // ==========================================================

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // DAFTAR TEKNISI
          Expanded(
            child: _TechnicianTabButton(
              label: 'Daftar Teknisi',
              icon: Icons.handyman_outlined,
              isSelected: _selectedTabIndex == 0,
              onTap: () => _onTabChanged(0),
            ),
          ),

          // DAFTARKAN TEKNISI
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
  // TECHNICIAN TAB
  // ==========================================================

  Widget _buildTechnicianTab() {
    return Column(
      children: [
        // SEARCH
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(
            hint: 'Cari nama atau email teknisi...',
          ),
        ),

        const SizedBox(height: 14),

        // BUILDING FILTER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildBuildingFilter(),
        ),

        const SizedBox(height: 18),

        // SUMMARY
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTechnicianSummary(),
        ),

        const SizedBox(height: 18),

        // LIST HEADER
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
                '${_filteredTechnicians.length} Teknisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // TECHNICIAN LIST
        Expanded(
          child: _buildTechnicianList(),
        ),
      ],
    );
  }

  // ==========================================================
  // SEARCH FIELD
  // ==========================================================

  Widget _buildSearchField({
    required String hint,
  }) {
    return TextField(
      controller: _searchController,

      onChanged: (_) {
        setState(() {});
      },

      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppColors.textPrimary,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),

        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                ),
              )
            : null,

        filled: true,
        fillColor: const Color(0xFFEEF2FA),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILDING FILTER
  // ==========================================================

  Widget _buildBuildingFilter() {
    final options = _buildingOptions;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.border,
          ),
        ),

        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(_selectedBuilding)
                ? _selectedBuilding
                : 'Semua Gedung',

            isExpanded: true,

            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),

            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),

            items: options.map((building) {
              return DropdownMenuItem(
                value: building,
                child: Text(building),
              );
            }).toList(),

            onChanged: (value) {
              setState(() {
                _selectedBuilding = value!;
              });
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TECHNICIAN SUMMARY
  // ==========================================================

  Widget _buildTechnicianSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(17),
      ),

      child: Row(
        children: [
          // TOTAL TEKNISI
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.engineering_rounded,
                  size: 34,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '$_totalTechnicians',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 23,
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
            height: 53,
            color: AppColors.primaryBlue.withValues(
              alpha: 0.2,
            ),
          ),

          const SizedBox(width: 15),

          // TOTAL TIKET AKTIF
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 34,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '$_totalActiveTickets',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 23,
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
  // TECHNICIAN LIST
  // ==========================================================

  Widget _buildTechnicianList() {
    final technicians = _filteredTechnicians;

    if (technicians.isEmpty) {
      return _EmptyState(
        icon: Icons.engineering_outlined,
        title: _technicians.isEmpty
            ? 'Belum Ada Teknisi'
            : 'Teknisi Tidak Ditemukan',
        description: _technicians.isEmpty
            ? 'Daftar teknisi akan ditampilkan setelah data tersedia.'
            : 'Coba ubah kata pencarian atau filter gedung.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        25,
      ),

      itemCount: technicians.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 10);
      },

      itemBuilder: (context, index) {
        final technician = technicians[index];

        return _TechnicianCard(
          technician: technician,
          onTap: () {
            widget.onTechnicianTap?.call(technician);
          },
        );
      },
    );
  }

  // ==========================================================
  // REGISTER TECHNICIAN TAB
  // ==========================================================

  Widget _buildRegisterTechnicianTab() {
    final users = _filteredUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFORMATION BOX
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const _InformationBanner(
            icon: Icons.info_outline_rounded,
            message:
                'Cari akun petugas fasilitas kampus yang telah terdaftar untuk diberikan akses sebagai teknisi SnaFix.',
          ),
        ),

        const SizedBox(height: 16),

        // SEARCH USER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(
            hint: 'Cari nama atau email pengguna...',
          ),
        ),

        const SizedBox(height: 24),

        // SEARCH RESULT HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Hasil Pencarian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(width: 5),

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

        // USER LIST
        Expanded(
          child: _buildRegisteredUserList(users),
        ),
      ],
    );
  }

  // ==========================================================
  // REGISTERED USER LIST
  // ==========================================================

  Widget _buildRegisteredUserList(
    List<RegisteredUserData> users,
  ) {
    if (users.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_search_rounded,
        title: 'Pengguna Tidak Ditemukan',
        description:
            'Cari akun berdasarkan nama atau email. Hanya akun dengan role Pelapor yang dapat didaftarkan sebagai Teknisi.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        25,
      ),

      itemCount: users.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 10);
      },

      itemBuilder: (context, index) {
        final user = users[index];

        return _RegisteredUserCard(
          user: user,
          onMakeTechnician: () {
            _confirmTechnicianRole(user);
          },
        );
      },
    );
  }

  // ==========================================================
  // CONFIRM ROLE CHANGE
  // ==========================================================

  Future<void> _confirmTechnicianRole(
    RegisteredUserData user,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,

      builder: (sheetContext) {
        return _RoleConfirmationSheet(
          user: user,
          onCancel: () {
            Navigator.pop(sheetContext, false);
          },
          onConfirm: () {
            Navigator.pop(sheetContext, true);
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // UPDATE ROLE SECARA LOKAL
    setState(() {
      user.role = UserRole.teknisi;

      // Pengguna yang telah menjadi teknisi
      // otomatis masuk daftar teknisi.
      _technicians.add(
        TechnicianData(
          uid: user.uid,
          name: user.name,
          email: user.email,
          photoUrl: user.photoUrl,
          buildings: const [],
          assignedTicketCount: 0,
          inProgressTicketCount: 0,
        ),
      );
    });

    // CALLBACK UNTUK HALAMAN PEMANGGIL
    widget.onRoleChanged?.call(user);

    // PINDAH KE TAB DAFTAR TEKNISI
    _searchController.clear();

    setState(() {
      _selectedTabIndex = 0;
    });

    _showMessage(
      '${user.name} berhasil diaktifkan sebagai Teknisi.',
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
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? AppColors.white
                  : AppColors.textPrimary,
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textPrimary,
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

    if (activeTickets >= 4) {
      badgeBackground = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFDC2626);
    } else if (activeTickets == 3) {
      badgeBackground = const Color(0xFFFFEDD5);
      badgeText = const Color(0xFFC2410C);
    } else {
      badgeBackground = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),

      child: Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE8EEF6),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A)
                  .withValues(alpha: 0.03),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            // FOTO TEKNISI
            _UserAvatar(
              name: technician.name,
              photoUrl: technician.photoUrl,
              size: 66,
            ),

            const SizedBox(width: 12),

            // INFORMASI TEKNISI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    technician.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          technician.buildings.isEmpty
                              ? 'Gedung belum ditentukan'
                              : technician.buildings.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // TIKET AKTIF
            Container(
              width: 82,
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '$activeTickets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: badgeText,
                    ),
                  ),

                  Text(
                    'Tiket Aktif',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REGISTERED USER CARD
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
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: 0.03),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // FOTO PENGGUNA
          _UserAvatar(
            name: user.name,
            photoUrl: user.photoUrl,
            size: 66,
          ),

          const SizedBox(width: 12),

          // INFORMASI USER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
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
                        'Pelapor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
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

          const SizedBox(width: 7),

          // ACTION BUTTON
          OutlinedButton(
            onPressed: onMakeTechnician,

            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,

              side: const BorderSide(
                color: AppColors.primaryBlue,
              ),

              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 10,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              minimumSize: Size.zero,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 19,
                ),

                const SizedBox(height: 3),

                Text(
                  'Jadikan\nTeknisi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
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
// ROLE CONFIRMATION SHEET
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
      padding: const EdgeInsets.fromLTRB(
        22,
        12,
        22,
        25,
      ),

      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HANDLE
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3ED),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 23),

            // ICON
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.statusDoneBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                size: 42,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            // TITLE
            Text(
              'Aktifkan Role Teknisi?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 9),

            // DESCRIPTION
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

            const SizedBox(height: 20),

            // WARNING
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
                    size: 22,
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      'Pastikan akun yang dipilih merupakan petugas teknisi resmi yang bertanggung jawab atas pemeliharaan fasilitas kampus.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 23),

            // ROLE TRANSITION
            Row(
              children: [
                Expanded(
                  child: _RoleBadge(
                    icon: Icons.person_outline_rounded,
                    label: 'Pelapor',
                    backgroundColor: AppColors.statusDoneBg,
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary,
                    size: 23,
                  ),
                ),

                Expanded(
                  child: _RoleBadge(
                    icon: Icons.engineering_rounded,
                    label: 'Teknisi',
                    backgroundColor: const Color(0xFFDCFCE7),
                    foregroundColor: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,

                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,

                      side: const BorderSide(
                        color: AppColors.primaryBlue,
                      ),

                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),

                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
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

                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),

                    child: Text(
                      'Aktifkan Teknisi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
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

// ============================================================
// ROLE BADGE
// ============================================================

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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: foregroundColor,
          ),

          const SizedBox(width: 7),

          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// USER AVATAR
// ============================================================

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
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

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
              errorBuilder: (context, error, stackTrace) {
                return _buildInitial();
              },
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

// ============================================================
// INFORMATION BANNER
// ============================================================

class _InformationBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InformationBanner({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 21,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
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
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

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
              width: 85,
              height: 85,
              decoration: const BoxDecoration(
                color: AppColors.statusDoneBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 18),

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
                fontSize: 11,
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