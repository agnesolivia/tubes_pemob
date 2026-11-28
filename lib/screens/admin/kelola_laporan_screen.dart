import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/detail_laporan_screen.dart';
import 'package:tubes_pemob/services/report_service.dart';
import 'package:tubes_pemob/widgets/report_card.dart';

class KelolaLaporanScreen extends StatefulWidget {
  static const String allStatusKey = 'semua';
  static const String overdueStatusKey = 'overdue';
  static const String unregisteredStatusKey = 'unregistered';

  /// Tampilkan tombol kembali jika dibuka lewat `Navigator.push`
  /// (biarkan `false` saat dipakai sebagai tab di `AdminMainScreen`).
  final bool showBackButton;

  /// Filter status awal yang diterapkan saat halaman dibuka atau saat
  /// berpindah tab dari `AdminDashboardScreen` (misal `overdueStatusKey`).
  final String? initialStatusFilter;

  /// Penanda versi permintaan filter dari parent (`AdminMainScreen`) agar
  /// perubahan filter tetap diterapkan walaupun widget berada di `IndexedStack`.
  final int filterRequestVersion;

  const KelolaLaporanScreen({
    super.key,
    this.showBackButton = false,
    this.initialStatusFilter,
    this.filterRequestVersion = 0,
  });

  @override
  State<KelolaLaporanScreen> createState() => _KelolaLaporanScreenState();
}

