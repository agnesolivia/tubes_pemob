import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/asset_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';
import 'package:tubes_pemob/services/storage_service.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/services/asset_service.dart';
import 'package:tubes_pemob/screens/shared/history_aset_screen.dart';

class CreateReportScreen extends StatefulWidget {
  final AssetModel? selectedAsset;

  const CreateReportScreen({super.key, this.selectedAsset});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailLocationController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _uploadedPhotos =
      []; // Menyimpan string Base64 hasil kompresi
  bool _isSubmitting = false;

  // Daftar Gedung di Universitas Sumatera Utara (USU)
  final List<String> _usuBuildings = const [
    'Gedung Fasilkom-TI (Gedung A)',
    'Gedung Fasilkom-TI (Gedung B)',
    'Gedung Fasilkom-TI (Gedung C)',
    'Gedung Fasilkom-TI (Gedung D)',
    'Biro Pusat Administrasi (BPA) USU',
    'Perpustakaan Pusat USU',
    'Auditorium USU',
    'Gedung Pancasila USU',
    'Fakultas Teknik (FT) USU',
    'Fakultas Kedokteran (FK) USU',
    'Fakultas Ekonomi dan Bisnis (FEB) USU',
    'Fakultas Hukum (FH) USU',
    'Fakultas Ilmu Budaya (FIB) USU',
    'Fakultas MIPA (FMIPA) USU',
    'Fakultas Pertanian (FP) USU',
    'Fakultas Ilmu Sosial dan Ilmu Politik (FISIP) USU',
    'Fakultas Kesehatan Masyarakat (FKM) USU',
    'Fakultas Farmasi (FF) USU',
    'Fakultas Psikologi (FPsi) USU',
    'Fakultas Keperawatan (FKep) USU',
    'Fakultas Kedokteran Gigi (FKG) USU',
    'Fakultas Kehutanan (Fahutan) USU',
    'Fakultas Vokasi USU',
    'Pusat Sistem Informasi (PSI) USU',
    'Poliklinik USU',
    'Masjid Dakwah USU',
    'Gelanggang Mahasiswa USU',
  ];

  String? _selectedBuilding;
  AssetModel? _selectedAsset;
  List<AssetModel> _allAssets = [];
  StreamSubscription<List<AssetModel>>? _assetsSub;

  /// Gabungan gedung unik (case-insensitive) dari Firestore `assets` + daftar USU
  List<String> get _buildingOptions {
    final seen = <String>{};
    final result = <String>[];
    for (final b in [
      ..._allAssets.map((a) => a.gedung.trim()),
      ..._usuBuildings,
    ]) {
      final key = b.toLowerCase();
      if (b.isNotEmpty && seen.add(key)) {
        result.add(b);
      }
    }
    return result;
  }

  /// Daftar aset di gedung yang sedang dipilih (case-insensitive)
  List<AssetModel> get _assetsInSelectedBuilding {
    if (_selectedBuilding == null) return const [];
    final target = _selectedBuilding!.trim().toLowerCase();
    return _allAssets
        .where((a) => a.gedung.trim().toLowerCase() == target)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final asset = widget.selectedAsset;
    if (asset != null) {
      _selectedAsset = asset;
      _titleController.text = asset.nama;
      _selectedBuilding = asset.gedung;
      _detailLocationController.text =
          asset.ruangan.trim().isEmpty ? 'Area Umum' : asset.ruangan;
    }
    _assetsSub = AssetService.instance.streamAllAssets().listen((assets) {
      if (mounted) setState(() => _allAssets = assets);
    });
  }

  @override
  void dispose() {
    _assetsSub?.cancel();
    _titleController.dispose();
    _detailLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Membuka pemilih file/galeri (JPG/PNG) atau kamera perangkat
  Future<void> _pickPhoto(ImageSource source) async {
    if (_uploadedPhotos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 1 foto bukti kerusakan (batas ukuran Firestore).'),
        ),
      );
      return;
    }

