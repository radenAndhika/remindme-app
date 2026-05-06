import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

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
