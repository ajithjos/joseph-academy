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
