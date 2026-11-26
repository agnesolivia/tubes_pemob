import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../models/report_model.dart';

class FirestoreSeeder {
  // Gambar PNG 1x1 piksel valid dalam Base64 agar Base64ImageViewer tidak error
  static const String _dummyBase64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  /// Jalankan sekali untuk mengisi master aset (Auto-ID + contoh batch '#')
  /// dan tiket laporan dengan variasi status.
  ///
  /// Set [forceReset] ke `true` jika ingin menghapus data `assets` & `reports`
  /// lama lalu mengisinya ulang dengan data contoh terbaru.
  static Future<void> seedAll({bool forceReset = false}) async {
    final db = FirebaseFirestore.instance;
    final assetsRef = db.collection('assets');
    final reportsRef = db.collection('reports');

    if (forceReset) {
      await _clearCollection(assetsRef);
      await _clearCollection(reportsRef);
    } else {
      final existingAssets = await assetsRef.limit(1).get();
      if (existingAssets.docs.isNotEmpty) {
        debugPrint(
          'SEEDER DILEWATI: Koleksi assets sudah terisi. '
          'Gunakan seedAll(forceReset: true) jika ingin mereset data contoh.',
        );
        return;
      }
    }

    // 1. Ambil akun pelapor & teknisi yang sudah ada di Firestore `users` (jika ada)
    // agar tiket contoh langsung terhubung ke akun pengujianmu.
    String pelaporId = 'dummy_pelapor';
    String pelaporNama = 'Budi Pelapor';
    String teknisiId = 'dummy_teknisi';
    String teknisiNama = 'Andi Teknisi';

    final usersSnapshot = await db.collection('users').get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? '';
      final nama = (data['nama'] as String? ?? '').trim();

      if (role == 'pelapor' && pelaporId == 'dummy_pelapor') {
        pelaporId = doc.id;
        if (nama.isNotEmpty) pelaporNama = nama;
      } else if (role == 'teknisi' && teknisiId == 'dummy_teknisi') {
        teknisiId = doc.id;
        if (nama.isNotEmpty) teknisiNama = nama;
      }
    }

    final now = DateTime.now();
    final batch = db.batch();

    // 2. Siapkan dokumen master aset menggunakan Auto-ID Firestore
    final acR204Ref = assetsRef.doc();
    final kursiA204Ref = assetsRef.doc();
    final kranWc1Ref = assetsRef.doc();
    final proyLab1Ref = assetsRef.doc();
    final pcLab1_01Ref = assetsRef.doc();
    final pcLab1_02Ref = assetsRef.doc();
    final panelB1Ref = assetsRef.doc();
    final kursiC302_01Ref = assetsRef.doc();
    final kursiC302_02Ref = assetsRef.doc();
    final kursiC302_03Ref = assetsRef.doc();

    final assets = [
      // Gedung A
      AssetModel(
        id: acR204Ref.id,
        nama: 'AC Daikin 2 PK',
        kategori: 'Elektronik',
        gedung: 'Gedung A',
        ruangan: 'Ruang 204',
        createdAt: now,
      ),
      AssetModel(
        id: kursiA204Ref.id,
        nama: 'Kursi Kuliah#01',
        kategori: 'Inventaris',
        gedung: 'Gedung A',
        ruangan: 'Ruang 204',
        createdAt: now,
      ),
      AssetModel(
        id: kranWc1Ref.id,
        nama: 'Kran Wastafel Lantai 1',
        kategori: 'Sanitasi',
        gedung: 'Gedung A',
        ruangan: 'Toilet Lt. 1',
        createdAt: now,
      ),

      // Gedung B
      AssetModel(
        id: proyLab1Ref.id,
        nama: 'Proyektor Epson EB-X500',
        kategori: 'Elektronik',
        gedung: 'Gedung B',
        ruangan: 'Lab Komputer 1',
        createdAt: now,
      ),
      AssetModel(
        id: pcLab1_01Ref.id,
        nama: 'PC All-in-One#01',
        kategori: 'Elektronik',
        gedung: 'Gedung B',
        ruangan: 'Lab Komputer 1',
        createdAt: now,
      ),
      AssetModel(
        id: pcLab1_02Ref.id,
        nama: 'PC All-in-One#02',
        kategori: 'Elektronik',
        gedung: 'Gedung B',
        ruangan: 'Lab Komputer 1',
        createdAt: now,
      ),
      AssetModel(
        id: panelB1Ref.id,
        nama: 'Panel MCB Utama Lt. 1',
        kategori: 'Kelistrikan',
        gedung: 'Gedung B',
        ruangan: 'Koridor Lt. 1',
        createdAt: now,
      ),

      // Gedung C (Contoh batch 3 kursi berurutan)
      AssetModel(
        id: kursiC302_01Ref.id,
        nama: 'Kursi Kuliah#01',
        kategori: 'Inventaris',
        gedung: 'Gedung C',
        ruangan: 'Ruang 302',
        createdAt: now,
      ),
      AssetModel(
        id: kursiC302_02Ref.id,
        nama: 'Kursi Kuliah#02',
        kategori: 'Inventaris',
        gedung: 'Gedung C',
        ruangan: 'Ruang 302',
        createdAt: now,
      ),
      AssetModel(
        id: kursiC302_03Ref.id,
        nama: 'Kursi Kuliah#03',
        kategori: 'Inventaris',
        gedung: 'Gedung C',
        ruangan: 'Ruang 302',
        createdAt: now,
      ),
    ];

