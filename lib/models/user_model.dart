import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  pelapor('pelapor', 'Pelapor'),
  admin('admin', 'Admin'),
  teknisi('teknisi', 'Teknisi');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String? val) {
    return UserRole.values.firstWhere(
      (e) => e.value == val,
      orElse: () => UserRole.pelapor,
    );
  }
}

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? photoBase64;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    this.role = UserRole.pelapor,
    required this.createdAt,
    this.photoBase64,
    this.photoUrl,
  });

  bool get isPelapor => role == UserRole.pelapor;
  bool get isAdmin => role == UserRole.admin;
  bool get isTeknisi => role == UserRole.teknisi;

  /// Versi lowercase dari nama untuk mendukung pencarian prefix di Firestore.
  String get nameLower => nama.trim().toLowerCase();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawBase64 = (data['photoBase64'] as String?)?.trim();
    final rawUrl = (data['photoUrl'] as String?)?.trim();

    return UserModel(
      uid: doc.id,
      nama: data['nama'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoBase64: (rawBase64 != null && rawBase64.isNotEmpty)
          ? rawBase64
          : null,
      photoUrl: (rawUrl != null && rawUrl.isNotEmpty) ? rawUrl : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama.trim(),
      'nameLower': nameLower,
      'email': email.trim().toLowerCase(),
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
      if (photoBase64 != null && photoBase64!.isNotEmpty)
        'photoBase64': photoBase64,
      if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? photoBase64,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      photoBase64: photoBase64 ?? this.photoBase64,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
