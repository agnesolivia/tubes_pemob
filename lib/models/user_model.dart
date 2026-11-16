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
  final String nomorInduk;
  final UserRole role;
  final bool isAvailable;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nomorInduk,
    this.role = UserRole.pelapor,
    this.isAvailable = true,
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
      nomorInduk: data['nomorInduk'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      isAvailable: data['isAvailable'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'nomorInduk': nomorInduk,
      'role': role.value,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? nomorInduk,
    UserRole? role,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nomorInduk: nomorInduk ?? this.nomorInduk,
      role: role ?? this.role,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}