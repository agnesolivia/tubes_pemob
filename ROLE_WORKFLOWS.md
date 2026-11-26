# 🔄 Alur Fitur & Spesifikasi Fungsional per Role

Dokumen ini berisi rincian **apa saja yang bisa dilakukan oleh masing-masing aktor**, alur perubahan data/status di balik layar, serta **batasan teknis** yang wajib diperhatikan selama pengembangan. Desain tampilan (warna, layout, animasi, dan komponen visual) sepenuhnya dibebaskan kepada tim *frontend*.

## 1. Alur Autentikasi & Modul Bersama (`auth/` & `shared/`)

### A. Autentikasi (`login_screen.dart`, `register_screen.dart`, `email_verification_screen.dart`, `auth_wrapper.dart`)

* **Registrasi Mandiri & Verifikasi Email:**

  * Pengguna baru yang mendaftar via **Email/Password** mengisi Nama, Email, dan Password. Sistem otomatis menyimpan profil ke koleksi `users` dengan nilai default `role: UserRole.pelapor` sekaligus mengirim email verifikasi (`sendEmailVerification()`).

  * Pengguna yang masuk via **Google Sign-In** otomatis terverifikasi emailnya dan langsung masuk ke beranda tanpa melalui halaman verifikasi.

* **Lupa Kata Sandi (`login_screen.dart`):**

  * Tersedia tombol **"Lupa Kata Sandi?"** yang memunculkan *pop-up dialog* input email untuk mengirimkan tautan reset password resmi dari Firebase Auth (`sendPasswordResetEmail()`).

* **Auto-Routing Berbasis Verifikasi & Role (`auth_wrapper.dart`):**

  * Memantau status login Firebase Auth. Jika akun menggunakan Email/Password dan `emailVerified == false`, arahkan pengguna ke `EmailVerificationScreen` (berisi tombol cek ulang status verifikasi, kirim ulang email, dan logout).

  * Jika email sudah terverifikasi, sistem membaca dokumen profil di koleksi `users` untuk mengarahkan pengguna secara otomatis ke halaman induk (`*MainScreen`) sesuai role-nya:

    * `PelaporMainScreen` jika `user.isPelapor`

    * `AdminMainScreen` jika `user.isAdmin`

    * `TeknisiMainScreen` jika `user.isTeknisi`

* **Catatan Akun Admin & Teknisi:** Tidak ada opsi memilih role saat registrasi mandiri. Akun `admin` pertama diatur manual di Firebase Console, sedangkan akun `teknisi` (petugas internal kampus) diaktifkan oleh Admin melalui menu kelola teknisi.

### B. Pemindai QR Code Lintas Role (`scan_qr_screen.dart`)

Satu halaman kamera pemindai bersama (`screens/shared/scan_qr_screen.dart`) yang digunakan oleh ketiga role dengan parameter mode pemindaian:

* **Mode Aset (`ASSET:<assetId>` — Pelapor, Admin, & Teknisi):** Memastikan teks QR diawali `ASSET:` (jika berawalan `USER:` atau format lain, tampilkan pesan error yang sesuai), melepas prefix `ASSET:` untuk mendapatkan Auto-ID dokumen aset, mencocokkan ke koleksi `assets`, lalu membuka `HistoryAssetScreen` (Pelapor lanjut membuat laporan, Admin melihat detail/riwayat aset, dan Teknisi melihat riwayat servis serta tiket aktif pada fasilitas tersebut).
* **Mode Pengguna (`USER:<uid>` — Khusus Admin dari `KelolaTeknisiScreen`):** Memastikan teks QR diawali `USER:`, melepas prefix untuk mendapatkan `uid` kandidat, mengambil data `UserModel`, lalu menampilkan dialog konfirmasi pengangkatan role menjadi `teknisi`.

### C. Detail Laporan (`detail_laporan_screen.dart`)

Satu halaman bersama untuk melihat detail tiket (`ReportModel`), berisi informasi aset, lokasi, deskripsi, foto kerusakan (`fotoSebelum`), foto hasil perbaikan (`fotoSesudah` jika sudah selesai), indikator SLA, lencana status konfirmasi (`isConfirmed`), dan riwayat perubahan status.

* **Tombol Aksi Dinamis:** Bagian aksi utama di halaman ini berubah menyesuaikan kombinasi **`user.role`** dan **`report.status`** (rincian tiap role ada di bagian bawah).

* **Aturan Konfirmasi Selesai & Sanggahan (*Re-open*) pada Status `resolved`:**

  * **Hak Akses Aksi:** Tombol tindak lanjut pada tiket berstatus `ReportStatus.resolved` (ketika `isConfirmed == false`) hanya ditampilkan kepada **Pelapor pembuat laporan** (`report.pelaporId == currentUser.uid`) dan **Admin** (`user.isAdmin`, sebagai *supervisor override*). Pelapor lain yang membuka tiket hanya memiliki akses baca (*read-only*).

  * **Konfirmasi Selesai:** Mengubah `isConfirmed` menjadi `true` (status tetap `ReportStatus.resolved`), menampilkan lencana *"Terkonfirmasi"*, dan menambahkan catatan log ke `riwayatStatus`.

  * **Belum Beres / Ajukan Ulang (*Re-open*):** Mewajibkan pengisian catatan/alasan singkat, mengembalikan status tiket dari `resolved` menjadi `assigned` (`resolvedAt: null`, `isConfirmed: false`), mencatat riwayat sanggahan di `riwayatStatus`, serta mengirim notifikasi ke Admin dan Teknisi terkait.

