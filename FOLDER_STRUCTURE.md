# 📐 Panduan Struktur Folder & Arsitektur Proyek

Dokumen ini menjadi acuan teknis bagi seluruh anggota tim dalam mengembangkan **Aplikasi Pengaduan Fasilitas Kampus** (Flutter + Firebase). Tujuannya agar struktur kode antar-anggota tetap rapi, konsisten, dan minim *merge conflict* selama kolaborasi Git.

## 1. Peta Lengkap Direktori `lib/`

Proyek ini menggunakan pola **Layer-First** yang dikombinasikan dengan pemisahan halaman berdasarkan *role* (`pelapor`, `admin`, `teknisi`) di dalam `screens/`. Seluruh file halaman penuh di dalam `screens/` wajib menggunakan akhiran `_screen.dart`, sedangkan komponen aksi/UI khusus per *role* diletakkan di subfolder `widgets/` milik *role* terkait.

```text
lib/
├── main.dart                                      # Entry point aplikasi, inisialisasi Firebase, & routing awal
│
├── constants/                                     # Nilai konstan & konfigurasi global
│   ├── app_colors.dart                            # Palet warna utama, status badge, & tema
│   └── app_constants.dart                         # Nama koleksi Firestore, kategori default, & teks umum
│
├── models/                                        # Blueprint objek data, enum, & konversi Firestore
│   ├── user_model.dart                            # UserModel + enum UserRole ('pelapor' | 'admin' | 'teknisi')
│   ├── asset_model.dart                           # AssetModel (data ruangan/aset kampus & Auto-ID QR)
│   ├── report_model.dart                          # ReportModel, StatusHistoryItem, & enum ReportStatus / ReportPriority
│   └── notification_model.dart                    # NotificationModel (notifikasi perubahan status tiket antar-role)
│
├── services/                                      # Seluruh komunikasi backend (Firebase Auth & Cloud Firestore)
│   ├── auth_service.dart                          # Login, register, Google Sign-In, verifikasi email, reset password, & role
│   ├── storage_service.dart                       # Kompresi foto lokal (< 250 KB) & konversi Base64 dua arah
│   ├── asset_service.dart                         # CRUD & batch master data aset/ruangan, validasi unik per ruangan, & QR
│   ├── report_service.dart                        # CRUD laporan, transisi status, hitung SLA, & log riwayat
│   └── notification_service.dart                  # Stream notifikasi real-time & tandai notifikasi sudah dibaca
│
├── utils/                                         # Utilitas bantu pengembangan (seeder data & akun uji)
│   ├── account_seeder.dart                        # Seeder akun dummy via Gmail dot trick (role awal 'pelapor')
│   └── firestore_seeder.dart                      # Seeder data dummy koleksi assets & reports
│
├── widgets/                                       # Komponen UI reusable yang dipakai lintas role / banyak halaman
│   ├── bottom_navbar.dart                         # Navigasi bawah reusable lintas role dengan tombol aksi tengah
│   ├── resolution_action_bar.dart                 # Tombol & dialog Konfirmasi Selesai / Belum Beres (Pelapor & Admin)
│   ├── status_badge.dart                          # Label warna otomatis sesuai ReportStatus
│   ├── sla_indicator.dart                         # Indikator sisa waktu / keterlambatan batas SLA
│   ├── report_card.dart                           # Kartu ringkasan laporan untuk daftar/list
│   └── base64_image_viewer.dart                   # Komponen render gambar dari string Base64 + fallback error
│
└── screens/                                       # Seluruh halaman penuh (Scaffold) & sub-widget khusus role
    ├── auth/                                      # Alur sebelum masuk ke beranda role
    │   ├── auth_wrapper.dart                      # Pengecek status login, verifikasi email, & routing sesuai role
    │   ├── login_screen.dart                      # Halaman masuk (Email/Password, Google Sign-In, & pop-up Lupa Password)
    │   ├── register_screen.dart                   # Halaman daftar akun baru (default role: UserRole.pelapor)
    │   └── email_verification_screen.dart         # Halaman tunggu verifikasi email & kirim ulang tautan verifikasi
    │
    ├── shared/                                    # Halaman lintas role (dipakai 2 atau 3 role sekaligus)
    │   ├── scan_qr_screen.dart                    # Pemindai kamera QR Code lintas role (ASSET:<id> & USER:<uid>)
    │   ├── detail_laporan_screen.dart             # Struktur inti detail tiket lintas role (memanggil *_report_actions sesuai role)
    │   ├── history_aset_screen.dart               # Info aset/ruangan, filter, & rekam jejak kerusakan real-time
    │   ├── notification_screen.dart               # Daftar notifikasi real-time lintas role
    │   └── profile_screen.dart                    # Profil akun, edit nama & foto, QR Code profil (USER:<uid>), & logout
    │
    ├── pelapor/                                   # Khusus Sivitas Akademika & Pengunjung Kampus
    │   ├── widgets/
    │   │   └── pelapor_report_actions.dart        # Tombol Batalkan Laporan & ResolutionActionBar di DetailLaporanScreen
    │   ├── pelapor_main_screen.dart               # Shell utama dengan IndexedStack & BottomNavbar tab Pelapor
    │   ├── pelapor_home_screen.dart               # Beranda pelapor, ringkasan status, & tombol Scan QR / Lapor
    │   ├── form_pengaduan_screen.dart             # Form buat laporan (otomatis dari QR, dropdown manual, & opsi lainnya)
    │   └── history_laporan_screen.dart            # Daftar riwayat laporan milik pelapor + filter status
    │
    ├── admin/                                     # Khusus Pengelola Fasilitas Kampus
    │   ├── widgets/
    │   │   └── admin_report_actions.dart          # Dialog Tolak, Bottom Sheet Verifikasi/SLA & Pilih Teknisi + ResolutionActionBar
    │   ├── admin_main_screen.dart                 # Shell utama dengan IndexedStack & BottomNavbar tab Admin
    │   ├── admin_dashboard_screen.dart            # Statistik tiket, monitoring kepatuhan SLA, & menu kelola
    │   ├── kelola_laporan_screen.dart             # Daftar laporan masuk untuk verifikasi, tolak, & pilih teknisi
    │   ├── kelola_aset_screen.dart                # Daftar master aset, filter lokasi & kategori, & pintasan QR
    │   ├── tambah_aset_screen.dart                # Form tambah aset satuan & batch multi-item (#) per ruangan
    │   ├── detail_aset_screen.dart                # Detail aset, stiker QR Code (Simpan/Bagikan), edit, hapus, & pintasan riwayat
    │   └── kelola_teknisi_screen.dart             # Daftar teknisi, beban tugas aktif, & kelola role via Search/Scan QR
    │
    └── teknisi/                                   # Khusus Petugas Perbaikan Lapangan
        ├── widgets/
        │   └── teknisi_report_actions.dart        # Tombol Mulai Kerjakan & Selesaikan Tugas di DetailLaporanScreen
        ├── teknisi_main_screen.dart               # Shell utama dengan IndexedStack & BottomNavbar tab Teknisi
        ├── teknisi_home_screen.dart               # Ringkasan tugas aktif & daftar prioritas SLA terdekat
        ├── daftar_tugas_screen.dart               # Daftar lengkap tugas yang ditugaskan ke teknisi terkait
        └── form_penyelesaian_screen.dart          # Form upload foto sesudah perbaikan & catatan tindakan
```

