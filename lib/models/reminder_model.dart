import '../services/task_priority_service.dart';

class Pengingat {
  final int? id;
  final int idPengguna;
  final String judul;
  final String deskripsi;
  final DateTime waktu;
  final DateTime? deadline;
  final String kategori;
  final String? lokasi;
  final bool sudahSelesai;
  final int priorityScore;
  final String priorityLabel;

  factory Pengingat({
    int? id,
    required int idPengguna,
    required String judul,
    required String deskripsi,
    required DateTime waktu,
    DateTime? deadline,
    String kategori = 'Umum',
    String? lokasi,
    bool sudahSelesai = false,
    int? priorityScore,
    String? priorityLabel,
  }) {
    final priority = (priorityScore == null || priorityLabel == null)
        ? TaskPriorityService.analyze(
            title: judul,
            description: deskripsi,
            category: kategori,
            deadline: deadline,
          )
        : null;

    return Pengingat._internal(
      id: id,
      idPengguna: idPengguna,
      judul: judul,
      deskripsi: deskripsi,
      waktu: waktu,
      deadline: deadline,
      kategori: kategori,
      lokasi: lokasi,
      sudahSelesai: sudahSelesai,
      priorityScore: priorityScore ?? priority!.score,
      priorityLabel: priorityLabel ?? priority!.label,
    );
  }

  const Pengingat._internal({
    this.id,
    required this.idPengguna,
    required this.judul,
    required this.deskripsi,
    required this.waktu,
    this.deadline,
    required this.kategori,
    this.lokasi,
    required this.sudahSelesai,
    required this.priorityScore,
    required this.priorityLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': idPengguna,
      'title': judul,
      'description': deskripsi,
      'dateTime': waktu.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'category': kategori,
      'location': lokasi,
      'isCompleted': sudahSelesai ? 1 : 0,
      'priorityScore': priorityScore,
      'priorityLabel': priorityLabel,
    };
  }

  factory Pengingat.fromMap(Map<String, dynamic> map) {
    final kategori = (map['category'] as String?) ?? 'Umum';
    final computedPriority = TaskPriorityService.analyze(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: kategori,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    );

    return Pengingat(
      id: map['id'],
      idPengguna: map['userId'],
      judul: map['title'],
      deskripsi: map['description'],
      waktu: DateTime.parse(map['dateTime']),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      kategori: kategori,
      lokasi: map['location'],
      sudahSelesai: map['isCompleted'] == 1,
      priorityScore: map['priorityScore'] ?? computedPriority.score,
      priorityLabel: map['priorityLabel'] ?? computedPriority.label,
    );
  }
}
