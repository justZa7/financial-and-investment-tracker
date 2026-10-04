import 'package:flutter/material.dart';

/// Palet warna "Matcha Latte" — hangat & creamy (bukan hijau pastel dingin),
/// jadi basis identitas visual MatchaFin.
///
/// Nama field SENGAJA dipertahankan sama seperti versi sebelumnya (dipakai
/// di puluhan widget lain) — yang berubah cuma NILAI warnanya, supaya efek
/// re-theme ini otomatis menyebar ke seluruh app tanpa perlu sentuh file lain.
class AppColors {
  AppColors._();

  // --- Palet Matcha Latte inti ---
  // matchaDarkest : hijau matcha pekat (bubuk matcha diseduh kental) — dipakai
  //                 untuk primary/brand color, ikon, teks penting.
  // matchaDark    : hijau matcha inti (warna "badan" matcha latte) — warna
  //                 utama untuk tombol & aksen brand.
  // matchaMedium  : hijau sage medium — aksen sekunder.
  // matchaLight   : hijau sage lembut — aksen tersier/highlight.
  // matchaPale    : hijau sage pudar kehijauan-krem — dasar container/badge.
  // matchaBg      : krem oat-milk hangat (BUKAN putih/mint pucat) — warna
  //                 "susu"-nya matcha latte, dipakai scaffold background.
  static const matchaDarkest = Color(0xFF34502B);
  static const matchaDark = Color(0xFF5C7A45);
  static const matchaMedium = Color(0xFF7D9B5E);
  static const matchaLight = Color(0xFFA8BE8A);
  static const matchaPale = Color(0xFFD9DEC2);
  static const matchaBg = Color(0xFFF1EADA);

  /// Warna "foam" — krem keputihan hangat dipakai untuk Card/Surface di
  /// light mode, menggantikan putih polos supaya nuansa latte kerasa
  /// sampai ke permukaan kartu, bukan cuma di background.
  static const latteFoam = Color(0xFFFBF6EB);

  // --- Dark mode: "iced matcha latte" di ruangan gelap ---
  static const darkBg = Color(0xFF171C12);
  static const darkSurface = Color(0xFF212819);
  static const darkSurfaceAlt = Color(0xFF2B3421);
  static const darkOnSurfaceMuted = Color(0xFFB7C4A0);

  // --- Warna semantik (gain/loss & kelas aset), diselaraskan ke nuansa
  // matcha-latte yang hangat alih-alih biru/ungu/hijau-mint terang ---
  static const gain = matchaDark;
  static const loss = Color(0xFFB9502B); // terracotta hangat (karamel gosong)
  static const equity = matchaDarkest;
  static const gold = Color(0xFFC49A3A); // karamel/gula aren
  static const crypto = Color(0xFF8A6A4E); // mocha-coffee brown
  static const moneyMarket = Color(0xFF5E8270); // sage-teal pekat
  static const cash = Color(0xFF9C8E72); // taupe foam latte
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.matchaDark,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.matchaDarkest,
      onPrimary: AppColors.latteFoam,
      primaryContainer: AppColors.matchaPale,
      onPrimaryContainer: AppColors.matchaDarkest,
      secondary: AppColors.matchaMedium,
      secondaryContainer: AppColors.matchaLight,
      // Surface pakai warna "foam" hangat, BUKAN putih polos — di sinilah
      // nuansa "latte" paling kerasa karena hampir semua Card pakai warna ini.
      surface: AppColors.latteFoam,
      surfaceContainerHighest: AppColors.matchaPale.withOpacity(0.6),
      onSurface: const Color(0xFF28311F),
      onSurfaceVariant: const Color(0xFF6B6350), // teks sekunder: coklat-taupe hangat
      outlineVariant: const Color(0xFFE2D7BE), // border krem hangat
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
        shadowColor: AppColors.matchaDarkest.withOpacity(0.12),
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
      onSurface: const Color(0xFFE8E4D4),
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
