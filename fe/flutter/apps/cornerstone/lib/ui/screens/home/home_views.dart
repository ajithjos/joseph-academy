part of '../../../main.dart';

extension _CornerstoneHomePageViews on _CornerstoneHomePageState {
  Widget _buildSignedOutScaffold(BuildContext context) {
    final session = _viewerSession;
    final availableUsers = session?.availableUsers ?? const <ViewerUser>[];
    final ownerCount = availableUsers
        .where((user) => user.canManageTeam)
        .length;
    final learnerCount = availableUsers.where((user) => user.isLearner).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _CornerstoneHomePageState._signedOutMaxWidth,
              ),
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
                        title: session?.team?.displayName ?? 'Cornerstone Team',
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
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.34),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USERNAME ONLY',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                        Text(
                          'Continue with username',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pick a team profile below or type the username directly.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (_sessionErrorMessage != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _sessionErrorMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
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
                          onSubmitted: _authBusy
                              ? null
                              : (_) => _loginWithUsername(),
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
                                onPressed: _authBusy
                                    ? null
                                    : () => _loginWithUsername(),
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
                        Text(
                          'Quick sign-in',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
                    children: [hero, const SizedBox(height: 20), loginCard],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody(BuildContext context) {
    final dashboard = _dashboard;
    final libraryWorkspace = _libraryWorkspace;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: () => _loadAll());
    }
    if (dashboard == null) {
      return const Center(child: Text('No data loaded'));
    }
    final activeDestination =
        _availableDestinations.contains(_selectedDestination)
        ? _selectedDestination
        : (_availableDestinations.isNotEmpty
              ? _availableDestinations.first
              : _ShellDestination.account);
    final content = switch (activeDestination) {
      _ShellDestination.owner =>
        libraryWorkspace == null
            ? const Center(child: Text('Team planning data is unavailable.'))
            : _buildOwnerView(context, dashboard, libraryWorkspace),
      _ShellDestination.learner => _buildLearnerView(context),
      _ShellDestination.library =>
        libraryWorkspace == null
            ? const Center(
                child: Text('Library access is unavailable for this viewer.'),
              )
            : _buildLibraryView(context, libraryWorkspace),
      _ShellDestination.account => _buildAccountView(context, dashboard),
    };
    return _wrapMainContent(
      content,
      maxWidth: _contentMaxWidthFor(activeDestination),
    );
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
              ? (dashboard.team?.description ??
                    'Manage your profile and theme in one place.')
              : viewer.canManageTeam
              ? 'Manage your profile, theme, and team learning space in one place.'
              : 'Keep your profile, theme, and learner space settings in one place.',
          trailing: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _BrandPalette.goldBright,
                        _BrandPalette.goldDeep,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _identityInitials(username),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _BrandPalette.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _viewerRoleLabel(viewer),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  viewer == null ? 'Signed out' : '@${viewer.username}',
                  style: theme.textTheme.bodySmall,
                ),
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
                  viewer.canManageTeam
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
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.14,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      _identityInitials(viewer.displayName),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(viewer.displayName),
                  subtitle: Text(
                    '@${viewer.username}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: _PillBadge(
                    text: _viewerRoleLabel(viewer),
                    color: viewer.canManageTeam
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    textColor: viewer.canManageTeam
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _AppearancePanel(controller: widget.themeController),
            ],
          ),
        ),
      ],
    );
  }
}
