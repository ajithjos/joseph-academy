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

  LearnerWorkspace get _workspace => widget.workspace.workspace;

  LearnerJourney? get _journey => widget.workspace.journey;

  bool get _isSupportView => widget.workspace.workspaceView == 'owner_support';

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
        return 'Do now';
      case _LearnerWorkspaceSection.practice:
        return 'Extra practice';
      case _LearnerWorkspaceSection.journey:
        return 'Full route';
      case _LearnerWorkspaceSection.progress:
        return 'How it is going';
    }
  }

  String _sectionDescription(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.now:
        return 'Open the exact session to do now.';
      case _LearnerWorkspaceSection.practice:
        return 'Pick worksheet, drill, or quick check items.';
      case _LearnerWorkspaceSection.journey:
        return 'See every session in this playbook path.';
      case _LearnerWorkspaceSection.progress:
        return 'Review secure, developing, and review items.';
    }
  }

  IconData _sectionIcon(_LearnerWorkspaceSection section) {
    switch (section) {
      case _LearnerWorkspaceSection.now:
        return Icons.play_circle_outline_rounded;
      case _LearnerWorkspaceSection.practice:
        return Icons.sports_score_rounded;
      case _LearnerWorkspaceSection.journey:
        return Icons.alt_route_rounded;
      case _LearnerWorkspaceSection.progress:
        return Icons.insights_rounded;
    }
  }

  String _sectionCountLabel(_LearnerWorkspaceSection section) {
    if (section == _LearnerWorkspaceSection.progress) {
      return '${widget.workspace.reviewItems.length} review';
    }
    final count = _sessionsFor(section).length;
    return '$count session${count == 1 ? '' : 's'}';
  }

  Widget _buildHeader(ThemeData theme) {
    final journey = _journey;
    final snapshot = _workspace.progressSnapshot;
    final standingLabel = journey == null
        ? '--'
        : 'S${journey.completedSessionCount + 1}/${journey.totalSessionCount}';
    final title = _isSupportView
        ? 'Learner workspace preview'
        : 'My learning workspace';

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PillBadge(
                text: _isSupportView ? 'owner_support' : 'learner',
                color: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
              ),
              _PillBadge(
                text: 'role:${widget.workspace.viewerRole}',
                color: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
              if (widget.workspace.includesAdultMaterials)
                _PillBadge(
                  text: 'teaching guidance visible',
                  color: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.onTertiaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            _isSupportView
                ? 'Use this preview to guide the learner through the exact pathway, playbook, and session. Teaching guidance appears in each session when available.'
                : 'Start with Do now, continue with Extra practice, and check progress clearly.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
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
        ],
      ),
    );
  }

  Widget _buildPathContext(ThemeData theme, SessionDetail? session) {
    final journey = _journey;
    if (journey == null && session == null) {
      return const SizedBox.shrink();
    }
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where am I?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Pathway -> Playbook -> Session context for this lane.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (journey?.pathwayTitle != null)
                _PillBadge(
                  text: 'Pathway: ${journey!.pathwayTitle}',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              if (journey != null)
                _PillBadge(
                  text: 'Playbook: ${journey.playlistTitle}',
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
              if (session != null)
                _PillBadge(
                  text: 'Session ${session.sequenceNumber ?? '?'}: ${session.title}',
                  color: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.onTertiaryContainer,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaneSelector(ThemeData theme) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning lanes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            _sectionDescription(_section),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _LearnerWorkspaceSection.values.map((section) {
              final selected = _section == section;
              return ChoiceChip(
                avatar: Icon(_sectionIcon(section), size: 18),
                label: Text('${_sectionLabel(section)} · ${_sectionCountLabel(section)}'),
                selected: selected,
                onSelected: (_) => _selectSection(section),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSelector(ThemeData theme, List<SessionDetail> sessions) {
    if (sessions.isEmpty) {
      return _SurfaceCard(
        child: Text(
          _section == _LearnerWorkspaceSection.now
              ? 'There is no active session yet.'
              : 'No sessions are available in this lane yet.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final selectedSessionId = _selectedSessionIds[_section];
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a session', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Click a card to open exactly what this session asks the learner to do.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sessions.map((session) {
              final selected = session.sessionId == selectedSessionId;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _selectSession(session.sessionId),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session ${session.sequenceNumber ?? '?'}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
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
                            text: 'learner:${session.learnerMaterialCount}',
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
                          if (_isSupportView)
                            _PillBadge(
                              text: 'adult:${session.adultMaterialCount}',
                              color: _contractChipBackgroundColor(
                                theme,
                                domain: 'audience',
                                value: 'adult',
                              ),
                              textColor: _contractChipForegroundColor(
                                theme,
                                domain: 'audience',
                                value: 'adult',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStudio(ThemeData theme, SessionDetail session) {
    final learnerGroups = session.materialsByKind
        .where((group) => group.audience == 'learner')
        .toList(growable: false);
    final adultGroups = session.materialsByKind
        .where((group) => group.audience == 'adult')
        .toList(growable: false);

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_sectionLabel(_section), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            _sectionDescription(_section),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _ContractChipRow(
            children: [
              const _ContractChip(domain: 'entity', value: 'session'),
              _ContractChip(domain: 'material_kind', value: session.dominantKind),
              if (session.requiresAdultSupport)
                const _ContractChip(domain: 'status', value: 'adult_guided'),
              if (session.estimatedMinutes > 0)
                _PillBadge(
                  text: '${session.estimatedMinutes} min',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (learnerGroups.isEmpty)
            const _MissingLearnerContentNotice()
          else
            _SessionWorkspaceAudiencePanel(
              title: _isSupportView
                  ? 'Learner materials in this session'
                  : 'What I work on in this session',
              description:
                  'Lesson notes, worksheets, drills, and checks for the learner are grouped here.',
              emptyState:
                  'No learner-facing materials are attached to this session yet.',
              icon: Icons.school_rounded,
              groups: learnerGroups,
              session: session,
              viewerCanReadLibrary: widget.viewerCanReadLibrary,
              showDocumentBodies: true,
              onOpenLibraryRoute: widget.onOpenLibraryRoute,
              onStartActivity: widget.onStartActivity,
            ),
          if (_isSupportView && adultGroups.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SessionWorkspaceAudiencePanel(
              title: 'Teaching guidance for parent or teacher',
              description:
                  'Use these teaching notes to guide explanation, correction, and pacing before or during learner work.',
              emptyState: 'No teaching guidance is attached to this session yet.',
              icon: Icons.co_present_rounded,
              groups: adultGroups,
              session: session,
              viewerCanReadLibrary: widget.viewerCanReadLibrary,
              showDocumentBodies: true,
              onOpenLibraryRoute: widget.onOpenLibraryRoute,
              onStartActivity: widget.onStartActivity,
            ),
          ],
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
          Text('How it is going', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'This shows what is secure, what is developing, and what should be reviewed next.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
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
            total: snapshot.reviewItemCount > 0 ? snapshot.reviewItemCount : 1,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 22),
          Text('Recent wins', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          if (recentWins.isEmpty)
            Text(
              'Completed work appears here when evidence is recorded.',
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
                        ? 'Completed and recorded in learner history.'
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
    );
  }

  Widget _buildMainPanel(ThemeData theme, SessionDetail? selectedSession) {
    if (_section == _LearnerWorkspaceSection.progress) {
      return _buildProgressStudio(theme);
    }
    if (selectedSession == null) {
      return _SurfaceCard(
        child: Text(
          'No session is selected for this lane yet.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
    return _buildSessionStudio(theme, selectedSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = _sessionsFor(_section);
    final selectedSession = _selectedSession();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _buildHeader(theme),
        const SizedBox(height: 14),
        _buildLaneSelector(theme),
        const SizedBox(height: 14),
        _buildPathContext(theme, selectedSession),
        if (_section != _LearnerWorkspaceSection.progress) ...[
          const SizedBox(height: 14),
          _buildSessionSelector(theme, sessions),
        ],
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _desktopStudioHeight(
              context,
              subtract: 320,
              minHeight: 460,
              maxHeight: 760,
            ),
          ),
          child: _buildMainPanel(theme, selectedSession),
        ),
      ],
    );
  }
}
