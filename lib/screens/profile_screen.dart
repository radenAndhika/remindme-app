import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/snackbar_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pengguna = Provider.of<AuthProvider>(context, listen: false).penggunaSaatIni;
      if (pengguna?.fotoProfil != null) {
        setState(() => _image = File(pengguna!.fotoProfil!));
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      await Provider.of<AuthProvider>(context, listen: false).perbaruiFotoProfil(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pengguna = auth.penggunaSaatIni;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Pengaturan Akun', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outline.withOpacity(0.1), width: 1.5),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          backgroundImage: _image != null ? FileImage(_image!) : null,
                          child: _image == null ? const Icon(Icons.person_outline, size: 40, color: AppTheme.primary) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    pengguna?.namaPengguna ?? 'Nama Pengguna',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSection(
              'Masukan Akademik',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesan & Kesan Mata Kuliah TPM',
                    style: TextStyle(color: AppTheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.1)),
                    ),
                    child: Text(
                      'Teknologi Pemrograman Mobile, Mantap Betol!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildTile(
              'Keamanan & Biometrik',
              Icons.fingerprint,
              AppTheme.primary,
              () {
                showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setDialogState) {
                      return AlertDialog(
                        title: const Text('Keamanan Biometrik'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Aktifkan biometrik untuk masuk ke aplikasi tanpa kata sandi.'),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Biometrik hanya bisa didaftarkan setelah kamu login. Saat diaktifkan, aplikasi akan meminta verifikasi biometrik satu kali untuk mendaftarkan login cepat.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Gunakan Biometrik'),
                              value: auth.biometrikAktif,
                              activeColor: AppTheme.primary,
                              onChanged: (val) async {
                                final message = await auth.setelBiometrik(val);
                                if (!mounted) return;
                                if (message == null) {
                                  SnackBarUtils.showSuccess(
                                    context,
                                    val
                                        ? 'Biometrik berhasil didaftarkan untuk login berikutnya.'
                                        : 'Biometrik berhasil dinonaktifkan.',
                                  );
                                } else {
                                  SnackBarUtils.showError(context, message);
                                }
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
                      );
                    }
                  ),
                );
              },
            ),
            _divider(),
            _buildTile(
              'Kebijakan Privasi',
              Icons.privacy_tip_outlined,
              AppTheme.outline,
              () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Kebijakan Privasi'),
                    content: const SingleChildScrollView(
                      child: Text('RemindMe+ menghargai privasi Anda. Data pengingat dan login Anda disimpan secara lokal di perangkat ini dengan enkripsi AES. Kami tidak mengirimkan data sensitif Anda ke server manapun kecuali untuk layanan AI Gemini yang bersifat anonim.'),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
                  ),
                );
              },
            ),
            _divider(),
            _buildTile(
              'Keluar',
              Icons.logout,
              Colors.redAccent,
              () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Keluar'),
                    content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Keluar')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await auth.keluar();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _divider() => Divider(color: AppTheme.outline.withOpacity(0.05), height: 1);

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }
}
