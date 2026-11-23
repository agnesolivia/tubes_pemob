import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tubes_pemob/constants/app_colors.dart';

// ============================================================
// ENUM STATUS DAN PRIORITAS
// ============================================================

enum ReportStatus {
  reported,
  verified,
  assigned,
  inProgress,
  resolved,
  rejected,
}

enum ReportPriority {
  high,
  medium,
  low,
}

// ============================================================
// MODEL DATA LAPORAN
// ============================================================

class KelolaLaporanData {
  final String id;
  final String title;
  final String location;
  final String description;
  final String reporterName;
  final String reporterRole;
  final DateTime createdAt;
  final IconData icon;
  final List<String> photoUrls;

  ReportStatus status;
  ReportPriority? priority;
  DateTime? deadlineAt;
  String? technician;
  String? rejectionReason;

  final List<KelolaLaporanHistory> history;

  KelolaLaporanData({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.reporterName,
    required this.reporterRole,
    required this.createdAt,
    required this.icon,
    required this.status,
    this.priority,
    this.deadlineAt,
    this.technician,
    this.rejectionReason,
    this.photoUrls = const [],
    this.history = const [],
  });
}

// ============================================================
// MODEL RIWAYAT STATUS
// ============================================================

class KelolaLaporanHistory {
  final ReportStatus status;
  final DateTime date;
  final String description;

  const KelolaLaporanHistory({
    required this.status,
    required this.date,
    required this.description,
  });
}

// ============================================================
// KELOLA LAPORAN SCREEN
// ============================================================

class KelolaLaporanScreen extends StatefulWidget {
  final KelolaLaporanData report;
  final List<String> technicians;
  final VoidCallback? onChanged;

  const KelolaLaporanScreen({
    super.key,
    required this.report,
    this.technicians = const [],
    this.onChanged,
  });

  @override
  State<KelolaLaporanScreen> createState() =>
      _KelolaLaporanScreenState();
}

class _KelolaLaporanScreenState extends State<KelolaLaporanScreen> {
  late ReportStatus _currentStatus;
  late ReportPriority? _currentPriority;
  late DateTime? _deadlineAt;
  late String? _currentTechnician;
  late String? _rejectionReason;

  final TextEditingController _rejectionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.report.status;
    _currentPriority = widget.report.priority;
    _deadlineAt = widget.report.deadlineAt;
    _currentTechnician = widget.report.technician;
    _rejectionReason = widget.report.rejectionReason;
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  // ==========================================================
  // STATUS LABEL
  // ==========================================================

  String _statusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return 'Dilaporkan';

      case ReportStatus.verified:
        return 'Terverifikasi';

      case ReportStatus.assigned:
        return 'Ditugaskan';

      case ReportStatus.inProgress:
        return 'Dalam Pengerjaan';

      case ReportStatus.resolved:
        return 'Selesai';

      case ReportStatus.rejected:
        return 'Ditolak';
    }
  }

  // ==========================================================
  // PRIORITY LABEL
  // ==========================================================

  String _priorityLabel(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.high:
        return 'Tinggi';

      case ReportPriority.medium:
        return 'Sedang';

      case ReportPriority.low:
        return 'Rendah';
    }
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return AppColors.statusProcessText;

      case ReportStatus.verified:
        return AppColors.statusDoneText;

      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return const Color(0xFF15803D);

      case ReportStatus.resolved:
        return AppColors.statusDoneText;

      case ReportStatus.rejected:
        return AppColors.statusRejectedText;
    }
  }

  Color _statusBackground(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return AppColors.statusProcessBg;

      case ReportStatus.verified:
      case ReportStatus.resolved:
        return AppColors.statusDoneBg;

      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return const Color(0xFFDCFCE7);

      case ReportStatus.rejected:
        return AppColors.statusRejectedBg;
    }
  }

  // ==========================================================
  // PERHITUNGAN DEADLINE SLA
  // ==========================================================

  DateTime _calculateDeadline(ReportPriority priority) {
    final now = DateTime.now();

    switch (priority) {
      case ReportPriority.high:
        return now.add(const Duration(days: 1));

      case ReportPriority.medium:
        return now.add(const Duration(days: 3));

      case ReportPriority.low:
        return now.add(const Duration(days: 7));
    }
  }

  // ==========================================================
  // FORMAT TANGGAL
  // ==========================================================

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

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

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} '
        '${date.year}, $hour:$minute';
  }

  // ==========================================================
  // UPDATE STATUS
  // ==========================================================

  void _updateStatus({
    required ReportStatus status,
    required String description,
  }) {
    setState(() {
      _currentStatus = status;

      widget.report.status = _currentStatus;
      widget.report.priority = _currentPriority;
      widget.report.deadlineAt = _deadlineAt;
      widget.report.technician = _currentTechnician;
      widget.report.rejectionReason = _rejectionReason;
    });

    widget.onChanged?.call();

    _showMessage(
      'Status laporan berhasil diperbarui.',
    );
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: isError
              ? AppColors.statusRejectedText
              : const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryBlue,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,

        // APP BAR
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,

          title: Text(
            'Kelola Laporan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),

          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),

        // MAIN CONTENT
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INFORMASI LAPORAN
              _buildReportHeader(),

              const SizedBox(height: 12),

              // FOTO BUKTI
              _buildPhotoSection(),

              const SizedBox(height: 16),

              // DETAIL LAPORAN
              _buildReportInformation(),

              const SizedBox(height: 14),

              // RIWAYAT STATUS
              _buildStatusHistory(),
            ],
          ),
        ),

        // BOTTOM ACTION
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