* **Konsistensi Informasi & Tombol Riwayat Aset:**

  * Baris informasi aset menampilkan `report.assetNama` beserta lokasi (`report.assetLokasi`), dan apabila `assetId == null` ditampilkan penanda tambahan bahwa fasilitas belum terdaftar di inventaris.

  * Tombol **Lihat Riwayat Aset** selalu tampil aktif dan seragam untuk **semua role** (Pelapor, Admin, dan Teknisi) serta untuk semua kondisi tiket (`assetId != null` maupun `assetId == null`), mengarahkan pengguna ke `HistoryAssetScreen` dengan membawa `assetId` beserta data *fallback* `assetNama` dan `assetLokasi`.

### D. Riwayat Aset / Ruangan (`history_asset_screen.dart`)

Halaman ini menerima parameter `assetId` yang bersifat *nullable* (`String?`) beserta data *fallback* (`fallbackNama` dan `fallbackLokasi`) untuk menangani dua skenario berikut:

1. **Jika `assetId != null` (Aset Terdaftar di Koleksi `assets`):**

   * Menampilkan detail fasilitas (`nama`, `kategori`, `gedung`, `ruangan`) dari koleksi `assets` dan daftar seluruh laporan kerusakan pada `assetId` tersebut (jika belum pernah dilaporkan, tampilkan *empty state* *"Belum ada riwayat kerusakan untuk aset ini"*).

   * **Aturan Data:** Laporan berstatus `ReportStatus.rejected` **tidak ditampilkan** di halaman ini agar rekam jejak kerusakan aset tetap valid.

   * **Pencegahan Laporan Ganda:** Jika di aset tersebut masih ada tiket aktif (`reported`, `verified`, `assigned`, atau `inProgress`), sistem memberi penanda bahwa kerusakan sedang ditangani.

2. **Jika `assetId == null` (Fasilitas Lainnya / Belum Terdaftar):**

   * Halaman tidak melakukan *query* ke koleksi `assets` maupun riwayat `reports`, melainkan menampilkan kartu informasi nama & lokasi fasilitas dari tiket dengan penanda **"Belum Terdaftar di Inventaris"**, disertai ilustrasi dan pesan penjelasan bahwa fasilitas dilaporkan secara manual sehingga belum memiliki rekam jejak unit.

   * **Khusus Admin (`user.isAdmin`):** Tepat di bawah pesan tersebut, tampilkan tombol aksi **"Daftarkan sebagai Aset Baru"** untuk membuka `TambahAsetScreen` dengan nama aset (`initialNama`) dan informasi lokasi (`initialGedung`, `initialRuangan`) sudah terisi otomatis (*pre-filled*).

### E. Notifikasi Dalam Aplikasi (`notification_screen.dart`)

* Menampilkan daftar dokumen dari koleksi `notifications` milik `recipientId == currentUser.uid`, diurutkan dari yang terbaru.

* Saat item notifikasi ditekan:

  1. Field `isRead` diperbarui menjadi `true`.

  2. Pengguna langsung diarahkan ke `DetailLaporanScreen` sesuai `reportId` yang tersimpan di notifikasi.

### F. Profil Pengguna (`profile_screen.dart`)

* **Semua Role:** Melihat informasi akun (Nama, Email, Role), mengubah nama tampilan, mengubah/menghapus foto profil (`photoBase64` di `users/{uid}`), menampilkan **QR Code Profil Akun** (`USER:${user.uid}` untuk keperluan aktivasi teknisi oleh Admin), dan tombol **Logout**. Halaman ini tidak memuat `bottomNavigationBar` sendiri sehingga dapat langsung disematkan ke dalam `IndexedStack` milik `PelaporMainScreen`, `AdminMainScreen`, maupun `TeknisiMainScreen`.

## 2. Alur Role: Pelapor (`screens/pelapor/`)

Aktor: Sivitas Akademika dan Pengunjung/Tamu Kampus.

### Alur Utama Pelaporan (Fleksibel: QR vs. Manual)

1. **Navigasi Utama (`pelapor_main_screen.dart`) & Beranda (`pelapor_home_screen.dart`):**

   * `PelaporMainScreen` membungkus 4 halaman tab (`Beranda`, `Riwayat`, `Notifikasi`, `Profil`) menggunakan `IndexedStack` dan 1 `BottomNavbar` permanen di bawah (dengan tombol kamera melayang di tengah untuk membuka `FormPengaduanScreen`).

   * Di beranda, Pelapor melihat ringkasan jumlah laporan pribadi (*Menunggu*, *Diproses*, *Selesai*), daftar laporan aktif, serta tombol cepat **Buat Laporan Baru** / **Scan QR**.

