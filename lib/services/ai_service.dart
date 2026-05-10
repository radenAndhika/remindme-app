import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'task_priority_service.dart';

class AIService {
  static const String _apiKey = 'AIzaSyDoPUvL7RsWRudBhoF2ksbb3TgA7nUm9Vo'; // ganti dengan Gemini API key lo

  static Future<String> getTaskSummary(List<String> tasks) async {
    if (tasks.isEmpty) return 'Belum ada tugas untuk dirangkum.';
    if (_apiKey.isEmpty) return 'API Key belum dikonfigurasi. Tambahkan --dart-define=GEMINI_API_KEY=kunci_anda saat menjalankan aplikasi.';

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final prompt = 'Rangkum tugas-tugas berikut dalam Bahasa Indonesia yang santai dan bersih (tanpa format markdown yang berlebihan) dan berikan satu tips produktivitas singkat: ${tasks.join(', ')}';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Gagal menghasilkan rangkuman.';
    } catch (e) {
      return 'Terjadi kesalahan saat menghubungi AI: $e';
    }
  }

  static Future<TaskPriorityResult> analyzePriority({
    required String title,
    required String description,
    required String category,
    DateTime? deadline,
  }) async {
    if (_apiKey.isEmpty) {
      return TaskPriorityService.analyze(title: title, description: description, category: category, deadline: deadline);
    }
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final deadlineStr = deadline != null ? DateFormat('yyyy-MM-dd HH:mm').format(deadline) : 'Tidak ada deadline';
      final prompt = 'Kamu adalah sistem analisis prioritas tugas akademik. Waktu sekarang: $now. '
          'Judul: "$title". Deskripsi: "${description.isEmpty ? "Tidak ada" : description}". '
          'Kategori: "$category". Deadline: "$deadlineStr". '
          'Panduan: Skor 75-100 = Tinggi (deadline <=24 jam atau ujian/presentasi/sidang). '
          'Skor 45-74 = Sedang (deadline 1-7 hari atau tugas kuliah/laporan). '
          'Skor 0-44 = Rendah (tidak ada deadline atau kategori pribadi/umum). '
          'Balas HANYA dengan JSON: {"score": <0-100>, "label": "<Tinggi|Sedang|Rendah>"}';
      final response = await model.generateContent([Content.text(prompt)]);
      final match = RegExp(r'\{[^}]+\}').firstMatch(response.text ?? '');
      if (match != null) {
        final decoded = json.decode(match.group(0)!);
        final score = (decoded['score'] as num).toInt().clamp(0, 100);
        final label = decoded['label']?.toString() ?? 'Rendah';
        return TaskPriorityResult(score: score, label: label);
      }
    } catch (e) {
      debugPrint('AI Priority fallback ke rule-based: $e');
    }
    return TaskPriorityService.analyze(title: title, description: description, category: category, deadline: deadline);
  }

  static ChatSession? startChat(List<String> tasks, {String? userLocation}) {
    if (_apiKey.isEmpty) return null;
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    
    String prompt = 'Kamu adalah asisten produktivitas di aplikasi RemindMe+. Berbicaralah dalam bahasa Indonesia yang ramah, santai, dan membantu. Berikut adalah daftar tugas penggunaku saat ini: ${tasks.isEmpty ? "Belum ada tugas." : tasks.join(', ')}. Setiap tugas bisa memuat kategori, label prioritas, skor prioritas, dan deadline. Perlakukan prioritas tinggi sebagai tugas yang lebih mendesak, lalu gunakan itu saat memberi saran urutan pengerjaan. Jawab singkat, solutif, dan hindari penggunaan format Markdown yang berlebihan seperti simbol pagar (#) atau daftar yang terlalu panjang. Gunakan gaya bahasa manusia yang normal dan bersih.';
    prompt += '\n\nJika pengguna meminta dibuatkan jadwal, reminder, atau tugas baru, berikan jawaban singkat yang manusiawi lalu akhiri dengan blok JSON valid di dalam fenced code block ```json. JSON itu harus punya format persis seperti ini: {"title":"...", "description":"...", "date":"YYYY-MM-DD", "time":"HH:mm", "category":"Tugas Kuliah", "location":"..."}. Field "location" boleh dikosongkan jika pengguna tidak menyebut tempat. Gunakan hanya salah satu kategori berikut: Tugas Kuliah, Ujian/Kuis, Presentasi, Revisi/Laporan, Rapat/Kegiatan, Pribadi, Administrasi, Umum. Jika informasi tanggal atau jam belum cukup jelas, jangan buat JSON dan minta klarifikasi singkat.';
    
    if (userLocation != null && userLocation.isNotEmpty) {
      prompt += '\n\nINFO LOKASI: Lokasi pengguna saat ini adalah $userLocation. Jika pengguna menyebutkan suatu tempat (seperti "alfamart", "cafe", dll) pada tugasnya, atau meminta rekomendasi tempat terdekat, berikan panduan rute atau saran tempat terdekat dari lokasinya tersebut. Berikan juga tautan Google Maps menggunakan format: https://www.google.com/maps/search/?api=1&query=[NAMA+TEMPAT+SPASI+NAMA+KOTA_ATAU_LOKASI]. Contoh: https://www.google.com/maps/search/?api=1&query=Alfamart+terdekat.';
    }
    
    final history = [
      Content.text(prompt),
      Content.model([TextPart('Siap! Aku siap membantumu mengelola tugas-tugas tersebut dan siap membantu mencari lokasi terdekat.')])
    ];
    
    return model.startChat(history: history);
  }
}
