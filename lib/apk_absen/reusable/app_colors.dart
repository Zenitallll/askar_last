import 'package:flutter/material.dart';

/// Satu set warna untuk satu mode tampilan (terang / gelap).
///
/// Ambil lewat `AppColors.of(context)` supaya otomatis mengikuti
/// tombol Mode Gelap di halaman Profil.
///
/// Warna blok (lemon, mint, coral, sky, lilac) sama di kedua mode dan
/// selalu dipakai dengan teks gelap [onBlock].
@immutable
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.border,
    required this.shadow,
    required this.primary,
    required this.onPrimary,
    required this.accentText,
    required this.danger,
    required this.lemon,
    required this.mint,
    required this.coral,
    required this.sky,
    required this.lilac,
    required this.onBlock,
  });

  final bool isDark;

  /// Latar halaman.
  final Color bg;

  /// Panel / kartu.
  final Color surface;

  /// Teks utama.
  final Color ink;

  /// Teks sekunder.
  final Color muted;

  /// Garis tepi tebal.
  final Color border;

  /// Bayangan keras (tanpa blur).
  final Color shadow;

  final Color primary;
  final Color onPrimary;

  /// Warna aksen untuk teks tautan (kontras aman di latar mode ini).
  final Color accentText;

  final Color danger;

  final Color lemon;
  final Color mint;
  final Color coral;
  final Color sky;
  final Color lilac;

  /// Teks di atas blok warna.
  final Color onBlock;
}

class AppColors {
  AppColors._();

  static const Color black = Color(0xFF15131A);

  static const AppPalette light = AppPalette(
    isDark: false,
    bg: Color(0xFFF5F3FF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF15131A),
    muted: Color(0xFF5E5A6B),
    border: Color(0xFF15131A),
    shadow: Color(0xFF15131A),
    primary: Color(0xFF6D4AFF),
    onPrimary: Color(0xFFFFFFFF),
    accentText: Color(0xFF5232E0),
    danger: Color(0xFFD92D20),
    lemon: Color(0xFFFFD93D),
    mint: Color(0xFF3DDC97),
    coral: Color(0xFFFF7A6B),
    sky: Color(0xFF6CC4FF),
    lilac: Color(0xFFD6CBFF),
    onBlock: Color(0xFF15131A),
  );

  static const AppPalette dark = AppPalette(
    isDark: true,
    bg: Color(0xFF15131A),
    surface: Color(0xFF221F2D),
    ink: Color(0xFFF5F3FF),
    muted: Color(0xFFABA6BD),
    border: Color(0xFFF5F3FF),
    shadow: Color(0xFF9B83FF),
    primary: Color(0xFF6D4AFF),
    onPrimary: Color(0xFFFFFFFF),
    accentText: Color(0xFFB9A8FF),
    danger: Color(0xFFFF8A80),
    lemon: Color(0xFFFFD93D),
    mint: Color(0xFF3DDC97),
    coral: Color(0xFFFF7A6B),
    sky: Color(0xFF6CC4FF),
    lilac: Color(0xFFD6CBFF),
    onBlock: Color(0xFF15131A),
  );

  /// Palet yang aktif untuk [context] (mengikuti ThemeMode aplikasi).
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// ThemeData untuk MaterialApp. Dipakai di main.dart.
class AppTheme {
  AppTheme._();

  /// Isi dengan nama font jika kamu menambahkan font sendiri di pubspec.yaml.
  /// Font geometris tebal (mis. Space Grotesk, Sora) cocok dengan gaya ini.
  static const String? fontFamily = null;

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.lemon,
      onSecondary: p.onBlock,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
    );

    OutlineInputBorder inputBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      dividerColor: p.border,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(
          color: p.bg,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      textSelectionTheme: TextSelectionThemeData(cursorColor: p.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(
          color: p.accentText,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: TextStyle(color: p.muted),
        prefixIconColor: p.ink,
        suffixIconColor: p.ink,
        errorStyle: TextStyle(
          color: p.danger,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        border: inputBorder(p.border, 2),
        enabledBorder: inputBorder(p.border, 2),
        focusedBorder: inputBorder(p.primary, 3),
        errorBorder: inputBorder(p.danger, 2),
        focusedErrorBorder: inputBorder(p.danger, 3),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentText,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
