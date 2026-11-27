import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/report_service.dart';
import 'package:tubes_pemob/widgets/resolution_action_bar.dart';

/// Pasangan data akun teknisi beserta jumlah tugas aktifnya saat ini.
class AdminTechnicianOption {
  final UserModel user;
  final int activeTaskCount;

  const AdminTechnicianOption({
    required this.user,
    required this.activeTaskCount,
  });

  String get uid => user.uid;
  String get nama => user.nama;
  String get email => user.email;
}

/// Bagian tombol aksi & modal khusus role Admin pada `DetailLaporanScreen`.
/// Terhubung langsung ke [ReportService] dan daftar teknisi real-time dari
/// [AuthService.streamTechnicians] + [ReportService.streamTechnicianActiveTaskCounts].
class AdminReportActions extends StatefulWidget {
  final ReportModel report;

  final ValueChanged<String>? onReject;
  final void Function(ReportPriority priority, UserModel? tech)?
      onVerifyAndAssign;
  final ValueChanged<UserModel>? onAssignTechnician;
  final VoidCallback? onConfirmResolution;
  final ValueChanged<String>? onReopenReport;

  const AdminReportActions({
    super.key,
    required this.report,
    this.onReject,
    this.onVerifyAndAssign,
    this.onAssignTechnician,
    this.onConfirmResolution,
    this.onReopenReport,
  });

  @override
  State<AdminReportActions> createState() => _AdminReportActionsState();
}

class _AdminReportActionsState extends State<AdminReportActions> {
  bool _isSubmitting = false;

  Future<UserModel> _resolveCurrentAdmin() async {
    final firebaseUser = AuthService.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan masuk kembali.');
    }

    final user = await AuthService.instance.getUserData(firebaseUser.uid);
    if (user == null || !user.isAdmin) {
      throw Exception('Akses ditolak: akun Anda bukan Admin.');
    }
    return user;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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

