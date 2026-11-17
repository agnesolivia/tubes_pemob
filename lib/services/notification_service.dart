import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final CollectionReference _notifRef =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// Stream daftar notifikasi milik pengguna tertentu (diurutkan dari terbaru).
  Stream<List<NotificationModel>> streamUserNotifications(String recipientId) {
    return _notifRef
        .where('recipientId', isEqualTo: recipientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream jumlah notifikasi yang belum dibaca (untuk badge lonceng di AppBar).
  Stream<int> streamUnreadCount(String recipientId) {
    return _notifRef
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Kirim notifikasi ke satu pengguna (Pelapor atau Teknisi).
  Future<void> sendNotification({
    required String recipientId,
    required String reportId,
    required String title,
    required String message,
  }) async {
    if (recipientId.trim().isEmpty) return;

    final notif = NotificationModel(
      id: '', // ID otomatis dibuat oleh Firestore via .add()
      recipientId: recipientId,
      reportId: reportId,
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notifRef.add(notif.toMap());
  }

  /// Kirim notifikasi ke seluruh akun Admin (saat laporan baru masuk atau selesai).
  Future<void> notifyAllAdmins({
    required String reportId,
    required String title,
    required String message,
  }) async {
    final adminSnapshot = await _usersRef
        .where('role', isEqualTo: UserRole.admin.value)
        .get();

    if (adminSnapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (final adminDoc in adminSnapshot.docs) {
      final newDocRef = _notifRef.doc();
      final notif = NotificationModel(
        id: newDocRef.id,
        recipientId: adminDoc.id,
        reportId: reportId,
        title: title,
        message: message,
        isRead: false,
        createdAt: now,
      );
      batch.set(newDocRef, notif.toMap());
    }

    await batch.commit();
  }

  /// Tandai satu notifikasi sudah dibaca saat item diklik.
  Future<void> markAsRead(String notificationId) async {
    await _notifRef.doc(notificationId).update({'isRead': true});
  }

  /// Tandai seluruh notifikasi pengguna sudah dibaca sekaligus.
  Future<void> markAllAsRead(String recipientId) async {
    final unreadSnapshot = await _notifRef
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}