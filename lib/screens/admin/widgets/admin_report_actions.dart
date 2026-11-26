import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/widgets/resolution_action_bar.dart';

/// Model ringan untuk tampilan daftar pilihan teknisi (UI-only).
/// Nantinya tinggal diganti dengan `UserModel` + `streamTechnicianActiveTaskCounts`.
class AdminTechnicianOption {
  final String uid;
  final String nama;
  final String email;
  final int activeTaskCount;

  const AdminTechnicianOption({
    required this.uid,
    required this.nama,
    required this.email,
    required this.activeTaskCount,
  });
}

/// Bagian tombol aksi & modal khusus role Admin pada `DetailLaporanScreen`.
/// Mode saat ini masih UI-only: semua modal/bottom sheet dapat dicoba langsung
/// tanpa menyentuh proses tulis Firestore.
class AdminReportActions extends StatelessWidget {
  final ReportModel report;

  /// Daftar teknisi opsional dari luar. Jika null, memakai daftar dummy untuk preview UI.
  final List<AdminTechnicianOption>? technicians;

  final ValueChanged<String>? onReject;
  final void Function(ReportPriority priority, AdminTechnicianOption? tech)?
      onVerifyAndAssign;
  final ValueChanged<AdminTechnicianOption>? onAssignTechnician;
  final VoidCallback? onConfirmResolution;
  final ValueChanged<String>? onReopenReport;

  const AdminReportActions({
    super.key,
    required this.report,
    this.technicians,
    this.onReject,
    this.onVerifyAndAssign,
    this.onAssignTechnician,
    this.onConfirmResolution,
    this.onReopenReport,
  });

  static const List<AdminTechnicianOption> _dummyTechnicians = [
    AdminTechnicianOption(
      uid: 'tech_01',
      nama: 'Teknisi SnaFix',
      email: 'teknisi1@snafix.id',
      activeTaskCount: 1,
    ),
    AdminTechnicianOption(
      uid: 'tech_02',
      nama: 'Andi Saputra',
      email: 'andi.teknisi@snafix.id',
      activeTaskCount: 3,
    ),
    AdminTechnicianOption(
      uid: 'tech_03',
      nama: 'Dedi Kurniawan',
      email: 'dedi.teknisi@snafix.id',
      activeTaskCount: 0,
    ),
  ];

  List<AdminTechnicianOption> get _effectiveTechnicians =>
      technicians ?? _dummyTechnicians;

  void _showPreviewSnackBar(BuildContext context, String message) {
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
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openRejectDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );

    if (reason == null || reason.isEmpty || !context.mounted) return;

    if (onReject != null) {
      onReject!(reason);
    } else {
      // TODO: Sambungkan ke ReportService.instance.rejectReport(...)
      _showPreviewSnackBar(
        context,
        'UI Preview: Laporan ditolak dengan alasan "$reason".',
      );
    }
  }

  Future<void> _openVerifySheet(BuildContext context) async {
    final result = await showModalBottomSheet<_VerifyResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerifyAndAssignModal(
        technicians: _effectiveTechnicians,
      ),
    );

    if (result == null || !context.mounted) return;

    if (onVerifyAndAssign != null) {
      onVerifyAndAssign!(result.priority, result.technician);
    } else {
      // TODO: Sambungkan ke ReportService.instance.verifyAndAssignReport(...)
      final techInfo = result.technician != null
          ? ' & ditugaskan ke ${result.technician!.nama}'
          : ' (tanpa teknisi dulu)';
      _showPreviewSnackBar(
        context,
        'UI Preview: Diverifikasi dengan Prioritas ${result.priority.label}$techInfo.',
      );
    }
  }

  Future<void> _openAssignSheet(BuildContext context) async {
    final isReassign = report.status != ReportStatus.verified;
    final selected = await showModalBottomSheet<AdminTechnicianOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignTechnicianModal(
        technicians: _effectiveTechnicians,
        currentTechnicianId: report.teknisiId,
        isReassign: isReassign,
      ),
    );

    if (selected == null || !context.mounted) return;

    if (onAssignTechnician != null) {
      onAssignTechnician!(selected);
    } else {
      // TODO: Sambungkan ke ReportService.instance.assignTechnician(...)
      _showPreviewSnackBar(
        context,
        isReassign
            ? 'UI Preview: Tugas dialihkan ke ${selected.nama}.'
            : 'UI Preview: Tugas ditugaskan ke ${selected.nama}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;

    if (report.status == ReportStatus.reported) {
      content = Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openRejectDialog(context),
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
              onPressed: () => _openVerifySheet(context),
              icon: const Icon(Icons.verified_outlined, size: 20),
              label: Text(
                'Verifikasi & Tugaskan',
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
          onPressed: () => _openAssignSheet(context),
          icon: const Icon(Icons.engineering_outlined, size: 20),
          label: Text(
            'Tugaskan Teknisi',
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
          onPressed: () => _openAssignSheet(context),
          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
          label: Text(
            'Alihkan Teknisi',
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
        onConfirm: onConfirmResolution,
        onReopen: onReopenReport,
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
  final AdminTechnicianOption? technician;

  const _VerifyResult({
    required this.priority,
    this.technician,
  });
}

class _VerifyAndAssignModal extends StatefulWidget {
  final List<AdminTechnicianOption> technicians;

  const _VerifyAndAssignModal({required this.technicians});

  @override
  State<_VerifyAndAssignModal> createState() => _VerifyAndAssignModalState();
}

class _VerifyAndAssignModalState extends State<_VerifyAndAssignModal> {
  ReportPriority _selectedPriority = ReportPriority.sedang;
  AdminTechnicianOption? _selectedTechnician;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
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
              Text(
                'Verifikasi & Tetapkan SLA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
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
              _TechnicianOptionList(
                technicians: widget.technicians,
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
  final List<AdminTechnicianOption> technicians;
  final String? currentTechnicianId;
  final bool isReassign;

  const _AssignTechnicianModal({
    required this.technicians,
    this.currentTechnicianId,
    required this.isReassign,
  });

  @override
  State<_AssignTechnicianModal> createState() => _AssignTechnicianModalState();
}

class _AssignTechnicianModalState extends State<_AssignTechnicianModal> {
  AdminTechnicianOption? _selectedTechnician;

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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
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
              Text(
                widget.isReassign ? 'Alihkan Teknisi' : 'Tugaskan Teknisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih teknisi berdasarkan jumlah tugas aktif saat ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _TechnicianOptionList(
                technicians: widget.technicians,
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

class _TechnicianOptionList extends StatelessWidget {
  final List<AdminTechnicianOption> technicians;
  final String? selectedUid;
  final String? disabledUid;
  final bool allowUnassigned;
  final ValueChanged<AdminTechnicianOption?> onSelected;

  const _TechnicianOptionList({
    required this.technicians,
    required this.selectedUid,
    this.disabledUid,
    required this.allowUnassigned,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
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
        if (technicians.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Belum ada akun teknisi terdaftar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...technicians.map((tech) {
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
                onTap: isDisabled ? null : () => onSelected(tech),
              ),
            );
          }),
      ],
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