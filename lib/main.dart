import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/pelapor/pelapor_main_screen.dart';
import 'screens/pelapor/history_laporan_screen.dart';
import 'screens/teknisi/teknisi_main_screen.dart';
import 'screens/shared/notification_screen.dart';
import 'services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/firestore_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService.instance.initialize();
  await FirestoreSeeder.seedAll();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelaporan Fasilitas Kampus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/admin-main': (context) => const AdminMainScreen(),
        '/admin-dashboard': (context) => const AdminMainScreen(),
        '/pelapor-main': (context) => const PelaporMainScreen(),
        '/teknisi-main': (context) => const TeknisiMainScreen(),
        '/riwayat-laporan': (context) => const RiwayatLaporanPage(),
        '/notifikasi': (context) => const NotificationScreen(),
      },
    );
  }
}