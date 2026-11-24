import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import 'package:tubes_pemob/constants/app_colors.dart';

// ============================================================
// MODEL ASSET
// ============================================================

class AssetItem {
  final String id;
  final String name;
  final String category;
  final String building;
  final String room;

  const AssetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.building,
    required this.room,
  });

  // ICON BERDASARKAN KATEGORI
  IconData get icon {
    switch (category) {
      case 'Elektronik':
        return Icons.ac_unit_rounded;

      case 'Inventaris':
        return Icons.chair_alt_rounded;

      case 'Sanitasi':
        return Icons.plumbing_rounded;

      case 'Kelistrikan':
        return Icons.electrical_services_rounded;

      default:
        return Icons.inventory_2_outlined;
    }
  }
}

// ============================================================
// KELOLA ASET SCREEN
// ============================================================

class KelolaAsetScreen extends StatefulWidget {
  const KelolaAsetScreen({super.key});

  @override
  State<KelolaAsetScreen> createState() =>
      _KelolaAsetScreenState();
}

class _KelolaAsetScreenState extends State<KelolaAsetScreen> {
  // SEARCH CONTROLLER
  final TextEditingController _searchController =
      TextEditingController();

  // DATA ASET
  // Tidak menggunakan data dummy.
  final List<AssetItem> _assets = [];

  // FILTER
  String _selectedCategory = 'Semua Kategori';
  String _selectedBuilding = 'Semua Gedung';

  // PILIHAN KATEGORI
  final List<String> _categories = [
    'Semua Kategori',
    'Elektronik',
    'Inventaris',
    'Sanitasi',
    'Kelistrikan',
    'Lainnya',
  ];

  // PILIHAN GEDUNG
  final List<String> _buildings = [
    'Semua Gedung',
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // FILTER ASSET
  // ==========================================================

  List<AssetItem> get _filteredAssets {
    final query = _searchController.text.toLowerCase();

    return _assets.where((asset) {
      final matchesSearch =
          asset.id.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'Semua Kategori' ||
          asset.category == _selectedCategory;

      final matchesBuilding =
          _selectedBuilding == 'Semua Gedung' ||
          asset.building == _selectedBuilding;

      return matchesSearch &&
          matchesCategory &&
          matchesBuilding;
    }).toList();
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

        // APP BAR
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
              onPressed: () => _openAssetForm(),
              icon: const Icon(
                Icons.add_rounded,
                size: 29,
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
                // SEARCH DAN FILTER
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    0,
                  ),
                  child: Column(
                    children: [
                      _buildSearchField(),

                      const SizedBox(height: 14),

                      _buildFilterSection(),

                      const SizedBox(height: 20),

                      _buildAssetCount(),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // DAFTAR ASET
                Expanded(
                  child: _buildAssetList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SEARCH FIELD
  // ==========================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),

      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppColors.textPrimary,
      ),

      decoration: InputDecoration(
        hintText: 'Cari ID aset, nama aset...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
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
                icon: const Icon(Icons.close_rounded),
              )
            : null,

        filled: true,
        fillColor: AppColors.white,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER SECTION
  // ==========================================================

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildFilterDropdown(
            value: _selectedBuilding,
            items: _buildings,
            onChanged: (value) {
              setState(() {
                _selectedBuilding = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),

          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),

          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  // ==========================================================
  // ASSET COUNT
  // ==========================================================

  Widget _buildAssetCount() {
    return Row(
      children: [
        Text(
          'Total Aset: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),

        Text(
          '${_filteredAssets.length}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ASSET LIST
  // ==========================================================

  Widget _buildAssetList() {
    final assets = _filteredAssets;

    if (assets.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        20,
        5,
        20,
        25,
      ),

      itemCount: assets.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },

      itemBuilder: (context, index) {
        final asset = assets[index];

        return _AssetCard(
          asset: asset,

          onQrPressed: () {
            _openQrScreen(asset);
          },

          onEditPressed: () {
            _openAssetForm(asset: asset);
          },

          onDeletePressed: () {
            _confirmDeleteAsset(asset);
          },
        );
      },
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty ||
        _selectedCategory != 'Semua Kategori' ||
        _selectedBuilding != 'Semua Gedung';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: const BoxDecoration(
                color: Color(0xFFE3EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              isSearching
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
              isSearching
                  ? 'Coba ubah kata pencarian atau filter.'
                  : 'Tambahkan master data fasilitas kampus untuk mulai mengelola aset.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            if (!isSearching)
              ElevatedButton.icon(
                onPressed: () => _openAssetForm(),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Tambah Aset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
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
        ),
      ),
    );
  }

  // ==========================================================
  // ADD / EDIT ASSET
  // ==========================================================

  Future<void> _openAssetForm({
    AssetItem? asset,
  }) async {
    final result = await showModalBottomSheet<AssetItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return _AssetFormSheet(
          asset: asset,
        );
      },
    );

    if (result == null || !mounted) return;

    // CEK ID DUPLIKAT
    final isDuplicate = _assets.any(
      (item) =>
          item.id.toLowerCase() == result.id.toLowerCase() &&
          item.id != asset?.id,
    );

    if (isDuplicate) {
      _showMessage(
        'ID aset sudah digunakan.',
        isError: true,
      );
      return;
    }

    setState(() {
      if (asset == null) {
        _assets.add(result);
      } else {
        final index = _assets.indexWhere(
          (item) => item.id == asset.id,
        );

        if (index != -1) {
          _assets[index] = result;
        }
      }
    });

    _showMessage(
      asset == null
          ? 'Aset berhasil ditambahkan.'
          : 'Aset berhasil diperbarui.',
    );
  }

  // ==========================================================
  // DELETE ASSET
  // ==========================================================

  Future<void> _confirmDeleteAsset(
    AssetItem asset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            'Hapus Aset?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          content: Text(
            'Apakah kamu yakin ingin menghapus ${asset.name} (${asset.id})?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusRejectedText,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _assets.removeWhere(
        (item) => item.id == asset.id,
      );
    });

    _showMessage('Aset berhasil dihapus.');
  }

  // ==========================================================
  // OPEN QR SCREEN
  // ==========================================================

  void _openQrScreen(AssetItem asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return QRAssetScreen(
            asset: asset,
          );
        },
      ),
    );
  }

  // ==========================================================
  // SNACKBAR
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
        ),
      );
  }
}

