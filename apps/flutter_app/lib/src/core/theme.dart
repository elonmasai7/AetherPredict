import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AetherColors {
  static const bg = Color(0xFF0B1017);
  static const bgElevated = Color(0xFF111826);
  static const bgPanel = Color(0xFF171F2E);
  static const border = Color(0xFF283245);
  static const muted = Color(0xFF8E9BB0);
  static const text = Color(0xFFE7EDF8);
  static const success = Color(0xFF2AB67D);
  static const warning = Color(0xFFE0A74A);
  static const critical = Color(0xFFDB6161);
  static const accent = Color(0xFF5A8FF0);
  static const accentSoft = Color(0xFF36588F);
}

class AetherRadii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
}

class AetherSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

ThemeData buildAetherTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final bodyText = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
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
    textTheme: bodyText.copyWith(
      displayLarge:
          bodyText.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge:
          bodyText.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          bodyText.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: bodyText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium:
          bodyText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodySmall:
          bodyText.bodySmall?.copyWith(color: AetherColors.muted, height: 1.35),
      labelSmall: bodyText.labelSmall?.copyWith(
        color: AetherColors.muted,
        letterSpacing: 0.25,
      ),
    ),
    cardTheme: CardThemeData(
      color: AetherColors.bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        side: const BorderSide(color: AetherColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerColor: AetherColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AetherColors.bgPanel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        borderSide: const BorderSide(color: AetherColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        borderSide: const BorderSide(color: AetherColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        borderSide: const BorderSide(color: AetherColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        borderSide: const BorderSide(color: AetherColors.critical),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        borderSide: const BorderSide(color: AetherColors.critical),
      ),
      hintStyle: const TextStyle(color: AetherColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AetherColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      backgroundColor: AetherColors.bgElevated,
      selectedColor: AetherColors.bgPanel,
      labelStyle: const TextStyle(color: AetherColors.text),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AetherColors.text,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AetherColors.accent,
        foregroundColor: AetherColors.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AetherRadii.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AetherColors.text,
        side: const BorderSide(color: AetherColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AetherRadii.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AetherColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AetherColors.bgElevated,
      indicatorColor: AetherColors.bgPanel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(AetherColors.accentSoft),
      trackColor: WidgetStatePropertyAll(Colors.transparent),
      radius: Radius.circular(999),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AetherColors.bgPanel,
      contentTextStyle: bodyText.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AetherRadii.md),
        side: const BorderSide(color: AetherColors.border),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextStyle numericStyle(
  BuildContext context, {
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color? color,
}) {
  return GoogleFonts.ibmPlexMono(
    textStyle: Theme.of(context).textTheme.bodyMedium,
    fontSize: size,
    fontWeight: weight,
    color: color ?? AetherColors.text,
  );
}
