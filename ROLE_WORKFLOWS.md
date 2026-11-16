# 🔄 Alur Fitur & Spesifikasi Fungsional per Role

Dokumen ini berisi rincian **apa saja yang bisa dilakukan oleh masing-masing aktor**, alur perubahan data/status di balik layar, serta **batasan teknis** yang wajib diperhatikan selama pengembangan. Desain tampilan (warna, layout, animasi, dan komponen visual) sepenuhnya dibebaskan kepada tim *frontend*.

## 1. Alur Autentikasi & Modul Bersama (`auth/` & `shared/`)

### A. Autentikasi (`login_screen.dart`, `register_screen.dart`, `auth_wrapper.dart`)

* **Registrasi Mandiri:** Pengguna baru mendaftar menggunakan Email/Password (atau Google Sign-In) dengan mengisi Nama dan NIM/NIP. Sistem otomatis menyimpan profil ke koleksi `users` dengan nilai default `role: 'pelapor'`.

* **Auto-Routing Berbasis Role:** `AuthWrapper` memantau status login Firebase Auth, lalu membaca dokumen profil di koleksi `users` untuk mengarahkan pengguna secara otomatis ke:

  * `PelaporHomeScreen` jika `role == 'pelapor'`

  * `AdminDashboardScreen` jika `role == 'admin'`

  * `TeknisiHomeScreen` jika `role == 'teknisi'`

* **Catatan Akun Admin & Teknisi:** Tidak ada opsi memilih role saat registrasi mandiri. Akun `admin` pertama diatur manual di Firebase Console, sedangkan akun `teknisi` diaktifkan oleh Admin melalui menu kelola teknisi.

### B. Detail Laporan (`detail_laporan_screen.dart`)

Satu halaman bersama untuk melihat detail tiket (`ReportModel`), berisi informasi aset, lokasi, deskripsi, foto kerusakan (`fotoSebelum`), foto hasil perbaikan (`fotoSesudah` jika sudah selesai), indikator SLA, dan riwayat perubahan status.

* **Tombol Aksi Dinamis:** Bagian aksi di halaman ini berubah menyesuaikan kombinasi **`user.role`** dan **`report.status`** (rincian tiap role ada di bagian bawah).

### C. Riwayat Aset / Ruangan (`history_asset_screen.dart`)

* Menampilkan detail fasilitas (`namaAset`, `kategori`, `gedung`, `ruangan`) dan daftar seluruh laporan kerusakan yang pernah terjadi pada `assetId` tersebut.

* **Aturan Data:** Laporan berstatus `rejected` **tidak ditampilkan** di halaman ini agar rekam jejak kerusakan aset tetap valid.

* **Pencegahan Laporan Ganda:** Jika di aset tersebut masih ada tiket aktif (`reported`, `verified`, `assigned`, atau `in progress`), sistem memberi penanda bahwa kerusakan sedang ditangani.

### D. Notifikasi Dalam Aplikasi (`notification_screen.dart`)

* Menampilkan daftar dokumen dari koleksi `notifications` milik `recipientId == currentUser.uid`, diurutkan dari yang terbaru.

* Saat item notifikasi ditekan:

  1. Field `isRead` diperbarui menjadi `true`.

  2. Pengguna langsung diarahkan ke `DetailLaporanScreen` sesuai `reportId` yang tersimpan di notifikasi.

### E. Profil Pengguna (`profile_screen.dart`)

* **Semua Role:** Melihat informasi akun (Nama, Email, NIM/NIP, Role), edit nama/nomor induk, dan tombol **Logout**.

* **Khusus Teknisi:** Terdapat *switch/toggle* **Status Ketersediaan (`isAvailable`)** untuk menandai apakah teknisi sedang siap menerima tugas baru atau sedang penuh/libur.

## 2. Alur Role: Pelapor (`screens/pelapor/`)

Aktor: Mahasiswa, Dosen, dan Staf Kampus.

### Alur Utama Pelaporan (Fleksibel: QR vs. Manual)

