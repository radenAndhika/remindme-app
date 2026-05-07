class PasswordValidator {
  static const String rulesSummary =
      'Minimal 8 karakter, ada huruf besar, huruf kecil, dan simbol.';
  static final RegExp _symbolPattern = RegExp(r'[^A-Za-z0-9]');

  static String? validate(String password) {
    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 huruf besar.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 huruf kecil.';
    }
    if (!_symbolPattern.hasMatch(password)) {
      return 'Password harus mengandung minimal 1 simbol.';
    }
    return null;
  }
}
