part of '../../../main.dart';

class _LearnerWorkspaceView extends StatelessWidget {
  const _LearnerWorkspaceView({
    required this.viewer,
    required this.detail,
    required this.viewerCanReadLibrary,
    required this.onOpenLibraryRoute,
    required this.onStartActivity,
  });

  final ViewerUser? viewer;
  final LearnerDetailPayload? detail;
  final bool viewerCanReadLibrary;
  final ValueChanged<String> onOpenLibraryRoute;
  final Future<void> Function(SessionDetail session, SessionMaterial material)
  onStartActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final learnerDetail = detail;
    if (learnerDetail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_rounded,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                viewer != null && viewer!.isLearner
                    ? 'This username is not linked to a learner profile yet.'
                    : 'Select a learner to open the learner workspace.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final journey = learnerDetail.journey;
    final workspace = learnerDetail.workspace;
    final continueBlock = workspace.continueBlock;
    final nextSession =
        continueBlock?.session ??
        learnerDetail.sessions
            .where((session) => session.status != 'completed')
            .cast<SessionDetail?>()
            .firstWhere(
              (session) =>
                  session?.sessionId == journey?.nextSessionId ||
                  journey?.nextSessionId == null,
              orElse: () => null,
            ) ??
        learnerDetail.sessions
            .where((session) => session.status != 'completed')
            .cast<SessionDetail?>()
            .firstWhere((_) => true, orElse: () => null);
    final currentStanding =
        nextSession?.sequenceNumber ??
        (journey != null && journey.totalSessionCount > 0
            ? (journey.completedSessionCount + 1).clamp(
                1,
                journey.totalSessionCount,
              )
            : null);
    final journeyProgress = journey == null || journey.totalSessionCount == 0
        ? null
        : (journey.completedSessionCount / journey.totalSessionCount).clamp(
            0.0,
            1.0,
          );
    final progressStatusCounts = <String, int>{};
    for (final state in learnerDetail.progress) {
      progressStatusCounts.update(
        state.status,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final practiceSessions = workspace.practiceLane;
    final progressSnapshot = workspace.progressSnapshot;
    final recentWins = workspace.recentWins;

    if (MediaQuery.sizeOf(context).width > 1080) {
      return _LearnerWorkspaceDesktop(
        viewer: viewer,
        detail: learnerDetail,
        viewerCanReadLibrary: viewerCanReadLibrary,
        onOpenLibraryRoute: onOpenLibraryRoute,
        onStartActivity: onStartActivity,
      );
    }

    Widget buildSessionSequenceCard(
      SessionDetail session, {
      required bool active,
    }) {
      final learnerGroups = session.materialsByKind
          .where((group) => group.audience == 'learner')
          .toList(growable: false);
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.55)
              : theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? theme.colorScheme.secondary.withValues(alpha: 0.26)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 14),
            initiallyExpanded: active,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: active
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  foregroundColor: active
                      ? theme.colorScheme.onSecondary
                      : theme.colorScheme.primary,
                  child: Text('${session.sequenceNumber ?? '?'}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ContractChip(
                            domain: 'material_kind',
                            value: session.dominantKind,
                          ),
                          if (session.requiresAdultSupport)
                            _PillBadge(
                              text: 'Adult support',
                              color: theme.colorScheme.tertiaryContainer,
                              textColor: theme.colorScheme.onTertiaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PillBadge(
                  text: session.status == 'completed'
                      ? 'Done'
                      : session.scheduledDate,
                  color: active
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: active
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.primary,
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: session.materialsByKind
                    .map(
                      (group) => _PillBadge(
                        text:
                            'material_kind:${_contractTermLabel(group.kind)} · count:${group.materialCount}',
                        color: _materialKindBackgroundColor(theme, group.kind),
                        textColor: _materialKindForegroundColor(
                          theme,
                          group.kind,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            children: [
              if (learnerGroups.isEmpty)
                const _MissingLearnerContentNotice()
              else
                _SessionWorkspaceAudiencePanel(
                  title: active
                      ? 'Current session workspace'
                      : 'Session workspace',
                  description:
                      'Open this session to read the note, work through the practice, and launch live activity items.',
                  emptyState:
                      'No learner-facing materials are attached to this session yet.',
                  icon: Icons.school_rounded,
                  groups: learnerGroups,
                  session: session,
                  viewerCanReadLibrary: viewerCanReadLibrary,
                  showDocumentBodies: true,
                  onOpenLibraryRoute: onOpenLibraryRoute,
                  onStartActivity: onStartActivity,
                ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _PageHeroCard(
          eyebrow: 'Learning workspace',
          title: 'My learning workspace',
          description: journey == null
              ? 'This is where your pathway, your current standing, and your session workspaces appear.'
              : workspace.attentionLabel.isNotEmpty
              ? workspace.attentionLabel
              : currentStanding == null
              ? 'You are part of ${journey.playlistTitle}. Open the session workspaces below to see what you learn and practise.'
              : 'You are in ${journey.playlistTitle}, standing at session $currentStanding of ${journey.totalSessionCount}. Open the workspace below to learn, practise, and check your progress.',
          chips: [
            _StatChip(
              label: 'Standing',
              value: currentStanding == null
                  ? '--'
                  : 'S$currentStanding/${journey?.totalSessionCount ?? learnerDetail.sessions.length}',
              icon: Icons.place_rounded,
            ),
            _StatChip(
              label: 'Completed',
              value: '${progressSnapshot.completedSessionCount}',
              icon: Icons.task_alt_rounded,
            ),
            _StatChip(
              label: 'Ready Now',
              value: '${progressSnapshot.pendingSessionCount}',
              icon: Icons.rocket_launch_rounded,
            ),
          ],
        ),
        if (journey != null) ...[
          const SizedBox(height: 20),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My current pathway',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  journey.pathwayTitle ?? journey.playlistTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const _ContractChipRow(
                  children: [
                    _ContractChip(domain: 'entity', value: 'pathway'),
                    _ContractChip(domain: 'entity', value: 'playlist'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  journey.pathwayDescription ?? journey.playlistDescription,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PillBadge(
                      text: '${journey.totalSessionCount} sessions',
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      textColor: theme.colorScheme.primary,
                    ),
                    _PillBadge(
                      text: '${journey.totalMaterialCount} materials',
                      color: theme.colorScheme.secondaryContainer,
                      textColor: theme.colorScheme.onSecondaryContainer,
                    ),
                    if (journey.recommendedLevel.isNotEmpty)
                      _PillBadge(
                        text: journey.recommendedLevel,
                        color: theme.colorScheme.tertiaryContainer,
                        textColor: theme.colorScheme.onTertiaryContainer,
                      ),
                  ],
                ),
                if (journeyProgress != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: journeyProgress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStanding == null
                        ? '${journey.completedSessionCount} of ${journey.totalSessionCount} sessions completed'
                        : 'You are standing at session $currentStanding of ${journey.totalSessionCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (viewerCanReadLibrary &&
                    (journey.pathwayRoutePath != null ||
                        journey.playlistRoutePath != null)) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (journey.pathwayRoutePath != null)
                        TextButton(
                          onPressed: () =>
                              onOpenLibraryRoute(journey.pathwayRoutePath!),
                          child: const Text('Open pathway brief'),
                        ),
                      if (journey.playlistRoutePath != null)
                        TextButton(
                          onPressed: () =>
                              onOpenLibraryRoute(journey.playlistRoutePath!),
                          child: const Text('Open playlist brief'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (nextSession != null) ...[
          const SizedBox(height: 20),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  continueBlock?.description ??
                      'This is the workspace for what you are learning right now. Read the note, do the practice, and launch the live step from here.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                if (continueBlock != null) ...[
                  Text(continueBlock.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                ],
                _ContractChipRow(
                  children: [
                    if (continueBlock != null)
                      _PillBadge(
                        text: continueBlock.actionLabel,
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                    const _ContractChip(domain: 'entity', value: 'session'),
                    _ContractChip(
                      domain: 'material_kind',
                      value: nextSession.dominantKind,
                    ),
                    if (nextSession.requiresAdultSupport)
                      const _ContractChip(
                        domain: 'status',
                        value: 'adult_guided',
                      ),
                    if (nextSession.estimatedMinutes > 0)
                      _PillBadge(
                        text: '${nextSession.estimatedMinutes} min',
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        textColor: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final learnerGroups = nextSession.materialsByKind
                        .where((group) => group.audience == 'learner')
                        .toList(growable: false);
                    if (learnerGroups.isEmpty) {
                      return const _MissingLearnerContentNotice();
                    }
                    return _SessionWorkspaceAudiencePanel(
                      title: 'What I work on now',
                      description:
                          'The learner-facing materials for the current session stay together here.',
                      emptyState:
                          'No learner-facing materials are attached to this session yet.',
                      icon: Icons.school_rounded,
                      groups: learnerGroups,
                      session: nextSession,
                      viewerCanReadLibrary: viewerCanReadLibrary,
                      showDocumentBodies: true,
                      onOpenLibraryRoute: onOpenLibraryRoute,
                      onStartActivity: onStartActivity,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        if (recentWins.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent wins', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Completed work that has already been recorded for this learner.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ...recentWins.map(
                  (win) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                win.sessionTitle,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                win.notes.isEmpty
                                    ? 'Completed and recorded in the learner history.'
                                    : win.notes,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _PillBadge(
                          text: win.scoreLabel,
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Journey', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Open any session workspace below to see where you stand and what that session asks you to do.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (learnerDetail.sessions.isEmpty)
                Text(
                  'No sessions are available yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...learnerDetail.sessions.map(
                  (session) => buildSessionSequenceCard(
                    session,
                    active: session.sessionId == nextSession?.sessionId,
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
              Text('Practice workspace', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Open the learner-facing practice and check materials that are already inside your assigned route.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (practiceSessions.isEmpty)
                Text(
                  'No practice items are available yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...practiceSessions.map((session) {
                  final practiceGroups = session.materialsByKind
                      .where(
                        (group) =>
                            group.kind == 'worksheet' ||
                            group.kind == 'drill' ||
                            group.kind == 'quick_check',
                      )
                      .toList(growable: false);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ContractChip(
                              domain: 'material_kind',
                              value: session.dominantKind,
                            ),
                            _PillBadge(
                              text: 'Session ${session.sequenceNumber ?? '?'}',
                              color: theme.colorScheme.surfaceContainerHighest,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...practiceGroups.map(
                          (group) => _SessionMaterialGroupPanel(
                            group: group,
                            session: session,
                            viewerCanReadLibrary: viewerCanReadLibrary,
                            showDocumentBodies: true,
                            onOpenLibraryRoute: onOpenLibraryRoute,
                            onStartActivity: onStartActivity,
                          ),
                        ),
                      ],
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
              Text('Progress', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'A simple snapshot of where this learner is secure, still developing, and not started yet.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (progressStatusCounts.isEmpty &&
                  progressSnapshot.secureCount == 0 &&
                  progressSnapshot.developingCount == 0 &&
                  progressSnapshot.notStartedCount == 0)
                Text(
                  'No progress has been recorded yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PillBadge(
                      text: '${progressSnapshot.secureCount} secure',
                      color: theme.colorScheme.secondaryContainer,
                      textColor: theme.colorScheme.onSecondaryContainer,
                    ),
                    _PillBadge(
                      text: '${progressSnapshot.developingCount} developing',
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      textColor: theme.colorScheme.primary,
                    ),
                    _PillBadge(
                      text: '${progressSnapshot.notStartedCount} not started',
                      color: theme.colorScheme.surfaceContainerHighest,
                      textColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    _PillBadge(
                      text: '${progressSnapshot.reviewItemCount} review items',
                      color: theme.colorScheme.tertiaryContainer,
                      textColor: theme.colorScheme.onTertiaryContainer,
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
              Text('Review items', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'These are the skills that still need another pass.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (learnerDetail.reviewItems.isEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Text('No pending review items.'),
                  ],
                )
              else
                ...learnerDetail.reviewItems.map(
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
      ],
    );
  }
}

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
