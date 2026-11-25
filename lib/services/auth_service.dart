import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  bool _isInitialized = false;

  /// Stream perubahan login/logout Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream perubahan status user termasuk saat user.reload() memperbarui emailVerified
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: kIsWeb ? null : AppConstants.googleWebClientId,
    );
    _isInitialized = true;
  }

  /// Login dengan Email & Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registrasi akun baru (Email & Password) + simpan profil ke Firestore + kirim email verifikasi
  Future<UserModel> registerWithEmail({
    required String nama,
    required String email,
    required String password,
    UserRole role = UserRole.pelapor,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(nama.trim());

    final newUser = UserModel(
      uid: user.uid,
      nama: nama.trim(),
      email: email.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    await _usersRef.doc(user.uid).set(newUser.toMap());

    // Bungkus try-catch agar jika kirim email awal gagal sementara,
    // akun tetap tercatat dan user bisa menekan "Kirim ulang" di layar verifikasi.
    try {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (_) {
      // Diabaikan di tahap registrasi; ditangani ulang di EmailVerificationScreen
    }

    return newUser;
  }

  /// Kirim ulang email verifikasi untuk akun Email/Password
  Future<void> sendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Muat ulang status user dari server Firebase & cek apakah email sudah diverifikasi
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  /// Login dengan Google + otomatis buat dokumen user jika pertama kali masuk
  Future<UserCredential?> signInWithGoogle() async {
    await initialize();

    try {
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Token autentikasi Google tidak ditemukan. Periksa SHA-1 dan Web Client ID di Firebase.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final docRef = _usersRef.doc(firebaseUser.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          final fallbackName = (firebaseUser.displayName != null &&
                  firebaseUser.displayName!.trim().isNotEmpty)
              ? firebaseUser.displayName!.trim()
              : (firebaseUser.email?.split('@').first ?? 'Pengguna Kampus');

          final newUser = UserModel(
            uid: firebaseUser.uid,
            nama: fallbackName,
            email: firebaseUser.email ?? '',
            role: UserRole.pelapor,
            createdAt: DateTime.now(),
          );

          await docRef.set(newUser.toMap());
        }
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Ambil data profil UserModel sekali baca
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream real-time profil UserModel (untuk AuthWrapper & ProfileScreen)
  Stream<UserModel?> streamUserData(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Update nama tampilan di halaman Profil
  Future<void> updateProfile({
    required String uid,
    required String nama,
  }) async {
    await _usersRef.doc(uid).update({
      'nama': nama.trim(),
    });
    await _firebaseAuth.currentUser?.updateDisplayName(nama.trim());
  }

  /// Simpan atau hapus foto profil Base64 di Firestore `users/{uid}`
  Future<void> updateProfilePhoto({
    required String uid,
    String? photoBase64,
  }) async {
    if (photoBase64 == null || photoBase64.isEmpty) {
      await _usersRef.doc(uid).update({
        'photoBase64': FieldValue.delete(),
      });
      try {
        await _firebaseAuth.currentUser?.updatePhotoURL(null);
      } catch (_) {}
    } else {
      await _usersRef.doc(uid).update({
        'photoBase64': photoBase64,
      });
    }
  }

  /// Stream seluruh pengguna terdaftar (untuk Admin mencari calon teknisi)
  Stream<List<UserModel>> streamAllUsers() {
    return _usersRef.snapshots().map((snapshot) {
      final users =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      users.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      return users;
    });
  }

  /// Stream daftar seluruh Teknisi (untuk Admin saat menugaskan tiket)
  Stream<List<UserModel>> streamTechnicians() {
    return _usersRef
        .where('role', isEqualTo: UserRole.teknisi.value)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Ubah role pengguna (misal: Admin mengangkat pelapor menjadi teknisi)
  Future<void> updateUserRole({
    required String uid,
    required UserRole newRole,
  }) async {
    await _usersRef.doc(uid).update({
      'role': newRole.value,
    });
  }

  /// Kirim email reset kata sandi
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Logout dari Google & Firebase Auth
  Future<void> signOut() async {
    await initialize();
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}