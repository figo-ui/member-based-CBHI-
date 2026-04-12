import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  AdminTheme._();

  static const Color primary = Color(0xFF0D7A5F);
  static const Color accent = Color(0xFF00BFA5);
  static const Color gold = Color(0xFFF9A825);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF2E7D52);
  static const Color warning = Color(0xFFFF8F00);
  static const Color surface = Color(0xFFF0F4F3);
  static const Color sidebarBg = Color(0xFF0D1F1A);
  static const Color sidebarText = Color(0xFFB8D4CC);
  static const Color sidebarSelected = Color(0xFF00BFA5);
  static const Color textDark = Color(0xFF1A2E35);
  static const Color textSecondary = Color(0xFF5A7A84);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0D7A5F), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: surface,
    );

    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        titleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: textDark,
          fontSize: 20,
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surface),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.04);
          }
          return Colors.white;
        }),
        headingTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: textSecondary,
          fontSize: 13,
        ),
        dataTextStyle: GoogleFonts.outfit(color: textDark, fontSize: 13),
        dividerThickness: 1,
        columnSpacing: 24,
      ),
    );
  }
}
