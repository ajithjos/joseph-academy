import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'models.dart';
import 'theme_controller.dart';

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

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: brightness,
    ).copyWith(
      primary: const Color(0xFF0F766E),
      secondary: const Color(0xFFD97706),
      surface: isDark ? const Color(0xFF182325) : Colors.white,
      surfaceContainerLow: isDark
          ? const Color(0xFF223235)
          : const Color(0xFFFFFCF6),
      surfaceContainerHigh: isDark
          ? const Color(0xFF293B3F)
          : const Color(0xFFF7F3EA),
      outlineVariant: isDark
          ? const Color(0xFF40555A)
          : const Color(0xFFE2DCCE),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF101A1C)
          : const Color(0xFFF7F3EA),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
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
  final TextEditingController _scoreController = TextEditingController(
    text: '8',
  );
  final TextEditingController _maxScoreController = TextEditingController(
    text: '10',
  );
  final TextEditingController _durationController = TextEditingController(
    text: '15',
  );
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
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final dashboard = await _apiClient.fetchDashboard();
      final catalog = await _apiClient.fetchCatalog();
      final nextLearnerId = preserveSelection && _selectedLearnerId != null
          ? _selectedLearnerId
          : (dashboard.learners.isNotEmpty
                ? dashboard.learners.first.learnerId
                : null);
      LearnerDetailPayload? learnerDetail;
      if (nextLearnerId != null) {
        learnerDetail = await _apiClient.fetchLearnerDetail(nextLearnerId);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _catalog = catalog;
        _selectedLearnerId = nextLearnerId;
        _learnerDetail = learnerDetail;
        _loading = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _selectLearner(String learnerId) async {
    setState(() {
      _selectedLearnerId = learnerId;
      _busy = true;
      _errorMessage = null;
    });
    try {
      final learnerDetail = await _apiClient.fetchLearnerDetail(learnerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _learnerDetail = learnerDetail;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _assignPlan(String planTemplateId) async {
    final learnerId = _selectedLearnerId;
    if (learnerId == null) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      await _apiClient.assignPlan(
        learnerId: learnerId,
        planTemplateId: planTemplateId,
        startDate: today,
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _recordCurrentSession() async {
    final session = _currentActionSession;
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
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
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  SessionDetail? get _currentActionSession {
    final detail = _learnerDetail;
    if (detail == null) {
      return null;
    }
    for (final session in detail.sessions) {
      if (session.status != 'completed') {
        return session;
      }
    }
    return detail.sessions.isNotEmpty ? detail.sessions.first : null;
  }

  String get _contentSiteLabel => Uri.base.resolve('/content/').toString();

  void _setDestination(_ShellDestination destination) {
    setState(() {
      _selectedDestination = destination;
    });
  }

  void _toggleShellNavigation() {
    setState(() {
      _shellNavExpanded = !_shellNavExpanded;
    });
  }

  String _shellUsername() {
    return _dashboard?.team?.displayName ?? 'Cornerstone Owner';
  }

  String _identityInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'CO';
    }
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _openContentSite({bool sameTab = true}) async {
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
      return IconButton(
        tooltip: 'Open content site',
        onPressed: _openContentSite,
        icon: const Icon(Icons.menu_book_rounded),
      );
    }

    return OutlinedButton.icon(
      onPressed: _openContentSite,
      icon: const Icon(Icons.menu_book_rounded, size: 18),
      label: const Text('Content'),
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
        child: const Text('Open content site'),
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
      duration: const Duration(milliseconds: 220),
      width: compact ? 40 : 38,
      height: compact ? 40 : 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.24)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _identityInitials(username),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              avatar,
              if (_shellNavExpanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _setDestination(_ShellDestination.account),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Household workspace',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
    final stripeWidth = _shellNavExpanded ? 164.0 : 48.0;
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
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.62),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.82),
                  ),
                ),
                child: Icon(
                  _shellNavExpanded
                      ? Icons.keyboard_arrow_left_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 20,
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
    final selectedIndex = _ShellDestination.values.indexOf(_selectedDestination);

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _shellNavExpanded ? 236 : 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                  alpha: theme.brightness == Brightness.light ? 0.04 : 0.18,
                ),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  extended: _shellNavExpanded,
                  minWidth: 72,
                  minExtendedWidth: 220,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    _setDestination(_ShellDestination.values[index]);
                  },
                  destinations: _ShellDestination.values
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.icon),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
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
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logo_symbol.png', height: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cornerstone',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _shellUsername(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._ShellDestination.values.map(
              (destination) => ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.label),
                selected: _selectedDestination == destination,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _setDestination(destination);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Open Content Site'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _openContentSite();
              },
            ),
            const SizedBox(height: 12),
            _AppearancePanel(controller: widget.themeController),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(BuildContext context) {
    final dashboard = _dashboard;
    final catalog = _catalog;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: () => _loadAll());
    }
    if (dashboard == null || catalog == null) {
      return const Center(child: Text('No data loaded'));
    }

    switch (_selectedDestination) {
      case _ShellDestination.owner:
        return _buildOwnerView(context, dashboard, catalog);
      case _ShellDestination.learner:
        return _buildLearnerView(context);
      case _ShellDestination.catalog:
        return _buildCatalogView(context, catalog);
      case _ShellDestination.account:
        return _buildAccountView(context, dashboard);
    }
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
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  _identityInitials(username),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      dashboard.team?.description ?? 'Household workspace owner',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
              const SizedBox(height: 14),
              _EndpointTile(
                title: 'Frontend host',
                subtitle: Uri.base.origin,
                actionLabel: 'Refresh',
                onPressed: _busy ? null : () => _loadAll(),
              ),
              _EndpointTile(
                title: 'Content site',
                subtitle: _contentSiteLabel,
                actionLabel: 'Open',
                onPressed: _openContentSite,
              ),
              _EndpointTile(
                title: 'API health',
                subtitle: Uri.base.resolve('/health').toString(),
                actionLabel: 'View',
                onPressed: () async {
                  final ok = await launchUrl(
                    Uri.base.resolve('/health'),
                    webOnlyWindowName: '_blank',
                  );
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Image.asset('assets/images/logo_symbol.png', height: 30),
            const SizedBox(width: 12),
            Image.asset('assets/images/logo_wordmark.png', height: 22),
          ],
        ),
        actions: [
          _buildContentAction(compact: isMobile),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            onPressed: _busy ? null : () => _loadAll(),
            icon: const Icon(Icons.refresh_rounded),
          ),
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

  Widget _buildOwnerView(
    BuildContext context,
    DashboardPayload dashboard,
    CatalogPayload catalog,
  ) {
    final detail = _learnerDetail;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1120;
        final leftPanel = _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.team?.displayName ?? 'Learning Team',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                dashboard.team?.description ?? 'Household learning operations',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatChip(
                    label: 'Capabilities',
                    value: '${dashboard.catalog.capabilityCount}',
                  ),
                  _StatChip(
                    label: 'Plans',
                    value: '${dashboard.catalog.planTemplateCount}',
                  ),
                  _StatChip(
                    label: 'Content',
                    value: '${dashboard.catalog.contentItemCount}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...dashboard.learners.map(
                (learner) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
              ? const Center(
                  child: Text(
                    'Select a learner to inspect plan and review state.',
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
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: leftPanel),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(child: rightPanel),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [leftPanel, const SizedBox(height: 20), rightPanel],
        );
      },
    );
  }

  Widget _buildLearnerView(BuildContext context) {
    final detail = _learnerDetail;
    final session = _currentActionSession;
    final theme = Theme.of(context);
    if (detail == null || session == null) {
      return const Center(
        child: Text('Select a learner with an active session.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _SurfaceCard(
        background: theme.colorScheme.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${detail.learner.displayName} Session',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: session.activities
                  .map(
                    (activity) => Container(
                      width: 280,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.capabilityId,
                            style: const TextStyle(
                              color: Color(0xFFFFD9A3),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activity.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Content: ${activity.contentId}',
                            style: const TextStyle(color: Color(0xFFE7F1EF)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Today: ${session.scheduledDate}',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogView(BuildContext context, CatalogPayload catalog) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catalog Snapshots',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text('Loaded at ${catalog.report.loadedAtUtc}'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatChip(
                    label: 'Capabilities',
                    value: '${catalog.report.capabilityCount}',
                  ),
                  _StatChip(
                    label: 'Milestones',
                    value: '${catalog.report.milestoneCount}',
                  ),
                  _StatChip(
                    label: 'Plans',
                    value: '${catalog.report.planTemplateCount}',
                  ),
                  _StatChip(
                    label: 'Content',
                    value: '${catalog.report.contentItemCount}',
                  ),
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
              Text(
                'Plan Templates',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...catalog.bundle.planTemplates.map(
                (plan) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(plan.title),
                  subtitle: Text(
                    'Age ${plan.recommendedAge} • ${plan.recommendedLevel} • ${plan.durationDays} days',
                  ),
                  trailing: Text('${plan.capabilityIds.length} caps'),
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
              Text(
                'Content Items',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...catalog.bundle.contentItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text('${item.subject} • ${item.kind}'),
                  trailing: Text(item.id),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.learner.displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${detail.learner.currentLevel} • age ${detail.learner.currentAge}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (detail.activePlan != null)
          _Band(
            title: 'Active Plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.activePlan!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${detail.activePlan!.completedSessions}/${detail.activePlan!.totalSessions} sessions complete',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: detail.activePlan!.completionPercent / 100,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _Band(
          title: 'Assign Plan',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: catalog.planTemplates
                .map(
                  (plan) => ActionChip(
                    label: Text(plan.title),
                    onPressed: () => onAssignPlan(plan.planTemplateId),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (currentActionSession != null)
          _Band(
            title: 'Record Current Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentActionSession!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CompactField(label: 'Score', controller: scoreController),
                    _CompactField(
                      label: 'Max Score',
                      controller: maxScoreController,
                    ),
                    _CompactField(
                      label: 'Minutes',
                      controller: durationController,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Session notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onRecordSession,
                  child: const Text('Record session and rebuild review'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _Band(
          title: 'Capability States',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: detail.capabilityStates
                .map(
                  (state) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1EA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.capabilityId,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.status} • ${(state.scoreAverage * 100).round()}% avg',
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        _Band(
          title: 'Review Queue',
          child: detail.reviewQueue.isEmpty
              ? const Text('No pending review items.')
              : Column(
                  children: detail.reviewQueue
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.capabilityId),
                          subtitle: Text(item.reason),
                          trailing: Text(item.dueDate),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({
    required this.learner,
    required this.selected,
    required this.onTap,
  });

  final LearnerCard learner;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE4F3F1) : const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFE5DED1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    learner.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('Age ${learner.currentAge}'),
              ],
            ),
            const SizedBox(height: 6),
            Text(learner.currentLevel),
            const SizedBox(height: 12),
            if (learner.activePlan != null)
              Text(
                'Plan: ${learner.activePlan!.title}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            Text('Review queue: ${learner.reviewQueueCount}'),
            if (learner.todaySession != null) ...[
              const SizedBox(height: 6),
              Text('Next: ${learner.todaySession!.title}'),
            ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
      ),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
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
      width: 140,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
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
                      Text(
                        'Appearance',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        switch (controller.themeMode) {
                          ThemeMode.light => 'Light mode active',
                          ThemeMode.dark => 'Dark mode active',
                          ThemeMode.system => 'Following system theme',
                        },
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 162,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded, size: 15),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded, size: 15),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded, size: 15),
                      ),
                    ],
                    selected: <ThemeMode>{controller.themeMode},
                    onSelectionChanged: (selection) {
                      controller.setThemeMode(selection.first);
                    },
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
