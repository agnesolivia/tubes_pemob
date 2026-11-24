
import 'package:flutter/material.dart';

// --------------------------------------------------------------- COLORS

class HistoryColors {
  static const primary = Color(0xFF0B63F6);
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

  const Laporan({
    required this.id,
    required this.tanggal,
    required this.judul,
    required this.lokasi,
    required this.status,
    this.adaFeedback = false,
    this.gambar,
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
  ),
  Laporan(
    id: '#SNF-2026-085',
    tanggal: '15 Nov 2026',
    judul: 'Proyektor Lab Komputer 1 Mati',
    lokasi: 'Gedung B • Lantai 1',
    status: StatusLaporan.ditolak,
    adaFeedback: true,
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
  const RiwayatLaporanPage({super.key});

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
  int _navIndex = 1;
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

      final q = _query.toLowerCase();

      final cocokCari = q.isEmpty ||
          laporan.judul.toLowerCase().contains(q) ||
          laporan.lokasi.toLowerCase().contains(q) ||
          laporan.id.toLowerCase().contains(q);

      return cocokFilter && cocokCari;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _hasil;

    return Scaffold(
      backgroundColor: HistoryColors.primary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: data.isEmpty
                        ? const Center(
                            child: Text(
                              'Laporan tidak ditemukan',
                              style: TextStyle(
                                color: HistoryColors.textGrey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              16, 4, 16, 24,
                            ),
                            itemCount: data.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _LaporanCard(laporan: data[i]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ------------------------------------------------------------- HEADER

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Riwayat Laporan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value);
                },
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Cari fasilitas, gedung, atau ID...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: HistoryColors.textGrey,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: HistoryColors.textGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final aktif = i == _filterIndex;

          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: aktif ? HistoryColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: aktif
                      ? HistoryColors.primary
                      : HistoryColors.border,
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      aktif ? FontWeight.w700 : FontWeight.w500,
                  color: aktif
                      ? Colors.white
                      : HistoryColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------- BOTTOM NAVIGATION

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  _navItem(Icons.home_rounded, 'Beranda', 0),
                  _navItem(Icons.assignment_outlined, 'Riwayat', 1),
                  const Expanded(child: SizedBox()),
                  _navItem(Icons.notifications_none, 'Notifikasi', 2),
                  _navItem(Icons.person_outline, 'Profil', 3),
                ],
              ),
              Positioned(
                top: -28,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: HistoryColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: HistoryColors.orange,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D0B63F6),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final aktif = _navIndex == index;
    final color = aktif
        ? HistoryColors.primary
        : HistoryColors.textGrey;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _navIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight:
                    aktif ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------- KARTU LAPORAN

class _LaporanCard extends StatelessWidget {
  final Laporan laporan;

  const _LaporanCard({required this.laporan});

  ({String label, Color bg, Color fg}) get _badge {
    switch (laporan.status) {
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
          fg: Color(0xFFD93636),
        );

      case StatusLaporan.diproses:
        return (
          label: 'Diproses',
          bg: const Color(0xFFFFF0CC),
          fg: Color(0xFFB7791F),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final diproses =
        laporan.status == StatusLaporan.diproses;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 11,
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
                  style: TextStyle(
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFE6EFFF),
                  child: laporan.gambar != null
                      ? Image.asset(
                          laporan.gambar!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: HistoryColors.primary,
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: HistoryColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      laporan.lokasi,
                      style: const TextStyle(
                        fontSize: 11,
                        color: HistoryColors.textGrey,
                      ),
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
                const Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Color(0xFFB7791F),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Sedang diperbaiki',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB7791F),
                      ),
                    ),
                  ],
                )
              else if (laporan.adaFeedback)
                const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: HistoryColors.textGrey,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Feedback Admin tersedia',
                      style: TextStyle(
                        fontSize: 11,
                        color: HistoryColors.textGrey,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Halaman detail laporan belum dibuat.',
                      ),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HistoryColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: HistoryColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
