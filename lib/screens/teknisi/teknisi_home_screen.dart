import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';
import 'package:tubes_pemob/screens/teknisi/daftar_tugas_screen.dart';
import 'package:tubes_pemob/screens/teknisi/detail_laporan_screen.dart';

// ============================================================
// TEKNISI HOME SCREEN
// ============================================================

class TeknisiHomeScreen extends StatefulWidget {
  final String currentUserUid;
  final String technicianName;

  final List<TechnicianTaskItem> tasks;

  final VoidCallback? onNotificationPressed;
  final VoidCallback? onViewAllTasksPressed;
  final ValueChanged<TechnicianTaskItem>? onTaskPressed;

  const TeknisiHomeScreen({
    super.key,
    required this.currentUserUid,
    required this.technicianName,
    this.tasks = const [],
    this.onNotificationPressed,
    this.onViewAllTasksPressed,
    this.onTaskPressed,
  });

  @override
  State<TeknisiHomeScreen> createState() =>
      _TeknisiHomeScreenState();
}

class _TeknisiHomeScreenState extends State<TeknisiHomeScreen> {
  // ==========================================================
  // FILTER TUGAS MILIK TEKNISI
  // ==========================================================

  List<TechnicianTaskItem> get _myTasks {
    return widget.tasks
        .where(
          (task) => task.teknisiId == widget.currentUserUid,
        )
        .toList();
  }

  // ==========================================================
  // JUMLAH TUGAS BARU
  // ==========================================================

  int get _assignedCount {
    return _myTasks
        .where(
          (task) => task.status == ReportStatus.assigned,
        )
        .length;
  }

  // ==========================================================
  // JUMLAH TUGAS SEDANG DIKERJAKAN
  // ==========================================================

  int get _inProgressCount {
    return _myTasks
        .where(
          (task) => task.status == ReportStatus.inProgress,
        )
        .length;
  }

  // ==========================================================
  // JUMLAH TUGAS SELESAI
  // ==========================================================

  int get _resolvedCount {
    return _myTasks
        .where(
          (task) => task.status == ReportStatus.resolved,
        )
        .length;
  }

  // ==========================================================
  // DAFTAR TUGAS AKTIF
  // DIURUTKAN BERDASARKAN DEADLINE TERDEKAT
  // ==========================================================

  List<TechnicianTaskItem> get _activeTasks {
    final tasks = _myTasks.where((task) {
      return task.status == ReportStatus.assigned ||
          task.status == ReportStatus.inProgress;
    }).toList();

    // SLA terdekat didahulukan.
    tasks.sort(
      (a, b) => a.deadlineAt.compareTo(b.deadlineAt),
    );

    return tasks;
  }

  // ==========================================================
  // VIEW ALL TASKS
  // ==========================================================

