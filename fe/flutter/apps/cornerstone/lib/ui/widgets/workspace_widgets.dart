part of '../../main.dart';

Color _materialKindBackgroundColor(ThemeData theme, String kind) {
  switch (kind) {
    case 'lesson_note':
      return theme.colorScheme.secondaryContainer;
    case 'teaching_note':
      return theme.colorScheme.tertiaryContainer;
    case 'worksheet':
      return theme.colorScheme.primary.withValues(alpha: 0.12);
    case 'drill':
      return theme.colorScheme.tertiaryContainer;
    case 'quick_check':
      return theme.colorScheme.secondaryContainer.withValues(alpha: 0.7);
    default:
      return theme.colorScheme.surfaceContainerHighest;
  }
}

Color _materialKindForegroundColor(ThemeData theme, String kind) {
  switch (kind) {
    case 'lesson_note':
      return theme.colorScheme.onSecondaryContainer;
    case 'teaching_note':
      return theme.colorScheme.onTertiaryContainer;
    case 'worksheet':
      return theme.colorScheme.primary;
    case 'drill':
      return theme.colorScheme.onTertiaryContainer;
    case 'quick_check':
      return theme.colorScheme.onSecondaryContainer;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
}

IconData _materialKindIcon(String kind) {
  switch (kind) {
    case 'lesson_note':
      return Icons.menu_book_rounded;
    case 'teaching_note':
      return Icons.record_voice_over_rounded;
    case 'worksheet':
      return Icons.edit_note_rounded;
    case 'drill':
      return Icons.play_circle_fill_rounded;
    case 'quick_check':
      return Icons.fact_check_rounded;
    default:
      return Icons.description_rounded;
  }
}

String _materialActionLabel(String kind) {
  switch (kind) {
    case 'lesson_note':
      return 'Open lesson note';
    case 'teaching_note':
      return 'Open teaching note';
    case 'worksheet':
      return 'Open worksheet';
    case 'drill':
      return 'Start drill';
    case 'quick_check':
      return 'Start quick check';
    default:
      return 'Open material';
  }
}

MarkdownStyleSheet _workspaceMarkdownStyle(ThemeData theme) {
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
    h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    code: theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'SF Mono',
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
    ),
    blockquote: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    codeblockPadding: const EdgeInsets.all(14),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
      ),
    ),
  );
}

class _SessionMaterialGroupPanel extends StatelessWidget {
  const _SessionMaterialGroupPanel({
    required this.group,
    required this.showDocumentBodies,
    this.session,
    this.viewerCanReadLibrary = false,
    this.onOpenLibraryRoute,
    this.onStartActivity,
  });

