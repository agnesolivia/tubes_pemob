import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/asset_model.dart';
import 'package:tubes_pemob/screens/admin/detail_aset_screen.dart';
import 'package:tubes_pemob/services/asset_service.dart';

class TambahAsetScreen extends StatefulWidget {
  final String? initialGedung;
  final String? initialRuangan;
  final String? initialNama;

  const TambahAsetScreen({
    super.key,
    this.initialGedung,
    this.initialRuangan,
    this.initialNama,
  });

  @override
  State<TambahAsetScreen> createState() => _TambahAsetScreenState();
}

class _TambahAsetScreenState extends State<TambahAsetScreen> {
  final _formKey = GlobalKey<FormState>();

  String _gedung = '';
  String _ruangan = '';
  bool _isSaving = false;

  late final List<_BatchRowController> _rows;

  static const List<String> _categories = [
    'Elektronik',
    'Inventaris',
    'Sanitasi',
    'Kelistrikan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _gedung = widget.initialGedung?.trim() ?? '';
    _ruangan = widget.initialRuangan?.trim() ?? '';
    _rows = [
      _BatchRowController(
        initialNama: widget.initialNama ?? '',
        initialKategori: 'Elektronik',
      ),
    ];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  int get _totalUnits {
    return _rows.fold<int>(0, (sum, row) => sum + row.jumlah);
  }

  void _addRow() {
    setState(() {
      _rows.add(_BatchRowController(initialKategori: 'Elektronik'));
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final removed = _rows.removeAt(index);
      removed.dispose();
    });
  }

  /// Hitung nomor tertinggi (#Max) untuk suatu nama dasar di (gedung, ruangan) terpilih
  int _getExistingMaxNumber(
    List<AssetModel> allAssets, {
    required String gedung,
    required String ruangan,
    required String baseName,
  }) {
    final gLower = gedung.trim().toLowerCase();
    final rLower = ruangan.trim().toLowerCase();
    final bLower = baseName.trim().toLowerCase();
    if (gLower.isEmpty || rLower.isEmpty || bLower.isEmpty) return 0;

    final suffixPattern = RegExp(r'^(.+)#(\d+)$');
    int maxNum = 0;

    for (final asset in allAssets) {
      if (asset.gedung.trim().toLowerCase() != gLower ||
          asset.ruangan.trim().toLowerCase() != rLower) {
        continue;
      }
      final match = suffixPattern.firstMatch(asset.nama.trim());
      if (match != null) {
        final existingBase = match.group(1)!.trim().toLowerCase();
        final numVal = int.tryParse(match.group(2)!) ?? 0;
        if (existingBase == bLower && numVal > maxNum) {
          maxNum = numVal;
        }
      }
    }

    return maxNum;
  }

  Future<void> _submitBatch() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_gedung.trim().isEmpty || _ruangan.trim().isEmpty) {
      _showSnackBar('Gedung dan ruangan wajib diisi.', isError: true);
      return;
    }

