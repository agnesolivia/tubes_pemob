import 'package:cloud_firestore/cloud_firestore.dart';

class StatusHistoryItem {
  final String status;
  final String catatan;
  final String updatedBy; // Nama atau role aktor yang mengubah status
  final DateTime timestamp;

  const StatusHistoryItem({
    required this.status,
    required this.catatan,
    required this.updatedBy,
    required this.timestamp,
  });

  factory StatusHistoryItem.fromMap(Map<String, dynamic> map) {
    return StatusHistoryItem(
      status: map['status'] as String? ?? '',
      catatan: map['catatan'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'catatan': catatan,
      'updatedBy': updatedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ReportModel {
  final String id; // Diambil langsung dari doc.id Firestore
  final String assetId;
  final String assetNama; // Denormalisasi agar daftar kartu tidak perlu query ulang ke assets
  final String assetLokasi; // Contoh: 'Gedung A - Ruang 204'
  final String pelaporId;
  final String pelaporNama;
  final String? teknisiId;
  final String? teknisiNama;
  final String deskripsi;
  final String fotoSebelum; // String Base64 hasil kompresi
  final String? fotoSesudah; // String Base64 hasil kompresi (diisi teknisi saat selesai)
  final String status; // 'reported' | 'verified' | 'assigned' | 'in progress' | 'resolved' | 'rejected'
  final String? prioritas; // 'tinggi' | 'sedang' | 'rendah'
  final DateTime? deadlineAt; // Batas waktu SLA setelah diverifikasi Admin
  final String? rejectionReason; // Diisi jika status == 'rejected'
  final String? catatanTeknisi; // Diisi saat teknisi menyelesaikan tugas
  final bool isConfirmed; // True jika pelapor sudah menekan tombol konfirmasi selesai
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<StatusHistoryItem> riwayatStatus;

  const ReportModel({
    required this.id,
    required this.assetId,
    required this.assetNama,
    required this.assetLokasi,
    required this.pelaporId,
    required this.pelaporNama,
    this.teknisiId,
    this.teknisiNama,
    required this.deskripsi,
    required this.fotoSebelum,
    this.fotoSesudah,
    this.status = 'reported',
    this.prioritas,
    this.deadlineAt,
    this.rejectionReason,
    this.catatanTeknisi,
    this.isConfirmed = false,
    required this.createdAt,
    this.resolvedAt,
    this.riwayatStatus = const [],
  });

  /// Cek apakah tiket aktif sudah melewati tenggat SLA
  bool get isOverdue {
    if (deadlineAt == null) return false;
    if (status == 'resolved' || status == 'rejected') return false;
    return DateTime.now().isAfter(deadlineAt!);
  }

  /// Cek apakah tiket sudah ditutup (selesai atau ditolak)
  bool get isClosed => status == 'resolved' || status == 'rejected';

  /// Konversi dokumen Firestore menjadi objek ReportModel
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawHistory = data['riwayatStatus'] as List<dynamic>? ?? [];

    return ReportModel(
      id: doc.id,
      assetId: data['assetId'] as String? ?? '',
      assetNama: data['assetNama'] as String? ?? '',
      assetLokasi: data['assetLokasi'] as String? ?? '',
      pelaporId: data['pelaporId'] as String? ?? '',
      pelaporNama: data['pelaporNama'] as String? ?? '',
      teknisiId: data['teknisiId'] as String?,
      teknisiNama: data['teknisiNama'] as String?,
      deskripsi: data['deskripsi'] as String? ?? '',
      fotoSebelum: data['fotoSebelum'] as String? ?? '',
      fotoSesudah: data['fotoSesudah'] as String?,
      status: data['status'] as String? ?? 'reported',
      prioritas: data['prioritas'] as String?,
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

  /// Konversi objek ReportModel menjadi Map untuk disimpan ke Firestore
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
      'status': status,
      'prioritas': prioritas,
      'deadlineAt': deadlineAt != null ? Timestamp.fromDate(deadlineAt!) : null,
      'rejectionReason': rejectionReason,
      'catatanTeknisi': catatanTeknisi,
      'isConfirmed': isConfirmed,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'riwayatStatus': riwayatStatus.map((e) => e.toMap()).toList(),
    };
  }

  /// Membuat salinan objek dengan field tertentu yang diperbarui
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
    String? status,
    String? prioritas,
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