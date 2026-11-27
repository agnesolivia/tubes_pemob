import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/history_asset_screen.dart';
import 'package:tubes_pemob/services/asset_service.dart';
import 'package:tubes_pemob/services/auth_service.dart';

enum ScanQrMode { asset, user, all }

class ScanQrScreen extends StatefulWidget {
  final ScanQrMode mode;
  final UserRole role;

  const ScanQrScreen({
    super.key,
    this.mode = ScanQrMode.asset,
    this.role = UserRole.pelapor,
  });

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
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lampu kilat tidak tersedia pada perangkat ini.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kamera lain tidak tersedia pada perangkat ini.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resumeScanner() {
    if (!mounted) return;
    setState(() {
      _statusMessage = null;
      _isProcessing = false;
    });
    _controller.start();
  }

  Future<void> _showErrorAndResume(String message) async {
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

    // Jeda singkat agar kamera tidak langsung menembak QR salah yang sama berulang kali
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted && !_isProcessing) {
      await _controller.start();
    }
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

    switch (widget.mode) {
      case ScanQrMode.asset:
        await _handleAssetQr(rawValue);
        break;
      case ScanQrMode.user:
        await _handleUserQrForReturn(rawValue);
        break;
      case ScanQrMode.all:
        await _handleUniversalAdminQr(rawValue);
        break;
    }
  }

  Future<void> _handleUniversalAdminQr(String rawValue) async {
    if (widget.role != UserRole.admin) {
      await _showErrorAndResume(
        'Mode pemindaian universal hanya tersedia untuk Admin.',
      );
      return;
    }

    if (rawValue.startsWith(_userPrefix)) {
      final uid = rawValue.substring(_userPrefix.length).trim();
      if (uid.isEmpty) {
        await _showErrorAndResume('UID pengguna pada QR tidak valid.');
        return;
      }
      await _handleAdminUserPromotion(uid);
      return;
    }

    if (rawValue.startsWith(_assetPrefix)) {
      final assetId = rawValue.substring(_assetPrefix.length).trim();
      if (assetId.isEmpty) {
        await _showErrorAndResume('ID aset pada QR kosong atau tidak valid.');
        return;
      }
      await _fetchAndRouteAsset(assetId);
      return;
    }

    await _showErrorAndResume(
      'Format QR tidak dikenali. Pindai QR Fasilitas (ASSET) atau QR Profil (USER) resmi SnaFix.',
    );
  }

  Future<void> _handleAssetQr(String rawValue) async {
    if (rawValue.startsWith(_userPrefix)) {
      await _showErrorAndResume(
        'Ini adalah QR Profil Pengguna, bukan QR Aset. Pindai stiker QR pada fasilitas.',
      );
      return;
    }

    if (!rawValue.startsWith(_assetPrefix)) {
      await _showErrorAndResume(
        'Format QR tidak dikenali. Pastikan memindai stiker QR resmi SnaFix.',
      );
      return;
    }

    final assetId = rawValue.substring(_assetPrefix.length).trim();
    if (assetId.isEmpty) {
      await _showErrorAndResume('ID aset pada QR kosong atau tidak valid.');
      return;
    }

    await _fetchAndRouteAsset(assetId);
  }

  Future<void> _fetchAndRouteAsset(String assetId) async {
    try {
      final asset = await AssetService.instance.getAssetById(assetId);
      if (!mounted) return;

      if (asset == null) {
        await _showErrorAndResume(
          'Aset tidak ditemukan di database. Gunakan Lapor Manual jika aset belum terdaftar.',
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HistoryAssetScreen(
            assetId: asset.id,
            initialAsset: asset,
            fallbackNama: asset.nama,
            fallbackLokasi: asset.lokasiLengkap,
            userRole: widget.role,
          ),
        ),
      );

      // Nyalakan kamera kembali saat pengguna menekan Back dari HistoryAssetScreen
      _resumeScanner();
    } catch (e) {
      await _showErrorAndResume('Gagal memuat data aset: $e');
    }
  }

  Future<void> _handleUserQrForReturn(String rawValue) async {
    if (widget.role != UserRole.admin) {
      await _showErrorAndResume(
        'Akses ditolak: hanya Admin yang dapat memindai QR Profil pengguna.',
      );
      return;
    }

    if (rawValue.startsWith(_assetPrefix)) {
      await _showErrorAndResume('Ini adalah QR Aset, bukan QR Profil Pengguna.');
      return;
    }

    if (!rawValue.startsWith(_userPrefix)) {
      await _showErrorAndResume(
        'Format QR tidak dikenali. Pastikan memindai QR Profil pengguna.',
      );
      return;
    }

    final uid = rawValue.substring(_userPrefix.length).trim();
    if (uid.isEmpty) {
      await _showErrorAndResume('UID pengguna pada QR tidak valid.');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop<String>(uid);
  }

  Future<void> _handleAdminUserPromotion(String uid) async {
    if (widget.role != UserRole.admin) {
      await _showErrorAndResume(
        'Akses ditolak: hanya Admin yang dapat mengubah role pengguna.',
      );
      return;
    }

    try {
      final targetUser = await AuthService.instance.getUserData(uid);
      if (!mounted) return;

      if (targetUser == null) {
        await _showErrorAndResume('Akun pengguna tidak ditemukan di database.');
        return;
      }

      if (targetUser.role != UserRole.pelapor) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Informasi Akun',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            content: Text(
              'Akun ${targetUser.nama} (${targetUser.email}) saat ini sudah berstatus ${targetUser.role.label}.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                ),
                child: Text(
                  'Mengerti',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        _resumeScanner();
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Angkat Jadi Teknisi?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pastikan identitas akun berikut sudah sesuai sebelum memberikan akses Teknisi:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetUser.nama,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetUser.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                'Jadikan Teknisi',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await AuthService.instance.updateUserRole(
          uid: targetUser.uid,
          newRole: UserRole.teknisi,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${targetUser.nama} berhasil diangkat menjadi Teknisi.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _resumeScanner();
    } catch (e) {
      await _showErrorAndResume('Gagal memproses QR pengguna: $e');
    }
  }

  String get _appBarTitle => switch (widget.mode) {
        ScanQrMode.asset => 'Scan QR Aset',
        ScanQrMode.user => 'Scan QR Pengguna',
        ScanQrMode.all => 'Scan QR SnaFix',
      };

  String get _defaultHintText => switch (widget.mode) {
        ScanQrMode.asset => 'Arahkan kamera ke stiker QR fasilitas kampus',
        ScanQrMode.user => 'Arahkan kamera ke QR Profil pelapor',
        ScanQrMode.all => 'Pindai QR Fasilitas kampus atau QR Profil pengguna',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _appBarTitle,
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
                      _statusMessage ?? _defaultHintText,
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
