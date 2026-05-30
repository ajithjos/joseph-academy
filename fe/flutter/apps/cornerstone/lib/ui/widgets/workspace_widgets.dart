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
      return 'Open lesson_note material';
    case 'teaching_note':
      return 'Open teaching_note material';
    case 'worksheet':
      return 'Open worksheet material';
    case 'drill':
      return 'Start drill material';
    case 'quick_check':
      return 'Start quick_check material';
    default:
      return 'Open session_material';
  }
}

Color _markdownCodeForegroundColor(ThemeData theme) {
  return theme.colorScheme.onSurface;
}

Color _markdownCodeBackgroundColor(ThemeData theme) {
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92);
}

double _desktopStudioHeight(
  BuildContext context, {
  double subtract = 240,
  double minHeight = 680,
  double maxHeight = 960,
}) {
  final height = MediaQuery.sizeOf(context).height - subtract;
  if (height < minHeight) {
    return minHeight;
  }
  if (height > maxHeight) {
    return maxHeight;
  }
  return height;
}

MarkdownStyleSheet _workspaceMarkdownStyle(ThemeData theme) {
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
    h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    code: theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'SF Mono',
      color: _markdownCodeForegroundColor(theme),
      backgroundColor: _markdownCodeBackgroundColor(theme),
    ),
    blockquote: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    codeblockPadding: const EdgeInsets.all(14),
    codeblockDecoration: BoxDecoration(
      color: _markdownCodeBackgroundColor(theme),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.82),
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
                child: Icon(
                  _materialKindIcon(group.kind),
                  size: 20,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _contractTermLabel(group.kind),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    _ContractChipRow(
                      children: [
                        _ContractChip(
                          domain: 'material_kind',
                          value: group.kind,
                        ),
                        _ContractChip(
                          domain: 'audience',
                          value: group.audience,
                        ),
                        _PillBadge(
                          text: 'count:${group.materialCount}',
                          color: theme.colorScheme.surfaceContainerHighest,
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...group.materials.map((material) {
            final hasDocumentBody = (material.documentBody ?? '')
                .trim()
                .isNotEmpty;
            final canOpenDocument =
                viewerCanReadLibrary &&
                onOpenLibraryRoute != null &&
                material.documentRoutePath != null;
            final canStart =
                session != null &&
                onStartActivity != null &&
                material.isExecutable;
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
                  _ContractChipRow(
                    children: [
                      _ContractChip(
                        domain: 'entity',
                        value: 'session_material',
                      ),
                      _ContractChip(
                        domain: 'material_kind',
                        value: material.kind,
                      ),
                      _PillBadge(
                        text: '${material.estimatedMinutes} min',
                        color: backgroundColor,
                        textColor: foregroundColor,
                      ),
                      if (material.isExecutable)
                        _ContractChip(domain: 'status', value: 'live'),
                    ],
                  ),
                  if (showDocumentBodies && hasDocumentBody) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
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
                            onPressed: () =>
                                onStartActivity!(session!, material),
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 18,
                            ),
                            label: Text(_materialActionLabel(material.kind)),
                          ),
                        if (canOpenDocument)
                          TextButton.icon(
                            onPressed: () => onOpenLibraryRoute!(
                              material.documentRoutePath!,
                            ),
                            icon: const Icon(
                              Icons.description_rounded,
                              size: 18,
                            ),
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
          _ContractChipRow(
            children: [
              _ContractChip(domain: 'material_kind', value: group.kind),
              _PillBadge(
                text: 'count:${group.materialCount}',
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
                        _ContractChipRow(
                          children: [
                            _ContractChip(
                              domain: 'entity',
                              value: 'session_material',
                            ),
                            _ContractChip(
                              domain: 'material_kind',
                              value: material.kind,
                            ),
                            _PillBadge(
                              text: '${material.estimatedMinutes} min',
                              color: theme.colorScheme.surfaceContainerHighest,
                              textColor: theme.colorScheme.onSurfaceVariant,
                            ),
                            if (material.executable)
                              _ContractChip(domain: 'status', value: 'live'),
                          ],
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

class _MissingLearnerContentNotice extends StatelessWidget {
  const _MissingLearnerContentNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This session is missing learner content.',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask your parent or teacher to add learner-facing material for this step before you continue.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
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
    final activeSessionCount = learners
        .where((learner) => learner.todaySession != null)
        .length;
    final selectedDetail = detail;
    final journey = selectedDetail?.journey;
    final workspace = selectedDetail?.workspace;
    final continueBlock = workspace?.continueBlock;
    final recentWins = workspace?.recentWins ?? const <LearnerRecentWin>[];
    final activeSession = currentActionSession;
    final learnerFacingGroups =
        activeSession?.materialsByKind
            .where((group) => group.audience == 'learner')
            .toList(growable: false) ??
        const <SessionMaterialKindGroup>[];
    final adultFacingGroups =
        activeSession?.materialsByKind
            .where((group) => group.audience == 'adult')
            .toList(growable: false) ??
        const <SessionMaterialKindGroup>[];
    final currentStanding =
        activeSession?.sequenceNumber ??
        (journey != null && journey.totalSessionCount > 0
            ? journey.completedSessionCount + 1
            : null);
    final journeyProgress = journey == null || journey.totalSessionCount == 0
        ? null
        : (journey.completedSessionCount / journey.totalSessionCount).clamp(
            0.0,
            1.0,
          );
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
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
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          textColor: theme.colorScheme.primary,
                        ),
                        if ((workspace?.attentionLabel ?? '').isNotEmpty)
                          _PillBadge(
                            text: workspace!.attentionLabel,
                            color: theme.colorScheme.surfaceContainerHighest,
                            textColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        if (selectedDetail.activeAssignment != null)
                          _PillBadge(
                            text:
                                '${selectedDetail.activeAssignment!.completedSessions}/${selectedDetail.activeAssignment!.totalSessions} complete',
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
                label: const Text('Open pathway planning'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (journey != null)
            _Band(
              title: 'Assigned pathway and playlist',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _ContractChip(domain: 'entity', value: 'pathway'),
                      _ContractChip(domain: 'entity', value: 'playlist'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (journey.pathwayTitle != null) ...[
                    Text(
                      journey.pathwayTitle!,
                      style: theme.textTheme.titleLarge,
                    ),
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
                  Text(
                    journey.playlistTitle,
                    style: theme.textTheme.titleMedium,
                  ),
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
                          text:
                              'Standing: session $currentStanding of ${journey.totalSessionCount}',
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                      _PillBadge(
                        text: '${journey.pendingSessionCount} pending sessions',
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
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
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
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
          if (continueBlock != null) ...[
            const SizedBox(height: 20),
            _Band(
              title: 'Continue this learner',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(continueBlock.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    continueBlock.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillBadge(
                        text: continueBlock.actionLabel,
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      if (continueBlock.session.estimatedMinutes > 0)
                        _PillBadge(
                          text: '${continueBlock.session.estimatedMinutes} min',
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          textColor: theme.colorScheme.primary,
                        ),
                      if (continueBlock.session.requiresAdultSupport)
                        _PillBadge(
                          text: 'Adult-guided',
                          color: theme.colorScheme.tertiaryContainer,
                          textColor: theme.colorScheme.onTertiaryContainer,
                        ),
                      if (continueBlock.session.liveMaterialCount > 0)
                        _PillBadge(
                          text:
                              '${continueBlock.session.liveMaterialCount} live',
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                    'Session ${activeSession.sequenceNumber ?? '-'} · dominant_kind:${_contractTermLabel(activeSession.dominantKind)}',
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
                              onPressed: () =>
                                  onStartActivity(activeSession, material),
                              icon: const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 18,
                              ),
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
                        _CompactField(
                          label: 'Score',
                          controller: scoreController,
                        ),
                        _CompactField(
                          label: 'Max Score',
                          controller: maxScoreController,
                        ),
                        _CompactField(
                          label: 'Minutes',
                          controller: durationController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Session notes',
                      ),
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
          if (recentWins.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Band(
              title: 'Recent wins',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recentWins
                    .map(
                      (win) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: 18,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    win.sessionTitle,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    win.notes.isEmpty
                                        ? 'Recorded evidence from the latest completed session.'
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
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              textColor: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _Band(
            title: 'Suggested next assignments',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'These are explicit first-playlist suggestions from the pathway workspace. Use them when this learner needs a fresh start or a better-fit route.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...libraryWorkspace.pathways.take(3).map((pathway) {
                  LibraryWorkspacePlaylist? starterPlaylist;
                  if (pathway.entryPoints.isNotEmpty) {
                    for (final playlist in pathway.playlists) {
                      if (playlist.playlistId ==
                          pathway.entryPoints.first.playlistId) {
                        starterPlaylist = playlist;
                        break;
                      }
                    }
                  }
                  starterPlaylist ??= pathway.playlists.isNotEmpty
                      ? pathway.playlists.first
                      : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
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
                              text:
                                  'Ages ${pathway.recommendedAgeMin}-${pathway.recommendedAgeMax}',
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
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
                                onPressed: () =>
                                    onOpenLibraryRoute(pathway.routePath!),
                                child: const Text('Open route'),
                              ),
                            if (starterPlaylist != null) ...[
                              Builder(
                                builder: (context) {
                                  final playlist = starterPlaylist!;
                                  return FilledButton.tonalIcon(
                                    onPressed: () => onCreateAssignment(
                                      selectedDetail.learner.learnerId,
                                      playlist.playlistId,
                                    ),
                                    icon: const Icon(
                                      Icons.playlist_add_check_circle_rounded,
                                      size: 18,
                                    ),
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
        final rosterPanel = _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Learner roster', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Select a learner to inspect pathway, playlist, and session actions.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _GoldAccentDivider(),
              const SizedBox(height: 14),
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LearnerCard(
                      learner: learner,
                      selected: learner.learnerId == selectedLearnerId,
                      onTap: () => onSelectLearner(learner.learnerId),
                    ),
                  ),
                ),
            ],
          ),
        );

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
                        text: 'team',
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Team teaching workspace',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onOpenLibraryWorkspace,
                        icon: const Icon(Icons.auto_stories_rounded, size: 18),
                        label: const Text('Open pathway planning'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Run learner sessions, assignments, and progress from one team surface.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ContractChipRow(
                    children: [
                      _PillBadge(
                        text: 'learners:${learners.length}',
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        textColor: theme.colorScheme.primary,
                      ),
                      _PillBadge(
                        text: 'active_today:$activeSessionCount',
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      _PillBadge(
                        text: 'review_queue:$totalReviewItems',
                        color: theme.colorScheme.tertiaryContainer,
                        textColor: theme.colorScheme.onTertiaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: rosterPanel),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: _SurfaceCard(child: buildSelectionPanel()),
                  ),
                ],
              )
            else ...[
              rosterPanel,
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
      for (final document
          in documents?.documents ?? const <LibraryDocumentSummary>[])
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

    if (MediaQuery.sizeOf(context).width > 1180) {
      return _LibraryPlanningDesktop(
        libraryWorkspace: libraryWorkspace,
        documents: documents,
        activeDocument: activeDocument,
        libraryDocumentBusy: libraryDocumentBusy,
        viewerCanManage: viewerCanManage,
        onCreateAssignment: onCreateAssignment,
        onOpenLibraryRoute: onOpenLibraryRoute,
        totalMaterials: totalMaterials,
      );
    }

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
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
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
                              text:
                                  'Ages ${pathway.recommendedAgeMin}-${pathway.recommendedAgeMax}',
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              textColor: theme.colorScheme.primary,
                            ),
                            _PillBadge(
                              text: '${pathway.playlistCount} playlists',
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
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
                                onPressed: () =>
                                    onOpenLibraryRoute(pathway.routePath!),
                                icon: const Icon(
                                  Icons.description_rounded,
                                  size: 18,
                                ),
                                label: const Text('Open route document'),
                              ),
                            if (pathway.entryPoints.isNotEmpty)
                              _PillBadge(
                                text:
                                    'Recommended start: ${pathway.entryPoints.first.playlistTitle}',
                                color: theme.colorScheme.tertiaryContainer,
                                textColor:
                                    theme.colorScheme.onTertiaryContainer,
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
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.58,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              playlist.title,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              playlist.description,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      _ContractChip(
                                        domain: 'status',
                                        value:
                                            playlist
                                                .deliveryShape
                                                .requiresAdultSupport
                                            ? 'adult_guided'
                                            : 'learner_ready',
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
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.12),
                                        textColor: theme.colorScheme.primary,
                                      ),
                                      _PillBadge(
                                        text: '${playlist.durationDays} days',
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.12),
                                        textColor: theme.colorScheme.primary,
                                      ),
                                      _PillBadge(
                                        text:
                                            '${playlist.materialCount} materials',
                                        color: theme
                                            .colorScheme
                                            .secondaryContainer,
                                        textColor: theme
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                      if (playlist
                                              .deliveryShape
                                              .lessonNoteCount >
                                          0)
                                        _PillBadge(
                                          text:
                                              '${playlist.deliveryShape.lessonNoteCount} lesson notes',
                                          color: _materialKindBackgroundColor(
                                            theme,
                                            'lesson_note',
                                          ),
                                          textColor:
                                              _materialKindForegroundColor(
                                                theme,
                                                'lesson_note',
                                              ),
                                        ),
                                      if (playlist
                                              .deliveryShape
                                              .teachingNoteCount >
                                          0)
                                        _PillBadge(
                                          text:
                                              '${playlist.deliveryShape.teachingNoteCount} teaching notes',
                                          color: _materialKindBackgroundColor(
                                            theme,
                                            'teaching_note',
                                          ),
                                          textColor:
                                              _materialKindForegroundColor(
                                                theme,
                                                'teaching_note',
                                              ),
                                        ),
                                      if (playlist
                                              .deliveryShape
                                              .worksheetCount >
                                          0)
                                        _PillBadge(
                                          text:
                                              '${playlist.deliveryShape.worksheetCount} worksheets',
                                          color: _materialKindBackgroundColor(
                                            theme,
                                            'worksheet',
                                          ),
                                          textColor:
                                              _materialKindForegroundColor(
                                                theme,
                                                'worksheet',
                                              ),
                                        ),
                                      if (playlist.deliveryShape.drillCount > 0)
                                        _PillBadge(
                                          text:
                                              '${playlist.deliveryShape.drillCount} drills',
                                          color: _materialKindBackgroundColor(
                                            theme,
                                            'drill',
                                          ),
                                          textColor:
                                              _materialKindForegroundColor(
                                                theme,
                                                'drill',
                                              ),
                                        ),
                                      if (playlist
                                              .deliveryShape
                                              .quickCheckCount >
                                          0)
                                        _PillBadge(
                                          text:
                                              '${playlist.deliveryShape.quickCheckCount} quick checks',
                                          color: _materialKindBackgroundColor(
                                            theme,
                                            'quick_check',
                                          ),
                                          textColor:
                                              _materialKindForegroundColor(
                                                theme,
                                                'quick_check',
                                              ),
                                        ),
                                      _PillBadge(
                                        text:
                                            '${playlist.deliveryShape.estimatedTotalMinutes} min total',
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        textColor:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  if (playlist
                                      .assignmentTargets
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      'Assignment targets',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: playlist.assignmentTargets
                                          .map((target) {
                                            return ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minWidth: 220,
                                                maxWidth: 320,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.32),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                target
                                                                    .displayName,
                                                                style: theme
                                                                    .textTheme
                                                                    .titleSmall,
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                'Age ${target.currentAge} · ${target.currentLevel}',
                                                                style: theme
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                      color: theme
                                                                          .colorScheme
                                                                          .onSurfaceVariant,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (target.recommended)
                                                          _PillBadge(
                                                            text: 'Recommended',
                                                            color: theme
                                                                .colorScheme
                                                                .secondaryContainer,
                                                            textColor: theme
                                                                .colorScheme
                                                                .onSecondaryContainer,
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      target.statusLabel,
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                    if (target
                                                            .activeAssignmentTitle !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Current: ${target.activeAssignmentTitle}',
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                    if (viewerCanManage) ...[
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      FilledButton.tonal(
                                                        onPressed:
                                                            target.assignedHere
                                                            ? null
                                                            : () => onCreateAssignment(
                                                                target
                                                                    .learnerId,
                                                                playlist
                                                                    .playlistId,
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
                                          })
                                          .toList(growable: false),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  ...playlist.sessions.map((session) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.32),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                _ContractChip(
                                                  domain: 'material_kind',
                                                  value: session.dominantKind,
                                                ),
                                                _PillBadge(
                                                  text:
                                                      '${session.estimatedMinutes} min',
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  textColor: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                if (session
                                                    .requiresAdultSupport)
                                                  _PillBadge(
                                                    text: 'Adult support',
                                                    color: theme
                                                        .colorScheme
                                                        .tertiaryContainer,
                                                    textColor: theme
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            ...session.materialsByKind.map(
                                              (group) =>
                                                  _WorkspaceMaterialGroupPanel(
                                                    group: group,
                                                    onOpenLibraryRoute:
                                                        onOpenLibraryRoute,
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
                                          onPressed: () => onOpenLibraryRoute(
                                            playlist.routePath!,
                                          ),
                                          child: const Text('Open playlist'),
                                        ),
                                      if (playlist.assignmentTargets.isEmpty)
                                        Text(
                                          'No learner targets are available for this playlist yet.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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

class _LibraryPlanningDesktop extends StatefulWidget {
  const _LibraryPlanningDesktop({
    required this.libraryWorkspace,
    required this.documents,
    required this.activeDocument,
    required this.libraryDocumentBusy,
    required this.viewerCanManage,
    required this.onCreateAssignment,
    required this.onOpenLibraryRoute,
    required this.totalMaterials,
  });

  final LibraryWorkspacePayload libraryWorkspace;
  final LibraryDocumentsPayload? documents;
  final LibraryDocumentData? activeDocument;
  final bool libraryDocumentBusy;
  final bool viewerCanManage;
  final Future<void> Function(String learnerId, String playlistId)
  onCreateAssignment;
  final ValueChanged<String> onOpenLibraryRoute;
  final int totalMaterials;

  @override
  State<_LibraryPlanningDesktop> createState() =>
      _LibraryPlanningDesktopState();
}

enum _PlanningFocus { pathway, playlist, session, material }

class _LibraryPlanningDesktopState extends State<_LibraryPlanningDesktop> {
  String? _selectedPathwayId;
  String? _selectedPlaylistId;
  int _selectedSessionIndex = 0;
  String? _selectedMaterialId;
  _PlanningFocus _focus = _PlanningFocus.pathway;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(covariant _LibraryPlanningDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  void _syncSelection() {
    final pathways = widget.libraryWorkspace.pathways;
    if (pathways.isEmpty) {
      _selectedPathwayId = null;
      _selectedPlaylistId = null;
      _selectedSessionIndex = 0;
      return;
    }
    final pathway = pathways.firstWhere(
      (item) => item.pathwayId == _selectedPathwayId,
      orElse: () => pathways.first,
    );
    _selectedPathwayId = pathway.pathwayId;
    if (pathway.playlists.isEmpty) {
      _selectedPlaylistId = null;
      _selectedSessionIndex = 0;
      return;
    }
    final playlist = pathway.playlists.firstWhere(
      (item) => item.playlistId == _selectedPlaylistId,
      orElse: () => pathway.playlists.first,
    );
    _selectedPlaylistId = playlist.playlistId;
    if (playlist.sessions.isEmpty) {
      _selectedSessionIndex = 0;
      return;
    }
    if (_selectedSessionIndex >= playlist.sessions.length) {
      _selectedSessionIndex = 0;
    }

    final selectedSession = _selectedSession;
    if (selectedSession == null || selectedSession.materials.isEmpty) {
      _selectedMaterialId = null;
      return;
    }
    final hasMaterial = selectedSession.materials.any(
      (material) => material.materialId == _selectedMaterialId,
    );
    if (!hasMaterial) {
      _selectedMaterialId = selectedSession.materials.first.materialId;
    }
  }

  LibraryWorkspacePathway? get _selectedPathway {
    for (final pathway in widget.libraryWorkspace.pathways) {
      if (pathway.pathwayId == _selectedPathwayId) {
        return pathway;
      }
    }
    return widget.libraryWorkspace.pathways.isEmpty
        ? null
        : widget.libraryWorkspace.pathways.first;
  }

  LibraryWorkspacePlaylist? get _selectedPlaylist {
    final pathway = _selectedPathway;
    if (pathway == null || pathway.playlists.isEmpty) {
      return null;
    }
    for (final playlist in pathway.playlists) {
      if (playlist.playlistId == _selectedPlaylistId) {
        return playlist;
      }
    }
    return pathway.playlists.first;
  }

  LibraryWorkspaceSession? get _selectedSession {
    final playlist = _selectedPlaylist;
    if (playlist == null || playlist.sessions.isEmpty) {
      return null;
    }
    if (_selectedSessionIndex >= playlist.sessions.length) {
      return playlist.sessions.first;
    }
    return playlist.sessions[_selectedSessionIndex];
  }

  LibraryWorkspaceMaterial? get _selectedMaterial {
    final session = _selectedSession;
    if (session == null || session.materials.isEmpty) {
      return null;
    }
    for (final material in session.materials) {
      if (material.materialId == _selectedMaterialId) {
        return material;
      }
    }
    return session.materials.first;
  }

  String? _preferredRouteForSession(LibraryWorkspaceSession session) {
    for (final material in session.materials) {
      final routePath = material.routePath;
      if (routePath != null && routePath.isNotEmpty) {
        return routePath;
      }
    }
    return null;
  }

  String? _preferredRouteForPlaylist(LibraryWorkspacePlaylist playlist) {
    final routePath = playlist.routePath;
    if (routePath != null && routePath.isNotEmpty) {
      return routePath;
    }
    for (final session in playlist.sessions) {
      final sessionRoute = _preferredRouteForSession(session);
      if (sessionRoute != null) {
        return sessionRoute;
      }
    }
    return null;
  }

  String? _preferredRouteForPathway(LibraryWorkspacePathway pathway) {
    final routePath = pathway.routePath;
    if (routePath != null && routePath.isNotEmpty) {
      return routePath;
    }
    for (final playlist in pathway.playlists) {
      final playlistRoute = _preferredRouteForPlaylist(playlist);
      if (playlistRoute != null) {
        return playlistRoute;
      }
    }
    return null;
  }

  void _openPreferredRoute(String? routePath) {
    if (routePath == null || routePath.isEmpty) {
      return;
    }
    widget.onOpenLibraryRoute(routePath);
  }

  void _selectPathway(LibraryWorkspacePathway pathway) {
    setState(() {
      _selectedPathwayId = pathway.pathwayId;
      _selectedPlaylistId = pathway.playlists.isEmpty
          ? null
          : pathway.playlists.first.playlistId;
      _selectedSessionIndex = 0;
      _focus = _PlanningFocus.pathway;
    });
    _openPreferredRoute(_preferredRouteForPathway(pathway));
  }

  void _selectPlaylist(LibraryWorkspacePlaylist playlist) {
    setState(() {
      _selectedPlaylistId = playlist.playlistId;
      _selectedSessionIndex = 0;
      _focus = _PlanningFocus.playlist;
    });
    _openPreferredRoute(_preferredRouteForPlaylist(playlist));
  }

  void _selectSession(int index) {
    final playlist = _selectedPlaylist;
    setState(() {
      _selectedSessionIndex = index;
      _focus = _PlanningFocus.session;
      if (playlist != null && index < playlist.sessions.length) {
        final materials = playlist.sessions[index].materials;
        _selectedMaterialId = materials.isEmpty
            ? null
            : materials.first.materialId;
      } else {
        _selectedMaterialId = null;
      }
    });
    if (playlist == null || index >= playlist.sessions.length) {
      return;
    }
    _openPreferredRoute(_preferredRouteForSession(playlist.sessions[index]));
  }

  void _selectMaterial(LibraryWorkspaceMaterial material) {
    setState(() {
      _selectedMaterialId = material.materialId;
      _focus = _PlanningFocus.material;
    });
    final routePath = material.routePath;
    if (routePath != null && routePath.isNotEmpty) {
      widget.onOpenLibraryRoute(routePath);
    }
  }

  String _focusLabel(_PlanningFocus focus) {
    switch (focus) {
      case _PlanningFocus.pathway:
        return 'Pathway';
      case _PlanningFocus.playlist:
        return 'Playlist';
      case _PlanningFocus.session:
        return 'Session';
      case _PlanningFocus.material:
        return 'Material';
    }
  }

  Widget _buildStickySelectors(
    ThemeData theme,
    LibraryWorkspacePathway pathway,
    LibraryWorkspacePlaylist playlist,
  ) {
    final session = _selectedSession;
    final material = _selectedMaterial;

    Widget boundedDropdown(Widget child) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<_PlanningFocus>(
          segments: _PlanningFocus.values
              .map(
                (focus) => ButtonSegment<_PlanningFocus>(
                  value: focus,
                  label: Text(_focusLabel(focus)),
                ),
              )
              .toList(growable: false),
          selected: {_focus},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            setState(() {
              _focus = selection.first;
            });
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            boundedDropdown(
              DropdownButtonFormField<String>(
                initialValue: _selectedPathwayId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pathway'),
                items: widget.libraryWorkspace.pathways
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.pathwayId,
                        child: Text(item.title),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  for (final item in widget.libraryWorkspace.pathways) {
                    if (item.pathwayId == value) {
                      _selectPathway(item);
                      return;
                    }
                  }
                },
              ),
            ),
            boundedDropdown(
              DropdownButtonFormField<String>(
                initialValue: _selectedPlaylistId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Playlist'),
                items: pathway.playlists
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.playlistId,
                        child: Text(item.title),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  for (final item in pathway.playlists) {
                    if (item.playlistId == value) {
                      _selectPlaylist(item);
                      return;
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            boundedDropdown(
              DropdownButtonFormField<int>(
                initialValue: session == null ? null : _selectedSessionIndex,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Session'),
                items: playlist.sessions
                    .asMap()
                    .entries
                    .map(
                      (entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          '${entry.value.sessionIndex}. ${entry.value.title}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _selectSession(value);
                },
              ),
            ),
            boundedDropdown(
              DropdownButtonFormField<String>(
                initialValue: material?.materialId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Material'),
                items:
                    (session?.materials ?? const <LibraryWorkspaceMaterial>[])
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.materialId,
                            child: Text(item.title),
                          ),
                        )
                        .toList(growable: false),
                onChanged: (value) {
                  if (value == null || session == null) {
                    return;
                  }
                  for (final item in session.materials) {
                    if (item.materialId == value) {
                      _selectMaterial(item);
                      return;
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ContractChipRow(
          children: [
            const _ContractChip(domain: 'entity', value: 'pathway'),
            _PillBadge(
              text: pathway.title,
              color: theme.colorScheme.secondaryContainer,
              textColor: theme.colorScheme.onSecondaryContainer,
            ),
            const _ContractChip(domain: 'entity', value: 'playlist'),
            _PillBadge(
              text: playlist.title,
              color: theme.colorScheme.tertiaryContainer,
              textColor: theme.colorScheme.onTertiaryContainer,
            ),
            if (session != null) ...[
              const _ContractChip(domain: 'entity', value: 'session'),
              _PillBadge(
                text: session.title,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                textColor: theme.colorScheme.primary,
              ),
            ],
            if (material != null) ...[
              const _ContractChip(domain: 'entity', value: 'session_material'),
              _PillBadge(
                text: material.title,
                color: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFocusDetail(
    ThemeData theme,
    LibraryWorkspacePathway pathway,
    LibraryWorkspacePlaylist playlist,
  ) {
    final session = _selectedSession;
    final material = _selectedMaterial;

    switch (_focus) {
      case _PlanningFocus.pathway:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pathway.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pathway.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pathway.routePath != null) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () =>
                        widget.onOpenLibraryRoute(pathway.routePath!),
                    icon: const Icon(Icons.description_rounded, size: 16),
                    label: const Text('Open document'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _ContractChipRow(
              children: [
                const _ContractChip(domain: 'entity', value: 'pathway'),
                _PillBadge(
                  text: pathway.areaTitle,
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
                _PillBadge(
                  text: 'playlists:${pathway.playlistCount}',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
                _PillBadge(
                  text:
                      'age:${pathway.recommendedAgeMin}-${pathway.recommendedAgeMax}',
                  color: theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        );
      case _PlanningFocus.playlist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playlist.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (playlist.routePath != null) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () =>
                        widget.onOpenLibraryRoute(playlist.routePath!),
                    icon: const Icon(Icons.auto_stories_rounded, size: 16),
                    label: const Text('Open document'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _ContractChipRow(
              children: [
                const _ContractChip(domain: 'entity', value: 'playlist'),
                _PillBadge(
                  text: 'sessions:${playlist.sessions.length}',
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
                _PillBadge(
                  text: 'materials:${playlist.materialCount}',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
                _PillBadge(
                  text:
                      'minutes:${playlist.deliveryShape.estimatedTotalMinutes}',
                  color: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.onTertiaryContainer,
                ),
              ],
            ),
            if (playlist.assignmentTargets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Assignment targets', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: playlist.assignmentTargets
                      .map(
                        (target) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 244),
                            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.70),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        target.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ),
                                    if (target.recommended) ...[
                                      const SizedBox(width: 6),
                                      _PillBadge(
                                        text: 'recommended',
                                        color: theme
                                            .colorScheme
                                            .secondaryContainer,
                                        textColor: theme
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  target.statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (widget.viewerCanManage) ...[
                                  const SizedBox(height: 8),
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: target.assignedHere
                                        ? null
                                        : () => widget.onCreateAssignment(
                                            target.learnerId,
                                            playlist.playlistId,
                                          ),
                                    child: Text(
                                      target.assignedHere
                                          ? 'Assigned here'
                                          : 'Assign playlist',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ],
        );
      case _PlanningFocus.session:
        if (session == null) {
          return Text(
            'No session available for this playlist.',
            style: theme.textTheme.bodyLarge,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _ContractChipRow(
              children: [
                const _ContractChip(domain: 'entity', value: 'session'),
                _ContractChip(
                  domain: 'material_kind',
                  value: session.dominantKind,
                ),
                if (session.requiresAdultSupport)
                  const _ContractChip(domain: 'status', value: 'adult_guided'),
                _PillBadge(
                  text: 'materials:${session.materialCount}',
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
                _PillBadge(
                  text: '${session.estimatedMinutes} min',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ContractChipRow(
              children: session.materialsByKind
                  .map(
                    (group) => _PillBadge(
                      text:
                          '${group.audience}:${group.kind}:${group.materialCount}',
                      color: _materialKindBackgroundColor(theme, group.kind),
                      textColor: _materialKindForegroundColor(
                        theme,
                        group.kind,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        );
      case _PlanningFocus.material:
        if (session == null || material == null) {
          return Text(
            'No material selected in this session.',
            style: theme.textTheme.bodyLarge,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (material.routePath != null) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () =>
                        widget.onOpenLibraryRoute(material.routePath!),
                    icon: const Icon(Icons.description_rounded, size: 16),
                    label: const Text('Open material'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _ContractChipRow(
              children: [
                const _ContractChip(
                  domain: 'entity',
                  value: 'session_material',
                ),
                _ContractChip(domain: 'material_kind', value: material.kind),
                _ContractChip(domain: 'audience', value: material.audience),
                if (material.executable)
                  const _ContractChip(domain: 'status', value: 'live'),
                _PillBadge(
                  text: '${material.estimatedMinutes} min',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildCompactStudioHeader(ThemeData theme) {
    final pathways = widget.libraryWorkspace.pathways;
    final pathway = _selectedPathway;
    final playlist = _selectedPlaylist;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _PillBadge(
                      text: 'library',
                      color: theme.colorScheme.secondaryContainer,
                      textColor: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Pathway planning studio',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              _ContractChipRow(
                children: [
                  _PillBadge(
                    text: 'pathways:${widget.libraryWorkspace.pathways.length}',
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    textColor: theme.colorScheme.primary,
                  ),
                  _PillBadge(
                    text:
                        'documents:${widget.documents?.documents.length ?? 0}',
                    color: theme.colorScheme.secondaryContainer,
                    textColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  _PillBadge(
                    text: 'materials:${widget.totalMaterials}',
                    color: theme.colorScheme.tertiaryContainer,
                    textColor: theme.colorScheme.onTertiaryContainer,
                  ),
                ],
              ),
            ],
          ),
          if (pathway != null && playlist != null) ...[
            const SizedBox(height: 12),
            _buildStickySelectors(theme, pathway, playlist),
          ] else ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedPathwayId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pathway'),
                items: pathways
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.pathwayId,
                        child: Text(item.title),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  for (final item in pathways) {
                    if (item.pathwayId == value) {
                      _selectPathway(item);
                      return;
                    }
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHierarchyNavigator(ThemeData theme) {
    final pathway = _selectedPathway;
    final playlist = _selectedPlaylist;
    if (pathway == null || playlist == null) {
      return _SurfaceCard(
        child: Text(
          'Select a playlist to inspect it.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final session = _selectedSession;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Navigator', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesktopSidebarButton(
                    label: pathway.title,
                    icon: Icons.route_rounded,
                    level: 0,
                    selected: true,
                    onTap: () {
                      _selectPathway(pathway);
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pathway.playlists
                          .map((item) {
                            final isSelectedPlaylist =
                                item.playlistId == _selectedPlaylistId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DesktopSidebarButton(
                                    label: item.title,
                                    icon: Icons.playlist_play_rounded,
                                    level: 1,
                                    selected: isSelectedPlaylist,
                                    onTap: () {
                                      _selectPlaylist(item);
                                    },
                                  ),
                                  if (isSelectedPlaylist) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: item.sessions
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              final isSelectedSession =
                                                  entry.key ==
                                                  _selectedSessionIndex;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _DesktopSidebarButton(
                                                      label:
                                                          '${entry.value.sessionIndex}. ${entry.value.title}',
                                                      icon: Icons
                                                          .fact_check_rounded,
                                                      level: 2,
                                                      selected:
                                                          isSelectedSession,
                                                      onTap: () {
                                                        _selectSession(
                                                          entry.key,
                                                        );
                                                      },
                                                    ),
                                                    if (isSelectedSession) ...[
                                                      const SizedBox(height: 6),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 12,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: entry
                                                              .value
                                                              .materials
                                                              .map((material) {
                                                                final isSelectedMaterial =
                                                                    material
                                                                        .materialId ==
                                                                    _selectedMaterialId;
                                                                return Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        bottom:
                                                                            6,
                                                                      ),
                                                                  child: _DesktopSidebarButton(
                                                                    label: material
                                                                        .title,
                                                                    icon: Icons
                                                                        .description_rounded,
                                                                    level: 3,
                                                                    selected:
                                                                        isSelectedMaterial,
                                                                    onTap: () {
                                                                      _selectMaterial(
                                                                        material,
                                                                      );
                                                                    },
                                                                  ),
                                                                );
                                                              })
                                                              .toList(
                                                                growable: false,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            })
                                            .toList(growable: false),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  if (session == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Select a session to expand materials.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildContentWorkspace(ThemeData theme) {
    final pathway = _selectedPathway;
    final playlist = _selectedPlaylist;
    if (pathway == null || playlist == null) {
      return _SurfaceCard(
        child: Text(
          'Select a pathway and playlist from the navigator.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final routeBySourcePath = {
      for (final document
          in widget.documents?.documents ?? const <LibraryDocumentSummary>[])
        document.sourcePath: document.routePath,
    };

    return Column(
      children: [
        _SurfaceCard(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 164),
            alignment: Alignment.topLeft,
            child: _buildFocusDetail(theme, pathway, playlist),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _SurfaceCard(
            child: SingleChildScrollView(
              child: _LibraryDocumentReader(
                document: widget.activeDocument,
                busy: widget.libraryDocumentBusy,
                routeBySourcePath: routeBySourcePath,
                onOpenLibraryRoute: widget.onOpenLibraryRoute,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _buildCompactStudioHeader(theme),
        const SizedBox(height: 20),
        SizedBox(
          height: _desktopStudioHeight(
            context,
            subtract: 200,
            minHeight: 760,
            maxHeight: 980,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildHierarchyNavigator(theme)),
              const SizedBox(width: 20),
              Expanded(flex: 7, child: _buildContentWorkspace(theme)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopSidebarButton extends StatelessWidget {
  const _DesktopSidebarButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.level = 0,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = switch (level) {
      0 => theme.colorScheme.secondary,
      1 => theme.colorScheme.primary,
      2 => theme.colorScheme.tertiary,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    final baseColor = switch (level) {
      0 =>
        isDark
            ? Color.alphaBlend(
                theme.colorScheme.secondary.withValues(alpha: 0.08),
                theme.colorScheme.surfaceContainerHigh,
              )
            : theme.colorScheme.secondaryContainer.withValues(alpha: 0.82),
      1 => Color.alphaBlend(
        theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.10),
        isDark
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surface,
      ),
      2 => Color.alphaBlend(
        theme.colorScheme.tertiary.withValues(alpha: isDark ? 0.08 : 0.10),
        isDark
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surface,
      ),
      _ =>
        isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.74)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
    };
    final baseTextColor = switch (level) {
      0 => theme.colorScheme.onSurface,
      1 => theme.colorScheme.primary,
      2 => theme.colorScheme.tertiary,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: 14 - (level > 2 ? 2 : 0),
          vertical: level >= 2 ? 11 : 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? baseColor.withValues(alpha: 0.88)
              : baseColor.withValues(alpha: level == 0 ? 0.42 : 0.28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? baseTextColor.withValues(alpha: 0.22)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: level >= 2 ? 20 : 26,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: selected ? 0.92 : 0.36),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: level >= 2 ? 24 : 28,
              height: level >= 2 ? 24 : 28,
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withValues(alpha: isDark ? 0.16 : 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: level >= 2 ? 14 : 16,
                color: selected
                    ? baseTextColor
                    : accentColor.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:
                    (level >= 2
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.titleSmall)
                        ?.copyWith(
                          color: selected ? baseTextColor : null,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSessionNavTile extends StatelessWidget {
  const _DesktopSessionNavTile({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.10)
              : theme.colorScheme.surface.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.22)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _PillBadge(
              text: statusLabel,
              color: selected
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              textColor: selected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
