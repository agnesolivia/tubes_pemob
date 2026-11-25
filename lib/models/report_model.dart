import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  reported('reported', 'Dilaporkan'),
  verified('verified', 'Diverifikasi'),
  assigned('assigned', 'Ditugaskan'),
  inProgress('in progress', 'Sedang Dikerjakan'),
  resolved('resolved', 'Selesai'),
  rejected('rejected', 'Ditolak');

  final String value;
  final String label;
  const ReportStatus(this.value, this.label);

  static ReportStatus fromString(String? val) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ReportStatus.reported,
    );
  }
}

enum ReportPriority {
  tinggi('tinggi', 'Tinggi', 24),
  sedang('sedang', 'Sedang', 72),
  rendah('rendah', 'Rendah', 168);

  final String value;
  final String label;
  final int slaHours;
  const ReportPriority(this.value, this.label, this.slaHours);

  static ReportPriority? fromString(String? val) {
    if (val == null || val.isEmpty) return null;
    for (final item in ReportPriority.values) {
      if (item.value == val) return item;
    }
    return null;
  }
}

class StatusHistoryItem {
  final ReportStatus status;
  final String catatan;
  final String updatedBy;
  final DateTime timestamp;

  const StatusHistoryItem({
    required this.status,
    required this.catatan,
    required this.updatedBy,
    required this.timestamp,
  });

