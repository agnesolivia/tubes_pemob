import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final ImagePicker _picker = ImagePicker();

  /// Batas aman ukuran raw bytes per foto (~250 KB -> ~340 KB setelah Base64).
  /// Dua foto (sebelum + sesudah) maksimal ~680 KB, aman di bawah limit 1 MB Firestore.
  static const int _maxRawBytes = 250 * 1024;
  static const int _hardLimitBytes = 350 * 1024;

  /// Mengambil gambar dari kamera atau galeri, mengompresi, lalu mengembalikan String Base64.
  /// Mengembalikan null jika pengguna membatalkan pemilihan gambar.
  Future<String?> pickAndCompressImage({
    required ImageSource source,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      // Batasi resolusi awal dari picker agar memori perangkat tidak berat
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (pickedFile == null) return null;

    final Uint8List originalBytes = await pickedFile.readAsBytes();

    // Kompresi tahap 1 (resolusi 800px, kualitas 65%)
    Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 800,
      minHeight: 800,
      quality: 65,
      format: CompressFormat.jpeg,
    );

    // Kompresi tahap 2 jika ukuran file masih di atas 250 KB
    if (compressedBytes.lengthInBytes > _maxRawBytes) {
      compressedBytes = await FlutterImageCompress.compressWithList(
        compressedBytes,
        minWidth: 600,
        minHeight: 600,
        quality: 45,
        format: CompressFormat.jpeg,
      );
    }

    if (compressedBytes.isEmpty) {
      throw Exception('Gagal memproses gambar. Silakan coba foto lain.');
    }

    if (compressedBytes.lengthInBytes > _hardLimitBytes) {
      throw Exception(
        'Ukuran foto terlalu besar setelah dikompresi. Gunakan foto dengan detail lebih sederhana.',
      );
    }

    return base64Encode(compressedBytes);
  }

  /// Mengubah String Base64 dari Firestore kembali menjadi Uint8List untuk Image.memory().
  /// Mengembalikan null jika string kosong atau rusak.
  Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) {
      return null;
    }

    try {
      // Bersihkan prefix data URI jika ada (misal: "data:image/jpeg;base64,")
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(cleanBase64.trim());
    } catch (_) {
      return null;
    }
  }
}