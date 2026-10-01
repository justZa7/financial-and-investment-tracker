import 'package:flutter/material.dart';

/// Palet warna Matcha — dipakai sebagai basis kedua tema (light & dark).
class AppColors {
  AppColors._();

  // --- Palet Matcha inti (sesuai permintaan) ---
  static const matchaDarkest = Color(0xFF3B6B3C);
  static const matchaDark = Color(0xFF5B9B56);
  static const matchaMedium = Color(0xFF7ABF7C);
  static const matchaLight = Color(0xFFA0D6A1);
  static const matchaPale = Color(0xFFC3E1B5);
  static const matchaBg = Color(0xFFE9F7E0);

  // --- Turunan untuk dark mode (belum ada di permintaan, diracik supaya
  // tetap terasa "matcha" tapi nyaman dilihat di background gelap) ---
  static const darkBg = Color(0xFF0F1A0E);
  static const darkSurface = Color(0xFF17241A);
  static const darkSurfaceAlt = Color(0xFF1F2E20);
  static const darkOnSurfaceMuted = Color(0xFFA9C0A2);

  // --- Warna semantik (gain/loss & kelas aset), diselaraskan dengan nuansa
  // matcha/earthy alih-alih biru/ungu terang seperti tema sebelumnya ---
  static const gain = matchaDark;
  static const loss = Color(0xFFC1502E); // terracotta hangat, kontras dengan hijau
  static const equity = matchaDarkest;
  static const gold = Color(0xFFC9A227);
  static const crypto = Color(0xFF7C6A9C); // plum pudar
  static const moneyMarket = Color(0xFF4C8577); // sage teal
  static const cash = Color(0xFF8A8677); // stone warm-gray
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.matchaDark,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.matchaDarkest,
      onPrimary: Colors.white,
      primaryContainer: AppColors.matchaPale,
      onPrimaryContainer: AppColors.matchaDarkest,
      secondary: AppColors.matchaMedium,
      secondaryContainer: AppColors.matchaLight,
      surface: Colors.white,
      surfaceContainerHighest: AppColors.matchaPale.withOpacity(0.55),
      onSurface: const Color(0xFF1E2A1C),
      onSurfaceVariant: const Color(0xFF4F5D49),
      outlineVariant: AppColors.matchaPale,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.matchaBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: AppColors.matchaDarkest.withOpacity(0.10),
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(fontSize: 12, color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 3,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      textTheme: const TextTheme().apply(
        fontFamily: 'Roboto',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.matchaMedium,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.matchaLight,
      onPrimary: AppColors.darkBg,
      primaryContainer: AppColors.matchaDarkest,
      onPrimaryContainer: AppColors.matchaLight,
      secondary: AppColors.matchaMedium,
      secondaryContainer: AppColors.darkSurfaceAlt,
      surface: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceAlt,
      onSurface: const Color(0xFFE3F0DE),
      onSurfaceVariant: AppColors.darkOnSurfaceMuted,
      outlineVariant: AppColors.darkSurfaceAlt,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.35),
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(fontSize: 12, color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 3,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      textTheme: const TextTheme().apply(
        fontFamily: 'Roboto',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
