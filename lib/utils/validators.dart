class AppValidators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final r = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!r.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  // ── Strong password validation ─────────────────────────────────────────────
  // Rules: 8+ chars, uppercase, lowercase, digit, special character
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Password must contain at least one uppercase letter (A–Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Password must contain at least one lowercase letter (a–z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'Password must contain at least one number (0–9)';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(v)) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }
    return null;
  }

  static String? confirmPassword(String? v, String password) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  static String? required(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Phone number is required';
    final r = RegExp(r'^(\+?254|0)[17]\d{8}$');
    if (!r.hasMatch(v.replaceAll(' ', ''))) {
      return 'Enter a valid Kenyan phone number';
    }
    return null;
  }

  static String? positiveNumber(String? v, String field) {
    if (v == null || v.isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return '$field must be greater than 0';
    return null;
  }

  static String? name(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    if (v.trim().length < 2) return '$field must be at least 2 characters';
    return null;
  }
}