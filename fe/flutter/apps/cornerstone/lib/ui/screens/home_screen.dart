part of '../../main.dart';

enum _ShellDestination {
  owner('Owner', 'Manage learners, assignments, and household progress.', Icons.dashboard_rounded),
  learner('Learner', 'Follow today\'s active session and material sequence.', Icons.school_rounded),
  library('Library', 'Browse pathways, playlists, and learning materials.', Icons.auto_stories_rounded),
  account('My Account', 'Profile and appearance.', Icons.person_rounded);

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
  static const String _viewerUsernamePreferenceKey =
      'cornerstone.viewer.username';
  static const double _signedOutMaxWidth = 1200;

  final CornerstoneApiClient _apiClient = CornerstoneApiClient();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController(text: '8');
  final TextEditingController _maxScoreController = TextEditingController(text: '10');
  final TextEditingController _durationController = TextEditingController(text: '15');
  final TextEditingController _notesController = TextEditingController(text: 'Completed well with one or two slow facts.');

  ViewerSessionPayload? _viewerSession;
  DashboardPayload? _dashboard;
  LibraryPayload? _library;
  LibraryDocumentsPayload? _libraryDocuments;
  LibraryDocumentData? _selectedLibraryDocument;
  LearnerDetailPayload? _learnerDetail;
  String? _selectedLearnerId;
  String? _selectedLibraryRoutePath;
  _ShellDestination _selectedDestination = _ShellDestination.owner;
  bool _shellNavExpanded = true;
  bool _sessionLoading = true;
  bool _loading = true;
  bool _authBusy = false;
  bool _busy = false;
  bool _libraryDocumentBusy = false;
  String? _sessionErrorMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreViewerSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _scoreController.dispose();
    _maxScoreController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ViewerUser? get _currentViewer => _viewerSession?.currentUser;
  bool get _viewerCanManage => _currentViewer?.canManageHousehold ?? false;

  List<_ShellDestination> get _availableDestinations {
    final viewer = _currentViewer;
    if (viewer == null) return const <_ShellDestination>[];
    if (viewer.canManageHousehold) {
      return _ShellDestination.values;
    }
    return const <_ShellDestination>[
      _ShellDestination.learner,
      _ShellDestination.library,
      _ShellDestination.account,
    ];
  }

  List<LearnerDashboard> get _visibleLearners {
    final dashboard = _dashboard;
    final viewer = _currentViewer;
    if (dashboard == null) return const <LearnerDashboard>[];
    if (viewer == null || viewer.canManageHousehold || viewer.learnerId == null) {
      return dashboard.learners;
    }
    return dashboard.learners
        .where((learner) => learner.learnerId == viewer.learnerId)
        .toList(growable: false);
  }

  _ShellDestination _defaultDestinationForViewer(ViewerUser viewer) {
    return viewer.isLearner
        ? _ShellDestination.learner
        : _ShellDestination.owner;
  }

  void _setUsernameInput(String username) {
    _usernameController.value = TextEditingValue(
      text: username,
      selection: TextSelection.collapsed(offset: username.length),
    );
  }