class _KelolaLaporanScreenState extends State<KelolaLaporanScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<ReportModel>> _reportsStream;

  static const String _allStatusKey = KelolaLaporanScreen.allStatusKey;
  static const String _overdueStatusKey = KelolaLaporanScreen.overdueStatusKey;
  static const String _unregisteredStatusKey =
      KelolaLaporanScreen.unregisteredStatusKey;

  static const String _allBuildingsLabel = 'Semua Gedung';
  static const String _allRoomsLabel = 'Semua Ruangan';
  static const String _noRoomLabel = 'Tanpa Ruangan';
  static const String _allPrioritiesLabel = 'Semua Prioritas';
  static const String _noPriorityLabel = 'Belum Ditetapkan';

  late String _selectedStatusFilter;
  String _selectedBuilding = _allBuildingsLabel;
  String _selectedRoom = _allRoomsLabel;
  String _selectedPriority = _allPrioritiesLabel;

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = widget.initialStatusFilter ?? _allStatusKey;
    _reportsStream = ReportService.instance.streamAllReports();
  }

  @override
  void didUpdateWidget(covariant KelolaLaporanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterRequestVersion != oldWidget.filterRequestVersion &&
        widget.initialStatusFilter != null) {
      _searchController.clear();
      _selectedStatusFilter = widget.initialStatusFilter!;
      _selectedBuilding = _allBuildingsLabel;
      _selectedRoom = _allRoomsLabel;
      _selectedPriority = _allPrioritiesLabel;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static ({String gedung, String ruangan}) _parseLocation(String assetLokasi) {
    final trimmed = assetLokasi.trim();
    if (trimmed.isEmpty) return (gedung: '', ruangan: '');

    final match = RegExp(r'\s+[-–]\s+').firstMatch(trimmed);
    if (match != null) {
      final gedung = trimmed.substring(0, match.start).trim();
      final ruangan = trimmed.substring(match.end).trim();
      return (gedung: gedung, ruangan: ruangan);
    }

    return (gedung: trimmed, ruangan: '');
  }

  static List<String> _buildBuildingOptions(List<ReportModel> reports) {
    final Map<String, String> uniqueMap = {};
    for (final report in reports) {
      final gedung = _parseLocation(report.assetLokasi).gedung;
      if (gedung.isNotEmpty) {
        uniqueMap.putIfAbsent(gedung.toLowerCase(), () => gedung);
      }
    }
    final sorted = uniqueMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [_allBuildingsLabel, ...sorted];
  }

  static List<String> _buildRoomOptions(
    List<ReportModel> reports, {
    required String effectiveBuilding,
  }) {
    final Map<String, String> uniqueMap = {};
    bool hasNoRoom = false;

    for (final report in reports) {
      final loc = _parseLocation(report.assetLokasi);
      final matchesBuilding = effectiveBuilding == _allBuildingsLabel ||
          loc.gedung.toLowerCase() == effectiveBuilding.toLowerCase();
      if (!matchesBuilding) continue;

      if (loc.ruangan.isEmpty) {
        hasNoRoom = true;
      } else {
        uniqueMap.putIfAbsent(loc.ruangan.toLowerCase(), () => loc.ruangan);
      }
    }

    final sorted = uniqueMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [
      _allRoomsLabel,
      if (hasNoRoom) _noRoomLabel,
      ...sorted,
    ];
  }

  static List<String> get _priorityOptions => [
        _allPrioritiesLabel,
        ReportPriority.tinggi.label,
        ReportPriority.sedang.label,
        ReportPriority.rendah.label,
        _noPriorityLabel,
      ];

  int _activeModalFilterCount({
    required String effectiveBuilding,
    required String effectiveRoom,
  }) {
    int count = 0;
    if (effectiveBuilding != _allBuildingsLabel) count++;
    if (effectiveRoom != _allRoomsLabel) count++;
    if (_selectedPriority != _allPrioritiesLabel) count++;
    return count;
  }

  bool _hasActiveFilter({
    required String effectiveBuilding,
    required String effectiveRoom,
  }) {
    return _searchController.text.trim().isNotEmpty ||
        _selectedStatusFilter != _allStatusKey ||
        _activeModalFilterCount(
              effectiveBuilding: effectiveBuilding,
              effectiveRoom: effectiveRoom,
            ) >
            0;
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedStatusFilter = _allStatusKey;
      _selectedBuilding = _allBuildingsLabel;
      _selectedRoom = _allRoomsLabel;
      _selectedPriority = _allPrioritiesLabel;
    });
  }

  List<ReportModel> _filterReports(
    List<ReportModel> reports, {
    required String effectiveBuilding,
    required String effectiveRoom,
  }) {
    final query = _searchController.text.trim().toLowerCase();

    return reports.where((report) {
      final matchesSearch = query.isEmpty ||
          report.assetNama.toLowerCase().contains(query) ||
          report.assetLokasi.toLowerCase().contains(query) ||
          report.deskripsi.toLowerCase().contains(query) ||
          report.pelaporNama.toLowerCase().contains(query) ||
          (report.teknisiNama?.toLowerCase().contains(query) ?? false);

      final matchesStatus = switch (_selectedStatusFilter) {
        _allStatusKey => true,
        _overdueStatusKey => report.isOverdue,
        _unregisteredStatusKey => !report.hasRegisteredAsset,
        _ => report.status.value == _selectedStatusFilter,
      };

      final loc = _parseLocation(report.assetLokasi);
      final matchesBuilding = effectiveBuilding == _allBuildingsLabel ||
          loc.gedung.toLowerCase() == effectiveBuilding.toLowerCase();

      final matchesRoom = switch (effectiveRoom) {
        _allRoomsLabel => true,
        _noRoomLabel => loc.ruangan.isEmpty,
        _ => loc.ruangan.toLowerCase() == effectiveRoom.toLowerCase(),
      };

      final matchesPriority = switch (_selectedPriority) {
        _allPrioritiesLabel => true,
        _noPriorityLabel => report.prioritas == null,
        _ => report.prioritas?.label == _selectedPriority,
      };

      return matchesSearch &&
          matchesStatus &&
          matchesBuilding &&
          matchesRoom &&
          matchesPriority;
    }).toList();
  }

  Future<void> _openFilterModal({
    required List<ReportModel> allReports,
    required String effectiveBuilding,
    required String effectiveRoom,
  }) async {
    final result = await showModalBottomSheet<_ReportFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportFilterBottomSheet(
        allReports: allReports,
        initialBuilding: effectiveBuilding,
        initialRoom: effectiveRoom,
        initialPriority: _selectedPriority,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedBuilding = result.building;
      _selectedRoom = result.room;
      _selectedPriority = result.priority;
    });
  }

  void _openReportDetail(ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailLaporanScreen(
          reportId: report.id,
          initialReport: report,
          userRole: UserRole.admin,
        ),
      ),
    );
  }

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
          automaticallyImplyLeading: false,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            'Kelola Laporan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: StreamBuilder<List<ReportModel>>(
            stream: _reportsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Gagal memuat daftar laporan: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.statusRejectedText,
                      ),
                    ),
                  ),
                );
              }

              final allReports = snapshot.data ?? const <ReportModel>[];
              final buildingOptions = _buildBuildingOptions(allReports);
              final effectiveBuilding =
                  buildingOptions.contains(_selectedBuilding)
                      ? _selectedBuilding
                      : _allBuildingsLabel;

              final roomOptions = _buildRoomOptions(
                allReports,
                effectiveBuilding: effectiveBuilding,
              );
              final effectiveRoom = roomOptions.contains(_selectedRoom)
                  ? _selectedRoom
                  : _allRoomsLabel;

              final modalFilterCount = _activeModalFilterCount(
                effectiveBuilding: effectiveBuilding,
                effectiveRoom: effectiveRoom,
              );
              final isFiltering = _hasActiveFilter(
                effectiveBuilding: effectiveBuilding,
                effectiveRoom: effectiveRoom,
              );
              final filteredReports = _filterReports(
                allReports,
                effectiveBuilding: effectiveBuilding,
                effectiveRoom: effectiveRoom,
              );

              return Column(
                children: [
                  // Baris 1: Search + Tombol Modal Filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchField()),
                        const SizedBox(width: 10),
                        _buildFilterButton(
                          activeCount: modalFilterCount,
                          onTap: () => _openFilterModal(
                            allReports: allReports,
                            effectiveBuilding: effectiveBuilding,
                            effectiveRoom: effectiveRoom,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Baris 2: Chip Status Horizontal
                  _buildStatusFilterChips(allReports),

                  // Ringkasan filter modal aktif (bisa dihapus langsung dengan 1 tap)
                  if (modalFilterCount > 0) ...[
                    const SizedBox(height: 10),
                    _buildActiveModalFilterBar(
                      effectiveBuilding: effectiveBuilding,
                      effectiveRoom: effectiveRoom,
                    ),
                  ],

                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildReportCount(
                      filteredCount: filteredReports.length,
                      totalCount: allReports.length,
                      isFiltering: isFiltering,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Daftar Laporan
                  Expanded(
                    child: filteredReports.isEmpty
                        ? _buildEmptyState(isFiltering: isFiltering)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              2,
                              20,
                              widget.showBackButton ? 28 : 115,
                            ),
                            itemCount: filteredReports.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return ReportCard(
                                report: report,
                                onTap: () => _openReportDetail(report),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Cari aset, lokasi, atau teknisi...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
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
          vertical: 12.5,
          horizontal: 14,
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

  Widget _buildFilterButton({
    required int activeCount,
    required VoidCallback onTap,
  }) {
    final isActive = activeCount > 0;

    return Tooltip(
      message: 'Filter Lokasi & Prioritas',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue : AppColors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.tune_rounded,
                size: 21,
                color: isActive ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            if (isActive)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$activeCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveModalFilterBar({
    required String effectiveBuilding,
    required String effectiveRoom,
  }) {
    final pills = <({String label, VoidCallback onRemove})>[
      if (effectiveBuilding != _allBuildingsLabel)
        (
          label: effectiveBuilding,
          onRemove: () => setState(() {
                _selectedBuilding = _allBuildingsLabel;
                _selectedRoom = _allRoomsLabel;
              }),
        ),
      if (effectiveRoom != _allRoomsLabel)
        (
          label: effectiveRoom,
          onRemove: () => setState(() => _selectedRoom = _allRoomsLabel),
        ),
      if (_selectedPriority != _allPrioritiesLabel)
        (
          label: 'Prioritas: $_selectedPriority',
          onRemove: () =>
              setState(() => _selectedPriority = _allPrioritiesLabel),
        ),
    ];

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final pill = pills[index];
          return InkWell(
            onTap: pill.onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pill.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilterChips(List<ReportModel> allReports) {
    final overdueCount = allReports.where((r) => r.isOverdue).length;
    final unregisteredCount =
        allReports.where((r) => !r.hasRegisteredAsset).length;

    final chips = <({String key, String label, bool isAlert})>[
      (
        key: _allStatusKey,
        label: 'Semua (${allReports.length})',
        isAlert: false,
      ),
      if (overdueCount > 0 || _selectedStatusFilter == _overdueStatusKey)
        (
          key: _overdueStatusKey,
          label: 'Overdue ($overdueCount)',
          isAlert: true,
        ),
      ...ReportStatus.values.map((status) {
        final count = allReports.where((r) => r.status == status).length;
        return (
          key: status.value,
          label: '${status.label} ($count)',
          isAlert: false,
        );
      }),
      if (unregisteredCount > 0 ||
          _selectedStatusFilter == _unregisteredStatusKey)
        (
          key: _unregisteredStatusKey,
          label: 'Belum Terdaftar ($unregisteredCount)',
          isAlert: false,
        ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedStatusFilter == chip.key;
          final activeColor = chip.isAlert
              ? AppColors.statusRejectedText
              : AppColors.primaryBlue;

          return InkWell(
            onTap: () => setState(() => _selectedStatusFilter = chip.key),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : chip.isAlert
                        ? AppColors.statusRejectedBg
                        : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : chip.isAlert
                          ? AppColors.statusRejectedText.withValues(alpha: 0.35)
                          : AppColors.border,
                ),
              ),
              child: Text(
                chip.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.white
                      : chip.isAlert
                          ? AppColors.statusRejectedText
                          : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCount({
    required int filteredCount,
    required int totalCount,
    required bool isFiltering,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Total Laporan: ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              isFiltering && totalCount > 0
                  ? '$filteredCount dari $totalCount'
                  : '$filteredCount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (isFiltering)
          GestureDetector(
            onTap: _resetAllFilters,
            child: Text(
              'Reset Semua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isFiltering}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          26,
          26,
          26,
          widget.showBackButton ? 26 : 115,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE3EEFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltering
                    ? Icons.filter_alt_off_outlined
                    : Icons.assignment_outlined,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? 'Laporan Tidak Ditemukan'
                  : 'Belum Ada Laporan Masuk',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? 'Tidak ada laporan yang sesuai dengan pencarian atau filter lokasi, prioritas, dan status saat ini.'
                  : 'Seluruh laporan kerusakan fasilitas kampus dari pelapor akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _resetAllFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  'Reset Semua Filter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MODAL BOTTOM SHEET: FILTER LOKASI & PRIORITAS
// ============================================================

class _ReportFilterSelection {
  final String building;
  final String room;
  final String priority;

  const _ReportFilterSelection({
    required this.building,
    required this.room,
    required this.priority,
  });
}

class _ReportFilterBottomSheet extends StatefulWidget {
  final List<ReportModel> allReports;
  final String initialBuilding;
  final String initialRoom;
  final String initialPriority;

  const _ReportFilterBottomSheet({
    required this.allReports,
    required this.initialBuilding,
    required this.initialRoom,
    required this.initialPriority,
  });

  @override
  State<_ReportFilterBottomSheet> createState() =>
      _ReportFilterBottomSheetState();
}

class _ReportFilterBottomSheetState extends State<_ReportFilterBottomSheet> {
  late String _building;
  late String _room;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _building = widget.initialBuilding;
    _room = widget.initialRoom;
    _priority = widget.initialPriority;
  }

  void _resetLocal() {
    setState(() {
      _building = _KelolaLaporanScreenState._allBuildingsLabel;
      _room = _KelolaLaporanScreenState._allRoomsLabel;
      _priority = _KelolaLaporanScreenState._allPrioritiesLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buildingOptions =
        _KelolaLaporanScreenState._buildBuildingOptions(widget.allReports);
    final effectiveBuilding = buildingOptions.contains(_building)
        ? _building
        : _KelolaLaporanScreenState._allBuildingsLabel;

    final roomOptions = _KelolaLaporanScreenState._buildRoomOptions(
      widget.allReports,
      effectiveBuilding: effectiveBuilding,
    );
    final effectiveRoom = roomOptions.contains(_room)
        ? _room
        : _KelolaLaporanScreenState._allRoomsLabel;

    final priorityOptions = _KelolaLaporanScreenState._priorityOptions;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Laporan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
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
              const SizedBox(height: 8),

              // Gedung
              _sectionLabel('Gedung'),
              const SizedBox(height: 8),
              _buildModalDropdown(
                value: effectiveBuilding,
                items: buildingOptions,
                prefixIcon: Icons.apartment_rounded,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _building = value;
                    _room = _KelolaLaporanScreenState._allRoomsLabel;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Ruangan
              _sectionLabel('Ruangan'),
              const SizedBox(height: 8),
              _buildModalDropdown(
                value: effectiveRoom,
                items: roomOptions,
                prefixIcon: Icons.meeting_room_outlined,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _room = value);
                },
              ),
              const SizedBox(height: 16),

              // Prioritas (Chip tap langsung)
              _sectionLabel('Prioritas'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: priorityOptions.map((option) {
                  final isSelected = _priority == option;
                  return InkWell(
                    onTap: () => setState(() => _priority = option),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : const Color(0xFFF7F9FD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Tombol Aksi Modal
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetLocal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _ReportFilterSelection(
                            building: effectiveBuilding,
                            room: effectiveRoom,
                            priority: _priority,
                          ),
                        );
                      },
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
                        'Terapkan Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
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
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModalDropdown({
    required String value,
    required List<String> items,
    required IconData prefixIcon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
