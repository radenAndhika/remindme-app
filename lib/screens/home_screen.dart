import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/task_priority_service.dart';
import '../core/app_theme.dart';
import '../core/snackbar_utils.dart';
import '../services/ai_service.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  StreamSubscription? _shakeSub;
  StreamSubscription? _tiltSub;

  @override
  void initState() {
    super.initState();
    SensorService.init();
    _shakeSub = SensorService.onShake.listen((_) {
      SnackBarUtils.showSuccess(context, 'Goncangan terdeteksi! Memperbarui...');
      _refresh();
    });
    _tiltSub = SensorService.onTilt.listen((val) {
      SnackBarUtils.showSuccess(context, 'Kemiringan terdeteksi: ${val > 0 ? "Kanan" : "Kiri"}');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    final pengguna = Provider.of<AuthProvider>(context, listen: false).penggunaSaatIni;
    if (pengguna != null) Provider.of<PengingatProvider>(context, listen: false).ambilPengingat(pengguna.id!);
  }

  void _openAIChat() {
    final pengingatProvider = Provider.of<PengingatProvider>(context, listen: false);
    final daftarTugas = pengingatProvider.daftarPengingat.map((r) {
      final deadline = r.deadline != null
          ? DateFormat('dd MMM yyyy, HH:mm').format(r.deadline!)
          : 'Tanpa deadline';
      return '${r.judul} | Kategori: ${r.kategori} | Prioritas: ${r.priorityLabel} (${r.priorityScore}) | Deadline: $deadline';
    }).toList();
    Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatScreen(tasks: daftarTugas)));
  }

  void _showAddReminderDialog(BuildContext context, int idPengguna) async {
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    String lokasiStr = 'Mengambil lokasi...';
    DateTime? selectedDeadline;
    String selectedCategory = TaskPriorityService.categories.first;
    bool isAnalyzing = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (lokasiStr == 'Mengambil lokasi...') {
            LocationService.getCurrentLocation().then((pos) async {
              if (pos != null) {
                final address = await LocationService.getAddressFromLatLng(pos);
                if (mounted) {
                  setDialogState(() {
                    lokasiStr = address;
                  });
                }
              } else {
                if (mounted) {
                  setDialogState(() {
                    lokasiStr = 'Lokasi tidak tersedia';
                  });
                }
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Pengingat Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: judulController,
                    decoration: const InputDecoration(hintText: 'Apa yang perlu dilakukan?'),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Tambah detail...'),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      hintText: 'Pilih kategori tugas',
                      prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primary),
                    ),
                    items: TaskPriorityService.categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                    title: Text(
                      selectedDeadline == null ? 'Set Tenggat Waktu (Opsional)' : 'Deadline: ${DateFormat('dd MMM yyyy, HH:mm').format(selectedDeadline!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDeadline == null ? AppTheme.onSurface.withOpacity(0.5) : AppTheme.primary,
                        fontWeight: selectedDeadline == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          if (picked.isBefore(DateTime.now())) {
                            if (mounted) {
                              SnackBarUtils.showError(context, 'Tenggat waktu tidak boleh di masa lalu!');
                            }
                          } else {
                            setDialogState(() => selectedDeadline = picked);
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(lokasiStr, style: const TextStyle(fontSize: 12, color: AppTheme.primary))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                  onPressed: isAnalyzing ? null : () async {
                  if (judulController.text.isEmpty) {
                    SnackBarUtils.showError(context, 'Judul tidak boleh kosong!');
                    return;
                  }
                  if (selectedDeadline != null && selectedDeadline!.isBefore(DateTime.now())) {
                    SnackBarUtils.showError(context, 'Tenggat waktu tidak boleh di masa lalu!');
                    return;
                  }
                  setDialogState(() => isAnalyzing = true);
                  try {
                    final priority = await AIService.analyzePriority(
                      title: judulController.text,
                      description: deskripsiController.text,
                      category: selectedCategory,
                      deadline: selectedDeadline,
                    );
                    final pengingat = Pengingat(
                      idPengguna: idPengguna,
                      judul: judulController.text,
                      deskripsi: deskripsiController.text,
                      waktu: DateTime.now().add(const Duration(seconds: 10)),
                      kategori: selectedCategory,
                      lokasi: lokasiStr == 'Mengambil lokasi...' ? 'Lokasi tidak diketahui' : lokasiStr,
                      deadline: selectedDeadline,
                      priorityScore: priority.score,
                      priorityLabel: priority.label,
                    );
                    await Provider.of<PengingatProvider>(context, listen: false).tambahPengingat(pengingat);
                    try {
                      if (selectedDeadline != null && selectedDeadline!.isAfter(DateTime.now())) {
                        final msg = await NotificationService.scheduleDeadlineNotifications(
                          id: Random().nextInt(1000) + 2000,
                          title: judulController.text,
                          deadline: selectedDeadline!,
                        );
                        if (mounted) SnackBarUtils.showSuccess(context, msg);
                      }
                    } catch (e) {
                      debugPrint('Gagal menampilkan notifikasi: $e');
                    }
                    if (mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setDialogState(() => isAnalyzing = false);
                    if (mounted) SnackBarUtils.showError(context, 'Gagal menambahkan tugas: $e');
                  }
                },
                child: isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    _tiltSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pengingatProvider = Provider.of<PengingatProvider>(context);
    final pengguna = Provider.of<AuthProvider>(context).penggunaSaatIni;

    final daftarTerfilter = pengingatProvider.daftarPengingat.where((r) {
      return r.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             r.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             r.kategori.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             r.priorityLabel.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList()
      ..sort((a, b) {
        final scoreCompare = b.priorityScore.compareTo(a.priorityScore);
        if (scoreCompare != 0) return scoreCompare;
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo,', style: TextStyle(fontSize: 14, color: AppTheme.onSurface.withOpacity(0.5))),
            Text(pengguna?.namaPengguna ?? "Pengguna", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        actions: [
          // 🔔 DEBUG: Tap to send an immediate test notification
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Test Notifikasi',
              icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
              onPressed: () async {
                final ok = await NotificationService.showImmediateNotification(
                  title: '🔔 Test Notifikasi',
                  body: 'Jika ini muncul, sistem notifikasi berfungsi dengan baik!',
                );
                if (mounted) {
                  if (ok) {
                    SnackBarUtils.showSuccess(context, 'Notifikasi dikirim! Cek status bar kamu.');
                  } else {
                    SnackBarUtils.showError(context, 'Gagal mengirim notifikasi. Cek izin aplikasi.');
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: _openAIChat,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari fokusmu...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.1), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _SectionHeader(count: daftarTerfilter.length),
            const SizedBox(height: 20),
            Expanded(
              child: pengingatProvider.sedangMemuat
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : daftarTerfilter.isEmpty
                      ? const _EmptyState()
                      : RepaintBoundary(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: daftarTerfilter.length,
                            addRepaintBoundaries: true,
                            addAutomaticKeepAlives: false,
                            itemBuilder: (context, index) {
                              return _ReminderCard(
                                key: ValueKey(daftarTerfilter[index].id),
                                pengingat: daftarTerfilter[index],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context, pengguna!.id!),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: const Text('Tambah Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;
  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Tugas Berjalan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Total',
            style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wb_sunny_outlined, size: 80, color: AppTheme.primary.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            'Belum ada tugas yang difokuskan.',
            style: TextStyle(color: AppTheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Pengingat pengingat;
  const _ReminderCard({super.key, required this.pengingat});

  Color _priorityColor() {
    switch (pengingat.priorityLabel) {
      case 'Tinggi':
        return Colors.redAccent;
      case 'Sedang':
        return Colors.orangeAccent;
      default:
        return AppTheme.secondary;
    }
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(pengingat.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pengingat.deskripsi, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  text: pengingat.kategori,
                  color: AppTheme.secondary,
                ),
                _InfoChip(
                  icon: Icons.auto_graph,
                  text: 'Prioritas ${pengingat.priorityLabel}',
                  color: _priorityColor(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(pengingat.lokasi ?? 'Tanpa Lokasi', style: const TextStyle(fontSize: 12, color: AppTheme.primary))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 16, color: AppTheme.onSurface),
                const SizedBox(width: 8),
                Text(pengingat.waktu.toString().split('.')[0], style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (pengingat.deadline != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event_busy, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: ${DateFormat('dd MMM yyyy, HH:mm').format(pengingat.deadline!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline.withOpacity(0.1), width: 1.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pengingat.judul,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.onSurface),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.auto_graph,
                            text: 'Prioritas ${pengingat.priorityLabel}',
                            color: _priorityColor(),
                          ),
                          _InfoChip(
                            icon: Icons.category_outlined,
                            text: pengingat.kategori,
                            color: AppTheme.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pengingat.deskripsi,
                        style: TextStyle(color: AppTheme.onSurface.withOpacity(0.6), fontSize: 14, height: 1.4),
                      ),
                      if (pengingat.lokasi != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pengingat.lokasi!,
                                style: const TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (pengingat.deadline != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                'Deadline: ${DateFormat('dd MMM').format(pengingat.deadline!)}',
                                style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Provider.of<PengingatProvider>(context, listen: false).hapusPengingat(pengingat.id!, pengingat.idPengguna);
                },
                icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.3)),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