  factory StatusHistoryItem.fromMap(Map<String, dynamic> map) {
    return StatusHistoryItem(
      status: ReportStatus.fromString(map['status'] as String?),
      catatan: map['catatan'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'catatan': catatan,
      'updatedBy': updatedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ReportModel {
  final String id;

  /// `null` jika Pelapor memilih opsi "Fasilitas Lainnya / Tidak Terdaftar".
  final String? assetId;
  final String assetNama;
  final String assetLokasi;
  final String pelaporId;
  final String pelaporNama;
  final String? teknisiId;
  final String? teknisiNama;
  final String deskripsi;
  final String fotoSebelum;
  final String? fotoSesudah;
  final ReportStatus status;
  final ReportPriority? prioritas;
  final DateTime? deadlineAt;
  final String? rejectionReason;
  final String? catatanTeknisi;
  final bool isConfirmed;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<StatusHistoryItem> riwayatStatus;

  const ReportModel({
    required this.id,
    this.assetId,
    required this.assetNama,
    required this.assetLokasi,
    required this.pelaporId,
    required this.pelaporNama,
    this.teknisiId,
    this.teknisiNama,
    required this.deskripsi,
    required this.fotoSebelum,
    this.fotoSesudah,
    this.status = ReportStatus.reported,
    this.prioritas,
    this.deadlineAt,
    this.rejectionReason,
    this.catatanTeknisi,
    this.isConfirmed = false,
    required this.createdAt,
    this.resolvedAt,
    this.riwayatStatus = const [],
  });

  /// Tiket sudah terdaftar di koleksi `assets` (bukan "Fasilitas Lainnya").
  bool get hasRegisteredAsset => assetId != null;

  bool get isOverdue {
    if (deadlineAt == null) return false;
    if (isClosed) return false;
    return DateTime.now().isAfter(deadlineAt!);
  }

  /// Tidak lagi memerlukan tindakan Teknisi (selesai atau ditolak).
  /// Catatan: tiket `resolved` yang belum dikonfirmasi tetap bisa di-re-open,
  /// gunakan [isAwaitingConfirmation] untuk membedakannya.
  bool get isClosed =>
      status == ReportStatus.resolved || status == ReportStatus.rejected;

  /// Tiket masih dalam proses penanganan:
  /// reported, verified, assigned, atau inProgress.
  bool get isActive =>
      status == ReportStatus.reported ||
      status == ReportStatus.verified ||
      status == ReportStatus.assigned ||
      status == ReportStatus.inProgress;

  /// Sudah `resolved` oleh Teknisi, menunggu Konfirmasi Selesai / Belum Beres
  /// dari Pelapor pembuat laporan (atau Admin sebagai supervisor override).
  bool get isAwaitingConfirmation =>
      status == ReportStatus.resolved && !isConfirmed;

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawHistory = data['riwayatStatus'] as List<dynamic>? ?? [];
    final rawAssetId = data['assetId'] as String?;

    return ReportModel(
      id: doc.id,
      // String kosong (data lama) diperlakukan sama seperti null.
      assetId: (rawAssetId == null || rawAssetId.isEmpty) ? null : rawAssetId,
      assetNama: data['assetNama'] as String? ?? '',
      assetLokasi: data['assetLokasi'] as String? ?? '',
      pelaporId: data['pelaporId'] as String? ?? '',
      pelaporNama: data['pelaporNama'] as String? ?? '',
      teknisiId: data['teknisiId'] as String?,
      teknisiNama: data['teknisiNama'] as String?,
      deskripsi: data['deskripsi'] as String? ?? '',
      fotoSebelum: data['fotoSebelum'] as String? ?? '',
      fotoSesudah: data['fotoSesudah'] as String?,
      status: ReportStatus.fromString(data['status'] as String?),
      prioritas: ReportPriority.fromString(data['prioritas'] as String?),
      deadlineAt: (data['deadlineAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
      catatanTeknisi: data['catatanTeknisi'] as String?,
      isConfirmed: data['isConfirmed'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      riwayatStatus: rawHistory
          .map((item) => StatusHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assetId': assetId,
      'assetNama': assetNama,
      'assetLokasi': assetLokasi,
      'pelaporId': pelaporId,
      'pelaporNama': pelaporNama,
      'teknisiId': teknisiId,
      'teknisiNama': teknisiNama,
      'deskripsi': deskripsi,
      'fotoSebelum': fotoSebelum,
      'fotoSesudah': fotoSesudah,
      'status': status.value,
      'prioritas': prioritas?.value,
      'deadlineAt': deadlineAt != null ? Timestamp.fromDate(deadlineAt!) : null,
      'rejectionReason': rejectionReason,
      'catatanTeknisi': catatanTeknisi,
      'isConfirmed': isConfirmed,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'riwayatStatus': riwayatStatus.map((e) => e.toMap()).toList(),
    };
  }

  /// Catatan: seperti umumnya pola `copyWith`, field nullable (assetId,
  /// teknisiId, resolvedAt, dst.) tidak bisa dikosongkan lewat method ini
  /// karena `null` berarti "pakai nilai lama".
  ReportModel copyWith({
    String? id,
    String? assetId,
    String? assetNama,
    String? assetLokasi,
    String? pelaporId,
    String? pelaporNama,
    String? teknisiId,
    String? teknisiNama,
    String? deskripsi,
    String? fotoSebelum,
    String? fotoSesudah,
    ReportStatus? status,
    ReportPriority? prioritas,
    DateTime? deadlineAt,
    String? rejectionReason,
    String? catatanTeknisi,
    bool? isConfirmed,
    DateTime? createdAt,
    DateTime? resolvedAt,
    List<StatusHistoryItem>? riwayatStatus,
  }) {
    return ReportModel(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetNama: assetNama ?? this.assetNama,
      assetLokasi: assetLokasi ?? this.assetLokasi,
      pelaporId: pelaporId ?? this.pelaporId,
      pelaporNama: pelaporNama ?? this.pelaporNama,
      teknisiId: teknisiId ?? this.teknisiId,
      teknisiNama: teknisiNama ?? this.teknisiNama,
      deskripsi: deskripsi ?? this.deskripsi,
      fotoSebelum: fotoSebelum ?? this.fotoSebelum,
      fotoSesudah: fotoSesudah ?? this.fotoSesudah,
      status: status ?? this.status,
      prioritas: prioritas ?? this.prioritas,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      catatanTeknisi: catatanTeknisi ?? this.catatanTeknisi,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      riwayatStatus: riwayatStatus ?? this.riwayatStatus,
    );
  }
}
