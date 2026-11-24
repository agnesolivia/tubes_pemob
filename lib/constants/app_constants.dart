class AppConstants {
  AppConstants._();

  static const String usersCollection = 'users';
  static const String assetsCollection = 'assets';
  static const String reportsCollection = 'reports';
  static const String notificationsCollection = 'notifications';

  // Web Client ID (client_type: 3 dari android/app/google-services.json)
  static const String googleWebClientId =
      '105927844526-cprccaqbkp79es928p01a7csakohr4qo.apps.googleusercontent.com';

  static const List<String> defaultAssetCategories = [
    'AC & Pendingin',
    'Kelistrikan & Lampu',
    'Proyektor & Audio',
    'Meja & Kursi',
    'Sanitasi & Air',
    'Jaringan & IT',
    'Lainnya',
  ];

  static const String appName = 'SnaFix';
  static const String appTagline = 'Snap it. Fix it.';
}