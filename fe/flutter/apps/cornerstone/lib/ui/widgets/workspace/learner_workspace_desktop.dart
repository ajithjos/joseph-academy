part of '../../../main.dart';

enum _LearnerWorkspaceSection { now, practice, journey, progress }

class _LearnerWorkspaceDesktop extends StatefulWidget {
  const _LearnerWorkspaceDesktop({
    required this.viewer,
    required this.workspace,
    required this.viewerCanReadLibrary,
    required this.onOpenLibraryRoute,
    required this.onStartActivity,
  });

  final ViewerUser? viewer;
  final LearnerWorkspacePayload workspace;
  final bool viewerCanReadLibrary;
  final ValueChanged<String> onOpenLibraryRoute;
  final Future<void> Function(SessionDetail session, SessionMaterial material)
  onStartActivity;

  @override
  State<_LearnerWorkspaceDesktop> createState() =>
      _LearnerWorkspaceDesktopState();
}

class _LearnerWorkspaceDesktopState extends State<_LearnerWorkspaceDesktop> {
  _LearnerWorkspaceSection _section = _LearnerWorkspaceSection.now;
  final Map<_LearnerWorkspaceSection, String?> _selectedSessionIds =
      <_LearnerWorkspaceSection, String?>{};

  @override
  void initState() {
    super.initState();
    _syncSelections();
  }

  @override
  void didUpdateWidget(covariant _LearnerWorkspaceDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelections();
  }

  LearnerWorkspace get _workspace => widget.workspace.workspace;

  LearnerJourney? get _journey => widget.workspace.journey;

  SessionDetail? get _continueSession {
    final continueSession = _workspace.continueBlock?.session;
    if (continueSession != null) {
      return continueSession;
    }
    for (final session in widget.workspace.sessions) {
      if (session.status != 'completed') {
        return session;
      }
    }
    return null;
  }