// ============================================================
// ASSET CARD
// ============================================================

class _AssetCard extends StatelessWidget {
  final AssetItem asset;
  final VoidCallback onQrPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const _AssetCard({
    required this.asset,
    required this.onQrPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ICON ASSET
          Container(
            width: 75,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.statusDoneBg,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Icon(
              asset.icon,
              color: AppColors.primaryBlue,
              size: 38,
            ),
          ),

          const SizedBox(width: 12),

          // INFORMASI ASET
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusDoneBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    asset.id,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  asset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                _assetInformation(
                  Icons.folder_outlined,
                  asset.category,
                ),

                const SizedBox(height: 4),

                _assetInformation(
                  Icons.apartment_rounded,
                  asset.building,
                ),

                const SizedBox(height: 4),

                _assetInformation(
                  Icons.location_on_outlined,
                  asset.room,
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          // ACTION BUTTONS
          Column(
            children: [
              _AssetActionButton(
                icon: Icons.qr_code_scanner_rounded,
                color: AppColors.primaryBlue,
                onTap: onQrPressed,
              ),

              const SizedBox(height: 6),

              _AssetActionButton(
                icon: Icons.edit_outlined,
                color: AppColors.primaryBlue,
                onTap: onEditPressed,
              ),

              const SizedBox(height: 6),

              _AssetActionButton(
                icon: Icons.delete_outline_rounded,
                color: AppColors.statusRejectedText,
                onTap: onDeletePressed,
                isDanger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assetInformation(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.textSecondary,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            text,
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
    );
  }
}

// ============================================================
// ASSET ACTION BUTTON
// ============================================================

class _AssetActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;

  const _AssetActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 43,
        height: 42,
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFFFF5F5)
              : AppColors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isDanger
                ? const Color(0xFFFFCDD2)
                : const Color(0xFFDCE5F1),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
    );
  }
}

// ============================================================
// ASSET FORM SHEET
// ============================================================

class _AssetFormSheet extends StatefulWidget {
  final AssetItem? asset;

  const _AssetFormSheet({
    this.asset,
  });

  @override
  State<_AssetFormSheet> createState() =>
      _AssetFormSheetState();
}

class _AssetFormSheetState extends State<_AssetFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _roomController;

  String? _selectedCategory;
  String? _selectedBuilding;

  final List<String> _categories = [
    'Elektronik',
    'Inventaris',
    'Sanitasi',
    'Kelistrikan',
    'Lainnya',
  ];

