import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Poppins';

  static ThemeData get light {
    const baseTextTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily),
      displayMedium: TextStyle(fontFamily: fontFamily),
      displaySmall: TextStyle(fontFamily: fontFamily),
      headlineLarge: TextStyle(fontFamily: fontFamily),
      headlineMedium: TextStyle(fontFamily: fontFamily),
      headlineSmall: TextStyle(fontFamily: fontFamily),
      titleLarge: TextStyle(fontFamily: fontFamily),
      titleMedium: TextStyle(fontFamily: fontFamily),
      titleSmall: TextStyle(fontFamily: fontFamily),
      bodyLarge: TextStyle(fontFamily: fontFamily),
      bodyMedium: TextStyle(fontFamily: fontFamily),
      bodySmall: TextStyle(fontFamily: fontFamily),
      labelLarge: TextStyle(fontFamily: fontFamily),
      labelMedium: TextStyle(fontFamily: fontFamily),
      labelSmall: TextStyle(fontFamily: fontFamily),
    );

    return ThemeData(
      useMaterial3: false,
      fontFamily: fontFamily,
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Color(0xFF9A9A9A),
          fontSize: 15,
        ),
      ),
    );
  }
}