  List<SessionDetail> _sessionsFor(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.now:
        final session = _continueSession;
        return session == null
            ? const <SessionDetail>[]
            : <SessionDetail>[session];
      case _LearnerWorkspaceSection.practice:
        return _workspace.practiceLane;
      case _LearnerWorkspaceSection.journey:
        return widget.workspace.sessions;
      case _LearnerWorkspaceSection.progress:
        return const <SessionDetail>[];
    }
  }

  SessionDetail? _selectedSession() {
    final sessions = _sessionsFor(_section);
    if (sessions.isEmpty) {
      return null;
    }
    final selectedSessionId = _selectedSessionIds[_section];
    for (final session in sessions) {
      if (session.sessionId == selectedSessionId) {
        return session;
      }
    }
    return sessions.first;
  }

  void _syncSelection(_LearnerWorkspaceSection section) {
    final sessions = _sessionsFor(section);
    if (sessions.isEmpty) {
      _selectedSessionIds[section] = null;
      return;
    }
    final selectedSessionId = _selectedSessionIds[section];
    final hasCurrent = sessions.any(
      (session) => session.sessionId == selectedSessionId,
    );
    if (!hasCurrent) {
      _selectedSessionIds[section] = sessions.first.sessionId;
    }
  }

  void _syncSelections() {
    for (final section in _LearnerWorkspaceSection.values) {
      _syncSelection(section);
    }
  }

  void _selectSection(_LearnerWorkspaceSection section) {
    setState(() {
      _section = section;
      _syncSelection(section);
    });
  }

  void _selectSession(String sessionId) {
    setState(() {
      _selectedSessionIds[_section] = sessionId;
    });
  }

  String _sectionLabel(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.now:
        return 'Now';
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
      case _LearnerWorkspaceSection.now:
        return Icons.play_circle_outline_rounded;
      case _LearnerWorkspaceSection.practice:
        return Icons.fitness_center_rounded;
      case _LearnerWorkspaceSection.journey:
        return Icons.route_rounded;
      case _LearnerWorkspaceSection.progress:
        return Icons.analytics_rounded;
    }
  }

  String _sectionSubtitle(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.now:
        return 'Resume the next session without browsing around.';
      case _LearnerWorkspaceSection.practice:
        return 'Open drills, worksheets, and checks that are ready now.';
      case _LearnerWorkspaceSection.journey:
        return 'See the full route and jump to any session workspace.';
      case _LearnerWorkspaceSection.progress:
        return 'Review mastery, wins, and review queue in one place.';
    }
  }

  String _sectionCountLabel(_LearnerWorkspaceSection section) {
    if (section == _LearnerWorkspaceSection.progress) {
      return '${widget.workspace.reviewItems.length} review';
    }
    final count = _sessionsFor(section).length;
    return '$count step${count == 1 ? '' : 's'}';
  }

  Widget _buildWorkspaceHeader(ThemeData theme) {
    final journey = _journey;
    final snapshot = _workspace.progressSnapshot;
    final continueSession = _continueSession;
    final standingLabel = journey == null
        ? '--'
        : 'S${journey.completedSessionCount + 1}/${journey.totalSessionCount}';
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PillBadge(
                text: 'learner',
                color: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'My learning workspace',
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
            'Land on what to do now, keep practising with purpose, and track progress clearly.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ContractChipRow(
            children: [
              _StatChip(
                label: 'Standing',
                value: standingLabel,
                icon: Icons.place_rounded,
              ),
              _StatChip(
                label: 'Completed',
                value: '${snapshot.completedSessionCount}',
                icon: Icons.task_alt_rounded,
              ),
              _StatChip(
                label: 'Ready now',
                value: '${snapshot.pendingSessionCount}',
                icon: Icons.rocket_launch_rounded,
              ),
              _StatChip(
                label: 'Review',
                value: '${snapshot.reviewItemCount}',
                icon: Icons.pending_actions_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (continueSession != null)
                FilledButton.icon(
                  onPressed: () {
                    _selectSection(_LearnerWorkspaceSection.now);
                    _selectSession(continueSession.sessionId);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume now'),
                ),
              if (_workspace.practiceLane.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _selectSection(
                    _LearnerWorkspaceSection.practice,
                  ),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('Open practice lane'),
                ),
              if (snapshot.reviewItemCount > 0)
                TextButton.icon(
                  onPressed: () => _selectSection(
                    _LearnerWorkspaceSection.progress,
                  ),
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('See progress report'),
                ),
              if (widget.viewerCanReadLibrary &&
                  journey != null &&
                  journey.playlistRoutePath != null)
                TextButton.icon(
                  onPressed: () => widget.onOpenLibraryRoute(
                    journey.playlistRoutePath!,
                  ),
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Open route brief'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final journey = _journey;
    final sectionSessions = _sessionsFor(_section);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning lanes', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            _sectionSubtitle(_section),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          ..._LearnerWorkspaceSection.values.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DesktopSidebarButton(
                label: '${_sectionLabel(section)} · ${_sectionCountLabel(section)}',
                icon: _sectionIcon(section),
                selected: _section == section,
                onTap: () => _selectSection(section),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                  if (_section != _LearnerWorkspaceSection.progress &&
                      sectionSessions.isNotEmpty) ...[
                    Text('In this lane', style: theme.textTheme.titleSmall),
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
                          selected: session.sessionId ==
                              _selectedSessionIds[_section],
                          onTap: () => _selectSession(session.sessionId),
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
    String? laneActionLabel,
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
          if (laneActionLabel != null) ...[
            _PillBadge(
              text: laneActionLabel,
              color: theme.colorScheme.secondaryContainer,
              textColor: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
          ],
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
                        Text('Session plan', style: theme.textTheme.titleMedium),
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
                          ...availableRoutes.take(2).map(
                            (route) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextButton(
                                onPressed: () => widget.onOpenLibraryRoute(route),
                                child: const Text('Open linked source'),
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

  Widget _buildJourneyOutline(ThemeData theme, SessionDetail? selectedSession) {
    final sessions = widget.workspace.sessions;
    if (sessions.isEmpty) {
      return _SurfaceCard(
        child: Text(
          'No journey steps are available yet.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Journey outline', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Select any session to open it in the learner studio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ...sessions.map((session) {
            final selected = selectedSession?.sessionId == session.sessionId;
            final completed = session.status == 'completed';
            final color = completed
                ? theme.colorScheme.secondaryContainer
                : selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest;
            final textColor = completed
                ? theme.colorScheme.onSecondaryContainer
                : selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _selectSession(session.sessionId),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: textColor.withValues(alpha: 0.16),
                        foregroundColor: textColor,
                        child: Text('${session.sequenceNumber ?? '?'}'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          session.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PillBadge(
                        text:
                            completed ? 'Done' : _contractTermLabel(session.dominantKind),
                        color: textColor.withValues(alpha: 0.14),
                        textColor: textColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressMeter(
    ThemeData theme, {
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text('$value', style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStudio(ThemeData theme) {
    final snapshot = _workspace.progressSnapshot;
    final recentWins = _workspace.recentWins;
    final reviewItems = widget.workspace.reviewItems;
    final masteredTotal = snapshot.secureCount +
        snapshot.developingCount +
        snapshot.notStartedCount;

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
                  _buildProgressMeter(
                    theme,
                    label: 'Secure',
                    value: snapshot.secureCount,
                    total: masteredTotal,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressMeter(
                    theme,
                    label: 'Developing',
                    value: snapshot.developingCount,
                    total: masteredTotal,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressMeter(
                    theme,
                    label: 'Not started',
                    value: snapshot.notStartedCount,
                    total: masteredTotal,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressMeter(
                    theme,
                    label: 'Review queue',
                    value: snapshot.reviewItemCount,
                    total: snapshot.reviewItemCount > 0
                        ? snapshot.reviewItemCount
                        : 1,
                    color: theme.colorScheme.tertiary,
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
    final selectedSession = _selectedSession();

    Widget mainPanel;
    switch (_section) {
      case _LearnerWorkspaceSection.now:
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
            eyebrow: 'Now',
            description:
                _workspace.continueBlock?.description ??
                'Open your next step and start the learner materials directly.',
            session: selectedSession,
            laneActionLabel: _workspace.continueBlock?.actionLabel,
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
                'Choose any practice or check step and complete it from one place.',
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
          mainPanel = Column(
            children: [
              _buildJourneyOutline(theme, selectedSession),
              const SizedBox(height: 14),
              Expanded(
                child: _buildSessionStudio(
                  theme,
                  eyebrow: 'Journey session',
                  description:
                      'Inspect the selected step and open learner materials below.',
                  session: selectedSession,
                ),
              ),
            ],
          );
        }
      case _LearnerWorkspaceSection.progress:
        mainPanel = _buildProgressStudio(theme);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _buildWorkspaceHeader(theme),
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
