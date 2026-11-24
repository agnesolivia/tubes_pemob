import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/report_model.dart';
import 'package:tubes_pemob/models/technician_task_item.dart';

// ============================================================
// CALLBACK PENYIMPANAN HASIL PERBAIKAN
// ============================================================

typedef CompletionSubmitCallback = Future<void> Function(
  TechnicianTaskItem task,
  XFile fotoSesudah,
  String catatanTeknisi,
);

// ============================================================
// FORM PENYELESAIAN SCREEN
// ============================================================

class FormPenyelesaianScreen extends StatefulWidget {
  final TechnicianTaskItem task;

  final CompletionSubmitCallback? onSubmit;

  const FormPenyelesaianScreen({
    super.key,
    required this.task,
    this.onSubmit,
  });

  @override
  State<FormPenyelesaianScreen> createState() =>
      _FormPenyelesaianScreenState();
}

class _FormPenyelesaianScreenState
    extends State<FormPenyelesaianScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _notesController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedPhoto;

  Uint8List? _photoBytes;

  bool _isSubmitting = false;

  bool _photoError = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PICK PHOTO
  // ==========================================================

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,

        // Ukuran awal foto:
        maxWidth: 800,
        maxHeight: 800,

        // Kualitas awal kompresi:
        imageQuality: 65,
      );

      if (photo == null) return;

      final bytes = await photo.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedPhoto = photo;
        _photoBytes = bytes;
        _photoError = false;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal mengambil foto. Periksa izin kamera atau galeri.',
        isError: true,
      );
    }
  }

  // ==========================================================
  // PHOTO SOURCE BOTTOM SHEET
  // ==========================================================

  void _showPhotoSource() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),

          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE3ED),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 15),

              _PhotoSourceItem(
                icon: Icons.camera_alt_rounded,
                label: 'Ambil Foto dengan Kamera',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.camera);
                },
              ),

              const SizedBox(height: 10),

              _PhotoSourceItem(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // REMOVE PHOTO
  // ==========================================================

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
      _photoBytes = null;
      _photoError = false;
    });
  }

  // ==========================================================
  // VALIDATION AND SUBMIT
  // ==========================================================

  Future<void> _submitCompletion() async {
    if (_isSubmitting) return;

    final isValid = _formKey.currentState!.validate();

    if (!isValid) return;

    if (_selectedPhoto == null) {
      setState(() {
        _photoError = true;
      });

      _showMessage(
        'Foto hasil perbaikan wajib diunggah.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Callback ini nantinya dihubungkan ke Service.
      // Service bertanggung jawab melakukan kompresi akhir,
      // konversi Base64, penyimpanan data, serta notifikasi.
      if (widget.onSubmit != null) {
        await widget.onSubmit!(
          widget.task,
          _selectedPhoto!,
          _notesController.text.trim(),
        );
      }

      if (!mounted) return;

      // Kembali ke Detail Laporan dengan hasil sukses.
      // Tanpa callback, hanya perubahan state lokal.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal menyimpan hasil perbaikan.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
              fontSize: 11,
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

        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,

          title: Text(
            'Form Penyelesaian',
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

        body: Form(
          key: _formKey,

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              25,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFORMASI ASET
                _buildAssetHeader(),

                const SizedBox(height: 23),

                // SECTION TITLE
                Text(
                  'Hasil Perbaikan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 15),

                // FOTO SESUDAH
                _buildPhotoUploadSection(),

                const SizedBox(height: 18),

                // CATATAN PERBAIKAN
                _buildNotesSection(),

                const SizedBox(height: 20),

                // INFORMASI PENYELESAIAN
                _buildConfirmationInformation(),
              ],
            ),
          ),
        ),

        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  // ==========================================================
  // ASSET HEADER
  // ==========================================================

  Widget _buildAssetHeader() {
    final task = widget.task;

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: _cardDecoration(),

      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(15),
            ),

            alignment: Alignment.center,

            child: Icon(
              task.assetIcon,
              size: 37,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.assetNama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  task.assetLokasi,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  task.pelaporNama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          _PriorityBadge(
            priority: task.priority,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PHOTO UPLOAD SECTION
  // ==========================================================

  Widget _buildPhotoUploadSection() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryBlue,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto Setelah Perbaikan *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Unggah foto hasil perbaikan',
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

          const SizedBox(height: 14),

          // PHOTO PREVIEW / UPLOAD BUTTON
          InkWell(
            onTap: _showPhotoSource,
            borderRadius: BorderRadius.circular(15),

            child: Container(
              width: double.infinity,
              height: 185,

              clipBehavior: Clip.antiAlias,

              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FD),
                borderRadius: BorderRadius.circular(15),

                border: Border.all(
                  color: _photoError
                      ? AppColors.statusRejectedText
                      : AppColors.border,
                  width: _photoError ? 1.5 : 1,
                ),
              ),

              child: _photoBytes != null
                  ? Image.memory(
                      _photoBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : _buildUploadPlaceholder(),
            ),
          ),

          if (_photoError) ...[
            const SizedBox(height: 7),

            Text(
              'Foto hasil perbaikan wajib diunggah.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.statusRejectedText,
              ),
            ),
          ],

          if (_selectedPhoto != null) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Foto berhasil dipilih.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: _showPhotoSource,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                  ),
                  label: Text(
                    'Ganti',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _removePhoto,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.statusRejectedText,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.primaryBlue,
          size: 40,
        ),

        const SizedBox(height: 10),

        Text(
          'Pilih atau Ambil Foto',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Kamera atau Galeri',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // NOTES SECTION
  // ==========================================================

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),

              const SizedBox(width: 8),

              Text(
                'Catatan Tindakan Perbaikan *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _notesController,

            maxLines: 5,
            minLines: 4,
            maxLength: 500,

            textCapitalization: TextCapitalization.sentences,

            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),

            decoration: InputDecoration(
              hintText:
                  'Tuliskan tindakan perbaikan yang dilakukan...',

              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),

              filled: true,
              fillColor: AppColors.white,

              contentPadding: const EdgeInsets.all(13),

              counterStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.4,
                ),
              ),
            ),

            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Catatan perbaikan wajib diisi.';
              }

              if (value.trim().length < 10) {
                return 'Catatan minimal 10 karakter.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CONFIRMATION INFORMATION
  // ==========================================================

  Widget _buildConfirmationInformation() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryBlue,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfirmasi Penyelesaian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Pastikan foto dan catatan sudah sesuai. Setelah disimpan, status laporan akan berubah menjadi "Selesai".',

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM ACTIONS
  // ==========================================================

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        15,
        12,
        15,
        12,
      ),

      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),

      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // BATAL
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(context),

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
                  'Batal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // SIMPAN DAN SELESAIKAN
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : _submitCompletion,

                icon: _isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                        size: 20,
                      ),

                label: Text(
                  _isSubmitting
                      ? 'Menyimpan...'
                      : 'Simpan & Selesaikan',

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),

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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DECORATION
  // ==========================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: AppColors.border,
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
}

// ============================================================
// PHOTO SOURCE ITEM
// ============================================================

class _PhotoSourceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),

      tileColor: AppColors.background,

      leading: Icon(
        icon,
        color: AppColors.primaryBlue,
      ),

      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ============================================================
// PRIORITY BADGE
// ============================================================

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;

  const _PriorityBadge({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    late Color color;
    late Color background;
    late IconData icon;

    switch (priority) {
      case ReportPriority.tinggi:
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE9E9);
        icon = Icons.keyboard_double_arrow_up_rounded;
        break;

      case ReportPriority.sedang:
        color = const Color(0xFFC2410C);
        background = const Color(0xFFFFF1E3);
        icon = Icons.drag_handle_rounded;
        break;

      case ReportPriority.rendah:
        color = const Color(0xFF15803D);
        background = const Color(0xFFE1F7E9);
        icon = Icons.keyboard_double_arrow_down_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),

          const SizedBox(width: 4),

          Text(
            priority.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}