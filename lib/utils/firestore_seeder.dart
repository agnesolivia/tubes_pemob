import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../models/notification_model.dart';
import '../models/report_model.dart';

class FirestoreSeeder {
  // Gambar PNG 1x1 piksel valid dalam Base64 agar image viewer tidak error
  static const String _dummyBase64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  /// Jalankan sekali untuk mengisi master aset, laporan, dan notifikasi contoh
  /// yang mencakup seluruh skenario pengujian aplikasi (6 status, SLA, re-open,
  /// aset tanpa ruangan, fasilitas lainnya, multi-riwayat, & notifikasi lintas role).
  ///
  /// Set [forceReset] ke `true` jika ingin menghapus data `assets` & `reports`
  /// lama lalu mengisinya ulang dengan data contoh terbaru.
  /// (Catatan: koleksi `notifications` tidak dihapus otomatis karena Security
  /// Rules tidak mengizinkan `delete` dari client.)
  static Future<void> seedAll({bool forceReset = false}) async {
    final db = FirebaseFirestore.instance;
    final assetsRef = db.collection('assets');
    final reportsRef = db.collection('reports');
    final notifRef = db.collection('notifications');

    if (forceReset) {
      await _clearCollection(assetsRef);
      await _clearCollection(reportsRef);
    } else {
      final existingAssets = await assetsRef.limit(1).get();
      if (existingAssets.docs.isNotEmpty) {
        debugPrint(
          'SEEDER DILEWATI: Koleksi assets sudah terisi. '
          'Gunakan seedAll(forceReset: true) jika ingin mereset data contoh, '
          'atau seedNotificationsFromExistingReports() untuk mengisi notifikasi saja.',
        );
        return;
      }
    }

    // 1. Ambil seluruh akun admin, serta akun pelapor & teknisi yang tersedia di `users`
    final actors = await _resolveActors(db);

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
    // ID dokumen dibuat lebih awal agar notifikasi langsung terhubung ke reportId asli.
    final rawReports = [
      // SKENARIO 1: `reported` (Aset terdaftar)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: kranWc1Ref.id,
        assetNama: 'Kran Wastafel Lantai 1',
        assetLokasi: 'Gedung A - Toilet Lt. 1',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        deskripsi:
            'Kran air patah dan air terus mengalir deras saat keran dibuka.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.reported,
        createdAt: now.subtract(const Duration(hours: 2)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),

      // SKENARIO 2: `reported` (Fasilitas Lainnya / assetId: null)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: null,
        assetNama: 'Keramik Koridor Lantai 2',
        assetLokasi: 'Gedung B - Koridor Lt. 2',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        deskripsi:
            'Beberapa ubin keramik terangkat dan retak di dekat tangga utama, rawan tersandung.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.reported,
        createdAt: now.subtract(const Duration(hours: 1)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),

      // SKENARIO 3: `verified` (Sudah diverifikasi + SLA, belum ditugaskan teknisi)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: panelB1Ref.id,
        assetNama: 'Panel MCB Utama Lt. 1',
        assetLokasi: 'Gedung B - Koridor Lt. 1',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
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
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 12)),
          ),
          StatusHistoryItem(
            status: ReportStatus.verified,
            catatan: 'Prioritas Sedang • Menunggu penugasan teknisi.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(hours: 10)),
          ),
        ],
      ),

      // SKENARIO 4: `assigned` (Normal, SLA aman) — di aset AC Daikin 2 PK
      ReportModel(
        id: reportsRef.doc().id,
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        teknisiId: actors.teknisiId,
        teknisiNama: actors.teknisiNama,
        deskripsi:
            'AC tidak dingin sama sekali dan lampu indikator timer berkedip.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.assigned,
        prioritas: ReportPriority.tinggi,
        deadlineAt: now.add(const Duration(hours: 18)),
        createdAt: now.subtract(const Duration(hours: 6)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Tinggi • Teknisi: ${actors.teknisiNama}.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
        ],
      ),

      // SKENARIO 5: `assigned` (Hasil Re-open / Belum Beres & OVERDUE SLA)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: pcLab1_01Ref.id,
        assetNama: 'PC All-in-One#01',
        assetLokasi: 'Gedung B - Lab Komputer 1',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        teknisiId: actors.teknisiId,
        teknisiNama: actors.teknisiNama,
        deskripsi:
            'Layar berkedip parah lalu mati total setelah 5 menit digunakan.',
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
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(days: 4)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Sedang • Teknisi: ${actors.teknisiNama}.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(days: 3, hours: 20)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan: 'Catatan: Kabel daya internal sudah dikencangkan ulang.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(days: 1, hours: 12)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan:
                'Diajukan ulang: Setelah dinyalakan 10 menit layar kembali mati.',
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 10)),
          ),
        ],
      ),

      // SKENARIO 6: `inProgress` & OVERDUE SLA
      ReportModel(
        id: reportsRef.doc().id,
        assetId: proyLab1Ref.id,
        assetNama: 'Proyektor Epson EB-X500',
        assetLokasi: 'Gedung B - Lab Komputer 1',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        teknisiId: actors.teknisiId,
        teknisiNama: actors.teknisiNama,
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
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 28)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Tinggi • Teknisi: ${actors.teknisiNama}.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(hours: 26)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),

      // SKENARIO 7: `resolved` BELUM dikonfirmasi (`isConfirmed: false`)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: kursiC302_01Ref.id,
        assetNama: 'Kursi Kuliah#01',
        assetLokasi: 'Gedung C - Ruang 302',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        teknisiId: actors.teknisiId,
        teknisiNama: actors.teknisiNama,
        deskripsi:
            'Meja lipat pada kursi lepas baut engselnya sehingga miring.',
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
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Rendah • Teknisi: ${actors.teknisiNama}.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(days: 1, hours: 18)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan:
                'Catatan: Baut engsel meja sudah diganti baru dan dikencangkan.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),

      // SKENARIO 8: `resolved` SUDAH dikonfirmasi (`isConfirmed: true`)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        teknisiId: actors.teknisiId,
        teknisiNama: actors.teknisiNama,
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
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(days: 14)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Sedang • Teknisi: ${actors.teknisiNama}.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(days: 13, hours: 20)),
          ),
          StatusHistoryItem(
            status: ReportStatus.inProgress,
            catatan: 'Mulai perbaikan di lokasi.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(days: 12, hours: 3)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan:
                'Catatan: Saluran pembuangan air dibersihkan dari lumut dan filter dicuci.',
            updatedBy: actors.teknisiNama,
            timestamp: now.subtract(const Duration(days: 12)),
          ),
          StatusHistoryItem(
            status: ReportStatus.resolved,
            catatan: 'Hasil perbaikan dikonfirmasi.',
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(days: 11, hours: 18)),
          ),
        ],
      ),

      // SKENARIO 9: `rejected` (Ditolak dengan alasan)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: acR204Ref.id,
        assetNama: 'AC Daikin 2 PK',
        assetLokasi: 'Gedung A - Ruang 204',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
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
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
          StatusHistoryItem(
            status: ReportStatus.rejected,
            catatan:
                'Alasan: Laporan duplikat dengan tiket aktif pada unit AC Daikin 2 PK yang sudah ditangani.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),

      // SKENARIO 10: Laporan pada aset area umum TANPA ruangan (`ruangan == ''`)
      ReportModel(
        id: reportsRef.doc().id,
        assetId: lampuLobbyBRef.id,
        assetNama: 'Lampu Sorot Lobi Utama',
        assetLokasi: 'Gedung B',
        pelaporId: actors.pelaporId,
        pelaporNama: actors.pelaporNama,
        teknisiId: actors.teknisiId,
        teknisiNama: actors.teknisiNama,
        deskripsi:
            'Satu lampu sorot di plafon lobi mati sehingga area masuk gelap.',
        fotoSebelum: _dummyBase64Image,
        status: ReportStatus.assigned,
        prioritas: ReportPriority.rendah,
        deadlineAt: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 1)),
        riwayatStatus: [
          StatusHistoryItem(
            status: ReportStatus.reported,
            catatan: 'Laporan kerusakan dikirim.',
            updatedBy: actors.pelaporNama,
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          StatusHistoryItem(
            status: ReportStatus.assigned,
            catatan: 'Prioritas Rendah • Teknisi: ${actors.teknisiNama}.',
            updatedBy: actors.adminNama,
            timestamp: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
    ];

    for (final report in rawReports) {
      batch.set(reportsRef.doc(report.id), report.toMap());
    }

    // 4. Buat notifikasi contoh untuk SEMUA admin, pelapor, & teknisi
    final notifications = _buildNotificationsForReports(
      reports: rawReports,
      adminIds: actors.adminIds,
    );

    for (final notif in notifications) {
      batch.set(notifRef.doc(), notif.toMap());
    }

    await batch.commit();
    debugPrint(
      'SEEDER SELESAI! ${assets.length} aset, ${rawReports.length} laporan, '
      '& ${notifications.length} notifikasi (untuk ${actors.adminIds.length} admin, pelapor, & teknisi) berhasil dibuat.',
    );
  }

  /// Mengisi koleksi `notifications` berdasarkan dokumen `reports` yang SUDAH ADA
  /// tanpa menghapus/mengubah koleksi `assets` maupun `reports`.
  ///
  /// Aman terhadap Security Rules ketat (`recipientId == request.auth.uid`):
  /// pengecekan duplikat hanya membaca notifikasi milik akun yang sedang login.
  static Future<void> seedNotificationsFromExistingReports({
    bool forceCreate = false,
  }) async {
    final db = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final notifRef = db.collection('notifications');

    if (!forceCreate && currentUid != null && currentUid.isNotEmpty) {
      final existingMine = await notifRef
          .where('recipientId', isEqualTo: currentUid)
          .limit(1)
          .get();
      if (existingMine.docs.isNotEmpty) {
        debugPrint(
          'SEEDER NOTIFIKASI DILEWATI: Akun saat ini sudah memiliki notifikasi. '
          'Gunakan forceCreate: true jika ingin menambahkan lagi.',
        );
        return;
      }
    }

    final reportSnap = await db.collection('reports').get();
    if (reportSnap.docs.isEmpty) {
      debugPrint(
        'SEEDER NOTIFIKASI DILEWATI: Belum ada laporan di koleksi reports.',
      );
      return;
    }

    final reports = reportSnap.docs
        .map((doc) => ReportModel.fromFirestore(doc))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final actors = await _resolveActors(db);
    final notifications = _buildNotificationsForReports(
      reports: reports,
      adminIds: actors.adminIds,
    );

    if (notifications.isEmpty) {
      debugPrint('SEEDER NOTIFIKASI: Tidak ada notifikasi yang dihasilkan.');
      return;
    }

    // Commit per 400 dokumen agar tetap aman di bawah batas 500 operasi WriteBatch
    for (var i = 0; i < notifications.length; i += 400) {
      final end =
          (i + 400 < notifications.length) ? i + 400 : notifications.length;
      final batch = db.batch();
      for (final notif in notifications.sublist(i, end)) {
        batch.set(notifRef.doc(), notif.toMap());
      }
      await batch.commit();
    }

    debugPrint(
      'SEEDER NOTIFIKASI SELESAI! ${notifications.length} notifikasi '
      '(termasuk untuk ${actors.adminIds.length} admin) berhasil dibuat dari ${reports.length} laporan.',
    );
  }

  // ===========================================================================
  // HELPER INTERNAL
  // ===========================================================================

  static Future<
      ({
        List<String> adminIds,
        String adminNama,
        String pelaporId,
        String pelaporNama,
        String teknisiId,
        String teknisiNama,
      })> _resolveActors(FirebaseFirestore db) async {
    final List<String> adminIds = [];
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

      if (role == 'admin') {
        adminIds.add(doc.id);
        if (nama.isNotEmpty && adminNama == 'Admin SnaFix') {
          adminNama = nama;
        }
      } else if (role == 'pelapor' && pelaporId == 'dummy_pelapor') {
        pelaporId = doc.id;
        if (nama.isNotEmpty) pelaporNama = nama;
      } else if (role == 'teknisi' && teknisiId == 'dummy_teknisi') {
        teknisiId = doc.id;
        if (nama.isNotEmpty) teknisiNama = nama;
      }
    }

    return (
      adminIds: adminIds,
      adminNama: adminNama,
      pelaporId: pelaporId,
      pelaporNama: pelaporNama,
      teknisiId: teknisiId,
      teknisiNama: teknisiNama,
    );
  }

  /// Menghasilkan daftar notifikasi realistis untuk semua role sesuai status
  /// setiap laporan. Setiap akun Admin di [adminIds] menerima dokumennya sendiri
  /// sehingga status `isRead` independen per Admin.
  static List<NotificationModel> _buildNotificationsForReports({
    required List<ReportModel> reports,
    required List<String> adminIds,
  }) {
    final List<NotificationModel> result = [];
    int adminUnreadCount = 0;

    void addForAllAdmins({
      required String reportId,
      required String title,
      required String message,
      required DateTime createdAt,
      required bool isRead,
    }) {
      if (!isRead) adminUnreadCount++;
      for (final adminUid in adminIds) {
        result.add(
          NotificationModel(
            id: '',
            recipientId: adminUid,
            reportId: reportId,
            title: title,
            message: message,
            isRead: isRead,
            createdAt: createdAt,
          ),
        );
      }
    }

    void addForUser({
      required String? recipientId,
      required String reportId,
      required String title,
      required String message,
      required DateTime createdAt,
      required bool isRead,
    }) {
      if (recipientId == null ||
          recipientId.isEmpty ||
          recipientId.startsWith('dummy_')) {
        return;
      }
      result.add(
        NotificationModel(
          id: '',
          recipientId: recipientId,
          reportId: reportId,
          title: title,
          message: message,
          isRead: isRead,
          createdAt: createdAt,
        ),
      );
    }

    for (final report in reports) {
      final lastEventTime = report.riwayatStatus.isNotEmpty
          ? report.riwayatStatus.last.timestamp
          : report.createdAt;
      final techName = report.teknisiNama ?? 'Teknisi';

      switch (report.status) {
        case ReportStatus.reported:
          addForAllAdmins(
            reportId: report.id,
            title: 'Laporan Kerusakan Baru',
            message:
                '${report.pelaporNama} melaporkan kerusakan pada ${report.assetNama} (${report.assetLokasi}).',
            createdAt: report.createdAt,
            isRead: false,
          );
          break;

        case ReportStatus.verified:
          addForUser(
            recipientId: report.pelaporId,
            reportId: report.id,
            title: 'Laporan Diverifikasi',
            message:
                'Laporan ${report.assetNama} telah diverifikasi dengan prioritas ${report.prioritas?.label ?? 'Sedang'}.',
            createdAt: lastEventTime,
            isRead: false,
          );
          break;

        case ReportStatus.assigned:
          final reopenMatches = report.riwayatStatus
              .where((item) => item.catatan.startsWith('Diajukan ulang:'))
              .toList();
          final reopenItem =
              reopenMatches.isNotEmpty ? reopenMatches.last : null;

          if (reopenItem != null) {
            final reason = reopenItem.catatan
                .replaceFirst('Diajukan ulang:', '')
                .trim();
            addForAllAdmins(
              reportId: report.id,
              title: 'Perbaikan Diajukan Ulang',
              message:
                  'Perbaikan ${report.assetNama} (${report.assetLokasi}) dinyatakan belum beres. Alasan: $reason',
              createdAt: reopenItem.timestamp,
              isRead: false,
            );
            addForUser(
              recipientId: report.teknisiId,
              reportId: report.id,
              title: 'Perbaikan Diajukan Ulang',
              message:
                  'Perbaikan ${report.assetNama} (${report.assetLokasi}) dinyatakan belum beres. Alasan: $reason',
              createdAt: reopenItem.timestamp,
              isRead: false,
            );
          } else {
            final isRecent =
                DateTime.now().difference(lastEventTime).inHours < 12;
            addForUser(
              recipientId: report.teknisiId,
              reportId: report.id,
              title: 'Tugas Perbaikan Baru',
              message:
                  'Anda ditugaskan memperbaiki ${report.assetNama} di ${report.assetLokasi}.',
              createdAt: lastEventTime,
              isRead: !isRecent,
            );
            addForUser(
              recipientId: report.pelaporId,
              reportId: report.id,
              title: 'Laporan Diverifikasi & Ditugaskan',
              message:
                  'Laporan ${report.assetNama} diverifikasi dan sedang ditangani oleh teknisi $techName.',
              createdAt: lastEventTime,
              isRead: !isRecent,
            );
          }
          break;

        case ReportStatus.inProgress:
          addForUser(
            recipientId: report.pelaporId,
            reportId: report.id,
            title: 'Perbaikan Sedang Dikerjakan',
            message:
                'Teknisi $techName sedang menangani kerusakan ${report.assetNama} di ${report.assetLokasi}.',
            createdAt: lastEventTime,
            isRead: true,
          );
          break;

        case ReportStatus.resolved:
          if (!report.isConfirmed) {
            addForAllAdmins(
              reportId: report.id,
              title: 'Tugas Perbaikan Selesai',
              message:
                  '$techName telah menyelesaikan perbaikan ${report.assetNama} (${report.assetLokasi}).',
              createdAt: report.resolvedAt ?? lastEventTime,
              isRead: false,
            );
            addForUser(
              recipientId: report.pelaporId,
              reportId: report.id,
              title: 'Fasilitas Selesai Diperbaiki',
              message:
                  'Kerusakan ${report.assetNama} telah selesai diperbaiki oleh $techName. Silakan cek hasil perbaikan.',
              createdAt: report.resolvedAt ?? lastEventTime,
              isRead: false,
            );
          } else {
            addForAllAdmins(
              reportId: report.id,
              title: 'Perbaikan Dikonfirmasi Selesai',
              message:
                  '${report.pelaporNama} mengonfirmasi perbaikan ${report.assetNama} (${report.assetLokasi}) telah selesai.',
              createdAt: lastEventTime,
              isRead: true,
            );
            addForUser(
              recipientId: report.teknisiId,
              reportId: report.id,
              title: 'Perbaikan Dikonfirmasi Selesai',
              message:
                  '${report.pelaporNama} mengonfirmasi perbaikan ${report.assetNama} (${report.assetLokasi}) telah selesai.',
              createdAt: lastEventTime,
              isRead: true,
            );
          }
          break;

        case ReportStatus.rejected:
          addForUser(
            recipientId: report.pelaporId,
            reportId: report.id,
            title: 'Laporan Ditolak',
            message:
                'Laporan ${report.assetNama} ditolak oleh Admin. Alasan: ${report.rejectionReason ?? '-'}',
            createdAt: lastEventTime,
            isRead: false,
          );
          break;
      }
    }

    // Fallback: jika semua laporan berstatus `reported` sudah terlanjur diproses
    // saat uji coba sebelumnya, tetap buat 1 contoh notifikasi laporan baru
    // untuk Admin agar pengujian UI & dot unread tetap lengkap.
    if (adminUnreadCount == 0 && adminIds.isNotEmpty && reports.isNotEmpty) {
      final latest = reports.first;
      addForAllAdmins(
        reportId: latest.id,
        title: 'Laporan Kerusakan Baru',
        message:
            '${latest.pelaporNama} melaporkan kerusakan pada ${latest.assetNama} (${latest.assetLokasi}).',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      );
    }

    return result;
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
