import 'package:cloud_firestore/cloud_firestore.dart';

class AssetModel {
  final String id;
  final String nama;
  final String kategori;
  final String gedung;
  final String ruangan;
  final DateTime createdAt;

  const AssetModel({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.gedung,
    required this.ruangan,
    required this.createdAt,
  });

  String get lokasiLengkap => '$gedung - $ruangan';

  factory AssetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AssetModel(
      id: doc.id,
      nama: data['nama'] as String? ?? '',
      kategori: data['kategori'] as String? ?? 'Umum',
      gedung: data['gedung'] as String? ?? '',
      ruangan: data['ruangan'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kategori': kategori,
      'gedung': gedung,
      'ruangan': ruangan,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AssetModel copyWith({
    String? id,
    String? nama,
    String? kategori,
    String? gedung,
    String? ruangan,
    DateTime? createdAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      gedung: gedung ?? this.gedung,
      ruangan: ruangan ?? this.ruangan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}