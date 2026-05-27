part of '../../main.dart';

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
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await launchUrl(Uri.base.resolve('/health'), webOnlyWindowName: '_blank');
                  if (!ok && mounted) {
                    messenger.showSnackBar(
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

