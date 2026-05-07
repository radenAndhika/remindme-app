import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/db_helper.dart';
import '../core/encryption_helper.dart';
import '../core/password_validator.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final LocalAuthentication _autentikasiLocal;
  static const String _biometrikAktifKey = 'biometrik_aktif';
  static const String _biometricUsernameKey = 'biometric_username';
  
  Pengguna? _penggunaSaatIni;
  bool _sudahMasuk = false;
  bool _biometrikAktif = false;
  String? _pesanAutentikasi;

  AuthProvider({
    DatabaseHelper? dbHelper,
    LocalAuthentication? auth,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _autentikasiLocal = auth ?? LocalAuthentication();

  Pengguna? get penggunaSaatIni => _penggunaSaatIni;
  bool get sudahMasuk => _sudahMasuk;
  bool get biometrikAktif => _biometrikAktif;
  bool get biometrikSiapLogin => _biometrikAktif;
  String? get pesanAutentikasi => _pesanAutentikasi;

  Future<void> perbaruiFotoProfil(String imagePath) async {
    if (_penggunaSaatIni == null) return;
    
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'id = ?',
      whereArgs: [_penggunaSaatIni!.id],
    );
    
    _penggunaSaatIni = Pengguna(
      id: _penggunaSaatIni!.id,
      namaPengguna: _penggunaSaatIni!.namaPengguna,
      kataSandi: _penggunaSaatIni!.kataSandi,
      fotoProfil: imagePath,
    );
    notifyListeners();
  }

  Future<void> periksaSesi() async {
    final prefs = await SharedPreferences.getInstance();
    _biometrikAktif =
        (prefs.getBool(_biometrikAktifKey) ?? false) &&
        (prefs.getString(_biometricUsernameKey)?.isNotEmpty ?? false);
    
    final username = prefs.getString('username');
    if (username != null) {
      final db = await _dbHelper.database;
      final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
      if (maps.isNotEmpty) {
        _penggunaSaatIni = Pengguna.fromMap(maps.first);
        _sudahMasuk = true;
        notifyListeners();
      }
    }
  }

  Future<String?> setelBiometrik(bool aktif) async {
    if (aktif) {
      return aktifkanBiometrik();
    }
    await nonaktifkanBiometrik();
    return null;
  }

  Future<String?> aktifkanBiometrik() async {
    if (kIsWeb) {
      return 'Biometrik tidak didukung di web.';
    }

    if (_penggunaSaatIni == null) {
      return 'Login dulu sebelum mengaktifkan biometrik.';
    }

    final didukung = await _perangkatMendukungBiometrik();
    if (!didukung) {
      return 'Perangkat ini tidak mendukung biometrik.';
    }

    try {
      final bool berhasil = await _autentikasiLocal.authenticate(
        localizedReason: 'Konfirmasi biometrik untuk mendaftarkan login cepat',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!berhasil) {
        return 'Pendaftaran biometrik dibatalkan.';
      }
    } catch (_) {
      return 'Gagal mendaftarkan biometrik di perangkat ini.';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometrikAktifKey, true);
    await prefs.setString(_biometricUsernameKey, _penggunaSaatIni!.namaPengguna);
    _biometrikAktif = true;
    notifyListeners();
    return null;
  }

  Future<void> nonaktifkanBiometrik() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometrikAktifKey, false);
    await prefs.remove(_biometricUsernameKey);
    _biometrikAktif = false;
    notifyListeners();
  }

  Future<bool> _perangkatMendukungBiometrik() async {
    final bool bisaBiometrik = await _autentikasiLocal.canCheckBiometrics;
    return bisaBiometrik || await _autentikasiLocal.isDeviceSupported();
  }

  Future<bool> daftar(String username, String password) async {
    _pesanAutentikasi = null;
    final usernameTrimmed = username.trim();
    if (usernameTrimmed.isEmpty) {
      _pesanAutentikasi = 'Nama pengguna tidak boleh kosong.';
      return false;
    }

    final passwordError = PasswordValidator.validate(password);
    if (passwordError != null) {
      _pesanAutentikasi = passwordError;
      return false;
    }

    final passwordTerkripsi = EncryptionHelper.encryptText(password);
    final pengguna = Pengguna(namaPengguna: usernameTrimmed, kataSandi: passwordTerkripsi);
    
    try {
      final db = await _dbHelper.database;
      await db.insert('users', pengguna.toMap());
      return true;
    } catch (e) {
      _pesanAutentikasi = 'Nama pengguna sudah dipakai atau data tidak valid.';
      return false;
    }
  }

  Future<bool> masuk(String username, String password) async {
    _pesanAutentikasi = null;
    final db = await _dbHelper.database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    
    if (maps.isNotEmpty) {
      final pengguna = Pengguna.fromMap(maps.first);
      final passwordTerdekripsi = EncryptionHelper.decryptText(pengguna.kataSandi);
      
      if (passwordTerdekripsi == password) {
        _penggunaSaatIni = pengguna;
        _sudahMasuk = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        notifyListeners();
        return true;
      }
    }
    _pesanAutentikasi = 'Nama pengguna atau kata sandi salah.';
    return false;
  }

  Future<bool> autentikasiBiometrik() async {
    if (kIsWeb) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled =
        (prefs.getBool(_biometrikAktifKey) ?? false) &&
        (prefs.getString(_biometricUsernameKey)?.isNotEmpty ?? false);
    if (!isEnabled) return false;
    
    try {
      final bool didukung = await _perangkatMendukungBiometrik();
      if (!didukung) return false;

      final bool berhasil = await _autentikasiLocal.authenticate(
        localizedReason: 'Silakan autentikasi untuk masuk',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (berhasil) {
        final bioUsername = prefs.getString(_biometricUsernameKey);
        if (bioUsername != null) {
          final db = await _dbHelper.database;
          final maps = await db.query('users', where: 'username = ?', whereArgs: [bioUsername]);
          if (maps.isNotEmpty) {
            _penggunaSaatIni = Pengguna.fromMap(maps.first);
            _sudahMasuk = true;
            await prefs.setString('username', bioUsername);
            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> keluar() async {
    _penggunaSaatIni = null;
    _sudahMasuk = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('last_active_time');
    notifyListeners();
  }

  Future<void> catatWaktuAktif() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_active_time', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> periksaPerluAutentikasi() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt('last_active_time');
    if (lastActive == null) return false;

    final diff = DateTime.now().millisecondsSinceEpoch - lastActive;
    return diff > 15000; // Lebih dari 15 detik
  }
}