## 2. Tanggung Jawab Tiap Folder

### `constants/`

Menyimpan nilai tetap agar tidak tersebar (*hardcoded*) di banyak file UI.

* **`app_colors.dart`:** Warna primer kampus, warna latar, dan warna status tiket.
* **`app_constants.dart`:** Konstanta nama koleksi Firestore, daftar kategori aset default, dan teks konstan aplikasi.

### `models/`

Berfungsi sebagai penerjemah antara dokumen mentah Cloud Firestore (`Map<String, dynamic>`) dan objek Dart, sekaligus menyimpan definisi *enum* statis (`UserRole`, `ReportStatus`, `ReportPriority`).

* Setiap model wajib memiliki `factory Model.fromFirestore(DocumentSnapshot doc)` dan `Map<String, dynamic> toMap()`.
* **Dilarang** mengakses `doc.data()['nama_field']` langsung di dalam `screens/`.

### `services/`

Satu-satunya lapisan yang boleh memanggil `FirebaseFirestore`, `FirebaseAuth`, atau utilitas pemrosesan gambar.

* File di `screens/` cukup memanggil *singleton instance* dari `services/` (misalnya `ReportService.instance.streamReportsByPelapor(uid)`) dan menerima data yang sudah berbentuk `Model` atau `List<Model>`.



