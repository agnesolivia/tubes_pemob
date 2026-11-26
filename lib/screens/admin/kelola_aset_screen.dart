import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/asset_model.dart';
import 'package:tubes_pemob/screens/admin/detail_aset_screen.dart';
import 'package:tubes_pemob/screens/admin/tambah_aset_screen.dart';
import 'package:tubes_pemob/services/asset_service.dart';

IconData getAssetCategoryIcon(String category) {
  switch (category.trim().toLowerCase()) {
    case 'elektronik':
      return Icons.devices_other_rounded;
    case 'inventaris':
      return Icons.chair_alt_rounded;
    case 'sanitasi':
      return Icons.plumbing_rounded;
    case 'kelistrikan':
      return Icons.electrical_services_rounded;
    default:
      return Icons.inventory_2_outlined;
  }
}

class KelolaAsetScreen extends StatefulWidget {
  const KelolaAsetScreen({super.key});

  @override
  State<KelolaAsetScreen> createState() => _KelolaAsetScreenState();
}

class _KelolaAsetScreenState extends State<KelolaAsetScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedBuilding = 'Semua Gedung';
  String _selectedRoom = 'Semua Ruangan';
  String _selectedCategory = 'Semua Kategori';

  static const String _noRoomFilterLabel = 'Tanpa Ruangan';

  static const List<String> _defaultCategories = [
    'Elektronik',
    'Inventaris',
    'Sanitasi',
    'Kelistrikan',
    'Lainnya',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _buildCategoryOptions(List<AssetModel> assets) {
    final Map<String, String> uniqueMap = {
      for (final cat in _defaultCategories) cat.toLowerCase(): cat,
    };

    for (final asset in assets) {
      final clean = asset.kategori.trim();
      if (clean.isNotEmpty) {
        uniqueMap.putIfAbsent(clean.toLowerCase(), () => clean);
      }
    }

    return ['Semua Kategori', ...uniqueMap.values];
  }

  List<String> _buildBuildingOptions(List<AssetModel> assets) {
    final uniqueGedung = AssetService.instance.extractUniqueGedung(assets);
    return ['Semua Gedung', ...uniqueGedung];
  }

  List<String> _buildRoomOptions(
    List<AssetModel> assets,
    String effectiveBuilding,
  ) {
    if (effectiveBuilding != 'Semua Gedung') {
      final rooms = AssetService.instance.extractUniqueRuangan(
        assets,
        effectiveBuilding,
      );
      final hasNoRoom = assets.any(
        (asset) =>
            asset.gedung.trim().toLowerCase() ==
                effectiveBuilding.trim().toLowerCase() &&
            !asset.hasRuangan,
      );
      return [
        'Semua Ruangan',
        if (hasNoRoom) _noRoomFilterLabel,
        ...rooms,
      ];
    }

    final Map<String, String> allRoomsMap = {};
    bool hasAnyNoRoom = false;

    for (final asset in assets) {
      if (!asset.hasRuangan) {
        hasAnyNoRoom = true;
        continue;
      }
      final clean = asset.ruangan.trim();
      allRoomsMap.putIfAbsent(clean.toLowerCase(), () => clean);
    }

    final sorted = allRoomsMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [
      'Semua Ruangan',
      if (hasAnyNoRoom) _noRoomFilterLabel,
      ...sorted,
    ];
  }

  bool _hasActiveFilter({
    required String effectiveBuilding,
    required String effectiveRoom,
    required String effectiveCategory,
  }) {
    return _searchController.text.trim().isNotEmpty ||
        effectiveBuilding != 'Semua Gedung' ||
        effectiveRoom != 'Semua Ruangan' ||
        effectiveCategory != 'Semua Kategori';
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedBuilding = 'Semua Gedung';
      _selectedRoom = 'Semua Ruangan';
      _selectedCategory = 'Semua Kategori';
    });
  }

  List<AssetModel> _filterAssets(
    List<AssetModel> assets, {
    required String effectiveBuilding,
    required String effectiveRoom,
    required String effectiveCategory,
  }) {
    final query = _searchController.text.trim().toLowerCase();

    return assets.where((asset) {
      final matchesSearch = query.isEmpty ||
          asset.nama.toLowerCase().contains(query) ||
          asset.gedung.toLowerCase().contains(query) ||
          asset.ruangan.toLowerCase().contains(query) ||
          asset.id.toLowerCase().contains(query);

      final matchesBuilding = effectiveBuilding == 'Semua Gedung' ||
          asset.gedung.trim().toLowerCase() ==
              effectiveBuilding.trim().toLowerCase();

      final matchesRoom = effectiveRoom == 'Semua Ruangan' ||
          (effectiveRoom == _noRoomFilterLabel
              ? !asset.hasRuangan
              : asset.ruangan.trim().toLowerCase() ==
                  effectiveRoom.trim().toLowerCase());

      final matchesCategory = effectiveCategory == 'Semua Kategori' ||
          asset.kategori.trim().toLowerCase() ==
              effectiveCategory.trim().toLowerCase();

      return matchesSearch &&
          matchesBuilding &&
          matchesRoom &&
          matchesCategory;
    }).toList();
  }

  void _openTambahAset() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahAsetScreen()),
    );
  }

  void _openDetailAset(AssetModel asset, {bool scrollToQr = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailAsetScreen(
          asset: asset,
          scrollToQr: scrollToQr,
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
          title: Text(
            'Kelola Aset & QR',
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
              onPressed: _openTambahAset,
              tooltip: 'Tambah Aset',
              icon: const Icon(Icons.add_rounded, size: 28),
            ),
            const SizedBox(width: 6),
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
            child: StreamBuilder<List<AssetModel>>(
              stream: AssetService.instance.streamAllAssets(),
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
                        'Gagal memuat data aset: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.statusRejectedText,
                        ),
                      ),
                    ),
                  );
                }

                final allAssets = snapshot.data ?? [];

                final buildingOptions = _buildBuildingOptions(allAssets);
                final effectiveBuilding =
                    buildingOptions.contains(_selectedBuilding)
                        ? _selectedBuilding
                        : 'Semua Gedung';

                final roomOptions = _buildRoomOptions(
                  allAssets,
                  effectiveBuilding,
                );
                final effectiveRoom = roomOptions.contains(_selectedRoom)
                    ? _selectedRoom
                    : 'Semua Ruangan';

                final categoryOptions = _buildCategoryOptions(allAssets);
                final effectiveCategory =
                    categoryOptions.contains(_selectedCategory)
                        ? _selectedCategory
                        : 'Semua Kategori';

                final isFiltering = _hasActiveFilter(
                  effectiveBuilding: effectiveBuilding,
                  effectiveRoom: effectiveRoom,
                  effectiveCategory: effectiveCategory,
                );

                final filteredAssets = _filterAssets(
                  allAssets,
                  effectiveBuilding: effectiveBuilding,
                  effectiveRoom: effectiveRoom,
                  effectiveCategory: effectiveCategory,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          _buildFilterSection(
                            buildingOptions: buildingOptions,
                            effectiveBuilding: effectiveBuilding,
                            roomOptions: roomOptions,
                            effectiveRoom: effectiveRoom,
                            categoryOptions: categoryOptions,
                            effectiveCategory: effectiveCategory,
                            isFiltering: isFiltering,
                          ),
                          const SizedBox(height: 16),
                          _buildAssetCount(
                            filteredCount: filteredAssets.length,
                            totalCount: allAssets.length,
                            isFiltering: isFiltering,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredAssets.isEmpty
                          ? _buildEmptyState(isFiltering: isFiltering)
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                4,
                                20,
                                26,
                              ),
                              itemCount: filteredAssets.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 11),
                              itemBuilder: (context, index) {
                                final asset = filteredAssets[index];
                                return _AssetListTile(
                                  asset: asset,
                                  onTap: () => _openDetailAset(asset),
                                  onQrTap: () => _openDetailAset(
                                    asset,
                                    scrollToQr: true,
                                  ),
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
        hintText: 'Cari nama aset, gedung, atau ruangan...',
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

  Widget _buildFilterSection({
    required List<String> buildingOptions,
    required String effectiveBuilding,
    required List<String> roomOptions,
    required String effectiveRoom,
    required List<String> categoryOptions,
    required String effectiveCategory,
    required bool isFiltering,
  }) {
    return Column(
      children: [
        // Baris 1: Lokasi (Gedung & Ruangan)
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                value: effectiveBuilding,
                items: buildingOptions,
                prefixIcon: Icons.apartment_rounded,
                isActive: effectiveBuilding != 'Semua Gedung',
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedBuilding = value;
                    _selectedRoom = 'Semua Ruangan';
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFilterDropdown(
                value: effectiveRoom,
                items: roomOptions,
                prefixIcon: Icons.meeting_room_outlined,
                isActive: effectiveRoom != 'Semua Ruangan',
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedRoom = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Baris 2: Kategori + Tombol Reset
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                value: effectiveCategory,
                items: categoryOptions,
                prefixIcon: Icons.category_outlined,
                isActive: effectiveCategory != 'Semua Kategori',
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
              ),
            ),
            if (isFiltering) ...[
              const SizedBox(width: 10),
              InkWell(
                onTap: _resetAllFilters,
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restart_alt_rounded,
                        size: 17,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildAssetCount({
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
              'Total Aset: ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              isFiltering && totalCount > 0
                  ? '$filteredCount dari $totalCount'
                  : '$filteredCount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (isFiltering)
          Text(
            'Filter aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isFiltering}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFE3EEFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltering
                    ? Icons.filter_alt_off_outlined
                    : Icons.inventory_2_outlined,
                size: 38,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFiltering
                  ? 'Aset tidak ditemukan'
                  : 'Belum Ada Aset Terdaftar',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? 'Tidak ada aset yang cocok dengan pencarian atau filter gedung, ruangan, dan kategori saat ini.'
                  : 'Tambahkan master data fasilitas kampus untuk mulai mengelola aset dan mencetak stiker QR.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (isFiltering)
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
              )
            else
              ElevatedButton.icon(
                onPressed: _openTambahAset,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Tambah Aset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetListTile extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;
  final VoidCallback onQrTap;

  const _AssetListTile({
    required this.asset,
    required this.onTap,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEF6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Kategori
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.statusDoneBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  getAssetCategoryIcon(asset.kategori),
                  color: AppColors.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // Nama Aset, Kategori, & Lokasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.5,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusDoneBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        asset.kategori,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      asset.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            asset.lokasiLengkap,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
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
              const SizedBox(width: 10),

              // Tombol Pintasan QR
              Tooltip(
                message: 'Lihat QR Aset',
                child: InkWell(
                  onTap: onQrTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
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
}