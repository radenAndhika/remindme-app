import 'package:flutter_test/flutter_test.dart';
import 'package:remindme/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Auth Provider Logic Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    test('Initial state should be logged out', () {
      expect(authProvider.sudahMasuk, false);
      expect(authProvider.penggunaSaatIni, isNull);
    });

    test('Logout should clear session', () async {
      await authProvider.keluar();
      expect(authProvider.sudahMasuk, false);
      expect(authProvider.penggunaSaatIni, isNull);
    });

    test('Disabling biometric should persist in memory', () async {
      await authProvider.nonaktifkanBiometrik();
      expect(authProvider.biometrikAktif, false);
    });

    test('Register should reject weak password', () async {
      final result = await authProvider.daftar('andhika', '111');
      expect(result, false);
      expect(authProvider.pesanAutentikasi, isNotNull);
    });
  });
}