### `widgets/`

Berisi komponen UI tanpa `Scaffold` yang digunakan di lebih dari satu halaman atau lintas role—contohnya `ReportCard` yang dipakai di daftar laporan semua role, `Base64ImageViewer` untuk render foto, dan `ResolutionActionBar` untuk tombol serta dialog **Konfirmasi Selesai / Belum Beres** yang dipakai bersama oleh Pelapor dan Admin.

### `screens/`

Berisi tampilan halaman penuh (`Scaffold`). Dikelompokkan berdasarkan aktor pengguna agar setiap anggota tim bisa fokus mengerjakan foldernya masing-masing tanpa saling menimpa file.

* **Pola Shell `*MainScreen` & `IndexedStack`:** Setiap role memiliki satu halaman induk (`PelaporMainScreen`, `AdminMainScreen`, dan `TeknisiMainScreen`) yang memegang `Scaffold`, `BottomNavbar`, dan `IndexedStack`. Keempat halaman tab utama (*Beranda*, *Riwayat/Tiket/Tugas*, *Notifikasi*, *Profil*) **tidak memasang `bottomNavigationBar` sendiri** agar navbar tetap diam di tempat (tidak ikut berkedip/tergeser) saat berpindah tab dan `ProfileScreen` dapat dipakai bersama lintas role tanpa duplikasi kode.
* **Pola Pemisahan Aksi `DetailLaporanScreen` per Role:** Halaman `screens/shared/detail_laporan_screen.dart` hanya menangani struktur konten yang seragam untuk semua role (header aset, status & SLA, foto sebelum/sesudah dengan *zoom*, tombol riwayat aset, dan timeline status). Seluruh tombol aksi *sticky bottom bar* beserta modal/dialog khususnya dipisahkan ke `screens/<role>/widgets/*_report_actions.dart` (`pelapor_report_actions.dart`, `admin_report_actions.dart`, `teknisi_report_actions.dart`) agar file utama tetap ringkas dan minim *merge conflict* saat tiap penanggung jawab role menyambungkan aksi ke `ReportService`.
* **Pemindai QR Lintas Role (`screens/shared/scan_qr_screen.dart`):** Satu halaman pemindai kamera bersama yang mendukung mode pemindaian berdasarkan peran pemanggil (Pelapor memindai `ASSET:<id>` untuk melapor, Admin memindai `USER:<uid>` untuk aktivasi teknisi maupun `ASSET:<id>` untuk cek histori aset, dan Teknisi memindai `ASSET:<id>` untuk mengakses riwayat & tiket fasilitas di lapangan).

## 3. Alur Inti & Skenario Lintas Role

### A. Siklus Hidup Tiket (6 Status)

```text
                  ┌──► rejected (Ditolak Admin + wajib alasan penolakan)
                  │
reported ─────────┴──► verified ──► assigned ──► in progress ──► resolved
(Pelapor kirim)       (Admin cek     (Admin pilih   (Teknisi        (Foto sesudah &
                      & set SLA)      teknisi)       kerjakan)       konfirmasi)
```

