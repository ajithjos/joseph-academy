class DashboardPayload {
  DashboardPayload({required this.catalog, required this.learners, this.team});

  factory DashboardPayload.fromJson(Map<String, dynamic> json) {
    return DashboardPayload(
      team: json['team'] == null
          ? null
          : TeamInfo.fromJson(json['team'] as Map<String, dynamic>),
      catalog: CatalogReport.fromJson(json['catalog'] as Map<String, dynamic>),
      learners: (json['learners'] as List<dynamic>)
          .map((item) => LearnerCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final TeamInfo? team;
  final CatalogReport catalog;
  final List<LearnerCard> learners;
}

class CatalogPayload {
  CatalogPayload({required this.report, required this.bundle});

  factory CatalogPayload.fromJson(Map<String, dynamic> json) {
    return CatalogPayload(
      report: CatalogReport.fromJson(json['report'] as Map<String, dynamic>),
      bundle: CatalogBundle.fromJson(json['bundle'] as Map<String, dynamic>),
    );
  }

  final CatalogReport report;
  final CatalogBundle bundle;
}

class CatalogBundle {
  CatalogBundle({
    required this.capabilities,
    required this.milestones,
    required this.planTemplates,
    required this.contentItems,
  });

  factory CatalogBundle.fromJson(Map<String, dynamic> json) {
    return CatalogBundle(
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((item) => CapabilityInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      milestones: (json['milestones'] as List<dynamic>)
          .map((item) => MilestoneInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      planTemplates: (json['plan_templates'] as List<dynamic>)
          .map(
            (item) => PlanTemplateInfo.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      contentItems: (json['content_items'] as List<dynamic>)
          .map((item) => ContentItemInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<CapabilityInfo> capabilities;
  final List<MilestoneInfo> milestones;
  final List<PlanTemplateInfo> planTemplates;
  final List<ContentItemInfo> contentItems;
}

class CatalogReport {
  CatalogReport({
    required this.subjectCount,
    required this.capabilityCount,
    required this.milestoneCount,
    required this.planTemplateCount,
    required this.contentItemCount,
    required this.loadedAtUtc,
  });

  factory CatalogReport.fromJson(Map<String, dynamic> json) {
    return CatalogReport(
      subjectCount: (json['subject_count'] as num).toInt(),
      capabilityCount: (json['capability_count'] as num).toInt(),
      milestoneCount: (json['milestone_count'] as num).toInt(),
      planTemplateCount: (json['plan_template_count'] as num).toInt(),
      contentItemCount: (json['content_item_count'] as num).toInt(),
      loadedAtUtc: json['loaded_at_utc'] as String,
    );
  }

  final int subjectCount;
  final int capabilityCount;
  final int milestoneCount;
  final int planTemplateCount;
  final int contentItemCount;
  final String loadedAtUtc;
}

class TeamInfo {
  TeamInfo({
    required this.teamId,
    required this.displayName,
    required this.description,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      teamId: json['team_id'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
    );
  }

  final String teamId;
  final String displayName;
  final String description;
}

class LearnerCard {
  LearnerCard({
    required this.learnerId,
    required this.displayName,
    required this.currentAge,
    required this.currentLevel,
    required this.notes,
    required this.reviewQueueCount,
    required this.capabilityStatusCounts,
    required this.milestoneProgress,
    this.activePlan,
    this.todaySession,
    this.latestAttempt,
  });

  factory LearnerCard.fromJson(Map<String, dynamic> json) {
    return LearnerCard(
      learnerId: json['learner_id'] as String,
      displayName: json['display_name'] as String,
      currentAge: (json['current_age'] as num).toInt(),
      currentLevel: json['current_level'] as String,
      notes: json['notes'] as String,
      reviewQueueCount: (json['review_queue_count'] as num).toInt(),
      capabilityStatusCounts:
          (json['capability_status_counts'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ),
      milestoneProgress: (json['milestone_progress'] as List<dynamic>)
          .map(
            (item) => MilestoneProgress.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      activePlan: json['active_plan'] == null
          ? null
          : PlanSummary.fromJson(json['active_plan'] as Map<String, dynamic>),
      todaySession: json['today_session'] == null
          ? null
          : SessionSummary.fromJson(
              json['today_session'] as Map<String, dynamic>,
            ),
      latestAttempt: json['latest_attempt'] == null
          ? null
          : AttemptSummary.fromJson(
              json['latest_attempt'] as Map<String, dynamic>,
            ),
    );
  }

  final String learnerId;
  final String displayName;
  final int currentAge;
  final String currentLevel;
  final String notes;
  final int reviewQueueCount;
  final Map<String, int> capabilityStatusCounts;
  final List<MilestoneProgress> milestoneProgress;
  final PlanSummary? activePlan;
  final SessionSummary? todaySession;
  final AttemptSummary? latestAttempt;
}

class LearnerDetailPayload {
  LearnerDetailPayload({
    required this.learner,
    required this.sessions,
    required this.capabilityStates,
    required this.reviewQueue,
    this.activePlan,
  });

  factory LearnerDetailPayload.fromJson(Map<String, dynamic> json) {
    return LearnerDetailPayload(
      learner: LearnerSummary.fromJson(json['learner'] as Map<String, dynamic>),
      activePlan: json['active_plan'] == null
          ? null
          : PlanSummary.fromJson(json['active_plan'] as Map<String, dynamic>),
      sessions: (json['sessions'] as List<dynamic>)
          .map((item) => SessionDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
      capabilityStates: (json['capability_states'] as List<dynamic>)
          .map(
            (item) =>
                CapabilityStateSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      reviewQueue: (json['review_queue'] as List<dynamic>)
          .map((item) => ReviewQueueItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final LearnerSummary learner;
  final PlanSummary? activePlan;
  final List<SessionDetail> sessions;
  final List<CapabilityStateSummary> capabilityStates;
  final List<ReviewQueueItem> reviewQueue;
}

class LearnerSummary {
  LearnerSummary({
    required this.learnerId,
    required this.displayName,
    required this.currentAge,
    required this.currentLevel,
    required this.notes,
  });

  factory LearnerSummary.fromJson(Map<String, dynamic> json) {
    return LearnerSummary(
      learnerId: json['learner_id'] as String,
      displayName: json['display_name'] as String,
      currentAge: (json['current_age'] as num).toInt(),
      currentLevel: json['current_level'] as String,
      notes: json['notes'] as String,
    );
  }

  final String learnerId;
  final String displayName;
  final int currentAge;
  final String currentLevel;
  final String notes;
}

class PlanSummary {
  PlanSummary({
    required this.learningPlanId,
    required this.planAssignmentId,
    required this.planTemplateId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalSessions,
    required this.completedSessions,
    required this.completionPercent,
  });

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    return PlanSummary(
      learningPlanId: json['learning_plan_id'] as String,
      planAssignmentId: json['plan_assignment_id'] as String,
      planTemplateId: json['plan_template_id'] as String,
      title: json['title'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
      totalSessions: (json['total_sessions'] as num).toInt(),
      completedSessions: (json['completed_sessions'] as num).toInt(),
      completionPercent: (json['completion_percent'] as num).toInt(),
    );
  }

  final String learningPlanId;
  final String planAssignmentId;
  final String planTemplateId;
  final String title;
  final String startDate;
  final String endDate;
  final String status;
  final int totalSessions;
  final int completedSessions;
  final int completionPercent;
}

class SessionSummary {
  SessionSummary({
    required this.sessionId,
    required this.title,
    required this.scheduledDate,
    required this.status,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['session_id'] as String,
      title: json['title'] as String,
      scheduledDate: json['scheduled_date'] as String,
      status: json['status'] as String,
    );
  }

  final String sessionId;
  final String title;
  final String scheduledDate;
  final String status;
}

class SessionDetail extends SessionSummary {
  SessionDetail({
    required super.sessionId,
    required super.title,
    required super.scheduledDate,
    required super.status,
    required this.notes,
    required this.activities,
    this.latestAttempt,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    return SessionDetail(
      sessionId: json['session_id'] as String,
      title: json['title'] as String,
      scheduledDate: json['scheduled_date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String,
      activities: (json['activities'] as List<dynamic>)
          .map((item) => SessionActivity.fromJson(item as Map<String, dynamic>))
          .toList(),
      latestAttempt: json['latest_attempt'] == null
          ? null
          : AttemptSummary.fromJson(
              json['latest_attempt'] as Map<String, dynamic>,
            ),
    );
  }

  final String notes;
  final List<SessionActivity> activities;
  final AttemptSummary? latestAttempt;
}

class SessionActivity {
  SessionActivity({
    required this.activityId,
    required this.title,
    required this.capabilityId,
    required this.contentId,
    required this.status,
  });

  factory SessionActivity.fromJson(Map<String, dynamic> json) {
    return SessionActivity(
      activityId: json['activity_id'] as String,
      title: json['title'] as String,
      capabilityId: json['capability_id'] as String,
      contentId: json['content_id'] as String,
      status: json['status'] as String,
    );
  }

  final String activityId;
  final String title;
  final String capabilityId;
  final String contentId;
  final String status;
}

class AttemptSummary {
  AttemptSummary({
    required this.attemptId,
    required this.score,
    required this.maxScore,
    required this.durationMinutes,
    required this.notes,
    required this.recordedAt,
  });

  factory AttemptSummary.fromJson(Map<String, dynamic> json) {
    return AttemptSummary(
      attemptId: json['attempt_id'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      notes: json['notes'] as String,
      recordedAt: json['recorded_at'] as String,
    );
  }

  final String attemptId;
  final double score;
  final double maxScore;
  final int durationMinutes;
  final String notes;
  final String recordedAt;
}

class CapabilityStateSummary {
  CapabilityStateSummary({
    required this.capabilityId,
    required this.status,
    required this.scoreAverage,
    required this.lastScore,
    required this.totalAttempts,
  });

  factory CapabilityStateSummary.fromJson(Map<String, dynamic> json) {
    return CapabilityStateSummary(
      capabilityId: json['capability_id'] as String,
      status: json['status'] as String,
      scoreAverage: (json['score_average'] as num).toDouble(),
      lastScore: (json['last_score'] as num).toDouble(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
    );
  }

  final String capabilityId;
  final String status;
  final double scoreAverage;
  final double lastScore;
  final int totalAttempts;
}

class ReviewQueueItem {
  ReviewQueueItem({
    required this.reviewQueueItemId,
    required this.capabilityId,
    required this.reason,
    required this.dueDate,
    required this.status,
  });

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) {
    return ReviewQueueItem(
      reviewQueueItemId: json['review_queue_item_id'] as String,
      capabilityId: json['capability_id'] as String,
      reason: json['reason'] as String,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
    );
  }

  final String reviewQueueItemId;
  final String capabilityId;
  final String reason;
  final String dueDate;
  final String status;
}

class MilestoneProgress {
  MilestoneProgress({
    required this.milestoneId,
    required this.title,
    required this.completedCapabilities,
    required this.totalCapabilities,
  });

  factory MilestoneProgress.fromJson(Map<String, dynamic> json) {
    return MilestoneProgress(
      milestoneId: json['milestone_id'] as String,
      title: json['title'] as String,
      completedCapabilities: (json['completed_capabilities'] as num).toInt(),
      totalCapabilities: (json['total_capabilities'] as num).toInt(),
    );
  }

  final String milestoneId;
  final String title;
  final int completedCapabilities;
  final int totalCapabilities;
}

class CapabilityInfo {
  CapabilityInfo({
    required this.capabilityId,
    required this.title,
    required this.subject,
    required this.description,
  });

  factory CapabilityInfo.fromJson(Map<String, dynamic> json) {
    return CapabilityInfo(
      capabilityId: json['capability_id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
    );
  }

  final String capabilityId;
  final String title;
  final String subject;
  final String description;
}

class MilestoneInfo {
  MilestoneInfo({
    required this.milestoneId,
    required this.title,
    required this.capabilityIds,
  });

  factory MilestoneInfo.fromJson(Map<String, dynamic> json) {
    return MilestoneInfo(
      milestoneId: json['milestone_id'] as String,
      title: json['title'] as String,
      capabilityIds: (json['capability_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  final String milestoneId;
  final String title;
  final List<String> capabilityIds;
}

class PlanTemplateInfo {
  PlanTemplateInfo({
    required this.planTemplateId,
    required this.title,
    required this.recommendedAge,
    required this.recommendedLevel,
    required this.durationDays,
    required this.capabilityIds,
  });

  factory PlanTemplateInfo.fromJson(Map<String, dynamic> json) {
    return PlanTemplateInfo(
      planTemplateId: json['plan_template_id'] as String,
      title: json['title'] as String,
      recommendedAge: (json['recommended_age'] as num).toInt(),
      recommendedLevel: json['recommended_level'] as String,
      durationDays: (json['duration_days'] as num).toInt(),
      capabilityIds: (json['capability_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  final String planTemplateId;
  final String title;
  final int recommendedAge;
  final String recommendedLevel;
  final int durationDays;
  final List<String> capabilityIds;
}

class ContentItemInfo {
  ContentItemInfo({
    required this.id,
    required this.title,
    required this.kind,
    required this.subject,
  });

  factory ContentItemInfo.fromJson(Map<String, dynamic> json) {
    return ContentItemInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: json['type'] as String,
      subject: json['subject'] as String,
    );
  }

  final String id;
  final String title;
  final String kind;
  final String subject;
}
