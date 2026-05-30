part of '../../../main.dart';

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
  final Future<void> Function(String learnerId, String playlistId) onCreateAssignment;
  final ValueChanged<String> onOpenLibraryRoute;
  final VoidCallback onOpenLibraryWorkspace;
  final VoidCallback onRecordSession;
  final Future<void> Function(SessionDetail session, SessionMaterial material) onStartActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalReviewItems = learners.fold<int>(0, (count, learner) => count + learner.reviewItemCount);
    final activeSessionCount = learners.where((learner) => learner.todaySession != null).length;
    final selectedDetail = detail;
    final journey = selectedDetail?.journey;
    final workspace = selectedDetail?.workspace;
    final continueBlock = workspace?.continueBlock;
    final recentWins = workspace?.recentWins ?? const <LearnerRecentWin>[];
    SessionDetail? activeSession;
    if (selectedDetail != null) {
      for (final session in selectedDetail.sessions) {
        if (session.status != 'completed') {
          activeSession = session;
          break;
        }
      }
    }
    activeSession ??= currentActionSession;
    final learnerFacingGroups =
        activeSession?.materialsByKind.where((group) => group.audience == 'learner').toList(growable: false) ?? const <SessionMaterialKindGroup>[];
    final adultFacingGroups = activeSession?.materialsByKind.where((group) => group.audience == 'adult').toList(growable: false) ?? const <SessionMaterialKindGroup>[];
    final currentStanding = activeSession?.sequenceNumber ?? (journey != null && journey.totalSessionCount > 0 ? journey.completedSessionCount + 1 : null);
    final journeyProgress = journey == null || journey.totalSessionCount == 0 ? null : (journey.completedSessionCount / journey.totalSessionCount).clamp(0.0, 1.0);
    final activeMaterials = activeSession?.materials.where((material) => material.isExecutable).toList(growable: false) ?? const <SessionMaterial>[];

    Widget buildSelectionPanel() {
      if (selectedDetail == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search_rounded, size: 54, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  'Choose a learner from the roster to open one clear view of assignments, sessions, and progress.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      }

      final statusCounts = <String, int>{};
      for (final state in selectedDetail.progress) {
        statusCounts.update(state.status, (count) => count + 1, ifAbsent: () => 1);
      }
      final secureCount = statusCounts['secure'] ?? 0;
      final developingCount = statusCounts['developing'] ?? 0;
      final notStartedCount = statusCounts['not_started'] ?? 0;
      final reviewCount = selectedDetail.reviewItems.length;

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
                    Text(selectedDetail.learner.displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
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
                        if ((workspace?.attentionLabel ?? '').isNotEmpty)
                          _PillBadge(text: workspace!.attentionLabel, color: theme.colorScheme.surfaceContainerHighest, textColor: theme.colorScheme.onSurfaceVariant),
                        if (selectedDetail.activeAssignment != null)
                          _PillBadge(
                            text: '${selectedDetail.activeAssignment!.completedSessions}/${selectedDetail.activeAssignment!.totalSessions} completed',
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
          const SizedBox(height: 20),
          _Band(
            title: 'Assigned pathway',
            child: journey == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No pathway is assigned to this learner yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onOpenLibraryWorkspace,
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: const Text('Assign first pathway'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (journey.pathwayTitle != null) Text(journey.pathwayTitle!, style: theme.textTheme.titleLarge),
                      if ((journey.pathwayDescription ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(journey.pathwayDescription!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 10),
                      Text(journey.playlistTitle, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(journey.playlistDescription, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (currentStanding != null)
                            _PillBadge(
                              text: 'Current session: $currentStanding/${journey.totalSessionCount}',
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
                      if (journeyProgress != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(minHeight: 10, value: journeyProgress, backgroundColor: theme.colorScheme.surfaceContainerHighest),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (journey.pathwayRoutePath != null)
                            TextButton(onPressed: () => onOpenLibraryRoute(journey.pathwayRoutePath!), child: const Text('Open pathway document')),
                          if (journey.playlistRoutePath != null)
                            TextButton(onPressed: () => onOpenLibraryRoute(journey.playlistRoutePath!), child: const Text('Open playlist document')),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          _Band(
            title: 'Current session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (continueBlock != null) ...[
                  Text(continueBlock.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(continueBlock.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 10),
                ],
                if (activeSession != null) ...[
                  Text(activeSession.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillBadge(
                        text: 'Session ${activeSession.sequenceNumber ?? '-'}',
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      if (activeSession.estimatedMinutes > 0)
                        _PillBadge(
                          text: '${activeSession.estimatedMinutes} min',
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          textColor: theme.colorScheme.primary,
                        ),
                      if (activeSession.requiresAdultSupport)
                        _PillBadge(text: 'Adult-guided', color: theme.colorScheme.tertiaryContainer, textColor: theme.colorScheme.onTertiaryContainer),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          tabs: [
                            Tab(text: 'Learner items (${learnerFacingGroups.length})'),
                            Tab(text: 'Teacher notes (${adultFacingGroups.length})'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: _SessionWorkspaceAudiencePanel(
                                  title: 'Learner items',
                                  description: 'Everything the learner needs for this session.',
                                  emptyState: 'No learner-facing materials are attached to this session yet.',
                                  icon: Icons.school_rounded,
                                  groups: learnerFacingGroups,
                                  session: activeSession,
                                  viewerCanReadLibrary: viewer?.canReadLibrary ?? false,
                                  showDocumentBodies: true,
                                  onOpenLibraryRoute: onOpenLibraryRoute,
                                  onStartActivity: onStartActivity,
                                ),
                              ),
                              SingleChildScrollView(
                                child: _SessionWorkspaceAudiencePanel(
                                  title: 'Teacher notes',
                                  description: 'Teaching guidance for running this session.',
                                  emptyState: 'No adult guidance notes are attached to this session.',
                                  icon: Icons.record_voice_over_rounded,
                                  groups: adultFacingGroups,
                                  session: activeSession,
                                  viewerCanReadLibrary: viewer?.canReadLibrary ?? false,
                                  showDocumentBodies: true,
                                  onOpenLibraryRoute: onOpenLibraryRoute,
                                  onStartActivity: onStartActivity,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activeMaterials.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: activeMaterials
                          .map(
                            (material) => FilledButton.icon(
                              onPressed: () => onStartActivity(activeSession!, material),
                              icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                              label: Text('Start ${material.title}'),
                            ),
                          )
                          .toList(growable: false),
                    )
                  else ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _CompactField(label: 'Score', controller: scoreController),
                        _CompactField(label: 'Max score', controller: maxScoreController),
                        _CompactField(label: 'Minutes', controller: durationController),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Session notes'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: onRecordSession, icon: const Icon(Icons.check_circle_rounded, size: 18), label: const Text('Record session')),
                  ],
                ] else
                  Text('No active session for this learner right now.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Band(
            title: 'Progress',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(label: 'Secure', value: '$secureCount', icon: Icons.verified_rounded),
                    _StatChip(label: 'Developing', value: '$developingCount', icon: Icons.construction_rounded),
                    _StatChip(label: 'Not Started', value: '$notStartedCount', icon: Icons.hourglass_bottom_rounded),
                    _StatChip(label: 'Review', value: '$reviewCount', icon: Icons.pending_actions_rounded),
                  ],
                ),
                if (recentWins.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Recent evidence', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...recentWins
                      .map(
                        (win) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(win.sessionTitle, style: theme.textTheme.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      win.notes.isEmpty ? 'Recorded session evidence.' : win.notes,
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _PillBadge(text: win.scoreLabel, color: theme.colorScheme.secondaryContainer, textColor: theme.colorScheme.onSecondaryContainer),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Band(
            title: 'Assign pathway order',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick one pathway and assign its first playlist as the explicit next order for this learner.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  starterPlaylist ??= pathway.playlists.isNotEmpty ? pathway.playlists.first : null;
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
                        Text(pathway.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                            if (pathway.routePath != null) TextButton(onPressed: () => onOpenLibraryRoute(pathway.routePath!), child: const Text('Open pathway')),
                            if (starterPlaylist != null) ...[
                              Builder(
                                builder: (context) {
                                  final playlist = starterPlaylist!;
                                  return FilledButton.tonalIcon(
                                    onPressed: () => onCreateAssignment(selectedDetail.learner.learnerId, playlist.playlistId),
                                    icon: const Icon(Icons.playlist_add_check_circle_rounded, size: 18),
                                    label: Text('Assign order: ${playlist.title}'),
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
                'Pick one learner to focus the right panel on assignment, session, and progress details.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _GoldAccentDivider(),
              const SizedBox(height: 14),
              if (learners.isEmpty)
                Text('No learners are visible in this workspace yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
              else
                ...learners.map(
                  (learner) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LearnerCard(learner: learner, selected: learner.learnerId == selectedLearnerId, onTap: () => onSelectLearner(learner.learnerId)),
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
                      _PillBadge(text: 'team', color: theme.colorScheme.secondaryContainer, textColor: theme.colorScheme.onSecondaryContainer),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Team teaching workspace', style: theme.textTheme.titleLarge)),
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
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  _ContractChipRow(
                    children: [
                      _PillBadge(text: '${learners.length} learners', color: theme.colorScheme.primary.withValues(alpha: 0.12), textColor: theme.colorScheme.primary),
                      _PillBadge(
                        text: '$activeSessionCount active today',
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                      _PillBadge(text: '$totalReviewItems review items', color: theme.colorScheme.tertiaryContainer, textColor: theme.colorScheme.onTertiaryContainer),
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
                  Expanded(flex: 6, child: _SurfaceCard(child: buildSelectionPanel())),
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
