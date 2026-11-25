import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';
import 'package:tubes_pemob/services/storage_service.dart';

class HistoryColors {
  static const primary = Color(0xFF0B63F6);
  static const background = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF1B1F2A);
  static const textGrey = Color(0xFF8A92A3);
  static const border = Color(0xFFE8ECF3);
  static const orange = Color(0xFFF5A623);
}

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

  List<ReportModel> _filterReports(List<ReportModel> reports) {
    return reports.where((report) {
      final cocokFilter = switch (_filterIndex) {
        1 => report.status == ReportStatus.reported ||
            report.status == ReportStatus.verified ||
            report.status == ReportStatus.assigned ||
            report.status == ReportStatus.inProgress,
        2 => report.status == ReportStatus.resolved,
        3 => report.status == ReportStatus.rejected,
        _ => true,
      };

      final q = _query.trim().toLowerCase();
      final cocokCari = q.isEmpty ||
          report.assetNama.toLowerCase().contains(q) ||
          report.assetLokasi.toLowerCase().contains(q) ||
          report.deskripsi.toLowerCase().contains(q) ||
          report.id.toLowerCase().contains(q);

      return cocokFilter && cocokCari;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;

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
                    child: uid == null
                        ? const Center(child: Text('Silakan masuk terlebih dahulu.'))
                        : StreamBuilder<List<ReportModel>>(
                            stream: ReportService.instance
                                .streamReportsByPelapor(uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final data = _filterReports(snapshot.data ?? []);
                              if (data.isEmpty) {
                                return _buildEmptyState();
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  105,
                                ),
                                itemCount: data.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _LaporanCard(report: data[i]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

class _LaporanCard extends StatelessWidget {
  final ReportModel report;

  const _LaporanCard({required this.report});

  ({String label, Color bg, Color fg}) get _badge {
    switch (report.status) {
      case ReportStatus.resolved:
        return (
          label: report.status.label,
          bg: const Color(0xFFDDEBFF),
          fg: HistoryColors.primary,
        );
      case ReportStatus.rejected:
        return (
          label: report.status.label,
          bg: const Color(0xFFFFE1E1),
          fg: const Color(0xFFD93636),
        );
      default:
        return (
          label: report.status.label,
          bg: const Color(0xFFFFF0CC),
          fg: const Color(0xFFB7791F),
        );
    }
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.assetNama,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: HistoryColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${report.assetLokasi} • ${report.status.label}',
                style: const TextStyle(
                  fontSize: 12,
                  color: HistoryColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              Text(report.deskripsi, style: const TextStyle(fontSize: 13)),
              if (report.status == ReportStatus.rejected &&
                  (report.rejectionReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Text(
                  'Alasan Penolakan: ${report.rejectionReason}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD93636),
                  ),
                ),
              ],
              if (report.catatanTeknisi?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(
                  'Catatan Teknisi: ${report.catatanTeknisi}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              if (report.status == ReportStatus.reported)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      try {
                        await ReportService.instance.cancelReport(report.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Laporan berhasil dibatalkan.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal membatalkan: $e')),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD93636),
                      side: const BorderSide(color: Color(0xFFD93636)),
                    ),
                    child: const Text('Batalkan Laporan'),
                  ),
                ),
              if (report.status == ReportStatus.resolved && !report.isConfirmed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      try {
                        await ReportService.instance.confirmResolution(
                          report: report,
                          pelaporNama: report.pelaporNama,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Perbaikan dikonfirmasi selesai.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal konfirmasi: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HistoryColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Konfirmasi Selesai'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final shortId = report.id.length > 8
        ? report.id.substring(0, 8).toUpperCase()
        : report.id.toUpperCase();
    final tanggal = DateFormat('dd MMM yyyy').format(report.createdAt);
    final imageBytes = StorageService.instance.base64ToBytes(report.fotoSebelum);
    final diproses = !report.isClosed;
    final adaFeedback = (report.rejectionReason?.isNotEmpty ?? false) ||
        (report.catatanTeknisi?.isNotEmpty ?? false);

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
                  '#$shortId • $tanggal',
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
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
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
                      report.assetNama,
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
                      report.assetLokasi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const Divider(height: 1, color: HistoryColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (diproses)
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: Color(0xFFB7791F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      report.status.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB7791F),
                      ),
                    ),
                  ],
                )
              else if (adaFeedback)
                const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: HistoryColors.textGrey,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Catatan tersedia',
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
                onTap: () => _showActionSheet(context),
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