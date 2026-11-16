import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id; // Diambil langsung dari doc.id Firestore
  final String recipientId; // UID user penerima notifikasi
  final String reportId; // ID dokumen laporan untuk navigasi ke DetailLaporanScreen
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.reportId,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  /// Konversi dokumen Firestore menjadi objek NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      reportId: data['reportId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Konversi objek NotificationModel menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'reportId': reportId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Membuat salinan objek dengan field tertentu yang diperbarui
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? reportId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      reportId: reportId ?? this.reportId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}