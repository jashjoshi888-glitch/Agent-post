import 'package:flutter/material.dart';

/// The AgentPost colour palette, defined once and used everywhere.
///
/// Brand feel: trustworthy deep navy + calm teal + warm gold accent.
/// (The same two colours are the default brand-kit colours for new agents.)
class AppColors {
  const AppColors._();

  /// Deep navy — primary brand colour (buttons, highlights).
  static const Color navy = Color(0xFF173B63);

  /// Lighter navy for dark accents and pressed states.
  static const Color navyDark = Color(0xFF0B2440);

  /// Soft navy tint for containers and highlights.
  static const Color navySoft = Color(0xFFD8E3F1);

  /// Teal — secondary brand colour.
  static const Color teal = Color(0xFF0FA3B1);

  /// Gold — accent colour for small highlights.
  static const Color gold = Color(0xFFC9A227);

  /// Standard surfaces.
  static const Color background = Color(0xFFF7F9FC);
  static const Color cardBorder = Color(0xFFE4E9F0);
  static const Color inputFill = Color(0xFFF1F4F8);

  /// Text colours.
  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textSecondary = Color(0xFF5B6472);
}
