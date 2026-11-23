import 'package:flutter/material.dart';
import 'package:tubes_pemob/constants/app_colors.dart';
import 'package:tubes_pemob/services/auth_service.dart';

class TeknisiHomeScreen extends StatelessWidget {
  const TeknisiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Teknisi'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handyman_rounded,
                size: 56, color: AppColors.primaryBlue),
            const SizedBox(height: 12),
            const Text('Login Teknisi Berhasil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(email, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}