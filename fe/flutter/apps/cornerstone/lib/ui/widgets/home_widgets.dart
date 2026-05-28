part of '../../main.dart';

String _humanizeLabel(String value) {
  final parts = value
    .split(RegExp(r'[_\-\s]+'))
    .where((part) => part.isNotEmpty)
    .toList(growable: false);
  if (parts.isEmpty) return value;
  return parts
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
}

class _LearnerOperationsPanel extends StatelessWidget {
  const _LearnerOperationsPanel({
    required this.detail,
    required this.library,
    required this.currentActionSession,
    required this.scoreController,
    required this.maxScoreController,
    required this.durationController,
    required this.notesController,
    required this.onCreateAssignment,
    required this.onRecordSession,
    required this.onStartActivity,
  });

  final LearnerDetailPayload detail;
  final LibraryBundle library;
  final SessionDetail? currentActionSession;
  final TextEditingController scoreController;
  final TextEditingController maxScoreController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final ValueChanged<String> onCreateAssignment;
  final VoidCallback onRecordSession;
  final ValueChanged<SessionMaterial> onStartActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressStatusCounts = <String, int>{};
    for (final state in detail.progress) {
      progressStatusCounts.update(state.status, (count) => count + 1, ifAbsent: () => 1);
    }
    final executableMaterials = currentActionSession?.materials
            .where((material) => material.runtime?.executable ?? false)
            .toList(growable: false) ??
        const <SessionMaterial>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.learner.displayName, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _PillBadge(text: detail.learner.currentLevel, color: theme.colorScheme.secondaryContainer, textColor: theme.colorScheme.onSecondaryContainer),
            _PillBadge(text: 'Age ${detail.learner.currentAge}', color: theme.colorScheme.primary.withValues(alpha: 0.12), textColor: theme.colorScheme.primary),
          ],
        ),
        const SizedBox(height: 22),
        if (detail.activeAssignment != null) ...[
          _Band(
            title: 'Active Assignment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.activeAssignment!.title,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: detail.activeAssignment!.completionPercent / 100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${detail.activeAssignment!.completedSessions}/${detail.activeAssignment!.totalSessions}',
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${detail.activeAssignment!.completedSessions} of ${detail.activeAssignment!.totalSessions} sessions complete',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Band(
          title: 'Create Assignment',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: library.playlists
                .map(
                  (playlist) => ActionChip(
                    label: Text(playlist.title),
                    onPressed: () => onCreateAssignment(playlist.playlistId),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (currentActionSession != null) ...[
          _Band(
            title: executableMaterials.isNotEmpty ? 'Run Current Session' : 'Record Current Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentActionSession!.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: currentActionSession!.materials
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
                const SizedBox(height: 12),
                if (executableMaterials.isNotEmpty) ...[
                  Text(
                    'Launch the live material here when the learner is ready. Static sessions still use the manual record form below.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: executableMaterials
                        .map(
                          (material) => FilledButton.icon(
                            onPressed: () => onStartActivity(material),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                            label: Text('Start ${material.title}'),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ] else ...[
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
                  FilledButton.icon(onPressed: onRecordSession, icon: const Icon(Icons.check_circle_rounded, size: 18), label: const Text('Record session')),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Band(
          title: 'Skill Progress',
          child: detail.progress.isEmpty
              ? Text(
                  'No progress has been recorded yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              : Wrap(
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
        ),
        const SizedBox(height: 20),
        _Band(
          title: 'Review Items',
          child: detail.reviewItems.isEmpty
              ? Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('No pending review items.'),
                  ],
                )
              : Column(
                  children: detail.reviewItems
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.reason),
                          trailing: _PillBadge(
                            text: item.dueDate,
                            color: Theme.of(context).colorScheme.errorContainer,
                            textColor: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _ExecutableActivityDialog extends StatefulWidget {
  const _ExecutableActivityDialog({
    required this.activity,
    required this.onComplete,
  });

  final ActivityInstance activity;
  final Future<CompleteActivityResponse> Function(
    List<String> answers,
    int durationSeconds,
    String notes,
  ) onComplete;

  @override
  State<_ExecutableActivityDialog> createState() => _ExecutableActivityDialogState();
}

class _ExecutableActivityDialogState extends State<_ExecutableActivityDialog> {
  late final List<TextEditingController> _answerControllers;
  final TextEditingController _notesController = TextEditingController();
  late final DateTime _startedAt;
  bool _submitting = false;
  String? _errorMessage;
  CompleteActivityResponse? _result;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _answerControllers = widget.activity.prompts
        .map((_) => TextEditingController())
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
      final response = await widget.onComplete(
        _answerControllers.map((controller) => controller.text.trim()).toList(growable: false),
        elapsedSeconds <= 0 ? 1 : elapsedSeconds,
        _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = response;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: result != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.activity.materialTitle, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Completed with ${result.activitySummary.correctCount}/${result.activitySummary.promptCount} correct (${(result.activitySummary.accuracy * 100).round()}%).',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PillBadge(
                          text: result.activitySummary.passed ? 'Pass threshold met' : 'More review needed',
                          color: result.activitySummary.passed
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.errorContainer,
                          textColor: result.activitySummary.passed
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onErrorContainer,
                        ),
                        ...result.activitySummary.weakGroups.map(
                          (group) => _PillBadge(
                            text: _humanizeLabel(group),
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            textColor: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.activity.materialTitle,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.activity.instructions, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PillBadge(
                          text: '${widget.activity.prompts.length} prompts',
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          textColor: theme.colorScheme.primary,
                        ),
                        _PillBadge(
                          text: '${widget.activity.estimatedMinutes} min',
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          textColor: theme.colorScheme.primary,
                        ),
                        if (widget.activity.scoring.passAccuracy != null)
                          _PillBadge(
                            text: '${(widget.activity.scoring.passAccuracy! * 100).round()}% pass',
                            color: theme.colorScheme.secondaryContainer,
                            textColor: theme.colorScheme.onSecondaryContainer,
                          ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: widget.activity.prompts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final prompt = widget.activity.prompts[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prompt ${index + 1}', style: theme.textTheme.labelLarge),
                                const SizedBox(height: 8),
                                Text(prompt.prompt, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _answerControllers[index],
                                  keyboardType: TextInputType.number,
                                  enabled: !_submitting,
                                  decoration: const InputDecoration(labelText: 'Answer'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      enabled: !_submitting,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes for this run'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.playlist_add_check_circle_rounded, size: 18),
                        label: const Text('Submit activity'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({required this.learner, required this.selected, required this.onTap});

  final LearnerDashboard learner;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? isDark
                      ? [Color.alphaBlend(_BrandPalette.goldBright.withValues(alpha: 0.10), _BrandPalette.slateRaised), _BrandPalette.slateCard]
                      : [Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.14), Colors.white), _BrandPalette.warmWhite]
                : isDark
                ? [theme.colorScheme.surface, _BrandPalette.slateRaised]
                : [theme.colorScheme.surface, _BrandPalette.warmPaper],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.34) : theme.colorScheme.outlineVariant.withValues(alpha: 0.64),
            width: selected ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.10) : Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
              blurRadius: selected ? 24 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(learner.displayName, style: theme.textTheme.titleLarge)),
                _PillBadge(text: 'Age ${learner.currentAge}', color: theme.colorScheme.primary.withValues(alpha: 0.12), textColor: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 5),
            Text(learner.currentLevel, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (learner.activeAssignment != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.assignment_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      learner.activeAssignment!.title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pending_actions_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Review: ${learner.reviewItemCount}', style: theme.textTheme.bodySmall),
                if (learner.todaySession != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.today_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(learner.todaySession!.title, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [theme.colorScheme.surface, _BrandPalette.slateRaised] : [theme.colorScheme.surface, _BrandPalette.warmPaper],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.58 : 0.72)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
              blurRadius: isDark ? 26 : 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              right: -24,
              child: IgnorePointer(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(26), child: child),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [_BrandPalette.slateHigh, _BrandPalette.slateRaised] : [Colors.white, _BrandPalette.warmPaper],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: -0.5),
              ),
              Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [_BrandPalette.slateRaised, _BrandPalette.slateCard] : [const Color(0xFFFFFCF6), const Color(0xFFF8F0E3)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.36), blurRadius: 12)],
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.text, required this.color, required this.textColor});

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }
}

class _GoldAccentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary.withValues(alpha: 0.0), theme.colorScheme.primary.withValues(alpha: 0.64), theme.colorScheme.primary.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _PageHeroCard extends StatelessWidget {
  const _PageHeroCard({required this.eyebrow, required this.title, required this.description, this.trailing, this.chips = const <Widget>[]});

  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? const [Color(0xFF2A241D), Color(0xFF221E1A), Color(0xFF161412)] : const [Color(0xFFFFF2C9), Color(0xFFFFFCF7), Color(0xFFF5EBDD)],
          stops: const [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = trailing == null || constraints.maxWidth < 760;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.20)),
                ),
                child: Text(
                  eyebrow.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.displaySmall),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(description, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              if (chips.isNotEmpty) ...[const SizedBox(height: 20), Wrap(spacing: 12, runSpacing: 12, children: chips)],
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (trailing != null) ...[const SizedBox(height: 20), trailing!],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: trailing!),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: theme.colorScheme.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, size: 40, color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: () => onRetry(), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.compact = false, this.toolbarVariant = false, this.onTap});

  final bool compact;
  final bool toolbarVariant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbolSize = toolbarVariant ? (compact ? 22.0 : 26.0) : (compact ? 30.0 : 36.0);
    final wordmarkHeight = toolbarVariant ? (compact ? 16.0 : 20.0) : (compact ? 20.0 : 26.0);
    final padding = toolbarVariant
        ? (compact ? const EdgeInsets.fromLTRB(2, 2, 4, 2) : const EdgeInsets.fromLTRB(4, 3, 6, 3))
        : compact
        ? const EdgeInsets.fromLTRB(8, 6, 10, 6)
        : const EdgeInsets.fromLTRB(10, 8, 14, 8);
    final radius = toolbarVariant ? 14.0 : 16.0;

    final contents = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandSymbol(size: symbolSize),
        if (!compact) ...[SizedBox(width: compact ? 6 : 8), _BrandWordmark(height: wordmarkHeight)],
      ],
    );

    final badge = toolbarVariant
        ? Padding(padding: padding, child: contents)
        : AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding,
            decoration: BoxDecoration(
              color: isDark ? _BrandPalette.slateRaised : Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _BrandPalette.gold.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: contents,
          );

    if (onTap == null) {
      return badge;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: badge),
    );
  }
}

class _BrandSymbol extends StatelessWidget {
  const _BrandSymbol({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.24)),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        minWidth: size * 1.84,
        minHeight: size * 1.84,
        maxWidth: size * 1.84,
        maxHeight: size * 1.84,
        alignment: Alignment.center,
        child: Image.asset('assets/images/logo_symbol.png', width: size * 1.84, height: size * 1.84, fit: BoxFit.cover, filterQuality: FilterQuality.high),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Cornerstone',
      maxLines: 1,
      style: GoogleFonts.sora(color: theme.colorScheme.onSurface, fontSize: height * 1.08, fontWeight: FontWeight.w600, letterSpacing: -1.1, height: 1),
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel({required this.controller});

  final CornerstoneThemeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 360;
            final selector = SizedBox(
              width: stacked ? double.infinity : 176,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 15)),
                  ButtonSegment<ThemeMode>(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 15)),
                  ButtonSegment<ThemeMode>(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 15)),
                ],
                selected: <ThemeMode>{controller.themeMode},
                onSelectionChanged: (selection) => controller.setThemeMode(selection.first),
              ),
            );

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.brightness == Brightness.dark ? [_BrandPalette.slateRaised, _BrandPalette.slateCard] : [Colors.white, _BrandPalette.warmPaper],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appearance', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(switch (controller.themeMode) {
                            ThemeMode.light => 'Light mode active',
                            ThemeMode.dark => 'Dark mode active',
                            ThemeMode.system => 'Following system theme',
                          }, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 14),
                          selector,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Appearance', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(switch (controller.themeMode) {
                                  ThemeMode.light => 'Light mode active',
                                  ThemeMode.dark => 'Dark mode active',
                                  ThemeMode.system => 'Following system theme',
                                }, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          selector,
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

