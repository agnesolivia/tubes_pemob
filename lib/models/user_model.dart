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

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    this.role = UserRole.pelapor,
    required this.createdAt,
  });

  bool get isPelapor => role == UserRole.pelapor;
  bool get isAdmin => role == UserRole.admin;
  bool get isTeknisi => role == UserRole.teknisi;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      nama: data['nama'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}