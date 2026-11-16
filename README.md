# Pelaporan Kerusakan Fasilitas Kampus

Proyek aplikasi mobile berbasis Flutter untuk pelaporan kerusakan fasilitas di lingkungan kampus.

## Kelompok 1

| No. | Nama                      | NIM       |
| --- | ------------------------- | --------- |
| 1   | Agnes Olivia Ketaren      | 241402066 |
| 2   | Rahma Sarita Nasution     | 241402043 |
| 3   | Ahmad Arif Fatahillah     | 241402036 |
| 4   | Richard Lim               | 241402073 |
| 5   | Bryan Sullivan Nauli      | 241402108 |


## Topik

Pelaporan Kerusakan Fasilitas Kampus

## Deskripsi

Aplikasi ini dirancang untuk membantu pengguna melaporkan fasilitas kampus yang rusak agar laporan dapat dicatat dan ditindaklanjuti. Proyek ini masih dalam tahap pengembangan.

## Teknologi

* Flutter
* Dart

## 📁 Struktur Proyek (`lib/`)

Proyek ini menggunakan pola **Layer-First** dengan pemisahan halaman berdasarkan *role* pengguna di dalam folder `screens/`:

```text
lib/
├── main.dart               # Entry point aplikasi & inisialisasi Firebase
├── constants/              # Nilai tetap (palet warna, tema, ukuran, teks konstan)
├── models/                 # Blueprint data & konversi dari/ke Firestore (UserModel, LaporanModel)
├── services/               # Logika backend (Firebase Auth, Cloud Firestore, Firebase Storage)
├── widgets/                # Komponen UI reusable yang dipakai di banyak halaman
└── screens/                # Seluruh halaman aplikasi (Scaffold)
    ├── auth/               # Halaman sebelum login (Splash, Login, Register, AuthWrapper)
    ├── shared/             # Halaman lintas role (Detail Laporan, Profil, Notifikasi)
    ├── pelapor/            # Halaman khusus pelapor (Beranda, Buat Laporan, Riwayat)
    ├── admin/              # Halaman khusus pengelola (Dashboard, Validasi Laporan, Kelola Teknisi)
    └── teknisi/            # Halaman khusus petugas lapangan (Daftar Tugas, Update Perbaikan)
```