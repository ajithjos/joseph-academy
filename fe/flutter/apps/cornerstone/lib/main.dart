import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'models.dart';
import 'theme_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand palette
// ─────────────────────────────────────────────────────────────────────────────

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
  static const Color slateOutline = Color(0xFF3D526E);
  static const Color slateMuted = Color(0xFF8AA0BC);
  static const Color slateText = Color(0xFFEEF2F9);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = CornerstoneThemeController();
  await themeController.load();
  runApp(CornerstoneApp(themeController: themeController));
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
        color: scheme.onSurface, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w700, letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w600, letterSpacing: -0.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w500,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500,
      ),
      displayLarge: base.displayLarge?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w300, letterSpacing: -1.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w300, letterSpacing: -0.5,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: scheme.onSurface, fontWeight: FontWeight.w400,
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
          color: scheme.onSurface, fontWeight: FontWeight.w700,
          fontSize: 18, letterSpacing: -0.1,
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
          fontWeight: FontWeight.w500, fontSize: 13, color: scheme.onSurface,
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
          color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13.5,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 13.5,
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
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? scheme.primary : scheme.secondary,
          backgroundColor: Color.alphaBlend(
            scheme.surface.withValues(alpha: 0.92), scheme.surfaceContainerLow,
          ),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
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
          color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 14,
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

enum _ShellDestination {
  owner('Owner', Icons.dashboard_rounded),
  learner('Learner', Icons.school_rounded),
  catalog('Catalog', Icons.auto_stories_rounded),
  account('My Account', Icons.person_rounded);

  const _ShellDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CornerstoneHomePage extends StatefulWidget {
  const CornerstoneHomePage({required this.themeController, super.key});
  final CornerstoneThemeController themeController;
  @override
  State<CornerstoneHomePage> createState() => _CornerstoneHomePageState();
}

class _CornerstoneHomePageState extends State<CornerstoneHomePage> {
  final CornerstoneApiClient _apiClient = CornerstoneApiClient();
  final TextEditingController _scoreController = TextEditingController(text: '8');
  final TextEditingController _maxScoreController = TextEditingController(text: '10');
  final TextEditingController _durationController = TextEditingController(text: '15');
  final TextEditingController _notesController = TextEditingController(
    text: 'Completed well with one or two slow facts.',
  );