2. **Jalur 1 — Scan QR (`screens/shared/scan_qr_screen.dart`):**

   * Kamera memindai QR Code pada stiker ruangan/aset dengan format `ASSET:<assetId>` (berisi Auto-ID dokumen aset di Firestore).

   * **Validasi Prefix:** Sistem memastikan teks QR diawali `ASSET:` (jika berawalan `USER:` atau format tidak dikenal, tampilkan pesan error yang sesuai). Setelah valid, awalan `ASSET:` dilepas untuk mendapatkan `assetId` (Auto-ID dokumen).

   * Sistem mencocokkan `assetId` ke koleksi `assets`. Jika ditemukan, pengguna diarahkan ke `HistoryAssetScreen` untuk melihat riwayat aset tersebut terlebih dahulu, lalu menekan tombol **Buat Laporan** menuju `FormPengaduanScreen` dengan data aset sudah terisi otomatis.

3. **Jalur 2 — Lapor Manual (`form_pengaduan_screen.dart`):**

   * **Aset Terdaftar di Sistem:** Jika masuk tanpa QR (`selectedAsset == null`), Pelapor cukup membaca teks **Nama Aset** (misalnya `Kursi#01`) dan lokasi yang tercetak pada stiker QR fisik, lalu memilih **Gedung** $\rightarrow$ **Ruangan** $\rightarrow$ **Nama Aset** melalui pilihan berjenjang (*dropdown* / daftar yang mendukung pencarian jika item banyak) dari koleksi `assets` (mengisi `assetId`, `assetNama`, dan `assetLokasi`). Daftar pilihan gedung dan ruangan dideduplikasi secara *case-insensitive*. Saat aset terpilih, tersedia pula pintasan **"Lihat Riwayat Aset"** menuju `HistoryAssetScreen` agar Pelapor dapat mengecek riwayat aset sebelum mengirim laporan.

   * **Opsi Ekstra — "Fasilitas Lainnya / Tidak Terdaftar":** Digunakan apabila fasilitas yang rusak belum dibuatkan data master oleh Admin atau berupa kerusakan bangunan umum (misalnya keramik pecah, atap bocor, kaca retak, atau kran air rusak). Ketika opsi ini dipilih, pengguna cukup mengisi **Nama Fasilitas** (`assetNama`) dan **Lokasi** (`assetLokasi`) secara manual, sehingga laporan dikirim dengan nilai **`assetId: null`**.

4. **Pengisian & Pengiriman Laporan (`form_pengaduan_screen.dart`):**

   * Pengguna mengisi deskripsi kerusakan dan wajib melampirkan foto bukti (`fotoSebelum`) dari kamera atau galeri.

   * Saat dikirim:

     * Dokumen baru tersimpan di `reports` dengan `status: ReportStatus.reported`.

     * Sistem mengirim notifikasi ke Admin bahwa ada laporan baru masuk.

5. **Riwayat & Tindak Lanjut (`history_laporan_screen.dart` & `detail_laporan_screen.dart`):**

   * Pelapor memantau seluruh tiket miliknya dengan filter status dan kolom pencarian.

   * **Jika status `reported`:** Pelapor masih bisa **membatalkan/menghapus** laporan jika salah input.

   * **Jika status `rejected`:** Pelapor dapat membaca alasan penolakan (`rejectionReason`) dari Admin.

   * **Jika status `resolved` (dan `isConfirmed == false`):** Pelapor pembuat laporan melihat perbandingan foto sebelum & sesudah perbaikan, lalu memilih salah satu dari dua tindakan:

     * **Konfirmasi Selesai:** Menandai `isConfirmed = true` sebagai tanda perbaikan sudah sesuai.

     * **Belum Beres / Ajukan Ulang:** Mengisi catatan singkat apa yang masih bermasalah agar tiket dibuka kembali menjadi `assigned` (dengan tenggat SLA awal tetap berjalan).

## 3. Alur Role: Admin (`screens/admin/`)

Aktor: Pengelola Sarana & Prasarana Kampus.

### Alur Kerja Admin

1. **Navigasi Utama (`admin_main_screen.dart`) & Dashboard Pantauan (`admin_dashboard_screen.dart`):**

   * `AdminMainScreen` membungkus 4 halaman tab (`Beranda`, `Tiket`, `Notifikasi`, `Profil`) menggunakan `IndexedStack` dan 1 `BottomNavbar` permanen di bawah (dengan tombol tengah membuka `screens/shared/scan_qr_screen.dart` untuk memindai QR profil calon teknisi `USER:<uid>` maupun QR stiker aset `ASSET:<id>`).

   * Di dashboard, Admin melihat statistik tiket berdasarkan status (`reported`, `verified`/`assigned`/`inProgress`, `resolved`) serta daftar peringatan tiket **Overdue SLA** (tiket belum `resolved` dan waktu sekarang sudah melewati `deadlineAt` / `report.isOverdue`).

