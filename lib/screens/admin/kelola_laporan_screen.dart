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
  /// Tampilkan tombol kembali jika dibuka lewat `Navigator.push`
  /// (biarkan `false` saat dipakai sebagai tab di `AdminMainScreen`).
  final bool showBackButton;

  const KelolaLaporanScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<KelolaLaporanScreen> createState() => _KelolaLaporanScreenState();
}

class _KelolaLaporanScreenState extends State<KelolaLaporanScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<ReportModel>> _reportsStream;

  static const String _allStatusKey = 'semua';
  static const String _overdueStatusKey = 'overdue';
  static const String _unregisteredStatusKey = 'unregistered';

  static const String _allBuildingsLabel = 'Semua Gedung';
  static const String _allPrioritiesLabel = 'Semua Prioritas';
  static const String _noPriorityLabel = 'Belum Ditetapkan';

  String _selectedStatusFilter = _allStatusKey;
  String _selectedBuilding = _allBuildingsLabel;
  String _selectedPriority = _allPrioritiesLabel;

  @override
  void initState() {
    super.initState();
    _reportsStream = ReportService.instance.streamAllReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _extractBuilding(String assetLokasi) {
    final trimmed = assetLokasi.trim();
    if (trimmed.isEmpty) return '';
    final separatorIndex = trimmed.indexOf(' - ');
    return separatorIndex != -1
        ? trimmed.substring(0, separatorIndex).trim()
        : trimmed;
  }

  List<String> _buildBuildingOptions(List<ReportModel> reports) {
    final Map<String, String> uniqueMap = {};
    for (final report in reports) {
      final gedung = _extractBuilding(report.assetLokasi);
      if (gedung.isNotEmpty) {
        uniqueMap.putIfAbsent(gedung.toLowerCase(), () => gedung);
      }
    }
    final sorted = uniqueMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [_allBuildingsLabel, ...sorted];
  }

  List<String> get _priorityOptions => [
        _allPrioritiesLabel,
        ReportPriority.tinggi.label,
        ReportPriority.sedang.label,
        ReportPriority.rendah.label,
        _noPriorityLabel,
      ];

  bool _hasActiveFilter(String effectiveBuilding) {
    return _searchController.text.trim().isNotEmpty ||
        _selectedStatusFilter != _allStatusKey ||
        effectiveBuilding != _allBuildingsLabel ||
        _selectedPriority != _allPrioritiesLabel;
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedStatusFilter = _allStatusKey;
      _selectedBuilding = _allBuildingsLabel;
      _selectedPriority = _allPrioritiesLabel;
    });
  }

  List<ReportModel> _filterReports(
    List<ReportModel> reports, {
    required String effectiveBuilding,
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

      final reportBuilding = _extractBuilding(report.assetLokasi);
      final matchesBuilding = effectiveBuilding == _allBuildingsLabel ||
          reportBuilding.toLowerCase() == effectiveBuilding.toLowerCase();

      final matchesPriority = switch (_selectedPriority) {
        _allPrioritiesLabel => true,
        _noPriorityLabel => report.prioritas == null,
        _ => report.prioritas?.label == _selectedPriority,
      };

      return matchesSearch &&
          matchesStatus &&
          matchesBuilding &&
          matchesPriority;
    }).toList();
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

              final isFiltering = _hasActiveFilter(effectiveBuilding);
              final filteredReports = _filterReports(
                allReports,
                effectiveBuilding: effectiveBuilding,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildDropdownFilters(
                          buildingOptions: buildingOptions,
                          effectiveBuilding: effectiveBuilding,
                          isFiltering: isFiltering,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusFilterChips(allReports),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildReportCount(
                      filteredCount: filteredReports.length,
                      totalCount: allReports.length,
                      isFiltering: isFiltering,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredReports.isEmpty
                        ? _buildEmptyState(isFiltering: isFiltering)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              4,
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
        hintText: 'Cari aset, gedung, pelapor, atau teknisi...',
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
          vertical: 13,
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

  Widget _buildDropdownFilters({
    required List<String> buildingOptions,
    required String effectiveBuilding,
    required bool isFiltering,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            value: effectiveBuilding,
            items: buildingOptions,
            prefixIcon: Icons.apartment_rounded,
            isActive: effectiveBuilding != _allBuildingsLabel,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedBuilding = value);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedPriority,
            items: _priorityOptions,
            prefixIcon: Icons.flag_outlined,
            isActive: _selectedPriority != _allPrioritiesLabel,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedPriority = value);
            },
          ),
        ),
        if (isFiltering) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Reset Filter',
            child: InkWell(
              onTap: _resetAllFilters,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restart_alt_rounded,
                  size: 19,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required IconData prefixIcon,
    required bool isActive,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF3F8FF) : AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            prefixIcon,
            size: 16,
            color: isActive ? AppColors.primaryBlue : AppColors.textSecondary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                  size: 19,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary,
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

  Widget _buildStatusFilterChips(List<ReportModel> allReports) {
    final overdueCount = allReports.where((r) => r.isOverdue).length;
    final unregisteredCount =
        allReports.where((r) => !r.hasRegisteredAsset).length;

    final chips = <({String key, String label, bool isAlert})>[
      (key: _allStatusKey, label: 'Semua (${allReports.length})', isAlert: false),
      if (overdueCount > 0)
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
      if (unregisteredCount > 0)
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
              'Reset Filter',
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
                  ? 'Tidak ada laporan yang sesuai dengan pencarian atau filter status, gedung, dan prioritas saat ini.'
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
