import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the Kinetic Pastel [ThemeData] for light and dark modes.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    final baseText = GoogleFonts.beVietnamProTextTheme();
    final textTheme = baseText.copyWith(
      displayLarge: AppTextStyles.displayLg,
      displayMedium: AppTextStyles.displayLgMobile,
      headlineMedium: AppTextStyles.headlineMd,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.bodyMd,
      labelLarge: AppTextStyles.labelBold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary stays as a lighter mint for contrast on dark surfaces.
      primary: AppColors.inversePrimary,
      onPrimary: AppColors.onPrimaryFixed,
      primaryContainer: Color(0xFF004D3A),
      onPrimaryContainer: AppColors.primaryFixedDim,
      secondary: Color(0xFFC5C5D8),
      onSecondary: AppColors.onSecondaryFixed,
      secondaryContainer: Color(0xFF3A3B4C),
      onSecondaryContainer: AppColors.secondaryFixedDim,
      tertiary: Color(0xFFFFB3B3),
      onTertiary: AppColors.onTertiaryFixed,
      tertiaryContainer: Color(0xFF6D3738),
      onTertiaryContainer: AppColors.tertiaryFixedDim,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0E1413),
      onSurface: Color(0xFFDDE4E6),
      surfaceContainerLowest: Color(0xFF090F10),
      surfaceContainerLow: Color(0xFF161D1F),
      surfaceContainer: Color(0xFF1A2224),
      surfaceContainerHigh: Color(0xFF243030),
      surfaceContainerHighest: Color(0xFF2E3A3C),
      onSurfaceVariant: Color(0xFFBDC9C2),
      outline: Color(0xFF879390),
      outlineVariant: Color(0xFF3E4944),
      inverseSurface: Color(0xFFDDE4E6),
      onInverseSurface: Color(0xFF2B3234),
      inversePrimary: AppColors.primary,
    );

    final baseText = GoogleFonts.beVietnamProTextTheme(
      ThemeData.dark().textTheme,
    );
    final textTheme = baseText.copyWith(
      displayLarge: AppTextStyles.displayLg.copyWith(color: const Color(0xFFDDE4E6)),
      displayMedium: AppTextStyles.displayLgMobile.copyWith(color: const Color(0xFFDDE4E6)),
      headlineMedium: AppTextStyles.headlineMd.copyWith(color: const Color(0xFFDDE4E6)),
      bodyLarge: AppTextStyles.bodyLg.copyWith(color: const Color(0xFFBDC9C2)),
      bodyMedium: AppTextStyles.bodyMd.copyWith(color: const Color(0xFFBDC9C2)),
      labelLarge: AppTextStyles.labelBold.copyWith(color: const Color(0xFFDDE4E6)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E1413),
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: const IconThemeData(color: Color(0xFFBDC9C2)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161D1F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF161D1F),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1A2224),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
