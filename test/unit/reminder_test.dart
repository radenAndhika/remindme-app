import 'package:flutter_test/flutter_test.dart';
import 'package:remindme/models/reminder_model.dart';

void main() {
  group('Pengingat Model Tests', () {
    test('Should convert to Map correctly', () {
      final waktu = DateTime.now();
      final deadline = waktu.add(const Duration(days: 5));
      
      final pengingat = Pengingat(
        id: 1,
        idPengguna: 10,
        judul: 'Belajar TDD',
        deskripsi: 'Menulis unit test untuk Flutter',
        waktu: waktu,
        deadline: deadline,
        kategori: 'Revisi/Laporan',
        lokasi: 'Yogyakarta',
        sudahSelesai: false,
      );

      final map = pengingat.toMap();

      expect(map['id'], 1);
      expect(map['userId'], 10);
      expect(map['title'], 'Belajar TDD');
      expect(map['dateTime'], waktu.toIso8601String());
      expect(map['deadline'], deadline.toIso8601String());
      expect(map['category'], 'Revisi/Laporan');
      expect(map['priorityScore'], isA<int>());
      expect(map['priorityLabel'], isA<String>());
      expect(map['isCompleted'], 0);
    });

    test('Should create from Map correctly', () {
      final waktuStr = DateTime.now().toIso8601String();
      final deadlineStr = DateTime.now().add(const Duration(days: 2)).toIso8601String();
      
      final map = {
        'id': 2,
        'userId': 20,
        'title': 'Test From Map',
        'description': 'Testing factory method',
        'dateTime': waktuStr,
        'deadline': deadlineStr,
        'category': 'Administrasi',
        'location': 'Jakarta',
        'isCompleted': 1,
        'priorityScore': 63,
        'priorityLabel': 'Sedang',
      };

      final pengingat = Pengingat.fromMap(map);

      expect(pengingat.id, 2);
      expect(pengingat.judul, 'Test From Map');
      expect(pengingat.kategori, 'Administrasi');
      expect(pengingat.sudahSelesai, true);
      expect(pengingat.priorityLabel, 'Sedang');
      expect(pengingat.deadline, isNotNull);
      expect(pengingat.deadline!.toIso8601String(), deadlineStr);
    });
  });
}
