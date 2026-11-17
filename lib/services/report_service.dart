import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Stream seluruh laporan (untuk Dashboard & Kelola Laporan Admin)
  Stream<List<ReportModel>> streamAllReports() {
    return _reportsRef.snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream laporan kampus yang masih aktif (untuk Beranda Pelapor)
  Stream<List<ReportModel>> streamActiveCampusReports() {
    return _reportsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .where((r) => !r.isClosed)
          .toList();
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
  Stream<List<ReportModel>> streamReportsByAsset(String assetId) {
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

  /// Stream jumlah tiket aktif ('assigned' + 'in progress') per Teknisi.
  /// Pengganti toggle isAvailable agar Admin melihat beban kerja aktual tiap teknisi.
  Stream<Map<String, int>> streamTechnicianActiveTaskCounts() {
    return _reportsRef.snapshots().map((snapshot) {
      final Map<String, int> counts = {};

      for (final doc in snapshot.docs) {
        final report = ReportModel.fromFirestore(doc);
        final techId = report.teknisiId;
        final isActiveTask = report.status == ReportStatus.assigned ||
            report.status == ReportStatus.inProgress;

        if (techId != null && techId.isNotEmpty && isActiveTask) {
          counts[techId] = (counts[techId] ?? 0) + 1;
        }
      }

      return counts;
    });
  }

  // ===========================================================================
  // 2. AKSI PELAPOR
  // ===========================================================================

  /// Buat laporan kerusakan baru + kirim notifikasi ke seluruh Admin
  Future<String> createReport({
    required AssetModel asset,
    required UserModel pelapor,
    required String deskripsi,
    required String fotoSebelumBase64,
  }) async {
    final now = DateTime.now();

    final initialHistory = StatusHistoryItem(
      status: ReportStatus.reported,
      catatan: 'Laporan kerusakan dikirim oleh pelapor.',
      updatedBy: pelapor.nama,
      timestamp: now,
    );

    final newReport = ReportModel(
      id: '', // ID otomatis dibuat Firestore via .add()
      assetId: asset.id,
      assetNama: asset.nama,
      assetLokasi: asset.lokasiLengkap,
      pelaporId: pelapor.uid,
      pelaporNama: pelapor.nama,
      deskripsi: deskripsi.trim(),
      fotoSebelum: fotoSebelumBase64,
      status: ReportStatus.reported,
      createdAt: now,
      riwayatStatus: [initialHistory],
    );

    final docRef = await _reportsRef.add(newReport.toMap());

    await _notifService.notifyAllAdmins(
      reportId: docRef.id,
      title: 'Laporan Kerusakan Baru',
      message:
          '${pelapor.nama} melaporkan kerusakan pada ${asset.nama} (${asset.lokasiLengkap}).',
    );

    return docRef.id;
  }

  /// Batalkan/hapus laporan oleh Pelapor (hanya diizinkan jika status masih 'reported')
  Future<void> cancelReport(String reportId) async {
    final docRef = _reportsRef.doc(reportId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final report = ReportModel.fromFirestore(snapshot);
    if (report.status != ReportStatus.reported) {
      throw Exception(
        'Laporan yang sudah diverifikasi atau diproses tidak dapat dibatalkan.',
      );
    }

    await docRef.delete();
  }

  /// Pelapor menekan tombol Konfirmasi Selesai setelah perbaikan berstatus 'resolved'
  Future<void> confirmResolution({
    required ReportModel report,
    required String pelaporNama,
  }) async {
    final historyItem = StatusHistoryItem(
      status: ReportStatus.resolved,
      catatan: 'Hasil perbaikan telah dikonfirmasi selesai oleh pelapor.',
      updatedBy: pelaporNama,
      timestamp: DateTime.now(),
    );

    await _reportsRef.doc(report.id).update({
      'isConfirmed': true,
      'riwayatStatus': FieldValue.arrayUnion([historyItem.toMap()]),
    });
  }

  // ===========================================================================
  // 3. AKSI ADMIN
  // ===========================================================================

  /// Verifikasi laporan, tetapkan prioritas + SLA, dan (opsional) langsung tugaskan Teknisi
  Future<void> verifyAndAssignReport({
    required ReportModel report,
    required ReportPriority prioritas,
    required String adminNama,
    UserModel? teknisi,
  }) async {
    final now = DateTime.now();
    final deadline = now.add(Duration(hours: prioritas.slaHours));
    final hasTechnician = teknisi != null;

    final nextStatus =
        hasTechnician ? ReportStatus.assigned : ReportStatus.verified;

    final historyItem = StatusHistoryItem(
      status: nextStatus,
      catatan: hasTechnician
          ? 'Diverifikasi (Prioritas ${prioritas.label}) & ditugaskan ke ${teknisi.nama}.'
          : 'Laporan diverifikasi dengan prioritas ${prioritas.label}. Menunggu penugasan teknisi.',
      updatedBy: adminNama,
      timestamp: now,
    );

    await _reportsRef.doc(report.id).update({
      'status': nextStatus.value,
      'prioritas': prioritas.value,
      'deadlineAt': Timestamp.fromDate(deadline),
      'teknisiId': teknisi?.uid,
      'teknisiNama': teknisi?.nama,
      'riwayatStatus': FieldValue.arrayUnion([historyItem.toMap()]),
    });

    // Notifikasi ke Pelapor
    await _notifService.sendNotification(
      recipientId: report.pelaporId,
      reportId: report.id,
      title: hasTechnician
          ? 'Laporan Diverifikasi & Ditugaskan'
          : 'Laporan Diverifikasi',
      message: hasTechnician
          ? 'Laporan ${report.assetNama} diverifikasi dan sedang ditangani oleh teknisi ${teknisi.nama}.'
          : 'Laporan ${report.assetNama} telah diverifikasi dengan prioritas ${prioritas.label}.',
    );

    // Notifikasi ke Teknisi jika langsung dipilih
    if (hasTechnician) {
      await _notifService.sendNotification(
        recipientId: teknisi.uid,
        reportId: report.id,
        title: 'Tugas Perbaikan Baru',
        message:
            'Anda ditugaskan memperbaiki ${report.assetNama} di ${report.assetLokasi} (Prioritas: ${prioritas.label}).',
      );
    }
  }

  /// Tugaskan atau alihkan tugas ke Teknisi (untuk tiket 'verified', 'assigned', atau 'in progress')
  Future<void> assignTechnician({
    required ReportModel report,
    required UserModel teknisi,
    required String adminNama,
  }) async {
    final now = DateTime.now();
    final isReassign =
        report.teknisiId != null && report.teknisiId != teknisi.uid;

    final historyItem = StatusHistoryItem(
      status: ReportStatus.assigned,
      catatan: isReassign
          ? 'Tugas dialihkan dari ${report.teknisiNama} ke ${teknisi.nama}.'
          : 'Ditugaskan kepada teknisi ${teknisi.nama}.',
      updatedBy: adminNama,
      timestamp: now,
    );

    await _reportsRef.doc(report.id).update({
      'status': ReportStatus.assigned.value,
      'teknisiId': teknisi.uid,
      'teknisiNama': teknisi.nama,
      'riwayatStatus': FieldValue.arrayUnion([historyItem.toMap()]),
    });

    await _notifService.sendNotification(
      recipientId: teknisi.uid,
      reportId: report.id,
      title: 'Tugas Perbaikan Baru',
      message:
          'Anda ditugaskan memperbaiki ${report.assetNama} di ${report.assetLokasi}.',
    );

    await _notifService.sendNotification(
      recipientId: report.pelaporId,
      reportId: report.id,
      title: 'Teknisi Ditugaskan',
      message:
          'Teknisi ${teknisi.nama} telah ditugaskan menangani laporan ${report.assetNama}.',
    );
  }

  /// Tolak laporan oleh Admin dengan alasan wajib
  Future<void> rejectReport({
    required ReportModel report,
    required String rejectionReason,
    required String adminNama,
  }) async {
    final cleanReason = rejectionReason.trim();
    if (cleanReason.isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }

    final historyItem = StatusHistoryItem(
      status: ReportStatus.rejected,
      catatan: 'Laporan ditolak: $cleanReason',
      updatedBy: adminNama,
      timestamp: DateTime.now(),
    );

    await _reportsRef.doc(report.id).update({
      'status': ReportStatus.rejected.value,
      'rejectionReason': cleanReason,
      'riwayatStatus': FieldValue.arrayUnion([historyItem.toMap()]),
    });

    await _notifService.sendNotification(
      recipientId: report.pelaporId,
      reportId: report.id,
      title: 'Laporan Ditolak',
      message:
          'Laporan ${report.assetNama} ditolak oleh Admin. Alasan: $cleanReason',
    );
  }

  // ===========================================================================
  // 4. AKSI TEKNISI
  // ===========================================================================

  /// Teknisi memulai pengerjaan di lokasi ('assigned' -> 'in progress')
  Future<void> startWork({
    required ReportModel report,
    required String teknisiNama,
  }) async {
    final historyItem = StatusHistoryItem(
      status: ReportStatus.inProgress,
      catatan: 'Teknisi mulai mengerjakan perbaikan di lokasi.',
      updatedBy: teknisiNama,
      timestamp: DateTime.now(),
    );

    await _reportsRef.doc(report.id).update({
      'status': ReportStatus.inProgress.value,
      'riwayatStatus': FieldValue.arrayUnion([historyItem.toMap()]),
    });

    await _notifService.sendNotification(
      recipientId: report.pelaporId,
      reportId: report.id,
      title: 'Perbaikan Sedang Dikerjakan',
      message:
          'Teknisi $teknisiNama sedang menangani kerusakan ${report.assetNama} di ${report.assetLokasi}.',
    );
  }

  /// Teknisi menyelesaikan tugas + unggah foto sesudah & catatan perbaikan
  Future<void> completeWork({
    required ReportModel report,
    required String fotoSesudahBase64,
    required String catatanTeknisi,
    required String teknisiNama,
  }) async {
    final cleanNote = catatanTeknisi.trim();
    if (cleanNote.isEmpty) {
      throw Exception('Catatan tindakan perbaikan wajib diisi.');
    }

    final now = DateTime.now();

    final historyItem = StatusHistoryItem(
      status: ReportStatus.resolved,
      catatan: 'Perbaikan selesai: $cleanNote',
      updatedBy: teknisiNama,
      timestamp: now,
    );

    await _reportsRef.doc(report.id).update({
      'status': ReportStatus.resolved.value,
      'fotoSesudah': fotoSesudahBase64,
      'catatanTeknisi': cleanNote,
      'resolvedAt': Timestamp.fromDate(now),
      'riwayatStatus': FieldValue.arrayUnion([historyItem.toMap()]),
    });

    // Notifikasi ke Pelapor
    await _notifService.sendNotification(
      recipientId: report.pelaporId,
      reportId: report.id,
      title: 'Fasilitas Selesai Diperbaiki',
      message:
          'Kerusakan ${report.assetNama} telah selesai diperbaiki oleh $teknisiNama. Silakan cek hasil perbaikan.',
    );

    // Notifikasi ke seluruh Admin
    await _notifService.notifyAllAdmins(
      reportId: report.id,
      title: 'Tugas Perbaikan Selesai',
      message:
          '$teknisiNama telah menyelesaikan perbaikan ${report.assetNama} (${report.assetLokasi}).',
    );
  }
}