    try {
      final base64Photo = await StorageService.instance.pickAndCompressImage(
        source: source,
      );

      if (base64Photo != null && mounted) {
        setState(() {
          _uploadedPhotos.add(base64Photo);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses gambar: $e')),
      );
    }
  }

  void _showBuildingPicker() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBuildings = _buildingOptions
                .where(
                  (building) => building.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.45,
              maxChildSize: 0.88,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
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
                        'Pilih Gedung di USU',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A0D14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Cari nama gedung atau fakultas...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF8A94A6),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF4F7FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredBuildings.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final building = filteredBuildings[index];
                            final isSelected = _selectedBuilding == building;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              leading: Icon(
                                Icons.apartment_rounded,
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              title: Text(
                                building,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : const Color(0xFF0A0D14),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  if (_selectedBuilding?.toLowerCase() !=
                                      building.toLowerCase()) {
                                    if (_selectedAsset != null) {
                                      _titleController.clear();
                                      _detailLocationController.clear();
                                    }
                                    _selectedAsset = null;
                                  }
                                  _selectedBuilding = building;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAssetPicker() {
    if (_selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gedung terlebih dahulu.')),
      );
      return;
    }

    String searchQuery = '';
    String? selectedRoom; // null = Semua, '' = Area Umum / Tanpa Ruangan
    final buildingAssets = _assetsInSelectedBuilding;

    // Kumpulkan daftar ruangan unik (case-insensitive) di gedung terpilih
    final seenRooms = <String>{};
    final roomOptions = <String>[];
    bool hasAreaUmum = false;
    for (final a in buildingAssets) {
      final r = a.ruangan.trim();
      if (r.isEmpty) {
        hasAreaUmum = true;
      } else if (seenRooms.add(r.toLowerCase())) {
        roomOptions.add(r);
      }
    }
    roomOptions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = searchQuery.trim().toLowerCase();
            final filtered = buildingAssets.where((a) {
              if (selectedRoom != null) {
                final r = a.ruangan.trim();
                if (selectedRoom == '' && r.isNotEmpty) return false;
                if (selectedRoom != '' &&
                    r.toLowerCase() != selectedRoom!.toLowerCase()) {
                  return false;
                }
              }
              if (q.isEmpty) return true;
              final ruangLabel =
                  a.ruangan.trim().isEmpty ? 'area umum' : a.ruangan.toLowerCase();
              return a.nama.toLowerCase().contains(q) ||
                  ruangLabel.contains(q) ||
                  a.kategori.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.45,
              maxChildSize: 0.88,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
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
                        'Pilih Aset di $_selectedBuilding',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A0D14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setModalState(() => searchQuery = v),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Cari ruangan atau nama aset (mis. Kursi#01)...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF8A94A6),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF4F7FC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      if (roomOptions.isNotEmpty || hasAreaUmum) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildRoomFilterChip(
                                label: 'Semua',
                                isSelected: selectedRoom == null,
                                onTap: () =>
                                    setModalState(() => selectedRoom = null),
                              ),
                              if (hasAreaUmum)
                                _buildRoomFilterChip(
                                  label: 'Area Umum / Tanpa Ruangan',
                                  isSelected: selectedRoom == '',
                                  onTap: () =>
                                      setModalState(() => selectedRoom = ''),
                                ),
                              ...roomOptions.map(
                                (room) => _buildRoomFilterChip(
                                  label: room,
                                  isSelected: selectedRoom?.toLowerCase() ==
                                      room.toLowerCase(),
                                  onTap: () =>
                                      setModalState(() => selectedRoom = room),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      // Opsi Resmi: Fasilitas Lainnya / Tidak Terdaftar (assetId: null)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        leading: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.accentOrange,
                        ),
                        title: Text(
                          'Fasilitas Lainnya / Tidak Terdaftar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A0D14),
                          ),
                        ),
                        subtitle: Text(
                          'Isi nama fasilitas & ruangan secara manual',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        trailing: _selectedAsset == null
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            if (_selectedAsset != null) {
                              _titleController.clear();
                              _detailLocationController.clear();
                            }
                            _selectedAsset = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'Belum ada aset terdaftar di gedung ini.\nGunakan opsi "Fasilitas Lainnya" di atas.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (context, index) {
                                  final asset = filtered[index];
                                  final isSelected =
                                      _selectedAsset?.id == asset.id;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    leading: Icon(
                                      Icons.inventory_2_outlined,
                                      color: isSelected
                                          ? AppColors.primaryBlue
                                          : const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    title: Text(
                                      asset.nama,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primaryBlue
                                            : const Color(0xFF0A0D14),
                                      ),
                                    ),
                                    subtitle: Text(
                                    '${asset.ruangan.trim().isEmpty ? 'Area Umum' : asset.ruangan} • ${asset.kategori}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primaryBlue,
                                            size: 20,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedAsset = asset;
                                        _titleController.text = asset.nama;
                                        _detailLocationController.text =
                                          asset.ruangan.trim().isEmpty
                                              ? 'Area Umum'
                                              : asset.ruangan;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openSelectedAssetHistory() {
    final asset = _selectedAsset;
    if (asset == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryAssetScreen(
          assetId: asset.id,
          initialAsset: asset,
          fallbackNama: asset.nama,
          fallbackLokasi: asset.lokasiLengkap,
          userRole: UserRole.pelapor,
        ),
      ),
    );
  }

  Future<void> _onSubmitReport() async {
    if (_uploadedPhotos.isEmpty ||
        _titleController.text.trim().isEmpty ||
        _selectedBuilding == null ||
        (_selectedAsset == null &&
            _detailLocationController.text.trim().isEmpty) ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua kolom yang bertanda bintang (*).'),
        ),
      );
      return;
    }

    final firebaseUser = AuthService.instance.currentUser;
    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan. Silakan masuk ulang.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final pelapor = await AuthService.instance.getUserData(firebaseUser.uid) ??
          UserModel(
            uid: firebaseUser.uid,
            nama: firebaseUser.displayName ?? 'Pengguna Kampus',
            email: firebaseUser.email ?? '',
            role: UserRole.pelapor,
            createdAt: DateTime.now(),
          );

      if (_selectedAsset != null) {
        await ReportService.instance.createReport(
          asset: _selectedAsset,
          pelapor: pelapor,
          deskripsi: _descriptionController.text.trim(),
          fotoSebelumBase64: _uploadedPhotos.first,
        );
      } else {
        await ReportService.instance.createReport(
          asset: null,
          assetNama: _titleController.text.trim(),
          assetLokasi:
              '${_selectedBuilding!} - ${_detailLocationController.text.trim()}',
          pelapor: pelapor,
          deskripsi: _descriptionController.text.trim(),
          fotoSebelumBase64: _uploadedPhotos.first,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim dan menunggu verifikasi Admin.'),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: AppColors.statusRejectedText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

            // 2. Tata Letak Utama (Header + Form Putih)
            Column(
              children: [
                // AppBar Custom di Atas Latar Biru
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
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
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Buat Laporan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Lengkapi foto & lokasi fasilitas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Container Putih Melengkung
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header Foto Kerusakan Fasilitas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRequiredLabel('Foto Kerusakan Fasilitas'),
                                Text(
                                  '${_uploadedPhotos.length}/1 Foto Terunggah',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Kotak Dashed Upload Foto
                            CustomPaint(
                              painter: _DashedRRectPainter(
                                color: const Color(0xFFCBD5E1),
                                radius: 18,
                                strokeWidth: 1.3,
                                dashWidth: 5,
                                dashSpace: 4,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                                child: Column(
                                  children: [
                                    // Area Tap to upload photo (Buka File / Galeri JPG & PNG)
                                    InkWell(
                                      onTap: () =>
                                          _pickPhoto(ImageSource.gallery),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF1F5F9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.cloud_upload_outlined,
                                                color: Color(0xFF475569),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Tap to upload photo',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.primaryBlue,
                                                  ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'JPG atau PNG',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w400,
                                                    color: const Color(
                                                      0xFF94A3B8,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Pembatas OR
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(
                                            color: Color(0xFFE2E8F0),
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(
                                            color: Color(0xFFE2E8F0),
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Tombol Open camera (Buka Kamera Langsung)
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _pickPhoto(ImageSource.camera),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryBlue,
                                          foregroundColor: AppColors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Open camera',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Thumbnail Foto yang Berhasil Dipilih / Dijepret
                                    if (_uploadedPhotos.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        alignment: WrapAlignment.center,
                                        children: List.generate(
                                          _uploadedPhotos.length,
                                          (index) {
                                            final photo =
                                                _uploadedPhotos[index];
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: () {
                                                    final bytes = StorageService
                                                        .instance
                                                        .base64ToBytes(photo);
                                                    if (bytes == null) {
                                                      return const SizedBox(
                                                        width: 74,
                                                        height: 74,
                                                        child: Icon(Icons.broken_image),
                                                      );
                                                    }
                                                    return Image.memory(
                                                      bytes,
                                                      width: 74,
                                                      height: 74,
                                                      fit: BoxFit.cover,
                                                    );
                                                  }(),
                                                ),
                                                Positioned(
                                                  top: -6,
                                                  right: -6,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _uploadedPhotos
                                                            .removeAt(index);
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 22,
                                                      height: 22,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0xFFEF4444,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: const Icon(
                                                        Icons.close_rounded,
                                                        size: 14,
                                                        color: AppColors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 2. Judul Kerusakan
                            _buildRequiredLabel('Judul Kerusakan'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              readOnly: _selectedAsset != null,
                              style: _inputTextStyle(),
                              decoration: _pillInputDecoration(
                                hintText: 'Masukkan judul kerusakan',
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 4a. Lokasi (Pilih Gedung di USU)
                            _buildRequiredLabel('Lokasi'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _showBuildingPicker,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFFD5DFEF),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedBuilding ?? 'Pilih gedung',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: _selectedBuilding != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedBuilding != null
                                              ? const Color(0xFF0A0D14)
                                              : const Color(0xFF8A94A6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                          // 4b. Pilih Aset di Gedung Tersebut (dari Firestore `assets` atau Fasilitas Lainnya)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Aset / Fasilitas',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0A0D14),
                                    ),
                                  ),
                                ),
                                if (_selectedAsset != null)
                                  InkWell(
                                    onTap: _openSelectedAssetHistory,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF2FF),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.history_rounded,
                                            size: 14,
                                            color: AppColors.primaryBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Riwayat Aset',
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
                            ),
                            const SizedBox(height: 8),

                            InkWell(
                              onTap: _showAssetPicker,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFFD5DFEF),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedAsset != null
                                            ? _selectedAsset!.nama
                                            : (_selectedBuilding == null
                                                ? 'Pilih gedung terlebih dahulu'
                                                : 'Fasilitas Lainnya'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: _selectedAsset != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedAsset != null
                                              ? const Color(0xFF0A0D14)
                                              : const Color(0xFF8A94A6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_selectedAsset != null)
                              StreamBuilder<List<ReportModel>>(
                                stream: ReportService.instance
                                    .streamActiveReportsByAsset(
                                  _selectedAsset!.id,
                                ),
                                builder: (context, snap) {
                                  final activeCount = snap.data?.length ?? 0;
                                  if (activeCount == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Info: Aset ini sedang memiliki $activeCount laporan aktif yang sedang ditangani.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 18),

                            // 5. Detail lokasi
                            _buildRequiredLabel('Detail lokasi'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _detailLocationController,
                              readOnly: _selectedAsset != null,
                              style: _inputTextStyle(),
                              decoration: _pillInputDecoration(
                                hintText: 'Lantai, nama ruangan',
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 6. Deskripsi + Counter 0/100
                            _buildRequiredLabel('Deskripsi'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              maxLength: 300,
                              onChanged: (_) => setState(() {}),
                              style: _inputTextStyle(),
                              decoration: InputDecoration(
                                hintText:
                                    'Jelaskan kerusakan yang kamu temukan',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF8A94A6),
                                ),
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.inputFill,
                                contentPadding: const EdgeInsets.all(18),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD5DFEF),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${_descriptionController.text.length}/300',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 7. Kotak Informasi Admin & Teknisi
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F6FE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFDCE7FA),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'i',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: const Color(0xFF334155),
                                          height: 1.45,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'Laporan akan diperiksa ',
                                          ),
                                          TextSpan(
                                            text: 'Admin',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0A0D14),
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' lalu diteruskan kepada ',
                                          ),
                                          TextSpan(
                                            text: 'Teknisi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0A0D14),
                                            ),
                                          ),
                                          TextSpan(text: ' untuk perbaikan.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 8. Tombol Utama "Kirim Laporan ->"
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _onSubmitReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Kirim Laporan',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0A0D14),
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _inputTextStyle() {
    return GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF0A0D14),
    );
  }

  Widget _buildRoomFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _pillInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF8A94A6),
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFFD5DFEF), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.4),
      ),
    );
  }
}

/// Painter untuk garis putus-putus pada kotak upload foto
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance.clamp(0.0, metric.length)),
          paint,
        );
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) => false;
}
