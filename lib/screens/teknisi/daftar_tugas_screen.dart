import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';
import 'package:tubes_pemob/screens/teknisi/detail_laporan_screen.dart';

// ============================================================
// DAFTAR TUGAS SCREEN
// ============================================================

class DaftarTugasScreen extends StatefulWidget {
  final String currentUserUid;
  final List<TechnicianTaskItem> tasks;

  final ValueChanged<TechnicianTaskItem>? onTaskPressed;

  const DaftarTugasScreen({
    super.key,
    required this.currentUserUid,
    this.tasks = const [],
    this.onTaskPressed,
  });

  @override
  State<DaftarTugasScreen> createState() =>
      _DaftarTugasScreenState();
}

class _DaftarTugasScreenState extends State<DaftarTugasScreen> {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ==========================================================
  // FILTER STATE
  // ==========================================================

  Set<ReportStatus> _selectedStatuses = {};

  String _selectedBuilding = 'Semua Gedung';

  bool _sortNearestDeadline = true;

  // ==========================================================
  // STATUS OPTIONS
  // ==========================================================

  final List<ReportStatus> _statusOptions = [
    ReportStatus.assigned,
    ReportStatus.inProgress,
    ReportStatus.resolved,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // FILTER TUGAS BERDASARKAN TEKNISI LOGIN
  // ==========================================================

  List<TechnicianTaskItem> get _myTasks {
    return widget.tasks.where((task) {
      final isMyTask = task.teknisiId == widget.currentUserUid;

      final isValidStatus =
          task.status == ReportStatus.assigned ||
          task.status == ReportStatus.inProgress ||
          task.status == ReportStatus.resolved;

      return isMyTask && isValidStatus;
    }).toList();
  }

  // ==========================================================
  // BUILDING NAME
  // ==========================================================

  String _getBuildingName(String location) {
    final match = RegExp(
      r'Gedung\s+[^,\-–]+',
      caseSensitive: false,
    ).firstMatch(location);

    return match?.group(0)?.trim() ?? location;
  }

  // ==========================================================
  // BUILDING OPTIONS
  // ==========================================================

  List<String> get _buildingOptions {
    final buildings = _myTasks
        .map((task) => _getBuildingName(task.assetLokasi))
        .where((building) => building.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return [
      'Semua Gedung',
      ...buildings,
    ];
  }

  // ==========================================================
  // FILTER DAN SEARCH TUGAS
  // ==========================================================

  List<TechnicianTaskItem> get _filteredTasks {
    final query = _searchController.text.trim().toLowerCase();

    final tasks = _myTasks.where((task) {
      // SEARCH
      final matchesSearch =
          task.id.toLowerCase().contains(query) ||
          task.assetNama.toLowerCase().contains(query) ||
          task.assetLokasi.toLowerCase().contains(query) ||
          task.pelaporNama.toLowerCase().contains(query);

      // FILTER STATUS
      final matchesStatus =
          _selectedStatuses.isEmpty ||
          _selectedStatuses.contains(task.status);

      // FILTER GEDUNG
      final matchesBuilding =
          _selectedBuilding == 'Semua Gedung' ||
          _getBuildingName(task.assetLokasi) == _selectedBuilding;

      return matchesSearch &&
          matchesStatus &&
          matchesBuilding;
    }).toList();

    // SORTING SLA
    tasks.sort((a, b) {
      if (_sortNearestDeadline) {
        // Tiket overdue didahulukan.
        if (a.isOverdue != b.isOverdue) {
          return a.isOverdue ? -1 : 1;
        }

        return a.deadlineAt.compareTo(b.deadlineAt);
      }

      return b.deadlineAt.compareTo(a.deadlineAt);
    });

    return tasks;
  }

  // ==========================================================
  // FILTER ACTIVE CHECK
  // ==========================================================

  bool get _hasActiveFilter {
    return _selectedStatuses.isNotEmpty ||
        _selectedBuilding != 'Semua Gedung';
  }

  // ==========================================================
  // RESET FILTER
  // ==========================================================

  void _resetFilters() {
    setState(() {
      _selectedStatuses.clear();
      _selectedBuilding = 'Semua Gedung';
      _searchController.clear();
    });
  }

  // ==========================================================
  // SHOW MESSAGE
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
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ==========================================================
  // OPEN TASK DETAIL
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

        // APP BAR
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,

          title: Text(
            'Daftar Tugas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),

          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),

        // MAIN CONTENT
        body: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),

            child: Column(
              children: [
                // SEARCH
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    0,
                  ),
                  child: _buildSearchField(),
                ),

                const SizedBox(height: 15),

                // FILTER BUTTONS
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: _buildFilterButtons(),
                ),