  final List<String> _buildings = [
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
  ];

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();

    _idController = TextEditingController(
      text: widget.asset?.id ?? '',
    );

    _nameController = TextEditingController(
      text: widget.asset?.name ?? '',
    );

    _roomController = TextEditingController(
      text: widget.asset?.room ?? '',
    );

    _selectedCategory = widget.asset?.category;
    _selectedBuilding = widget.asset?.building;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),

      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),

        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            25,
          ),

          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HANDLE
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

                const SizedBox(height: 20),

                // TITLE
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Ubah Data Aset'
                            : 'Tambah Aset Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Lengkapi informasi aset fasilitas kampus.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 23),

                // ID ASET
                _fieldLabel('ID Aset'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _idController,
                  enabled: !_isEditing,

                  textCapitalization: TextCapitalization.characters,

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),

                  decoration: _inputDecoration(
                    hint: 'Contoh: AST-001',
                    icon: Icons.qr_code_rounded,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ID aset wajib diisi.';
                    }

                    if (!RegExp(
                      r'^[A-Za-z0-9_-]+$',
                    ).hasMatch(value.trim())) {
                      return 'Gunakan huruf, angka, - atau _.';
                    }

                    return null;
                  },
                ),

                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      'ID aset tidak dapat diubah agar QR tetap konsisten.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                const SizedBox(height: 17),

                // NAMA ASET
                _fieldLabel('Nama Aset'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),

                  decoration: _inputDecoration(
                    hint: 'Masukkan nama fasilitas',
                    icon: Icons.inventory_2_outlined,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama aset wajib diisi.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 17),

                // KATEGORI
                _fieldLabel('Kategori'),

                const SizedBox(height: 8),

                _buildFormDropdown(
                  value: _selectedCategory,
                  hint: 'Pilih kategori aset',
                  items: _categories,
                  icon: Icons.category_outlined,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 17),

                // GEDUNG
                _fieldLabel('Gedung'),

                const SizedBox(height: 8),

                _buildFormDropdown(
                  value: _selectedBuilding,
                  hint: 'Pilih gedung',
                  items: _buildings,
                  icon: Icons.apartment_rounded,
                  onChanged: (value) {
                    setState(() {
                      _selectedBuilding = value;
                    });
                  },
                ),

                const SizedBox(height: 17),

                // RUANGAN
                _fieldLabel('Ruangan'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _roomController,

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),

                  decoration: _inputDecoration(
                    hint: 'Contoh: Ruang D-204',
                    icon: Icons.location_on_outlined,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ruangan wajib diisi.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // BUTTON SAVE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveAsset,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      _isEditing
                          ? 'Simpan Perubahan'
                          : 'Tambah Aset',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SAVE ASSET
  // ==========================================================

  void _saveAsset() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null ||
        _selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori dan gedung wajib dipilih.'),
        ),
      );
      return;
    }

    final asset = AssetItem(
      id: _idController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      building: _selectedBuilding!,
      room: _roomController.text.trim(),
    );

    Navigator.pop(context, asset);
  }

  // ==========================================================
  // FORM LABEL
  // ==========================================================

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ==========================================================
  // TEXT FIELD DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        color: AppColors.textSecondary,
      ),

      prefixIcon: Icon(
        icon,
        size: 19,
        color: AppColors.textSecondary,
      ),

      filled: true,
      fillColor: const Color(0xFFF7F9FD),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.primaryBlue,
          width: 1.5,
        ),
      ),
    );
  }

  // ==========================================================
  // FORM DROPDOWN
  // ==========================================================

  Widget _buildFormDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,

      isExpanded: true,

      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          size: 19,
          color: AppColors.textSecondary,
        ),

        filled: true,
        fillColor: const Color(0xFFF7F9FD),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),

      hint: Text(
        hint,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),

      onChanged: onChanged,

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilihan wajib diisi.';
        }

        return null;
      },
    );
  }
}

// ============================================================
// QR ASSET SCREEN
// ============================================================

class QRAssetScreen extends StatefulWidget {
  final AssetItem asset;

  const QRAssetScreen({
    super.key,
    required this.asset,
  });

  @override
  State<QRAssetScreen> createState() => _QRAssetScreenState();
}

class _QRAssetScreenState extends State<QRAssetScreen> {
  // KEY UNTUK MENANGKAP GAMBAR QR
  final GlobalKey _qrKey = GlobalKey();

  bool _isProcessing = false;

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
        backgroundColor: AppColors.background,

        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,

