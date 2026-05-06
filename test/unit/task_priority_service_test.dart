import 'package:flutter_test/flutter_test.dart';
import 'package:remindme/services/task_priority_service.dart';

void main() {
  group('TaskPriorityService', () {
    test('Harus memberi prioritas tinggi untuk tugas ujian yang deadline dekat', () {
      final result = TaskPriorityService.analyze(
        title: 'Belajar ujian akhir',
        description: 'Materi harus selesai malam ini',
        category: 'Ujian/Kuis',
        deadline: DateTime.now().add(const Duration(hours: 12)),
      );

      expect(result.label, 'Tinggi');
      expect(result.score, greaterThanOrEqualTo(75));
    });

    test('Harus memberi prioritas lebih rendah untuk tugas umum tanpa deadline', () {
      final result = TaskPriorityService.analyze(
        title: 'Rapikan catatan',
        description: 'Kalau sempat saja',
        category: 'Umum',
      );

      expect(result.label, anyOf('Rendah', 'Sedang'));
      expect(result.score, lessThan(75));
    });
  });
}