  Future<String?> _loadStoredViewerUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_viewerUsernamePreferenceKey)?.trim();
    if (username == null || username.isEmpty) {
      return null;
    }
    return username;
  }

  Future<void> _persistViewerUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewerUsernamePreferenceKey, username.trim());
  }

  Future<void> _clearStoredViewerUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewerUsernamePreferenceKey);
  }

  String? _nextLearnerIdForViewer(
    DashboardPayload dashboard, {
    bool preserveSelection = true,
  }) {
    final viewer = _currentViewer;
    if (viewer != null && viewer.isLearner && viewer.learnerId != null) {
      final learnerId = viewer.learnerId!;
      return dashboard.learners.any((learner) => learner.learnerId == learnerId)
          ? learnerId
          : null;
    }
    if (preserveSelection && _selectedLearnerId != null) {
      final learnerId = _selectedLearnerId!;
      if (dashboard.learners.any((learner) => learner.learnerId == learnerId)) {
        return learnerId;
      }
    }
    return dashboard.learners.isNotEmpty ? dashboard.learners.first.learnerId : null;
  }

  Future<void> _restoreViewerSession() async {
    setState(() {
      _sessionLoading = true;
      _sessionErrorMessage = null;
    });
    try {
      final storedUsername = await _loadStoredViewerUsername();
      final viewerSession = await _apiClient.fetchViewerSession(
        username: storedUsername,
      );
      if (!mounted) return;
      final suggestedUsername = viewerSession.currentUser?.username ??
          storedUsername ??
          '';
      _setUsernameInput(suggestedUsername);

      if (viewerSession.currentUser == null && storedUsername != null) {
        await _clearStoredViewerUsername();
      }

      if (viewerSession.currentUser == null) {
        setState(() {
          _viewerSession = viewerSession;
          _sessionLoading = false;
          _authBusy = false;
          _dashboard = null;
          _library = null;
          _libraryDocuments = null;
          _selectedLibraryDocument = null;
          _learnerDetail = null;
          _selectedLearnerId = null;
          _selectedLibraryRoutePath = null;
          _selectedDestination = _ShellDestination.owner;
          _loading = false;
          _busy = false;
          _libraryDocumentBusy = false;
          _errorMessage = null;
        });
        return;
      }

      await _persistViewerUsername(viewerSession.currentUser!.username);
      setState(() {
        _viewerSession = viewerSession;
        _sessionLoading = false;
        _authBusy = false;
        _sessionErrorMessage = null;
        _dashboard = null;
        _library = null;
        _libraryDocuments = null;
        _selectedLibraryDocument = null;
        _learnerDetail = null;
        _selectedLearnerId = null;
        _selectedLibraryRoutePath = null;
        _selectedDestination = _defaultDestinationForViewer(
          viewerSession.currentUser!,
        );
        _loading = true;
        _busy = false;
        _libraryDocumentBusy = false;
        _errorMessage = null;
      });
      await _loadAll(preserveSelection: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionLoading = false;
        _authBusy = false;
        _loading = false;
        _busy = false;
        _sessionErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loginWithUsername([String? username]) async {
    final requestedUsername = (username ?? _usernameController.text).trim();
    if (requestedUsername.isEmpty) {
      setState(() {
        _sessionErrorMessage = 'Enter a username to continue.';
      });
      return;
    }

    setState(() {
      _authBusy = true;
      _sessionErrorMessage = null;
    });
    try {
      final viewerSession = await _apiClient.login(requestedUsername);
      if (!mounted) return;
      final currentUser = viewerSession.currentUser;
      if (currentUser == null) {
        setState(() {
          _authBusy = false;
          _sessionErrorMessage = 'Unable to resolve that username.';
        });
        return;
      }

      _setUsernameInput(currentUser.username);
      await _persistViewerUsername(currentUser.username);
      setState(() {
        _viewerSession = viewerSession;
        _authBusy = false;
        _dashboard = null;
        _library = null;
        _libraryDocuments = null;
        _selectedLibraryDocument = null;
        _learnerDetail = null;
        _selectedLearnerId = null;
        _selectedLibraryRoutePath = null;
        _selectedDestination = _defaultDestinationForViewer(currentUser);
        _loading = true;
        _busy = false;
        _libraryDocumentBusy = false;
        _errorMessage = null;
      });
      await _loadAll(preserveSelection: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _sessionErrorMessage = error.toString();
      });
    }
  }

  Future<void> _logoutViewer() async {
    setState(() {
      _authBusy = true;
      _sessionErrorMessage = null;
    });
    try {
      await _clearStoredViewerUsername();
      if (!mounted) return;
      await _restoreViewerSession();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _sessionErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadAll({bool preserveSelection = true}) async {
    if (_currentViewer == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final dashboard = await _apiClient.fetchDashboard();
      final library = await _apiClient.fetchLibrary();
      final libraryDocuments = await _apiClient.fetchLibraryDocuments();
      final nextLearnerId = _nextLearnerIdForViewer(
        dashboard,
        preserveSelection: preserveSelection,
      );
      final nextLibraryRoutePath = _nextLibraryRoutePath(
        library: library,
        documents: libraryDocuments,
        preserveSelection: preserveSelection,
      );
      LearnerDetailPayload? learnerDetail;
      LibraryDocumentData? selectedLibraryDocument;
      if (nextLearnerId != null) {
        learnerDetail = await _apiClient.fetchLearnerDetail(nextLearnerId);
      }
      if (nextLibraryRoutePath != null) {
        selectedLibraryDocument = await _apiClient.fetchLibraryDocument(
          nextLibraryRoutePath,
        );
      }
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _library = library;
        _libraryDocuments = libraryDocuments;
        _selectedLibraryRoutePath = nextLibraryRoutePath;
        _selectedLibraryDocument = selectedLibraryDocument;
        _selectedLearnerId = nextLearnerId;
        _learnerDetail = learnerDetail;
        _loading = false;
        _busy = false;
        _libraryDocumentBusy = false;
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

  String? _nextLibraryRoutePath({
    required LibraryPayload library,
    required LibraryDocumentsPayload documents,
    bool preserveSelection = true,
  }) {
    final availableRoutes = documents.documents
        .map((document) => document.routePath)
        .toSet();
    if (
        preserveSelection &&
        _selectedLibraryRoutePath != null &&
        availableRoutes.contains(_selectedLibraryRoutePath)) {
      return _selectedLibraryRoutePath;
    }

    if (library.bundle.pathways.isNotEmpty) {
      final preferredSourcePath = library.bundle.pathways.first.sourcePath;
      for (final document in documents.documents) {
        if (document.sourcePath == preferredSourcePath) {
          return document.routePath;
        }
      }
    }

    return documents.documents.isNotEmpty ? documents.documents.first.routePath : null;
  }

  Future<void> _selectLibraryDocument(String routePath) async {
    final normalizedRoutePath = routePath.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (normalizedRoutePath.isEmpty) {
      return;
    }
    if (
        normalizedRoutePath == _selectedLibraryRoutePath &&
        _selectedLibraryDocument != null) {
      _setDestination(_ShellDestination.library);
      return;
    }

    setState(() {
      _selectedDestination = _ShellDestination.library;
      _selectedLibraryRoutePath = normalizedRoutePath;
      _libraryDocumentBusy = true;
    });

    try {
      final document = await _apiClient.fetchLibraryDocument(normalizedRoutePath);
      if (!mounted) return;
      setState(() {
        _selectedLibraryDocument = document;
        _libraryDocumentBusy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _libraryDocumentBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load that document: $error')),
      );
    }
  }

  Future<void> _selectLearner(String learnerId) async {
    final viewer = _currentViewer;
    if (viewer != null && viewer.isLearner && viewer.learnerId != learnerId) {
      return;
    }
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
    if (!_viewerCanManage) return;
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
    if (!_viewerCanManage) return;
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
    return null;
  }

  void _setDestination(_ShellDestination d) {
    if (!_availableDestinations.contains(d)) return;
    setState(() => _selectedDestination = d);
  }

  void _toggleShellNavigation() => setState(() => _shellNavExpanded = !_shellNavExpanded);

  String _shellUsername() =>
      _currentViewer?.displayName ?? _viewerSession?.team?.displayName ?? 'Cornerstone';

  String _viewerRoleLabel(ViewerUser? viewer) {
    if (viewer == null) return 'Signed out';
    return viewer.canManageHousehold ? 'Parent / Teacher' : 'Student';
  }

  String _shellWorkspaceLabel() {
    final viewer = _currentViewer;
    if (viewer == null) return 'Signed out';
    return viewer.canManageHousehold
        ? 'Parent / teacher workspace'
        : 'Student workspace';
  }

  bool _hasMeaningfulViewerNotes(ViewerUser viewer) {
    final notes = viewer.notes.trim();
    return notes.isNotEmpty && notes.toLowerCase() != 'owner';
  }

  double _contentMaxWidthFor(_ShellDestination destination) {
    return switch (destination) {
      _ShellDestination.owner => 1320,
      _ShellDestination.learner => 1160,
      _ShellDestination.library => 1480,
      _ShellDestination.account => 1040,
    };
  }

  Widget _wrapMainContent(Widget child, {double? maxWidth}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? _contentMaxWidthFor(_selectedDestination)),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }

  String _identityInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CO';
    if (parts.length == 1) {
      final w = parts.first;
      return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  List<Widget> _buildProfileMenuChildren(BuildContext context) {
    return [
      MenuItemButton(leadingIcon: const Icon(Icons.person_rounded), onPressed: () => _setDestination(_ShellDestination.account), child: const Text('My Account')),
      MenuItemButton(leadingIcon: const Icon(Icons.auto_stories_rounded), onPressed: () => _setDestination(_ShellDestination.library), child: const Text('Open library')),
      MenuItemButton(leadingIcon: const Icon(Icons.logout_rounded), onPressed: _authBusy ? null : () => _logoutViewer(), child: const Text('Log out')),
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
                          Text(_shellWorkspaceLabel(), overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
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
    final shellTitle = _viewerCanManage ? 'Control Center' : 'Learner Space';
    final shellDescription = _viewerCanManage
        ? 'Keep navigation and actions close at hand without extra branding noise.'
        : 'Stay focused on today\'s work, your progress, and what comes next.';

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
                        child: Text(shellTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      _buildShellRailToggle(theme),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(shellDescription, style: theme.textTheme.bodySmall),
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
                      children: _availableDestinations.map((destination) => _buildDesktopNavItem(context, destination)).toList(growable: false),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                  child: _buildProfileMenuAnchor(compact: !_shellNavExpanded),
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
                        Text(_shellWorkspaceLabel(), style: theme.textTheme.bodySmall),
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
            ..._availableDestinations.map(
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
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Log out'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onTap: _authBusy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _logoutViewer();
                    },
            ),
            const SizedBox(height: 16),
            _AppearancePanel(controller: widget.themeController),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLoginTile(BuildContext context, ViewerUser user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [_BrandPalette.slateHigh, _BrandPalette.slateRaised]
              : [Colors.white, _BrandPalette.warmPaper],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          foregroundColor: theme.colorScheme.primary,
          child: Text(
            _identityInitials(user.displayName),
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(user.displayName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${_viewerRoleLabel(user)} · @${user.username}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
        onTap: _authBusy ? null : () => _loginWithUsername(user.username),
      ),
    );
  }

  Widget _buildSignedOutScaffold(BuildContext context) {
    final session = _viewerSession;
    final availableUsers = session?.availableUsers ?? const <ViewerUser>[];
    final ownerCount = availableUsers.where((user) => user.canManageHousehold).length;
    final learnerCount = availableUsers.where((user) => user.isLearner).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _signedOutMaxWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 1080;
                  final hero = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BrandLockup(),
                      const SizedBox(height: 20),
                      _PageHeroCard(
                        eyebrow: 'Sign In',
                        title: session?.team?.displayName ?? 'Cornerstone Household',
                        description:
                            'Choose a username to enter the parent / teacher workspace or the student view. There is no password yet, so keep the flow simple and fast.',
                        chips: [
                          _StatChip(
                            label: 'Parent / Teacher',
                            value: '$ownerCount',
                            icon: Icons.manage_accounts_rounded,
                          ),
                          _StatChip(
                            label: 'Students',
                            value: '$learnerCount',
                            icon: Icons.school_rounded,
                          ),
                          const _StatChip(
                            label: 'Themes',
                            value: 'Light + Dark',
                            icon: Icons.contrast_rounded,
                          ),
                        ],
                        trailing: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.34),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USERNAME ONLY',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Use a parent / teacher account to manage every learner. Use a student account to see what is completed and what is pending.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );

                  final loginCard = _SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Continue with username', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Pick a household profile below or type the username directly.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        if (_sessionErrorMessage != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _sessionErrorMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.go,
                          onSubmitted: _authBusy ? null : (_) => _loginWithUsername(),
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _authBusy ? null : () => _loginWithUsername(),
                                icon: _authBusy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded, size: 18),
                                label: const Text('Enter Workspace'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text('Quick sign-in', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        if (availableUsers.isEmpty)
                          Text(
                            'No usernames are available yet. Run bootstrap and try again.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Column(
                            children: availableUsers
                                .map(
                                  (user) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildQuickLoginTile(context, user),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        const SizedBox(height: 10),
                        _AppearancePanel(controller: widget.themeController),
                      ],
                    ),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: hero),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: loginCard),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hero,
                      const SizedBox(height: 20),
                      loginCard,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearnerMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.54),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSessionListCard(
    BuildContext context, {
    required String title,
    required String description,
    required String emptyMessage,
    required List<SessionDetail> sessions,
    required bool completed,
  }) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          if (sessions.isEmpty)
            Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...sessions.map(
              (session) {
                final evidence = session.latestEvidence;
                final trailingLabel = completed && evidence != null
                    ? '${evidence.score.toStringAsFixed(0)}/${evidence.maxScore.toStringAsFixed(0)}'
                    : session.scheduledDate;
                final subtitle = completed
                    ? (session.notes.isEmpty ? 'Completed' : session.notes)
                    : (session.notes.isEmpty
                          ? 'Still pending'
                          : session.notes);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(session.title),
                  subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
                  trailing: _PillBadge(
                    text: trailingLabel,
                    color: completed
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    textColor: completed
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.primary,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContentBody(BuildContext context) {
    final dashboard = _dashboard;
    final library = _library;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _ErrorState(message: _errorMessage!, onRetry: () => _loadAll());
    if (dashboard == null || library == null) return const Center(child: Text('No data loaded'));
    final content = switch (_selectedDestination) {
      _ShellDestination.owner => _buildOwnerView(context, dashboard, library),
      _ShellDestination.learner => _buildLearnerView(context),
      _ShellDestination.library => _buildLibraryView(context, library),
      _ShellDestination.account => _buildAccountView(context, dashboard),
    };
    return _wrapMainContent(content);
  }

  Widget _buildAccountView(BuildContext context, DashboardPayload dashboard) {
    final theme = Theme.of(context);
    final username = _shellUsername();
    final viewer = _currentViewer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _PageHeroCard(
          eyebrow: 'Account',
          title: username,
          description: viewer == null
              ? (dashboard.team?.description ?? 'Manage your profile and theme in one place.')
              : viewer.canManageHousehold
                ? 'Manage your profile, theme, and household learning space in one place.'
                : 'Keep your profile, theme, and learner space settings in one place.',
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
                Text(_viewerRoleLabel(viewer), style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(viewer == null ? 'Signed out' : '@${viewer.username}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (viewer != null) ...[
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  viewer.canManageHousehold
                      ? 'This account can manage every learner, assignments, and progress updates.'
                      : 'This account stays focused on the learner view, progress, and pending work.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      _identityInitials(viewer.displayName),
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(viewer.displayName),
                  subtitle: Text('@${viewer.username}', style: theme.textTheme.bodySmall),
                  trailing: _PillBadge(
                    text: _viewerRoleLabel(viewer),
                    color: viewer.canManageHousehold
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    textColor: viewer.canManageHousehold
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.primary,
                  ),
                ),
                if (viewer.currentLevel != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Current level: ${viewer.currentLevel}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (_hasMeaningfulViewerNotes(viewer)) ...[
                  const SizedBox(height: 8),
                  Text(
                    viewer.notes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _authBusy ? null : _logoutViewer,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_currentViewer == null) {
      return _buildSignedOutScaffold(context);
    }

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
          if (_busy || _authBusy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
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

  Widget _buildOwnerView(BuildContext context, DashboardPayload dashboard, LibraryPayload library) {
    final detail = _learnerDetail;
    final theme = Theme.of(context);
    final viewer = _currentViewer;
    final learners = _visibleLearners;
    final activeSessionCount = learners.where((learner) => learner.todaySession != null).length;
    final totalReviewItems = learners.fold<int>(0, (sum, learner) => sum + learner.reviewItemCount);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1120;
        final hero = _PageHeroCard(
          eyebrow: 'Parent / Teacher',
          title: viewer == null ? (dashboard.team?.displayName ?? 'Learning Team') : '${viewer.displayName} dashboard',
          description: 'Manage assignments, review needs, and learner progress across the whole household from one workspace.',
          chips: [
            _StatChip(label: 'Learners', value: '${learners.length}', icon: Icons.groups_rounded),
            _StatChip(label: 'Active Today', value: '$activeSessionCount', icon: Icons.today_rounded),
            _StatChip(label: 'Review Queue', value: '$totalReviewItems', icon: Icons.pending_actions_rounded),
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
              if (learners.isEmpty)
                Text(
                  'No learners are visible in this workspace yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                ...learners.map(
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
                      library: library.bundle,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewer = _currentViewer;
    if (detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 20),
              Text(
                viewer != null && viewer.isLearner
                    ? 'This username is not linked to a learner profile yet.'
                    : 'Select a learner to open the student view.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final pendingSessions = detail.sessions
        .where((session) => session.status != 'completed')
        .toList(growable: false);
    final completedSessions = detail.sessions
        .where((session) => session.status == 'completed')
        .toList(growable: false);
    final progressStatusCounts = <String, int>{};
    for (final state in detail.progress) {
      progressStatusCounts.update(state.status, (count) => count + 1, ifAbsent: () => 1);
    }
    final nextSession = pendingSessions.isNotEmpty ? pendingSessions.first : null;
    final heroLabel = nextSession == null ? 'PROGRESS' : 'ACTIVE SESSION';
    final heroTitle = nextSession?.title ?? 'No active session right now';
    final heroDescription = viewer != null && viewer.canManageHousehold
        ? 'Use this learner-facing view to understand what is still pending, what is already completed, and what the learner sees next.'
        : 'See what is next, what you have already completed, and what still needs attention.';

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
                      heroLabel,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                    ),
                  ),
                  const Spacer(),
                  Text(nextSession?.scheduledDate ?? 'Up to date', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 18),
              Text(detail.learner.displayName, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              Text(heroTitle, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                heroDescription,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _buildLearnerMetricCard(
                    context,
                    label: 'Pending sessions',
                    value: '${pendingSessions.length}',
                    icon: Icons.pending_actions_rounded,
                  ),
                  _buildLearnerMetricCard(
                    context,
                    label: 'Completed sessions',
                    value: '${completedSessions.length}',
                    icon: Icons.task_alt_rounded,
                  ),
                  _buildLearnerMetricCard(
                    context,
                    label: 'Review items',
                    value: '${detail.reviewItems.length}',
                    icon: Icons.assignment_late_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (nextSession != null) ...[
          const SizedBox(height: 20),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Material sequence', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  '${nextSession.materials.length} materials lined up for the next session.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: nextSession.materials
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
                                'Ready for today\'s practice',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
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
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 1120;
            final pendingCard = _buildSessionListCard(
              context,
              title: 'What is pending',
              description: 'Sessions that still need attention in the current assignment.',
              emptyMessage: 'No pending sessions right now.',
              sessions: pendingSessions,
              completed: false,
            );
            final completedCard = _buildSessionListCard(
              context,
              title: 'Completed work',
              description: 'Work that has already been recorded for this learner.',
              emptyMessage: 'No completed sessions have been recorded yet.',
              sessions: completedSessions,
              completed: true,
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: pendingCard),
                  const SizedBox(width: 20),
                  Expanded(child: completedCard),
                ],
              );
            }
            return Column(
              children: [
                pendingCard,
                const SizedBox(height: 20),
                completedCard,
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Skill progress', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Current status across the skills attached to this learner.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              if (progressStatusCounts.isEmpty)
                Text(
                  'No progress has been recorded yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: progressStatusCounts.entries
                      .map(
                        (entry) => _PillBadge(
                          text: '${entry.value} ${_humanizeLabel(entry.key)}',
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          textColor: theme.colorScheme.primary,
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryView(BuildContext context, LibraryPayload library) {
    final theme = Theme.of(context);
    final documents = _libraryDocuments;
    final activeDocument = _selectedLibraryDocument;
    final areaById = {
      for (final area in library.bundle.areas) area.areaId: area,
    };
    final playlistsById = {
      for (final playlist in library.bundle.playlists) playlist.playlistId: playlist,
    };
    final routeBySourcePath = {
      for (final document in documents?.documents ?? const <LibraryDocumentSummary>[])
        document.sourcePath: document.routePath,
    };
    final documentsByKey = {
      for (final document in documents?.documents ?? const <LibraryDocumentSummary>[])
        '${document.kind}:${document.documentId}': document,
    };

    Widget buildNavigatorPanel() {
      return Column(
        children: [
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pathways', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Open the route document first, then jump to the supporting playlists and materials as needed.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (library.bundle.pathways.isEmpty)
                  Text(
                    'No pathways are available yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                else
                  ...library.bundle.pathways.map((pathway) {
                    final areaTitle = areaById[pathway.areaId]?.title ?? pathway.areaId;
                    final orderedPlaylists = pathway.playlistIds
                        .map((playlistId) => playlistsById[playlistId])
                        .whereType<PlaylistInfo>()
                        .toList(growable: false);
                    final entryPoints = pathway.entryPoints.entries.toList(growable: false)
                      ..sort((left, right) {
                        final leftAge = int.tryParse(left.key.replaceFirst('age_', '')) ?? 0;
                        final rightAge = int.tryParse(right.key.replaceFirst('age_', '')) ?? 0;
                        return leftAge.compareTo(rightAge);
                      });
                    final pathwayRoutePath = routeBySourcePath[pathway.sourcePath];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pathway.title, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              pathway.description,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PillBadge(
                                  text: areaTitle,
                                  color: theme.colorScheme.secondaryContainer,
                                  textColor: theme.colorScheme.onSecondaryContainer,
                                ),
                                _PillBadge(
                                  text: 'Ages ${pathway.recommendedAgeMin}-${pathway.recommendedAgeMax}',
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  textColor: theme.colorScheme.primary,
                                ),
                                _PillBadge(
                                  text: '${pathway.stageIds.length} stages',
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  textColor: theme.colorScheme.primary,
                                ),
                                _PillBadge(
                                  text: '${orderedPlaylists.length} playlists',
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  textColor: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: pathwayRoutePath == null
                                  ? null
                                  : () => _selectLibraryDocument(pathwayRoutePath),
                              icon: const Icon(Icons.description_rounded, size: 18),
                              label: const Text('Open route document'),
                            ),
                            if (entryPoints.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text('Entry guidance', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: entryPoints.map((entry) {
                                  final age = entry.key.replaceFirst('age_', '');
                                  final playlistTitle = playlistsById[entry.value]?.title ?? entry.value;
                                  return _PillBadge(
                                    text: 'Age $age: $playlistTitle',
                                    color: theme.colorScheme.tertiaryContainer,
                                    textColor: theme.colorScheme.onTertiaryContainer,
                                  );
                                }).toList(growable: false),
                              ),
                            ],
                            if (orderedPlaylists.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text('Ordered playlists', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 10),
                              ...orderedPlaylists.asMap().entries.map((entry) {
                                final playlist = entry.value;
                                final playlistRoute = documentsByKey['playlist:${playlist.playlistId}']?.routePath;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    foregroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  title: Text(playlist.title),
                                  subtitle: Text(
                                    'Age ${playlist.recommendedAge} · ${playlist.recommendedLevel} · ${playlist.durationDays} days · ${playlist.skillIds.length} skills',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: TextButton(
                                    onPressed: playlistRoute == null
                                        ? null
                                        : () => _selectLibraryDocument(playlistRoute),
                                    child: const Text('Open'),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supporting materials', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Open the exact worksheet, teaching note, or check without leaving the app.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ...library.bundle.materials.map((item) {
                  final materialRoute = documentsByKey['material:${item.id}']?.routePath;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text(
                      '${_humanizeLabel(item.kind)} · ${item.estimatedMinutes} min · age ${item.recommendedAge}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: TextButton(
                      onPressed: materialRoute == null
                          ? null
                          : () => _selectLibraryDocument(materialRoute),
                      child: const Text('Open'),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildReaderPanel() {
      return _SurfaceCard(
        child: _LibraryDocumentReader(
          document: activeDocument,
          busy: _libraryDocumentBusy,
          routeBySourcePath: routeBySourcePath,
          onOpenLibraryRoute: _selectLibraryDocument,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1240;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            _PageHeroCard(
              eyebrow: 'Library',
              title: 'Learning Library',
              description: 'Browse the authored pathways first, then read the underlying markdown documents directly inside Cornerstone.',
              chips: [
                _StatChip(label: 'Pathways', value: '${library.report.pathwayCount}', icon: Icons.route_rounded),
                _StatChip(label: 'Documents', value: '${documents?.documents.length ?? 0}', icon: Icons.description_rounded),
                _StatChip(label: 'Materials', value: '${library.report.materialCount}', icon: Icons.menu_book_rounded),
              ],
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: buildNavigatorPanel()),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: buildReaderPanel()),
                ],
              )
            else ...[
              buildNavigatorPanel(),
              const SizedBox(height: 20),
              buildReaderPanel(),
            ],
          ],
        );
      },
    );
  }
}