2. **Verifikasi, Penolakan & Penugasan (`kelola_laporan_screen.dart` & `detail_laporan_screen.dart`):**

   * Admin memfilter daftar seluruh laporan masuk berdasarkan status, gedung, atau tingkat prioritas (termasuk kemampuan memantau tiket dari jalur *Fasilitas Lainnya* dengan `assetId == null`).

   * **Penanganan Laporan Tanpa ID Aset (`assetId == null`):** Laporan yang dikirim lewat opsi *Fasilitas Lainnya* tetap masuk ke antrean `reported` secara normal. Admin dapat langsung memverifikasi dan menugaskan teknisi **tanpa wajib membuat data baru di `TambahAsetScreen`**. Jika objek tersebut merupakan unit inventaris yang sering dilaporkan dan perlu stiker QR, Admin dapat membuka **Lihat Riwayat Aset** dari `DetailLaporanScreen` lalu menekan tombol **"Daftarkan sebagai Aset Baru"** di dalam `HistoryAssetScreen`.

   * **Aksi pada tiket `reported`:**

     * **Verifikasi & Tugaskan:** Admin wajib memilih **Tingkat Prioritas** (*Tinggi*, *Sedang*, *Rendah*) yang otomatis menghitung `deadlineAt`. Admin dapat langsung memilih **Teknisi** (status langsung menjadi `assigned`) atau mengosongkannya terlebih dahulu jika teknisi belum tersedia/menunggu suku cadang (status menjadi `verified`).

     * **Tolak Laporan:** Admin wajib mengisi alasan penolakan (`rejectionReason`). Status berubah menjadi `rejected` (final).

   * **Aksi pada tiket `verified`:** Admin memilih teknisi untuk mengubah status menjadi `assigned`.

   * **Aksi pada tiket `assigned` / `inProgress`:** Admin dapat mengalihkan tugas ke teknisi baru/lain (**Alihkan Teknisi**) jika terjadi kendala di lapangan atau setelah tiket dibuka kembali akibat perbaikan sebelumnya belum beres.

   * **Aksi pada tiket `resolved` (Pengawasan & *Supervisor Override*):** Admin menerima notifikasi saat teknisi menandai tugas selesai dan dapat mengecek foto hasil perbaikan (`fotoSesudah`). Admin berhak menekan **Konfirmasi Selesai** (`isConfirmed = true`) apabila pelapor tidak merespons dan hasil perbaikan sudah valid, atau menekan **Belum Beres / Ajukan Ulang** (mengembalikan status ke `assigned`) lalu mengalihkannya ke teknisi baru jika hasil kerja teknisi tidak sesuai.

   * *Catatan:* Setiap perubahan status otomatis mengirim notifikasi ke pihak terkait serta dicatat dalam `riwayatStatus`.

