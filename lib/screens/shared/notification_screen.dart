import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/notification_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/shared/detail_laporan_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/notification_service.dart';

class _NotifColors {
  static const primary = AppColors.primaryBlue;
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const danger = Color(0xFFE53935);
}

class NotificationScreen extends StatefulWidget {
  final UserRole? userRole;

  const NotificationScreen({
    super.key,
    this.userRole,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const List<String> _filters = ['Semua', 'Belum Dibaca'];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  int _selectedFilterIndex = 0;
  bool _isMarkingAllRead = false;
  String? _uid;
  UserRole? _resolvedRole;
  Stream<List<NotificationModel>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _uid = AuthService.instance.currentUser?.uid;
    _resolvedRole = widget.userRole;
    if (_uid != null && _uid!.isNotEmpty) {
      _notificationsStream =
          NotificationService.instance.streamUserNotifications(_uid!);
      if (_resolvedRole == null) {
        _loadUserRole(_uid!);
      }
    }
  }

  Future<void> _loadUserRole(String uid) async {
    try {
      final user = await AuthService.instance.getUserData(uid);
      if (!mounted || user == null) return;
      setState(() => _resolvedRole = user.role);
    } catch (_) {
      // Diabaikan; akan dicoba ulang saat notifikasi diketuk jika belum terisi
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
          ),
          backgroundColor:
              isError ? _NotifColors.danger : _NotifColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _markAllAsRead(int unreadCount) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty || unreadCount == 0 || _isMarkingAllRead) {
      return;
    }

    setState(() => _isMarkingAllRead = true);
    try {
      await NotificationService.instance.markAllAsRead(uid);
      _showSnackBar('Semua notifikasi ditandai sudah dibaca.');
    } catch (e) {
      _showSnackBar('Gagal memperbarui notifikasi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _onNotificationTap(NotificationModel notif) async {
    if (!notif.isRead) {
      try {
        await NotificationService.instance.markAsRead(notif.id);
      } catch (_) {
        // Tetap lanjutkan navigasi meski gagal menandai dibaca sementara
      }
    }

    if (!mounted) return;

    final reportId = notif.reportId.trim();
    if (reportId.isEmpty) {
      _showSnackBar('Laporan terkait tidak tersedia.', isError: true);
      return;
    }

    var role = widget.userRole ?? _resolvedRole;
    if (role == null && _uid != null && _uid!.isNotEmpty) {
      try {
        final user = await AuthService.instance.getUserData(_uid!);
        role = user?.role;
        if (mounted && role != null) {
          setState(() => _resolvedRole = role);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailLaporanScreen(
          reportId: reportId,
          userRole: role ?? UserRole.pelapor,
        ),
      ),
    );
  }

  ({IconData icon, Color bg, Color fg}) _resolveVisual(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('ditolak') ||
        lower.contains('diajukan ulang') ||
        lower.contains('belum beres') ||
        lower.contains('overdue')) {
      return (
        icon: Icons.error_outline_rounded,
        bg: const Color(0xFFFFE6E6),
        fg: _NotifColors.danger,
      );
    }
    if (lower.contains('selesai') || lower.contains('dikonfirmasi')) {
      return (
        icon: Icons.check_circle_outline_rounded,
        bg: const Color(0xFFD9F7E4),
        fg: const Color(0xFF1E9E55),
      );
    }
    if (lower.contains('ditugaskan') ||
        lower.contains('diverifikasi') ||
        lower.contains('dikerjakan') ||
        lower.contains('dialihkan') ||
        lower.contains('tugas perbaikan baru')) {
      return (
        icon: Icons.build_circle_outlined,
        bg: const Color(0xFFFFF3D6),
        fg: const Color(0xFFB7791F),
      );
    }
    return (
      icon: Icons.notifications_active_outlined,
      bg: const Color(0xFFE3EEFF),
      fg: _NotifColors.primary,
    );
  }

  String _formatRelativeTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24 && now.day == createdAt.day) {
      return '${diff.inHours} jam lalu';
    }

    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    final yesterday = now.subtract(const Duration(days: 1));
    if (createdAt.year == yesterday.year &&
        createdAt.month == yesterday.month &&
        createdAt.day == yesterday.day) {
      return 'Kemarin • $hh:$mm';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }

    final month = _months[createdAt.month - 1];
    return '${createdAt.day} $month ${createdAt.year} • $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsStream == null) {
      return Scaffold(
        backgroundColor: _NotifColors.background,
        body: Center(
          child: Text(
            'Pengguna belum masuk.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: _NotifColors.textGrey,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        final allNotifications = snapshot.data ?? const <NotificationModel>[];
        final unreadCount = allNotifications.where((n) => !n.isRead).length;
        final filteredItems = _selectedFilterIndex == 1
            ? allNotifications.where((n) => !n.isRead).toList()
            : allNotifications;

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: _NotifColors.primary,
            body: Stack(
              children: [
                // 1. Gambar Gelombang Biru Atas
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/wave_top.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                // 2. Tata Letak Utama (Header + Konten Putih)
                Column(
                  children: [
                    _buildHeader(unreadCount),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: _NotifColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 18),
                              _buildFilterChips(unreadCount),
                              const SizedBox(height: 14),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Daftar Notifikasi (${filteredItems.length})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _NotifColors.textDark,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      GestureDetector(
                                        onTap: _isMarkingAllRead
                                            ? null
                                            : () => _markAllAsRead(unreadCount),
                                        child: Text(
                                          _isMarkingAllRead
                                              ? 'Memproses...'
                                              : 'Tandai semua dibaca',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _NotifColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: _buildBodyContent(
                                  isLoading: isLoading,
                                  error: snapshot.error,
                                  items: filteredItems,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyContent({
    required bool isLoading,
    required Object? error,
    required List<NotificationModel> items,
  }) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 105),
          child: CircularProgressIndicator(color: _NotifColors.primary),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 105),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _NotifColors.danger,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                'Gagal Memuat Notifikasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _NotifColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _NotifColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 105),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = items[index];
        final visual = _resolveVisual(item.title);
        return _NotificationCard(
          title: item.title,
          message: item.message,
          timeLabel: _formatRelativeTime(item.createdAt),
          isRead: item.isRead,
          icon: visual.icon,
          iconBg: visual.bg,
          iconFg: visual.fg,
          onTap: () => _onNotificationTap(item),
        );
      },
    );
  }

  // HEADER (bersih tanpa tombol back maupun ikon done_all redundan)
  Widget _buildHeader(int unreadCount) {
    final subtitle = unreadCount > 0
        ? '$unreadCount notifikasi belum dibaca'
        : 'Semua notifikasi sudah dibaca';

    return SafeArea(
      bottom: false,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifikasi',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FILTER CHIPS (2 filter universal lintas role)
  Widget _buildFilterChips(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = index == _selectedFilterIndex;
          final label = index == 1 && unreadCount > 0
              ? '${_filters[index]} ($unreadCount)'
              : _filters[index];

          return Padding(
            padding: EdgeInsets.only(right: index == 0 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _NotifColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _NotifColors.primary
                        : _NotifColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.white
                        : _NotifColors.textDark,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    final isUnreadFilter = _selectedFilterIndex == 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 105),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFE6EFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnreadFilter
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_none_rounded,
                color: _NotifColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isUnreadFilter
                  ? 'Semua Notifikasi Sudah Dibaca'
                  : 'Belum Ada Notifikasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _NotifColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnreadFilter
                  ? 'Tidak ada notifikasi baru yang menunggu untuk dibaca.'
                  : 'Pembaruan status laporan dan penugasan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _NotifColors.textGrey,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String timeLabel;
  final bool isRead;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.isRead,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !isRead;

    return Material(
      color: isUnread ? const Color(0xFFF2F7FF) : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? _NotifColors.primary.withValues(alpha: 0.32)
                  : _NotifColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconFg, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _NotifColors.textGrey,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _NotifColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _NotifColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
