import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';

void main() {
  runApp(const CornerstoneApp());
}

class CornerstoneApp extends StatelessWidget {
  const CornerstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cornerstone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E))
            .copyWith(
              primary: const Color(0xFF0F766E),
              secondary: const Color(0xFFD97706),
            ),
        scaffoldBackgroundColor: const Color(0xFFF7F3EA),
      ),
      home: const CornerstoneHomePage(),
    );
  }
}

class CornerstoneHomePage extends StatefulWidget {
  const CornerstoneHomePage({super.key});

  @override
  State<CornerstoneHomePage> createState() => _CornerstoneHomePageState();
}

class _CornerstoneHomePageState extends State<CornerstoneHomePage> {
  final CornerstoneApiClient _apiClient = CornerstoneApiClient();
  final TextEditingController _scoreController = TextEditingController(
    text: '8',
  );
  final TextEditingController _maxScoreController = TextEditingController(
    text: '10',
  );
  final TextEditingController _durationController = TextEditingController(
    text: '15',
  );
  final TextEditingController _notesController = TextEditingController(
    text: 'Completed well with one or two slow facts.',
  );

  DashboardPayload? _dashboard;
  CatalogPayload? _catalog;
  LearnerDetailPayload? _learnerDetail;
  String? _selectedLearnerId;
  bool _loading = true;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _maxScoreController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool preserveSelection = true}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final dashboard = await _apiClient.fetchDashboard();
      final catalog = await _apiClient.fetchCatalog();
      final nextLearnerId = preserveSelection && _selectedLearnerId != null
          ? _selectedLearnerId
          : (dashboard.learners.isNotEmpty
                ? dashboard.learners.first.learnerId
                : null);
      LearnerDetailPayload? learnerDetail;
      if (nextLearnerId != null) {
        learnerDetail = await _apiClient.fetchLearnerDetail(nextLearnerId);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _catalog = catalog;
        _selectedLearnerId = nextLearnerId;
        _learnerDetail = learnerDetail;
        _loading = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _selectLearner(String learnerId) async {
    setState(() {
      _selectedLearnerId = learnerId;
      _busy = true;
      _errorMessage = null;
    });
    try {
      final learnerDetail = await _apiClient.fetchLearnerDetail(learnerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _learnerDetail = learnerDetail;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _assignPlan(String planTemplateId) async {
    final learnerId = _selectedLearnerId;
    if (learnerId == null) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      await _apiClient.assignPlan(
        learnerId: learnerId,
        planTemplateId: planTemplateId,
        startDate: today,
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _recordCurrentSession() async {
    final session = _currentActionSession;
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await _apiClient.recordSession(
        sessionId: session.sessionId,
        score: double.parse(_scoreController.text),
        maxScore: double.parse(_maxScoreController.text),
        durationMinutes: int.parse(_durationController.text),
        notes: _notesController.text,
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.toString();
      });
    }
  }

  SessionDetail? get _currentActionSession {
    final detail = _learnerDetail;
    if (detail == null) {
      return null;
    }
    for (final session in detail.sessions) {
      if (session.status != 'completed') {
        return session;
      }
    }
    return detail.sessions.isNotEmpty ? detail.sessions.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;
    final catalog = _catalog;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/images/logo_symbol.png', height: 30),
              const SizedBox(width: 12),
              Image.asset('assets/images/logo_wordmark.png', height: 22),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              onPressed: _busy ? null : () => _loadAll(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Owner'),
              Tab(text: 'Learner'),
              Tab(text: 'Catalog'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _ErrorState(message: _errorMessage!, onRetry: () => _loadAll())
            : dashboard == null || catalog == null
            ? const Center(child: Text('No data loaded'))
            : TabBarView(
                children: [
                  _buildOwnerView(context, dashboard, catalog),
                  _buildLearnerView(context),
                  _buildCatalogView(context, catalog),
                ],
              ),
      ),
    );
  }

  Widget _buildOwnerView(
    BuildContext context,
    DashboardPayload dashboard,
    CatalogPayload catalog,
  ) {
    final detail = _learnerDetail;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1120;
        final leftPanel = _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.team?.displayName ?? 'Learning Team',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                dashboard.team?.description ?? 'Household learning operations',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatChip(
                    label: 'Capabilities',
                    value: '${dashboard.catalog.capabilityCount}',
                  ),
                  _StatChip(
                    label: 'Plans',
                    value: '${dashboard.catalog.planTemplateCount}',
                  ),
                  _StatChip(
                    label: 'Content',
                    value: '${dashboard.catalog.contentItemCount}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...dashboard.learners.map(
                (learner) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _LearnerCard(
                    learner: learner,
                    selected: learner.learnerId == _selectedLearnerId,
                    onTap: () => _selectLearner(learner.learnerId),
                  ),
                ),
              ),
            ],
          ),
        );
        final rightPanel = _SurfaceCard(
          child: detail == null
              ? const Center(
                  child: Text(
                    'Select a learner to inspect plan and review state.',
                  ),
                )
              : _LearnerOperationsPanel(
                  detail: detail,
                  catalog: catalog.bundle,
                  currentActionSession: _currentActionSession,
                  scoreController: _scoreController,
                  maxScoreController: _maxScoreController,
                  durationController: _durationController,
                  notesController: _notesController,
                  onAssignPlan: _assignPlan,
                  onRecordSession: _recordCurrentSession,
                ),
        );
        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: leftPanel),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(child: rightPanel),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [leftPanel, const SizedBox(height: 20), rightPanel],
        );
      },
    );
  }

  Widget _buildLearnerView(BuildContext context) {
    final detail = _learnerDetail;
    final session = _currentActionSession;
    if (detail == null || session == null) {
      return const Center(
        child: Text('Select a learner with an active session.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _SurfaceCard(
        background: const Color(0xFF0E3B39),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${detail.learner.displayName} Session',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFFFF6E5),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: session.activities
                  .map(
                    (activity) => Container(
                      width: 280,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.capabilityId,
                            style: const TextStyle(
                              color: Color(0xFFFFD9A3),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activity.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Content: ${activity.contentId}',
                            style: const TextStyle(color: Color(0xFFE7F1EF)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Today: ${session.scheduledDate}',
              style: const TextStyle(color: Color(0xFFE7F1EF), fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogView(BuildContext context, CatalogPayload catalog) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catalog Snapshots',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text('Loaded at ${catalog.report.loadedAtUtc}'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatChip(
                    label: 'Capabilities',
                    value: '${catalog.report.capabilityCount}',
                  ),
                  _StatChip(
                    label: 'Milestones',
                    value: '${catalog.report.milestoneCount}',
                  ),
                  _StatChip(
                    label: 'Plans',
                    value: '${catalog.report.planTemplateCount}',
                  ),
                  _StatChip(
                    label: 'Content',
                    value: '${catalog.report.contentItemCount}',
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
              Text(
                'Plan Templates',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...catalog.bundle.planTemplates.map(
                (plan) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(plan.title),
                  subtitle: Text(
                    'Age ${plan.recommendedAge} • ${plan.recommendedLevel} • ${plan.durationDays} days',
                  ),
                  trailing: Text('${plan.capabilityIds.length} caps'),
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
              Text(
                'Content Items',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...catalog.bundle.contentItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text('${item.subject} • ${item.kind}'),
                  trailing: Text(item.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.learner.displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${detail.learner.currentLevel} • age ${detail.learner.currentAge}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (detail.activePlan != null)
          _Band(
            title: 'Active Plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.activePlan!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${detail.activePlan!.completedSessions}/${detail.activePlan!.totalSessions} sessions complete',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: detail.activePlan!.completionPercent / 100,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _Band(
          title: 'Assign Plan',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
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
        if (currentActionSession != null)
          _Band(
            title: 'Record Current Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentActionSession!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CompactField(label: 'Score', controller: scoreController),
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
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onRecordSession,
                  child: const Text('Record session and rebuild review'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _Band(
          title: 'Capability States',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: detail.capabilityStates
                .map(
                  (state) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1EA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.capabilityId,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.status} • ${(state.scoreAverage * 100).round()}% avg',
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        _Band(
          title: 'Review Queue',
          child: detail.reviewQueue.isEmpty
              ? const Text('No pending review items.')
              : Column(
                  children: detail.reviewQueue
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.capabilityId),
                          subtitle: Text(item.reason),
                          trailing: Text(item.dueDate),
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE4F3F1) : const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFE5DED1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    learner.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('Age ${learner.currentAge}'),
              ],
            ),
            const SizedBox(height: 6),
            Text(learner.currentLevel),
            const SizedBox(height: 12),
            if (learner.activePlan != null)
              Text(
                'Plan: ${learner.activePlan!.title}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            Text('Review queue: ${learner.reviewQueueCount}'),
            if (learner.todaySession != null) ...[
              const SizedBox(height: 6),
              Text('Next: ${learner.todaySession!.title}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.background = Colors.white});

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5DED1)),
      ),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
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
      width: 140,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E0D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
