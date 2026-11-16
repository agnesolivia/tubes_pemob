# 📐 Panduan Struktur Folder & Arsitektur Proyek

Dokumen ini menjadi acuan teknis bagi seluruh anggota tim dalam mengembangkan **Aplikasi Pengaduan Fasilitas Kampus** (Flutter + Firebase). Tujuannya agar pembagian tugas antar-anggota tetap rapi, konsisten, dan minim *merge conflict*.

## 1. Peta Lengkap Direktori `lib/`

Proyek ini menggunakan pola **Layer-First** yang dikombinasikan dengan pemisahan halaman berdasarkan *role* (`pelapor`, `admin`, `teknisi`) di dalam `screens/`. Seluruh file halaman di dalam `screens/` wajib menggunakan akhiran `_screen.dart`.

```text
lib/
├── main.dart                             # Entry point aplikasi, inisialisasi Firebase, & routing awal
│
├── constants/                            # Nilai konstan & konfigurasi global
│   ├── app_colors.dart                   # Palet warna utama, status badge, & tema
│   └── app_constants.dart                # Daftar status tiket, level prioritas, & aturan durasi SLA
│
├── models/                               # Blueprint objek data & konversi Firestore (fromFirestore / toMap)
│   ├── user_model.dart                   # Data pengguna & role ('pelapor' | 'admin' | 'teknisi')
│   ├── asset_model.dart                  # Data ruangan/aset kampus & kode QR
│   ├── report_model.dart                 # Data tiket laporan, foto sebelum/sesudah, SLA, & riwayat status
│   └── notification_model.dart           # Data notifikasi perubahan status tiket antar-role
│
├── services/                             # Seluruh komunikasi backend (Firebase Auth, Firestore, Storage)
│   ├── auth_service.dart               # Login, register, logout, & ambil profil role user aktif
│   ├── report_service.dart             # CRUD laporan, verifikasi, penugasan, & update progres teknisi
│   ├── asset_service.dart              # Ambil & kelola master data ruangan/aset untuk QR & dropdown
│   └── storage_service.dart            # Upload foto bukti sebelum & sesudah perbaikan
│
├── widgets/                              # Komponen UI kecil yang dipakai berulang di banyak halaman
│   ├── status_badge.dart                 # Label warna otomatis sesuai status ('reported', 'resolved', dll.)
│   ├── sla_indicator.dart                # Indikator sisa waktu / keterlambatan batas SLA
│   ├── report_card.dart                  # Kartu ringkasan laporan untuk daftar/list
│   └── custom_button.dart                # Tombol standar aplikasi dengan state loading
│
└── screens/                              # Seluruh halaman penuh (Scaffold)
    ├── auth/                             # Alur sebelum masuk ke beranda role
    │   ├── auth_wrapper.dart             # Pengecek status login & pengarah otomatis sesuai role
    │   ├── login_screen.dart             # Halaman masuk (Email/Password & Google Sign-In)
    │   └── register_screen.dart          # Halaman daftar akun baru (default role: 'pelapor')
    │
    ├── shared/                           # Halaman lintas role (dipakai 2 atau 3 role sekaligus)
    │   ├── detail_laporan_screen.dart    # Detail tiket lengkap + tombol aksi dinamis sesuai role
    │   ├── history_asset_screen.dart     # Info aset/ruangan & rekam jejak seluruh kerusakannya
    │   ├── notification_screen.dart      # Daftar notifikasi real-time lintas role
    │   └── profile_screen.dart           # Profil akun, pengaturan khusus role, & tombol logout
    │
    ├── pelapor/                          # Khusus Mahasiswa / Dosen / Staf
    │   ├── pelapor_home_screen.dart      # Beranda pelapor, ringkasan status, & tombol Scan QR / Lapor
    │   ├── scan_qr_screen.dart           # Pemindai kamera QR Code stiker ruangan/aset
    │   ├── form_pengaduan_screen.dart    # Form buat laporan (otomatis dari QR atau pilih dropdown)
    │   └── history_pelaporan_screen.dart # Daftar riwayat laporan milik pelapor + filter status
    │
    ├── admin/                            # Khusus Pengelola Fasilitas Kampus
    │   ├── admin_dashboard_screen.dart   # Statistik tiket, monitoring kepatuhan SLA, & menu kelola
    │   ├── kelola_laporan_screen.dart    # Daftar laporan masuk untuk verifikasi, tolak, & pilih teknisi
    │   ├── kelola_aset_screen.dart       # Tambah/edit ruangan & aset + generate & cetak QR Code
    │   └── kelola_teknisi_screen.dart    # Daftar teknisi, status ketersediaan, & beban tugas aktif
    │
    └── teknisi/                          # Khusus Petugas Perbaikan Lapangan
        ├── teknisi_home_screen.dart      # Ringkasan tugas aktif & daftar prioritas tertinggi (Urgent)
        ├── daftar_tugas_screen.dart      # Daftar lengkap tugas yang ditugaskan ke teknisi terkait
        └── form_penyelesaian_screen.dart # Form upload foto sesudah perbaikan & catatan tindakan
```

