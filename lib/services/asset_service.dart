import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset_model.dart';

class AssetService {
  AssetService._();

  static final AssetService instance = AssetService._();

  final CollectionReference _assetsRef =
      FirebaseFirestore.instance.collection('assets');

  /// Cari satu aset berdasarkan ID hasil scan QR (misal: 'AC-R204').
  /// Mengembalikan null jika kode QR tidak terdaftar di database.
  Future<AssetModel?> getAssetById(String assetId) async {
    final cleanId = assetId.trim();
    if (cleanId.isEmpty || cleanId.contains('/')) return null;

    final doc = await _assetsRef.doc(cleanId).get();
    if (!doc.exists) return null;
    return AssetModel.fromFirestore(doc);
  }

  /// Stream seluruh daftar aset (untuk Kelola Aset Admin & Dropdown Lapor Manual).
  /// Diurutkan otomatis berdasarkan Gedung -> Ruangan -> Nama Aset.
  Stream<List<AssetModel>> streamAllAssets() {
    return _assetsRef.snapshots().map((snapshot) {
      final assets =
          snapshot.docs.map((doc) => AssetModel.fromFirestore(doc)).toList();

      assets.sort((a, b) {
        final gedungCmp =
            a.gedung.toLowerCase().compareTo(b.gedung.toLowerCase());
        if (gedungCmp != 0) return gedungCmp;

        final ruangCmp =
            a.ruangan.toLowerCase().compareTo(b.ruangan.toLowerCase());
        if (ruangCmp != 0) return ruangCmp;

        return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
      });

      return assets;
    });
  }

  /// Tambah master aset baru dengan ID kustom (wajib pakai .doc(id).set).
  Future<void> createAsset(AssetModel asset) async {
    final cleanId = asset.id.trim();

    if (cleanId.isEmpty) {
      throw Exception('Kode aset tidak boleh kosong.');
    }
    if (cleanId.contains('/')) {
      throw Exception(
        'Kode aset tidak boleh mengandung tanda garis miring (/). Gunakan tanda hubung (-).',
      );
    }

    final docRef = _assetsRef.doc(cleanId);
    final existing = await docRef.get();

    if (existing.exists) {
      throw Exception('Kode aset "$cleanId" sudah terdaftar.');
    }

    await docRef.set(asset.toMap());
  }

  /// Perbarui data detail aset (Nama, Kategori, Gedung, Ruangan).
  Future<void> updateAsset(AssetModel asset) async {
    await _assetsRef.doc(asset.id).update({
      'nama': asset.nama.trim(),
      'kategori': asset.kategori.trim(),
      'gedung': asset.gedung.trim(),
      'ruangan': asset.ruangan.trim(),
    });
  }

  /// Hapus data master aset.
  Future<void> deleteAsset(String assetId) async {
    await _assetsRef.doc(assetId).delete();
  }
}