import 'package:flutter/material.dart';

/// Warm, light, high-contrast theme. Every text style is at least 18 sp and
/// every button at least 56 dp tall.
class AppColors {
  static const cream = Color(0xFFFFF8E7);
  static const creamDark = Color(0xFFF6E7C1);
  static const gold = Color(0xFFC8901A);
  static const deepGold = Color(0xFF7A4F00);
  static const brown = Color(0xFF3B2412);
  static const whatsapp = Color(0xFF1B7F45);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.deepGold,
    onPrimary: Colors.white,
    secondary: AppColors.gold,
    surface: AppColors.cream,
    onSurface: AppColors.brown,
    surfaceContainerHighest: AppColors.creamDark,
    outline: const Color(0xFF8C6A3F),
  );

  const minButton = Size(64, 56);
  const buttonText = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);

  final text = const TextTheme(
    displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 20),
    bodyMedium: TextStyle(fontSize: 19),
    bodySmall: TextStyle(fontSize: 18),
    labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 18),
  ).apply(bodyColor: AppColors.brown, displayColor: AppColors.brown);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.brown,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.brown),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        textStyle: buttonText,
        padding: buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        textStyle: buttonText,
        padding: buttonPadding,
        foregroundColor: AppColors.brown,
        side: const BorderSide(color: AppColors.deepGold, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minButton,
        textStyle: buttonText,
        foregroundColor: AppColors.deepGold,
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.brown),
      secondaryLabelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      selectedColor: AppColors.deepGold,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      side: const BorderSide(color: AppColors.deepGold, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(fontSize: 20),
      hintStyle: const TextStyle(fontSize: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 14,
      titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.brown),
      subtitleTextStyle: TextStyle(fontSize: 18, color: Color(0xFF5C4128)),
      iconColor: AppColors.deepGold,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.deepGold,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.whatsapp : AppColors.creamDark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.creamDark,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 18,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.brown,
        ),
      ),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 30, color: AppColors.brown)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      labelColor: AppColors.brown,
      unselectedLabelColor: Color(0xFF6B4E2E),
      indicatorColor: AppColors.deepGold,
    ),
    snackBarTheme: const SnackBarThemeData(
      contentTextStyle: TextStyle(fontSize: 19, color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
