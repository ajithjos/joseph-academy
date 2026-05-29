part of '../../main.dart';

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
  final ValueChanged<String> onCreateAssignment;
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
    final activeMaterials =
        activeSession?.materials
            .where((material) => material.runtime?.executable ?? false)
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
              title: 'Current learning path',
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
                  : 'Run the current session',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activeSession.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Session ${activeSession.sequenceNumber ?? '-'} · ${activeSession.materials.length} materials',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeSession.materials
                        .map(
                          (material) => _PillBadge(
                            text: '${material.title} · ${_humanizeLabel(material.kind)}${material.runtime != null ? ' · Live' : ''}',
                            color: material.runtime != null
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.primary.withValues(alpha: 0.12),
                            textColor: material.runtime != null
                                ? theme.colorScheme.onTertiaryContainer
                                : theme.colorScheme.primary,
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
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
                                      onPressed: () => onCreateAssignment(playlist.playlistId),
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
              eyebrow: 'Parent / Teacher',
              title: viewer == null
                  ? 'Household workspace'
                  : '${viewer!.displayName} dashboard',
              description:
                  'Choose a learner, inspect their current journey, and assign the next pathway with backend-shaped data instead of raw library blobs.',
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
    final progressStatusCounts = <String, int>{};
    for (final state in learnerDetail.progress) {
      progressStatusCounts.update(
        state.status,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    Widget buildSessionSequenceCard(SessionDetail session, {required bool active}) {
      final executableMaterials = session.materials
          .where((material) => material.runtime?.executable ?? false)
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(
                        active
                            ? 'Up next'
                            : session.status == 'completed'
                            ? 'Completed'
                            : 'Pending',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.materials
                  .map(
                    (material) => _PillBadge(
                      text: '${material.title} · ${_humanizeLabel(material.kind)}${material.runtime != null ? ' · Live' : ''}',
                      color: material.runtime != null
                          ? theme.colorScheme.tertiaryContainer
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      textColor: material.runtime != null
                          ? theme.colorScheme.onTertiaryContainer
                          : theme.colorScheme.primary,
                    ),
                  )
                  .toList(growable: false),
            ),
            if (active && executableMaterials.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: executableMaterials
                    .map(
                      (material) => FilledButton.icon(
                        onPressed: () => onStartActivity(session, material),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                        label: Text('Start ${material.title}'),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        _PageHeroCard(
          eyebrow: nextSession == null ? 'Progress' : 'Active session',
          title: nextSession?.title ?? 'No active session right now',
          description: journey == null
              ? 'Work through the assigned sessions in order and start live materials when they appear here.'
              : 'Stay inside the assigned journey, follow the session order, and launch the live material when the next step is ready.',
          chips: [
            _StatChip(
              label: 'Pending',
              value: '${journey?.pendingSessionCount ?? pendingSessions.length}',
              icon: Icons.pending_actions_rounded,
            ),
            _StatChip(
              label: 'Completed',
              value: '${journey?.completedSessionCount ?? completedSessions.length}',
              icon: Icons.task_alt_rounded,
            ),
            _StatChip(
              label: 'Live Activities',
              value: '${journey?.liveMaterialCount ?? 0}',
              icon: Icons.play_circle_fill_rounded,
            ),
          ],
        ),
        if (journey != null) ...[
          const SizedBox(height: 20),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned pathway', style: theme.textTheme.headlineSmall),
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
                Text('Start the next session', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Follow the steps in order. Live materials can be launched directly here.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ...nextSession.materials.asMap().entries.map((entry) {
                  final material = entry.value;
                  final executable = material.runtime?.executable ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${entry.key + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(material.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          '${_humanizeLabel(material.kind)} · ${material.estimatedMinutes} min',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (executable)
                          FilledButton.tonalIcon(
                            onPressed: () => onStartActivity(nextSession, material),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                            label: const Text('Start live activity'),
                          )
                        else
                          Text(
                            'This step is not executable yet. Complete it with the parent or use the supporting note for this session.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Journey sequence', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Work moves forward session by session. Completed sessions stay visible so progress is obvious.',
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
              Text('Skill progress', style: theme.textTheme.headlineSmall),
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
    required this.learners,
    required this.selectedLearnerId,
    required this.viewerCanManage,
    required this.onCreateAssignment,
    required this.onOpenLibraryRoute,
  });

  final LibraryWorkspacePayload libraryWorkspace;
  final LibraryDocumentsPayload? documents;
  final LibraryDocumentData? activeDocument;
  final bool libraryDocumentBusy;
  final List<LearnerDashboard> learners;
  final String? selectedLearnerId;
  final bool viewerCanManage;
  final ValueChanged<String> onCreateAssignment;
  final ValueChanged<String> onOpenLibraryRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLearner = learners
        .where((learner) => learner.learnerId == selectedLearnerId)
        .cast<LearnerDashboard?>()
        .firstWhere((_) => true, orElse: () => null);
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
              'Browse the parent-facing pathway contract, inspect the ordered playlist shape, and assign the right entry point for the selected learner.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _PillBadge(
              text: selectedLearner == null
                  ? 'Select a learner in Household to assign from here'
                  : 'Assignment target: ${selectedLearner.displayName}',
              color: selectedLearner == null
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.secondaryContainer,
              textColor: selectedLearner == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSecondaryContainer,
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
                                        text: '${playlist.liveMaterialCount} live',
                                        color: theme.colorScheme.tertiaryContainer,
                                        textColor: theme.colorScheme.onTertiaryContainer,
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
                                    ],
                                  ),
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
                                              children: session.materials
                                                  .map(
                                                    (material) => _PillBadge(
                                                      text: '${material.title} · ${_humanizeLabel(material.kind)}${material.executable ? ' · Live' : ''}',
                                                      color: material.executable
                                                          ? theme.colorScheme.tertiaryContainer
                                                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                                                      textColor: material.executable
                                                          ? theme.colorScheme.onTertiaryContainer
                                                          : theme.colorScheme.primary,
                                                    ),
                                                  )
                                                  .toList(growable: false),
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
                                      if (viewerCanManage)
                                        FilledButton.tonal(
                                          onPressed: selectedLearner == null
                                              ? null
                                              : () => onCreateAssignment(playlist.playlistId),
                                          child: Text(
                                            selectedLearner == null
                                                ? 'Select learner to assign'
                                                : 'Assign to ${selectedLearner.displayName}',
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
                  'Browse the backend-derived pathway catalog, inspect ordered playlists and materials, then read the authored markdown without leaving the app.',
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
