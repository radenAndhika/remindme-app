import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/password_validator.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/snackbar_utils.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Provider.of<AuthProvider>(context, listen: false).sudahMasuk) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    });
  }

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      SnackBarUtils.showError(context, 'Nama pengguna tidak boleh kosong.');
      return;
    }

    bool success;
    if (_isLogin) {
      success = await auth.masuk(username, password);
    } else {
      final passwordError = PasswordValidator.validate(password);
      if (passwordError != null) {
        SnackBarUtils.showError(context, passwordError);
        return;
      }

      success = await auth.daftar(username, password);
      if (success) {
        setState(() => _isLogin = true);
        SnackBarUtils.showSuccess(context, 'Pendaftaran berhasil! Silakan masuk.');
        return;
      }
    }

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } else {
      if (mounted) {
        SnackBarUtils.showError(context, auth.pesanAutentikasi ?? 'Autentikasi gagal!');
      }
    }
  }

  void _biometricLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.autentikasiBiometrik();
    if (success) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } else {
      if (mounted) {
        SnackBarUtils.showError(context, 'Autentikasi biometrik gagal atau belum diatur!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
                  ),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 60,
                    height: 60,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _isLogin ? 'RemindMe+' : 'Gabung RemindMe+',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                Text(
                  _isLogin ? 'Selamat datang kembali!' : 'Mulai perjalanan fokusmu hari ini.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Nama Pengguna',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) {
                    if (!_isLogin) {
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, size: 18, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text(
                              'Syarat Password',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PasswordRule(
                          text: 'Minimal 8 karakter',
                          passed: _passwordController.text.length >= 8,
                        ),
                        _PasswordRule(
                          text: 'Memiliki huruf besar',
                          passed: RegExp(r'[A-Z]').hasMatch(_passwordController.text),
                        ),
                        _PasswordRule(
                          text: 'Memiliki huruf kecil',
                          passed: RegExp(r'[a-z]').hasMatch(_passwordController.text),
                        ),
                        _PasswordRule(
                          text: 'Memiliki simbol',
                          passed: RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'MASUK' : 'DAFTAR'),
                  ),
                ),
                const SizedBox(height: 30),
                if (_isLogin && context.watch<AuthProvider>().biometrikSiapLogin) ...[
                  GestureDetector(
                    onTap: _biometricLogin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outline.withOpacity(0.2), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fingerprint, color: AppTheme.secondary),
                          SizedBox(width: 10),
                          Text('Gunakan Biometrik', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk', 
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  final String text;
  final bool passed;

  const _PasswordRule({
    required this.text,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppTheme.secondary : AppTheme.onSurface.withOpacity(0.55);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
