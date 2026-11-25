
import 'package:flutter/material.dart';

class DetailColors {
  static const primary = Color(0xFF0B63F6);
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const placeholder = Color(0xFFE2E7F5);
  static const placeholderIcon = Color(0xFF5B6FE0);
  static const badgeBg = Color(0xFFFFF0CC);
  static const badgeText = Color(0xFFB7791F);
  static const tahap = Color(0xFFE08A00);
}

class DetailLaporanPage extends StatelessWidget {
  final String id;
  final String tanggal;
  final String judul;
  final String lokasi;
  final String status;
  final String kategori;
  final String detailLokasi;
  final String dilaporkan;
  final String deskripsi;
  final String? gambar;

  final List<String> fotoPaths;

  final String waktuDikirim;
  final String waktuVerifikasi;
  final String waktuPerbaikan;
  final String waktuSelesai;
  final String catatanAdmin;

  const DetailLaporanPage({
    super.key,
    required this.id,
    required this.tanggal,
    required this.judul,
    required this.lokasi,
    required this.status,
    this.kategori = '-',
    this.detailLokasi = '-',
    this.dilaporkan = '-',
    this.deskripsi = 'Belum ada deskripsi laporan.',
    this.gambar,
    this.fotoPaths = const [],
    this.waktuDikirim = '-',
    this.waktuVerifikasi = '-',
    this.waktuPerbaikan = '-',
    this.waktuSelesai = '-',
    this.catatanAdmin = '-',
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return DetailColors.badgeText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DetailColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(),
                  _buildPhoto(),
                  _buildInformation(),
                  _buildDescription(),
                  _buildTimeline(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 28),
      decoration: const BoxDecoration(
        color: DetailColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              const Expanded(
                child: Text(
                  'Detail Laporan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Text(
            id,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tanggal,
                  style: const TextStyle(
                    color: DetailColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            judul,
            style: const TextStyle(
              color: DetailColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
  final List<String> photos = fotoPaths.isNotEmpty
      ? fotoPaths
      : (gambar != null && gambar!.isNotEmpty ? [gambar!] : []);

  if (photos.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 210,
          color: DetailColors.placeholder,
          child: _photoPlaceholder(),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  photos[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder(),
                ),
              );
            },
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${photos.length} foto laporan',
              style: const TextStyle(
                color: DetailColors.textGrey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _photoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 48,
          color: DetailColors.placeholderIcon,
        ),
        SizedBox(height: 8),
        Text(
          'Foto laporan belum tersedia',
          style: TextStyle(
            color: DetailColors.textGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInformation() {
  return _section(
    title: 'Informasi Laporan',
    child: Column(
      children: [
        _infoRow('Kategori', kategori),
        _infoRow('Lokasi', lokasi),
        _infoRow('Detail Lokasi', detailLokasi),
        _infoRow('Waktu Dilaporkan', dilaporkan),
      ],
    ),
  );
}

Widget _buildDescription() {
  final deskripsiTampil = deskripsi.trim().isEmpty
      ? 'Belum ada deskripsi laporan.'
      : deskripsi;

  return _section(
    title: 'Deskripsi Laporan',
    child: Text(
      deskripsiTampil,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        color: DetailColors.textGrey,
        fontSize: 13,
        height: 1.6,
      ),
    ),
  );
}

Widget _buildTimeline() {
  final tahapLaporan = [
    (
      'Laporan Dikirim',
      true,
      false,
      waktuDikirim,
    ),
    (
      status == 'Ditolak'
          ? 'Laporan Ditolak'
          : 'Menunggu Verifikasi Admin',
      status == 'Diproses' ||
          status == 'Selesai' ||
          status == 'Ditolak',
      false,
      waktuVerifikasi,
    ),
    (
      'Sedang Diperbaiki',
      status == 'Selesai',
      status == 'Diproses',
      waktuPerbaikan,
    ),
    (
      'Selesai',
      status == 'Selesai',
      false,
      waktuSelesai,
    ),
  ];

  return _section(
    title: 'Riwayat Status',
    child: Column(
      children: List.generate(tahapLaporan.length, (index) {
        final tahap = tahapLaporan[index];
        final selesai = tahap.$2;
        final berjalan = tahap.$3;
        final waktu = tahap.$4;
        final terakhir = index == tahapLaporan.length - 1;

        final warna = selesai
            ? DetailColors.primary
            : berjalan
                ? DetailColors.tahap
                : DetailColors.textGrey;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  selesai
                      ? Icons.check_circle
                      : berjalan
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  color: warna,
                  size: 21,
                ),
                if (!terakhir)
                  Container(
                    width: 2,
                    height: 55,
                    color: DetailColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tahap.$1,
                      style: TextStyle(
                        color: berjalan || selesai
                            ? DetailColors.textDark
                            : DetailColors.textGrey,
                        fontSize: 13,
                        fontWeight: berjalan || selesai
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (waktu != '-')
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          waktu,
                          style: const TextStyle(
                            color: DetailColors.textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (status == 'Ditolak' && index == 1 &&
                        catatanAdmin != '-')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Catatan admin: $catatanAdmin',
                          style: const TextStyle(
                            color: DetailColors.textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    ),
  );
}

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DetailColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DetailColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: DetailColors.textGrey,
                fontSize: 12,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: DetailColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