3. **Kelola Aset, Tambah Massal, & Generator QR (`kelola_aset_screen.dart`, `tambah_aset_screen.dart`, `detail_aset_screen.dart`):**

   * **Daftar & Filter Master Aset (`kelola_aset_screen.dart`):**

     * Menampilkan daftar seluruh master data fasilitas di koleksi `assets` secara *real-time* yang diurutkan berdasarkan `Gedung` $\rightarrow$ `Ruangan` $\rightarrow$ `Nama Aset`.

     * Mendukung pencarian teks serta filter berjenjang: baris pertama untuk lokasi (**Gedung** & **Ruangan**), dan baris kedua untuk **Kategori** disertai tombol cepat **Reset** saat ada filter aktif.

     * Mengetuk kartu aset membuka `DetailAsetScreen`, sedangkan tombol pintasan ikon **QR** di sisi kanan kartu langsung membuka `DetailAsetScreen` dan menggulir ke bagian stiker QR Code (`scrollToQr: true`). Tombol `+` di AppBar membuka `TambahAsetScreen`.

   * **Tambah Aset Satuan & Batch Multi-Item (`tambah_aset_screen.dart`):**

     * Halaman form penuh dengan **`doc.id` menggunakan Auto-ID Firestore** (Admin tidak perlu menginput kode ID custom).

     * **Pemilihan & Input Gedung / Ruangan (Tanpa Koleksi Terpisah):** Field **Gedung** menggunakan `Autocomplete` yang menampilkan saran seluruh gedung unik yang sudah ada sekaligus mengizinkan pengetikan gedung baru. Field **Ruangan** mengikuti pola berjenjang yang sama dengan menyarankan ruangan unik di dalam gedung terpilih. Input bersifat ***case-insensitive*** agar tidak memunculkan pilihan ganda akibat perbedaan huruf kapital atau spasi berlebih.

     * **Input Multi-Item & Batch per Ruangan:** Admin memilih **Gedung** dan **Ruangan** satu kali di kartu lokasi bagian atas, lalu dapat menambahkan beberapa baris jenis barang (`+ Tambah Jenis Barang Lain di Ruangan Ini`), masing-masing berisi **Nama Aset (atau Nama Dasar)**, **Kategori**, dan **Jumlah Unit** (default `1`).

     * **Batas Total Unit (Maksimal 500):** Form menampilkan penghitung total seluruh unit dari semua baris yang ditambahkan (misalnya `Total: 32 / 500 unit`). Total unit dalam sekali simpan wajib berada di rentang `1` hingga **`500` unit** sesuai batas transaksi `WriteBatch` Firestore.

     * **Aturan Unik per Ruangan, Karakter `#`, & Penomoran Otomatis pada `nama`:**

       * **Keunikan Berbasis `(gedung, ruangan, nama)` (*Case-Insensitive*):** Nama aset yang sama **diizinkan** apabila berada di gedung atau ruangan yang berbeda (misalnya `Kursi#01` di *Gedung A - Ruang 101* dan `Kursi#01` di *Gedung B - Ruang 202* sama-sama valid), tetapi **wajib ditolak** apabila sudah ada nama yang sama di dalam gedung dan ruangan yang sama.

       * **Jika `Jumlah == 1` (Input Satuan):** Sistem menyimpan `nama` persis seperti yang diinput Admin (setelah merapikan spasi berlebih). Karakter `#` **diizinkan** pada mode satuan agar Admin dapat menyisipkan kembali nomor unit yang pernah terhapus di tengah pada ruangan tersebut (misalnya `Kursi#02`). Jika total unit yang disimpan adalah `1`, halaman otomatis diarahkan ke `DetailAsetScreen` untuk langsung melihat/mencetak QR-nya.

       * **Jika `Jumlah > 1` (Input Batch):** Karakter `#` **dilarang** diketik manual di kolom nama dasar. Sistem otomatis menambahkan pemisah `#` dan nomor urut 2 digit pada field `nama` (`<Nama Dasar>#01`, `<Nama Dasar>#02`, dst., atau 3 digit jika $\ge 100$) serta menampilkan pratinjau rentang nama yang akan dibuat secara langsung.

       * **Auto-Continue (`Max + 1` per Ruangan):** Apabila nama dasar tersebut sudah pernah terdaftar di `(gedung, ruangan)` yang sama (misalnya sudah ada `Kursi#01`, `Kursi#03`, `Kursi#04`), sistem mencari angka akhiran **tertinggi** (`04`) di ruangan tersebut lalu melanjutkan batch baru dari `Max + 1` (`Kursi#05`, `Kursi#06`, dst.).

     * **Validasi Anti-Duplikat:** Sebelum `batch.commit()`, sistem menolak seluruh transaksi apabila ditemukan duplikat nama (*case-insensitive*) antar-baris dalam satu form maupun dengan data aset yang sudah terdaftar di `(gedung, ruangan)` yang sama.

   * **Detail Aset, Ubah/Hapus, & Generator Stiker QR (`detail_aset_screen.dart`):**

     * Menampilkan rincian lengkap aset (`nama`, `kategori`, `gedung`, `ruangan`, tanggal terdaftar), tombol **Ubah** (*bottom sheet* edit dengan validasi unik per ruangan) dan **Hapus** (dengan dialog konfirmasi) di AppBar.

     * **Generator & Label Stiker QR Code:** Payload QR Code men-encode **`ASSET:${asset.id}`** (Auto-ID dokumen Firestore) menggunakan `qr_flutter` dengan tombol **Simpan QR** (ke galeri perangkat) dan **Bagikan QR** (PNG resolusi tinggi). Tampilan stiker QR menampilkan teks label **`asset.nama`** (misalnya `Kursi#01` atau `AC Daikin 2 PK`) beserta lokasi (`Gedung - Ruangan`) di bawah kode QR—bukan Auto-ID mentah—sehingga apabila kamera perangkat tidak berfungsi, Pelapor tetap dapat membaca nama unit pada stiker dan memilihnya melalui jalur **Lapor Manual**.

4. **Kelola Teknisi (`kelola_teknisi_screen.dart`):**

   * Melihat daftar seluruh teknisi beserta **jumlah tiket aktif** (`assigned` + `inProgress`) yang sedang ditangani masing-masing teknisi sebagai acuan pembagian tugas.

   * **Mengaktifkan Akun Teknisi (`pelapor` $\rightarrow$ `teknisi`):** Admin dapat mengangkat pengguna terdaftar (yang masih berstatus `UserRole.pelapor`) menjadi `UserRole.teknisi` melalui **2 cara**:

     1. **Pencarian Email / Nama (Jarak Jauh):** Filter kandidat hanya untuk `role == pelapor`, serta wajib menampilkan **Email** secara jelas di bawah nama sebagai pembeda unik agar tidak tertukar jika terdapat nama yang sama.

     2. **Scan QR Profil Akun (Tatap Muka / Screenshot):** Memindai QR Code dari `ProfileScreen` pengguna yang berawalan `USER:<uid>` menggunakan `screens/shared/scan_qr_screen.dart` dalam mode pemindaian user.

     * *Dialog Konfirmasi Wajib:* Sebelum mengubah role, tampilkan dialog konfirmasi yang mencantumkan **Nama dan Email** lengkap pengguna tersebut.

   * **Cabut Akses / Kembalikan ke Pelapor (`teknisi` $\rightarrow$ `pelapor`):** Admin dapat mengembalikan role teknisi menjadi `pelapor` (sebagai pengaman jika salah pilih orang atau petugas tidak lagi bertugas), **dengan syarat jumlah tiket aktif (`assigned` + `inProgress`) milik teknisi tersebut adalah `0`**.

## 4. Alur Role: Teknisi (`screens/teknisi/`)

Aktor: Petugas Perbaikan Lapangan (Staf Internal Kampus).

### Alur Kerja Teknisi

