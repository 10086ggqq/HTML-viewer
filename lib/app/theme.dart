import 'package:flutter/material.dart';

import '../features/settings/settings_model.dart';
import 'chest_page_transition.dart';

/// Minecraft-inspired color palette.
///
/// Only the "block world" visual language is used; nothing copies official
/// game assets.
class McColors {
  const McColors._();

  // Brand colors shared across themes.
  static const grass = Color(0xFF6FBF4A);
  static const grassDark = Color(0xFF4E8A2E);
  static const diamond = Color(0xFF3EC7C0);
  static const gold = Color(0xFFF2C14E);
  static const redstone = Color(0xFFD9483F);

  // Light theme.
  static const lightBackground = Color(0xFFF5F3EA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightOutline = Color(0xFFC9C2AD);

  // Dark theme.
  static const darkBackground = Color(0xFF101411);
  static const darkCard = Color(0xFF181D19);
  static const darkOutline = Color(0xFF39423A);
}

/// Builds the app theme for [brightness], customized by [settings].
ThemeData buildTheme(Brightness brightness, Settings settings) {
  final dark = brightness == Brightness.dark;

  final primary = dark ? const Color(0xFF8ED468) : McColors.grass;
  final onPrimary = dark ? const Color(0xFF0B1408) : Colors.white;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: dark ? const Color(0xFF2E4A1F) : const Color(0xFFDDF0CE),
    onPrimaryContainer:
        dark ? const Color(0xFFC8F0A8) : const Color(0xFF1C3A0C),
    secondary: McColors.diamond,
    onSecondary: dark ? const Color(0xFF04211F) : Colors.white,
    secondaryContainer:
        dark ? const Color(0xFF0F3E3B) : const Color(0xFFD3F5F2),
    onSecondaryContainer:
        dark ? const Color(0xFFA5F0EA) : const Color(0xFF08302D),
    surface: dark ? McColors.darkBackground : McColors.lightBackground,
    onSurface: dark ? const Color(0xFFE4E7E0) : const Color(0xFF1E2117),
    surfaceContainerHighest:
        dark ? const Color(0xFF232A24) : const Color(0xFFEDEAE0),
    onSurfaceVariant: dark ? const Color(0xFFB7BDB2) : const Color(0xFF5A5F52),
    error: McColors.redstone,
    onError: Colors.white,
    outline: dark ? McColors.darkOutline : McColors.lightOutline,
    outlineVariant: dark ? McColors.darkOutline : McColors.lightOutline,
  );

  final typography = Typography.material2021();
  var textTheme = (dark ? typography.white : typography.black)
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  if (settings.pixelFont) {
    textTheme = _applyPixelDisplayFont(textTheme);
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: settings.animations
          ? const {
              TargetPlatform.android: ChestPageTransitionsBuilder(),
              TargetPlatform.iOS: ChestPageTransitionsBuilder(),
            }
          : const {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
    ),
    splashFactory:
        settings.animations ? InkSparkle.splashFactory : NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? McColors.darkCard : McColors.lightCard,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : (dark ? const Color(0xFFB7BDB2) : const Color(0xFF9A9E8F)),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : (dark ? McColors.darkOutline : McColors.lightOutline),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: dark ? McColors.darkOutline : McColors.lightOutline,
      thumbColor: McColors.diamond,
      overlayColor: const Color(0x263EC7C0),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(
            color: dark ? McColors.darkOutline : McColors.lightOutline,
          ),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: dark ? McColors.darkOutline : McColors.lightOutline,
      thickness: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF2A2E28),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// Applies the bundled pixel font (Press Start 2P) to display/title styles.
///
/// The pixel font has no CJK glyphs, so Chinese text falls back to the system
/// font automatically — mixing both is intentional.
TextTheme _applyPixelDisplayFont(TextTheme base) {
  TextStyle pixel(TextStyle? style) {
    if (style == null) return const TextStyle(fontFamily: 'PressStart2P');
    return style.copyWith(
      fontFamily: 'PressStart2P',
      fontSize: (style.fontSize ?? 14) * 0.68,
      height: 1.4,
    );
  }

  return base.copyWith(
    displayLarge: pixel(base.displayLarge),
    displayMedium: pixel(base.displayMedium),
    displaySmall: pixel(base.displaySmall),
    headlineLarge: pixel(base.headlineLarge),
    headlineMedium: pixel(base.headlineMedium),
    headlineSmall: pixel(base.headlineSmall),
    titleLarge: pixel(base.titleLarge),
    titleMedium: pixel(base.titleMedium),
  );
}