  void _onViewAllTasksPressed() {
    if (widget.onViewAllTasksPressed != null) {
      widget.onViewAllTasksPressed!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaftarTugasScreen(
          currentUserUid: widget.currentUserUid,
          tasks: widget.tasks,
        ),
      ),
    );
  }

  // ==========================================================
  // NOTIFICATION
  // ==========================================================

  void _onNotificationPressed() {
    if (widget.onNotificationPressed != null) {
      widget.onNotificationPressed!();
    } else {
      _showMessage('Halaman notifikasi belum dihubungkan.');
    }
  }

  // ==========================================================
  // TASK DETAIL
  // ==========================================================

  void _onTaskPressed(TechnicianTaskItem task) {
    if (widget.onTaskPressed != null) {
      widget.onTaskPressed!(task);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporanScreen(
          task: task,
        ),
      ),
    );
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showMessage(String message) {
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
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),

      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,

        body: Stack(
          children: [
            // BACKGROUND WAVE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave_top.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),

            // MAIN CONTENT
            Column(
              children: [
                // HEADER
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      22,
                    ),
                    child: _buildHeader(),
                  ),
                ),

                // WHITE CONTENT
                Expanded(
                  child: Container(
                    width: double.infinity,

                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFBFD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),

                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),

                      padding: const EdgeInsets.fromLTRB(
                        20,
                        22,
                        20,
                        115,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RINGKASAN TUGAS
                          _buildSummarySection(),

                          const SizedBox(height: 30),

                          // TUGAS AKTIF
                          _buildActiveTaskSection(),
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

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LOGO DAN NOTIFIKASI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/snafix_logo.png',
              width: 125,
              height: 40,
              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'SnaFix',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                );
              },
            ),

            // NOTIFICATION BUTTON
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _onNotificationPressed,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.white,
                    size: 29,
                  ),
                ),

                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D55),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // GREETING
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${widget.technicianName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'Teknisi - Fasilitas Kampus USU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // HEADER ILLUSTRATION
            const _TechnicianIllustration(),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // SUMMARY SECTION
  // ==========================================================

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Tugas',

              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A0D14),
              ),
            ),

            GestureDetector(
              onTap: _onViewAllTasksPressed,
              child: Row(
                children: [
                  Text(
                    'Lihat Semua Tugas',

                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(width: 3),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 17),

        // STATUS SUMMARY CARDS
        Row(
          children: [
            Expanded(
              child: _TaskSummaryCard(
                label: 'Baru Ditugaskan',
                count: _assignedCount,
                icon: Icons.assignment_outlined,
                backgroundColor: const Color(0xFFE8F1FF),
                iconColor: AppColors.primaryBlue,
                textColor: const Color(0xFF14213D),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _TaskSummaryCard(
                label: 'Sedang Dikerjakan',
                count: _inProgressCount,
                icon: Icons.build_rounded,
                backgroundColor: const Color(0xFFFFF1E3),
                iconColor: const Color(0xFFC65A0A),
                textColor: const Color(0xFF7C2D12),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _TaskSummaryCard(
                label: 'Selesai',
                count: _resolvedCount,
                icon: Icons.check_circle_outline_rounded,
                backgroundColor: const Color(0xFFE1F7E9),
                iconColor: const Color(0xFF15803D),
                textColor: const Color(0xFF14532D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // ACTIVE TASK SECTION
  // ==========================================================

  Widget _buildActiveTaskSection() {
    final tasks = _activeTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tugas Aktif',

              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A0D14),
              ),
            ),

            // SORT INDICATOR
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryBlue,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Deadline Terdekat',

                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // EMPTY STATE
        if (tasks.isEmpty)
          const _EmptyTaskCard()
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),

              child: _ActiveTaskCard(
                task: task,
                onTap: () => _onTaskPressed(task),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// TASK SUMMARY CARD
// ============================================================

class _TaskSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const _TaskSummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 135,
      ),

      padding: const EdgeInsets.fromLTRB(
        10,
        14,
        9,
        13,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(19),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: AppColors.white.withValues(
                alpha: 0.65,
              ),
              shape: BoxShape.circle,
            ),

            alignment: Alignment.center,

            child: Icon(
              icon,
              size: 25,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 7),

          // COUNT
          Text(
            '$count',

            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),

          // LABEL
          Text(
            label,

            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIVE TASK CARD
// ============================================================

class _ActiveTaskCard extends StatelessWidget {
  final TechnicianTaskItem task;
  final VoidCallback onTap;

  const _ActiveTaskCard({
    required this.task,
    required this.onTap,
  });

  // ==========================================================
  // PRIORITY COLOR
  // ==========================================================

  Color get _priorityColor {
    switch (task.priority) {
      case ReportPriority.tinggi:
        return const Color(0xFFDC2626);

      case ReportPriority.sedang:
        return const Color(0xFFC2410C);

      case ReportPriority.rendah:
        return const Color(0xFF15803D);
    }
  }

  Color get _priorityBackground {
    switch (task.priority) {
      case ReportPriority.tinggi:
        return const Color(0xFFFEE9E9);

      case ReportPriority.sedang:
        return const Color(0xFFFFF1E3);

      case ReportPriority.rendah:
        return const Color(0xFFE1F7E9);
    }
  }

  IconData get _priorityIcon {
    switch (task.priority) {
      case ReportPriority.tinggi:
        return Icons.keyboard_double_arrow_up_rounded;

      case ReportPriority.sedang:
        return Icons.drag_handle_rounded;

      case ReportPriority.rendah:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  // ==========================================================
  // SLA LABEL
  // ==========================================================

  String get _slaLabel {
    final now = DateTime.now();

    if (task.isOverdue) {
      final difference = now.difference(task.deadlineAt);

      if (difference.inDays >= 1) {
        return 'Terlambat ${difference.inDays} hari';
      }

      if (difference.inHours >= 1) {
        return 'Terlambat ${difference.inHours} jam';
      }

      return 'Terlambat <1 jam';
    }

    final difference = task.deadlineAt.difference(now);

    if (difference.inDays >= 1) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;

      if (hours > 0) {
        return 'Sisa $days hari $hours jam';
      }

      return 'Sisa $days hari';
    }

    if (difference.inHours >= 1) {
      return 'Sisa ${difference.inHours} jam';
    }

    return 'Sisa <1 jam';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),

      child: Container(
        padding: const EdgeInsets.all(13),

        decoration: BoxDecoration(
          color: AppColors.white,

          borderRadius: BorderRadius.circular(19),

          border: Border(
            top: const BorderSide(
              color: Color(0xFFE5EAF2),
              width: 1,
            ),

            right: const BorderSide(
              color: Color(0xFFE5EAF2),
              width: 1,
            ),

            bottom: const BorderSide(
              color: Color(0xFFE5EAF2),
              width: 1,
            ),

            left: BorderSide(
              color: task.isOverdue
                  ? AppColors.statusRejectedText
                  : _priorityColor,
              width: 4,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(
                alpha: 0.035,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ICON FASILITAS
            Container(
              width: 76,
              height: 84,

              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(17),
              ),

              alignment: Alignment.center,

              child: Icon(
                task.assetIcon,
                color: AppColors.primaryBlue,
                size: 40,
              ),
            ),

            const SizedBox(width: 12),

            // INFORMASI TUGAS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID LAPORAN
                  Text(
                    '#${task.id}',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // NAMA ASET
                  Text(
                    task.assetNama,

                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0A0D14),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // LOKASI
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          task.assetLokasi,

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // PELAPOR
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          task.pelaporNama,

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // STATUS
                  Text(
                    task.status.label,

                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 7),

            // PRIORITAS DAN SLA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // PRIORITY BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: _priorityBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _priorityIcon,
                        size: 15,
                        color: _priorityColor,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        task.priority.label,

                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 9),

                // SLA BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: task.isOverdue
                        ? const Color(0xFFFEE9E9)
                        : _priorityBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: task.isOverdue
                            ? AppColors.statusRejectedText
                            : _priorityColor,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        _slaLabel,

                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: task.isOverdue
                              ? AppColors.statusRejectedText
                              : _priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),

            // ARROW
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF334155),
              size: 23,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TECHNICIAN HEADER ILLUSTRATION
// ============================================================

class _TechnicianIllustration extends StatelessWidget {
  const _TechnicianIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      height: 105,

      child: Stack(
        alignment: Alignment.center,
        children: [
          // GEAR
          const Positioned(
            left: 5,
            top: 8,
            child: Icon(
              Icons.settings_rounded,
              size: 70,
              color: Color(0xFF5C9AFF),
            ),
          ),

          // WRENCH
          const Positioned(
            right: 0,
            bottom: 5,
            child: Icon(
              Icons.build_rounded,
              size: 65,
              color: Color(0xFF9BC1FF),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY TASK CARD
// ============================================================

class _EmptyTaskCard extends StatelessWidget {
  const _EmptyTaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,

            decoration: const BoxDecoration(
              color: AppColors.statusDoneBg,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primaryBlue,
              size: 33,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Belum Ada Tugas Aktif',

            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Tugas yang diberikan oleh Admin akan muncul di sini.',

            textAlign: TextAlign.center,

            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}