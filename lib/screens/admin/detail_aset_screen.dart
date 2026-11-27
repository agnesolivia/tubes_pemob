import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/asset_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/kelola_aset_screen.dart';
import 'package:tubes_pemob/screens/shared/history_asset_screen.dart';
import 'package:tubes_pemob/services/asset_service.dart';

class DetailAsetScreen extends StatefulWidget {
  final AssetModel asset;
  final bool scrollToQr;

  const DetailAsetScreen({
    super.key,
    required this.asset,
    this.scrollToQr = false,
  });

  @override
  State<DetailAsetScreen> createState() => _DetailAsetScreenState();
}

class _DetailAsetScreenState extends State<DetailAsetScreen> {
  final GlobalKey _qrKey = GlobalKey();
  final GlobalKey _qrSectionKey = GlobalKey();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollToQr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _qrSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Future<void> _openEditSheet(
    AssetModel currentAsset,
    List<AssetModel> allAssets,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAssetSheet(
        asset: currentAsset,
        allAssets: allAssets,
      ),
    );

    if (updated == true && mounted) {
      _showMessage('Data aset berhasil diperbarui.');
    }
  }

  Future<void> _confirmDelete(AssetModel currentAsset) async {
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
            'Apakah kamu yakin ingin menghapus "${currentAsset.nama}" di ${currentAsset.lokasiLengkap}?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
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

    try {
      await AssetService.instance.deleteAsset(currentAsset.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Aset "${currentAsset.nama}" berhasil dihapus.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menghapus aset: $e', isError: true);
    }
  }

  Future<Uint8List> _captureQrImage() async {
    await WidgetsBinding.instance.endOfFrame;

    final renderObject = _qrKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('QR Code gagal diproses.');
    }

    final ui.Image image = await renderObject.toImage(pixelRatio: 4);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw Exception('Gagal menghasilkan gambar QR.');
    }

    return byteData.buffer.asUint8List();
  }

  String _safeFileName(AssetModel asset) {
    final sanitizedName = asset.nama
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'QR_${sanitizedName}_${asset.id.substring(0, 5)}.png';
  }

  Future<void> _shareQrImage(AssetModel asset) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _captureQrImage();
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: _safeFileName(asset),
          ),
        ],
        text: 'QR Code Aset ${asset.nama} (${asset.lokasiLengkap})',
        subject: 'QR Code Aset ${asset.nama}',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Gagal membagikan QR Code.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveQrImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _captureQrImage();
      await Gal.putImageBytes(bytes);
      if (mounted) {
        _showMessage('QR Code berhasil disimpan ke galeri.');
      }
    } on GalException catch (error) {
      if (mounted) {
        _showMessage(error.type.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Gagal menyimpan QR Code.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          backgroundColor: isError
              ? AppColors.statusRejectedText
              : const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AssetModel>>(
      stream: AssetService.instance.streamAllAssets(),
      builder: (context, snapshot) {
        final allAssets = snapshot.data ?? const <AssetModel>[];
        // Ambil versi terbaru aset jika baru saja di-edit
        final currentAsset = allAssets.firstWhere(
          (item) => item.id == widget.asset.id,
          orElse: () => widget.asset,
        );

        final qrPayload = 'ASSET:${currentAsset.id}';

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
                'Detail Aset & QR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _openEditSheet(currentAsset, allAssets),
                  tooltip: 'Ubah Aset',
                  icon: const Icon(Icons.edit_outlined, size: 22),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(currentAsset),
                  tooltip: 'Hapus Aset',
                  icon: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                children: [
                  // 1. INFORMASI ASET
                  _buildAssetInformation(currentAsset),
                  const SizedBox(height: 18),

                  // 2. KARTU STIKER QR CODE
                  Container(
                    key: _qrSectionKey,
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        width: double.infinity,
                        color: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              semanticsLabel: 'QR Code ${currentAsset.nama}',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentAsset.nama,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentAsset.lokasiLengkap,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. KARTU PINTASAN RIWAYAT KERUSAKAN ASET
                  Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryAssetScreen(
                              assetId: currentAsset.id,
                              initialAsset: currentAsset,
                              fallbackNama: currentAsset.nama,
                              fallbackLokasi: currentAsset.lokasiLengkap,
                              userRole: UserRole.admin,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.statusDoneBg,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Riwayat Kerusakan Aset',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lihat rekam jejak laporan & perbaikan unit ini',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _shareQrImage(currentAsset),
                        icon: const Icon(Icons.share_rounded, size: 19),
                        label: Text(
                          'Bagikan QR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _saveQrImage,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 20),
                        label: Text(
                          'Simpan QR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          elevation: 0,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssetInformation(AssetModel asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.statusDoneBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  getAssetCategoryIcon(asset.kategori),
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusDoneBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        asset.kategori,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      asset.nama,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            icon: Icons.apartment_rounded,
            label: 'Gedung',
            value: asset.gedung,
          ),
          const Divider(color: AppColors.border, height: 1),
          _detailRow(
            icon: Icons.meeting_room_outlined,
            label: 'Ruangan',
            value: asset.hasRuangan
                ? asset.ruangan
                : 'Tidak ada (Area gedung)',
            isMuted: !asset.hasRuangan,
          ),
          const Divider(color: AppColors.border, height: 1),
          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Terdaftar',
            value: _formatDate(asset.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMuted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isMuted ? FontWeight.w500 : FontWeight.w700,
                fontStyle: isMuted ? FontStyle.italic : FontStyle.normal,
                color:
                    isMuted ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditAssetSheet extends StatefulWidget {
  final AssetModel asset;
  final List<AssetModel> allAssets;

  const _EditAssetSheet({
    required this.asset,
    required this.allAssets,
  });

  @override
  State<_EditAssetSheet> createState() => _EditAssetSheetState();
}

class _EditAssetSheetState extends State<_EditAssetSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _gedungController;
  late final TextEditingController _ruanganController;
  late final FocusNode _gedungFocusNode;
  late final FocusNode _ruanganFocusNode;

  late String _selectedCategory;
  late String _lastGedung;
  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _categories = [
    'Elektronik',
    'Inventaris',
    'Sanitasi',
    'Kelistrikan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.asset.nama);
    _gedungController = TextEditingController(text: widget.asset.gedung);
    _ruanganController = TextEditingController(text: widget.asset.ruangan);
    _gedungFocusNode = FocusNode();
    _ruanganFocusNode = FocusNode();
    _lastGedung = widget.asset.gedung.trim().toLowerCase();
    _selectedCategory = _categories.contains(widget.asset.kategori)
        ? widget.asset.kategori
        : 'Lainnya';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _gedungController.dispose();
    _ruanganController.dispose();
    _gedungFocusNode.dispose();
    _ruanganFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedAsset = widget.asset.copyWith(
        nama: _namaController.text.trim(),
        kategori: _selectedCategory,
        gedung: _gedungController.text.trim(),
        ruangan: _ruanganController.text.trim(),
      );

      await AssetService.instance.updateAsset(updatedAsset);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = cleanMsg);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gedungOptions =
        AssetService.instance.extractUniqueGedung(widget.allAssets);
    final currentGedung = _gedungController.text.trim();
    final ruanganOptions = currentGedung.isEmpty
        ? const <String>[]
        : AssetService.instance.extractUniqueRuangan(
            widget.allAssets,
            currentGedung,
          );

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ubah Data Aset',
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
                  const SizedBox(height: 16),

                  _label('Nama Aset'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _namaController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _decoration(
                      hint: 'Masukkan nama aset',
                      icon: Icons.inventory_2_outlined,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                  ),
                  const SizedBox(height: 14),

                  _label('Kategori'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: _decoration(
                      hint: 'Pilih kategori',
                      icon: Icons.category_outlined,
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  _label('Gedung'),
                  const SizedBox(height: 6),
                  _buildAutocompleteField(
                    controller: _gedungController,
                    focusNode: _gedungFocusNode,
                    hint: 'Pilih atau ketik nama gedung',
                    icon: Icons.apartment_rounded,
                    suggestions: gedungOptions,
                    openDirection: OptionsViewOpenDirection.down,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                    onSelected: (selection) {
                      final normalized = selection.trim().toLowerCase();
                      if (normalized != _lastGedung) {
                        _ruanganController.clear();
                        _lastGedung = normalized;
                      }
                      setState(() {});
                    },
                    onChanged: () {
                      _lastGedung =
                          _gedungController.text.trim().toLowerCase();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),

                  _label('Ruangan (Opsional)'),
                  const SizedBox(height: 6),
                  _buildAutocompleteField(
                    controller: _ruanganController,
                    focusNode: _ruanganFocusNode,
                    hint: 'Kosongkan jika berada di area gedung',
                    icon: Icons.meeting_room_outlined,
                    suggestions: ruanganOptions,
                    openDirection: OptionsViewOpenDirection.up,
                    onSelected: (_) => setState(() {}),
                    onChanged: () => setState(() {}),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusRejectedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: AppColors.statusRejectedText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusRejectedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required List<String> suggestions,
    required OptionsViewOpenDirection openDirection,
    String? Function(String?)? validator,
    ValueChanged<String>? onSelected,
    VoidCallback? onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: focusNode,
          optionsViewOpenDirection: openDirection,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (suggestions.isEmpty) return const Iterable<String>.empty();
            final query = textEditingValue.text.trim().toLowerCase();
            // Jika kosong atau masih sama persis dengan opsi yang ada,
            // tampilkan semua saran agar Admin mudah ganti lokasi
            if (query.isEmpty ||
                suggestions.any((item) => item.toLowerCase() == query)) {
              return suggestions;
            }
            return suggestions.where(
              (item) => item.toLowerCase().contains(query),
            );
          },
          onSelected: (selection) {
            onSelected?.call(selection);
          },
          fieldViewBuilder: (
            context,
            fieldController,
            fieldFocusNode,
            onFieldSubmitted,
          ) {
            return TextFormField(
              controller: fieldController,
              focusNode: fieldFocusNode,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onChanged?.call(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
              decoration: _decoration(
                hint: hint,
                icon: icon,
                suffixIcon: fieldController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          fieldController.clear();
                          fieldFocusNode.requestFocus();
                          onChanged?.call();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : (suggestions.isNotEmpty
                        ? const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          )
                        : null),
              ),
              validator: validator,
            );
          },
          optionsViewBuilder: (context, onOptionSelected, options) {
            return Align(
              alignment: openDirection == OptionsViewOpenDirection.up
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              child: Material(
                elevation: 6,
                color: AppColors.white,
                borderRadius: BorderRadius.circular(13),
                shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.14),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 170),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onOptionSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F9FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.border),
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
}
