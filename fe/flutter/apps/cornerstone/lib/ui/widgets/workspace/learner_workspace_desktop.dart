part of '../../../main.dart';

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
  String? _selectedSessionId;

  LearnerJourney? get _journey => widget.workspace.journey;

  LearnerWorkspace get _workspace => widget.workspace.workspace;

  bool get _isSupportView => widget.workspace.workspaceView == 'owner_support';

  List<SessionDetail> get _orderedSessions {
    final sessions = widget.workspace.sessions.toList(growable: false)
      ..sort((left, right) {
        final leftSequence = left.sequenceNumber ?? 1 << 30;
        final rightSequence = right.sequenceNumber ?? 1 << 30;
        final sequenceCompare = leftSequence.compareTo(rightSequence);
        if (sequenceCompare != 0) return sequenceCompare;
        final dateCompare = left.scheduledDate.compareTo(right.scheduledDate);
        if (dateCompare != 0) return dateCompare;
        return left.title.compareTo(right.title);
      });
    return sessions;
  }

  SessionDetail? get _currentSession {
    for (final session in _orderedSessions) {
      if (session.status != 'completed') {
        return session;
      }
    }
    return null;
  }

  SessionDetail? get _selectedSession {
    final sessions = _orderedSessions;
    if (sessions.isEmpty) {
      return null;
    }
    for (final session in sessions) {
      if (session.sessionId == _selectedSessionId) {
        return session;
      }
    }
    return _currentSession ?? sessions.first;
  }

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(covariant _LearnerWorkspaceDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  void _syncSelection() {
    final selected = _selectedSession;
    _selectedSessionId = selected?.sessionId;
  }

  Widget _buildHeader(ThemeData theme) {
    final journey = _journey;
    final snapshot = _workspace.progressSnapshot;
    final currentSession = _currentSession;
    final currentStanding =
        currentSession?.sequenceNumber ??
        (journey != null && journey.totalSessionCount > 0
            ? (journey.completedSessionCount + 1).clamp(
                1,
                journey.totalSessionCount,
              )
            : null);

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillBadge(
                text: _isSupportView ? 'support view' : 'learner view',
                color: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
              ),
              if (_isSupportView)
                _PillBadge(
                  text: 'role:${widget.workspace.viewerRole}',
                  color: theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isSupportView
                ? 'Learner workspace preview'
                : 'My learning workspace',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _isSupportView
                ? 'Current session is always the first non-completed session in order. Use this page to guide the learner through that step.'
                : 'Current session is always the first non-completed session in order. Start there.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                label: 'Current session',
                value: currentStanding == null
                    ? '--'
                    : '$currentStanding/${journey?.totalSessionCount ?? _orderedSessions.length}',
                icon: Icons.play_circle_outline_rounded,
              ),
              _StatChip(
                label: 'Completed',
                value: '${snapshot.completedSessionCount}',
                icon: Icons.task_alt_rounded,
              ),
              _StatChip(
                label: 'Pending',
                value: '${snapshot.pendingSessionCount}',
                icon: Icons.timelapse_rounded,
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

  Widget _buildPathwayBand(ThemeData theme) {
    final journey = _journey;
    if (journey == null) {
      return _Band(
        title: 'Assigned pathway',
        child: Text(
          'No pathway is assigned yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final currentSession = _currentSession;
    final standing =
        currentSession?.sequenceNumber ??
        (journey.totalSessionCount > 0
            ? (journey.completedSessionCount + 1).clamp(
                1,
                journey.totalSessionCount,
              )
            : null);
    final progress = journey.totalSessionCount == 0
        ? 0.0
        : (journey.completedSessionCount / journey.totalSessionCount).clamp(
            0.0,
            1.0,
          );

    return _Band(
      title: 'Assigned pathway',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (journey.pathwayTitle != null)
            Text(journey.pathwayTitle!, style: theme.textTheme.titleLarge),
          if ((journey.pathwayDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              journey.pathwayDescription!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(journey.playlistTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            journey.playlistDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (standing != null)
                _PillBadge(
                  text:
                      'Current session: $standing/${journey.totalSessionCount}',
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
              _PillBadge(
                text: 'Completed: ${journey.completedSessionCount}',
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                textColor: theme.colorScheme.primary,
              ),
              _PillBadge(
                text: 'Pending: ${journey.pendingSessionCount}',
                color: theme.colorScheme.tertiaryContainer,
                textColor: theme.colorScheme.onTertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionPathBand(ThemeData theme) {
    final sessions = _orderedSessions;
    if (sessions.isEmpty) {
      return _Band(
        title: 'Session path',
        child: Text(
          'No sessions are available yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final currentSessionId = _currentSession?.sessionId;
    return _Band(
      title: 'Session path',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a session card to inspect it. The current session is highlighted.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sessions
                .map((session) {
                  final isCurrent = session.sessionId == currentSessionId;
                  final isSelected = session.sessionId == _selectedSessionId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _selectedSessionId = session.sessionId;
                      });
                    },
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : isCurrent
                            ? theme.colorScheme.secondaryContainer.withValues(
                                alpha: 0.55,
                              )
                            : theme.colorScheme.surface.withValues(alpha: 0.64),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isCurrent
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session ${session.sequenceNumber ?? '?'}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (isCurrent)
                                _PillBadge(
                                  text: 'Current',
                                  color: theme.colorScheme.secondaryContainer,
                                  textColor:
                                      theme.colorScheme.onSecondaryContainer,
                                ),
                              _PillBadge(
                                text: session.status == 'completed'
                                    ? 'Done'
                                    : 'Pending',
                                color: session.status == 'completed'
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                textColor: session.status == 'completed'
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                              ),
                              _ContractChip(
                                domain: 'material_kind',
                                value: session.dominantKind,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionContentBand(ThemeData theme, SessionDetail? session) {
    if (session == null) {
      return _Band(
        title: 'Current session',
        child: Text(
          'No active session is available right now.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final learnerGroups = session.materialsByKind
        .where((group) => group.audience == 'learner')
        .toList(growable: false);
    final adultGroups = session.materialsByKind
        .where((group) => group.audience == 'adult')
        .toList(growable: false);
    final isCurrent = session.sessionId == _currentSession?.sessionId;

    return _Band(
      title: isCurrent ? 'Current session' : 'Selected session',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillBadge(
                text: 'Session ${session.sequenceNumber ?? '-'}',
                color: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
              ),
              if (session.estimatedMinutes > 0)
                _PillBadge(
                  text: '${session.estimatedMinutes} min',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              if (session.requiresAdultSupport)
                _PillBadge(
                  text: 'Adult-guided',
                  color: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.onTertiaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (learnerGroups.isEmpty)
            const _MissingLearnerContentNotice()
          else
            _SessionWorkspaceAudiencePanel(
              title: _isSupportView
                  ? 'Learner items'
                  : 'What I do in this session',
              description:
                  'Everything learner-facing for this session is grouped here.',
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
          if (_isSupportView) ...[
            const SizedBox(height: 12),
            _SessionWorkspaceAudiencePanel(
              title: 'Teaching guidance',
              description:
                  'Use these notes to guide explanation and correction for this session.',
              emptyState: 'No teaching guidance is attached to this session.',
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

  Widget _buildProgressBand(ThemeData theme) {
    final snapshot = _workspace.progressSnapshot;
    final reviewItems = widget.workspace.reviewItems;
    final total =
        snapshot.secureCount +
        snapshot.developingCount +
        snapshot.notStartedCount;

    Widget buildMeter(String label, int value, Color color) {
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

    return _Band(
      title: 'Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildMeter(
            'Secure',
            snapshot.secureCount,
            theme.colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          buildMeter(
            'Developing',
            snapshot.developingCount,
            theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          buildMeter(
            'Not started',
            snapshot.notStartedCount,
            theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          buildMeter(
            'Review queue',
            snapshot.reviewItemCount,
            theme.colorScheme.tertiary,
          ),
          if (reviewItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Review items', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSession = _selectedSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _buildHeader(theme),
        const SizedBox(height: 16),
        _buildPathwayBand(theme),
        const SizedBox(height: 16),
        _buildSessionPathBand(theme),
        const SizedBox(height: 16),
        _buildSessionContentBand(theme, selectedSession),
        const SizedBox(height: 16),
        _buildProgressBand(theme),
      ],
    );
  }
}
