part of '../../../main.dart';

enum _LearnerWorkspaceSection { continueFlow, practice, journey, progress }

class _LearnerWorkspaceDesktop extends StatefulWidget {
  const _LearnerWorkspaceDesktop({
    required this.viewer,
    required this.detail,
    required this.viewerCanReadLibrary,
    required this.onOpenLibraryRoute,
    required this.onStartActivity,
  });

  final ViewerUser? viewer;
  final LearnerDetailPayload detail;
  final bool viewerCanReadLibrary;
  final ValueChanged<String> onOpenLibraryRoute;
  final Future<void> Function(SessionDetail session, SessionMaterial material)
  onStartActivity;

  @override
  State<_LearnerWorkspaceDesktop> createState() =>
      _LearnerWorkspaceDesktopState();
}

class _LearnerWorkspaceDesktopState extends State<_LearnerWorkspaceDesktop> {
  _LearnerWorkspaceSection _section = _LearnerWorkspaceSection.continueFlow;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = _defaultSessionFor(_section)?.sessionId;
  }

  @override
  void didUpdateWidget(covariant _LearnerWorkspaceDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  LearnerWorkspace get _workspace => widget.detail.workspace;

  SessionDetail? _defaultSessionFor(_LearnerWorkspaceSection section) {
    if (section == _LearnerWorkspaceSection.continueFlow) {
      return _workspace.continueBlock?.session;
    }
    final sessions = _sessionsFor(section);
    return sessions.isEmpty ? null : sessions.first;
  }

  List<SessionDetail> _sessionsFor(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.continueFlow:
        final session = _workspace.continueBlock?.session;
        return session == null
            ? const <SessionDetail>[]
            : <SessionDetail>[session];
      case _LearnerWorkspaceSection.practice:
        return _workspace.practiceLane;
      case _LearnerWorkspaceSection.journey:
        return widget.detail.sessions;
      case _LearnerWorkspaceSection.progress:
        return const <SessionDetail>[];
    }
  }

  SessionDetail? _selectedSession() {
    final sessions = _sessionsFor(_section);
    if (sessions.isEmpty) {
      return null;
    }
    for (final session in sessions) {
      if (session.sessionId == _selectedSessionId) {
        return session;
      }
    }
    return sessions.first;
  }

  void _syncSelection() {
    final sessions = _sessionsFor(_section);
    if (sessions.isEmpty) {
      _selectedSessionId = null;
      return;
    }
    final hasCurrent = sessions.any(
      (session) => session.sessionId == _selectedSessionId,
    );
    if (!hasCurrent) {
      _selectedSessionId = sessions.first.sessionId;
    }
  }

  void _selectSection(_LearnerWorkspaceSection section) {
    setState(() {
      _section = section;
      _selectedSessionId = _defaultSessionFor(section)?.sessionId;
      _syncSelection();
    });
  }

  String _sectionLabel(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.continueFlow:
        return 'Continue';
      case _LearnerWorkspaceSection.practice:
        return 'Practice';
      case _LearnerWorkspaceSection.journey:
        return 'Journey';
      case _LearnerWorkspaceSection.progress:
        return 'Progress';
    }
  }

  IconData _sectionIcon(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.continueFlow:
        return Icons.play_circle_outline_rounded;
      case _LearnerWorkspaceSection.practice:
        return Icons.fitness_center_rounded;
      case _LearnerWorkspaceSection.journey:
        return Icons.route_rounded;
      case _LearnerWorkspaceSection.progress:
        return Icons.analytics_rounded;
    }
  }

  Widget _buildSidebar(ThemeData theme) {
    final journey = widget.detail.journey;
    final sectionSessions = _sessionsFor(_section);
    final practiceCount = _workspace.practiceLane.length;
    final reviewCount = _workspace.progressSnapshot.reviewItemCount;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning flow', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Select the section and session to open learner materials directly.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (journey != null)
                _PillBadge(
                  text:
                      '${journey.completedSessionCount} complete · ${journey.pendingSessionCount} ahead',
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
              _PillBadge(
                text:
                    '$practiceCount practice step${practiceCount == 1 ? '' : 's'}',
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                textColor: theme.colorScheme.primary,
              ),
              _PillBadge(
                text: '$reviewCount review item${reviewCount == 1 ? '' : 's'}',
                color: theme.colorScheme.tertiaryContainer,
                textColor: theme.colorScheme.onTertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (journey != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journey.playlistTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Route: ${journey.totalSessionCount} sessions · ${journey.totalMaterialCount} materials',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  ..._LearnerWorkspaceSection.values.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DesktopSidebarButton(
                        label: _sectionLabel(section),
                        icon: _sectionIcon(section),
                        selected: _section == section,
                        onTap: () => _selectSection(section),
                      ),
                    ),
                  ),
                  if (_section != _LearnerWorkspaceSection.progress &&
                      sectionSessions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('Steps', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    ...sectionSessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DesktopSessionNavTile(
                          title: session.title,
                          subtitle: 'Session ${session.sequenceNumber ?? '?'}',
                          statusLabel: session.status == 'completed'
                              ? 'Done'
                              : _contractTermLabel(session.dominantKind),
                          selected: session.sessionId == _selectedSessionId,
                          onTap: () => setState(
                            () => _selectedSessionId = session.sessionId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStudio(
    ThemeData theme, {
    required String eyebrow,
    required String description,
    required SessionDetail session,
  }) {
    final learnerGroups = session.materialsByKind
        .where((group) => group.audience == 'learner')
        .toList(growable: false);
    final availableRoutes = session.materials
        .map((material) => material.documentRoutePath)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final materialKinds = <String, int>{};
    for (final material in session.materials) {
      materialKinds.update(
        material.kind,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Text(session.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          _ContractChipRow(
            children: [
              const _ContractChip(domain: 'entity', value: 'session'),
              _ContractChip(
                domain: 'material_kind',
                value: session.dominantKind,
              ),
              if (session.estimatedMinutes > 0)
                _PillBadge(
                  text: '${session.estimatedMinutes} min',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              if (session.requiresAdultSupport)
                _ContractChip(domain: 'status', value: 'adult_guided'),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final split = constraints.maxWidth > 900;
                final summary = SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.36),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session summary',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _ContractChipRow(
                          children: [
                            _PillBadge(
                              text:
                                  'learner_count:${session.learnerMaterialCount}',
                              color: _contractChipBackgroundColor(
                                theme,
                                domain: 'audience',
                                value: 'learner',
                              ),
                              textColor: _contractChipForegroundColor(
                                theme,
                                domain: 'audience',
                                value: 'learner',
                              ),
                            ),
                            _PillBadge(
                              text: 'live_count:${session.liveMaterialCount}',
                              color: _contractChipBackgroundColor(
                                theme,
                                domain: 'status',
                                value: 'live',
                              ),
                              textColor: _contractChipForegroundColor(
                                theme,
                                domain: 'status',
                                value: 'live',
                              ),
                            ),
                          ],
                        ),
                        if (materialKinds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ContractChipRow(
                            children: materialKinds.entries
                                .map(
                                  (entry) => _PillBadge(
                                    text:
                                        '${_contractTermLabel(entry.key)}:${entry.value}',
                                    color: _materialKindBackgroundColor(
                                      theme,
                                      entry.key,
                                    ),
                                    textColor: _materialKindForegroundColor(
                                      theme,
                                      entry.key,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                        if (widget.viewerCanReadLibrary &&
                            availableRoutes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text('References', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          ...availableRoutes
                              .take(2)
                              .map(
                                (route) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TextButton(
                                    onPressed: () =>
                                        widget.onOpenLibraryRoute(route),
                                    child: const Text('Open linked material'),
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                );
                final content = SingleChildScrollView(
                  child: learnerGroups.isEmpty
                      ? const _MissingLearnerContentNotice()
                      : Column(
                          children: learnerGroups
                              .map(
                                (group) => _SessionMaterialGroupPanel(
                                  group: group,
                                  session: session,
                                  viewerCanReadLibrary:
                                      widget.viewerCanReadLibrary,
                                  showDocumentBodies: true,
                                  onOpenLibraryRoute: widget.onOpenLibraryRoute,
                                  onStartActivity: widget.onStartActivity,
                                ),
                              )
                              .toList(growable: false),
                        ),
                );

                if (!split) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summary,
                      const SizedBox(height: 16),
                      Expanded(child: content),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: summary),
                    const SizedBox(width: 18),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStudio(ThemeData theme) {
    final snapshot = _workspace.progressSnapshot;
    final recentWins = _workspace.recentWins;
    final reviewItems = widget.detail.reviewItems;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress and review', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'See what is secure, what still needs practice, and what should be reviewed next.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatChip(
                        label: 'Secure',
                        value: '${snapshot.secureCount}',
                        icon: Icons.verified_rounded,
                      ),
                      _StatChip(
                        label: 'Developing',
                        value: '${snapshot.developingCount}',
                        icon: Icons.construction_rounded,
                      ),
                      _StatChip(
                        label: 'Not Started',
                        value: '${snapshot.notStartedCount}',
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                      _StatChip(
                        label: 'Review',
                        value: '${snapshot.reviewItemCount}',
                        icon: Icons.pending_actions_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Recent wins', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (recentWins.isEmpty)
                    Text(
                      'Completed work will appear here once this learner has recorded evidence.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...recentWins.map(
                      (win) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(win.sessionTitle),
                          subtitle: Text(
                            win.notes.isEmpty
                                ? 'Completed and recorded in the learner history.'
                                : win.notes,
                          ),
                          trailing: _PillBadge(
                            text: win.scoreLabel,
                            color: theme.colorScheme.secondaryContainer,
                            textColor: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text('Review queue', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (reviewItems.isEmpty)
                    Text(
                      'No review items are waiting.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...reviewItems.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.reason),
                        subtitle: Text(_contractTermLabel(item.skillId)),
                        trailing: _PillBadge(
                          text: item.dueDate,
                          color: theme.colorScheme.errorContainer,
                          textColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journey = widget.detail.journey;
    final snapshot = _workspace.progressSnapshot;
    final selectedSession = _selectedSession();

    Widget mainPanel;
    switch (_section) {
      case _LearnerWorkspaceSection.continueFlow:
        if (selectedSession == null) {
          mainPanel = _SurfaceCard(
            child: Text(
              'There is no active learner step yet.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        } else {
          mainPanel = _buildSessionStudio(
            theme,
            eyebrow: 'Continue',
            description:
                _workspace.continueBlock?.description ??
                'Open the current step and go straight into the learner material.',
            session: selectedSession,
          );
        }
      case _LearnerWorkspaceSection.practice:
        if (selectedSession == null) {
          mainPanel = _SurfaceCard(
            child: Text(
              'No practice steps are ready yet.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        } else {
          mainPanel = _buildSessionStudio(
            theme,
            eyebrow: 'Practice',
            description:
                'Choose a practice or check step from the left and work through the learner material directly.',
            session: selectedSession,
          );
        }
      case _LearnerWorkspaceSection.journey:
        if (selectedSession == null) {
          mainPanel = _SurfaceCard(
            child: Text(
              'No journey steps are available yet.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        } else {
          mainPanel = _buildSessionStudio(
            theme,
            eyebrow: 'Journey',
            description:
                'Inspect any step in the route without opening and collapsing a stack of nested cards.',
            session: selectedSession,
          );
        }
      case _LearnerWorkspaceSection.progress:
        mainPanel = _buildProgressStudio(theme);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PillBadge(
                    text: 'workspace',
                    color: theme.colorScheme.secondaryContainer,
                    textColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Learner workspace',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (_workspace.attentionLabel.isNotEmpty)
                    _PillBadge(
                      text: _workspace.attentionLabel,
                      color: theme.colorScheme.tertiaryContainer,
                      textColor: theme.colorScheme.onTertiaryContainer,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Follow the learning flow: Continue, Practice, Journey, and Progress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _ContractChipRow(
                children: [
                  _PillBadge(
                    text: journey == null
                        ? 'standing:--'
                        : 'standing:S${journey.completedSessionCount + 1}/${journey.totalSessionCount}',
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    textColor: theme.colorScheme.primary,
                  ),
                  _PillBadge(
                    text: 'completed:${snapshot.completedSessionCount}',
                    color: theme.colorScheme.secondaryContainer,
                    textColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  _PillBadge(
                    text: 'ready_now:${snapshot.pendingSessionCount}',
                    color: theme.colorScheme.tertiaryContainer,
                    textColor: theme.colorScheme.onTertiaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: _desktopStudioHeight(
            context,
            subtract: 210,
            minHeight: 720,
            maxHeight: 980,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: _buildSidebar(theme)),
              const SizedBox(width: 20),
              Expanded(child: mainPanel),
            ],
          ),
        ),
      ],
    );
  }
}
