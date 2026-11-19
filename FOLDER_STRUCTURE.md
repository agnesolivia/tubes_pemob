# 📐 Panduan Struktur Folder & Arsitektur Proyek

Dokumen ini menjadi acuan teknis bagi seluruh anggota tim dalam mengembangkan **Aplikasi Pengaduan Fasilitas Kampus** (Flutter + Firebase). Tujuannya agar struktur kode antar-anggota tetap rapi, konsisten, dan minim *merge conflict* selama kolaborasi Git.

## 1. Peta Lengkap Direktori `lib/`

Proyek ini menggunakan pola **Layer-First** yang dikombinasikan dengan pemisahan halaman berdasarkan *role* (`pelapor`, `admin`, `teknisi`) di dalam `screens/`. Seluruh file halaman di dalam `screens/` wajib menggunakan akhiran `_screen.dart`.

```
lib/
├── main.dart                             # Entry point aplikasi, inisialisasi Firebase, & routing awal
│
├── constants/                            # Nilai konstan & konfigurasi global
│   ├── app_colors.dart                   # Palet warna utama, status badge, & tema
│   └── app_constants.dart                # Nama koleksi Firestore, kategori default, & teks umum
│
├── models/                               # Blueprint objek data, enum, & konversi Firestore
│   ├── user_model.dart                   # UserModel + enum UserRole ('pelapor' | 'admin' | 'teknisi')
│   ├── asset_model.dart                  # AssetModel (data ruangan/aset kampus & kode QR)
│   ├── report_model.dart                 # ReportModel, StatusHistoryItem, & enum ReportStatus / ReportPriority
│   └── notification_model.dart           # NotificationModel (notifikasi perubahan status tiket antar-role)
│
├── services/                             # Seluruh komunikasi backend (Firebase Auth & Cloud Firestore)
│   ├── auth_service.dart                 # Login, register, Google Sign-In, kelola role, & stream UserModel
│   ├── storage_service.dart              # Kompresi foto lokal (< 250 KB) & konversi Base64 dua arah
│   ├── asset_service.dart                # CRUD master data ruangan/aset & lookup berdasarkan ID QR
│   ├── report_service.dart               # CRUD laporan, transisi status, hitung SLA, & log riwayat
│   └── notification_service.dart         # Stream notifikasi real-time & tandai notifikasi sudah dibaca
│
├── widgets/                              # Komponen UI kecil yang dipakai berulang di banyak halaman
│   ├── status_badge.dart                 # Label warna otomatis sesuai ReportStatus
│   ├── sla_indicator.dart                # Indikator sisa waktu / keterlambatan batas SLA
│   ├── report_card.dart                  # Kartu ringkasan laporan untuk daftar/list
│   └── base64_image_viewer.dart          # Komponen render gambar dari string Base64 + fallback error
│
└── screens/                              # Seluruh halaman penuh (Scaffold)
    ├── auth/                             # Alur sebelum masuk ke beranda role
    │   ├── auth_wrapper.dart             # Pengecek status login & pengarah otomatis sesuai role
    │   ├── login_screen.dart             # Halaman masuk (Email/Password & Google Sign-In)
    │   └── register_screen.dart          # Halaman daftar akun baru (default role: UserRole.pelapor)
    │
    ├── shared/                           # Halaman lintas role (dipakai 2 atau 3 role sekaligus)
    │   ├── detail_laporan_screen.dart    # Detail tiket lengkap + tombol aksi dinamis sesuai role
    │   ├── history_asset_screen.dart     # Info aset/ruangan & rekam jejak seluruh kerusakannya
    │   ├── notification_screen.dart      # Daftar notifikasi real-time lintas role
    │   └── profile_screen.dart           # Profil akun, edit nama tampilan, & tombol logout
    │
    ├── pelapor/                          # Khusus Sivitas Akademika & Pengunjung Kampus
    │   ├── pelapor_home_screen.dart      # Beranda pelapor, ringkasan status, & tombol Scan QR / Lapor
    │   ├── scan_qr_screen.dart           # Pemindai kamera QR Code stiker ruangan/aset
    │   ├── form_pengaduan_screen.dart    # Form buat laporan (otomatis dari QR atau pilih dropdown)
    │   └── history_pelaporan_screen.dart # Daftar riwayat laporan milik pelapor + filter status
    │
    ├── admin/                            # Khusus Pengelola Fasilitas Kampus
    │   ├── admin_dashboard_screen.dart   # Statistik tiket, monitoring kepatuhan SLA, & menu kelola
    │   ├── kelola_laporan_screen.dart    # Daftar laporan masuk untuk verifikasi, tolak, & pilih teknisi
    │   ├── kelola_aset_screen.dart       # Tambah/edit ruangan & aset + generate & cetak QR Code
    │   └── kelola_teknisi_screen.dart    # Daftar teknisi, beban tugas aktif, & ubah role user ke teknisi
    │
    └── teknisi/                          # Khusus Petugas Perbaikan Lapangan
        ├── teknisi_home_screen.dart      # Ringkasan tugas aktif & daftar prioritas SLA terdekat
        ├── daftar_tugas_screen.dart      # Daftar lengkap tugas yang ditugaskan ke teknisi terkait
        └── form_penyelesaian_screen.dart # Form upload foto sesudah perbaikan & catatan tindakan
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
Berisi komponen UI tanpa `Scaffold` yang digunakan di lebih dari satu halaman—contohnya `ReportCard` yang dipakai di beranda Pelapor, daftar Admin, maupun daftar tugas Teknisi, serta `Base64ImageViewer` untuk menampilkan foto laporan.

### `screens/`
Berisi tampilan halaman penuh (`Scaffold`). Dikelompokkan berdasarkan aktor pengguna agar setiap anggota tim bisa fokus mengerjakan foldernya masing-masing tanpa saling menimpa file.

## 3. Alur Inti & Skenario Lintas Role

### A. Siklus Hidup Tiket (6 Status)

```
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
* **`ReportStatus.resolved`:** Teknisi mengunggah **foto sesudah diperbaiki** dan catatan perbaikan, lalu Pelapor dapat menekan konfirmasi penyelesaian.

