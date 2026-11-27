import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../models/report_model.dart';

class FirestoreSeeder {
  // Gambar PNG 1x1 piksel valid dalam Base64 agar image viewer tidak error
  static const String _dummyBase64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  /// Jalankan sekali untuk mengisi master aset dan laporan dengan cakupan
  /// seluruh skenario pengujian aplikasi (semua 6 status, SLA, re-open,
  /// aset tanpa ruangan, fasilitas lainnya, & multi-riwayat pada 1 aset).
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

    // 1. Ambil akun admin, pelapor, & teknisi yang sudah ada di Firestore `users`
    // agar tiket contoh langsung terhubung ke akun pengujianmu.
    String adminNama = 'Admin SnaFix';
    String pelaporId = 'dummy_pelapor';
    String pelaporNama = 'Pelapor Mahasiswa';
    String teknisiId = 'dummy_teknisi';
    String teknisiNama = 'Teknisi SnaFix';

    final usersSnapshot = await db.collection('users').get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? '';
      final nama = (data['nama'] as String? ?? '').trim();

      if (role == 'admin' && nama.isNotEmpty && adminNama == 'Admin SnaFix') {
        adminNama = nama;
      } else if (role == 'pelapor' && pelaporId == 'dummy_pelapor') {
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
    final aparGedungARef = assetsRef.doc();
    final proyLab1Ref = assetsRef.doc();
    final pcLab1_01Ref = assetsRef.doc();
    final pcLab1_02Ref = assetsRef.doc();
    final panelB1Ref = assetsRef.doc();
    final lampuLobbyBRef = assetsRef.doc();
    final kursiC302_01Ref = assetsRef.doc();
    final kursiC302_02Ref = assetsRef.doc();
    final kursiC302_03Ref = assetsRef.doc();

    final assets = [
      // Gedung A (Ruangan spesifik + 1 aset area umum tanpa ruangan)
      AssetModel(
        id: acR204Ref.id,
        nama: 'AC Daikin 2 PK',
        kategori: 'Elektronik',
        gedung: 'Gedung A',
        ruangan: 'Ruang 204',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AssetModel(
        id: kursiA204Ref.id,
        nama: 'Kursi Kuliah#01',
        kategori: 'Inventaris',
        gedung: 'Gedung A',
        ruangan: 'Ruang 204',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      AssetModel(
        id: kranWc1Ref.id,
        nama: 'Kran Wastafel Lantai 1',
        kategori: 'Sanitasi',
        gedung: 'Gedung A',
        ruangan: 'Toilet Lt. 1',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // Contoh aset TANPA ruangan (ruangan == '') -> tes filter "Tanpa Ruangan" & Area Umum
      AssetModel(
        id: aparGedungARef.id,
        nama: 'APAR Koridor#01',
        kategori: 'Lainnya',
        gedung: 'Gedung A',
        ruangan: '',
        createdAt: now.subtract(const Duration(days: 20)),
      ),

      // Gedung B (Lab + Kelistrikan + 1 aset area umum tanpa ruangan)
      AssetModel(
        id: proyLab1Ref.id,
        nama: 'Proyektor Epson EB-X500',
        kategori: 'Elektronik',
        gedung: 'Gedung B',
        ruangan: 'Lab Komputer 1',
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      AssetModel(
        id: pcLab1_01Ref.id,
        nama: 'PC All-in-One#01',
        kategori: 'Elektronik',
        gedung: 'Gedung B',
        ruangan: 'Lab Komputer 1',
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      // Aset tanpa riwayat laporan -> tes empty state di HistoryAssetScreen
      AssetModel(
        id: pcLab1_02Ref.id,
        nama: 'PC All-in-One#02',
        kategori: 'Elektronik',
        gedung: 'Gedung B',
        ruangan: 'Lab Komputer 1',
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      AssetModel(
        id: panelB1Ref.id,
        nama: 'Panel MCB Utama Lt. 1',
        kategori: 'Kelistrikan',
        gedung: 'Gedung B',
        ruangan: 'Koridor Lt. 1',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      AssetModel(
        id: lampuLobbyBRef.id,
        nama: 'Lampu Sorot Lobi Utama',
        kategori: 'Kelistrikan',
        gedung: 'Gedung B',
        ruangan: '',
        createdAt: now.subtract(const Duration(days: 15)),
      ),

      // Gedung C (Contoh batch 3 kursi berurutan)
      AssetModel(
        id: kursiC302_01Ref.id,
        nama: 'Kursi Kuliah#01',
        kategori: 'Inventaris',
        gedung: 'Gedung C',
        ruangan: 'Ruang 302',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      AssetModel(
        id: kursiC302_02Ref.id,
        nama: 'Kursi Kuliah#02',
        kategori: 'Inventaris',
        gedung: 'Gedung C',
        ruangan: 'Ruang 302',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      AssetModel(
        id: kursiC302_03Ref.id,
        nama: 'Kursi Kuliah#03',
        kategori: 'Inventaris',
        gedung: 'Gedung C',
        ruangan: 'Ruang 302',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    ];

    for (final asset in assets) {
      batch.set(assetsRef.doc(asset.id), asset.toMap());
    }

    // 3. Seed 10 tiket laporan yang mencakup SEMUA skenario aplikasi
    final reports = [
      // SKENARIO 1: `reported` (Aset terdaftar)
      // Tes: Admin (Tolak / Verifikasi & Tugaskan) & Pelapor (Batalkan Laporan)
      ReportModel(
        id: '',
        assetId: kranWc1Ref.id,
        assetNama: 'Kran Wastafel Lantai 1',
        assetLokasi: 'Gedung A - Toilet Lt. 1',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        deskripsi: 'Kran air patah dan air terus mengalir deras saat keran dibuka.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.reported,
        createdAt: now.subtract(const Duration(hours: 2)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),

      // SKENARIO 2: `reported` (Fasilitas Lainnya / assetId: null)
      // Tes: HistoryAssetScreen state "Belum Terdaftar" + Admin tombol "Daftarkan sebagai Aset Baru"
      ReportModel(
        id: '',
        assetId: null,
        assetNama: 'Keramik Koridor Lantai 2',
        assetLokasi: 'Gedung B - Koridor Lt. 2',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        deskripsi:
            'Beberapa ubin keramik terangkat dan retak di dekat tangga utama, rawan tersandung.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.reported,
        createdAt: now.subtract(const Duration(hours: 1)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),

      // SKENARIO 3: `verified` (Sudah diverifikasi + SLA, tapi belum ditugaskan teknisi)
      // Tes: Admin tombol "Tugaskan Teknisi"
      ReportModel(
        id: '',
        assetId: panelB1Ref.id,
        assetNama: 'Panel MCB Utama Lt. 1',
        assetLokasi: 'Gedung B - Koridor Lt. 1',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        deskripsi:
            'Saklar MCB sering turun sendiri saat AC dan proyektor dinyalakan bersamaan.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.verified,
        prioritas: ReportPriority.sedang,
        deadlineAt: now.add(const Duration(hours: 60)),
        createdAt: now.subtract(const Duration(hours: 12)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 12)),
          ),
          StatusHistoryItem(
            status: ReportStatus.verified,
            catatan: 'Prioritas Sedang • Menunggu penugasan teknisi.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(hours: 10)),
          ),
        ],
      ),

      // SKENARIO 4: `assigned` (Normal, SLA aman) — di aset AC Daikin 2 PK (multi-riwayat)
      // Tes: Teknisi tombol "Mulai Kerjakan", Admin "Alihkan Teknisi", & banner tiket aktif di HistoryAssetScreen
      ReportModel(
        id: '',
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'AC tidak dingin sama sekali dan lampu indikator timer berkedip.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.assigned,
        prioritas: ReportPriority.tinggi,
        deadlineAt: now.add(const Duration(hours: 18)),
        createdAt: now.subtract(const Duration(hours: 6)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Tinggi • Teknisi: $teknisiNama.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
        ],
      ),

      // SKENARIO 5: `assigned` (Hasil Re-open / Belum Beres & OVERDUE SLA)
      // Tes: Timeline riwayat re-open & tenggat SLA tetap berjalan (tidak di-reset)
      ReportModel(
        id: '',
        assetId: pcLab1_01Ref.id,
        assetNama: 'PC All-in-One#01',
        assetLokasi: 'Gedung B - Lab Komputer 1',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'Layar berkedip parah lalu mati total setelah 5 menit digunakan.',
        fotoSebelum: _dummyBase64Image,
        fotoSesudah: _dummyBase64Image,
        catatanTeknisi: 'Kabel daya internal sudah dikencangkan ulang.',
        status: ReportStatus.assigned,
        prioritas: ReportPriority.sedang,
        deadlineAt: now.subtract(const Duration(hours: 8)),
        isConfirmed: false,
        createdAt: now.subtract(const Duration(days: 4)),
        resolvedAt: null,
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(days: 4)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Sedang • Teknisi: $teknisiNama.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(days: 3, hours: 20)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan: 'Catatan: Kabel daya internal sudah dikencangkan ulang.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(days: 1, hours: 12)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan:
                'Diajukan ulang: Setelah dinyalakan 10 menit layar kembali mati.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 10)),
          ),
        ],
      ),

      // SKENARIO 6: `inProgress` & OVERDUE SLA
      // Tes: Peringatan Overdue SLA, Teknisi tombol "Selesaikan Tugas", & Admin "Alihkan Teknisi"
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
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 28)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Tinggi • Teknisi: $teknisiNama.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(hours: 26)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),

      // SKENARIO 7: `resolved` BELUM dikonfirmasi (`isConfirmed: false`)
      // Tes: Pelapor & Admin (Supervisor Override) tombol "Konfirmasi Selesai" / "Belum Beres"
      ReportModel(
        id: '',
        assetId: kursiC302_01Ref.id,
        assetNama: 'Kursi Kuliah#01',
        assetLokasi: 'Gedung C - Ruang 302',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'Meja lipat pada kursi lepas baut engselnya sehingga miring.',
        fotoSebelum: _dummyBase64Image,
        fotoSesudah: _dummyBase64Image,
        catatanTeknisi:
            'Baut engsel meja sudah diganti baru dan dikencangkan.',
        status: ReportStatus.resolved,
        prioritas: ReportPriority.rendah,
        deadlineAt: now.add(const Duration(days: 4)),
        isConfirmed: false,
        createdAt: now.subtract(const Duration(days: 2)),
        resolvedAt: now.subtract(const Duration(hours: 4)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Rendah • Teknisi: $teknisiNama.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(days: 1, hours: 18)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan:
                'Catatan: Baut engsel meja sudah diganti baru dan dikencangkan.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),

      // SKENARIO 8: `resolved` SUDAH dikonfirmasi (`isConfirmed: true`) — di aset AC Daikin 2 PK
      // Tes: Lencana "Terkonfirmasi", status final tanpa tombol aksi, & filter "Selesai" di HistoryAssetScreen
      ReportModel(
        id: '',
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'Air kondensasi AC menetes deras ke lantai ruang kelas.',
        fotoSebelum: _dummyBase64Image,
        fotoSesudah: _dummyBase64Image,
        catatanTeknisi:
            'Saluran pembuangan air dibersihkan dari lumut dan filter dicuci.',
        status: ReportStatus.resolved,
        prioritas: ReportPriority.sedang,
        deadlineAt: now.subtract(const Duration(days: 10)),
        isConfirmed: true,
        createdAt: now.subtract(const Duration(days: 14)),
        resolvedAt: now.subtract(const Duration(days: 12)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(days: 14)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Sedang • Teknisi: $teknisiNama.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(days: 13, hours: 20)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(days: 12, hours: 3)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan:
                'Catatan: Saluran pembuangan air dibersihkan dari lumut dan filter dicuci.',
            updatedBy: teknisiNama,
            timestamp: now.subtract(const Duration(days: 12)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan: 'Hasil perbaikan dikonfirmasi.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(days: 11, hours: 18)),
          ),
        ],
      ),

      // SKENARIO 9: `rejected` (Ditolak dengan alasan) — di aset AC Daikin 2 PK
      // Tes: Kartu Alasan Penolakan di DetailLaporanScreen & memastikan TIDAK tampil di HistoryAssetScreen
      ReportModel(
        id: '',
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        deskripsi: 'AC mati total tidak mau menyala.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.rejected,
        rejectionReason:
            'Laporan duplikat dengan tiket aktif pada unit AC Daikin 2 PK yang sudah ditangani.',
        createdAt: now.subtract(const Duration(hours: 4)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
          StatusHistoryItem(
            status: ReportStatus.rejected,
            catatan:
                'Alasan: Laporan duplikat dengan tiket aktif pada unit AC Daikin 2 PK yang sudah ditangani.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),

      // SKENARIO 10: Laporan pada aset area umum TANPA ruangan (`ruangan == ''`)
      // Tes: Tampilan `assetLokasi` hanya nama gedung ("Gedung B") tanpa tanda "-"
      ReportModel(
        id: '',
        assetId: lampuLobbyBRef.id,
        assetNama: 'Lampu Sorot Lobi Utama',
        assetLokasi: 'Gedung B',
        pelaporId: pelaporId,
        pelaporNama: pelaporNama,
        teknisiId: teknisiId,
        teknisiNama: teknisiNama,
        deskripsi: 'Satu lampu sorot di plafon lobi mati sehingga area masuk gelap.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.assigned,
        prioritas: ReportPriority.rendah,
        deadlineAt: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 1)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: pelaporNama,
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Rendah • Teknisi: $teknisiNama.',
            updatedBy: adminNama,
            timestamp: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
    ];

    for (final report in reports) {
      batch.set(reportsRef.doc(), report.toMap());
    }

    await batch.commit();
    debugPrint(
      'SEEDER SELESAI! ${assets.length} aset & ${reports.length} laporan (semua skenario) berhasil dibuat.',
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