  final SessionMaterialKindGroup group;
  final SessionDetail? session;
  final bool viewerCanReadLibrary;
  final bool showDocumentBodies;
  final ValueChanged<String>? onOpenLibraryRoute;
  final Future<void> Function(SessionDetail session, SessionMaterial material)?
  onStartActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _materialKindBackgroundColor(theme, group.kind);
    final foregroundColor = _materialKindForegroundColor(theme, group.kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_materialKindIcon(group.kind), size: 20, color: foregroundColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_humanizeLabel(group.kind), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${group.materialCount} item${group.materialCount == 1 ? '' : 's'} · ${_humanizeLabel(group.audience)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...group.materials.map((material) {
            final hasDocumentBody = (material.documentBody ?? '').trim().isNotEmpty;
            final canOpenDocument =
                viewerCanReadLibrary &&
                onOpenLibraryRoute != null &&
                material.documentRoutePath != null;
            final canStart = session != null && onStartActivity != null && material.isExecutable;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillBadge(
                        text: '${material.estimatedMinutes} min',
                        color: backgroundColor,
                        textColor: foregroundColor,
                      ),
                      if (material.isExecutable)
                        _PillBadge(
                          text: 'Live',
                          color: theme.colorScheme.tertiaryContainer,
                          textColor: theme.colorScheme.onTertiaryContainer,
                        ),
                    ],
                  ),
                  if (showDocumentBodies && hasDocumentBody) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SelectionArea(
                        child: MarkdownBody(
                          data: material.documentBody!,
                          selectable: true,
                          styleSheet: _workspaceMarkdownStyle(theme),
                        ),
                      ),
                    ),
                  ],
                  if (canStart || canOpenDocument) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (canStart)
                          FilledButton.tonalIcon(
                            onPressed: () => onStartActivity!(session!, material),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                            label: Text(_materialActionLabel(material.kind)),
                          ),
                        if (canOpenDocument)
                          TextButton.icon(
                            onPressed: () => onOpenLibraryRoute!(material.documentRoutePath!),
                            icon: const Icon(Icons.description_rounded, size: 18),
                            label: Text(_materialActionLabel(material.kind)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WorkspaceMaterialGroupPanel extends StatelessWidget {
  const _WorkspaceMaterialGroupPanel({
    required this.group,
    required this.onOpenLibraryRoute,
  });

  final WorkspaceMaterialKindGroup group;
  final ValueChanged<String> onOpenLibraryRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _materialKindBackgroundColor(theme, group.kind);
    final foregroundColor = _materialKindForegroundColor(theme, group.kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillBadge(
                text: _humanizeLabel(group.kind),
                color: backgroundColor,
                textColor: foregroundColor,
              ),
              _PillBadge(
                text: '${group.materialCount} item${group.materialCount == 1 ? '' : 's'}',
                color: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...group.materials.map(
            (material) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(material.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${material.estimatedMinutes} min${material.executable ? ' · Live' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (material.routePath != null)
                    TextButton(
                      onPressed: () => onOpenLibraryRoute(material.routePath!),
                      child: const Text('Open'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionWorkspaceAudiencePanel extends StatelessWidget {
  const _SessionWorkspaceAudiencePanel({
    required this.title,
    required this.description,
    required this.emptyState,
    required this.icon,
    required this.groups,
    required this.session,
    required this.viewerCanReadLibrary,
    required this.showDocumentBodies,
    required this.onOpenLibraryRoute,
    required this.onStartActivity,
  });

  final String title;
  final String description;
  final String emptyState;
  final IconData icon;
  final List<SessionMaterialKindGroup> groups;
  final SessionDetail session;
  final bool viewerCanReadLibrary;
  final bool showDocumentBodies;
  final ValueChanged<String> onOpenLibraryRoute;
  final Future<void> Function(SessionDetail session, SessionMaterial material)
  onStartActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            Text(
              emptyState,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...groups.map(
              (group) => _SessionMaterialGroupPanel(
                group: group,
                session: session,
                viewerCanReadLibrary: viewerCanReadLibrary,
                showDocumentBodies: showDocumentBodies,
                onOpenLibraryRoute: onOpenLibraryRoute,
                onStartActivity: onStartActivity,
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnerWorkspaceView extends StatelessWidget {
  const _OwnerWorkspaceView({
    required this.viewer,
    required this.learners,
    required this.selectedLearnerId,
    required this.detail,
    required this.libraryWorkspace,
    required this.currentActionSession,
    required this.scoreController,
    required this.maxScoreController,
    required this.durationController,
    required this.notesController,
    required this.onSelectLearner,
    required this.onCreateAssignment,
    required this.onOpenLibraryRoute,
    required this.onOpenLibraryWorkspace,
    required this.onRecordSession,
    required this.onStartActivity,
  });

  final ViewerUser? viewer;
  final List<LearnerDashboard> learners;
  final String? selectedLearnerId;
  final LearnerDetailPayload? detail;
  final LibraryWorkspacePayload libraryWorkspace;
  final SessionDetail? currentActionSession;
  final TextEditingController scoreController;
  final TextEditingController maxScoreController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final ValueChanged<String> onSelectLearner;
  final Future<void> Function(String learnerId, String playlistId)
  onCreateAssignment;
  final ValueChanged<String> onOpenLibraryRoute;
  final VoidCallback onOpenLibraryWorkspace;
  final VoidCallback onRecordSession;
  final Future<void> Function(SessionDetail session, SessionMaterial material)
  onStartActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalReviewItems = learners.fold<int>(
      0,
      (count, learner) => count + learner.reviewItemCount,
    );
    final activeSessionCount = learners.where((learner) => learner.todaySession != null).length;
    final selectedDetail = detail;
    final journey = selectedDetail?.journey;
    final activeSession = currentActionSession;
    final learnerFacingGroups = activeSession?.materialsByKind
        .where((group) => group.audience == 'learner')
        .toList(growable: false) ??
      const <SessionMaterialKindGroup>[];
    final adultFacingGroups = activeSession?.materialsByKind
        .where((group) => group.audience == 'adult')
        .toList(growable: false) ??
      const <SessionMaterialKindGroup>[];
    final currentStanding = activeSession?.sequenceNumber ??
      (journey != null && journey.totalSessionCount > 0
        ? journey.completedSessionCount + 1
        : null);
    final journeyProgress = journey == null || journey.totalSessionCount == 0
      ? null
      : (journey.completedSessionCount / journey.totalSessionCount)
        .clamp(0.0, 1.0);
    final activeMaterials =
        activeSession?.materials
        .where((material) => material.isExecutable)
            .toList(growable: false) ??
        const <SessionMaterial>[];

    Widget buildSelectionPanel() {
      if (selectedDetail == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 54,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a learner to inspect their current plan and next actions.',
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDetail.learner.displayName,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PillBadge(
                          text: selectedDetail.learner.currentLevel,
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                        _PillBadge(
                          text: 'Age ${selectedDetail.learner.currentAge}',
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          textColor: theme.colorScheme.primary,
                        ),
                        if (selectedDetail.activeAssignment != null)
                          _PillBadge(
                            text: '${selectedDetail.activeAssignment!.completedSessions}/${selectedDetail.activeAssignment!.totalSessions} complete',
                            color: theme.colorScheme.tertiaryContainer,
                            textColor: theme.colorScheme.onTertiaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onOpenLibraryWorkspace,
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: const Text('Browse pathways'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (journey != null)
            _Band(
              title: 'Current learning workspace',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (journey.pathwayTitle != null) ...[
                    Text(journey.pathwayTitle!, style: theme.textTheme.titleLarge),
                    if ((journey.pathwayDescription ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        journey.pathwayDescription!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                  Text(journey.playlistTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    journey.playlistDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (currentStanding != null)
                        _PillBadge(
                          text: 'Standing: session $currentStanding of ${journey.totalSessionCount}',
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                      _PillBadge(
                        text: '${journey.pendingSessionCount} pending sessions',
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        textColor: theme.colorScheme.primary,
                      ),
                      _PillBadge(
                        text: '${journey.liveMaterialCount} live materials',
                        color: theme.colorScheme.tertiaryContainer,
                        textColor: theme.colorScheme.onTertiaryContainer,
                      ),
                      _PillBadge(
                        text: '${journey.totalMaterialCount} total materials',
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
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
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${journey.completedSessionCount} of ${journey.totalSessionCount} sessions completed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (journey.pathwayRoutePath != null)
                        TextButton(
                          onPressed: () => onOpenLibraryRoute(journey.pathwayRoutePath!),
                          child: const Text('Open pathway brief'),
                        ),
                      if (journey.playlistRoutePath != null)
                        TextButton(
                          onPressed: () => onOpenLibraryRoute(journey.playlistRoutePath!),
                          child: const Text('Open playlist brief'),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else
            _Band(
              title: 'No assignment yet',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This learner does not have an active pathway yet. Open the pathway workspace and assign the first playlist you want them to start.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onOpenLibraryWorkspace,
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('Choose a pathway'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (activeSession != null)
            _Band(
              title: activeMaterials.isEmpty
                  ? 'Record the current session'
                  : 'Current session workspace',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activeSession.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Session ${activeSession.sequenceNumber ?? '-'} · ${_humanizeLabel(activeSession.dominantKind)} lead',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  if (activeSession.requiresAdultSupport)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PillBadge(
                        text: 'Adult guidance is part of this session',
                        color: theme.colorScheme.tertiaryContainer,
                        textColor: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  Text(
                    'Use this as the live session board: what the learner sees on one side and the guidance you coach from on the other.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final splitView = constraints.maxWidth > 980;
                      final learnerPanel = _SessionWorkspaceAudiencePanel(
                        title: 'Learner workspace',
                        description:
                            'This is the learner-facing material stack for this session.',
                        emptyState:
                            'No learner-facing materials are attached to this session yet.',
                        icon: Icons.school_rounded,
                        groups: learnerFacingGroups,
                        session: activeSession,
                        viewerCanReadLibrary: viewer?.canReadLibrary ?? false,
                        showDocumentBodies: true,
                        onOpenLibraryRoute: onOpenLibraryRoute,
                        onStartActivity: onStartActivity,
                      );
                      final teachingPanel = _SessionWorkspaceAudiencePanel(
                        title: 'Teaching notes',
                        description:
                            'Guide the session from here while the learner works through the learner workspace.',
                        emptyState:
                            'No adult guidance notes are attached to this session.',
                        icon: Icons.record_voice_over_rounded,
                        groups: adultFacingGroups,
                        session: activeSession,
                        viewerCanReadLibrary: viewer?.canReadLibrary ?? false,
                        showDocumentBodies: true,
                        onOpenLibraryRoute: onOpenLibraryRoute,
                        onStartActivity: onStartActivity,
                      );

                      if (!splitView) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            learnerPanel,
                            const SizedBox(height: 14),
                            teachingPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: learnerPanel),
                          const SizedBox(width: 16),
                          Expanded(child: teachingPanel),
                        ],
                      );
                    },
                  ),
                  if (activeMaterials.isEmpty)
                    const SizedBox(height: 4)
                  else
                    const SizedBox(height: 8),
                  if (activeMaterials.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: activeMaterials
                          .map(
                            (material) => FilledButton.icon(
                              onPressed: () => onStartActivity(activeSession, material),
                              icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                              label: Text('Start ${material.title}'),
                            ),
                          )
                          .toList(growable: false),
                    )
                  else ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _CompactField(label: 'Score', controller: scoreController),
                        _CompactField(label: 'Max Score', controller: maxScoreController),
                        _CompactField(label: 'Minutes', controller: durationController),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Session notes'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onRecordSession,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Record session'),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          _Band(
            title: 'Suggested next assignments',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'These pathway starters come from the backend workspace contract. Use the full pathway tab when you want the complete document and sub-item view.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...libraryWorkspace.pathways.take(3).map((pathway) {
                  LibraryWorkspacePlaylist? starterPlaylist;
                  if (pathway.entryPoints.isNotEmpty) {
                    for (final playlist in pathway.playlists) {
                      if (playlist.playlistId == pathway.entryPoints.first.playlistId) {
                        starterPlaylist = playlist;
                        break;
                      }
                    }
                  }
                  starterPlaylist ??=
                      pathway.playlists.isNotEmpty ? pathway.playlists.first : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pathway.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          pathway.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PillBadge(
                              text: 'Ages ${pathway.recommendedAgeMin}-${pathway.recommendedAgeMax}',
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              textColor: theme.colorScheme.primary,
                            ),
                            _PillBadge(
                              text: '${pathway.playlistCount} playlists',
                              color: theme.colorScheme.secondaryContainer,
                              textColor: theme.colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (pathway.routePath != null)
                              TextButton(
                                onPressed: () => onOpenLibraryRoute(pathway.routePath!),
                                child: const Text('Open route'),
                              ),
                            if (starterPlaylist != null)
                              ...[
                                Builder(
                                  builder: (context) {
                                    final playlist = starterPlaylist!;
                                    return FilledButton.tonalIcon(
                                              onPressed: () => onCreateAssignment(
                                                selectedDetail.learner.learnerId,
                                                playlist.playlistId,
                                              ),
                                      icon: const Icon(Icons.playlist_add_check_circle_rounded, size: 18),
                                      label: Text('Assign ${playlist.title}'),
                                    );
                                  },
                                ),
                              ],
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1120;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            _PageHeroCard(
              eyebrow: 'Teaching workspace',
              title: 'Team teaching workspace',
              description:
                  'Choose a learner, see where they stand in the pathway, and run the current session with learner materials and teaching notes side by side.',
              chips: [
                _StatChip(
                  label: 'Learners',
                  value: '${learners.length}',
                  icon: Icons.groups_rounded,
                ),
                _StatChip(
                  label: 'Active Today',
                  value: '$activeSessionCount',
                  icon: Icons.today_rounded,
                ),
                _StatChip(
                  label: 'Review Queue',
                  value: '$totalReviewItems',
                  icon: Icons.pending_actions_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Learner roster', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text(
                            'Pick a learner to inspect the assignment journey and what can be started right now.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _GoldAccentDivider(),
                          const SizedBox(height: 18),
                          if (learners.isEmpty)
                            Text(
                              'No learners are visible in this workspace yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            ...learners.map(
                              (learner) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _LearnerCard(
                                  learner: learner,
                                  selected: learner.learnerId == selectedLearnerId,
                                  onTap: () => onSelectLearner(learner.learnerId),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: _SurfaceCard(child: buildSelectionPanel())),
                ],
              )
            else ...[
              _SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learner roster', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Pick a learner to inspect the assignment journey and what can be started right now.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (learners.isEmpty)
                      Text(
                        'No learners are visible in this workspace yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...learners.map(
                        (learner) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _LearnerCard(
                            learner: learner,
                            selected: learner.learnerId == selectedLearnerId,
                            onTap: () => onSelectLearner(learner.learnerId),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SurfaceCard(child: buildSelectionPanel()),
            ],
          ],
        );
      },
    );
  }
}

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
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
    final nextSession =
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
    final pendingSessions = learnerDetail.sessions
        .where((session) => session.status != 'completed')
        .toList(growable: false);
    final completedSessions = learnerDetail.sessions
        .where((session) => session.status == 'completed')
        .toList(growable: false);
    final currentStanding = nextSession?.sequenceNumber ??
      (journey != null && journey.totalSessionCount > 0
        ? (journey.completedSessionCount + 1).clamp(1, journey.totalSessionCount)
        : null);
    final journeyProgress = journey == null || journey.totalSessionCount == 0
      ? null
      : (journey.completedSessionCount / journey.totalSessionCount)
        .clamp(0.0, 1.0);
    final progressStatusCounts = <String, int>{};
    for (final state in learnerDetail.progress) {
      progressStatusCounts.update(
        state.status,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final practiceSessions = pendingSessions
        .where(
          (session) => session.materialsByKind.any(
            (group) =>
                group.kind == 'worksheet' ||
                group.kind == 'drill' ||
                group.kind == 'quick_check',
          ),
        )
        .toList(growable: false);

    Widget buildSessionSequenceCard(SessionDetail session, {required bool active}) {
      final learnerGroups = session.materialsByKind
          .where((group) => group.audience == 'learner')
          .toList(growable: false);
      final adultGroups = session.materialsByKind
          .where((group) => group.audience == 'adult')
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
                          _PillBadge(
                            text: _humanizeLabel(session.dominantKind),
                            color: _materialKindBackgroundColor(
                              theme,
                              session.dominantKind,
                            ),
                            textColor: _materialKindForegroundColor(
                              theme,
                              session.dominantKind,
                            ),
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
                        text: '${_humanizeLabel(group.kind)} · ${group.materialCount}',
                        color: _materialKindBackgroundColor(theme, group.kind),
                        textColor: _materialKindForegroundColor(theme, group.kind),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            children: [
              _SessionWorkspaceAudiencePanel(
                title: active ? 'Current session workspace' : 'Session workspace',
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
              if (adultGroups.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (viewer != null && viewer!.isLearner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'A parent or coach may have a teaching note to guide this session alongside your work.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  )
                else
                  _SessionWorkspaceAudiencePanel(
                    title: 'Teaching notes',
                    description:
                        'Adult guidance attached to this session appears here.',
                    emptyState: 'No teaching note is attached to this session.',
                    icon: Icons.record_voice_over_rounded,
                    groups: adultGroups,
                    session: session,
                    viewerCanReadLibrary: viewerCanReadLibrary,
                    showDocumentBodies: true,
                    onOpenLibraryRoute: onOpenLibraryRoute,
                    onStartActivity: onStartActivity,
                  ),
              ],
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
              value: '${journey?.completedSessionCount ?? completedSessions.length}',
              icon: Icons.task_alt_rounded,
            ),
            _StatChip(
              label: 'Ready Now',
              value: '${pendingSessions.length}',
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
                Text('My current pathway', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  journey.pathwayTitle ?? journey.playlistTitle,
                  style: theme.textTheme.titleLarge,
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
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                          onPressed: () => onOpenLibraryRoute(journey.pathwayRoutePath!),
                          child: const Text('Open pathway brief'),
                        ),
                      if (journey.playlistRoutePath != null)
                        TextButton(
                          onPressed: () => onOpenLibraryRoute(journey.playlistRoutePath!),
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
                Text('Current session workspace', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'This is the workspace for what you are learning right now. Read the note, do the practice, and launch the live step from here.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PillBadge(
                      text: _humanizeLabel(nextSession.dominantKind),
                      color: _materialKindBackgroundColor(
                        theme,
                        nextSession.dominantKind,
                      ),
                      textColor: _materialKindForegroundColor(
                        theme,
                        nextSession.dominantKind,
                      ),
                    ),
                    if (nextSession.requiresAdultSupport)
                      _PillBadge(
                        text: 'Adult support first',
                        color: theme.colorScheme.tertiaryContainer,
                        textColor: theme.colorScheme.onTertiaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                  _SessionWorkspaceAudiencePanel(
                    title: 'What I work on now',
                    description:
                        'The learner-facing materials for the current session stay together here.',
                    emptyState:
                        'No learner-facing materials are attached to this session yet.',
                    icon: Icons.school_rounded,
                    groups: nextSession.materialsByKind
                        .where((group) => group.audience == 'learner')
                        .toList(growable: false),
                    session: nextSession,
                    viewerCanReadLibrary: viewerCanReadLibrary,
                    showDocumentBodies: true,
                    onOpenLibraryRoute: onOpenLibraryRoute,
                    onStartActivity: onStartActivity,
                  ),
                if (nextSession.materialsByKind.any(
                  (group) => group.audience == 'adult',
                )) ...[
                  const SizedBox(height: 4),
                  if (viewer != null && viewer!.isLearner)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'A parent or coach may have a teaching note for this session and can guide you alongside this workspace.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    )
                  else
                    _SessionWorkspaceAudiencePanel(
                      title: 'Teaching notes',
                      description:
                          'Adult guidance attached to this session appears here.',
                      emptyState: 'No teaching note is attached to this session.',
                      icon: Icons.record_voice_over_rounded,
                      groups: nextSession.materialsByKind
                          .where((group) => group.audience == 'adult')
                          .toList(growable: false),
                      session: nextSession,
                      viewerCanReadLibrary: viewerCanReadLibrary,
                      showDocumentBodies: true,
                      onOpenLibraryRoute: onOpenLibraryRoute,
                      onStartActivity: onStartActivity,
                    ),
                ],
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
                      border: Border.all(color: theme.colorScheme.outlineVariant),
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
                            _PillBadge(
                              text: _humanizeLabel(session.dominantKind),
                              color: _materialKindBackgroundColor(
                                theme,
                                session.dominantKind,
                              ),
                              textColor: _materialKindForegroundColor(
                                theme,
                                session.dominantKind,
                              ),
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
                'Current status across the skills attached to this learner.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (progressStatusCounts.isEmpty)
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
                    subtitle: Text(_humanizeLabel(item.skillId)),
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

class _LibraryWorkspaceView extends StatelessWidget {
  const _LibraryWorkspaceView({
    required this.libraryWorkspace,
    required this.documents,
    required this.activeDocument,
    required this.libraryDocumentBusy,
    required this.viewerCanManage,
    required this.onCreateAssignment,
    required this.onOpenLibraryRoute,
  });

  final LibraryWorkspacePayload libraryWorkspace;
  final LibraryDocumentsPayload? documents;
  final LibraryDocumentData? activeDocument;
  final bool libraryDocumentBusy;
  final bool viewerCanManage;
  final Future<void> Function(String learnerId, String playlistId)
  onCreateAssignment;
  final ValueChanged<String> onOpenLibraryRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeBySourcePath = {
      for (final document in documents?.documents ?? const <LibraryDocumentSummary>[])
        document.sourcePath: document.routePath,
    };
    final totalMaterials = libraryWorkspace.pathways.fold<int>(
      0,
      (count, pathway) =>
          count +
          pathway.playlists.fold<int>(
            0,
            (playlistCount, playlist) => playlistCount + playlist.materialCount,
          ),
    );

    Widget buildNavigatorPanel() {
      return _SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pathway browser', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Browse the backend-owned pathway contract, inspect delivery shape by canonical material kind, and assign the right playlist directly from each learner target.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (libraryWorkspace.pathways.isEmpty)
              Text(
                'No pathways are available yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...libraryWorkspace.pathways.map((pathway) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pathway.title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          pathway.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PillBadge(
                              text: pathway.areaTitle,
                              color: theme.colorScheme.secondaryContainer,
                              textColor: theme.colorScheme.onSecondaryContainer,
                            ),
                            _PillBadge(
                              text: 'Ages ${pathway.recommendedAgeMin}-${pathway.recommendedAgeMax}',
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              textColor: theme.colorScheme.primary,
                            ),
                            _PillBadge(
                              text: '${pathway.playlistCount} playlists',
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              textColor: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (pathway.routePath != null)
                              FilledButton.icon(
                                onPressed: () => onOpenLibraryRoute(pathway.routePath!),
                                icon: const Icon(Icons.description_rounded, size: 18),
                                label: const Text('Open route document'),
                              ),
                            if (pathway.entryPoints.isNotEmpty)
                              _PillBadge(
                                text: 'Recommended start: ${pathway.entryPoints.first.playlistTitle}',
                                color: theme.colorScheme.tertiaryContainer,
                                textColor: theme.colorScheme.onTertiaryContainer,
                              ),
                          ],
                        ),
                        if (pathway.playlists.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          ...pathway.playlists.map((playlist) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.58),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              playlist.title,
                                              style: theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              playlist.description,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      _PillBadge(
                                        text: _humanizeLabel(playlist.deliveryShape.requiresAdultSupport ? 'adult_guided' : 'learner_ready'),
                                        color: playlist.deliveryShape.requiresAdultSupport
                                            ? theme.colorScheme.tertiaryContainer
                                            : theme.colorScheme.secondaryContainer,
                                        textColor: playlist.deliveryShape.requiresAdultSupport
                                            ? theme.colorScheme.onTertiaryContainer
                                            : theme.colorScheme.onSecondaryContainer,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _PillBadge(
                                        text: 'Age ${playlist.recommendedAge}',
                                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        textColor: theme.colorScheme.primary,
                                      ),
                                      _PillBadge(
                                        text: '${playlist.durationDays} days',
                                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        textColor: theme.colorScheme.primary,
                                      ),
                                      _PillBadge(
                                        text: '${playlist.materialCount} materials',
                                        color: theme.colorScheme.secondaryContainer,
                                        textColor: theme.colorScheme.onSecondaryContainer,
                                      ),
                                      if (playlist.deliveryShape.lessonNoteCount > 0)
                                        _PillBadge(
                                          text: '${playlist.deliveryShape.lessonNoteCount} lesson notes',
                                          color: _materialKindBackgroundColor(theme, 'lesson_note'),
                                          textColor: _materialKindForegroundColor(theme, 'lesson_note'),
                                        ),
                                      if (playlist.deliveryShape.teachingNoteCount > 0)
                                        _PillBadge(
                                          text: '${playlist.deliveryShape.teachingNoteCount} teaching notes',
                                          color: _materialKindBackgroundColor(theme, 'teaching_note'),
                                          textColor: _materialKindForegroundColor(theme, 'teaching_note'),
                                        ),
                                      if (playlist.deliveryShape.worksheetCount > 0)
                                        _PillBadge(
                                          text: '${playlist.deliveryShape.worksheetCount} worksheets',
                                          color: _materialKindBackgroundColor(theme, 'worksheet'),
                                          textColor: _materialKindForegroundColor(theme, 'worksheet'),
                                        ),
                                      if (playlist.deliveryShape.drillCount > 0)
                                        _PillBadge(
                                          text: '${playlist.deliveryShape.drillCount} drills',
                                          color: _materialKindBackgroundColor(theme, 'drill'),
                                          textColor: _materialKindForegroundColor(theme, 'drill'),
                                        ),
                                      if (playlist.deliveryShape.quickCheckCount > 0)
                                        _PillBadge(
                                          text: '${playlist.deliveryShape.quickCheckCount} quick checks',
                                          color: _materialKindBackgroundColor(theme, 'quick_check'),
                                          textColor: _materialKindForegroundColor(theme, 'quick_check'),
                                        ),
                                      _PillBadge(
                                        text: '${playlist.deliveryShape.estimatedTotalMinutes} min total',
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        textColor: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  if (playlist.assignmentTargets.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      'Assignment targets',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: playlist.assignmentTargets.map((target) {
                                        return ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 220,
                                            maxWidth: 320,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            target.displayName,
                                                            style: theme.textTheme.titleSmall,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Age ${target.currentAge} · ${target.currentLevel}',
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: theme.colorScheme.onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (target.recommended)
                                                      _PillBadge(
                                                        text: 'Recommended',
                                                        color: theme.colorScheme.secondaryContainer,
                                                        textColor: theme.colorScheme.onSecondaryContainer,
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  target.statusLabel,
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                                if (target.activeAssignmentTitle != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Current: ${target.activeAssignmentTitle}',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                                if (viewerCanManage) ...[
                                                  const SizedBox(height: 12),
                                                  FilledButton.tonal(
                                                    onPressed: target.assignedHere
                                                        ? null
                                                        : () => onCreateAssignment(
                                                              target.learnerId,
                                                              playlist.playlistId,
                                                            ),
                                                    child: Text(
                                                      target.assignedHere
                                                          ? 'Already assigned here'
                                                          : 'Assign to ${target.displayName}',
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(growable: false),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  ...playlist.sessions.map((session) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${session.sessionIndex}. ${session.title}',
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _PillBadge(
                                                  text: _humanizeLabel(session.dominantKind),
                                                  color: _materialKindBackgroundColor(
                                                    theme,
                                                    session.dominantKind,
                                                  ),
                                                  textColor: _materialKindForegroundColor(
                                                    theme,
                                                    session.dominantKind,
                                                  ),
                                                ),
                                                _PillBadge(
                                                  text: '${session.estimatedMinutes} min',
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  textColor: theme.colorScheme.onSurfaceVariant,
                                                ),
                                                if (session.requiresAdultSupport)
                                                  _PillBadge(
                                                    text: 'Adult support',
                                                    color: theme.colorScheme.tertiaryContainer,
                                                    textColor: theme.colorScheme.onTertiaryContainer,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            ...session.materialsByKind.map(
                                              (group) => _WorkspaceMaterialGroupPanel(
                                                group: group,
                                                onOpenLibraryRoute: onOpenLibraryRoute,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      if (playlist.routePath != null)
                                        TextButton(
                                          onPressed: () => onOpenLibraryRoute(playlist.routePath!),
                                          child: const Text('Open playlist'),
                                        ),
                                      if (playlist.assignmentTargets.isEmpty)
                                        Text(
                                          'No learner targets are available for this playlist yet.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
      );
    }

    Widget buildReaderPanel() {
      return _SurfaceCard(
        child: _LibraryDocumentReader(
          document: activeDocument,
          busy: libraryDocumentBusy,
          routeBySourcePath: routeBySourcePath,
          onOpenLibraryRoute: onOpenLibraryRoute,
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
              title: 'Pathway planning workspace',
              description:
                  'Browse the backend-derived pathway catalog, inspect delivery shape and assignment targets, then read the authored markdown without leaving the app.',
              chips: [
                _StatChip(
                  label: 'Pathways',
                  value: '${libraryWorkspace.pathways.length}',
                  icon: Icons.route_rounded,
                ),
                _StatChip(
                  label: 'Documents',
                  value: '${documents?.documents.length ?? 0}',
                  icon: Icons.description_rounded,
                ),
                _StatChip(
                  label: 'Materials',
                  value: '$totalMaterials',
                  icon: Icons.menu_book_rounded,
                ),
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