1. **Beranda (`pelapor_home_screen.dart`):**

   * Melihat ringkasan jumlah laporan pribadi (*Menunggu*, *Diproses*, *Selesai*).

   * Melihat daftar laporan aktif terbaru di kampus (untuk mengecek apakah fasilitas rusak sudah dilaporkan orang lain).

   * Memilih satu dari dua jalur pelaporan: **Scan QR** atau **Lapor Manual**.

2. **Jalur 1 — Scan QR (`scan_qr_screen.dart`):**

   * Kamera memindai QR Code pada stiker ruangan/aset untuk membaca teks `assetId` (misal: `AC-R204`).

   * Sistem mencocokkan `assetId` ke koleksi `assets`. Jika ditemukan, pengguna diarahkan ke `HistoryAssetScreen` untuk melihat riwayat aset tersebut, lalu menekan tombol **Buat Laporan** menuju `FormPengaduanScreen` dengan data aset sudah terisi otomatis.

3. **Jalur 2 — Lapor Manual (`form_pengaduan_screen.dart`):**

   * Jika masuk tanpa QR (`selectedAsset == null`), pengguna memilih **Gedung** $\rightarrow$ **Ruangan** $\rightarrow$ **Aset** melalui *dropdown* berjenjang.

4. **Pengisian & Pengiriman Laporan (`form_pengaduan_screen.dart`):**

   * Pengguna mengisi deskripsi kerusakan dan wajib melampirkan 1 foto bukti (`fotoSebelum`) dari kamera atau galeri.

   * Saat dikirim:

     * Dokumen baru tersimpan di `reports` dengan `status: 'reported'`.

     * Sistem mengirim notifikasi ke Admin bahwa ada laporan baru masuk.

5. **Riwayat & Tindak Lanjut (`history_pelaporan_screen.dart` & `detail_laporan_screen.dart`):**

   * Pelapor memantau seluruh tiket miliknya dengan filter status.

   * **Jika status `reported`:** Pelapor masih bisa **membatalkan/menghapus** laporan jika salah input.

   * **Jika status `rejected`:** Pelapor dapat membaca alasan penolakan (`rejectionReason`) dari Admin.

   * **Jika status `resolved`:** Pelapor melihat perbandingan foto sebelum & sesudah perbaikan, serta dapat menekan tombol **Konfirmasi Selesai** (opsional: memberi rating/ulasan singkat).

## 3. Alur Role: Admin (`screens/admin/`)

Aktor: Pengelola Sarana & Prasarana Kampus.

### Alur Kerja Admin

1. **Dashboard Pantauan (`admin_dashboard_screen.dart`):**

   * Melihat statistik tiket berdasarkan status (`reported`, `verified`/`assigned`/`in progress`, `resolved`).

   * Melihat daftar peringatan tiket **Overdue SLA** (tiket belum `resolved` dan waktu sekarang sudah melewati `deadlineAt`).

2. **Verifikasi, Penolakan & Penugasan (`kelola_laporan_screen.dart` & `detail_laporan_screen.dart`):**

   * Admin memfilter daftar seluruh laporan masuk berdasarkan status, gedung, atau tingkat prioritas.

   * **Aksi pada tiket `reported`:**

     * **Verifikasi & Tugaskan:** Admin wajib memilih **Tingkat Prioritas** (*Tinggi*, *Sedang*, *Rendah*) yang otomatis menghitung `deadlineAt`. Admin dapat langsung memilih **Teknisi** (status langsung menjadi `assigned`) atau mengosongkannya terlebih dahulu jika teknisi belum tersedia/menunggu suku cadang (status menjadi `verified`).

     * **Tolak Laporan:** Admin wajib mengisi alasan penolakan (`rejectionReason`). Status berubah menjadi `rejected` (final).

   * **Aksi pada tiket `verified`:** Admin memilih teknisi yang tersedia untuk mengubah status menjadi `assigned`.

   * **Aksi pada tiket `assigned` / `in progress`:** Admin dapat mengalihkan tugas ke teknisi lain jika terjadi kendala di lapangan.

   * *Catatan:* Setiap perubahan status otomatis mengirim notifikasi ke Pelapor (dan Teknisi jika ditugaskan).

