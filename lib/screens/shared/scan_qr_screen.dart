import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/screens/pelapor/form_pengaduan_screen.dart';
import 'package:tubes_pemob/services/asset_service.dart';

enum ScanQrMode { asset, user }

class ScanQrScreen extends StatefulWidget {
  final ScanQrMode mode;

  const ScanQrScreen({super.key, this.mode = ScanQrMode.asset});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  static const String _assetPrefix = 'ASSET:';
  static const String _userPrefix = 'USER:';

  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() => _isTorchOn = !_isTorchOn);
  }

  Future<void> _switchCamera() async {
    await _controller.switchCamera();
  }

  void _showErrorAndResume(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _statusMessage = message;
      _isProcessing = false;
    });
    _controller.start();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Memverifikasi QR Code...';
    });
    await _controller.stop();

    if (widget.mode == ScanQrMode.asset) {
      await _handleAssetQr(rawValue);
    } else {
      _handleUserQr(rawValue);
    }
  }

  Future<void> _handleAssetQr(String rawValue) async {
    if (rawValue.startsWith(_userPrefix)) {
      _showErrorAndResume(
        'Ini adalah QR Profil Pengguna, bukan QR Aset. Pindai stiker QR pada fasilitas.',
      );
      return;
    }

    if (!rawValue.startsWith(_assetPrefix)) {
      _showErrorAndResume(
        'Format QR tidak dikenali. Pastikan memindai stiker QR resmi SnaFix.',
      );
      return;
    }

    final assetId = rawValue.substring(_assetPrefix.length).trim();
    if (assetId.isEmpty) {
      _showErrorAndResume('ID aset pada QR kosong atau tidak valid.');
      return;
    }

    try {
      final asset = await AssetService.instance.getAssetById(assetId);
      if (!mounted) return;

      if (asset == null) {
        _showErrorAndResume(
          'Aset tidak ditemukan di database. Gunakan Lapor Manual jika aset belum terdaftar.',
        );
        return;
      }

      // TODO: Arahkan ke HistoryAssetScreen(asset: asset) terlebih dahulu
      // setelah halaman lib/screens/shared/history_asset_screen.dart selesai dibuat.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CreateReportScreen(selectedAsset: asset),
        ),
      );
    } catch (e) {
      _showErrorAndResume('Gagal memuat data aset: $e');
    }
  }

  void _handleUserQr(String rawValue) {
    if (rawValue.startsWith(_assetPrefix)) {
      _showErrorAndResume('Ini adalah QR Aset, bukan QR Profil Pengguna.');
      return;
    }

    if (!rawValue.startsWith(_userPrefix)) {
      _showErrorAndResume(
        'Format QR tidak dikenali. Pastikan memindai QR Profil pengguna.',
      );
      return;
    }

    final uid = rawValue.substring(_userPrefix.length).trim();
    if (uid.isEmpty) {
      _showErrorAndResume('UID pengguna pada QR tidak valid.');
      return;
    }

    Navigator.of(context).pop<String>(uid);
  }

  @override
  Widget build(BuildContext context) {
    final isAssetMode = widget.mode == ScanQrMode.asset;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isAssetMode ? 'Scan QR Aset' : 'Scan QR Pengguna',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Lampu Kilat',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Ganti Kamera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.amber : AppColors.primaryBlue,
                  width: 3.5,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.28),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 28,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _statusMessage ??
                          (isAssetMode
                              ? 'Arahkan kamera ke stiker QR fasilitas kampus'
                              : 'Arahkan kamera ke QR Profil pelapor'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