1. **Navigasi Utama (`teknisi_main_screen.dart`) & Beranda Teknisi (`teknisi_home_screen.dart`):**

   * `TeknisiMainScreen` membungkus 4 halaman tab (`Beranda`, `Tugas`, `Notifikasi`, `Profil`) menggunakan `IndexedStack` dan 1 `BottomNavbar` permanen di bawah (dengan tombol tengah membuka `screens/shared/scan_qr_screen.dart` untuk memindai QR stiker fasilitas di lapangan dan langsung mengecek `HistoryAssetScreen`).

   * Di beranda, Teknisi melihat ringkasan jumlah tugas pribadi (*Baru Ditugaskan*, *Sedang Dikerjakan*, *Selesai*) serta daftar tugas aktif yang **diurutkan otomatis berdasarkan batas SLA terdekat / paling mendesak** (termasuk tiket *re-open* yang sudah melewati SLA awal).

2. **Daftar Tugas (`daftar_tugas_screen.dart`):**

   * Menampilkan seluruh laporan dengan `teknisiId == currentUser.uid` (baik yang memiliki `assetId` maupun yang `assetId == null`).

   * Mendukung filter berdasarkan **Status** (`assigned`, `inProgress`, `resolved`) dan **Gedung** (memudahkan teknisi mengerjakan beberapa tugas dalam satu gedung sekaligus).

3. **Eksekusi Perbaikan (`detail_laporan_screen.dart` & `form_penyelesaian_screen.dart`):**

   * **Jika status `assigned`:** Teknisi membuka detail tiket (dapat menekan **Lihat Riwayat Aset** untuk mengecek `HistoryAssetScreen`—baik untuk melihat riwayat servis unit terdaftar maupun keterangan bahwa fasilitas belum terdaftar di inventaris), lalu menekan tombol **Mulai Kerjakan** saat tiba di lokasi. Status berubah menjadi `inProgress` dan notifikasi terkirim ke Pelapor.

   * **Jika status `inProgress`:** Teknisi menekan tombol **Selesaikan Tugas** untuk membuka `FormPenyelesaianScreen`.

   * **Form Penyelesaian (`form_penyelesaian_screen.dart`):**

     * Teknisi wajib mengunggah foto hasil perbaikan (`fotoSesudah`) dan mengisi catatan tindakan perbaikan (`catatanTeknisi`).

     * Saat disimpan: status langsung berubah menjadi `resolved`, `resolvedAt` dicatat, dan sistem mengirim notifikasi ke Pelapor serta Admin. Jika Pelapor atau Admin mengajukan sanggahan (*Belum Beres*), tiket akan kembali muncul pada status `assigned` selama belum dialihkan Admin ke teknisi lain.

## 5. Catatan Teknis Penting (Wajib Diperhatikan Tim)

1. **Kompresi Foto & Batas 1 MB Dokumen Firestore:**

   * Karena penyimpanan foto menggunakan **string Base64 di dalam Firestore** (tanpa Firebase Storage), setiap foto **wajib dikompres** di `StorageService` (resolusi maksimal `800x800`, kualitas `~65%`) agar ukurannya berada di bawah **250 KB per foto**.

   * Satu dokumen `reports` menampung 2 foto (`fotoSebelum` dan `fotoSesudah`). Menjaga ukuran tiap foto di bawah 250 KB memastikan total dokumen tetap aman di bawah batas maksimal Firestore (1 MiB).

   * Untuk menampilkan gambar di UI, decode string Base64 menggunakan `StorageService.instance.base64ToBytes(base64String)`.

2. **Rumus Perhitungan SLA (`deadlineAt`) & Aturan *Re-open*:**

   * Dihitung otomatis saat Admin memverifikasi laporan berdasarkan prioritas yang dipilih (`ReportPriority.slaHours`):

     * **`tinggi`:** `verifiedAt + 24 jam`

     * **`sedang`:** `verifiedAt + 72 jam` (3 hari)

     * **`rendah`:** `verifiedAt + 168 jam` (7 hari)

   * `deadlineAt` bersifat tetap (*fixed timestamp*) dan **tidak di-reset** apabila tiket berstatus `resolved` dibuka kembali (*re-open*) menjadi `assigned` karena pekerjaan belum beres. Jika waktu saat *re-open* sudah melewati `deadlineAt`, maka `report.isOverdue` otomatis kembali bernilai `true`.

3. **Denormalisasi Data & Field `assetId` Nullable pada Koleksi `reports`:**

   * Saat membuat atau memperbarui tiket di `ReportService`, wajib ikut menyimpan `assetNama`, `assetLokasi`, `pelaporNama`, dan `teknisiNama` langsung di dokumen `reports`. Tujuannya agar halaman daftar tiket dapat menampilkan nama aset dan pelapor dalam satu kali *query* tanpa melakukan pembacaan ulang ke koleksi `assets` dan `users`.

   * Field `assetId` bersifat *nullable* (`String?`): terisi Auto-ID dokumen aset jika berasal dari Scan QR atau *dropdown* `assets`, dan bernilai `null` jika Pelapor memilih opsi *Fasilitas Lainnya / Tidak Terdaftar*.