* **`ReportStatus.reported`:** Laporan baru masuk dari Pelapor (masih bisa dibatalkan oleh Pelapor).
* **`ReportStatus.rejected`:** Laporan tidak valid/ganda (final, tidak masuk perhitungan SLA maupun histori aset).
* **`ReportStatus.verified` & `ReportStatus.assigned`:** Admin memvalidasi laporan, menetapkan **prioritas** (yang otomatis menghitung tenggat **SLA**), dan memilih Teknisi berdasarkan beban tugas aktif.
* **`ReportStatus.inProgress`:** Teknisi mulai menangani perbaikan di lokasi.
* **`ReportStatus.resolved`:** Teknisi mengunggah **foto sesudah diperbaiki** dan catatan perbaikan, lalu Pelapor (atau Admin) dapat menekan konfirmasi penyelesaian atau mengajukan ulang (*re-open*) ke `assigned` apabila perbaikan belum beres.

### B. Aturan SLA (*Service Level Agreement*)

Saat Admin memverifikasi tiket dan memilih prioritas, sistem otomatis mengisi field `deadlineAt` menggunakan `ReportPriority.slaHours`:

* **Tinggi (`ReportPriority.tinggi`):** +24 jam dari waktu verifikasi.
* **Sedang (`ReportPriority.sedang`):** +72 jam (3 hari) dari waktu verifikasi.
* **Rendah (`ReportPriority.rendah`):** +168 jam (7 hari) dari waktu verifikasi.

### C. Alur Fleksibel QR Code, Riwayat Aset, & Anti-Loop Navigasi

```text
pelapor_home_screen
  ├──► [Scan QR]      ──► shared/scan_qr_screen ──► history_aset_screen ──► form_pengaduan_screen (aset terisi)
  └──► [Lapor Manual] ─────────────────────────────────────────────────────► form_pengaduan_screen (pilih dropdown)

admin/detail_aset_screen ──► [Riwayat Kerusakan Aset] ──► history_aset_screen ◄──► detail_laporan_screen
                                                               (fromAssetHistory: true mencegah loop stack)
```

* **Standar Prefix & Stiker QR Code:** Seluruh QR Code menggunakan awalan tipe agar pemindai langsung bisa membedakan jenis QR secara otomatis:
  * **QR Fasilitas / Aset:** Payload QR berisi `ASSET:<assetId>` (menggunakan Auto-ID dokumen Firestore pada koleksi `assets`), sedangkan teks cetak pada stiker menampilkan **`asset.nama`** (misal `Kursi#01`) dan lokasi (`Gedung - Ruangan`) agar tetap bisa dipilih di jalur **Lapor Manual** jika kamera bermasalah.
  * **QR Profil Akun:** Payload QR berisi `USER:<uid>` (ditampilkan di `profile_screen.dart` untuk dipindai Admin via `shared/scan_qr_screen.dart`).
* **Anti-Loop Navigasi `HistoryAssetScreen` $\leftrightarrow$ `DetailLaporanScreen`:** Karena kartu di `HistoryAssetScreen` membuka `DetailLaporanScreen` dan `DetailLaporanScreen` memiliki tombol **Lihat Riwayat Aset**, gunakan parameter `fromAssetHistory: true` saat membuka detail dari halaman riwayat aset. Dengan begitu, mengetuk **Lihat Riwayat Aset** dari dalam detail akan langsung melakukan `Navigator.pop(context)` alih-alih menumpuk halaman baru.

### D. Sistem Notifikasi Dalam Aplikasi (*In-App Notification*)

Notifikasi dibangun menggunakan koleksi Firestore `notifications` secara *real-time* (tanpa memerlukan Cloud Functions atau Firebase Storage):

* **Pelapor** menerima notifikasi saat laporan diverifikasi/ditugaskan, ditolak (`rejected`), atau selesai diperbaiki (`resolved`).
* **Teknisi** menerima notifikasi saat Admin menugaskan tiket baru kepadanya (`assigned`) maupun saat tiket dibuka kembali (*re-open*).
* **Admin** menerima notifikasi saat laporan baru masuk (`reported`), saat Teknisi menandai tugas selesai (`resolved`), atau saat Pelapor mengajukan sanggahan (*re-open*).
* Menekan item notifikasi di `notification_screen.dart` akan langsung membuka `detail_laporan_screen.dart` sesuai `reportId` terkait.

