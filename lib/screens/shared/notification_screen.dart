import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';

class _NotifColors {
  static const primary = AppColors.primaryBlue;
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const danger = Color(0xFFE53935);
}

enum NotifType { selesai, diproses, feedback, sistem }

class AppNotification {
  final String id;
  final String? ticketId;
  final String judul;
  final String pesan;
  final String waktu;
  final String? lokasi;
  final NotifType type;
  bool isRead;

  AppNotification({
    required this.id,
    this.ticketId,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.lokasi,
    required this.type,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const NotificationScreen({
    super.key,
    this.onBackToHome,
  });
  
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<String> _filters = const [
    'Semua',
    'Belum Dibaca',
    'Status Laporan',
    'Feedback Admin',
  ];

  int _selectedFilterIndex = 0;

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif-1',
      ticketId: '#SNF-2026-089',
      judul: 'Perbaikan Fasilitas Selesai',
      pesan:
          'Laporan AC Ruang Kelas D-204 Bocor telah selesai diperbaiki oleh Teknisi. Silakan cek kondisi ruangan.',
      waktu: '10 menit lalu',
      lokasi: 'Gedung D • Lantai 2',
      type: NotifType.selesai,
      isRead: false,
    ),
    AppNotification(
      id: 'notif-2',
      ticketId: '#SNF-2026-090',
      judul: 'Teknisi Sedang Menangani',
      pesan:
          'Laporan Kursi Lipat Mahasiswa Patah telah diverifikasi Admin dan diteruskan ke Teknisi untuk perbaikan.',
      waktu: '1 jam lalu',
      lokasi: 'Gedung C • Ruang C-102',
      type: NotifType.diproses,
      isRead: false,
    ),
    AppNotification(
      id: 'notif-3',
      ticketId: '#SNF-2026-085',
      judul: 'Feedback Baru dari Admin',
      pesan:
          'Laporan Proyektor Lab Komputer 1 Mati ditolak karena duplikat dengan tiket #SNF-2026-082 yang sedang dikerjakan.',
      waktu: 'Kemarin • 14:20',
      lokasi: 'Gedung B • Lantai 1',
      type: NotifType.feedback,
      isRead: true,
    ),
    AppNotification(
      id: 'notif-4',
      ticketId: '#SNF-2026-090',
      judul: 'Laporan Berhasil Dikirim',
      pesan:
          'Laporan kerusakan fasilitasmu berhasil masuk ke sistem dan menunggu pemeriksaan Admin.',
      waktu: 'Kemarin • 09:15',
      lokasi: 'Gedung C • Ruang C-102',
      type: NotifType.diproses,
      isRead: true,
    ),
    AppNotification(
      id: 'notif-5',
      judul: 'Akun SnaFix Aktif',
      pesan:
          'Selamat datang di SnaFix! Kamu kini dapat melaporkan kerusakan fasilitas kampus dan memantau progresnya secara langsung.',
      waktu: '12 Nov 2026',
      type: NotifType.sistem,
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> get _filteredNotifications {
    return _notifications.where((item) {
      return switch (_selectedFilterIndex) {
        1 => !item.isRead,
        2 => item.type == NotifType.selesai || item.type == NotifType.diproses,
        3 => item.type == NotifType.feedback,
        _ => true,
      };
    }).toList();
  }

  void _markAllAsRead() {
    if (_unreadCount == 0) return;
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua notifikasi ditandai sudah dibaca.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: _NotifColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ({IconData icon, Color bg, Color fg, String label}) _typeVisual(
    NotifType type,
  ) {
    return switch (type) {
      NotifType.selesai => (
          icon: Icons.check_circle_outline_rounded,
          bg: const Color(0xFFD9F7E4),
          fg: const Color(0xFF1E9E55),
          label: 'Selesai',
        ),
      NotifType.diproses => (
          icon: Icons.build_circle_outlined,
          bg: const Color(0xFFFFF3D6),
          fg: const Color(0xFFB7791F),
          label: 'Progres',
        ),
      NotifType.feedback => (
          icon: Icons.chat_bubble_outline_rounded,
          bg: const Color(0xFFFFE6E6),
          fg: _NotifColors.danger,
          label: 'Feedback Admin',
        ),
      NotifType.sistem => (
          icon: Icons.notifications_active_outlined,
          bg: const Color(0xFFE3EEFF),
          fg: _NotifColors.primary,
          label: 'Info Sistem',
        ),
    };
  }

  void _openNotificationDetail(AppNotification item) {
    if (!item.isRead) {
      setState(() => item.isRead = true);
    }

    final visual = _typeVisual(item.type);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: visual.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        visual.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: visual.fg,
                        ),
                      ),
                    ),
                    if (item.ticketId != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.ticketId!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _NotifColors.primary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      item.waktu,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: _NotifColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.judul,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _NotifColors.textDark,
                  ),
                ),
                if (item.lokasi != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: _NotifColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.lokasi!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _NotifColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _NotifColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _NotifColors.border),
                  ),
                  child: Text(
                    item.pesan,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _NotifColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _NotifColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredNotifications;

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
                _buildHeader(),
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
                          _buildFilterChips(),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daftar Notifikasi (${items.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _NotifColors.textDark,
                                  ),
                                ),
                                if (_unreadCount > 0)
                                  GestureDetector(
                                    onTap: _markAllAsRead,
                                    child: Text(
                                      'Tandai semua dibaca',
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
                            child: items.isEmpty
                                ? _buildEmptyState()
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      2,
                                      16,
                                      105,
                                    ),
                                    itemCount: items.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, index) =>
                                        _buildNotificationCard(items[index]),
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
  }

  // HEADER
  Widget _buildHeader() {
    final subtitle = _unreadCount > 0
        ? 'Kamu punya $_unreadCount notifikasi belum dibaca'
        : 'Semua notifikasi sudah dibaca';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: widget.onBackToHome ?? () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
            Column(
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
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: _markAllAsRead,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.done_all_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FILTER CHIPS
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isSelected = index == _selectedFilterIndex;
          final label = index == 1 && _unreadCount > 0
              ? '${_filters[index]} ($_unreadCount)'
              : _filters[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
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
          );
        },
      ),
    );
  }

  // NOTIFICATION CARD
  Widget _buildNotificationCard(AppNotification item) {
    final visual = _typeVisual(item.type);
    final isUnread = !item.isRead;

    return InkWell(
      onTap: () => _openNotificationDetail(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF2F7FF) : AppColors.white,
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
            // Ikon Kategori Notifikasi
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: visual.bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                visual.icon,
                color: visual.fg,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Konten Notifikasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.ticketId != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EEFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.ticketId!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _NotifColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.waktu,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _NotifColors.textGrey,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _NotifColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.judul,
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
                    item.pesan,
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
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _NotifColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _NotifColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pembaruan status laporan dan pesan dari Admin akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _NotifColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}