  Future<void> _openRejectDialog() async {
    if (_isSubmitting) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    if (widget.onReject != null) {
      widget.onReject!(reason);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final admin = await _resolveCurrentAdmin();
      await ReportService.instance.rejectReport(
        report: widget.report,
        rejectionReason: reason,
        adminNama: admin.nama,
      );
      _showSnackBar('Laporan berhasil ditolak.');
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(cleanMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openVerifySheet() async {
    if (_isSubmitting) return;

    final result = await showModalBottomSheet<_VerifyResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VerifyAndAssignModal(),
    );

    if (result == null || !mounted) return;

    if (widget.onVerifyAndAssign != null) {
      widget.onVerifyAndAssign!(result.priority, result.technician);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final admin = await _resolveCurrentAdmin();
      await ReportService.instance.verifyAndAssignReport(
        report: widget.report,
        prioritas: result.priority,
        adminNama: admin.nama,
        teknisi: result.technician,
      );

      final message = result.technician != null
          ? 'Laporan diverifikasi & ditugaskan ke ${result.technician!.nama}.'
          : 'Laporan berhasil diverifikasi (Prioritas ${result.priority.label}).';
      _showSnackBar(message);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(cleanMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openAssignSheet() async {
    if (_isSubmitting) return;

    final isReassign = widget.report.status != ReportStatus.verified;
    final selected = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignTechnicianModal(
        currentTechnicianId: widget.report.teknisiId,
        isReassign: isReassign,
      ),
    );

    if (selected == null || !mounted) return;

    if (widget.onAssignTechnician != null) {
      widget.onAssignTechnician!(selected);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final admin = await _resolveCurrentAdmin();
      await ReportService.instance.assignTechnician(
        report: widget.report,
        teknisi: selected,
        adminNama: admin.nama,
      );
      _showSnackBar(
        isReassign
            ? 'Tugas berhasil dialihkan ke ${selected.nama}.'
            : 'Tugas berhasil ditugaskan ke ${selected.nama}.',
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(cleanMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    Widget? content;

    if (report.status == ReportStatus.reported) {
      content = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _openRejectDialog,
              icon: const Icon(Icons.close_rounded, size: 19),
              label: Text(
                'Tolak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusRejectedText,
                side: const BorderSide(color: AppColors.statusRejectedText),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _openVerifySheet,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified_outlined, size: 20),
              label: Text(
                _isSubmitting ? 'Memproses...' : 'Verifikasi & Tugaskan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
      );
    } else if (report.status == ReportStatus.verified) {
      content = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _openAssignSheet,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.engineering_outlined, size: 20),
          label: Text(
            _isSubmitting ? 'Menugaskan...' : 'Tugaskan Teknisi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
      );
    } else if (report.status == ReportStatus.assigned ||
        report.status == ReportStatus.inProgress) {
      content = SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _openAssignSheet,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.swap_horiz_rounded, size: 20),
          label: Text(
            _isSubmitting ? 'Mengalihkan...' : 'Alihkan Teknisi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: const BorderSide(color: AppColors.primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );
    } else if (report.isAwaitingConfirmation) {
      content = ResolutionActionBar(
        report: report,
        onConfirm: widget.onConfirmResolution,
        onReopen: widget.onReopenReport,
      );
    }

    if (content == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}

// ============================================================
// MODAL BOTTOM SHEET: VERIFIKASI & TETAPKAN SLA
// ============================================================

class _VerifyResult {
  final ReportPriority priority;
  final UserModel? technician;

  const _VerifyResult({
    required this.priority,
    this.technician,
  });
}

class _VerifyAndAssignModal extends StatefulWidget {
  const _VerifyAndAssignModal();

  @override
  State<_VerifyAndAssignModal> createState() => _VerifyAndAssignModalState();
}

class _VerifyAndAssignModalState extends State<_VerifyAndAssignModal> {
  late final Stream<List<UserModel>> _techniciansStream;
  late final Stream<Map<String, int>> _taskCountsStream;

  ReportPriority _selectedPriority = ReportPriority.sedang;
  UserModel? _selectedTechnician;

  @override
  void initState() {
    super.initState();
    _techniciansStream = AuthService.instance.streamTechnicians();
    _taskCountsStream =
        ReportService.instance.streamTechnicianActiveTaskCounts();
  }

  String _formatPreviewDeadline(ReportPriority priority) {
    final target = DateTime.now().add(Duration(hours: priority.slaHours));
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
    final hour = target.hour.toString().padLeft(2, '0');
    final minute = target.minute.toString().padLeft(2, '0');
    return '${target.day} ${months[target.month - 1]} ${target.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verifikasi & Tetapkan SLA',
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
              Text(
                'Pilih tingkat prioritas untuk menghitung tenggat SLA secara otomatis.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Tingkat Prioritas (Wajib)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ReportPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  final slaText = priority.slaHours >= 24
                      ? '${priority.slaHours ~/ 24} hari'
                      : '${priority.slaHours} jam';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: priority == ReportPriority.rendah ? 0 : 8,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () =>
                            setState(() => _selectedPriority = priority),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.statusDoneBg
                                : const Color(0xFFF7F9FD),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                priority.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SLA $slaText',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tenggat SLA: ${_formatPreviewDeadline(_selectedPriority)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Tugaskan Teknisi (Opsional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _LiveTechnicianPicker(
                techniciansStream: _techniciansStream,
                taskCountsStream: _taskCountsStream,
                selectedUid: _selectedTechnician?.uid,
                allowUnassigned: true,
                onSelected: (tech) =>
                    setState(() => _selectedTechnician = tech),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _VerifyResult(
                        priority: _selectedPriority,
                        technician: _selectedTechnician,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _selectedTechnician != null
                        ? 'Verifikasi & Tugaskan'
                        : 'Verifikasi Tanpa Teknisi',
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
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODAL BOTTOM SHEET: TUGASKAN / ALIHKAN TEKNISI
// ============================================================

class _AssignTechnicianModal extends StatefulWidget {
  final String? currentTechnicianId;
  final bool isReassign;

  const _AssignTechnicianModal({
    this.currentTechnicianId,
    required this.isReassign,
  });

  @override
  State<_AssignTechnicianModal> createState() => _AssignTechnicianModalState();
}

class _AssignTechnicianModalState extends State<_AssignTechnicianModal> {
  late final Stream<List<UserModel>> _techniciansStream;
  late final Stream<Map<String, int>> _taskCountsStream;

  UserModel? _selectedTechnician;

  @override
  void initState() {
    super.initState();
    _techniciansStream = AuthService.instance.streamTechnicians();
    _taskCountsStream =
        ReportService.instance.streamTechnicianActiveTaskCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isReassign ? 'Alihkan Teknisi' : 'Tugaskan Teknisi',
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
              Text(
                'Pilih teknisi berdasarkan jumlah tugas aktif saat ini (diurutkan dari beban paling ringan).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _LiveTechnicianPicker(
                techniciansStream: _techniciansStream,
                taskCountsStream: _taskCountsStream,
                selectedUid: _selectedTechnician?.uid,
                disabledUid:
                    widget.isReassign ? widget.currentTechnicianId : null,
                allowUnassigned: false,
                onSelected: (tech) =>
                    setState(() => _selectedTechnician = tech),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedTechnician == null
                      ? null
                      : () => Navigator.pop(context, _selectedTechnician),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    widget.isReassign ? 'Konfirmasi Pengalihan' : 'Tugaskan',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTechnicianPicker extends StatelessWidget {
  final Stream<List<UserModel>> techniciansStream;
  final Stream<Map<String, int>> taskCountsStream;
  final String? selectedUid;
  final String? disabledUid;
  final bool allowUnassigned;
  final ValueChanged<UserModel?> onSelected;

  const _LiveTechnicianPicker({
    required this.techniciansStream,
    required this.taskCountsStream,
    required this.selectedUid,
    this.disabledUid,
    required this.allowUnassigned,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: techniciansStream,
      builder: (context, techSnap) {
        if (techSnap.connectionState == ConnectionState.waiting &&
            !techSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (techSnap.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusRejectedBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Gagal memuat daftar teknisi: ${techSnap.error}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.statusRejectedText,
              ),
            ),
          );
        }

        final users = techSnap.data ?? const <UserModel>[];

        return StreamBuilder<Map<String, int>>(
          stream: taskCountsStream,
          builder: (context, countSnap) {
            final counts = countSnap.data ?? const <String, int>{};

            final options = users
                .map(
                  (u) => AdminTechnicianOption(
                    user: u,
                    activeTaskCount: counts[u.uid] ?? 0,
                  ),
                )
                .toList()
              ..sort((a, b) {
                final cmpCount = a.activeTaskCount.compareTo(b.activeTaskCount);
                if (cmpCount != 0) return cmpCount;
                return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
              });

            return Column(
              children: [
                if (allowUnassigned) ...[
                  _buildTile(
                    title: 'Tugaskan Nanti (Verifikasi Saja)',
                    subtitle: 'Status menjadi Diverifikasi',
                    isSelected: selectedUid == null,
                    isDisabled: false,
                    badgeText: null,
                    onTap: () => onSelected(null),
                  ),
                  const SizedBox(height: 8),
                ],
                if (options.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Belum ada akun teknisi terdaftar. Aktifkan akun teknisi melalui menu Kelola Teknisi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  )
                else
                  ...options.map((tech) {
                    final isDisabled = disabledUid == tech.uid;
                    final isSelected = selectedUid == tech.uid;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTile(
                        title: tech.nama,
                        subtitle: isDisabled
                            ? '${tech.email} • Sedang ditugaskan'
                            : tech.email,
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        badgeText: '${tech.activeTaskCount} tugas aktif',
                        onTap: isDisabled ? null : () => onSelected(tech.user),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDisabled,
    required String? badgeText,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.statusDoneBg
                : const Color(0xFFF7F9FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color:
                    isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Tolak Laporan',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berikan alasan penolakan yang jelas untuk pelapor.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: Laporan duplikat / fasilitas normal',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.4,
                  ),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Alasan penolakan wajib diisi.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusRejectedText,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          child: Text(
            'Tolak',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