          title: Text(
            'QR Aset',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),

        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            25,
          ),

          child: Column(
            children: [
              // INFORMASI ASET
              _buildAssetInformation(),

              const SizedBox(height: 18),

              // QR CODE
              _buildQrContainer(),

              const SizedBox(height: 16),

              // INFORMASI QR
              _buildInformationBox(),
            ],
          ),
        ),

        // BUTTON SAVE DAN SHARE
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  // ==========================================================
  // INFORMASI ASET
  // ==========================================================

  Widget _buildAssetInformation() {
    final asset = widget.asset;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              // ICON
              Container(
                width: 72,
                height: 75,
                decoration: BoxDecoration(
                  color: AppColors.statusDoneBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  asset.icon,
                  color: AppColors.primaryBlue,
                  size: 38,
                ),
              ),

              const SizedBox(width: 14),

              // NAMA ASET
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusDoneBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        asset.id,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      asset.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _assetDetailRow(
            icon: Icons.folder_outlined,
            label: 'Kategori',
            value: asset.category,
          ),

          _divider(),

          _assetDetailRow(
            icon: Icons.apartment_rounded,
            label: 'Gedung',
            value: asset.building,
          ),

          _divider(),

          _assetDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Ruangan',
            value: asset.room,
          ),
        ],
      ),
    );
  }

  Widget _assetDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),

      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF475569),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 95,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      color: AppColors.border,
      height: 1,
    );
  }

  // ==========================================================
  // QR CONTAINER
  // ==========================================================

  Widget _buildQrContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: RepaintBoundary(
        key: _qrKey,

        child: Container(
          width: double.infinity,
          color: AppColors.white,

          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),

          child: Column(
            children: [
              // QR IMAGE
              QrImageView(
                data: widget.asset.id,
                version: QrVersions.auto,
                size: 235,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                semanticsLabel: 'QR Code ${widget.asset.id}',
              ),

              const SizedBox(height: 12),

              // ASSET ID
              Text(
                widget.asset.id,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // QR INFORMATION
  // ==========================================================

  Widget _buildInformationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryBlue,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'QR Code ini berisi ID Aset (${widget.asset.id}) '
              'yang digunakan untuk pelaporan dan identifikasi fasilitas.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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

  // ==========================================================
  // CAPTURE QR IMAGE
  // ==========================================================

  Future<Uint8List> _captureQrImage() async {
    // Tunggu frame selesai dirender
    await WidgetsBinding.instance.endOfFrame;

    final renderObject =
        _qrKey.currentContext?.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('QR Code gagal diproses.');
    }

    // Resolusi tinggi untuk kebutuhan cetak
    final ui.Image image = await renderObject.toImage(
      pixelRatio: 4,
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();

    if (byteData == null) {
      throw Exception('Gagal menghasilkan gambar QR.');
    }

    return byteData.buffer.asUint8List();
  }

  // ==========================================================
  // SHARE QR IMAGE
  // ==========================================================

  Future<void> _shareQrImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await _captureQrImage();

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'QR_${widget.asset.id}.png',
          ),
        ],
        text:
            'QR Code Aset ${widget.asset.name} (${widget.asset.id})',
        subject: 'QR Code Aset ${widget.asset.id}',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Gagal membagikan QR Code.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // SAVE QR IMAGE
  // ==========================================================

  Future<void> _saveQrImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await _captureQrImage();

      await Gal.putImageBytes(bytes);

      if (mounted) {
        _showMessage(
          'QR Code berhasil disimpan ke galeri.',
        );
      }
    } on GalException catch (error) {
      if (mounted) {
        _showMessage(
          error.type.message,
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Gagal menyimpan QR Code.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // BOTTOM ACTION BUTTONS
  // ==========================================================

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),

      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),

      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // BAGIKAN QR
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : _shareQrImage,

                icon: const Icon(
                  Icons.share_rounded,
                  size: 19,
                ),

                label: Text(
                  'Bagikan QR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,

                  side: const BorderSide(
                    color: AppColors.primaryBlue,
                  ),

                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // SIMPAN QR
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : _saveQrImage,

                icon: _isProcessing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        size: 20,
                      ),

                label: Text(
                  'Simpan QR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,

                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

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

  // ==========================================================
  // SNACKBAR
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
              fontSize: 11,
            ),
          ),

          backgroundColor: isError
              ? AppColors.statusRejectedText
              : const Color(0xFF15803D),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}