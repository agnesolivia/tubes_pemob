import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/models/user_model.dart';
import 'package:tubes_pemob/screens/admin/admin_main_screen.dart';
import 'package:tubes_pemob/screens/auth/email_verification_screen.dart';
import 'package:tubes_pemob/screens/auth/login_screen.dart';
import 'package:tubes_pemob/screens/pelapor/pelapor_main_screen.dart';
import 'package:tubes_pemob/screens/teknisi/teknisi_main_screen.dart';
import 'package:tubes_pemob/services/auth_service.dart';
import 'package:tubes_pemob/services/notification_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _cachedUid;
  Stream<UserModel?>? _userStream;

  @override
  void dispose() {
    NotificationService.instance.stopForegroundListener();
    super.dispose();
  }

  Stream<UserModel?> _getUserStream(String uid) {
    if (_cachedUid != uid || _userStream == null) {
      _cachedUid = uid;
      _userStream = AuthService.instance.streamUserData(uid);
    }
    return _userStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges() ikut terpanggil saat user.reload() mendeteksi emailVerified == true
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            !authSnapshot.hasData) {
          return const _AuthLoadingScreen();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          _cachedUid = null;
          _userStream = null;
          NotificationService.instance.stopForegroundListener();
          return const LoginScreen();
        }

        // Gerbang wajib verifikasi email sebelum masuk ke halaman utama
        if (!firebaseUser.emailVerified) {
          NotificationService.instance.stopForegroundListener();
          return EmailVerificationScreen(
            onVerified: () {
              if (mounted) setState(() {});
            },
          );
        }

        return StreamBuilder<UserModel?>(
          stream: _getUserStream(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting &&
                !userSnapshot.hasData) {
              return const _AuthLoadingScreen();
            }

            if (userSnapshot.hasError) {
              return _AuthErrorScreen(
                message: 'Gagal memuat profil pengguna: ${userSnapshot.error}',
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const _AuthLoadingScreen(
                message: 'Menyiapkan profil akun...',
              );
            }

            // Aktifkan listener banner notifikasi foreground sesuai akun & role aktif
            NotificationService.instance.startForegroundListener(
              uid: user.uid,
              userRole: user.role,
            );

            if (user.isAdmin) {
              return const AdminMainScreen();
            }
            if (user.isTeknisi) {
              return TeknisiMainScreen(
                currentUserUid: user.uid,
                technicianName: user.nama,
              );
            }
            return const PelaporMainScreen();
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  final String? message;

  const _AuthLoadingScreen({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String message;

  const _AuthErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.statusRejectedText,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => AuthService.instance.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Kembali ke Halaman Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
