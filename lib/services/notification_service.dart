import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tubes_pemob/models/notification_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/detail_laporan_screen.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Pasang di `MaterialApp(navigatorKey: NotificationService.navigatorKey)`
  /// agar ketukan pada banner notifikasi dapat langsung membuka DetailLaporanScreen.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'snafix_updates',
    'Notifikasi SnaFix',
    description: 'Pembaruan status laporan dan penugasan fasilitas kampus.',
    importance: Importance.high,
  );

  final CollectionReference _notifRef =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Preferensi tampilan banner pop-up saat aplikasi aktif (terhubung ke ProfileScreen).
  final ValueNotifier<bool> foregroundAlertsEnabled = ValueNotifier<bool>(true);

  bool _isLocalNotifInitialized = false;
  StreamSubscription<QuerySnapshot>? _foregroundSub;
  String? _listeningUid;
  UserRole _activeUserRole = UserRole.pelapor;
  final Set<String> _shownNotificationIds = <String>{};

  // ===========================================================================
  // 1. INISIALISASI & FOREGROUND LOCAL NOTIFICATION LISTENER
  // ===========================================================================

  /// Panggil sekali di `main()` setelah `Firebase.initializeApp()`.
  Future<void> initializeLocalNotifications() async {
    if (_isLocalNotifInitialized || kIsWeb) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _isLocalNotifInitialized = true;
    } catch (e) {
      debugPrint('Gagal inisialisasi local notifications: $e');
    }
  }

  /// Mulai mendengarkan notifikasi baru secara real-time saat aplikasi aktif.
  /// Aman dipanggil berulang kali dari AuthWrapper (idempoten per UID).
  void startForegroundListener({
    required String uid,
    required UserRole userRole,
  }) {
    _activeUserRole = userRole;
    if (_listeningUid == uid && _foregroundSub != null) {
      return;
    }

    stopForegroundListener();
    _listeningUid = uid;
    _activeUserRole = userRole;
    _loadAlertPreference(uid);

    var isInitialSnapshot = true;

    _foregroundSub = _notifRef
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        if (isInitialSnapshot) {
          isInitialSnapshot = false;
          for (final doc in snapshot.docs) {
            _shownNotificationIds.add(doc.id);
          }
          return;
        }

        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final docId = change.doc.id;
          if (_shownNotificationIds.contains(docId)) continue;
          _shownNotificationIds.add(docId);

          final notif = NotificationModel.fromFirestore(change.doc);
          if (!notif.isRead && foregroundAlertsEnabled.value) {
            _showLocalNotification(notif);
          }
        }
      },
      onError: (Object error) {
        debugPrint('Foreground notification listener error: $error');
      },
    );
  }

  /// Hentikan listener saat logout atau pengguna belum terverifikasi.
  void stopForegroundListener() {
    _foregroundSub?.cancel();
    _foregroundSub = null;
    _listeningUid = null;
    _shownNotificationIds.clear();
  }

  Future<bool> _hasSystemNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return (await androidPlugin.areNotificationsEnabled()) ?? true;
      }
    } catch (_) {}
    return true;
  }

  Future<bool> _ensureNotificationPermission() async {
    if (kIsWeb) return true;

    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final alreadyEnabled = await androidPlugin.areNotificationsEnabled();
        if (alreadyEnabled == true) return true;

        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted != null) return granted;

        return (await androidPlugin.areNotificationsEnabled()) ?? false;
      }

      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Gagal memeriksa izin notifikasi: $e');
    }
    return true;
  }

  Future<void> _loadAlertPreference(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      final savedEnabled = data?['notificationsEnabled'] as bool? ?? true;
      final osGranted =
          savedEnabled ? await _hasSystemNotificationPermission() : false;

      if (_listeningUid == uid) {
        foregroundAlertsEnabled.value = savedEnabled && osGranted;
      }
    } catch (_) {
      // Tetap gunakan nilai default jika gagal membaca preferensi
    }
  }

  /// Simpan preferensi switch notifikasi dari ProfileScreen ke Firestore.
  /// Mengembalikan `false` jika user menyalakan switch tetapi izin notifikasi
  /// ditolak oleh sistem operasi (switch otomatis dikembalikan mati).
  Future<bool> setForegroundAlertsEnabled({
    required String uid,
    required bool enabled,
  }) async {
    if (enabled) {
      final hasPermission = await _ensureNotificationPermission();
      if (!hasPermission) {
        foregroundAlertsEnabled.value = false;
        return false;
      }
    }

    foregroundAlertsEnabled.value = enabled;
    try {
      await _usersRef.doc(uid).update({'notificationsEnabled': enabled});
    } catch (e) {
      debugPrint('Gagal menyimpan preferensi notifikasi: $e');
    }
    return true;
  }

  Future<void> _showLocalNotification(NotificationModel notif) async {
    if (!_isLocalNotifInitialized || kIsWeb) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = jsonEncode({
      'notifId': notif.id,
      'reportId': notif.reportId,
    });

    try {
      await _localNotifications.show(
        notif.id.hashCode & 0x7FFFFFFF,
        notif.title,
        notif.message,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Gagal menampilkan banner notifikasi: $e');
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final rawPayload = response.payload;
    if (rawPayload == null || rawPayload.isEmpty) return;

    try {
      final data = jsonDecode(rawPayload) as Map<String, dynamic>;
      final notifId = (data['notifId'] as String? ?? '').trim();
      final reportId = (data['reportId'] as String? ?? '').trim();

      if (notifId.isNotEmpty) {
        try {
          await markAsRead(notifId);
        } catch (_) {}
      }

      if (reportId.isEmpty) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DetailLaporanScreen(
            reportId: reportId,
            userRole: _activeUserRole,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Gagal membuka laporan dari notifikasi: $e');
    }
  }

  // ===========================================================================
  // 2. STREAM & OPERASI FIRESTORE NOTIFIKASI
  // ===========================================================================

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

  /// Stream jumlah notifikasi yang belum dibaca (untuk dot badge di BottomNavbar).
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