import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class FirestoreSeeder {
  // Gambar PNG 1x1 piksel valid dalam Base64 agar Base64ImageViewer tidak error
  static const String _dummyBase64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  /// Jalankan sekali untuk membuat 3 akun uji (.pelapor, .admin, .teknisi),
  /// 4 master aset, dan 4 tiket laporan dengan variasi status.
  ///
  /// Contoh: baseEmail = 'richard@gmail.com' akan membuat:
  /// - richard.pelapor@gmail.com
  /// - richard.admin@gmail.com
  /// - richard.teknisi@gmail.com
  static Future<void> seedAll({
    required String baseEmail,
    String password = 'Password123!',
  }) async {
    final parts = baseEmail.trim().split('@');
    if (parts.length != 2) {
      throw ArgumentError(
        'Format baseEmail tidak valid. Contoh: tes@gmail.com',
      );
    }

    final prefix = parts[0];
    final domain = parts[1];

    final pelaporEmail = '$prefix.pelapor@$domain';
    final adminEmail = '$prefix.admin@$domain';
    final teknisiEmail = '$prefix.teknisi@$domain';

    // 1. Buat / ambil 3 akun uji di Firebase Auth & Firestore users
    final pelapor = await _ensureUser(
      email: pelaporEmail,
      password: password,
      nama: 'Budi Pelapor',
      role: UserRole.pelapor,
    );

    final teknisi = await _ensureUser(
      email: teknisiEmail,
      password: password,
      nama: 'Andi Teknisi',
      role: UserRole.teknisi,
    );

    // Akun admin dibuat terakhir agar sesi aktif saat menulis koleksi assets adalah admin
    await _ensureUser(
      email: adminEmail,
      password: password,
      nama: 'Admin Sarpras',
      role: UserRole.admin,
    );

    final db = FirebaseFirestore.instance;

    // 2. Cek apakah koleksi assets sudah terisi agar tidak duplikat
    final existingAssets = await db.collection('assets').limit(1).get();
    if (existingAssets.docs.isEmpty) {
      final now = DateTime.now();
      final batch = db.batch();

      final assets = [
        AssetModel(
          id: 'AC-R204',
          nama: 'AC Daikin 2 PK',
          kategori: 'Elektronik',
          gedung: 'Gedung A',
          ruangan: 'Ruang 204',
          createdAt: now,
        ),
        AssetModel(
          id: 'PROY-LAB1',
          nama: 'Proyektor Epson EB-X500',
          kategori: 'Elektronik',
          gedung: 'Gedung B',
          ruangan: 'Lab Komputer 1',
          createdAt: now,
        ),
        AssetModel(
          id: 'KRAN-WC1',
          nama: 'Kran Wastafel Lantai 1',
          kategori: 'Sanitasi',
          gedung: 'Gedung A',
          ruangan: 'Toilet Lt. 1',
          createdAt: now,
        ),
        AssetModel(
          id: 'KURSI-C302',
          nama: 'Kursi Kuliah Lipat (Baris Depan)',
          kategori: 'Inventaris',
          gedung: 'Gedung C',
          ruangan: 'Ruang 302',
          createdAt: now,
        ),
      ];

      for (final asset in assets) {
        batch.set(db.collection('assets').doc(asset.id), asset.toMap());
      }

      // 3. Seed 4 tiket laporan dengan variasi status
      final reports = [
        // Status: reported (untuk tes Verifikasi / Tolak oleh Admin)
        ReportModel(
          id: '',
          assetId: 'KRAN-WC1',
          assetNama: 'Kran Wastafel Lantai 1',
          assetLokasi: 'Gedung A - Toilet Lt. 1',
          pelaporId: pelapor.uid,
          pelaporNama: pelapor.nama,
          deskripsi: 'Kran air patah dan air terus mengalir deras.',
          fotoSebelum: _dummyBase64Image,
          status: ReportStatus.reported,
          createdAt: now.subtract(const Duration(hours: 2)),
          riwayatStatus: [
            StatusHistoryItem(
              status: ReportStatus.reported,
              catatan: 'Laporan kerusakan dikirim oleh pelapor.',
              updatedBy: pelapor.nama,
              timestamp: now.subtract(const Duration(hours: 2)),
            ),
          ],
        ),

        // Status: assigned (untuk tes Mulai Kerjakan oleh Teknisi)
        ReportModel(
          id: '',
          assetId: 'AC-R204',
          assetNama: 'AC Daikin 2 PK',
          assetLokasi: 'Gedung A - Ruang 204',
          pelaporId: pelapor.uid,
          pelaporNama: pelapor.nama,
          teknisiId: teknisi.uid,
          teknisiNama: teknisi.nama,
          deskripsi: 'AC tidak dingin sama sekali dan lampu timer berkedip.',
          fotoSebelum: _dummyBase64Image,
          status: ReportStatus.assigned,
          prioritas: ReportPriority.tinggi,
          deadlineAt: now.add(const Duration(hours: 18)),
          createdAt: now.subtract(const Duration(hours: 6)),
          riwayatStatus: [
            StatusHistoryItem(
              status: ReportStatus.reported,
              catatan: 'Laporan kerusakan dikirim oleh pelapor.',
              updatedBy: pelapor.nama,
              timestamp: now.subtract(const Duration(hours: 6)),
            ),
            StatusHistoryItem(
              status: ReportStatus.assigned,
              catatan:
                  'Diverifikasi (Prioritas Tinggi) & ditugaskan ke ${teknisi.nama}.',
              updatedBy: 'Admin Sarpras',
              timestamp: now.subtract(const Duration(hours: 5)),
            ),
          ],
        ),

        // Status: in progress & OVERDUE SLA (untuk tes peringatan Overdue + Selesaikan Tugas)
        ReportModel(
          id: '',
          assetId: 'PROY-LAB1',
          assetNama: 'Proyektor Epson EB-X500',
          assetLokasi: 'Gedung B - Lab Komputer 1',
          pelaporId: pelapor.uid,
          pelaporNama: pelapor.nama,
          teknisiId: teknisi.uid,
          teknisiNama: teknisi.nama,
          deskripsi:
              'Tampilan proyektor buram kekuningan dan mati sendiri setelah 10 menit.',
          fotoSebelum: _dummyBase64Image,
          status: ReportStatus.inProgress,
          prioritas: ReportPriority.tinggi,
          deadlineAt: now.subtract(const Duration(hours: 3)),
          createdAt: now.subtract(const Duration(hours: 28)),
          riwayatStatus: [
            StatusHistoryItem(
              status: ReportStatus.reported,
              catatan: 'Laporan kerusakan dikirim oleh pelapor.',
              updatedBy: pelapor.nama,
              timestamp: now.subtract(const Duration(hours: 28)),
            ),
            StatusHistoryItem(
              status: ReportStatus.inProgress,
              catatan: 'Teknisi mulai mengerjakan perbaikan di lokasi.',
              updatedBy: teknisi.nama,
              timestamp: now.subtract(const Duration(hours: 20)),
            ),
          ],
        ),

        // Status: resolved (untuk tes Konfirmasi Selesai oleh Pelapor)
        ReportModel(
          id: '',
          assetId: 'KURSI-C302',
          assetNama: 'Kursi Kuliah Lipat (Baris Depan)',
          assetLokasi: 'Gedung C - Ruang 302',
          pelaporId: pelapor.uid,
          pelaporNama: pelapor.nama,
          teknisiId: teknisi.uid,
          teknisiNama: teknisi.nama,
          deskripsi: 'Meja lipat pada 2 kursi di baris depan lepas bautnya.',
          fotoSebelum: _dummyBase64Image,
          fotoSesudah: _dummyBase64Image,
          catatanTeknisi:
              'Baut engsel meja sudah diganti baru dan dikencangkan.',
          status: ReportStatus.resolved,
          prioritas: ReportPriority.rendah,
          deadlineAt: now.add(const Duration(days: 4)),
          createdAt: now.subtract(const Duration(days: 2)),
          resolvedAt: now.subtract(const Duration(hours: 4)),
          riwayatStatus: [
            StatusHistoryItem(
              status: ReportStatus.resolved,
              catatan:
                  'Perbaikan selesai: Baut engsel meja sudah diganti baru dan dikencangkan.',
              updatedBy: teknisi.nama,
              timestamp: now.subtract(const Duration(hours: 4)),
            ),
          ],
        ),
      ];

      for (final report in reports) {
        batch.set(db.collection('reports').doc(), report.toMap());
      }

      await batch.commit();
    }

    // Logout setelah seeding selesai agar aplikasi mulai dari layar Login
    await FirebaseAuth.instance.signOut();
    debugPrint(
      'SEEDER SELESAI! Cek inbox $baseEmail untuk klik 3 link verifikasi.',
    );
  }

  static Future<UserModel> _ensureUser({
    required String email,
    required String password,
    required String nama,
    required UserRole role,
  }) async {
    final auth = FirebaseAuth.instance;
    final usersRef = FirebaseFirestore.instance.collection('users');

    User firebaseUser;
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(nama);
      await firebaseUser.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final credential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = credential.user!;
      } else {
        rethrow;
      }
    }

    final userModel = UserModel(
      uid: firebaseUser.uid,
      nama: nama,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    await usersRef.doc(firebaseUser.uid).set(
          userModel.toMap(),
          SetOptions(merge: true),
        );

    return userModel;
  }
}