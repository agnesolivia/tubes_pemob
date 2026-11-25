import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';

// --------------------------------------------------------------- COLORS

class HistoryColors {
  static const primary = AppColors.primaryBlue;
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const orange = Color(0xFFF5A623);
}

// --------------------------------------------------------------- MODEL

enum StatusLaporan { diproses, selesai, ditolak }

class Laporan {
  final String id;
  final String tanggal;
  final String judul;
  final String lokasi;
  final StatusLaporan status;
  final bool adaFeedback;
  final String? gambar;
  final String? catatanAdmin;

  const Laporan({
    required this.id,
    required this.tanggal,
    required this.judul,
    required this.lokasi,
    required this.status,
    this.adaFeedback = false,
    this.gambar,
    this.catatanAdmin,
  });
}

// Data sementara untuk pengujian tampilan
const List<Laporan> dataLaporan = [
  Laporan(
    id: '#SNF-2026-089',
    tanggal: '16 Nov 2026',
    judul: 'AC Ruang Kelas D-204 Bocor',
    lokasi: 'Gedung D • Lantai 2',
    status: StatusLaporan.selesai,
    adaFeedback: true,
    catatanAdmin:
        'Saluran pembuangan AC telah dibersihkan dan unit sudah berfungsi normal kembali.',
  ),
  Laporan(
    id: '#SNF-2026-085',
    tanggal: '15 Nov 2026',
    judul: 'Proyektor Lab Komputer 1 Mati',
    lokasi: 'Gedung B • Lantai 1',
    status: StatusLaporan.ditolak,
    adaFeedback: true,
    catatanAdmin:
        'Laporan duplikat dengan tiket #SNF-2026-082 yang sedang ditangani teknisi.',
  ),
  Laporan(
    id: '#SNF-2026-090',
    tanggal: 'Baru Saja',
    judul: 'Kursi Lipat Mahasiswa Patah',
    lokasi: 'Gedung C • Ruang C-102',
    status: StatusLaporan.diproses,
  ),
];

// --------------------------------------------------------------- PAGE

class RiwayatLaporanPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const RiwayatLaporanPage({
    super.key,
    this.onBackToHome,
  });

  @override
  State<RiwayatLaporanPage> createState() => _RiwayatLaporanPageState();
}

class _RiwayatLaporanPageState extends State<RiwayatLaporanPage> {
  final _searchController = TextEditingController();

  final _filters = const [
    'Semua',
    'Diproses',
    'Selesai',
    'Ditolak',
  ];

  int _filterIndex = 0;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Laporan> get _hasil {
    return dataLaporan.where((laporan) {
      final cocokFilter = switch (_filterIndex) {
        1 => laporan.status == StatusLaporan.diproses,
        2 => laporan.status == StatusLaporan.selesai,
        3 => laporan.status == StatusLaporan.ditolak,
        _ => true,
      };

      final q = _query.trim().toLowerCase();

      final cocokCari = q.isEmpty ||
          laporan.judul.toLowerCase().contains(q) ||
          laporan.lokasi.toLowerCase().contains(q) ||
          laporan.id.toLowerCase().contains(q);

      return cocokFilter && cocokCari;
    }).toList();
  }

  void _showDetailSheet(Laporan laporan) {
    final badge = _badgeStyle(laporan.status);

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      laporan.id,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HistoryColors.textGrey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badge.fg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  laporan.judul,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: HistoryColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: HistoryColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HistoryColors.border),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Lokasi', laporan.lokasi),
                      const Divider(height: 1, color: HistoryColors.border),
                      _detailRow('Waktu Lapor', laporan.tanggal),
                    ],
                  ),
                ),
                if (laporan.adaFeedback) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Feedback Admin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: HistoryColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE7FA)),
                    ),
                    child: Text(
                      laporan.catatanAdmin ??
                          'Laporan telah ditinjau oleh Admin SnaFix.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HistoryColors.primary,
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: HistoryColors.textGrey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: HistoryColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _hasil;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: HistoryColors.primary,
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

            // 2. Tata Letak Utama (Header + Konten Melengkung)
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: HistoryColors.background,
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
                          const SizedBox(height: 12),
                          Expanded(
                            child: data.isEmpty
                                ? _buildEmptyState()
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      4,
                                      16,
                                      105,
                                    ),
                                    itemCount: data.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, i) => _LaporanCard(
                                      laporan: data[i],
                                      onTapDetail: () =>
                                          _showDetailSheet(data[i]),
                                    ),
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

  // ------------------------------------------------------------- HEADER

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: widget.onBackToHome ??
                        () => Navigator.maybePop(context),
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
                      'Riwayat Laporan',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pantau progres & status laporanmu',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A0D14).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value);
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: HistoryColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari fasilitas, gedung, atau ID...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: HistoryColors.textGrey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: HistoryColors.primary,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: HistoryColors.textGrey,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- FILTER CHIPS

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final aktif = i == _filterIndex;

          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: aktif ? HistoryColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      aktif ? HistoryColors.primary : HistoryColors.border,
                ),
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w600,
                  color: aktif ? AppColors.white : HistoryColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------- EMPTY STATE

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
                Icons.assignment_outlined,
                color: HistoryColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Laporan tidak ditemukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HistoryColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba gunakan kata kunci pencarian atau filter status lainnya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: HistoryColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------- HELPER BADGE

({String label, Color bg, Color fg}) _badgeStyle(StatusLaporan status) {
  switch (status) {
    case StatusLaporan.selesai:
      return (
        label: 'Selesai',
        bg: const Color(0xFFDDEBFF),
        fg: HistoryColors.primary,
      );

    case StatusLaporan.ditolak:
      return (
        label: 'Ditolak',
        bg: const Color(0xFFFFE1E1),
        fg: const Color(0xFFD93636),
      );

    case StatusLaporan.diproses:
      return (
        label: 'Diproses',
        bg: const Color(0xFFFFF0CC),
        fg: const Color(0xFFB7791F),
      );
  }
}

// --------------------------------------------------------- KARTU LAPORAN

class _LaporanCard extends StatelessWidget {
  final Laporan laporan;
  final VoidCallback onTapDetail;

  const _LaporanCard({
    required this.laporan,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _badgeStyle(laporan.status);
    final diproses = laporan.status == StatusLaporan.diproses;

    return InkWell(
      onTap: onTapDetail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HistoryColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${laporan.id} • ${laporan.tanggal}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: HistoryColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badge.fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFE6EFFF),
                    child: laporan.gambar != null
                        ? Image.asset(
                            laporan.gambar!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: HistoryColors.primary,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laporan.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: HistoryColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: HistoryColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              laporan.lokasi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: HistoryColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              height: 1,
              color: HistoryColors.border,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (diproses)
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Color(0xFFB7791F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sedang diperbaiki',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB7791F),
                        ),
                      ),
                    ],
                  )
                else if (laporan.adaFeedback)
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: HistoryColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Feedback Admin tersedia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: HistoryColors.textGrey,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    Text(
                      'Detail',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HistoryColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: HistoryColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}