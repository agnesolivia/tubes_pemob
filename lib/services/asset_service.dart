import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset_model.dart';

/// Model input sementara untuk setiap baris barang pada form tambah aset massal/multi-item.
class AssetBatchItem {
  final String nama;
  final String kategori;
  final int jumlah;

  const AssetBatchItem({
    required this.nama,
    required this.kategori,
    this.jumlah = 1,
  });
}

class AssetService {
  AssetService._();

  static final AssetService instance = AssetService._();

  static const int maxBatchUnits = 500;

  final CollectionReference _assetsRef = FirebaseFirestore.instance.collection(
    'assets',
  );

  /// Cari satu aset berdasarkan Auto-ID hasil scan QR (setelah prefix 'ASSET:' dilepas).
  /// Mengembalikan null jika ID aset tidak terdaftar di database.
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
      final assets = snapshot.docs
          .map((doc) => AssetModel.fromFirestore(doc))
          .toList();

      assets.sort((a, b) {
        final gedungCmp = a.gedung.toLowerCase().compareTo(
          b.gedung.toLowerCase(),
        );
        if (gedungCmp != 0) return gedungCmp;

        final ruangCmp = a.ruangan.toLowerCase().compareTo(
          b.ruangan.toLowerCase(),
        );
        if (ruangCmp != 0) return ruangCmp;

        return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
      });