## 2. Tanggung Jawab Tiap Folder

### `constants/`
Menyimpan nilai tetap agar tidak tersebar (*hardcoded*) di banyak file UI.
* **`app_colors.dart`:** Warna primer kampus, warna latar, dan warna status tiket.
* **`app_constants.dart`:** Konstanta *string* untuk status laporan, prioritas, dan durasi SLA agar tidak terjadi *typo* antar-anggota tim.

### `models/`
Berfungsi sebagai penerjemah antara dokumen mentah Cloud Firestore (`Map<String, dynamic>`) dan objek Dart.
* Setiap model wajib memiliki `factory Model.fromFirestore(DocumentSnapshot doc)` dan `Map<String, dynamic> toMap()`.
* **Dilarang** mengakses `doc.data()['nama_field']` langsung di dalam `screens/`.

### `services/`
Satu-satunya lapisan yang boleh memanggil `FirebaseFirestore`, `FirebaseAuth`, atau layanan *upload* gambar.
* File di `screens/` cukup memanggil *method* dari `services/` (misalnya `reportService.watchMyReports(uid)`) dan menerima data yang sudah berbentuk `Model` atau `List<Model>`.

### `widgets/`
Berisi komponen UI tanpa `Scaffold` yang digunakan di lebih dari satu halaman—contohnya `ReportCard` yang dipakai di beranda Pelapor, daftar Admin, maupun daftar tugas Teknisi.

### `screens/`
Berisi tampilan halaman penuh (`Scaffold`). Dikelompokkan berdasarkan aktor pengguna agar setiap anggota tim bisa fokus mengerjakan foldernya masing-masing tanpa saling menimpa file.

## 3. Alur Inti & Skenario Lintas Role

### A. Siklus Hidup Tiket (6 Status)

```text
                  ┌──► rejected (Ditolak Admin + wajib alasan penolakan)
                  │
reported ─────────┴──► verified ──► assigned ──► in progress ──► resolved
(Pelapor kirim)       (Admin cek     (Admin pilih   (Teknisi        (Foto sesudah &
                      & set SLA)      teknisi)       kerjakan)       konfirmasi)
```

* **`reported`:** Laporan baru masuk dari Pelapor (masih bisa dibatalkan oleh Pelapor).
* **`rejected`:** Laporan tidak valid/ganda (final, tidak masuk perhitungan SLA maupun histori aset).
* **`verified` & `assigned`:** Admin memvalidasi laporan, menetapkan **prioritas** (yang otomatis menghitung tenggat **SLA**), dan memilih Teknisi.
* **`in progress`:** Teknisi mulai menangani perbaikan di lokasi.
* **`resolved`:** Teknisi mengunggah **foto sesudah diperbaiki** dan catatan perbaikan, lalu Pelapor/Admin mengonfirmasi penyelesaian.

