class TaskPriorityResult {
  final int score;
  final String label;

  const TaskPriorityResult({
    required this.score,
    required this.label,
  });
}

class TaskPriorityService {
  static const List<String> categories = [
    'Tugas Kuliah',
    'Ujian/Kuis',
    'Presentasi',
    'Revisi/Laporan',
    'Rapat/Kegiatan',
    'Pribadi',
    'Administrasi',
    'Umum',
  ];

  static const Map<String, int> _categoryWeights = {
    'Tugas Kuliah': 14,
    'Ujian/Kuis': 22,
    'Presentasi': 20,
    'Revisi/Laporan': 18,
    'Rapat/Kegiatan': 15,
    'Pribadi': 8,
    'Administrasi': 12,
    'Umum': 10,
  };

  static const Map<String, int> _keywordWeights = {
    'ujian': 8,
    'kuis': 8,
    'presentasi': 7,
    'sidang': 9,
    'laporan': 7,
    'revisi': 6,
    'skripsi': 10,
    'proposal': 7,
    'submit': 8,
    'kumpul': 7,
    'deadline': 8,
    'segera': 8,
    'penting': 6,
    'darurat': 10,
    'hari ini': 10,
    'besok': 9,
    'malam ini': 9,
    'pagi ini': 8,
    'rapat': 5,
    'temui': 5,
    'bawa': 4,
    'kirim': 5,
  };

  static TaskPriorityResult analyze({
    required String title,
    required String description,
    required String category,
    DateTime? deadline,
  }) {
    final now = DateTime.now();
    var score = 0;

    score += _scoreDeadline(now, deadline);
    score += _categoryWeights[category] ?? _categoryWeights['Umum']!;
    score += _scoreText('$title ${description.trim()}');
    score += _scoreComplexity(description);

    final normalizedScore = score.clamp(0, 100).toInt();

    return TaskPriorityResult(
      score: normalizedScore,
      label: _labelForScore(normalizedScore),
    );
  }

  static int _scoreDeadline(DateTime now, DateTime? deadline) {
    if (deadline == null) return 10;

    final hours = deadline.difference(now).inHours;
    if (hours <= 24) return 55;
    if (hours <= 72) return 45;
    if (hours <= 168) return 30;
    if (hours <= 336) return 18;
    return 8;
  }

  static int _scoreText(String text) {
    final normalized = text.toLowerCase();
    var score = 0;

    _keywordWeights.forEach((keyword, weight) {
      if (normalized.contains(keyword)) {
        score += weight;
      }
    });

    return score.clamp(0, 20).toInt();
  }

  static int _scoreComplexity(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return 0;
    if (trimmed.length >= 120) return 8;
    if (trimmed.length >= 60) return 5;
    if (trimmed.length >= 20) return 3;
    return 1;
  }

  static String _labelForScore(int score) {
    if (score >= 75) return 'Tinggi';
    if (score >= 45) return 'Sedang';
    return 'Rendah';
  }
}
