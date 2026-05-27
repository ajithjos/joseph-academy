part of '../../main.dart';

enum _ShellDestination {
  owner('Owner', 'Manage learners, assignments, and household progress.', Icons.dashboard_rounded),
  learner('Learner', 'Follow today\'s active session and material sequence.', Icons.school_rounded),
  catalog('Catalog', 'Browse subjects, stages, playlists, and materials.', Icons.auto_stories_rounded),
  account('My Account', 'Adjust appearance and workspace links.', Icons.person_rounded);

  const _ShellDestination(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
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
  final TextEditingController _notesController = TextEditingController(text: 'Completed well with one or two slow facts.');

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
      if (!mounted) return;
      setState(() {
        _learnerDetail = learnerDetail;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _createAssignment(String playlistId) async {
    final learnerId = _selectedLearnerId;
    if (learnerId == null) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      await _apiClient.createAssignment(
        learnerId: learnerId,
        playlistId: playlistId,
        startDate: today,
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _recordCurrentSession() async {
    final session = _currentActionSession;
    if (session == null) return;
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
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
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
    final ok = await launchUrl(Uri.base.resolve('/content/'), webOnlyWindowName: sameTab ? '_self' : '_blank');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open the content site.')));
    }
  }

  Widget _buildContentAction({required bool compact}) {
    if (compact) {
      return IconButton.filledTonal(tooltip: 'Open content site', onPressed: _openContentSite, icon: const Icon(Icons.open_in_new_rounded));
    }
    return OutlinedButton.icon(onPressed: _openContentSite, icon: const Icon(Icons.open_in_new_rounded, size: 17), label: const Text('Content Site'));
  }

  List<Widget> _buildProfileMenuChildren(BuildContext context) {
    return [
      MenuItemButton(leadingIcon: const Icon(Icons.person_rounded), onPressed: () => _setDestination(_ShellDestination.account), child: const Text('My Account')),
      MenuItemButton(leadingIcon: const Icon(Icons.refresh_rounded), onPressed: _busy ? null : () => _loadAll(), child: const Text('Refresh data')),
      MenuItemButton(leadingIcon: const Icon(Icons.menu_book_rounded), onPressed: _openContentSite, child: const Text('Open content site in new tab')),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Divider(height: 18)),
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
            ? const LinearGradient(colors: [_BrandPalette.goldBright, _BrandPalette.goldDeep], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: selected ? null : theme.colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.30) : theme.colorScheme.outlineVariant.withValues(alpha: 0.50),
          width: selected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _identityInitials(username),
        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
      ),
    );

    return MenuAnchor(
      menuChildren: _buildProfileMenuChildren(context),
      builder: (context, controller, _) {
        if (compact) {
          return Tooltip(
            message: username,
            child: IconButton(tooltip: 'Profile menu', onPressed: () => controller.isOpen ? controller.close() : controller.open(), icon: avatar),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark ? [_BrandPalette.slateRaised, _BrandPalette.slateCard] : [Colors.white, _BrandPalette.warmPaper],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
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
                          Text('Household workspace', overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
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
    return Tooltip(
      message: _shellNavExpanded ? 'Collapse navigation' : 'Expand navigation',
      child: IconButton(
        onPressed: _toggleShellNavigation,
        visualDensity: VisualDensity.compact,
        icon: Icon(_shellNavExpanded ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildShellHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(_shellNavExpanded ? 16 : 10, 14, _shellNavExpanded ? 16 : 10, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(_shellNavExpanded ? 16 : 8, 14, _shellNavExpanded ? 16 : 8, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [_BrandPalette.slateHigh, _BrandPalette.slateRaised] : [Colors.white, _BrandPalette.warmPaper],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.46)),
        ),
        child: _shellNavExpanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAVIGATION',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Control Center', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      _buildShellRailToggle(theme),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Keep navigation and actions close at hand without extra branding noise.', style: theme.textTheme.bodySmall),
                ],
              )
            : Center(child: _buildShellRailToggle(theme)),
      ),
    );
  }

  Widget _buildDesktopNavItem(BuildContext context, _ShellDestination destination) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = _selectedDestination == destination;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _setDestination(destination),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: _shellNavExpanded ? 12 : 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Color.alphaBlend(_BrandPalette.goldBright.withValues(alpha: 0.14), _BrandPalette.slateRaised), _BrandPalette.slateCard]
                        : [Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.14), Colors.white), _BrandPalette.warmPaper],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? theme.colorScheme.primary.withValues(alpha: 0.34) : theme.colorScheme.outlineVariant.withValues(alpha: 0.46)),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.14) : theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? theme.colorScheme.primary.withValues(alpha: 0.24) : theme.colorScheme.outlineVariant.withValues(alpha: 0.46)),
                ),
                alignment: Alignment.center,
                child: Icon(destination.icon, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 20),
              ),
              if (_shellNavExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: selected ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopShell(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = Color.alphaBlend(isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.72), theme.colorScheme.surfaceContainerLow);

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _shellNavExpanded ? 256 : 92,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? _BrandPalette.slateBorder : theme.colorScheme.primary.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                _buildShellHeader(theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _ShellDestination.values.map((destination) => _buildDesktopNavItem(context, destination)).toList(growable: false),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: _buildContentAction(compact: !_shellNavExpanded)),
                      const SizedBox(height: 12),
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
    final username = _shellUsername();
    return Drawer(
      backgroundColor: isDark ? _BrandPalette.slatePanel : _BrandPalette.warmPaper,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark ? [_BrandPalette.slateRaised, _BrandPalette.slateCard] : [Colors.white, _BrandPalette.warmPaper],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_BrandPalette.goldBright, _BrandPalette.goldDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _identityInitials(username),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: _BrandPalette.navy),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORKSPACE',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(username, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Choose a view and keep daily tasks in reach.', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'NAVIGATION',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            ..._ShellDestination.values.map(
              (d) => ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                subtitle: Text(d.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                selected: _selectedDestination == d,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () {
                  Navigator.of(context).pop();
                  _setDestination(d);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Open Content Site'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onTap: () {
                Navigator.of(context).pop();
                _openContentSite();
              },
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _PageHeroCard(
          eyebrow: 'Account',
          title: username,
          description: dashboard.team?.description ?? 'Manage appearance, workspace links, and the operational details behind your household workspace.',
          trailing: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_BrandPalette.goldBright, _BrandPalette.goldDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _identityInitials(username),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: _BrandPalette.navy),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Household workspace', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Owner controls', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Switch between warm daylight and stone-dark workspace styling.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              _AppearancePanel(controller: widget.themeController),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workspace Links', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              _EndpointTile(title: 'Frontend host', subtitle: Uri.base.origin, actionLabel: 'Refresh', onPressed: _busy ? null : () => _loadAll()),
              _EndpointTile(title: 'Content site', subtitle: _contentSiteLabel, actionLabel: 'Open', onPressed: _openContentSite),
              _EndpointTile(
                title: 'API health',
                subtitle: Uri.base.resolve('/health').toString(),
                actionLabel: 'View',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await launchUrl(Uri.base.resolve('/health'), webOnlyWindowName: '_blank');
                  if (!ok && mounted) {
                    messenger.showSnackBar(const SnackBar(content: Text('Unable to open /health.')));
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
        title: _BrandLockup(compact: isMobile, toolbarVariant: true, onTap: () => _setDestination(_ShellDestination.owner)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.0),
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.0),
                ],
              ),
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
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: KeyedSubtree(key: ValueKey(_selectedDestination), child: _buildContentBody(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerView(BuildContext context, DashboardPayload dashboard, CatalogPayload catalog) {
    final detail = _learnerDetail;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1120;
        final hero = _PageHeroCard(
          eyebrow: 'Operations',
          title: dashboard.team?.displayName ?? 'Learning Team',
          description: dashboard.team?.description ?? 'Track learner progress, create assignments, and keep the curriculum close without losing your place.',
          chips: [
            _StatChip(label: 'Skills', value: '${dashboard.catalog.skillCount}', icon: Icons.extension_rounded),
            _StatChip(label: 'Playlists', value: '${dashboard.catalog.playlistCount}', icon: Icons.assignment_rounded),
            _StatChip(label: 'Materials', value: '${dashboard.catalog.materialCount}', icon: Icons.menu_book_rounded),
          ],
        );
        final leftPanel = _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Learner roster', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Choose a learner to inspect assignments, review needs, and live session state.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _GoldAccentDivider(),
              const SizedBox(height: 18),
              ...dashboard.learners.map(
                (learner) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LearnerCard(learner: learner, selected: learner.learnerId == _selectedLearnerId, onTap: () => _selectLearner(learner.learnerId)),
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
                        Icon(Icons.person_search_rounded, size: 52, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
                        const SizedBox(height: 16),
                        Text(
                          'Select a learner to inspect\nassignment and review state.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learner workspace', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Active assignment, current session capture, and skill progress in one place.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _LearnerOperationsPanel(
                      detail: detail,
                      catalog: catalog.bundle,
                      currentActionSession: _currentActionSession,
                      scoreController: _scoreController,
                      maxScoreController: _maxScoreController,
                      durationController: _durationController,
                      notesController: _notesController,
                      onCreateAssignment: _createAssignment,
                      onRecordSession: _recordCurrentSession,
                    ),
                  ],
                ),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            hero,
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: leftPanel),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: rightPanel),
                ],
              )
            else ...[
              leftPanel,
              const SizedBox(height: 20),
              rightPanel,
            ],
          ],
        );
      },
    );
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
              Icon(Icons.school_rounded, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 20),
              Text('Select a learner with an active session.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2A2117), _BrandPalette.slateRaised, const Color(0xFF171411)]
                  : [const Color(0xFFFFF4CC), Colors.white, const Color(0xFFF7ECDD)],
              stops: const [0.0, 0.58, 1.0],
            ),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.08),
                blurRadius: 34,
                offset: const Offset(0, 18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      'ACTIVE SESSION',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                    ),
                  ),
                  const Spacer(),
                  Text(session.scheduledDate, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 18),
              Text(detail.learner.displayName, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              Text(session.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                'Guide the learner through the sequence below, then capture the outcome from the owner workspace.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Material sequence', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '${session.materials.length} materials lined up for today\'s session.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: session.materials
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final material = entry.value;
                      return Container(
                        width: 280,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark ? [_BrandPalette.slateHigh, _BrandPalette.slateRaised] : [Colors.white, _BrandPalette.warmPaper],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                'STEP ${index + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(material.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text(
                              material.skillId,
                              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text('Material: ${material.materialId}', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogView(BuildContext context, CatalogPayload catalog) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _PageHeroCard(
          eyebrow: 'Catalog',
          title: 'Catalog Snapshot',
          description: 'See the current breadth of subjects, areas, skills, stages, playlists, and materials loaded into Cornerstone.',
          chips: [
            _StatChip(label: 'Areas', value: '${catalog.report.areaCount}', icon: Icons.grid_view_rounded),
            _StatChip(label: 'Skills', value: '${catalog.report.skillCount}', icon: Icons.extension_rounded),
            _StatChip(label: 'Stages', value: '${catalog.report.stageCount}', icon: Icons.flag_rounded),
            _StatChip(label: 'Materials', value: '${catalog.report.materialCount}', icon: Icons.menu_book_rounded),
          ],
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('Loaded at ${catalog.report.loadedAtUtc}', style: theme.textTheme.bodySmall)],
          ),
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Playlists', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Ready-made learning runs ordered by age, level, stage, and duration.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...catalog.bundle.playlists.map(
                (playlist) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(playlist.title),
                  subtitle: Text(
                    'Age ${playlist.recommendedAge} · ${playlist.recommendedLevel} · ${playlist.durationDays} days',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: _PillBadge(
                    text: '${playlist.skillIds.length} skills',
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
              Text('Materials', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Source material available to session sequences across the catalog.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...catalog.bundle.materials.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text('${item.subjectId} · ${item.kind}', style: theme.textTheme.bodySmall),
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
