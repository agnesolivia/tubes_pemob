import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/widgets/teknisi_cards.dart';
import 'package:tubes_pemob/screens/admin/widgets/teknisi_sheets.dart';
import 'package:tubes_pemob/screens/shared/scan_qr_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';

class KelolaTeknisiScreen extends StatefulWidget {
  const KelolaTeknisiScreen({super.key});

  @override
  State<KelolaTeknisiScreen> createState() => _KelolaTeknisiScreenState();
}

class _KelolaTeknisiScreenState extends State<KelolaTeknisiScreen> {
  final TextEditingController _techSearchController = TextEditingController();
  final TextEditingController _candidateSearchController =
      TextEditingController();

  late final Stream<List<UserModel>> _techniciansStream;
  late final Stream<Map<String, int>> _taskCountsStream;

  static const String _filterAll = 'semua';
  static const String _filterAvailable = 'tersedia';
  static const String _filterBusy = 'bertugas';
  static const int _minSearchLength = 2;
  static const int _candidateSearchLimit = 15;

  int _selectedTabIndex = 0;
  String _selectedWorkloadFilter = _filterAll;
  bool _isProcessing = false;

  // State pencarian kandidat on-demand (Tab 2)
  Timer? _searchDebounce;
  List<UserModel> _candidateResults = const [];
  bool _isSearchingCandidates = false;
  String? _candidateSearchError;
  String _lastSearchedQuery = '';
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _techniciansStream = AuthService.instance.streamTechnicians();
    _taskCountsStream =
        ReportService.instance.streamTechnicianActiveTaskCounts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _techSearchController.dispose();
    _candidateSearchController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTabIndex = index;
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
          duration: const Duration(seconds: 3),
        ),
      );
  }

  List<UserModel> _filterTechnicians(
    List<UserModel> allTechnicians,
    Map<String, int> taskCounts,
  ) {
    final query = _techSearchController.text.trim().toLowerCase();
    final list = allTechnicians.where((tech) {
      final activeCount = taskCounts[tech.uid] ?? 0;
      final matchesSearch = query.isEmpty ||
          tech.nama.toLowerCase().contains(query) ||
          tech.email.toLowerCase().contains(query);
      final matchesWorkload = switch (_selectedWorkloadFilter) {
        _filterAvailable => activeCount == 0,
        _filterBusy => activeCount > 0,
        _ => true,
      };
      return matchesSearch && matchesWorkload;
    }).toList();

    list.sort((a, b) {
      final cmp = (taskCounts[a.uid] ?? 0).compareTo(taskCounts[b.uid] ?? 0);
      if (cmp != 0) return cmp;
      return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
    });
    return list;
  }

  // ==========================================================
  // PENCARIAN KANDIDAT PELAPOR ON-DEMAND (TAB 2)
  // ==========================================================

  void _onCandidateQueryChanged(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.length < _minSearchLength) {
      _searchRequestId++;
      setState(() {
        _candidateResults = const [];
        _isSearchingCandidates = false;
        _candidateSearchError = null;
        _lastSearchedQuery = '';
      });
      return;
    }

    setState(() {});
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchCandidates(trimmed),
    );
  }

  Future<void> _searchCandidates(String rawQuery) async {
    final trimmed = rawQuery.trim();
    if (trimmed.length < _minSearchLength) return;

    final requestId = ++_searchRequestId;
    setState(() {
      _isSearchingCandidates = true;
      _candidateSearchError = null;
    });

    try {
      final results = await AuthService.instance.searchPelaporCandidates(
        trimmed,
        limit: _candidateSearchLimit,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _candidateResults = results;
        _lastSearchedQuery = trimmed;
        _isSearchingCandidates = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _candidateSearchError =
            e.toString().replaceFirst('Exception: ', '');
        _isSearchingCandidates = false;
      });
    }
  }

  void _clearCandidateSearch() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    _candidateSearchController.clear();
    setState(() {
      _candidateResults = const [];
      _isSearchingCandidates = false;
      _candidateSearchError = null;
      _lastSearchedQuery = '';
    });
  }

  // ==========================================================
  // AKSI FIRESTORE
  // ==========================================================

  Future<void> _openScanUserQr() async {
    if (_isProcessing) return;

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

    setState(() => _isProcessing = true);
    UserModel? targetUser;
    try {
      targetUser = await AuthService.instance.getUserData(scannedUid.trim());
    } catch (e) {
      _showMessage('Gagal membaca data pengguna: $e', isError: true);
      return;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (!mounted) return;
    if (targetUser == null) {
      _showMessage('Akun pengguna dari QR tidak ditemukan.', isError: true);
      return;
    }
    if (targetUser.isAdmin) {
      _showMessage(
        '${targetUser.nama} berstatus Admin dan tidak dapat diubah menjadi Teknisi.',
        isError: true,
      );
      return;
    }
    if (targetUser.isTeknisi) {
      _showMessage('${targetUser.nama} sudah terdaftar sebagai Teknisi.');
      return;
    }

    await _promoteToTechnician(targetUser);
  }

  Future<void> _promoteToTechnician(UserModel user) async {
    if (_isProcessing) return;
    final confirmed = await showPromoteTechnicianSheet(context, user: user);
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await AuthService.instance.updateUserRole(
        uid: user.uid,
        newRole: UserRole.teknisi,
      );
      if (!mounted) return;
      _clearCandidateSearch();
      setState(() => _selectedTabIndex = 0);
      _showMessage('${user.nama} berhasil diaktifkan sebagai Teknisi.');
    } catch (e) {
      _showMessage(
        'Gagal mengaktifkan teknisi: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleTechnicianTap(
    UserModel technician,
    int activeTaskCount,
  ) async {
    if (_isProcessing) return;
    final shouldRevoke = await showTechnicianDetailSheet(
      context,
      technician: technician,
      activeTaskCount: activeTaskCount,
    );
    if (!shouldRevoke || !mounted) return;

    final confirmed = await showRevokeTechnicianDialog(
      context,
      technician: technician,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final latestActiveTasks = await ReportService.instance
          .countActiveTasksByTeknisi(technician.uid);
      if (latestActiveTasks > 0) {
        _showMessage(
          'Gagal mencabut akses: ${technician.nama} masih memiliki $latestActiveTasks tiket aktif.',
          isError: true,
        );
        return;
      }

      await AuthService.instance.updateUserRole(
        uid: technician.uid,
        newRole: UserRole.pelapor,
      );
      _showMessage(
        'Akses teknisi ${technician.nama} berhasil dicabut (kembali ke Pelapor).',
      );
    } catch (e) {
      _showMessage(
        'Gagal mencabut akses: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
        ),
        floatingActionButton: _selectedTabIndex == 1
            ? FloatingActionButton.extended(
                onPressed: _isProcessing ? null : _openScanUserQr,
                backgroundColor: _isProcessing
                    ? AppColors.border
                    : AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: Text(
                  'Scan QR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
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
                if (_isProcessing)
                  const LinearProgressIndicator(
                    minHeight: 2.5,
                    color: AppColors.primaryBlue,
                    backgroundColor: Color(0xFFEAF2FF),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildTabNavigation(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildTechnicianStreamTab(),
                      _buildRegisterTab(),
                    ],
                  ),
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
          _tabItem(0, 'Daftar Teknisi', Icons.handyman_outlined),
          _tabItem(1, 'Daftarkan Teknisi', Icons.person_add_alt_1_rounded),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabChanged(index),
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
      ),
    );
  }

  // ==========================================================
  // TAB 1: DAFTAR TEKNISI (STREAM KHUSUS ROLE TEKNISI)
  // ==========================================================

  Widget _buildTechnicianStreamTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _techniciansStream,
      builder: (context, techSnap) {
        if (techSnap.connectionState == ConnectionState.waiting &&
            !techSnap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }
        if (techSnap.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal Memuat Daftar Teknisi',
            description: '${techSnap.error}',
          );
        }

        final allTechnicians = techSnap.data ?? const <UserModel>[];

        return StreamBuilder<Map<String, int>>(
          stream: _taskCountsStream,
          builder: (context, countSnap) {
            return _buildTechnicianTab(
              allTechnicians: allTechnicians,
              taskCounts: countSnap.data ?? const {},
            );
          },
        );
      },
    );
  }

  Widget _buildTechnicianTab({
    required List<UserModel> allTechnicians,
    required Map<String, int> taskCounts,
  }) {
    final technicians = _filterTechnicians(allTechnicians, taskCounts);
    final availableCount =
        allTechnicians.where((t) => (taskCounts[t.uid] ?? 0) == 0).length;
    final busyCount = allTechnicians.length - availableCount;
    final displayedActiveTickets = technicians.fold<int>(
      0,
      (sum, tech) => sum + (taskCounts[tech.uid] ?? 0),
    );

    final chips = <({String key, String label})>[
      (key: _filterAll, label: 'Semua (${allTechnicians.length})'),
      (key: _filterAvailable, label: 'Tersedia ($availableCount)'),
      (key: _filterBusy, label: 'Bertugas ($busyCount)'),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(
            controller: _techSearchController,
            hint: 'Cari nama atau email teknisi...',
            onChanged: (_) => setState(() {}),
            onClear: () {
              _techSearchController.clear();
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chip = chips[index];
              final selected = _selectedWorkloadFilter == chip.key;
              return InkWell(
                onTap: () =>
                    setState(() => _selectedWorkloadFilter = chip.key),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryBlue : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          selected ? AppColors.primaryBlue : AppColors.border,
                    ),
                  ),
                  child: Text(
                    chip.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
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
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${technicians.length} Teknisi • $displayedActiveTickets Tiket Aktif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: technicians.isEmpty
              ? _buildEmptyState(
                  icon: Icons.engineering_outlined,
                  title: allTechnicians.isEmpty
                      ? 'Belum Ada Teknisi'
                      : 'Teknisi Tidak Ditemukan',
                  description: allTechnicians.isEmpty
                      ? 'Aktifkan akun petugas melalui tab Daftarkan Teknisi atau Scan QR Profil.'
                      : 'Coba ubah kata pencarian atau filter beban tugas.',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: technicians.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tech = technicians[index];
                    final count = taskCounts[tech.uid] ?? 0;
                    return TechnicianCard(
                      technician: tech,
                      activeTaskCount: count,
                      onTap: () => _handleTechnicianTap(tech, count),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================================
  // TAB 2: DAFTARKAN TEKNISI (SEARCH-ON-DEMAND + SCAN QR FAB)
  // ==========================================================

  Widget _buildRegisterTab() {
    final trimmedQuery = _candidateSearchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(
            controller: _candidateSearchController,
            hint: 'Ketik nama depan atau email pelapor...',
            textInputAction: TextInputAction.search,
            onChanged: _onCandidateQueryChanged,
            onSubmitted: (value) {
              _searchDebounce?.cancel();
              _searchCandidates(value);
            },
            onClear: _clearCandidateSearch,
          ),
        ),
        if (_lastSearchedQuery.isNotEmpty &&
            !_isSearchingCandidates &&
            _candidateSearchError == null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kandidat Pelapor (${_candidateResults.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_candidateResults.length >= _candidateSearchLimit)
                  Text(
                    'Maks. $_candidateSearchLimit hasil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: _buildRegisterTabBody(trimmedQuery),
        ),
      ],
    );
  }

  Widget _buildRegisterTabBody(String trimmedQuery) {
    if (trimmedQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search_rounded,
        title: 'Cari Kandidat Teknisi',
        description:
            'Ketik minimal $_minSearchLength huruf awal nama atau email pelapor, atau tekan tombol Scan QR di kanan bawah.',
        extraBottomPadding: true,
      );
    }

    if (trimmedQuery.length < _minSearchLength) {
      return _buildEmptyState(
        icon: Icons.keyboard_rounded,
        title: 'Ketik Minimal $_minSearchLength Karakter',
        description:
            'Masukkan minimal $_minSearchLength huruf awal nama atau email untuk mencari akun pelapor.',
        extraBottomPadding: true,
      );
    }

    if (_isSearchingCandidates) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_candidateSearchError != null) {
      return _buildEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Gagal Mencari Pengguna',
        description: _candidateSearchError!,
        extraBottomPadding: true,
      );
    }

    if (_lastSearchedQuery.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_candidateResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        title: 'Pelapor Tidak Ditemukan',
        description:
            'Tidak ada akun Pelapor yang diawali "$_lastSearchedQuery". Coba cari dengan email lengkap atau gunakan Scan QR.',
        extraBottomPadding: true,
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      itemCount: _candidateResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _candidateResults[index];
        return PelaporCandidateCard(
          user: user,
          onMakeTechnician:
              _isProcessing ? null : () => _promoteToTechnician(user),
        );
      },
    );
  }

  // ==========================================================
  // SHARED UI HELPERS
  // ==========================================================

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    ValueChanged<String>? onSubmitted,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
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
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 19),
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12.5,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    bool extraBottomPadding = false,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          28,
          28,
          28,
          extraBottomPadding ? 96 : 28,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: AppColors.statusDoneBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
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
