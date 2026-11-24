import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tubes_pemob/models/report_model.dart';

class TechnicianTaskItem {
  final String id;
  final String teknisiId;

  final String assetNama;
  final String assetLokasi;
  final String pelaporNama;

  final DateTime deadlineAt;
  final DateTime? reportedAt;

  final ReportStatus status;
  final ReportPriority priority;

  final bool isOverdue;

  final IconData assetIcon;

  // Informasi tambahan untuk halaman detail
  final String? assetId;
  final String? reportDescription;

  // Foto sebelum perbaikan dalam bentuk bytes.
  // Bytes dapat diperoleh dari StorageService.
  final Uint8List? fotoSebelumBytes;

  const TechnicianTaskItem({
    required this.id,
    required this.teknisiId,
    required this.assetNama,
    required this.assetLokasi,
    required this.pelaporNama,
    required this.deadlineAt,
    required this.status,
    required this.priority,
    required this.isOverdue,
    this.reportedAt,
    this.assetId,
    this.reportDescription,
    this.fotoSebelumBytes,
    this.assetIcon = Icons.build_outlined,
  });
}