## 4. Desain Database Firestore (*Flat Collections*)

Proyek ini menggunakan **4 koleksi sejajar (*root collections*)** tanpa *subcollection* agar mudah di-*query* dari sudut pandang Pelapor, Admin, Teknisi, maupun histori aset.

> **Aturan ID Dokumen (`doc.id` Murni):** Seluruh koleksi tidak menyimpan ulang field ID di dalam isi dokumen; `fromFirestore` langsung mengambilnya dari `doc.id`. Koleksi `users` wajib disimpan menggunakan `.doc(uid).set(...)`, sedangkan koleksi `assets`, `reports`, dan `notifications` menggunakan **Auto-ID Firestore** (`.doc()` / `.add(...)`).

1. **`users`** *(Document ID = `uid` dari Firebase Auth)*
   * `nama`, `email`, `role` (`'pelapor'` | `'admin'` | `'teknisi'`), `photoBase64` *(opsional, Base64 < 250 KB)*, `createdAt`.
2. **`assets`** *(Document ID = Auto-generated Firestore ID; payload QR di-generate dengan prefix `'ASSET:<doc.id>'`)*
   * `nama` *(unik secara case-insensitive per kombinasi `gedung` + `ruangan`, misal `'Kursi#01'`)*, `kategori`, `gedung`, `ruangan`, `createdAt`.
3. **`reports`** *(Document ID = Auto-generated)*
   * `assetId` *(nullable; null jika jalur Fasilitas Lainnya)*, `assetNama`, `assetLokasi`, `pelaporId`, `pelaporNama`, `teknisiId`, `teknisiNama`, `deskripsi`, `fotoSebelum` *(Base64)*, `fotoSesudah` *(Base64)*, `status`, `prioritas`, `deadlineAt`, `rejectionReason`, `catatanTeknisi`, `isConfirmed`, `createdAt`, `resolvedAt`, `riwayatStatus`.
   * *Catatan Denormalisasi:* `assetNama`, `assetLokasi`, `pelaporNama`, dan `teknisiNama` ikut disimpan langsung di `reports` agar daftar laporan dapat ditampilkan dalam satu kali baca tanpa *query* tambahan.
4. **`notifications`** *(Document ID = Auto-generated)*
   * `recipientId` *(UID penerima)*, `reportId`, `title`, `message`, `isRead` *(`bool`)*, `createdAt`.

## 5. Aturan Kolaborasi & Git Tim

1. **Penamaan File & Variabel:**
   * Nama file halaman penuh wajib `snake_case`, menyertakan peran/fungsinya, dan berakhiran `_screen.dart` untuk seluruh halaman di `screens/` (contoh: `pelapor_home_screen.dart`, `history_aset_screen.dart`, `detail_aset_screen.dart`).
   * Komponen sub-UI khusus role yang berada di `screens/<role>/widgets/` **tidak** memakai akhiran `_screen.dart`, melainkan akhiran sesuai fungsinya (contoh: `admin_report_actions.dart`, `pelapor_report_actions.dart`, `teknisi_report_actions.dart`).
   * Nama *class* wajib `PascalCase` sesuai nama file (contoh: `PelaporHomeScreen`, `HistoryAssetScreen`, `AdminReportActions`).
2. **Alur Branch & Commit:**
   * Jangan *push* fitur setengah jadi langsung ke `main`.
   * Buat *branch* baru dari `main` sesuai tugas: `feature/pelapor-scan-qr`, `feature/admin-verifikasi`, `fix/login-error`, atau `chore/update-docs`.
   * Gunakan awalan pesan *commit* yang jelas: `feat: ...`, `fix: ...`, `docs: ...`, atau `chore: ...`.