4. **Normalisasi *Case-Insensitive* untuk `gedung` & `ruangan` (Tanpa Koleksi Baru):**

   * Data `gedung` dan `ruangan` tetap disimpan langsung di dalam dokumen koleksi `assets` tanpa membuat koleksi lokasi terpisah.

   * Baik saat penyimpanan di `AssetService` maupun saat ekstraksi daftar pilihan unik di UI (`kelola_aset_screen.dart`, `tambah_aset_screen.dart`, dan `form_pengaduan_screen.dart`), perbandingan nilai `gedung` dan pasangan `(gedung, ruangan)` wajib dilakukan secara ***case-insensitive*** (mengabaikan perbedaan huruf besar/kecil dan spasi berlebih) agar pilihan pengguna bebas dari duplikat.

5. **Pemicu Notifikasi (`NotificationModel`) & Audit `riwayatStatus`:**

   * Pembuatan dokumen notifikasi dan penambahan log `StatusHistoryItem` pada array `riwayatStatus` dilakukan langsung di dalam *method* `ReportService` setiap kali status laporan berubah maupun saat tindakan **Konfirmasi Selesai** (`isConfirmed = true`) dan **Belum Beres** (*re-open* ke `assigned`) dijalankan—tidak perlu memakai Cloud Functions.

6. **Gunakan Enum dari File Model (Jangan Hardcode String):**

   * `UserRole` (ada di `user_model.dart`): `UserRole.pelapor`, `UserRole.admin`, `UserRole.teknisi`

   * `ReportStatus` (ada di `report_model.dart`): `ReportStatus.reported`, `ReportStatus.verified`, `ReportStatus.assigned`, `ReportStatus.inProgress`, `ReportStatus.resolved`, `ReportStatus.rejected`

   * `ReportPriority` (ada di `report_model.dart`): `ReportPriority.tinggi`, `ReportPriority.sedang`, `ReportPriority.rendah`

   * *Tips UI:* Untuk menampilkan teks Bahasa Indonesia ke layar, langsung panggil `.label` (contoh: `report.status.label` otomatis menghasilkan `"Sedang Dikerjakan"`).

7. **ID Dokumen Firestore (`doc.id` Murni) & Standar Prefix QR Code:**

   * Koleksi `users` dan `assets` tidak menyimpan ulang field `uid`/`id` di dalam dokumen. Koleksi `users` wajib disimpan menggunakan `.doc(uid).set(...)`, sedangkan koleksi `assets` menggunakan **Auto-ID Firestore** (`.doc()` / `.add(...)`) sehingga Admin tidak perlu menginput kode ID custom.

   * **Standar Payload QR Code & Stiker:** Meskipun `doc.id` di Firestore disimpan murni tanpa awalan, teks di dalam QR Code wajib memakai awalan agar pemindai bisa memvalidasi tipe QR secara otomatis:

     * QR Fasilitas / Aset: payload **`ASSET:<asset.id>`** (Auto-ID Firestore), sementara teks label cetak pada stiker menampilkan **`asset.nama`** (misal `Kursi#01`) dan lokasi (`Gedung - Ruangan`).

     * QR Profil Pengguna: payload **`USER:<user.uid>`** (contoh: `USER:x9K2mP7qL1vB8nR4`).

8. **Aturan Batch Aset (`WriteBatch`), Pemisah `#`, dan `Max + 1` per Ruangan:**

   * Penambahan multi-item / massal di `AssetService` wajib dieksekusi dalam satu transaksi `WriteBatch` dengan total seluruh unit berada pada rentang **`1` hingga `500` dokumen** per submit.

   * Pemisah nomor urut batch (`#`) disematkan pada field **`nama`** (`<Nama Dasar>#01`), bukan pada `doc.id`. Karakter `#` hanya diizinkan pada input satuan (`Jumlah == 1` atau saat edit aset) untuk menyisipkan kembali nomor unit yang pernah terhapus di ruangan tersebut, dan **wajib ditolak** pada input massal (`Jumlah > 1`) agar sistem yang menghasilkan nomor urutnya secara otomatis.

   * Validasi keunikan `nama` bersifat *case-insensitive* per pasangan **`(gedung, ruangan)`** (nama yang sama diizinkan jika gedung atau ruangannya berbeda), dan penomoran lanjutan batch berikutnya wajib dihitung dari **angka akhiran tertinggi (`Max + 1`)** pada kombinasi `(gedung, ruangan)` tersebut.

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

* [ ] Buat `constants/app_colors.dart` & `constants/app_constants.dart` (konstanta warna & teks umum)

* [x] Buat `models/user_model.dart`

* [x] Buat `models/asset_model.dart`

* [x] Buat `models/report_model.dart`

* [x] Buat `models/notification_model.dart`

* [x] Isi data sampel awal di Firebase Console (akun uji untuk `pelapor`, `admin`, `teknisi`, serta dummy `assets` & `reports`)

### Jalur A — Layanan Backend (`services/`)

* [x] `services/auth_service.dart` (Login, Register, Google Sign-In, verifikasi email, reset password, & kelola role)

* [x] `services/storage_service.dart` (Ambil gambar, kompres < 250 KB, & encode/decode Base64)

