import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AetherColors {
  static const bg = Color(0xFF0F131A);
  static const bgElevated = Color(0xFF151B24);
  static const bgPanel = Color(0xFF1A2230);
  static const border = Color(0xFF2C3747);
  static const muted = Color(0xFF95A1B3);
  static const text = Color(0xFFE6EDF7);
  static const success = Color(0xFF2FB67C);
  static const warning = Color(0xFFF0B429);
  static const critical = Color(0xFFE25B5B);
  static const accent = Color(0xFF5EA4FF);
  static const accentSoft = Color(0xFF3B5D8A);
}

ThemeData buildAetherTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AetherColors.text,
    displayColor: AetherColors.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AetherColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AetherColors.bgPanel,
      primary: AetherColors.accent,
      secondary: AetherColors.accentSoft,
      error: AetherColors.critical,
    ),
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: textTheme.bodySmall?.copyWith(color: AetherColors.muted),
    ),
    cardTheme: CardThemeData(
      color: AetherColors.bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AetherColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerColor: AetherColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AetherColors.bgPanel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AetherColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AetherColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AetherColors.accent),
      ),
      hintStyle: const TextStyle(color: AetherColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AetherColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: AetherColors.bgElevated,
      labelStyle: const TextStyle(color: AetherColors.text),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AetherColors.text,
      elevation: 0,
    ),
  );
}

TextStyle numericStyle(BuildContext context, {double size = 14, FontWeight weight = FontWeight.w600, Color? color}) {
  return GoogleFonts.ibmPlexMono(
    textStyle: Theme.of(context).textTheme.bodyMedium,
    fontSize: size,
    fontWeight: weight,
    color: color ?? AetherColors.text,
  );
}