### B. Aturan SLA (*Service Level Agreement*)
Saat Admin memverifikasi tiket dan memilih prioritas, sistem otomatis mengisi field `deadlineAt`:
* **Tinggi / Urgent:** +24 jam dari waktu verifikasi.
* **Sedang:** +72 jam (3 hari) dari waktu verifikasi.
* **Rendah:** +7 hari dari waktu verifikasi.

### C. Alur Fleksibel QR Code vs. Manual

```text
pelapor_home_screen
  ├──► [Scan QR]      ──► scan_qr_screen ──► history_asset_screen ──► form_pengaduan_screen (aset terisi)
  └──► [Lapor Manual] ──────────────────────────────────────────────► form_pengaduan_screen (pilih dropdown)
```

### D. Sistem Notifikasi Dalam Aplikasi (*In-App Notification*)
Notifikasi dibangun menggunakan koleksi Firestore `notifications` secara *real-time* (tanpa memerlukan Cloud Functions):
* **Pelapor** menerima notifikasi saat laporan diverifikasi/ditugaskan, ditolak (`rejected`), atau selesai diperbaiki (`resolved`).
* **Teknisi** menerima notifikasi saat Admin menugaskan tiket baru kepadanya (`assigned`).
* **Admin** menerima notifikasi saat laporan baru masuk (`reported`) atau saat Teknisi menandai tugas selesai.
* Menekan item notifikasi di `notification_screen.dart` akan langsung membuka `detail_laporan_screen.dart` sesuai `reportId` terkait.

## 4. Desain Database Firestore (*Flat Collections*)

Proyek ini menggunakan **4 koleksi sejajar (*root collections*)** tanpa *subcollection* agar mudah di-*query* dari sudut pandang Pelapor, Admin, Teknisi, maupun histori aset:

1. **`users`**
   * `uid`, `nama`, `email`, `nomorInduk` (NIM/NIP), `role` (`pelapor` | `admin` | `teknisi`), `isAvailable` (khusus teknisi), `createdAt`.
2. **`assets`**
   * `id` (sama dengan teks QR Code, misal `AC-R204`), `namaAset`, `kategori`, `gedung`, `ruangan`, `createdAt`.
3. **`reports`**
   * `id`, `assetId`, `namaAset`, `lokasiLengkap`, `deskripsi`, `fotoSebelumUrl`, `fotoSesudahUrl`, `status`, `prioritas`, `rejectionReason`, `catatanTeknisi`, `pelaporId`, `pelaporNama`, `teknisiId`, `teknisiNama`, `createdAt`, `verifiedAt`, `deadlineAt`, `resolvedAt`.
   * *Catatan Denormalisasi:* `namaAset`, `lokasiLengkap`, `pelaporNama`, dan `teknisiNama` ikut disimpan langsung di `reports` agar daftar laporan dapat ditampilkan dalam satu kali baca tanpa *query* tambahan.
4. **`notifications`**
   * `id`, `recipientId` (UID penerima), `reportId`, `title`, `message`, `isRead` (`bool`), `createdAt`.

## 5. Aturan Kolaborasi & Git Tim

1. **Penamaan File & Variabel:**
   * Nama file wajib `snake_case`, menyertakan peran/fungsinya, dan berakhiran `_screen.dart` untuk seluruh halaman di `screens/` (contoh: `pelapor_home_screen.dart`, `history_asset_screen.dart`, `report_model.dart`).
   * Nama *class* wajib `PascalCase` sesuai nama file (contoh: `PelaporHomeScreen`, `HistoryAssetScreen`).
2. **Alur Branch & Commit:**
   * Jangan *push* fitur setengah jadi langsung ke `main`.
   * Buat *branch* baru dari `main` sesuai tugas: `feature/pelapor-scan-qr`, `feature/admin-verifikasi`, `fix/login-error`, atau `chore/update-docs`.
   * Gunakan awalan pesan *commit* yang jelas: `feat: ...`, `fix: ...`, `refactor: ...`, atau `chore: ...`.