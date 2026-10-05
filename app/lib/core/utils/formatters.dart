/// Small formatting helpers used across screens.
class Formatters {
  const Formatters._();

  /// Shows a mobile number as "+91 98765 43210" when possible.
  static String mobile(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      final last10 = digits.substring(2);
      return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
    }
    return raw.trim();
  }

  /// Joins a list like [Surat, Vadodara] into "Surat, Vadodara".
  static String list(List<String> items) => items.join(', ');

  /// Shows a date as "5 Oct 2026" (no locale packages needed).
  static String date(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