3. **Kelola Aset & Generator QR (`kelola_aset_screen.dart`):**

   * Menambah, mengubah, atau menghapus master data fasilitas di koleksi `assets` (ID Aset, Nama Aset, Kategori, Gedung, Ruangan).

   * Menghasilkan tampilan **QR Code** dari `asset.id` (menggunakan `qr_flutter`) beserta opsi simpan/bagikan gambar QR untuk dicetak.

4. **Kelola Teknisi (`kelola_teknisi_screen.dart`):**

   * Melihat daftar seluruh teknisi, status ketersediaan (`isAvailable`), serta jumlah tiket aktif (`assigned` + `in progress`) yang sedang ditangani masing-masing teknisi.

   * Mengubah peran (`role`) pengguna terdaftar dari `pelapor` menjadi `teknisi` berdasarkan pencarian email/NIM.

## 4. Alur Role: Teknisi (`screens/teknisi/`)

Aktor: Petugas Perbaikan Lapangan.

### Alur Kerja Teknisi

1. **Beranda Teknisi (`teknisi_home_screen.dart`):**

   * Melihat ringkasan jumlah tugas pribadi (*Baru Ditugaskan*, *Sedang Dikerjakan*, *Selesai*).

   * Melihat daftar tugas aktif yang **diurutkan otomatis berdasarkan batas SLA terdekat / paling mendesak**.

2. **Daftar Tugas (`daftar_tugas_screen.dart`):**

   * Menampilkan seluruh laporan dengan `teknisiId == currentUser.uid`.

   * Mendukung filter berdasarkan **Status** (`assigned`, `in progress`, `resolved`) dan **Gedung** (memudahkan teknisi mengerjakan beberapa tugas dalam satu gedung sekaligus).

3. **Eksekusi Perbaikan (`detail_laporan_screen.dart` & `selesaikan_tugas_screen.dart`):**

   * **Jika status `assigned`:** Teknisi membuka detail tiket (bisa mengecek `HistoryAssetScreen` untuk melihat riwayat servis alat sebelumnya), lalu menekan tombol **Mulai Kerjakan** saat tiba di lokasi. Status berubah menjadi `in progress` dan notifikasi terkirim ke Pelapor.

   * **Jika status `in progress`:** Teknisi menekan tombol **Selesaikan Tugas** untuk membuka `SelesaikanTugasScreen`.

   * **Form Penyelesaian (`selesaikan_tugas_screen.dart`):**

     * Teknisi wajib mengunggah foto hasil perbaikan (`fotoSesudah`) dan mengisi catatan tindakan perbaikan (`catatanTeknisi`).

     * Saat disimpan: status berubah menjadi `resolved`, `resolvedAt` dicatat, dan sistem mengirim notifikasi ke Pelapor serta Admin.

## 5. Catatan Teknis Penting (Wajib Diperhatikan Tim)

1. **Kompresi Foto & Batas 1 MB Dokumen Firestore:**

   * Karena penyimpanan foto menggunakan **string Base64 di dalam Firestore** (tanpa Firebase Storage), setiap foto **wajib dikompres** di `StorageService` (resolusi maksimal `800x800`, kualitas `~60%`) agar ukurannya berada di kisaran **80–150 KB** (batas keras maksimal **250 KB per foto**).

   * Satu dokumen `reports` menampung 2 foto (`fotoSebelum` dan `fotoSesudah`). Menjaga ukuran tiap foto di bawah 250 KB memastikan total dokumen tetap aman di bawah batas maksimal Firestore (1 MiB).

   * Untuk menampilkan gambar di UI, decode string Base64 menggunakan `Image.memory(base64Decode(base64String))`.

