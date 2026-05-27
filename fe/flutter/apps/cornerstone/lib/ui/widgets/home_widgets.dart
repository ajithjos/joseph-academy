part of '../../main.dart';

class _LearnerOperationsPanel extends StatelessWidget {
  const _LearnerOperationsPanel({
    required this.detail,
    required this.catalog,
    required this.currentActionSession,
    required this.scoreController,
    required this.maxScoreController,
    required this.durationController,
    required this.notesController,
    required this.onAssignPlan,
    required this.onRecordSession,
  });

  final LearnerDetailPayload detail;
  final CatalogBundle catalog;
  final SessionDetail? currentActionSession;
  final TextEditingController scoreController;
  final TextEditingController maxScoreController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final ValueChanged<String> onAssignPlan;
  final VoidCallback onRecordSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.learner.displayName, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _PillBadge(
              text: detail.learner.currentLevel,
              color: theme.colorScheme.secondaryContainer,
              textColor: theme.colorScheme.onSecondaryContainer,
            ),
            _PillBadge(
              text: 'Age ${detail.learner.currentAge}',
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              textColor: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (detail.activePlan != null) ...[
          _Band(
            title: 'Active Plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.activePlan!.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: detail.activePlan!.completionPercent / 100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${detail.activePlan!.completedSessions}/${detail.activePlan!.totalSessions}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${detail.activePlan!.completedSessions} of ${detail.activePlan!.totalSessions} sessions complete',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Band(
          title: 'Assign Plan',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: catalog.planTemplates
                .map(
                  (plan) => ActionChip(
                    label: Text(plan.title),
                    onPressed: () => onAssignPlan(plan.planTemplateId),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (currentActionSession != null) ...[
          _Band(
            title: 'Record Current Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentActionSession!.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 14),
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
            ),
          ),
          const SizedBox(height: 20),
        ],
        _Band(
          title: 'Capability States',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: detail.capabilityStates
                .map((state) => _CapabilityStateChip(state: state))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        _Band(
          title: 'Review Queue',
          child: detail.reviewQueue.isEmpty
              ? Row(
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
              : Column(
                  children: detail.reviewQueue
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.capabilityId),
                          subtitle: Text(
                            item.reason,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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

class _LearnerCard extends StatelessWidget {
  const _LearnerCard({
    required this.learner,
    required this.selected,
    required this.onTap,
  });

  final LearnerCard learner;
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
          color: selected
              ? isDark
                    ? Color.alphaBlend(
                        _BrandPalette.goldBright.withValues(alpha: 0.08),
                        _BrandPalette.slateRaised,
                      )
                    : Color.alphaBlend(
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                        Colors.white,
                      )
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 3,
            ),
            top: BorderSide(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.36)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.70),
            ),
            right: BorderSide(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.36)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.70),
            ),
            bottom: BorderSide(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.36)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.70),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 20 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(learner.displayName, style: theme.textTheme.titleLarge),
                ),
                _PillBadge(
                  text: 'Age ${learner.currentAge}',
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  textColor: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              learner.currentLevel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (learner.activePlan != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      learner.activePlan!.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text('Review: ${learner.reviewQueueCount}', style: theme.textTheme.bodySmall),
                if (learner.todaySession != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.today_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      learner.todaySession!.title,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: isDark ? 24 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isDark
          ? DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0AFFFFFF), Colors.transparent],
                  stops: [0.0, 0.25],
                ),
              ),
              child: child,
            )
          : child,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateRaised : const Color(0xFFFCF8EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CapabilityStateChip extends StatelessWidget {
  const _CapabilityStateChip({required this.state});

  final CapabilityStateSummary state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = (state.scoreAverage * 100).round();
    final isStrong = pct >= 80;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateHigh : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStrong
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.capabilityId,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isStrong ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text('${state.status} · $pct% avg', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _GoldAccentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.0),
            theme.colorScheme.primary.withValues(alpha: 0.55),
            theme.colorScheme.primary.withValues(alpha: 0.0),
          ],
        ),
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
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBrandHeader extends StatelessWidget {
  const _NavBrandHeader({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(expanded ? 18 : 12, 18, expanded ? 18 : 12, 0),
      child: Column(
        crossAxisAlignment: expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandSymbol(size: expanded ? 34 : 28),
              if (expanded) ...[
                const SizedBox(width: 10),
                const _BrandWordmark(height: 19),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                  theme.colorScheme.primary.withValues(alpha: 0.60),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({
    this.compact = false,
    this.toolbarVariant = false,
    this.mobileVariant = false,
    this.onTap,
  });

  final bool compact;
  final bool toolbarVariant;
  final bool mobileVariant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbolSize = toolbarVariant ? (compact ? 28.0 : 32.0) : (compact ? 36.0 : 44.0);
    final wordmarkHeight = toolbarVariant ? (compact ? 16.0 : 20.0) : (compact ? 20.0 : 26.0);
    final padding = toolbarVariant
        ? (compact
              ? const EdgeInsets.fromLTRB(6, 4, 10, 4)
              : const EdgeInsets.fromLTRB(8, 5, 12, 5))
        : compact
        ? const EdgeInsets.fromLTRB(8, 6, 10, 6)
        : const EdgeInsets.fromLTRB(10, 8, 14, 8);
    final radius = toolbarVariant ? 14.0 : 16.0;

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _BrandPalette.slateRaised : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _BrandPalette.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? (toolbarVariant ? 0.20 : 0.24) : (toolbarVariant ? 0.06 : 0.09),
            ),
            blurRadius: toolbarVariant ? 10 : 14,
            offset: Offset(0, toolbarVariant ? 4 : 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandSymbol(size: symbolSize),
          if (!compact || mobileVariant) ...[
            SizedBox(width: compact ? 6 : 8),
            _BrandWordmark(height: wordmarkHeight),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return badge;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: badge,
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        minWidth: size * 1.84,
        minHeight: size * 1.84,
        maxWidth: size * 1.84,
        maxHeight: size * 1.84,
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/logo_symbol.png',
          width: size * 1.84,
          height: size * 1.84,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Image.asset(
        'assets/images/logo_wordmark.png',
        fit: BoxFit.fitHeight,
        filterQuality: FilterQuality.high,
      ),
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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Appearance',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        switch (controller.themeMode) {
                          ThemeMode.light => 'Light mode active',
                          ThemeMode.dark => 'Dark mode active',
                          ThemeMode.system => 'Following system theme',
                        },
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 162,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded, size: 15),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded, size: 15),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded, size: 15),
                      ),
                    ],
                    selected: <ThemeMode>{controller.themeMode},
                    onSelectionChanged: (selection) => controller.setThemeMode(selection.first),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.44)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.tonal(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}