  DashboardPayload? _dashboard;
  CatalogPayload? _catalog;
  LearnerDetailPayload? _learnerDetail;
  String? _selectedLearnerId;
  _ShellDestination _selectedDestination = _ShellDestination.owner;
  bool _shellNavExpanded = true;
  bool _loading = true;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _maxScoreController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool preserveSelection = true}) async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final dashboard = await _apiClient.fetchDashboard();
      final catalog = await _apiClient.fetchCatalog();
      final nextLearnerId = preserveSelection && _selectedLearnerId != null
          ? _selectedLearnerId
          : (dashboard.learners.isNotEmpty ? dashboard.learners.first.learnerId : null);
      LearnerDetailPayload? learnerDetail;
      if (nextLearnerId != null) {
        learnerDetail = await _apiClient.fetchLearnerDetail(nextLearnerId);
      }
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _catalog = catalog;
        _selectedLearnerId = nextLearnerId;
        _learnerDetail = learnerDetail;
        _loading = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loading = false; _busy = false; _errorMessage = error.toString(); });
    }
  }

  Future<void> _selectLearner(String learnerId) async {
    setState(() { _selectedLearnerId = learnerId; _busy = true; _errorMessage = null; });
    try {
      final learnerDetail = await _apiClient.fetchLearnerDetail(learnerId);
      if (!mounted) return;
      setState(() { _learnerDetail = learnerDetail; _busy = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _busy = false; _errorMessage = error.toString(); });
    }
  }

  Future<void> _assignPlan(String planTemplateId) async {
    final learnerId = _selectedLearnerId;
    if (learnerId == null) return;
    setState(() { _busy = true; _errorMessage = null; });
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      await _apiClient.assignPlan(
        learnerId: learnerId,
        planTemplateId: planTemplateId,
        startDate: today,
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      setState(() { _busy = false; _errorMessage = error.toString(); });
    }
  }

  Future<void> _recordCurrentSession() async {
    final session = _currentActionSession;
    if (session == null) return;
    setState(() { _busy = true; _errorMessage = null; });
    try {
      await _apiClient.recordSession(
        sessionId: session.sessionId,
        score: double.parse(_scoreController.text),
        maxScore: double.parse(_maxScoreController.text),
        durationMinutes: int.parse(_durationController.text),
        notes: _notesController.text,
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      setState(() { _busy = false; _errorMessage = error.toString(); });
    }
  }

  SessionDetail? get _currentActionSession {
    final detail = _learnerDetail;
    if (detail == null) return null;
    for (final session in detail.sessions) {
      if (session.status != 'completed') return session;
    }
    return detail.sessions.isNotEmpty ? detail.sessions.first : null;
  }

  String get _contentSiteLabel => Uri.base.resolve('/content/').toString();
  void _setDestination(_ShellDestination d) => setState(() => _selectedDestination = d);
  void _toggleShellNavigation() => setState(() => _shellNavExpanded = !_shellNavExpanded);
  String _shellUsername() => _dashboard?.team?.displayName ?? 'Cornerstone Owner';

  String _identityInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CO';
    if (parts.length == 1) {
      final w = parts.first;
      return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _openContentSite({bool sameTab = false}) async {
    final ok = await launchUrl(
      Uri.base.resolve('/content/'),
      webOnlyWindowName: sameTab ? '_self' : '_blank',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the content site.')),
      );
    }
  }

  Widget _buildContentAction({required bool compact}) {
    if (compact) {
      return IconButton.filledTonal(
        tooltip: 'Open content site',
        onPressed: _openContentSite,
        icon: const Icon(Icons.open_in_new_rounded),
      );
    }
    return OutlinedButton.icon(
      onPressed: _openContentSite,
      icon: const Icon(Icons.open_in_new_rounded, size: 17),
      label: const Text('Content Site'),
    );
  }

  List<Widget> _buildProfileMenuChildren(BuildContext context) {
    return [
      MenuItemButton(
        leadingIcon: const Icon(Icons.person_rounded),
        onPressed: () => _setDestination(_ShellDestination.account),
        child: const Text('My Account'),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Icons.refresh_rounded),
        onPressed: _busy ? null : () => _loadAll(),
        child: const Text('Refresh data'),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Icons.menu_book_rounded),
        onPressed: _openContentSite,
        child: const Text('Open content site in new tab'),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Divider(height: 18),
      ),
      SizedBox(width: 284, child: _AppearancePanel(controller: widget.themeController)),
    ];
  }

  Widget _buildProfileMenuAnchor({required bool compact}) {
    final theme = Theme.of(context);
    final selected = _selectedDestination == _ShellDestination.account;
    final username = _shellUsername();

    final avatar = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: compact ? 40 : 36,
      height: compact ? 40 : 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? const LinearGradient(
                colors: [_BrandPalette.goldBright, _BrandPalette.goldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : theme.colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.30)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.50),
          width: selected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _identityInitials(username),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return MenuAnchor(
      menuChildren: _buildProfileMenuChildren(context),
      builder: (context, controller, _) {
        if (compact) {
          return Tooltip(
            message: username,
            child: IconButton(
              tooltip: 'Profile menu',
              onPressed: () => controller.isOpen ? controller.close() : controller.open(),
              icon: avatar,
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
          ),
          child: Row(
            children: [
              avatar,
              if (_shellNavExpanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _setDestination(_ShellDestination.account),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Household workspace',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              IconButton(
                tooltip: 'Profile menu',
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShellRailToggle(ThemeData theme) {
    final stripeWidth = _shellNavExpanded ? 144.0 : 48.0;
    return GestureDetector(
      onTap: _toggleShellNavigation,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: stripeWidth,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: stripeWidth,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  _shellNavExpanded ? Icons.keyboard_arrow_left_rounded : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopShell(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedIndex = _ShellDestination.values.indexOf(_selectedDestination);

    final panelColor = isDark
        ? _BrandPalette.slatePanel
        : Color.alphaBlend(
            theme.colorScheme.secondary.withValues(alpha: 0.028),
            _BrandPalette.warmPaper,
          );

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _shellNavExpanded ? 224 : 84,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? _BrandPalette.slateBorder : theme.colorScheme.primary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                _NavBrandHeader(expanded: _shellNavExpanded),
                Expanded(
                  child: NavigationRail(
                    leading: const SizedBox(height: 4),
                    backgroundColor: Colors.transparent,
                    extended: _shellNavExpanded,
                    minWidth: 64,
                    minExtendedWidth: 194,
                    groupAlignment: -0.8,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _setDestination(_ShellDestination.values[index]),
                    destinations: _ShellDestination.values.map(
                      (d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                    ).toList(growable: false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShellRailToggle(theme),
                      const SizedBox(height: 10),
                      Center(child: _buildContentAction(compact: !_shellNavExpanded)),
                      const SizedBox(height: 10),
                      _buildProfileMenuAnchor(compact: !_shellNavExpanded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? _BrandPalette.slatePanel : _BrandPalette.warmPaper,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                color: isDark ? _BrandPalette.slateRaised : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandLockup(mobileVariant: true),
                  const SizedBox(height: 16),
                  Text(_shellUsername(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Household workspace', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._ShellDestination.values.map(
              (d) => ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                selected: _selectedDestination == d,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () { Navigator.of(context).pop(); _setDestination(d); },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Open Content Site'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onTap: () { Navigator.of(context).pop(); _openContentSite(); },
            ),
            const SizedBox(height: 16),
            _AppearancePanel(controller: widget.themeController),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(BuildContext context) {
    final dashboard = _dashboard;
    final catalog = _catalog;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _ErrorState(message: _errorMessage!, onRetry: () => _loadAll());
    if (dashboard == null || catalog == null) return const Center(child: Text('No data loaded'));
    return switch (_selectedDestination) {
      _ShellDestination.owner => _buildOwnerView(context, dashboard, catalog),
      _ShellDestination.learner => _buildLearnerView(context),
      _ShellDestination.catalog => _buildCatalogView(context, catalog),
      _ShellDestination.account => _buildAccountView(context, dashboard),
    };
  }

  Widget _buildAccountView(BuildContext context, DashboardPayload dashboard) {
    final theme = Theme.of(context);
    final username = _shellUsername();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SurfaceCard(
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_BrandPalette.goldBright, _BrandPalette.goldDeep],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _identityInitials(username),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: _BrandPalette.navy),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 5),
                    Text(
                      dashboard.team?.description ?? 'Household workspace owner',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(child: _AppearancePanel(controller: widget.themeController)),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workspace Links', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              _EndpointTile(
                title: 'Frontend host', subtitle: Uri.base.origin,
                actionLabel: 'Refresh', onPressed: _busy ? null : () => _loadAll(),
              ),
              _EndpointTile(
                title: 'Content site', subtitle: _contentSiteLabel,
                actionLabel: 'Open', onPressed: _openContentSite,
              ),
              _EndpointTile(
                title: 'API health',
                subtitle: Uri.base.resolve('/health').toString(),
                actionLabel: 'View',
                onPressed: () async {
                  final ok = await launchUrl(Uri.base.resolve('/health'), webOnlyWindowName: '_blank');
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unable to open /health.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        title: _BrandLockup(
          compact: isMobile, toolbarVariant: true,
          onTap: () => _setDestination(_ShellDestination.owner),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                theme.colorScheme.outlineVariant.withValues(alpha: 0.0),
                theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                theme.colorScheme.outlineVariant.withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
        actions: [
          _buildContentAction(compact: isMobile),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(onPressed: _busy ? null : () => _loadAll(), icon: const Icon(Icons.refresh_rounded)),
          if (isMobile) _buildProfileMenuAnchor(compact: true),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildDesktopShell(context),
          Expanded(child: _buildContentBody(context)),
        ],
      ),
    );
  }

  Widget _buildOwnerView(BuildContext context, DashboardPayload dashboard, CatalogPayload catalog) {
    final detail = _learnerDetail;
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 1120;
      final leftPanel = _SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dashboard.team?.displayName ?? 'Learning Team', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              dashboard.team?.description ?? 'Household learning operations',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                _StatChip(label: 'Capabilities', value: '${dashboard.catalog.capabilityCount}', icon: Icons.extension_rounded),
                _StatChip(label: 'Plans', value: '${dashboard.catalog.planTemplateCount}', icon: Icons.assignment_rounded),
                _StatChip(label: 'Content', value: '${dashboard.catalog.contentItemCount}', icon: Icons.menu_book_rounded),
              ],
            ),
            const SizedBox(height: 24),
            _GoldAccentDivider(),
            const SizedBox(height: 18),
            Text(
              'Learners',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...dashboard.learners.map(
              (learner) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _LearnerCard(
                  learner: learner,
                  selected: learner.learnerId == _selectedLearnerId,
                  onTap: () => _selectLearner(learner.learnerId),
                ),
              ),
            ),
          ],
        ),
      );
      final rightPanel = _SurfaceCard(
        child: detail == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search_rounded, size: 52,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
                      const SizedBox(height: 16),
                      Text(
                        'Select a learner to inspect\nplan and review state.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            : _LearnerOperationsPanel(
                detail: detail,
                catalog: catalog.bundle,
                currentActionSession: _currentActionSession,
                scoreController: _scoreController,
                maxScoreController: _maxScoreController,
                durationController: _durationController,
                notesController: _notesController,
                onAssignPlan: _assignPlan,
                onRecordSession: _recordCurrentSession,
              ),
      );
      if (wide) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: SingleChildScrollView(child: leftPanel)),
              const SizedBox(width: 20),
              Expanded(flex: 6, child: SingleChildScrollView(child: rightPanel)),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [leftPanel, const SizedBox(height: 20), rightPanel],
      );
    });
  }

  Widget _buildLearnerView(BuildContext context) {
    final detail = _learnerDetail;
    final session = _currentActionSession;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (detail == null || session == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, size: 56,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 20),
              Text(
                'Select a learner with an active session.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2A1F00), _BrandPalette.slateRaised]
                : [const Color(0xFFFFF8E0), const Color(0xFFF5ECD6)],
          ),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 32, offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    'ACTIVE SESSION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Spacer(),
                Text(session.scheduledDate, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              detail.learner.displayName,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary, letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(session.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14, runSpacing: 14,
              children: session.activities.map((activity) => Container(
                width: 280,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.20)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.capabilityId,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(activity.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Content: ${activity.contentId}', style: theme.textTheme.bodySmall),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogView(BuildContext context, CatalogPayload catalog) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catalog Snapshot', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('Loaded at ${catalog.report.loadedAtUtc}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: [
                  _StatChip(label: 'Capabilities', value: '${catalog.report.capabilityCount}', icon: Icons.extension_rounded),
                  _StatChip(label: 'Milestones', value: '${catalog.report.milestoneCount}', icon: Icons.flag_rounded),
                  _StatChip(label: 'Plans', value: '${catalog.report.planTemplateCount}', icon: Icons.assignment_rounded),
                  _StatChip(label: 'Content', value: '${catalog.report.contentItemCount}', icon: Icons.menu_book_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan Templates', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              ...catalog.bundle.planTemplates.map(
                (plan) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(plan.title),
                  subtitle: Text(
                    'Age ${plan.recommendedAge} · ${plan.recommendedLevel} · ${plan.durationDays} days',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: _PillBadge(
                    text: '${plan.capabilityIds.length} caps',
                    color: theme.colorScheme.secondaryContainer,
                    textColor: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Content Items', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              ...catalog.bundle.contentItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text('${item.subject} · ${item.kind}', style: theme.textTheme.bodySmall),
                  trailing: Text(item.id, style: theme.textTheme.labelSmall),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearnerOperationsPanel extends StatelessWidget {
  const _LearnerOperationsPanel({
    required this.detail,
    required this.catalog,
    required this.currentActionSession,
    required this.scoreController,
    required this.maxScoreController,
    required this.durationController,
    required this.notesController,
    required this.onAssignPlan,
    required this.onRecordSession,
  });

  final LearnerDetailPayload detail;
  final CatalogBundle catalog;
  final SessionDetail? currentActionSession;
  final TextEditingController scoreController;
  final TextEditingController maxScoreController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final ValueChanged<String> onAssignPlan;
  final VoidCallback onRecordSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.learner.displayName, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _PillBadge(
              text: detail.learner.currentLevel,
              color: theme.colorScheme.secondaryContainer,
              textColor: theme.colorScheme.onSecondaryContainer,
            ),
            _PillBadge(
              text: 'Age ${detail.learner.currentAge}',
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              textColor: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (detail.activePlan != null) ...[
          _Band(
            title: 'Active Plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.activePlan!.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: detail.activePlan!.completionPercent / 100),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${detail.activePlan!.completedSessions}/${detail.activePlan!.totalSessions}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${detail.activePlan!.completedSessions} of ${detail.activePlan!.totalSessions} sessions complete',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Band(
          title: 'Assign Plan',
          child: Wrap(
            spacing: 10, runSpacing: 10,
            children: catalog.planTemplates.map(
              (plan) => ActionChip(
                label: Text(plan.title),
                onPressed: () => onAssignPlan(plan.planTemplateId),
              ),
            ).toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (currentActionSession != null) ...[
          _Band(
            title: 'Record Current Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentActionSession!.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    _CompactField(label: 'Score', controller: scoreController),
                    _CompactField(label: 'Max Score', controller: maxScoreController),
                    _CompactField(label: 'Minutes', controller: durationController),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  minLines: 2, maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Session notes'),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRecordSession,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Record session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Band(
          title: 'Capability States',
          child: Wrap(
            spacing: 10, runSpacing: 10,
            children: detail.capabilityStates.map((s) => _CapabilityStateChip(state: s)).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _Band(
          title: 'Review Queue',
          child: detail.reviewQueue.isEmpty
              ? Row(children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text('No pending review items.'),
                ])
              : Column(
                  children: detail.reviewQueue.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.capabilityId),
                      subtitle: Text(item.reason, style: Theme.of(context).textTheme.bodySmall),
                      trailing: _PillBadge(
                        text: item.dueDate,
                        color: Theme.of(context).colorScheme.errorContainer,
                        textColor: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ).toList(),
                ),
        ),
      ],
    );
  }
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({required this.learner, required this.selected, required this.onTap});
  final LearnerCard learner;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? isDark
                    ? Color.alphaBlend(_BrandPalette.goldBright.withValues(alpha: 0.08), _BrandPalette.slateRaised)
                    : Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.10), Colors.white)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: selected ? theme.colorScheme.primary : Colors.transparent, width: 3),
            top: BorderSide(color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.36)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.70)),
            right: BorderSide(color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.36)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.70)),
            bottom: BorderSide(color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.36)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.70)),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 20 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(learner.displayName, style: theme.textTheme.titleLarge)),
                _PillBadge(
                  text: 'Age ${learner.currentAge}',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(learner.currentLevel,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (learner.activePlan != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.assignment_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      learner.activePlan!.title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pending_actions_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Review: ${learner.reviewQueueCount}', style: theme.textTheme.bodySmall),
                if (learner.todaySession != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.today_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(learner.todaySession!.title, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.background});
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: isDark ? 24 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: background == null && isDark
          ? DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x0AFFFFFF), Colors.transparent],
                  stops: [0.0, 0.25],
                ),
              ),
              child: child,
            )
          : child,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.60)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: -0.3,
                ),
              ),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label)),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateRaised : const Color(0xFFFCF8EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3, height: 20,
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.text, required this.color, required this.textColor});
  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CapabilityStateChip extends StatelessWidget {
  const _CapabilityStateChip({required this.state});
  final CapabilityStateSummary state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = (state.scoreAverage * 100).round();
    final isStrong = pct >= 80;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateHigh : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStrong
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.capabilityId,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isStrong ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text('${state.status} · ${pct}% avg', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _GoldAccentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.0),
            theme.colorScheme.primary.withValues(alpha: 0.55),
            theme.colorScheme.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: theme.colorScheme.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, size: 40, color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBrandHeader extends StatelessWidget {
  const _NavBrandHeader({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(expanded ? 18 : 12, 18, expanded ? 18 : 12, 0),
      child: Column(
        crossAxisAlignment: expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandSymbol(size: expanded ? 34 : 28),
              if (expanded) ...[const SizedBox(width: 10), const _BrandWordmark(height: 19)],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                  theme.colorScheme.primary.withValues(alpha: 0.60),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({
    this.compact = false,
    this.toolbarVariant = false,
    this.shellVariant = false,
    this.mobileVariant = false,
    this.onTap,
  });
  final bool compact;
  final bool toolbarVariant;
  final bool shellVariant;
  final bool mobileVariant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbolSize = toolbarVariant ? (compact ? 28.0 : 32.0) : (compact ? 36.0 : 44.0);
    final wordmarkHeight = toolbarVariant ? (compact ? 16.0 : 20.0) : (compact ? 20.0 : 26.0);
    final padding = toolbarVariant
        ? (compact ? const EdgeInsets.fromLTRB(6, 4, 10, 4) : const EdgeInsets.fromLTRB(8, 5, 12, 5))
        : compact ? const EdgeInsets.fromLTRB(8, 6, 10, 6) : const EdgeInsets.fromLTRB(10, 8, 14, 8);
    final radius = toolbarVariant ? 14.0 : (shellVariant ? 18.0 : 16.0);

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateRaised : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _BrandPalette.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? (toolbarVariant ? 0.20 : 0.24) : (toolbarVariant ? 0.06 : 0.09),
            ),
            blurRadius: toolbarVariant ? 10 : 14,
            offset: Offset(0, toolbarVariant ? 4 : 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandSymbol(size: symbolSize),
          if (!compact || mobileVariant) ...[
            SizedBox(width: compact ? 6 : 8),
            _BrandWordmark(height: wordmarkHeight),
          ],
        ],
      ),
    );

    if (onTap == null) return badge;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: badge),
    );
  }
}

class _BrandSymbol extends StatelessWidget {
  const _BrandSymbol({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.24)),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        minWidth: size * 1.84, minHeight: size * 1.84,
        maxWidth: size * 1.84, maxHeight: size * 1.84,
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/logo_symbol.png',
          width: size * 1.84, height: size * 1.84,
          fit: BoxFit.cover, filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Image.asset(
        'assets/images/logo_wordmark.png',
        fit: BoxFit.fitHeight, filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel({required this.controller});
  final CornerstoneThemeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Appearance', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                        switch (controller.themeMode) {
                          ThemeMode.light => 'Light mode active',
                          ThemeMode.dark => 'Dark mode active',
                          ThemeMode.system => 'Following system theme',
                        },
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 162,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 15)),
                      ButtonSegment<ThemeMode>(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 15)),
                      ButtonSegment<ThemeMode>(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 15)),
                    ],
                    selected: <ThemeMode>{controller.themeMode},
                    onSelectionChanged: (s) => controller.setThemeMode(s.first),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.tonal(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
