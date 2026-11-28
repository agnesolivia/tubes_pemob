import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  final CollectionReference _reportsRef =
      FirebaseFirestore.instance.collection('reports');
  final NotificationService _notifService = NotificationService.instance;

  /// Nilai status untuk tiket yang masih aktif ditangani (dipakai di filter
  /// server-side `whereIn` agar dokumen resolved/rejected tidak ikut diunduh).
  static final List<String> _activeStatusValues = [
    ReportStatus.reported.value,
    ReportStatus.verified.value,
    ReportStatus.assigned.value,
    ReportStatus.inProgress.value,
  ];

  /// Nilai status untuk tiket yang sedang menjadi beban kerja Teknisi.
  static final List<String> _technicianTaskStatusValues = [
    ReportStatus.assigned.value,
    ReportStatus.inProgress.value,
  ];

  // ===========================================================================
  // 0. HELPER INTERNAL
  // ===========================================================================

  /// Menambahkan satu log ke array `riwayatStatus`.
  FieldValue _historyUnion({
    required ReportStatus status,
    required String catatan,
    required String updatedBy,
    required DateTime timestamp,
  }) {
    final item = StatusHistoryItem(
      status: status,
      catatan: catatan,
      updatedBy: updatedBy,
      timestamp: timestamp,
    );
    return FieldValue.arrayUnion([item.toMap()]);
  }

  /// Membungkus pengiriman notifikasi agar gangguan jaringan/write notifikasi
  /// tidak memunculkan error palsu ke UI padahal status laporan sudah tersimpan.
  Future<void> _safeSendNotification({
    required String recipientId,
    required String reportId,
    required String title,
    required String message,
  }) async {
    if (recipientId.trim().isEmpty) return;
    try {
      await _notifService.sendNotification(
        recipientId: recipientId,
        reportId: reportId,
        title: title,
        message: message,
      );
    } catch (e) {
      debugPrint('Gagal mengirim notifikasi ke $recipientId: $e');
    }
  }

  /// Membungkus pengiriman notifikasi broadcast ke seluruh Admin.
  Future<void> _safeNotifyAllAdmins({
    required String reportId,
    required String title,
    required String message,
  }) async {
    try {
      await _notifService.notifyAllAdmins(
        reportId: reportId,
        title: title,
        message: message,
      );
    } catch (e) {
      debugPrint('Gagal mengirim notifikasi ke seluruh Admin: $e');
    }
  }

  /// Menjalankan transisi status di dalam transaksi Firestore.
  ///
  /// Status dokumen dibaca ulang dari server sebelum diubah, sehingga aksi dari
  /// UI yang datanya sudah basi (mis. Pelapor membatalkan tepat saat Admin
  /// memverifikasi) ditolak dengan pesan yang jelas, bukan menimpa data diam-diam.
  /// Mengembalikan data TERBARU dokumen (sebelum diubah) untuk dipakai
  /// membuat notifikasi.
  Future<ReportModel> _transition({
    required String reportId,
    required Set<ReportStatus> allowedFrom,
    required String invalidStatusMessage,
    void Function(ReportModel current)? validate,
    required Map<String, dynamic> Function(ReportModel current) buildUpdate,
  }) {
    final docRef = _reportsRef.doc(reportId);

    return FirebaseFirestore.instance.runTransaction<ReportModel>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) {
        throw Exception('Laporan tidak ditemukan atau sudah dihapus.');
      }

      final current = ReportModel.fromFirestore(snap);
      if (!allowedFrom.contains(current.status)) {
        throw Exception(invalidStatusMessage);
      }

      validate?.call(current);
      tx.update(docRef, buildUpdate(current));
      return current;
    });
  }

  /// Hanya Pelapor pembuat laporan atau Admin (supervisor override) yang boleh
  /// menindaklanjuti tiket berstatus 'resolved'.
  void _ensureCanRespondToResolution(ReportModel report, UserModel actor) {
    if (!actor.isAdmin && report.pelaporId != actor.uid) {
      throw Exception(
        'Hanya pelapor pembuat laporan atau Admin yang dapat menindaklanjuti hasil perbaikan.',
      );
    }
  }

  /// Notifikasi setelah Konfirmasi Selesai / Belum Beres.
  /// - Aksi oleh Pelapor -> kabari seluruh Admin + Teknisi terkait.
  /// - Aksi oleh Admin   -> kabari Pelapor + Teknisi terkait.
  Future<void> _notifyResolutionFollowUp({
    required ReportModel current,
    required UserModel actor,
    required String title,
    required String message,
  }) async {
    final List<Future<void>> tasks = [];

    if (actor.isAdmin) {
      if (current.pelaporId.isNotEmpty && current.pelaporId != actor.uid) {
        tasks.add(
          _safeSendNotification(
            recipientId: current.pelaporId,
            reportId: current.id,
            title: title,
            message: message,
          ),
        );
      }
    } else {
      tasks.add(
        _safeNotifyAllAdmins(
          reportId: current.id,
          title: title,
          message: message,
        ),
      );
    }

    final techId = current.teknisiId;
    if (techId != null && techId.isNotEmpty && techId != actor.uid) {
      tasks.add(
        _safeSendNotification(
          recipientId: techId,
          reportId: current.id,
          title: title,
          message: message,
        ),
      );
    }

    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
  }

  // ===========================================================================
  // 1. STREAM & QUERY DATA (Client-Side Sorting agar Bebas Composite Index)
  // ===========================================================================

  /// Stream real-time satu dokumen laporan (untuk DetailLaporanScreen)
  Stream<ReportModel?> streamReportById(String reportId) {
    return _reportsRef.doc(reportId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ReportModel.fromFirestore(doc);
    });
  }

  /// Stream seluruh laporan (untuk Dashboard & Kelola Laporan Admin).
  /// Semua status ikut karena Admin memfilter berdasarkan status di sisi UI.
  Stream<List<ReportModel>> streamAllReports() {
    return _reportsRef.snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream laporan kampus yang masih aktif (untuk Beranda Pelapor).
  /// Filter status dilakukan di server: dokumen resolved/rejected tidak diunduh.
  Stream<List<ReportModel>> streamActiveCampusReports() {
    return _reportsRef
        .where('status', whereIn: _activeStatusValues)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream riwayat laporan milik Pelapor tertentu
  Stream<List<ReportModel>> streamReportsByPelapor(String pelaporId) {
    return _reportsRef
        .where('pelaporId', isEqualTo: pelaporId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream tugas milik Teknisi tertentu.
  /// Tugas aktif diurutkan berdasarkan batas SLA terdekat; tugas selesai di bagian bawah.
  Stream<List<ReportModel>> streamReportsByTeknisi(String teknisiId) {
    return _reportsRef
        .where('teknisiId', isEqualTo: teknisiId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();

      list.sort((a, b) {
        if (a.isClosed != b.isClosed) {
          return a.isClosed ? 1 : -1;
        }
        if (!a.isClosed && !b.isClosed) {
          if (a.deadlineAt == null && b.deadlineAt == null) {
            return b.createdAt.compareTo(a.createdAt);
          }
          if (a.deadlineAt == null) return 1;
          if (b.deadlineAt == null) return -1;
          return a.deadlineAt!.compareTo(b.deadlineAt!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  /// Stream riwayat kerusakan per Aset/Ruangan (untuk HistoryAssetScreen).
  /// Sesuai aturan bisnis, laporan berstatus 'rejected' tidak ditampilkan.
  ///
  /// Jika [assetId] null/kosong (Fasilitas Lainnya), tidak ada query ke
  /// Firestore dan stream langsung berisi daftar kosong.
  Stream<List<ReportModel>> streamReportsByAsset(String? assetId) {
    if (assetId == null || assetId.isEmpty) {
      return Stream.value(const <ReportModel>[]);
    }

    return _reportsRef
        .where('assetId', isEqualTo: assetId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .where((r) => r.status != ReportStatus.rejected)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream tiket yang masih aktif (reported, verified, assigned, inProgress)
  /// pada satu aset. Dipakai untuk penanda "kerusakan sedang ditangani".
  /// Hanya sebagai penanda; tidak memblokir pembuatan laporan baru.
  Stream<List<ReportModel>> streamActiveReportsByAsset(String? assetId) {
    if (assetId == null || assetId.isEmpty) {
      return Stream.value(const <ReportModel>[]);
    }

    return _reportsRef
        .where('assetId', isEqualTo: assetId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .where((r) => r.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream jumlah tiket aktif ('assigned' + 'in progress') per Teknisi.
  /// Pengganti toggle isAvailable agar Admin melihat beban kerja aktual tiap teknisi.
  /// Filter status dilakukan di server; hanya field teknisiId yang dibaca.
  Stream<Map<String, int>> streamTechnicianActiveTaskCounts() {
    return _reportsRef
        .where('status', whereIn: _technicianTaskStatusValues)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> counts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final techId = data['teknisiId'] as String?;

        if (techId != null && techId.isNotEmpty) {
          counts[techId] = (counts[techId] ?? 0) + 1;
        }
      }

      return counts;
    });
  }

  /// Jumlah tiket aktif ('assigned' + 'in progress') milik satu Teknisi.
  /// Dipakai sebagai syarat Cabut Akses (harus 0) di Kelola Teknisi.
  Future<int> countActiveTasksByTeknisi(String teknisiId) async {
    final snapshot =
        await _reportsRef.where('teknisiId', isEqualTo: teknisiId).get();

    var count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (_technicianTaskStatusValues.contains(data['status'] as String?)) {
        count++;
      }
    }
    return count;
  }

  // ===========================================================================
  // 2. AKSI PELAPOR
  // ===========================================================================

  /// Buat laporan kerusakan baru + kirim notifikasi ke seluruh Admin.
  ///
  /// Dua jalur:
  /// - Aset terdaftar (Scan QR / dropdown): isi [asset]. `assetNama` dan
  ///   `assetLokasi` diambil dari aset.
  /// - Fasilitas Lainnya / Tidak Terdaftar: [asset] null, isi [assetNama] dan
  ///   [assetLokasi] manual. Laporan tersimpan dengan `assetId: null`.
  Future<String> createReport({
    AssetModel? asset,
    String? assetNama,
    String? assetLokasi,
    required UserModel pelapor,
    required String deskripsi,
    required String fotoSebelumBase64,
  }) async {
    final cleanDeskripsi = deskripsi.trim();
    if (cleanDeskripsi.isEmpty) {
      throw Exception('Deskripsi kerusakan wajib diisi.');
    }
    if (fotoSebelumBase64.isEmpty) {
      throw Exception('Foto bukti kerusakan wajib dilampirkan.');
    }

    final String? resolvedAssetId = asset?.id;
    final String resolvedNama = (asset?.nama ?? assetNama ?? '').trim();
    final String resolvedLokasi =
        (asset?.lokasiLengkap ?? assetLokasi ?? '').trim();

    if (asset == null) {
      if (resolvedNama.isEmpty) {
        throw Exception('Nama fasilitas wajib diisi.');
      }
      if (resolvedLokasi.isEmpty) {
        throw Exception('Lokasi fasilitas wajib diisi.');
      }
    }

    final now = DateTime.now();

    final initialHistory = StatusHistoryItem(
      status: ReportStatus.reported,
      catatan: 'Laporan kerusakan dikirim.',
      updatedBy: pelapor.nama,
      timestamp: now,
    );

    final newReport = ReportModel(
      id: '', // ID otomatis dibuat Firestore via .add()
      assetId: resolvedAssetId,
      assetNama: resolvedNama,
      assetLokasi: resolvedLokasi,
      pelaporId: pelapor.uid,
      pelaporNama: pelapor.nama,
      deskripsi: cleanDeskripsi,
      fotoSebelum: fotoSebelumBase64,
      status: ReportStatus.reported,
      createdAt: now,
      riwayatStatus: [initialHistory],
    );

    final docRef = await _reportsRef.add(newReport.toMap());

    await _safeNotifyAllAdmins(
      reportId: docRef.id,
      title: 'Laporan Kerusakan Baru',
      message:
          '${pelapor.nama} melaporkan kerusakan pada $resolvedNama ($resolvedLokasi).',
    );

    return docRef.id;
  }

  /// Batalkan/hapus laporan oleh Pelapor (hanya diizinkan jika status masih 'reported').
  /// Status dicek ulang di dalam transaksi agar tidak menghapus tiket yang
  /// baru saja diverifikasi Admin.
  Future<void> cancelReport(String reportId) async {
    final docRef = _reportsRef.doc(reportId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;

      final report = ReportModel.fromFirestore(snapshot);
      if (report.status != ReportStatus.reported) {
        throw Exception(
          'Laporan yang sudah diverifikasi atau diproses tidak dapat dibatalkan.',
        );
      }

      tx.delete(docRef);
    });
  }

  /// Konfirmasi Selesai: `isConfirmed = true` (status tetap 'resolved').
  /// Boleh dilakukan Pelapor pembuat laporan atau Admin (supervisor override).
  Future<void> confirmResolution({
    required ReportModel report,
    required UserModel actor,
  }) async {
    final now = DateTime.now();

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {ReportStatus.resolved},
      invalidStatusMessage:
          'Hanya laporan berstatus selesai yang dapat dikonfirmasi.',
      validate: (r) {
        _ensureCanRespondToResolution(r, actor);
        if (r.isConfirmed) {
          throw Exception('Laporan ini sudah dikonfirmasi sebelumnya.');
        }
      },
      buildUpdate: (r) => {
        'isConfirmed': true,
        'riwayatStatus': _historyUnion(
          status: ReportStatus.resolved,
          catatan: 'Hasil perbaikan dikonfirmasi.',
          updatedBy: actor.nama,
          timestamp: now,
        ),
      },
    );

    await _notifyResolutionFollowUp(
      current: current,
      actor: actor,
      title: 'Perbaikan Dikonfirmasi Selesai',
      message: actor.isAdmin
          ? 'Admin ${actor.nama} mengonfirmasi perbaikan ${current.assetNama} (${current.assetLokasi}) telah selesai.'
          : '${actor.nama} mengonfirmasi perbaikan ${current.assetNama} (${current.assetLokasi}) telah selesai.',
    );
  }

  /// Belum Beres / Ajukan Ulang (re-open): 'resolved' -> 'assigned'.
  /// Alasan wajib diisi. `deadlineAt` sengaja TIDAK di-reset sehingga
  /// `isOverdue` kembali true bila tenggat awal sudah terlewati.
  /// Boleh dilakukan Pelapor pembuat laporan atau Admin (supervisor override).
  Future<void> reopenReport({
    required ReportModel report,
    required UserModel actor,
    required String alasan,
  }) async {
    final cleanReason = alasan.trim();
    if (cleanReason.isEmpty) {
      throw Exception('Alasan wajib diisi agar teknisi tahu apa yang belum beres.');
    }

    final now = DateTime.now();

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {ReportStatus.resolved},
      invalidStatusMessage:
          'Hanya laporan berstatus selesai yang dapat diajukan ulang.',
      validate: (r) {
        _ensureCanRespondToResolution(r, actor);
        if (r.isConfirmed) {
          throw Exception(
            'Laporan yang sudah dikonfirmasi selesai tidak dapat diajukan ulang.',
          );
        }
      },
      buildUpdate: (r) => {
        'status': ReportStatus.assigned.value,
        'isConfirmed': false,
        'resolvedAt': null,
        'riwayatStatus': _historyUnion(
          status: ReportStatus.assigned,
          catatan: 'Diajukan ulang: $cleanReason',
          updatedBy: actor.nama,
          timestamp: now,
        ),
      },
    );

    await _notifyResolutionFollowUp(
      current: current,
      actor: actor,
      title: 'Perbaikan Diajukan Ulang',
      message:
          'Perbaikan ${current.assetNama} (${current.assetLokasi}) dinyatakan belum beres. Alasan: $cleanReason',
    );
  }

  // ===========================================================================
  // 3. AKSI ADMIN
  // ===========================================================================

  /// Verifikasi laporan ('reported'), tetapkan prioritas + SLA, dan (opsional)
  /// langsung tugaskan Teknisi.
  Future<void> verifyAndAssignReport({
    required ReportModel report,
    required ReportPriority prioritas,
    required String adminNama,
    UserModel? teknisi,
  }) async {
    if (teknisi != null && !teknisi.isTeknisi) {
      throw Exception('Pengguna yang dipilih bukan teknisi.');
    }

    final now = DateTime.now();
    final deadline = now.add(Duration(hours: prioritas.slaHours));
    final nextStatus =
        teknisi != null ? ReportStatus.assigned : ReportStatus.verified;

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {ReportStatus.reported},
      invalidStatusMessage:
          'Laporan ini sudah diverifikasi, ditolak, atau dibatalkan oleh pelapor.',
      buildUpdate: (r) => {
        'status': nextStatus.value,
        'prioritas': prioritas.value,
        'deadlineAt': Timestamp.fromDate(deadline),
        'teknisiId': teknisi?.uid,
        'teknisiNama': teknisi?.nama,
        'riwayatStatus': _historyUnion(
          status: nextStatus,
          catatan: teknisi != null
              ? 'Prioritas ${prioritas.label} • Teknisi: ${teknisi.nama}.'
              : 'Prioritas ${prioritas.label} • Menunggu penugasan teknisi.',
          updatedBy: adminNama,
          timestamp: now,
        ),
      },
    );

    final List<Future<void>> notifTasks = [
      // Notifikasi ke Pelapor
      _safeSendNotification(
        recipientId: current.pelaporId,
        reportId: current.id,
        title: teknisi != null
            ? 'Laporan Diverifikasi & Ditugaskan'
            : 'Laporan Diverifikasi',
        message: teknisi != null
            ? 'Laporan ${current.assetNama} diverifikasi dan sedang ditangani oleh teknisi ${teknisi.nama}.'
            : 'Laporan ${current.assetNama} telah diverifikasi dengan prioritas ${prioritas.label}.',
      ),
    ];

    // Notifikasi ke Teknisi jika langsung dipilih
    if (teknisi != null) {
      notifTasks.add(
        _safeSendNotification(
          recipientId: teknisi.uid,
          reportId: current.id,
          title: 'Tugas Perbaikan Baru',
          message:
              'Anda ditugaskan memperbaiki ${current.assetNama} di ${current.assetLokasi} (Prioritas: ${prioritas.label}).',
        ),
      );
    }

    await Future.wait(notifTasks);
  }

  /// Tugaskan atau alihkan tugas ke Teknisi (untuk tiket 'verified', 'assigned', atau 'in progress').
  /// `deadlineAt` tidak diubah.
  Future<void> assignTechnician({
    required ReportModel report,
    required UserModel teknisi,
    required String adminNama,
  }) async {
    if (!teknisi.isTeknisi) {
      throw Exception('Pengguna yang dipilih bukan teknisi.');
    }

    final now = DateTime.now();

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {
        ReportStatus.verified,
        ReportStatus.assigned,
        ReportStatus.inProgress,
      },
      invalidStatusMessage:
          'Tiket ini tidak dapat ditugaskan pada status saat ini.',
      validate: (r) {
        if (r.status != ReportStatus.verified && r.teknisiId == teknisi.uid) {
          throw Exception('Tiket ini sudah ditugaskan ke ${teknisi.nama}.');
        }
      },
      buildUpdate: (r) {
        final isReassign = r.teknisiId != null && r.teknisiId != teknisi.uid;
        return {
          'status': ReportStatus.assigned.value,
          'teknisiId': teknisi.uid,
          'teknisiNama': teknisi.nama,
          'riwayatStatus': _historyUnion(
            status: ReportStatus.assigned,
            catatan: isReassign
                ? 'Dialihkan dari ${r.teknisiNama ?? 'teknisi sebelumnya'} ke ${teknisi.nama}.'
                : 'Teknisi: ${teknisi.nama}.',
            updatedBy: adminNama,
            timestamp: now,
          ),
        };
      },
    );

    final previousTechId = current.teknisiId;

    final List<Future<void>> notifTasks = [
      _safeSendNotification(
        recipientId: teknisi.uid,
        reportId: current.id,
        title: 'Tugas Perbaikan Baru',
        message:
            'Anda ditugaskan memperbaiki ${current.assetNama} di ${current.assetLokasi}.',
      ),
      _safeSendNotification(
        recipientId: current.pelaporId,
        reportId: current.id,
        title: 'Teknisi Ditugaskan',
        message:
            'Teknisi ${teknisi.nama} telah ditugaskan menangani laporan ${current.assetNama}.',
      ),
    ];

    // Kabari teknisi lama bahwa tugas dialihkan
    if (previousTechId != null &&
        previousTechId.isNotEmpty &&
        previousTechId != teknisi.uid) {
      notifTasks.add(
        _safeSendNotification(
          recipientId: previousTechId,
          reportId: current.id,
          title: 'Tugas Dialihkan',
          message:
              'Tugas perbaikan ${current.assetNama} di ${current.assetLokasi} dialihkan ke ${teknisi.nama}.',
        ),
      );
    }

    await Future.wait(notifTasks);
  }

  /// Tolak laporan oleh Admin dengan alasan wajib (hanya untuk tiket 'reported').
  Future<void> rejectReport({
    required ReportModel report,
    required String rejectionReason,
    required String adminNama,
  }) async {
    final cleanReason = rejectionReason.trim();
    if (cleanReason.isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }

    final now = DateTime.now();

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {ReportStatus.reported},
      invalidStatusMessage:
          'Hanya laporan berstatus dilaporkan yang dapat ditolak.',
      buildUpdate: (r) => {
        'status': ReportStatus.rejected.value,
        'rejectionReason': cleanReason,
        'riwayatStatus': _historyUnion(
          status: ReportStatus.rejected,
          catatan: 'Alasan: $cleanReason',
          updatedBy: adminNama,
          timestamp: now,
        ),
      },
    );

    await _safeSendNotification(
      recipientId: current.pelaporId,
      reportId: current.id,
      title: 'Laporan Ditolak',
      message:
          'Laporan ${current.assetNama} ditolak oleh Admin. Alasan: $cleanReason',
    );
  }

  // ===========================================================================
  // 4. AKSI TEKNISI
  // ===========================================================================

  /// Teknisi memulai pengerjaan di lokasi ('assigned' -> 'in progress').
  /// Hanya teknisi yang ditugaskan pada tiket tersebut yang diizinkan.
  Future<void> startWork({
    required ReportModel report,
    required UserModel teknisi,
  }) async {
    final now = DateTime.now();

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {ReportStatus.assigned},
      invalidStatusMessage:
          'Tiket ini tidak berstatus ditugaskan (mungkin sudah dialihkan atau dikerjakan).',
      validate: (r) {
        if (r.teknisiId != teknisi.uid) {
          throw Exception('Tiket ini tidak ditugaskan kepada Anda.');
        }
      },
      buildUpdate: (r) => {
        'status': ReportStatus.inProgress.value,
        'riwayatStatus': _historyUnion(
          status: ReportStatus.inProgress,
          catatan: 'Mulai perbaikan di lokasi.',
          updatedBy: teknisi.nama,
          timestamp: now,
        ),
      },
    );

    await _safeSendNotification(
      recipientId: current.pelaporId,
      reportId: current.id,
      title: 'Perbaikan Sedang Dikerjakan',
      message:
          'Teknisi ${teknisi.nama} sedang menangani kerusakan ${current.assetNama} di ${current.assetLokasi}.',
    );
  }

  /// Teknisi menyelesaikan tugas ('in progress' -> 'resolved')
  /// + unggah foto sesudah & catatan perbaikan.
  Future<void> completeWork({
    required ReportModel report,
    required String fotoSesudahBase64,
    required String catatanTeknisi,
    required UserModel teknisi,
  }) async {
    final cleanNote = catatanTeknisi.trim();
    if (cleanNote.isEmpty) {
      throw Exception('Catatan tindakan perbaikan wajib diisi.');
    }
    if (fotoSesudahBase64.isEmpty) {
      throw Exception('Foto hasil perbaikan wajib diunggah.');
    }

    final now = DateTime.now();

    final current = await _transition(
      reportId: report.id,
      allowedFrom: {ReportStatus.inProgress},
      invalidStatusMessage:
          'Tiket ini tidak sedang dikerjakan (mungkin sudah dialihkan atau diselesaikan).',
      validate: (r) {
        if (r.teknisiId != teknisi.uid) {
          throw Exception('Tiket ini tidak ditugaskan kepada Anda.');
        }
      },
      buildUpdate: (r) => {
        'status': ReportStatus.resolved.value,
        'fotoSesudah': fotoSesudahBase64,
        'catatanTeknisi': cleanNote,
        'isConfirmed': false,
        'resolvedAt': Timestamp.fromDate(now),
        'riwayatStatus': _historyUnion(
          status: ReportStatus.resolved,
          catatan: 'Catatan: $cleanNote',
          updatedBy: teknisi.nama,
          timestamp: now,
        ),
      },
    );

    await Future.wait([
      // Notifikasi ke Pelapor
      _safeSendNotification(
        recipientId: current.pelaporId,
        reportId: current.id,
        title: 'Fasilitas Selesai Diperbaiki',
        message:
            'Kerusakan ${current.assetNama} telah selesai diperbaiki oleh ${teknisi.nama}. Silakan cek hasil perbaikan.',
      ),
      // Notifikasi ke seluruh Admin
      _safeNotifyAllAdmins(
        reportId: current.id,
        title: 'Tugas Perbaikan Selesai',
        message:
            '${teknisi.nama} telah menyelesaikan perbaikan ${current.assetNama} (${current.assetLokasi}).',
      ),
    ]);
  }
}
