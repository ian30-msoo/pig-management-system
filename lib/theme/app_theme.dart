// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Primary — Dark Navy ───────────────────────────────────────────────────
  static const primary      = Color(0xFF1A1A2E); // deep dark navy (your app color)
  static const primaryDark  = Color(0xFF0F0F1E); // darker navy
  static const primaryLight = Color(0xFF2D2D44); // lighter navy
  static const primaryBg    = Color(0xFFEAEAF0); // very light navy tint

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const dark         = Color(0xFF1A1A2E);
  static const darkMid      = Color(0xFF2D2D44);
  static const offWhite     = Color(0xFFF7F8FA);
  static const cardWhite    = Color(0xFFFFFFFF);
  static const gray100      = Color(0xFFF3F4F6);
  static const gray200      = Color(0xFFE5E7EB);
  static const gray300      = Color(0xFFD1D5DB);
  static const gray400      = Color(0xFF9CA3AF);
  static const gray600      = Color(0xFF4B5563);
  static const gray900      = Color(0xFF111827);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const success      = Color(0xFF10B981);
  static const successBg    = Color(0xFFECFDF5);
  static const warning      = Color(0xFFF59E0B);
  static const warningBg    = Color(0xFFFFFBEB);
  static const danger       = Color(0xFFEF4444);
  static const dangerBg     = Color(0xFFFEF2F2);
  static const blue         = Color(0xFF3B82F6);
  static const blueBg       = Color(0xFFEFF6FF);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary:   AppColors.primary,
        secondary: AppColors.primaryLight,
        surface:   AppColors.cardWhite,
        error:     AppColors.danger,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.offWhite,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation:       0,
        centerTitle:     false,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          textStyle: const TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          textStyle: const TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.primaryLight.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white38,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   14,
        ),
        hintStyle:  const TextStyle(color: AppColors.gray400, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.gray600, fontSize: 12),
      ),

      cardTheme: CardThemeData(
        color:     AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),

      textTheme: const TextTheme(
        headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.dark),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.dark),
        headlineSmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
        titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark),
        titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
        bodyLarge:      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.dark),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.gray600),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.gray400),
        labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
        labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray400),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryBg,
        labelStyle: const TextStyle(
          color:      AppColors.primary,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     AppColors.primary,
        selectedItemColor:   Colors.white,
        unselectedItemColor: AppColors.gray400,
      ),

      dividerTheme: const DividerThemeData(
        color:     AppColors.gray100,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkMid,
        contentTextStyle: const TextStyle(
          color:      Colors.white,
          fontFamily: 'Poppins',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}