2. **Rumus Perhitungan SLA (`deadlineAt`):**

   * Dihitung otomatis saat Admin memverifikasi laporan berdasarkan prioritas yang dipilih:

     * **`tinggi`:** `verifiedAt + 24 jam`

     * **`sedang`:** `verifiedAt + 72 jam` (3 hari)

     * **`rendah`:** `verifiedAt + 168 jam` (7 hari)

   * Tiket dianggap **Overdue (Melewati SLA)** jika `status != 'resolved'` dan `DateTime.now().isAfter(deadlineAt)`.

3. **Denormalisasi Data pada Koleksi `reports`:**

   * Saat membuat atau memperbarui tiket di `ReportService`, wajib ikut menyimpan `namaAset`, `lokasiLengkap`, `pelaporNama`, dan `teknisiNama` langsung di dokumen `reports`. Tujuannya agar halaman daftar tiket dapat menampilkan nama aset dan pelapor dalam satu kali *query* tanpa melakukan pembacaan ulang ke koleksi `assets` dan `users`.

4. **Pemicu Notifikasi (`NotificationModel`):**

   * Pembuatan dokumen notifikasi dilakukan langsung di dalam *method* `ReportService` setiap kali status laporan berubah—tidak perlu memakai Cloud Functions.

5. **Gunakan Enum dari File Model (Jangan Hardcode String):**
   * `UserRole` (ada di `user_model.dart`): `UserRole.pelapor`, `UserRole.admin`, `UserRole.teknisi`
   * `ReportStatus` (ada di `report_model.dart`): `ReportStatus.reported`, `ReportStatus.verified`, `ReportStatus.assigned`, `ReportStatus.inProgress`, `ReportStatus.resolved`, `ReportStatus.rejected`
   * `ReportPriority` (ada di `report_model.dart`): `ReportPriority.tinggi`, `ReportPriority.sedang`, `ReportPriority.rendah`
   * *Tips UI:* Untuk menampilkan teks Bahasa Indonesia ke layar, langsung panggil `.label` (contoh: `report.status.label` otomatis menghasilkan `"Sedang Dikerjakan"`).

6. **ID Dokumen Firestore (`doc.id` Murni):**
   * Koleksi `users` dan `assets` tidak menyimpan ulang field `uid`/`id` di dalam dokumen. Saat menyimpan data baru di `services/`, wajib gunakan `.doc(id).set(...)` (bukan `.add(...)`).
   * Kode QR Aset (`asset.id`) **dilarang mengandung karakter garis miring (`/`)** karena akan terbaca sebagai jalur *subcollection* oleh Firestore (gunakan tanda hubung `-`, misal: `AC-R204`).

## 6. Checklist Pengerjaan Tim (Paralel & Anti-Blocking)

Agar seluruh anggota tim bisa mengerjakan tugas secara bersamaan tanpa saling menunggu (*blocking*), pengerjaan dibagi menjadi **Tahap Fondasi** (kontrak data) dan **Jalur Independen** yang bebas diambil oleh siapa saja sesuai kapasitas tim.

> **Aturan Kerja Anti-Blocking:**
>
> * **Klaim sebelum *coding*:** Tandai nama/inisial di samping item yang diambil (atau infokan di grup/GitHub Issue) sebelum membuat *branch* baru agar tidak terjadi tabrakan file.
>
> * **Siapkan *Dummy Data* di Firebase Console:** Isi manual 1–2 data contoh di koleksi `assets` dan `reports` (dengan variasi status `reported`, `assigned`, `in progress`, `resolved`) langsung di Firebase Console. Dengan begitu, pengerjaan layar **Admin** dan **Teknisi** bisa langsung diuji tanpa menunggu fitur *Buat Laporan* milik **Pelapor** selesai.
>
> * **UI bisa berjalan lebih dulu:** Selama *method* di `services/` belum selesai dibuat, halaman UI tetap bisa dikerjakan menggunakan objek `Model` sementara (*mock object*).

### Tahap 0 — Fondasi & Kontrak Data (Prioritas Pertama)

*Selesaikan tahap ini lebih dulu dan merge ke `main` agar semua jalur di bawah memiliki acuan tipe data yang sama.*

* [ ] Buat `constants/app_colors.dart` & `constants/app_constants.dart` (konstanta status, prioritas, durasi SLA)