* [x] `services/asset_service.dart` (CRUD & batch multi-aset `#` per ruangan dengan `Max + 1`, validasi unik `(gedung, ruangan, nama)`, & lookup ID QR)

* [x] `services/notification_service.dart` (Stream notifikasi real-time, hitung belum dibaca, & tandai sudah dibaca)

* [x] `services/report_service.dart` (CRUD laporan, transisi status, hitung SLA, konfirmasi/`re-open`, & pemicu notifikasi)

### Jalur B — Komponen UI Reusable (`widgets/`)

*Dapat dikerjakan sepenuhnya secara paralel tanpa menunggu koneksi Firebase.*

* [x] `widgets/bottom_navbar.dart` (Navigasi bawah reusable lintas role dengan tombol aksi tengah)

* [ ] `widgets/status_badge.dart` (Label warna otomatis per status tiket)

* [ ] `widgets/sla_indicator.dart` (Indikator sisa waktu / label *Overdue* berdasarkan `deadlineAt`)

* [ ] `widgets/report_card.dart` (Kartu ringkasan laporan untuk daftar di seluruh role)

* [ ] `widgets/base64_image_viewer.dart` (Komponen render gambar dari string Base64 + tampilan saat error/kosong)

### Jalur C — Modul Autentikasi & Lintas Role (`screens/auth/` & `screens/shared/`)

* [x] `screens/auth/login_screen.dart` (termasuk pop-up Lupa Kata Sandi) & `register_screen.dart`

* [x] `screens/auth/email_verification_screen.dart` (Halaman tunggu verifikasi email & kirim ulang tautan)

* [x] `screens/auth/auth_wrapper.dart` (*Auto-routing* sesuai verifikasi email & `user.role`)

* [ ] `screens/shared/scan_qr_screen.dart` (Pemindai kamera QR lintas role & validasi prefix `ASSET:` / `USER:`)

* [ ] `screens/shared/detail_laporan_screen.dart` (Detail tiket + tombol aksi kondisional per kombinasi role & status, termasuk konfirmasi & *re-open*)

* [ ] `screens/shared/history_asset_screen.dart` (Info aset terdaftar & riwayat kerusakan non-`rejected`, atau tampilan fasilitas belum terdaftar + opsi daftar aset baru untuk Admin)

* [ ] `screens/shared/notification_screen.dart` (Daftar notifikasi *real-time* & tandai sudah dibaca)

* [ ] `screens/shared/profile_screen.dart` (Info profil, edit nama & foto, QR Code profil `USER:<uid>`, & logout)

### Jalur D — Modul Pelapor (`screens/pelapor/`)

* [ ] `screens/pelapor/pelapor_main_screen.dart` (*Shell* utama dengan `IndexedStack` & `BottomNavbar` untuk tab Pelapor)

* [ ] `screens/pelapor/pelapor_home_screen.dart` (Ringkasan status pribadi, laporan kampus terkini, & tombol QR/Manual)

* [ ] `screens/pelapor/form_pengaduan_screen.dart` (Form dual-mode: otomatis dari QR, pilihan berjenjang manual + pencarian, & opsi *Fasilitas Lainnya* dengan `assetId: null`)

* [ ] `screens/pelapor/history_laporan_screen.dart` (Daftar riwayat laporan pelapor + filter status)

### Jalur E — Modul Admin (`screens/admin/`)

* [ ] `screens/admin/admin_main_screen.dart` (*Shell* utama dengan `IndexedStack` & `BottomNavbar` untuk tab Admin)

* [ ] `screens/admin/admin_dashboard_screen.dart` (Statistik tiket & daftar peringatan *Overdue SLA*)

* [ ] `screens/admin/kelola_laporan_screen.dart` (Filter semua laporan & modal verifikasi/tolak/tugaskan teknisi)

* [x] `screens/admin/kelola_aset_screen.dart` (Daftar master aset, filter berjenjang Gedung/Ruangan/Kategori, & pintasan QR)

* [x] `screens/admin/tambah_aset_screen.dart` (Form tambah aset satuan & batch multi-item `#` per ruangan dengan `Autocomplete` lokasi)

* [x] `screens/admin/detail_aset_screen.dart` (Detail aset, edit/hapus data, & simpan/bagikan stiker QR Code `ASSET:<id>` berlabel `asset.nama`)

* [ ] `screens/admin/kelola_teknisi_screen.dart` (Daftar teknisi, beban tugas aktif, & ubah role `pelapor` $\leftrightarrow$ `teknisi` via Search Email/Nama atau Scan QR Profil)

### Jalur F — Modul Teknisi (`screens/teknisi/`)

* [ ] `screens/teknisi/teknisi_main_screen.dart` (*Shell* utama dengan `IndexedStack` & `BottomNavbar` untuk tab Teknisi)

* [ ] `screens/teknisi/teknisi_home_screen.dart` (Ringkasan tugas pribadi & daftar urut batas SLA terdekat)

* [ ] `screens/teknisi/daftar_tugas_screen.dart` (Daftar tugas teknisi + filter status & gedung)

* [ ] `screens/teknisi/form_penyelesaian_screen.dart` (Form unggah foto sesudah perbaikan & catatan tindakan)