      return assets;
    });
  }

  /// Tambah satu master aset baru menggunakan Auto-ID Firestore.
  /// Mengembalikan [AssetModel] lengkap dengan [id] yang baru dibuat.
  Future<AssetModel> createAsset(AssetModel asset) async {
    final created = await createMultipleAssets(
      gedung: asset.gedung,
      ruangan: asset.ruangan,
      items: [
        AssetBatchItem(nama: asset.nama, kategori: asset.kategori, jumlah: 1),
      ],
    );
    return created.first;
  }

  /// Tambah banyak aset sekaligus (campuran satuan & batch) dalam satu gedung/ruangan
  /// menggunakan WriteBatch Firestore (maksimal 500 total unit per simpan).
  /// Parameter [ruangan] bersifat opsional (boleh kosong untuk area umum gedung).
  Future<List<AssetModel>> createMultipleAssets({
    required String gedung,
    String ruangan = '',
    required List<AssetBatchItem> items,
  }) async {
    final normalizedGedung = _normalizeText(gedung);
    final normalizedRuangan = _normalizeText(ruangan);

    if (normalizedGedung.isEmpty) {
      throw Exception('Nama gedung tidak boleh kosong.');
    }
    if (items.isEmpty) {
      throw Exception('Daftar aset yang akan ditambahkan tidak boleh kosong.');
    }

    int totalUnits = 0;
    for (final item in items) {
      if (item.jumlah < 1) {
        throw Exception('Jumlah unit minimal 1 untuk setiap baris aset.');
      }
      totalUnits += item.jumlah;
    }

    if (totalUnits > maxBatchUnits) {
      throw Exception(
        'Total unit dalam satu kali simpan maksimal $maxBatchUnits unit (saat ini: $totalUnits unit).',
      );
    }

    // Ambil snapshot aset sekali untuk mencocokkan ejaan gedung/ruangan
    // sekaligus mengecek duplikat nama & nomor urut terakhir di lokasi terkait.
    final snapshot = await _assetsRef.get();

    String canonicalGedung = normalizedGedung;
    String canonicalRuangan = normalizedRuangan;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final existingGedung = (data['gedung'] as String? ?? '').trim();
      final existingRuangan = (data['ruangan'] as String? ?? '').trim();

      if (existingGedung.toLowerCase() == normalizedGedung.toLowerCase()) {
        canonicalGedung = existingGedung;
        if (normalizedRuangan.isNotEmpty &&
            existingRuangan.toLowerCase() == normalizedRuangan.toLowerCase()) {
          canonicalRuangan = existingRuangan;
          break;
        }
      }
    }

    // Kumpulkan nama aset yang sudah ada & nomor tertinggi (#Max) khusus di (gedung, ruangan) ini
    final Set<String> existingNamesLower = {};
    final Map<String, int> maxNumberByBaseLower = {};
    final suffixPattern = RegExp(r'^(.+)#(\d+)$');

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final existingGedung = (data['gedung'] as String? ?? '').trim();
      final existingRuangan = (data['ruangan'] as String? ?? '').trim();

      if (existingGedung.toLowerCase() == canonicalGedung.toLowerCase() &&
          existingRuangan.toLowerCase() == canonicalRuangan.toLowerCase()) {
        final existingNama = (data['nama'] as String? ?? '').trim();
        if (existingNama.isEmpty) continue;

        existingNamesLower.add(existingNama.toLowerCase());

        final match = suffixPattern.firstMatch(existingNama);
        if (match != null) {
          final baseLower = match.group(1)!.trim().toLowerCase();
          final numVal = int.tryParse(match.group(2)!) ?? 0;
          final currentMax = maxNumberByBaseLower[baseLower] ?? 0;
          if (numVal > currentMax) {
            maxNumberByBaseLower[baseLower] = numVal;
          }
        }
      }
    }

    final WriteBatch batch = FirebaseFirestore.instance.batch();
    final List<AssetModel> createdAssets = [];
    final DateTime now = DateTime.now();
    final lokasiLabel = _formatLokasi(canonicalGedung, canonicalRuangan);

    for (final item in items) {
      final cleanNama = _normalizeText(item.nama);
      final cleanKategori = _normalizeText(item.kategori);

      if (cleanNama.isEmpty) {
        throw Exception('Nama aset tidak boleh kosong.');
      }
      if (cleanKategori.isEmpty) {
        throw Exception('Kategori untuk aset "$cleanNama" tidak boleh kosong.');
      }

      if (item.jumlah == 1) {
        // Mode satuan: karakter '#' diizinkan (misal menyisipkan ulang 'Kursi#02')
        final nameLower = cleanNama.toLowerCase();
        if (existingNamesLower.contains(nameLower)) {
          throw Exception('Aset "$cleanNama" sudah terdaftar di $lokasiLabel.');
        }

        existingNamesLower.add(nameLower);

        // Jika nama satuan memakai format '<Basis>#<Angka>', perbarui tracker Max
        final match = suffixPattern.firstMatch(cleanNama);
        if (match != null) {
          final baseLower = match.group(1)!.trim().toLowerCase();
          final numVal = int.tryParse(match.group(2)!) ?? 0;
          if (numVal > (maxNumberByBaseLower[baseLower] ?? 0)) {
            maxNumberByBaseLower[baseLower] = numVal;
          }
        }

        final docRef = _assetsRef.doc();
        final newAsset = AssetModel(
          id: docRef.id,
          nama: cleanNama,
          kategori: cleanKategori,
          gedung: canonicalGedung,
          ruangan: canonicalRuangan,
          createdAt: now,
        );

        batch.set(docRef, newAsset.toMap());
        createdAssets.add(newAsset);
      } else {
        // Mode batch (jumlah > 1): karakter '#' dilarang pada nama dasar
        if (cleanNama.contains('#')) {
          final suggestedBase = cleanNama.split('#').first.trim();
          throw Exception(
            'Karakter "#" ditambahkan otomatis oleh sistem untuk input massal. '
            'Masukkan nama dasar tanpa "#" (contoh: ${suggestedBase.isEmpty ? 'Kursi' : suggestedBase}).',
          );
        }

        final baseLower = cleanNama.toLowerCase();
        final int startNumber = (maxNumberByBaseLower[baseLower] ?? 0) + 1;
        final int endNumber = startNumber + item.jumlah - 1;
        final int padWidth = endNumber >= 100 ? 3 : 2;

        for (int i = startNumber; i <= endNumber; i++) {
          final suffix = i.toString().padLeft(padWidth, '0');
          final generatedName = '$cleanNama#$suffix';
          final generatedLower = generatedName.toLowerCase();

          if (existingNamesLower.contains(generatedLower)) {
            throw Exception(
              'Aset "$generatedName" sudah terdaftar di $lokasiLabel.',
            );
          }

          existingNamesLower.add(generatedLower);

          final docRef = _assetsRef.doc();
          final newAsset = AssetModel(
            id: docRef.id,
            nama: generatedName,
            kategori: cleanKategori,
            gedung: canonicalGedung,
            ruangan: canonicalRuangan,
            createdAt: now,
          );

          batch.set(docRef, newAsset.toMap());
          createdAssets.add(newAsset);
        }

        maxNumberByBaseLower[baseLower] = endNumber;
      }
    }

    await batch.commit();
    return createdAssets;
  }

  /// Perbarui data detail aset (Nama, Kategori, Gedung, dan Ruangan opsional)
  /// dengan normalisasi lokasi & validasi nama unik per lokasi.
  Future<void> updateAsset(AssetModel asset) async {
    final cleanNama = _normalizeText(asset.nama);
    final cleanKategori = _normalizeText(asset.kategori);
    final normalizedGedung = _normalizeText(asset.gedung);
    final normalizedRuangan = _normalizeText(asset.ruangan);

    if (cleanNama.isEmpty ||
        cleanKategori.isEmpty ||
        normalizedGedung.isEmpty) {
      throw Exception('Nama aset, kategori, dan gedung wajib diisi.');
    }

    final snapshot = await _assetsRef.get();

    String canonicalGedung = normalizedGedung;
    String canonicalRuangan = normalizedRuangan;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final existingGedung = (data['gedung'] as String? ?? '').trim();
      final existingRuangan = (data['ruangan'] as String? ?? '').trim();

      if (existingGedung.toLowerCase() == normalizedGedung.toLowerCase()) {
        canonicalGedung = existingGedung;
        if (normalizedRuangan.isNotEmpty &&
            existingRuangan.toLowerCase() == normalizedRuangan.toLowerCase()) {
          canonicalRuangan = existingRuangan;
          break;
        }
      }
    }

    final lokasiLabel = _formatLokasi(canonicalGedung, canonicalRuangan);

    // Pastikan nama baru tidak bentrok dengan aset lain di (gedung, ruangan) yang sama
    for (final doc in snapshot.docs) {
      if (doc.id == asset.id) continue;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final existingGedung = (data['gedung'] as String? ?? '').trim();
      final existingRuangan = (data['ruangan'] as String? ?? '').trim();
      final existingNama = (data['nama'] as String? ?? '').trim();

      if (existingGedung.toLowerCase() == canonicalGedung.toLowerCase() &&
          existingRuangan.toLowerCase() == canonicalRuangan.toLowerCase() &&
          existingNama.toLowerCase() == cleanNama.toLowerCase()) {
        throw Exception('Aset "$cleanNama" sudah terdaftar di $lokasiLabel.');
      }
    }

    await _assetsRef.doc(asset.id).update({
      'nama': cleanNama,
      'kategori': cleanKategori,
      'gedung': canonicalGedung,
      'ruangan': canonicalRuangan,
    });
  }

  /// Hapus data master aset.
  Future<void> deleteAsset(String assetId) async {
    await _assetsRef.doc(assetId).delete();
  }

  /// Helper UI: Ekstrak daftar gedung unik (deduplikasi case-insensitive).
  List<String> extractUniqueGedung(List<AssetModel> assets) {
    final Map<String, String> uniqueMap = {};
    for (final asset in assets) {
      final clean = asset.gedung.trim();
      if (clean.isEmpty) continue;
      uniqueMap.putIfAbsent(clean.toLowerCase(), () => clean);
    }
    return uniqueMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Helper UI: Ekstrak daftar ruangan unik non-kosong di dalam [gedung] tertentu (case-insensitive).
  List<String> extractUniqueRuangan(List<AssetModel> assets, String gedung) {
    final targetGedungLower = gedung.trim().toLowerCase();
    if (targetGedungLower.isEmpty) return [];

    final Map<String, String> uniqueMap = {};
    for (final asset in assets) {
      if (asset.gedung.trim().toLowerCase() != targetGedungLower) continue;
      final cleanRuangan = asset.ruangan.trim();
      if (cleanRuangan.isEmpty) continue;
      uniqueMap.putIfAbsent(cleanRuangan.toLowerCase(), () => cleanRuangan);
    }
    return uniqueMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  String _formatLokasi(String gedung, String ruangan) {
    return ruangan.trim().isEmpty ? gedung : '$gedung - $ruangan';
  }

  /// Merapikan spasi berlebih & mengkapitalisasi awal tiap kata tanpa merusak singkatan (misal: "AC", "PC").
  String _normalizeText(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return '';

    return cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}