### B. Aturan SLA (*Service Level Agreement*)
Saat Admin memverifikasi tiket dan memilih prioritas, sistem otomatis mengisi field `deadlineAt` menggunakan `ReportPriority.slaHours`:
* **Tinggi (`ReportPriority.tinggi`):** +24 jam dari waktu verifikasi.
* **Sedang (`ReportPriority.sedang`):** +72 jam (3 hari) dari waktu verifikasi.
* **Rendah (`ReportPriority.rendah`):** +168 jam (7 hari) dari waktu verifikasi.

### C. Alur Fleksibel QR Code vs. Manual

```
pelapor_home_screen
  ├──► [Scan QR]      ──► scan_qr_screen ──► history_asset_screen ──► form_pengaduan_screen (aset terisi)
  └──► [Lapor Manual] ──────────────────────────────────────────────► form_pengaduan_screen (pilih dropdown)
```

### D. Sistem Notifikasi Dalam Aplikasi (*In-App Notification*)
Notifikasi dibangun menggunakan koleksi Firestore `notifications` secara *real-time* (tanpa memerlukan Cloud Functions atau Firebase Storage):
* **Pelapor** menerima notifikasi saat laporan diverifikasi/ditugaskan, ditolak (`rejected`), atau selesai diperbaiki (`resolved`).
* **Teknisi** menerima notifikasi saat Admin menugaskan tiket baru kepadanya (`assigned`).
* **Admin** menerima notifikasi saat laporan baru masuk (`reported`) atau saat Teknisi menandai tugas selesai (`resolved`).
* Menekan item notifikasi di `notification_screen.dart` akan langsung membuka `detail_laporan_screen.dart` sesuai `reportId` terkait.

## 4. Desain Database Firestore (*Flat Collections*)

Proyek ini menggunakan **4 koleksi sejajar (*root collections*)** tanpa *subcollection* agar mudah di-*query* dari sudut pandang Pelapor, Admin, Teknisi, maupun histori aset.

> **Aturan ID Dokumen (`doc.id` Murni):** Seluruh koleksi tidak menyimpan ulang field ID di dalam isi dokumen; `fromFirestore` langsung mengambilnya dari `doc.id`. Koleksi `users` dan `assets` wajib disimpan menggunakan `.doc(id).set(...)`, sedangkan `reports` dan `notifications` menggunakan `.add(...)`.

1. **`users`** *(Document ID = `uid` dari Firebase Auth)*
   * `nama`, `email`, `role` (`'pelapor'` | `'admin'` | `'teknisi'`), `createdAt`.
2. **`assets`** *(Document ID = Kode QR Aset, misal `'AC-R204'`, tanpa tanda `/`)*
   * `nama`, `kategori`, `gedung`, `ruangan`, `createdAt`.
3. **`reports`** *(Document ID = Auto-generated)*
   * `assetId`, `assetNama`, `assetLokasi`, `pelaporId`, `pelaporNama`, `teknisiId`, `teknisiNama`, `deskripsi`, `fotoSebelum` *(Base64)*, `fotoSesudah` *(Base64)*, `status`, `prioritas`, `deadlineAt`, `rejectionReason`, `catatanTeknisi`, `isConfirmed`, `createdAt`, `resolvedAt`, `riwayatStatus`.
   * *Catatan Denormalisasi:* `assetNama`, `assetLokasi`, `pelaporNama`, dan `teknisiNama` ikut disimpan langsung di `reports` agar daftar laporan dapat ditampilkan dalam satu kali baca tanpa *query* tambahan.
4. **`notifications`** *(Document ID = Auto-generated)*
   * `recipientId` *(UID penerima)*, `reportId`, `title`, `message`, `isRead` *(`bool`)*, `createdAt`.

## 5. Aturan Kolaborasi & Git Tim

1. **Penamaan File & Variabel:**
   * Nama file wajib `snake_case`, menyertakan peran/fungsinya, dan berakhiran `_screen.dart` untuk seluruh halaman di `screens/` (contoh: `pelapor_home_screen.dart`, `history_asset_screen.dart`, `report_model.dart`).
   * Nama *class* wajib `PascalCase` sesuai nama file (contoh: `PelaporHomeScreen`, `HistoryAssetScreen`).
2. **Alur Branch & Commit:**
   * Jangan *push* fitur setengah jadi langsung ke `main`.
   * Buat *branch* baru dari `main` sesuai tugas: `feature/pelapor-scan-qr`, `feature/admin-verifikasi`, `fix/login-error`, atau `chore/update-docs`.
   * Gunakan awalan pesan *commit* yang jelas: `feat: ...`, `fix: ...`, `docs: ...`, atau `chore: ...`.