                const SizedBox(height: 12),

                // ACTIVE FILTER CHIPS
                if (_hasActiveFilter)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: _buildActiveFilterChips(),
                  ),

                const SizedBox(height: 18),

                // TASK COUNT AND SORTING
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: _buildTaskHeader(),
                ),

                const SizedBox(height: 13),

                // TASK LIST
                Expanded(
                  child: _buildTaskList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SEARCH FIELD
  // ==========================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,

      onChanged: (_) {
        setState(() {});
      },

      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppColors.textPrimary,
      ),

      decoration: InputDecoration(
        hintText: 'Cari laporan, aset, atau pelapor...',

        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textPrimary,
          size: 21,
        ),

        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                ),
              )
            : null,

        filled: true,
        fillColor: const Color(0xFFEEF2FA),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER BUTTONS
  // ==========================================================

  Widget _buildFilterButtons() {
    return Row(
      children: [
        // STATUS FILTER
        Expanded(
          child: _FilterButton(
            icon: Icons.filter_list_rounded,
            label: _selectedStatuses.isEmpty
                ? 'Status'
                : 'Status (${_selectedStatuses.length})',
            isActive: _selectedStatuses.isNotEmpty,
            onTap: _showFilterSheet,
          ),
        ),

        const SizedBox(width: 10),

        // BUILDING FILTER
        Expanded(
          child: _FilterButton(
            icon: Icons.apartment_rounded,
            label: _selectedBuilding == 'Semua Gedung'
                ? 'Gedung'
                : _selectedBuilding,
            isActive: _selectedBuilding != 'Semua Gedung',
            onTap: _showFilterSheet,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ACTIVE FILTER CHIPS
  // ==========================================================

  Widget _buildActiveFilterChips() {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // STATUS CHIPS
          ..._selectedStatuses.map(
            (status) {
              return _ActiveFilterChip(
                label: 'Status: ${status.label}',
                onDeleted: () {
                  setState(() {
                    _selectedStatuses.remove(status);
                  });
                },
              );
            },
          ),

          // BUILDING CHIP
          if (_selectedBuilding != 'Semua Gedung')
            _ActiveFilterChip(
              label: 'Gedung: $_selectedBuilding',
              onDeleted: () {
                setState(() {
                  _selectedBuilding = 'Semua Gedung';
                });
              },
            ),

          // RESET CHIP
          if (_hasActiveFilter)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatuses.clear();
                  _selectedBuilding = 'Semua Gedung';
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 7,
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusRejectedText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // TASK HEADER
  // ==========================================================

  Widget _buildTaskHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Tugas (${_filteredTasks.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        PopupMenuButton<bool>(
          initialValue: _sortNearestDeadline,

          onSelected: (value) {
            setState(() {
              _sortNearestDeadline = value;
            });
          },

          color: AppColors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          itemBuilder: (context) => [
            PopupMenuItem<bool>(
              value: true,
              child: Text(
                'SLA Terdekat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                ),
              ),
            ),

            PopupMenuItem<bool>(
              value: false,
              child: Text(
                'SLA Terjauh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                ),
              ),
            ),
          ],

          child: Row(
            children: [
              Text(
                'Urutkan: ${_sortNearestDeadline ? 'SLA Terdekat' : 'SLA Terjauh'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TASK LIST
  // ==========================================================

  Widget _buildTaskList() {
    final tasks = _filteredTasks;

    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        25,
      ),

      itemCount: tasks.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 11);
      },

      itemBuilder: (context, index) {
        final task = tasks[index];

        return _TaskCard(
          task: task,
          onTap: () => _onTaskPressed(task),
        );
      },
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE3EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primaryBlue,
                size: 38,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              isSearching
                  ? 'Tugas Tidak Ditemukan'
                  : 'Belum Ada Tugas',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              isSearching
                  ? 'Coba gunakan kata kunci lain atau ubah filter.'
                  : 'Tugas yang diberikan oleh Admin akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            if (_hasActiveFilter || isSearching) ...[
              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _resetFilters,
                child: Text(
                  'Reset Pencarian dan Filter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER BOTTOM SHEET
  // ==========================================================

  void _showFilterSheet() {
    Set<ReportStatus> temporaryStatuses = {
      ..._selectedStatuses,
    };

    String temporaryBuilding = _selectedBuilding;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final buildings = _buildingOptions;

            if (!buildings.contains(temporaryBuilding)) {
              temporaryBuilding = 'Semua Gedung';
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.80,
              ),

              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),

              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(27),
                ),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HANDLE
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

                  // TITLE
                  Center(
                    child: Text(
                      'Filter Tugas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // STATUS FILTER
                          Text(
                            'Status Laporan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),

                            child: Column(
                              children: [
                                ..._statusOptions.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final status = entry.value;

                                    final isSelected =
                                        temporaryStatuses.contains(status);

                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          value: isSelected,

                                          onChanged: (value) {
                                            setModalState(() {
                                              if (value == true) {
                                                temporaryStatuses.add(status);
                                              } else {
                                                temporaryStatuses.remove(status);
                                              }
                                            });
                                          },

                                          activeColor: AppColors.primaryBlue,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,

                                          dense: true,

                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),

                                          title: Text(
                                            status.label,
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),

                                        if (index !=
                                            _statusOptions.length - 1)
                                          const Divider(
                                            height: 1,
                                            color: AppColors.border,
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // BUILDING FILTER
                          Text(
                            'Gedung',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: temporaryBuilding,

                            isExpanded: true,

                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.apartment_rounded,
                                color: AppColors.textSecondary,
                                size: 21,
                              ),

                              filled: true,
                              fillColor: AppColors.white,

                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 13,
                              ),

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

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),

                            items: buildings.map((building) {
                              return DropdownMenuItem(
                                value: building,
                                child: Text(
                                  building,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),

                            onChanged: (value) {
                              if (value == null) return;

                              setModalState(() {
                                temporaryBuilding = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              temporaryStatuses.clear();
                              temporaryBuilding = 'Semua Gedung';
                            });
                          },

                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),

                          child: Text(
                            'Reset',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatuses = {
                                ...temporaryStatuses,
                              };

                              _selectedBuilding = temporaryBuilding;
                            });

                            Navigator.pop(sheetContext);
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),

                          child: Text(
                            'Terapkan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// FILTER BUTTON
// ============================================================

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFEAF2FF)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),

          border: Border.all(
            color: isActive
                ? AppColors.primaryBlue
                : AppColors.border,
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isActive
                  ? AppColors.primaryBlue
                  : AppColors.textPrimary,
            ),

            const SizedBox(width: 7),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 5),

            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isActive
                  ? AppColors.primaryBlue
                  : AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACTIVE FILTER CHIP
// ============================================================

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _ActiveFilterChip({
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFE3EEFF),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,

            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF174EA6),
            ),
          ),

          const SizedBox(width: 7),

          InkWell(
            onTap: onDeleted,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFF174EA6),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TASK CARD
// ============================================================

class _TaskCard extends StatelessWidget {
  final TechnicianTaskItem task;
  final VoidCallback onTap;

  const _TaskCard({
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
  // STATUS COLOR
  // ==========================================================

  Color get _statusColor {
    switch (task.status) {
      case ReportStatus.assigned:
        return AppColors.primaryBlue;

      case ReportStatus.inProgress:
        return const Color(0xFFC2410C);

      case ReportStatus.resolved:
        return const Color(0xFF15803D);

      default:
        return AppColors.textSecondary;
    }
  }

  // ==========================================================
  // STATUS BACKGROUND
  // ==========================================================

  Color get _statusBackground {
    switch (task.status) {
      case ReportStatus.assigned:
        return const Color(0xFFE3EEFF);

      case ReportStatus.inProgress:
        return const Color(0xFFFFF1E3);

      case ReportStatus.resolved:
        return const Color(0xFFE1F7E9);

      default:
        return AppColors.background;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),

      child: Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(17),

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
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            // ASSET ICON
            Container(
              width: 62,
              height: 70,

              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(14),
              ),

              alignment: Alignment.center,

              child: Icon(
                task.assetIcon,
                color: AppColors.primaryBlue,
                size: 33,
              ),
            ),

            const SizedBox(width: 10),

            // TASK INFORMATION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID
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

                  // ASSET NAME
                  Text(
                    task.assetNama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // LOCATION
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

                  // REPORTER
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

                  // STATUS BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.status.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 7),

            // PRIORITY AND SLA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // PRIORITY
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

                      const SizedBox(width: 3),

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

                const SizedBox(height: 8),

                // SLA
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                        size: 13,
                        color: task.isOverdue
                            ? AppColors.statusRejectedText
                            : _priorityColor,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        _slaLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
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

            const SizedBox(width: 3),

            // ARROW
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}