* [ x ] Buat `models/user_model.dart`

* [ x ] Buat `models/asset_model.dart`

* [ x ] Buat `models/report_model.dart`

* [ x ] Buat `models/notification_model.dart`

* [ ] Isi data sampel awal di Firebase Console (akun uji untuk `pelapor`, `admin`, `teknisi`, serta dummy `assets` & `reports`)

### Jalur A — Layanan Backend (`services/`)

* [ ] `services/auth_service.dart` (Login, Register, Logout, & ambil `UserModel`)

* [ ] `services/storage_service.dart` (Ambil gambar, kompres < 250 KB, & encode/decode Base64)

* [ ] `services/asset_service.dart` (CRUD data aset/ruangan & pencarian berdasarkan ID QR)

* [ ] `services/report_service.dart` (CRUD laporan, transisi status, hitung SLA, & pemicu notifikasi)

### Jalur B — Komponen UI Reusable (`widgets/`)

*Dapat dikerjakan sepenuhnya secara paralel tanpa menunggu koneksi Firebase.*

* [ ] `widgets/status_badge.dart` (Label warna otomatis per status tiket)

* [ ] `widgets/sla_indicator.dart` (Indikator sisa waktu / label *Overdue* berdasarkan `deadlineAt`)

* [ ] `widgets/report_card.dart` (Kartu ringkasan laporan untuk daftar di seluruh role)

* [ ] `widgets/base64_image_viewer.dart` (Komponen render gambar dari string Base64 + tampilan saat error/kosong)

### Jalur C — Modul Autentikasi & Lintas Role (`screens/auth/` & `screens/shared/`)

* [ ] `screens/auth/login_screen.dart` & `register_screen.dart`

* [ ] `screens/auth/auth_wrapper.dart` (*Auto-routing* sesuai `user.role`)

* [ ] `screens/shared/detail_laporan_screen.dart` (Detail tiket + tombol aksi kondisional per kombinasi role & status)

* [ ] `screens/shared/history_asset_screen.dart` (Info aset & riwayat kerusakan non-`rejected`)

* [ ] `screens/shared/notification_screen.dart` (Daftar notifikasi *real-time* & tandai sudah dibaca)

* [ ] `screens/shared/profile_screen.dart` (Info profil, edit nama/NIM, toggle status teknisi, & logout)

### Jalur D — Modul Pelapor (`screens/pelapor/`)

* [ ] `screens/pelapor/pelapor_home_screen.dart` (Ringkasan status pribadi, laporan kampus terkini, & tombol QR/Manual)

* [ ] `screens/pelapor/scan_qr_screen.dart` (Pemindai kamera QR & validasi `assetId`)

* [ ] `screens/pelapor/form_pengaduan_screen.dart` (Form dual-mode: otomatis dari QR & *dropdown* manual + unggah foto)

* [ ] `screens/pelapor/history_pelaporan_screen.dart` (Daftar riwayat laporan pelapor + filter status)

### Jalur E — Modul Admin (`screens/admin/`)

* [ ] `screens/admin/admin_dashboard_screen.dart` (Statistik tiket & daftar peringatan *Overdue SLA*)

* [ ] `screens/admin/kelola_laporan_screen.dart` (Filter semua laporan & modal verifikasi/tolak/tugaskan teknisi)

* [ ] `screens/admin/kelola_aset_screen.dart` (CRUD master aset & generator tampilan/simpan QR Code)

* [ ] `screens/admin/kelola_teknisi_screen.dart` (Daftar teknisi, beban tugas aktif, & ubah role user ke teknisi)

### Jalur F — Modul Teknisi (`screens/teknisi/`)

* [ ] `screens/teknisi/teknisi_home_screen.dart` (Ringkasan tugas pribadi & daftar urut batas SLA terdekat)

* [ ] `screens/teknisi/daftar_tugas_screen.dart` (Daftar tugas teknisi + filter status & gedung)

* [ ] `screens/teknisi/selesaikan_tugas_screen.dart` (Form unggah foto sesudah perbaikan & catatan tindakan)