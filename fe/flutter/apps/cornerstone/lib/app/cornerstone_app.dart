part of '../main.dart';

// Brand palette

class _BrandPalette {
  // Core brand colours (drawn from the stone-block logo)
  static const Color gold = Color(0xFFD5A11E);
  static const Color goldBright = Color(0xFFF0BE3A);
  static const Color goldDeep = Color(0xFFA97C0A);
  static const Color navy = Color(0xFF16263B);

  // Light mode: warm limestone
  static const Color limestone = Color(0xFFF0E8D4);
  static const Color warmPaper = Color(0xFFFDFAF0);
  static const Color warmWhite = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFE3D1A5);
  static const Color navySoft = Color(0xFFDDE7F5);

  // Dark mode: volcanic slate
  static const Color obsidian = Color(0xFF0D1119);
  static const Color slatePanel = Color(0xFF131A26);
  static const Color slateCard = Color(0xFF192030);
  static const Color slateRaised = Color(0xFF1C2538);
  static const Color slateHigh = Color(0xFF222E44);
  static const Color slateBorder = Color(0xFF28384F);
  static const Color slateMuted = Color(0xFF8AA0BC);
  static const Color slateText = Color(0xFFEEF2F9);
}

class CornerstoneApp extends StatelessWidget {
  const CornerstoneApp({required this.themeController, super.key});

  final CornerstoneThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Cornerstone',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeController.themeMode,
          home: CornerstoneHomePage(themeController: themeController),
        );
      },
    );
  }

  TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      displayLarge: base.displayLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: _BrandPalette.gold,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? _BrandPalette.goldBright : _BrandPalette.gold,
      onPrimary: _BrandPalette.navy,
      primaryContainer: isDark ? const Color(0xFF3A2A04) : const Color(0xFFFFF3D0),
      onPrimaryContainer: isDark ? const Color(0xFFFFE0A0) : _BrandPalette.navy,
      secondary: _BrandPalette.navy,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? _BrandPalette.slateHigh : _BrandPalette.navySoft,
      onSecondaryContainer: isDark ? _BrandPalette.slateText : _BrandPalette.navy,
      tertiary: isDark ? _BrandPalette.goldBright : const Color(0xFFEDC463),
      onTertiary: _BrandPalette.navy,
      surface: isDark ? _BrandPalette.slateCard : _BrandPalette.warmWhite,
      surfaceContainerLow: isDark ? _BrandPalette.slatePanel : _BrandPalette.warmPaper,
      surfaceContainerHigh: isDark ? _BrandPalette.slateHigh : const Color(0xFFF5ECD8),
      outlineVariant: isDark ? _BrandPalette.slateBorder : _BrandPalette.sand,
      surfaceTint: isDark ? _BrandPalette.goldBright : _BrandPalette.gold,
      onSurface: isDark ? _BrandPalette.slateText : _BrandPalette.navy,
      onSurfaceVariant: isDark ? _BrandPalette.slateMuted : const Color(0xFF5A6B82),
      error: isDark ? const Color(0xFFFF8A80) : const Color(0xFFB00020),
      onError: isDark ? Colors.black : Colors.white,
    );

    final textTheme = _buildTextTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? _BrandPalette.obsidian : _BrandPalette.limestone,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.1,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.54),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _BrandPalette.slateHigh : _BrandPalette.warmWhite,
        selectedColor: isDark
            ? _BrandPalette.goldBright.withValues(alpha: 0.20)
            : _BrandPalette.gold.withValues(alpha: 0.14),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: scheme.onSurface,
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.72)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? _BrandPalette.goldBright : _BrandPalette.gold,
        linearTrackColor: isDark ? _BrandPalette.slateBorder : _BrandPalette.sand,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(6),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        useIndicator: true,
        indicatorColor: isDark
            ? Color.alphaBlend(
                _BrandPalette.goldBright.withValues(alpha: 0.14),
                _BrandPalette.slateRaised,
              )
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.12),
                scheme.surfaceContainerLow,
              ),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 21),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedColor: isDark ? scheme.primary : scheme.secondary,
        selectedTileColor: isDark
            ? Color.alphaBlend(
                _BrandPalette.goldBright.withValues(alpha: 0.10),
                scheme.surfaceContainerLow,
              )
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.09),
                scheme.surface,
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? scheme.primary : scheme.secondary,
          foregroundColor: isDark ? scheme.onPrimary : scheme.onSecondary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? scheme.primary : scheme.secondary,
          backgroundColor: Color.alphaBlend(
            scheme.surface.withValues(alpha: 0.92),
            scheme.surfaceContainerLow,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.46)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return scheme.surface;
          }),
          side: WidgetStateProperty.resolveWith(
            (_) => BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.68)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _BrandPalette.slateRaised : const Color(0xFFFCF8EE),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _BrandPalette.slateHigh : _BrandPalette.navy,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}