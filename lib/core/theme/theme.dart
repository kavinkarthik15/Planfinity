import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFF00C9A7);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFB020);
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF60A5FA);

  static const background = Color(0xFF0F172A);
  static const card = Color(0xFF1E293B);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
}

class AppTextStyles {
  static const headline = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}

class AppRadius {
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(20));
}

class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,

    textTheme: TextTheme(
      headlineLarge: AppTextStyles.headline,
      titleMedium: AppTextStyles.title,
      bodyMedium: AppTextStyles.body,
    ),

    cardColor: AppColors.card,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
    ),

    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
    ),
  );
}
