import 'package:flutter/material.dart';

/// FlowSync palette: soft white, sage green and deep olive.
///
/// Contrast rules (WCAG):
/// - [sage] is for fills only. Never use it for text, icons or borders.
/// - [inputBorder] meets 3:1 on both [background] and [surface].
/// - [warningText] is the readable text color for the gold [accent] family.
abstract final class AppColors {
  static const Color background = Color(0xFFE8E9DF);
  static const Color surface = Color(0xFFF5F6EF);

  static const Color primary = Color(0xFF2E3D28);
  static const Color accessiblePrimary = Color(0xFF2E3D28);
  static const Color onPrimary = Color(0xFFF5F6EF);

  static const Color sage = Color(0xFFA9B887);

  static const Color secondary = Color(0xFF5B6754);
  static const Color accessibleSecondary = Color(0xFF5B6754);

  static const Color textPrimary = Color(0xFF2E3D28);
  static const Color textSecondary = Color(0xFF566250);

  static const Color accent = Color(0xFFD5A34D);
  static const Color warningText = Color(0xFF7A5200);

  static const Color border = Color(0xFFD2D5C4);
  static const Color inputBorder = Color(0xFF74806C);

  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E6B4F);
}
