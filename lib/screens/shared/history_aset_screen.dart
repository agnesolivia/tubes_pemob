import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/asset_model.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/kelola_aset_screen.dart';
import 'package:tubes_pemob/screens/admin/tambah_aset_screen.dart';
import 'package:tubes_pemob/screens/pelapor/form_pengaduan_screen.dart';
import 'package:tubes_pemob/screens/shared/detail_laporan_screen.dart';
import 'package:tubes_pemob/services/asset_service.dart';
import 'package:tubes_pemob/services/report_service.dart';

class HistoryAssetScreen extends StatefulWidget {
  final String? assetId;
  final AssetModel? initialAsset;
  final String? fallbackNama;
  final String? fallbackLokasi;
  final UserRole userRole;

  const HistoryAssetScreen({
    super.key,
    required this.assetId,
    this.initialAsset,
    this.fallbackNama,
    this.fallbackLokasi,
    this.userRole = UserRole.pelapor,
  });

  @override
  State<HistoryAssetScreen> createState() => _HistoryAssetScreenState();
}

class _HistoryAssetScreenState extends State<HistoryAssetScreen> {
  String _selectedFilter = 'Semua';

  Future<AssetModel?>? _assetFuture;
  Stream<List<ReportModel>>? _reportsStream;

  bool get _isRegisteredAsset =>
      widget.assetId != null && widget.assetId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isRegisteredAsset) {
      final cleanAssetId = widget.assetId!.trim();
      _assetFuture = AssetService.instance.getAssetById(cleanAssetId);
      _reportsStream = ReportService.instance.streamReportsByAsset(cleanAssetId);
    }
  }

  String _resolveNama(AssetModel? asset) {
    if (asset != null && asset.nama.trim().isNotEmpty) {
      return asset.nama.trim();
    }
    if (widget.fallbackNama != null && widget.fallbackNama!.trim().isNotEmpty) {
      return widget.fallbackNama!.trim();
    }
    return 'Fasilitas Tanpa Nama';
  }

  String _resolveLokasi(AssetModel? asset) {
    if (asset != null && asset.lokasiLengkap.trim().isNotEmpty) {
      return asset.lokasiLengkap;
    }
    if (widget.fallbackLokasi != null &&
        widget.fallbackLokasi!.trim().isNotEmpty) {
      return widget.fallbackLokasi!.trim();
    }
    return 'Lokasi tidak diketahui';
  }

  String _resolveKategori(AssetModel? asset) {
    if (asset != null && asset.kategori.trim().isNotEmpty) {
      return asset.kategori.trim();
    }
    return 'Lainnya';
  }

  String _formatDate(DateTime date) {
    const months = [
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
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  List<ReportModel> _applyFilter(List<ReportModel> reports) {
    if (_selectedFilter == 'Aktif') {
      return reports.where((r) => r.isActive).toList();
    }
    if (_selectedFilter == 'Selesai') {
      return reports.where((r) => r.status == ReportStatus.resolved).toList();
    }
    return reports;
  }

  ({String? gedung, String? ruangan}) _parseFallbackLocation() {
    final raw = widget.fallbackLokasi?.trim() ?? '';
    if (raw.isEmpty) return (gedung: null, ruangan: null);

    final separatorIndex = raw.indexOf(' - ');
    if (separatorIndex != -1) {
      final gedung = raw.substring(0, separatorIndex).trim();
      final ruangan = raw.substring(separatorIndex + 3).trim();
      return (
        gedung: gedung.isEmpty ? null : gedung,
        ruangan: ruangan.isEmpty ? null : ruangan,
      );
    }

    return (gedung: raw, ruangan: null);
  }

  void _openTambahAset() {
    final parsedLocation = _parseFallbackLocation();
    final rawNama = widget.fallbackNama?.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahAsetScreen(
          initialNama: (rawNama != null && rawNama.isNotEmpty) ? rawNama : null,
          initialGedung: parsedLocation.gedung,
          initialRuangan: parsedLocation.ruangan,
        ),
      ),
    );
  }

  void _openReportDetail(ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailLaporanScreen(
          reportId: report.id,
          initialReport: report,
          userRole: widget.userRole,
          fromAssetHistory: true,
        ),
      ),
    );
  }

  void _openFormPengaduan(AssetModel asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReportScreen(selectedAsset: asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRegisteredAsset) {
      return _buildScaffold(
        body: _buildUnregisteredBody(),
        bottomNavigationBar: null,
      );
    }

    return FutureBuilder<AssetModel?>(
      future: _assetFuture,
      initialData: widget.initialAsset,
      builder: (context, assetSnapshot) {
        final resolvedAsset = assetSnapshot.data ?? widget.initialAsset;
        final isAssetLoading =
            assetSnapshot.connectionState == ConnectionState.waiting &&
            resolvedAsset == null;

        return _buildScaffold(
          body: StreamBuilder<List<ReportModel>>(
            stream: _reportsStream,
            builder: (context, reportSnapshot) {
              if (reportSnapshot.hasError) {
                return _buildErrorBody(
                  'Gagal memuat riwayat aset: ${reportSnapshot.error}',
                );
              }

              final isReportsLoading =
                  reportSnapshot.connectionState == ConnectionState.waiting &&
                  !reportSnapshot.hasData;

              if (isAssetLoading && isReportsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              final reports = reportSnapshot.data ?? const <ReportModel>[];
              return _buildRegisteredBody(
                asset: resolvedAsset,
                reports: reports,
                isReportsLoading: isReportsLoading,
              );
            },
          ),
          bottomNavigationBar: _buildBottomBar(
            resolvedAsset,
            isAssetLoading: isAssetLoading,
          ),
        );
      },
    );
  }

  Widget _buildScaffold({
    required Widget body,
    required Widget? bottomNavigationBar,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Riwayat Aset',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  // ===========================================================================
  // SKENARIO 1: ASET TERDAFTAR (assetId != null)
  // ===========================================================================

  Widget _buildRegisteredBody({
    required AssetModel? asset,
    required List<ReportModel> reports,
    required bool isReportsLoading,
  }) {
    final activeCount = reports.where((r) => r.isActive).length;
    final resolvedCount =
        reports.where((r) => r.status == ReportStatus.resolved).length;
    final hasActiveReport = activeCount > 0;
    final visibleReports = _applyFilter(reports);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kartu Info Aset & Ringkasan Metrik
          _buildAssetHeaderCard(
            asset: asset,
            totalCount: reports.length,
            activeCount: activeCount,
            resolvedCount: resolvedCount,
          ),
          const SizedBox(height: 14),

          // 2. Banner Pencegahan Laporan Ganda (jika masih ada tiket aktif)
          if (hasActiveReport) ...[
            _buildActiveTicketBanner(activeCount),
            const SizedBox(height: 18),
          ],

          // 3. Header Section + Filter Chip
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rekam Jejak Kerusakan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${visibleReports.length} laporan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFilterChips(),
          const SizedBox(height: 14),

          // 4. Daftar Riwayat / Loading / Empty State
          if (isReportsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
            )
          else if (reports.isEmpty)
            _buildEmptyHistory(isFilteredEmpty: false)
          else if (visibleReports.isEmpty)
            _buildEmptyHistory(isFilteredEmpty: true)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleReports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildReportHistoryCard(visibleReports[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetHeaderCard({
    required AssetModel? asset,
    required int totalCount,
    required int activeCount,
    required int resolvedCount,
  }) {
    final kategori = _resolveKategori(asset);
    final nama = _resolveNama(asset);
    final lokasi = _resolveLokasi(asset);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.statusDoneBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  getAssetCategoryIcon(kategori),
                  color: AppColors.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusDoneBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kategori,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      nama,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lokasi,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Total Laporan',
                  value: '$totalCount',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  label: 'Sedang Aktif',
                  value: '$activeCount',
                  valueColor: AppColors.statusProcessText,
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  label: 'Selesai',
                  value: '$resolvedCount',
                  valueColor: AppColors.statusSuccessText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTicketBanner(int activeCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusProcessBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.statusProcessText.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.build_circle_outlined,
            color: AppColors.statusProcessText,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kerusakan Sedang Ditangani ($activeCount tiket aktif)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.statusProcessText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masih terdapat laporan aktif pada aset ini. Pastikan kendala yang ingin dilaporkan berbeda untuk menghindari laporan ganda.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['Semua', 'Aktif', 'Selesai'];

    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
            selectedColor: AppColors.primaryBlue,
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportHistoryCard(ReportModel report) {
    final statusStyle = _getStatusStyle(report.status);
    final hasTeknisi =
        report.teknisiNama != null && report.teknisiNama!.trim().isNotEmpty;
    final actorLabel = hasTeknisi
        ? '${report.pelaporNama} • ${report.teknisiNama}'
        : report.pelaporNama;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openReportDetail(report),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Badge Status + Badge Tambahan + Panah
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusStyle.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.status.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusStyle.text,
                            ),
                          ),
                        ),
                        if (report.isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusRejectedBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Overdue SLA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusRejectedText,
                              ),
                            ),
                          ),
                        if (report.isConfirmed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Terkonfirmasi',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (report.isAwaitingConfirmation)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusProcessBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Menunggu Konfirmasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusProcessText,
                              ),
                            ),
                          )
                        else if (report.prioritas != null)
                          Text(
                            'Prioritas ${report.prioritas!.label}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Deskripsi Kerusakan
              Text(
                report.deskripsi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),

              // Metadata Pelapor, Teknisi, & Tanggal
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      actorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(report.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory({required bool isFilteredEmpty}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isFilteredEmpty
                  ? AppColors.inputFill
                  : AppColors.statusSuccessBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isFilteredEmpty
                  ? Icons.filter_list_off_rounded
                  : Icons.check_circle_outline_rounded,
              color: isFilteredEmpty
                  ? AppColors.primaryBlue
                  : AppColors.statusSuccessText,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFilteredEmpty
                ? 'Tidak Ada Laporan $_selectedFilter'
                : 'Belum Ada Riwayat Kerusakan',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFilteredEmpty
                ? 'Tidak ditemukan laporan dengan filter "$_selectedFilter" pada aset ini.'
                : 'Belum ada riwayat kerusakan untuk aset ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: AppColors.statusRejectedText,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SKENARIO 2: FASILITAS LAINNYA / BELUM TERDAFTAR (assetId == null)
  // ===========================================================================

  Widget _buildUnregisteredBody() {
    final displayNama = _resolveNama(null);
    final displayLokasi = _resolveLokasi(null);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(
        children: [
          // Kartu Info Fasilitas Fallback
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.statusProcessBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.statusProcessText,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusProcessBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Belum Terdaftar di Inventaris',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusProcessText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayNama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayLokasi,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kartu Penjelasan + Tombol Daftar Aset Baru (Khusus Admin)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 32,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Rekam Jejak Tidak Tersedia',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fasilitas ini dilaporkan secara manual melalui opsi Fasilitas Lainnya sehingga belum tercatat di master inventaris dan belum memiliki riwayat kerusakan per unit.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (widget.userRole == UserRole.admin) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openTambahAset,
                      icon: const Icon(Icons.add_box_outlined, size: 20),
                      label: Text(
                        'Daftarkan sebagai Aset Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol bawah hanya tampil untuk Pelapor saat melihat aset terdaftar (alur Scan QR -> Lapor)
  Widget? _buildBottomBar(
    AssetModel? resolvedAsset, {
    required bool isAssetLoading,
  }) {
    if (!_isRegisteredAsset || widget.userRole != UserRole.pelapor) {
      return null;
    }

    if (resolvedAsset == null && !isAssetLoading) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: resolvedAsset == null
                ? null
                : () => _openFormPengaduan(resolvedAsset),
            icon: const Icon(Icons.report_problem_outlined, size: 20),
            label: Text(
              resolvedAsset == null
                  ? 'Memuat Data Aset...'
                  : 'Buat Laporan untuk Aset Ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _StatusBadgeStyle _getStatusStyle(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return const _StatusBadgeStyle(
          bg: AppColors.inputFill,
          text: AppColors.textSecondary,
        );
      case ReportStatus.verified:
      case ReportStatus.assigned:
        return const _StatusBadgeStyle(
          bg: AppColors.statusDoneBg,
          text: AppColors.statusDoneText,
        );
      case ReportStatus.inProgress:
        return const _StatusBadgeStyle(
          bg: AppColors.statusProcessBg,
          text: AppColors.statusProcessText,
        );
      case ReportStatus.resolved:
        return const _StatusBadgeStyle(
          bg: AppColors.statusSuccessBg,
          text: AppColors.statusSuccessText,
        );
      case ReportStatus.rejected:
        return const _StatusBadgeStyle(
          bg: AppColors.statusRejectedBg,
          text: AppColors.statusRejectedText,
        );
    }
  }
}

class _StatusBadgeStyle {
  final Color bg;
  final Color text;

  const _StatusBadgeStyle({
    required this.bg,
    required this.text,
  });
}