// ==========================================================
// CARD DECORATION
// ==========================================================

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0xFFE8EEF6),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

  // ==========================================================
  // REPORT HEADER
  // ==========================================================

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON FASILITAS
          Container(
            width: 56,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE3EEFF),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.report.icon,
              color: AppColors.primaryBlue,
              size: 29,
            ),
          ),

          const SizedBox(width: 11),

          // INFORMASI LAPORAN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${widget.report.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A94A6),
                        ),
                      ),
                    ),

                    _buildStatusBadge(),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  widget.report.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A0D14),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: Color(0xFFEF4444),
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        widget.report.location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      'Dilaporkan: ${_formatDate(widget.report.createdAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS BADGE
  // ==========================================================

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(_currentStatus),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(_currentStatus),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _statusColor(_currentStatus),
        ),
      ),
    );
  }

  // ==========================================================
  // PHOTO SECTION
  // ==========================================================

  Widget _buildPhotoSection() {
    final photos = widget.report.photoUrls;

    return SizedBox(
      height: 115,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildPhotoItem(
              photos.isNotEmpty ? photos[0] : null,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildPhotoItem(
              photos.length > 1 ? photos[1] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String? photoUrl) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: photoUrl == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF94A3B8),
                  size: 30,
                ),

                const SizedBox(height: 5),

                Text(
                  'Foto belum tersedia',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF94A3B8),
                    size: 30,
                  ),
                );
              },
            ),
    );
  }

  // ==========================================================
  // DETAIL LAPORAN
  // ==========================================================

  Widget _buildReportInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Detail Laporan'),

          const SizedBox(height: 12),

          _informationRow(
            icon: Icons.description_outlined,
            label: 'Deskripsi',
            value: widget.report.description,
          ),

          _divider(),

          _informationRow(
            icon: Icons.person_outline_rounded,
            label: 'Pelapor',
            value:
                '${widget.report.reporterName}\n${widget.report.reporterRole}',
          ),

          _divider(),

          _informationRow(
            icon: Icons.monitor_heart_outlined,
            label: 'Status',
            value: _statusLabel(_currentStatus),
          ),

          _divider(),

          _informationRow(
            icon: Icons.flag_outlined,
            label: 'Prioritas',
            value: _currentPriority == null
                ? '-'
                : _priorityLabel(_currentPriority!),
          ),

          _divider(),

          _informationRow(
            icon: Icons.access_time_rounded,
            label: 'Deadline',
            value: _formatDate(_deadlineAt),
          ),

          _divider(),

          _informationRow(
            icon: Icons.engineering_outlined,
            label: 'Teknisi',
            value: _currentTechnician ?? '-',
          ),

          if (_currentStatus == ReportStatus.rejected) ...[
            _divider(),

            _informationRow(
              icon: Icons.cancel_outlined,
              label: 'Alasan',
              value: _rejectionReason ?? '-',
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION ROW
  // ==========================================================

  Widget _informationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 75,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      color: Color(0xFFEDF1F7),
      height: 1,
      thickness: 0.8,
    );
  }

  // ==========================================================
  // RIWAYAT STATUS
  // ==========================================================

  Widget _buildStatusHistory() {
    final history = widget.report.history;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Riwayat Status'),

          const SizedBox(height: 15),

          if (history.isEmpty)
            const _EmptyHistory()
          else
            ...history.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return _HistoryItem(
                status: item.status,
                statusLabel: _statusLabel(item.status),
                date: _formatDate(item.date),
                description: item.description,
                statusColor: _statusColor(item.status),
                backgroundColor: _statusBackground(item.status),
                isLast: index == history.length - 1,
              );
            }),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM ACTION BUTTON
  // ==========================================================

  Widget _buildBottomActions() {
    Widget actionButtons;

    if (_currentStatus == ReportStatus.reported) {
      actionButtons = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showRejectSheet,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
              ),
              label: Text(
                'Tolak Laporan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusRejectedText,
                side: const BorderSide(
                  color: AppColors.statusRejectedText,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _showVerificationSheet,
              icon: const Icon(
                Icons.check_rounded,
                size: 18,
              ),
              label: Text(
                'Verifikasi & Tugaskan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: _primaryButtonStyle(),
            ),
          ),
        ],
      );
    } else if (_currentStatus == ReportStatus.verified) {
      actionButtons = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAssignmentSheet,
          icon: const Icon(Icons.engineering_rounded),
          label: Text(
            'Tugaskan Teknisi',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          style: _primaryButtonStyle(),
        ),
      );
    } else if (_currentStatus == ReportStatus.assigned ||
        _currentStatus == ReportStatus.inProgress) {
      actionButtons = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAssignmentSheet,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: Text(
            'Alihkan Teknisi',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          style: _primaryButtonStyle(),
        ),
      );
    } else {
      actionButtons = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          _currentStatus == ReportStatus.resolved
              ? 'Laporan telah selesai.'
              : 'Laporan telah ditolak.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: actionButtons,
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }

  // ==========================================================
  // VERIFIKASI DAN PENUGASAN
  // ==========================================================

  void _showVerificationSheet() {
    ReportPriority? selectedPriority = _currentPriority;
    String? selectedTechnician;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final deadline = selectedPriority == null
                ? null
                : _calculateDeadline(selectedPriority!);

            return _ActionBottomSheet(
              title: 'Verifikasi & Tugaskan',
              subtitle:
                  'Verifikasi laporan, tentukan prioritas, dan tugaskan teknisi untuk penanganan.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Tingkat Prioritas *'),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _PriorityOption(
                          priority: ReportPriority.high,
                          selected: selectedPriority ==
                              ReportPriority.high,
                          onTap: () {
                            setModalState(() {
                              selectedPriority = ReportPriority.high;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _PriorityOption(
                          priority: ReportPriority.medium,
                          selected: selectedPriority ==
                              ReportPriority.medium,
                          onTap: () {
                            setModalState(() {
                              selectedPriority =
                                  ReportPriority.medium;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _PriorityOption(
                          priority: ReportPriority.low,
                          selected: selectedPriority ==
                              ReportPriority.low,
                          onTap: () {
                            setModalState(() {
                              selectedPriority = ReportPriority.low;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (deadline != null)
                    _DeadlineInformation(
                      deadline: _formatDate(deadline),
                      priority: _priorityLabel(selectedPriority!),
                    ),

                  const SizedBox(height: 20),

                  _sectionTitle('Tugaskan Teknisi'),

                  const SizedBox(height: 10),

                  _TechnicianDropdown(
                    technicians: widget.technicians,
                    selectedTechnician: selectedTechnician,
                    optional: true,
                    onChanged: (value) {
                      setModalState(() {
                        selectedTechnician = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  const _InformationBox(
                    message:
                        'Jika teknisi belum tersedia, laporan akan berstatus Terverifikasi dan dapat ditugaskan nanti.',
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedPriority == null
                          ? null
                          : () {
                              _currentPriority = selectedPriority;
                              _deadlineAt = deadline;
                              _currentTechnician = selectedTechnician;

                              _updateStatus(
                                status: selectedTechnician == null
                                    ? ReportStatus.verified
                                    : ReportStatus.assigned,
                                description: selectedTechnician == null
                                    ? 'Laporan berhasil diverifikasi.'
                                    : 'Laporan ditugaskan kepada $selectedTechnician.',
                              );

                              Navigator.pop(sheetContext);
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        'Simpan Verifikasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: _primaryButtonStyle(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // PENUGASAN / ALIH TEKNISI
  // ==========================================================

  void _showAssignmentSheet() {
    String? selectedTechnician;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isTransfer =
                _currentStatus == ReportStatus.assigned ||
                _currentStatus == ReportStatus.inProgress;

            return _ActionBottomSheet(
              title: isTransfer
                  ? 'Alihkan Teknisi'
                  : 'Tugaskan Teknisi',
              subtitle:
                  'Pilih teknisi yang bertanggung jawab menangani laporan ini.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Pilih Teknisi *'),

                  const SizedBox(height: 12),

                  _TechnicianDropdown(
                    technicians: widget.technicians,
                    selectedTechnician: selectedTechnician,
                    currentTechnician: _currentTechnician,
                    onChanged: (value) {
                      setModalState(() {
                        selectedTechnician = value;
                      });
                    },
                  ),

                  const SizedBox(height: 13),

                  const _InformationBox(
                    message:
                        'Teknisi yang dipilih akan bertanggung jawab menangani laporan ini.',
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedTechnician == null
                          ? null
                          : () {
                              _currentTechnician = selectedTechnician;

                              _updateStatus(
                                status: ReportStatus.assigned,
                                description:
                                    'Laporan ditugaskan kepada $selectedTechnician.',
                              );

                              Navigator.pop(sheetContext);
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        'Simpan Penugasan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: _primaryButtonStyle(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // PENOLAKAN LAPORAN
  // ==========================================================

  void _showRejectSheet() {
    _rejectionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _ActionBottomSheet(
            title: 'Tolak Laporan',
            subtitle:
                'Berikan alasan penolakan agar pelapor mengetahui mengapa laporannya ditolak.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Alasan Penolakan *'),

                const SizedBox(height: 10),

                TextField(
                  controller: _rejectionController,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tuliskan alasan penolakan laporan...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                const _InformationBox(
                  message:
                      'Laporan yang ditolak akan berstatus final.',
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final reason =
                          _rejectionController.text.trim();

                      if (reason.isEmpty) {
                        _showMessage(
                          'Alasan penolakan wajib diisi.',
                          isError: true,
                        );
                        return;
                      }

                      _rejectionReason = reason;

                      _updateStatus(
                        status: ReportStatus.rejected,
                        description:
                            'Laporan ditolak. Alasan: $reason',
                      );

                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: Text(
                      'Konfirmasi Penolakan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusRejectedText,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
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

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

}

// ============================================================
// ACTION BOTTOM SHEET
// ============================================================

class _ActionBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ActionBottomSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE3ED),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: AppColors.statusDoneBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 23),

            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRIORITY OPTION
// ============================================================

class _PriorityOption extends StatelessWidget {
  final ReportPriority priority;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    late Color iconColor;
    late IconData icon;
    late String duration;

    switch (priority) {
      case ReportPriority.high:
        iconColor = const Color(0xFFEF4444);
        icon = Icons.warning_rounded;
        duration = '≤ 1 hari';
        break;

      case ReportPriority.medium:
        iconColor = AppColors.accentYellow;
        icon = Icons.flag_rounded;
        duration = '≤ 3 hari';
        break;

      case ReportPriority.low:
        iconColor = const Color(0xFF13B779);
        icon = Icons.eco_rounded;
        duration = '≤ 7 hari';
        break;
    }

    final label = switch (priority) {
      ReportPriority.high => 'Tinggi',
      ReportPriority.medium => 'Sedang',
      ReportPriority.low => 'Rendah',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF2FF)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : AppColors.border,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 23,
            ),

            const SizedBox(height: 8),

            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              duration,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),

            if (selected) ...[
              const SizedBox(height: 5),

              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryBlue,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DEADLINE INFORMATION
// ============================================================

class _DeadlineInformation extends StatelessWidget {
  final String deadline;
  final String priority;

  const _DeadlineInformation({
    required this.deadline,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryBlue,
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deadline otomatis: $deadline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Berdasarkan prioritas $priority.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TECHNICIAN DROPDOWN
// ============================================================

class _TechnicianDropdown extends StatelessWidget {
  final List<String> technicians;
  final String? selectedTechnician;
  final String? currentTechnician;
  final ValueChanged<String?> onChanged;
  final bool optional;

  const _TechnicianDropdown({
    required this.technicians,
    required this.selectedTechnician,
    required this.onChanged,
    this.currentTechnician,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final availableTechnicians = technicians
        .where((technician) => technician != currentTechnician)
        .toList();

    const noTechnicianValue = '__without_technician__';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFDCE5F1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTechnician,
          isExpanded: true,

          hint: Text(
            technicians.isEmpty && !optional
                ? 'Teknisi belum tersedia'
                : optional
                    ? 'Pilih teknisi (opsional)'
                    : 'Pilih teknisi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),

          items: [
            if (optional)
              DropdownMenuItem<String>(
                value: noTechnicianValue,
                child: Text(
                  'Tanpa teknisi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

            ...availableTechnicians.map(
              (technician) {
                return DropdownMenuItem<String>(
                  value: technician,
                  child: Text(
                    technician,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ],

          onChanged: technicians.isEmpty && !optional
              ? null
              : (value) {
                  onChanged(
                    value == noTechnicianValue ? null : value,
                  );
                },
        ),
      ),
    );
  }
}

// ============================================================
// INFORMATION BOX
// ============================================================

class _InformationBox extends StatelessWidget {
  final String message;

  const _InformationBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY HISTORY
// ============================================================

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        'Riwayat status belum tersedia.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ============================================================
// HISTORY ITEM
// ============================================================

class _HistoryItem extends StatelessWidget {
  final ReportStatus status;
  final String statusLabel;
  final String date;
  final String description;
  final Color statusColor;
  final Color backgroundColor;
  final bool isLast;

  const _HistoryItem({
    required this.status,
    required this.statusLabel,
    required this.date,
    required this.description,
    required this.statusColor,
    required this.backgroundColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 3,
                  ),
                ),
              ),

              if (!isLast)
                Container(
                  width: 2,
                  height: 62,
                  color: const Color(0xFFDCE5F1),
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}