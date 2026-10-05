/// Form validation helpers, shared by the onboarding and edit-profile forms.
///
/// Rules are intentionally simple and friendly: the agent is told exactly
/// what is wrong in plain language.
class Validators {
  const Validators._();

  /// Indian mobile numbers: 10 digits starting with 6–9,
  /// optionally written with a +91 / 0 / spaces / dashes prefix.
  static final RegExp _indianMobile = RegExp(r'^(?:\+?91[-\s]?|0)?[6-9]\d{9}$');

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Removes spaces, dashes and brackets used when typing phone numbers.
  static String normalizeMobile(String input) =>
      input.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Checks an Indian mobile number (after allowing pretty formatting).
  static bool isValidIndianMobile(String? input) {
    if (input == null) return false;
    return _indianMobile.hasMatch(normalizeMobile(input.trim()));
  }

  /// Required non-empty text (with a friendly message).
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  /// Required full name: 2–120 characters.
  static String? fullName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter your full name';
    if (trimmed.length < 2) return 'Name looks too short';
    if (trimmed.length > 120) return 'Name must be at most 120 characters';
    return null;
  }

  /// Mobile/WhatsApp number: required, Indian format.
  static String? mobile(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a mobile number';
    if (!isValidIndianMobile(trimmed)) {
      return 'Enter a valid Indian mobile number (10 digits, starting 6–9)';
    }
    return null;
  }

  /// Optional mobile/WhatsApp number (empty is fine, but must be valid).
  static String? optionalMobile(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return mobile(trimmed);
  }

  /// Email address: optional but must look like an email if entered.
  static String? optionalEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!_email.hasMatch(trimmed)) return 'Enter a valid email address';
    if (trimmed.length > 254) return 'Email must be at most 254 characters';
    return null;
  }

  /// Email address: required.
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter your email address';
    return optionalEmail(trimmed);
  }

  /// Password: at least 8 characters (kept simple on purpose).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Optional short text with a maximum length.
  static String? optionalText(String? value, {required String label, int max = 120}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > max) return '$label must be at most $max characters';
    return null;
  }

  /// A colour written as #RRGGBB (hex).
  static bool isValidHexColor(String value) =>
      RegExp(r'^#([0-9A-Fa-f]{6})$').hasMatch(value.trim());
}