    for (final asset in assets) {
      batch.set(assetsRef.doc(asset.id), asset.toMap());
    }

    // 3. Seed 5 tiket laporan dengan variasi status + 1 contoh Fasilitas Lainnya (assetId: null)
    final reports = [
      // 1) Status: reported (Aset terdaftar - untuk tes Verifikasi / Tolak oleh Admin)
      ReportModel(
        id: '',
        assetId: kranWc1Ref.id,
        assetNama: 'Kran Wastafel Lantai 1',
        assetLokasi: 'Gedung A - Toilet Lt. 1',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        deskripsi: 'Kran air patah dan air terus mengalir deras.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.reported,
        createdAt: now.subtract(const Duration(hours: 2)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim oleh pelapor.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),

      // 2) Status: reported (Fasilitas Lainnya / assetId: null)
      ReportModel(
        id: '',
        assetId: null,
        assetNama: 'Keramik Koridor Lantai 2',
        assetLokasi: 'Gedung B - Koridor Lt. 2',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        deskripsi:
            'Beberapa ubin keramik terangkat dan retak di dekat tangga utama.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.reported,
        createdAt: now.subtract(const Duration(hours: 1)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim oleh pelapor.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),

      // 3) Status: assigned (untuk tes Mulai Kerjakan oleh Teknisi)
      ReportModel(
        id: '',
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'AC tidak dingin sama sekali dan lampu timer berkedip.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.assigned,
        prioritas: ReportPriority.tinggi,
        deadlineAt: now.add(const Duration(hours: 18)),
        createdAt: now.subtract(const Duration(hours: 6)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim oleh pelapor.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan:
                'Diverifikasi (Prioritas Tinggi) & ditugaskan ke $teknisiNama.',
            updatedBy: 'Admin Sarpras',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
        ],
      ),

      // 4) Status: inProgress & OVERDUE SLA (untuk tes peringatan Overdue + Selesaikan Tugas)
      ReportModel(
        id: '',
        assetId: proyLab1Ref.id,
        assetNama: 'Proyektor Epson EB-X500',
        assetLokasi: 'Gedung B - Lab Komputer 1',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi:
            'Tampilan proyektor buram kekuningan dan mati sendiri setelah 10 menit.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.inProgress,
        prioritas: ReportPriority.tinggi,
        deadlineAt: now.subtract(const Duration(hours: 3)),
        createdAt: now.subtract(const Duration(hours: 28)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim oleh pelapor.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 28)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Teknisi mulai mengerjakan perbaikan di lokasi.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),

      // 5) Status: resolved (untuk tes Konfirmasi Selesai / Re-open oleh Pelapor)
      ReportModel(
        id: '',
        assetId: kursiC302_01Ref.id,
        assetNama: 'Kursi Kuliah#01',
        assetLokasi: 'Gedung C - Ruang 302',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'Meja lipat pada kursi lepas baut engselnya.',
        fotoSebelum: _dummyBase64Image,
        fotoSesudah: _dummyBase64Image,
        catatanTeknisi:
            'Baut engsel meja sudah diganti baru dan dikencangkan.',
        status: ReportStatus.resolved,
        prioritas: ReportPriority.rendah,
        deadlineAt: now.add(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 2)),
        resolvedAt: now.subtract(const Duration(hours: 4)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan:
                'Perbaikan selesai: Baut engsel meja sudah diganti baru dan dikencangkan.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
    ];

    for (final report in reports) {
      batch.set(reportsRef.doc(), report.toMap());
    }

    await batch.commit();
    debugPrint(
      'SEEDER SELESAI! ${assets.length} aset & ${reports.length} laporan berhasil dibuat.',
    );
  }

  static Future<void> _clearCollection(CollectionReference ref) async {
    final snapshot = await ref.get();
    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}