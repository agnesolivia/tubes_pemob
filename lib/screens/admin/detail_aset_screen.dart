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
import 'package:tubes_pemob/screens/admin/kelola_aset_screen.dart';
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

  Future<void> _openEditSheet(AssetModel currentAsset) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAssetSheet(asset: currentAsset),
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
        // Ambil versi terbaru aset jika baru saja di-edit
        final currentAsset = snapshot.data?.firstWhere(
              (item) => item.id == widget.asset.id,
              orElse: () => widget.asset,
            ) ??
            widget.asset;

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
                  onPressed: () => _openEditSheet(currentAsset),
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

                  // 3. INFO PENJELASAN STIKER QR
                  Container(
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
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Kode QR terhubung ke ID dokumen ($qrPayload). Label nama aset dan lokasi dicetak di bawah QR agar pelapor tetap bisa melapor manual bila kamera bermasalah.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

  const _EditAssetSheet({required this.asset});

  @override
  State<_EditAssetSheet> createState() => _EditAssetSheetState();
}

class _EditAssetSheetState extends State<_EditAssetSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _gedungController;
  late final TextEditingController _ruanganController;
  late String _selectedCategory;
  bool _isSaving = false;

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
    _selectedCategory = _categories.contains(widget.asset.kategori)
        ? widget.asset.kategori
        : 'Lainnya';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _gedungController.dispose();
    _ruanganController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              cleanMsg,
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
            backgroundColor: AppColors.statusRejectedText,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          child: Form(
            key: _formKey,
            child: Column(
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
                TextFormField(
                  controller: _gedungController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                  decoration: _decoration(
                    hint: 'Contoh: Gedung A',
                    icon: Icons.apartment_rounded,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                ),
                const SizedBox(height: 14),

                _label('Ruangan (Opsional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ruanganController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                  decoration: _decoration(
                    hint: 'Kosongkan jika berada di area gedung',
                    icon: Icons.meeting_room_outlined,
                  ),
                ),
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
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),
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