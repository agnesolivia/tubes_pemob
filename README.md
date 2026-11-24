# Pelaporan Kerusakan Fasilitas Kampus

Proyek aplikasi mobile berbasis Flutter untuk pelaporan dan pemantauan perbaikan kerusakan fasilitas di lingkungan kampus (mendukung 3 *role*: **Pelapor**, **Admin**, dan **Teknisi**).

## Kelompok 1

| No. | Nama                      | NIM       |
| --- | ------------------------- | --------- |
| 1   | Agnes Olivia Ketaren      | 241402066 |
| 2   | Rahma Sarita Nasution     | 241402043 |
| 3   | Ahmad Arif Fatahillah     | 241402036 |
| 4   | Richard Lim               | 241402073 |
| 5   | Bryan Sullivan Nauli      | 241402108 |
| 6   | Rohaya Hasibuan           | 241402030 |

## Topik

Pelaporan Kerusakan Fasilitas Kampus

## Deskripsi

Aplikasi ini dirancang untuk membantu sivitas akademika melaporkan kerusakan fasilitas kampus (baik melalui pemindaian QR Code ruangan/aset maupun input manual) agar laporan dapat diverifikasi oleh Admin, ditugaskan kepada Teknisi sesuai target SLA, serta dipantau hingga selesai diperbaiki.

## Teknologi

* **Framework:** Flutter & Dart
* **Backend & Database:** Firebase Authentication (Email & Google Sign-In) & Cloud Firestore
* **Media & Utilitas:** Image Picker, Flutter Image Compress (Base64 Storage), Mobile Scanner, QR Flutter, Intl

## 📚 Dokumentasi Teknis Tim

Sebelum mulai mengerjakan fitur, seluruh anggota tim wajib membaca dua panduan berikut:
* **[Struktur Folder & Aturan Kode (`FOLDER_STRUCTURE.md`)](./FOLDER_STRUCTURE.md)** — Penjelasan fungsi tiap folder, skema koleksi Firestore, dan aturan penamaan file.
* **[Detail Alur Fitur & Checklist Tim (`ROLE_WORKFLOWS.md`)](./ROLE_WORKFLOWS.md)** — Rincian fungsionalitas per *role*, siklus status tiket (`reported` hingga `resolved`), serta pembagian tugas paralel.

## 📁 Struktur Proyek (`lib/`)

Proyek ini menggunakan pola **Layer-First** dengan pemisahan halaman berdasarkan *role* pengguna di dalam folder `screens/`:

```text
lib/
├── main.dart               # Entry point aplikasi & inisialisasi Firebase
├── constants/              # Nilai tetap (palet warna, tema, ukuran, teks konstan)
├── models/                 # Blueprint data & konversi Firestore (User, Asset, Report, Notification)
├── services/               # Logika backend (Auth, Firestore CRUD/Stream, Kompresi Foto Base64)
├── widgets/                # Komponen UI reusable yang dipakai di banyak halaman
└── screens/                # Seluruh halaman aplikasi (Scaffold)
    ├── auth/               # Halaman sebelum login (Splash, Login, Register, AuthWrapper)
    ├── shared/             # Halaman lintas role (Detail Laporan, History Aset, Profil, Notifikasi)
    ├── pelapor/            # Halaman khusus pelapor (Beranda, Scan QR, Form Pengaduan, Riwayat)
    ├── admin/              # Halaman khusus pengelola (Dashboard SLA, Kelola Laporan, Aset & QR, Teknisi)
    └── teknisi/            # Halaman khusus petugas lapangan (Beranda, Daftar Tugas, Selesaikan Tugas)