    if (_totalUnits < 1 || _totalUnits > AssetService.maxBatchUnits) {
      _showSnackBar(
        'Total unit harus antara 1 sampai ${AssetService.maxBatchUnits} unit.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final items = _rows
          .map(
            (row) => AssetBatchItem(
              nama: row.namaController.text.trim(),
              kategori: row.kategori,
              jumlah: row.jumlah,
            ),
          )
          .toList();

      final createdAssets = await AssetService.instance.createMultipleAssets(
        gedung: _gedung,
        ruangan: _ruangan,
        items: items,
      );

      if (!mounted) return;

      _showSnackBar(
        '${createdAssets.length} aset berhasil ditambahkan ke ${_gedung.trim()} - ${_ruangan.trim()}.',
      );

      if (createdAssets.length == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAsetScreen(
              asset: createdAssets.first,
              scrollToQr: true,
            ),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(cleanMsg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
            'Tambah Aset Baru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
        body: StreamBuilder<List<AssetModel>>(
          stream: AssetService.instance.streamAllAssets(),
          builder: (context, snapshot) {
            final allAssets = snapshot.data ?? [];
            final gedungSuggestions =
                AssetService.instance.extractUniqueGedung(allAssets);
            final ruanganSuggestions = _gedung.trim().isEmpty
                ? <String>[]
                : AssetService.instance.extractUniqueRuangan(
                    allAssets,
                    _gedung,
                  );

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KARTU LOKASI (SEKALI PILIH UNTUK SEMUA BARIS)
                    _buildLocationCard(
                      gedungSuggestions: gedungSuggestions,
                      ruanganSuggestions: ruanganSuggestions,
                    ),
                    const SizedBox(height: 18),

                    // 2. HEADER DAFTAR BARANG + PENGHITUNG UNIT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Barang (${_rows.length} jenis)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _totalUnits > AssetService.maxBatchUnits
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Total: $_totalUnits / ${AssetService.maxBatchUnits} unit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _totalUnits > AssetService.maxBatchUnits
                                  ? AppColors.statusRejectedText
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 3. DAFTAR BARIS BARANG
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildItemRowCard(
                          index: index,
                          row: _rows[index],
                          allAssets: allAssets,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // TOMBOL TAMBAH BARIS BARANG
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                        label: Text(
                          'Tambah Jenis Barang Lain di Ruangan Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          backgroundColor: AppColors.white,
                          side: BorderSide(
                            color: AppColors.primaryBlue.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _submitBatch,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isSaving
                    ? 'Menyimpan Aset...'
                    : 'Simpan Semua ($_totalUnits Unit)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required List<String> gedungSuggestions,
    required List<String> ruanganSuggestions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryBlue,
                size: 19,
              ),
              const SizedBox(width: 6),
              Text(
                'Lokasi Penempatan Aset',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih dari saran yang sudah ada atau ketik gedung/ruangan baru.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // GEDUNG AUTOCOMPLETE
          _fieldLabel('Gedung'),
          const SizedBox(height: 6),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _gedung),
            optionsBuilder: (textEditingValue) {
              final q = textEditingValue.text.trim().toLowerCase();
              if (q.isEmpty) return gedungSuggestions;
              return gedungSuggestions.where(
                (item) => item.toLowerCase().contains(q),
              );
            },
            onSelected: (selection) {
              setState(() => _gedung = selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.words,
                onChanged: (val) => setState(() => _gedung = val),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDecoration(
                  hint: 'Contoh: Gedung A',
                  icon: Icons.apartment_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama gedung wajib diisi.';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 14),

          // RUANGAN AUTOCOMPLETE
          _fieldLabel('Ruangan'),
          const SizedBox(height: 6),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _ruangan),
            optionsBuilder: (textEditingValue) {
              final q = textEditingValue.text.trim().toLowerCase();
              if (q.isEmpty) return ruanganSuggestions;
              return ruanganSuggestions.where(
                (item) => item.toLowerCase().contains(q),
              );
            },
            onSelected: (selection) {
              setState(() => _ruangan = selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.words,
                onChanged: (val) => setState(() => _ruangan = val),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDecoration(
                  hint: 'Contoh: Ruang 204',
                  icon: Icons.meeting_room_outlined,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama ruangan wajib diisi.';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRowCard({
    required int index,
    required _BatchRowController row,
    required List<AssetModel> allAssets,
  }) {
    final rawNama = row.namaController.text.trim();
    final isBatch = row.jumlah > 1;
    final hasHash = rawNama.contains('#');

    String? previewText;
    if (rawNama.isNotEmpty && !isBatch) {
      previewText = 'Nama tersimpan: $rawNama';
    } else if (rawNama.isNotEmpty && isBatch && !hasHash) {
      final startNum = _getExistingMaxNumber(
            allAssets,
            gedung: _gedung,
            ruangan: _ruangan,
            baseName: rawNama,
          ) +
          1;
      final endNum = startNum + row.jumlah - 1;
      final padWidth = endNum >= 100 ? 3 : 2;
      final startStr = startNum.toString().padLeft(padWidth, '0');
      final endStr = endNum.toString().padLeft(padWidth, '0');
      previewText = 'Otomatis dibuat: $rawNama#$startStr s/d $rawNama#$endStr';
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header baris
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Barang #${index + 1}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              if (_rows.length > 1)
                InkWell(
                  onTap: () => _removeRow(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.statusRejectedText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Hapus',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusRejectedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Nama Aset / Nama Dasar
          _fieldLabel(isBatch ? 'Nama Dasar Aset' : 'Nama Aset'),
          const SizedBox(height: 6),
          TextFormField(
            controller: row.namaController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              hint: isBatch
                  ? 'Contoh: Kursi Kuliah (tanpa #)'
                  : 'Contoh: AC Daikin 2 PK atau Kursi#02',
              icon: Icons.inventory_2_outlined,
            ),
            validator: (value) {
              final clean = value?.trim() ?? '';
              if (clean.isEmpty) {
                return 'Nama aset wajib diisi.';
              }
              if (row.jumlah > 1 && clean.contains('#')) {
                return 'Hapus karakter "#" untuk jumlah > 1 (ditambahkan otomatis).';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Kategori & Jumlah Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown Kategori
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Kategori'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: row.kategori,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF7F9FD),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => row.kategori = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Input Jumlah Unit
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Jumlah Unit'),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FD),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: row.jumlah > 1
                                ? () {
                                    setState(() {
                                      row.setJumlah(row.jumlah - 1);
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 44,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: row.jumlahController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                final parsed = int.tryParse(val) ?? 1;
                                setState(() {
                                  row.jumlah = parsed < 1 ? 1 : parsed;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _totalUnits < AssetService.maxBatchUnits
                                ? () {
                                    setState(() {
                                      row.setJumlah(row.jumlah + 1);
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Pratinjau Nama Hasil Generate
          if (previewText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      previewText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F9FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
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
          width: 1.5,
        ),
      ),
    );
  }
}

class _BatchRowController {
  final TextEditingController namaController;
  final TextEditingController jumlahController;
  String kategori;
  int jumlah;

  _BatchRowController({
    String initialNama = '',
    required this.initialKategori,
    this.jumlah = 1,
  })  : kategori = initialKategori,
        namaController = TextEditingController(text: initialNama),
        jumlahController = TextEditingController(text: '$jumlah');

  final String initialKategori;

  void setJumlah(int value) {
    jumlah = value < 1 ? 1 : value;
    jumlahController.text = '$jumlah';
  }

  void dispose() {
    namaController.dispose();
    jumlahController.dispose();
  }
}