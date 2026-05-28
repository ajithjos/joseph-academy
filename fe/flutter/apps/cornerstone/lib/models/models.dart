class DashboardPayload {
  DashboardPayload({required this.library, required this.learners, this.team});

  factory DashboardPayload.fromJson(Map<String, dynamic> json) {
    return DashboardPayload(
      team: json['team'] == null
          ? null
          : TeamInfo.fromJson(json['team'] as Map<String, dynamic>),
      library: LibraryReport.fromJson(json['library'] as Map<String, dynamic>),
      learners: (json['learners'] as List<dynamic>)
          .map((item) => LearnerDashboard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final TeamInfo? team;
  final LibraryReport library;
  final List<LearnerDashboard> learners;
}

class ViewerSessionPayload {
  ViewerSessionPayload({
    required this.status,
    required this.availableUsers,
    this.team,
    this.currentUser,
  });

  factory ViewerSessionPayload.fromJson(Map<String, dynamic> json) {
    return ViewerSessionPayload(
      status: json['status'] as String,
      team: json['team'] == null
          ? null
          : TeamInfo.fromJson(json['team'] as Map<String, dynamic>),
      currentUser: json['current_user'] == null
          ? null
          : ViewerUser.fromJson(
              json['current_user'] as Map<String, dynamic>,
            ),
      availableUsers: (json['available_users'] as List<dynamic>)
          .map((item) => ViewerUser.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String status;
  final TeamInfo? team;
  final ViewerUser? currentUser;
  final List<ViewerUser> availableUsers;
}

class LibraryPayload {
  LibraryPayload({required this.report, required this.bundle});

  factory LibraryPayload.fromJson(Map<String, dynamic> json) {
    return LibraryPayload(
      report: LibraryReport.fromJson(json['report'] as Map<String, dynamic>),
      bundle: LibraryBundle.fromJson(json['bundle'] as Map<String, dynamic>),
    );
  }

  final LibraryReport report;
  final LibraryBundle bundle;
}

class LibraryBundle {
  LibraryBundle({
    required this.subjects,
    required this.areas,
    required this.pathways,
    required this.skills,
    required this.stages,
    required this.playlists,
    required this.materials,
  });

  factory LibraryBundle.fromJson(Map<String, dynamic> json) {
    return LibraryBundle(
      subjects: (json['subjects'] as List<dynamic>)
          .map((item) => SubjectInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      areas: (json['areas'] as List<dynamic>)
          .map((item) => AreaInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      pathways: ((json['pathways'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => PathwayInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>)
          .map((item) => SkillInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      stages: (json['stages'] as List<dynamic>)
          .map((item) => StageInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      playlists: (json['playlists'] as List<dynamic>)
          .map((item) => PlaylistInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List<dynamic>)
          .map((item) => MaterialInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<SubjectInfo> subjects;
  final List<AreaInfo> areas;
  final List<PathwayInfo> pathways;
  final List<SkillInfo> skills;
  final List<StageInfo> stages;
  final List<PlaylistInfo> playlists;
  final List<MaterialInfo> materials;
}

class LibraryReport {
  LibraryReport({
    required this.subjectCount,
    required this.areaCount,
    required this.pathwayCount,
    required this.skillCount,
    required this.stageCount,
    required this.playlistCount,
    required this.materialCount,
    required this.loadedAtUtc,
  });

  factory LibraryReport.fromJson(Map<String, dynamic> json) {
    return LibraryReport(
      subjectCount: (json['subject_count'] as num).toInt(),
      areaCount: (json['area_count'] as num).toInt(),
      pathwayCount: (json['pathway_count'] as num?)?.toInt() ?? 0,
      skillCount: (json['skill_count'] as num).toInt(),
      stageCount: (json['stage_count'] as num).toInt(),
      playlistCount: (json['playlist_count'] as num).toInt(),
      materialCount: (json['material_count'] as num).toInt(),
      loadedAtUtc: json['loaded_at_utc'] as String,
    );
  }

  final int subjectCount;
  final int areaCount;
  final int pathwayCount;
  final int skillCount;
  final int stageCount;
  final int playlistCount;
  final int materialCount;
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

class ViewerUser {
  ViewerUser({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.notes,
    this.currentLevel,
    this.learnerId,
  });

  factory ViewerUser.fromJson(Map<String, dynamic> json) {
    return ViewerUser(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      currentLevel: json['current_level'] as String?,
      notes: json['notes'] as String? ?? '',
      learnerId: json['learner_id'] as String?,
    );
  }

  final String userId;
  final String username;
  final String displayName;
  final String role;
  final String notes;
  final String? currentLevel;
  final String? learnerId;

  bool get isLearner => role == 'learner';
  bool get canManageHousehold => !isLearner;
}

class LearnerDashboard {
  LearnerDashboard({
    required this.learnerId,
    required this.displayName,
    required this.currentAge,
    required this.currentLevel,
    required this.notes,
    required this.reviewItemCount,
    required this.progressStatusCounts,
    required this.stageProgress,
    this.activeAssignment,
    this.todaySession,
    this.latestEvidence,
  });

  factory LearnerDashboard.fromJson(Map<String, dynamic> json) {
    return LearnerDashboard(
      learnerId: json['learner_id'] as String,
      displayName: json['display_name'] as String,
      currentAge: (json['current_age'] as num).toInt(),
      currentLevel: json['current_level'] as String,
      notes: json['notes'] as String,
      reviewItemCount: (json['review_item_count'] as num).toInt(),
      progressStatusCounts:
          (json['progress_status_counts'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ),
      stageProgress: (json['stage_progress'] as List<dynamic>)
          .map((item) => StageProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
      activeAssignment: json['active_assignment'] == null
          ? null
          : AssignmentSummary.fromJson(
              json['active_assignment'] as Map<String, dynamic>,
            ),
      todaySession: json['today_session'] == null
          ? null
          : SessionSummary.fromJson(
              json['today_session'] as Map<String, dynamic>,
            ),
      latestEvidence: json['latest_evidence'] == null
          ? null
          : EvidenceSummary.fromJson(
              json['latest_evidence'] as Map<String, dynamic>,
            ),
    );
  }

  final String learnerId;
  final String displayName;
  final int currentAge;
  final String currentLevel;
  final String notes;
  final int reviewItemCount;
  final Map<String, int> progressStatusCounts;
  final List<StageProgress> stageProgress;
  final AssignmentSummary? activeAssignment;
  final SessionSummary? todaySession;
  final EvidenceSummary? latestEvidence;
}

class LearnerDetailPayload {
  LearnerDetailPayload({
    required this.learner,
    required this.sessions,
    required this.progress,
    required this.reviewItems,
    this.activeAssignment,
  });

  factory LearnerDetailPayload.fromJson(Map<String, dynamic> json) {
    return LearnerDetailPayload(
      learner: LearnerSummary.fromJson(json['learner'] as Map<String, dynamic>),
      activeAssignment: json['active_assignment'] == null
          ? null
          : AssignmentSummary.fromJson(
              json['active_assignment'] as Map<String, dynamic>,
            ),
      sessions: (json['sessions'] as List<dynamic>)
          .map((item) => SessionDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
      progress: (json['progress'] as List<dynamic>)
          .map(
            (item) => SkillProgressSummary.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      reviewItems: (json['review_items'] as List<dynamic>)
          .map((item) => ReviewItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final LearnerSummary learner;
  final AssignmentSummary? activeAssignment;
  final List<SessionDetail> sessions;
  final List<SkillProgressSummary> progress;
  final List<ReviewItem> reviewItems;
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

class AssignmentSummary {
  AssignmentSummary({
    required this.assignmentId,
    required this.playlistId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalSessions,
    required this.completedSessions,
    required this.completionPercent,
  });

  factory AssignmentSummary.fromJson(Map<String, dynamic> json) {
    return AssignmentSummary(
      assignmentId: json['assignment_id'] as String,
      playlistId: json['playlist_id'] as String,
      title: json['title'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
      totalSessions: (json['total_sessions'] as num).toInt(),
      completedSessions: (json['completed_sessions'] as num).toInt(),
      completionPercent: (json['completion_percent'] as num).toInt(),
    );
  }

  final String assignmentId;
  final String playlistId;
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
    required this.materials,
    this.latestEvidence,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    return SessionDetail(
      sessionId: json['session_id'] as String,
      title: json['title'] as String,
      scheduledDate: json['scheduled_date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String,
      materials: (json['materials'] as List<dynamic>)
          .map((item) => SessionMaterial.fromJson(item as Map<String, dynamic>))
          .toList(),
      latestEvidence: json['latest_evidence'] == null
          ? null
          : EvidenceSummary.fromJson(
              json['latest_evidence'] as Map<String, dynamic>,
            ),
    );
  }

  final String notes;
  final List<SessionMaterial> materials;
  final EvidenceSummary? latestEvidence;
}

class SessionMaterial {
  SessionMaterial({
    required this.sessionMaterialId,
    required this.title,
    required this.skillId,
    required this.materialId,
    required this.status,
  });

  factory SessionMaterial.fromJson(Map<String, dynamic> json) {
    return SessionMaterial(
      sessionMaterialId: json['session_material_id'] as String,
      title: json['title'] as String,
      skillId: json['skill_id'] as String,
      materialId: json['material_id'] as String,
      status: json['status'] as String,
    );
  }

  final String sessionMaterialId;
  final String title;
  final String skillId;
  final String materialId;
  final String status;
}

class EvidenceSummary {
  EvidenceSummary({
    required this.evidenceId,
    required this.score,
    required this.maxScore,
    required this.durationMinutes,
    required this.notes,
    required this.recordedAt,
  });

  factory EvidenceSummary.fromJson(Map<String, dynamic> json) {
    return EvidenceSummary(
      evidenceId: json['evidence_id'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      notes: json['notes'] as String,
      recordedAt: json['recorded_at'] as String,
    );
  }

  final String evidenceId;
  final double score;
  final double maxScore;
  final int durationMinutes;
  final String notes;
  final String recordedAt;
}

class SkillProgressSummary {
  SkillProgressSummary({
    required this.skillId,
    required this.status,
    required this.scoreAverage,
    required this.lastScore,
    required this.totalEvidence,
    this.lastEvidenceAt,
  });

  factory SkillProgressSummary.fromJson(Map<String, dynamic> json) {
    return SkillProgressSummary(
      skillId: json['skill_id'] as String,
      status: json['status'] as String,
      scoreAverage: (json['score_average'] as num).toDouble(),
      lastScore: (json['last_score'] as num).toDouble(),
      totalEvidence: (json['total_evidence'] as num).toInt(),
      lastEvidenceAt: json['last_evidence_at'] as String?,
    );
  }

  final String skillId;
  final String status;
  final double scoreAverage;
  final double lastScore;
  final int totalEvidence;
  final String? lastEvidenceAt;
}

class ReviewItem {
  ReviewItem({
    required this.reviewItemId,
    required this.skillId,
    required this.reason,
    required this.dueDate,
    required this.status,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      reviewItemId: json['review_item_id'] as String,
      skillId: json['skill_id'] as String,
      reason: json['reason'] as String,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
    );
  }

  final String reviewItemId;
  final String skillId;
  final String reason;
  final String dueDate;
  final String status;
}

class StageProgress {
  StageProgress({
    required this.stageId,
    required this.title,
    required this.completedSkills,
    required this.totalSkills,
  });

  factory StageProgress.fromJson(Map<String, dynamic> json) {
    return StageProgress(
      stageId: json['stage_id'] as String,
      title: json['title'] as String,
      completedSkills: (json['completed_skills'] as num).toInt(),
      totalSkills: (json['total_skills'] as num).toInt(),
    );
  }

  final String stageId;
  final String title;
  final int completedSkills;
  final int totalSkills;
}

class SubjectInfo {
  SubjectInfo({
    required this.subjectId,
    required this.title,
    required this.description,
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    return SubjectInfo(
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  final String subjectId;
  final String title;
  final String description;
}

class AreaInfo {
  AreaInfo({
    required this.areaId,
    required this.subjectId,
    required this.title,
    required this.description,
  });

  factory AreaInfo.fromJson(Map<String, dynamic> json) {
    return AreaInfo(
      areaId: json['area_id'] as String,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  final String areaId;
  final String subjectId;
  final String title;
  final String description;
}

class PathwayInfo {
  PathwayInfo({
    required this.pathwayId,
    required this.title,
    required this.subjectId,
    required this.areaId,
    required this.recommendedAgeMin,
    required this.recommendedAgeMax,
    required this.stageIds,
    required this.playlistIds,
    required this.entryPoints,
    required this.description,
    required this.sourcePath,
  });

  factory PathwayInfo.fromJson(Map<String, dynamic> json) {
    return PathwayInfo(
      pathwayId: json['pathway_id'] as String,
      title: json['title'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      recommendedAgeMin: (json['recommended_age_min'] as num).toInt(),
      recommendedAgeMax: (json['recommended_age_max'] as num).toInt(),
      stageIds: (json['stage_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      playlistIds: (json['playlist_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      entryPoints: (json['entry_points'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      description: json['description'] as String,
      sourcePath: json['source_path'] as String,
    );
  }

  final String pathwayId;
  final String title;
  final String subjectId;
  final String areaId;
  final int recommendedAgeMin;
  final int recommendedAgeMax;
  final List<String> stageIds;
  final List<String> playlistIds;
  final Map<String, String> entryPoints;
  final String description;
  final String sourcePath;
}

class SkillInfo {
  SkillInfo({
    required this.skillId,
    required this.subjectId,
    required this.areaId,
    required this.title,
    required this.recommendedAge,
    required this.recommendedLevel,
    required this.description,
    required this.successCriteria,
  });

  factory SkillInfo.fromJson(Map<String, dynamic> json) {
    return SkillInfo(
      skillId: json['skill_id'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      title: json['title'] as String,
      recommendedAge: (json['recommended_age'] as num).toInt(),
      recommendedLevel: json['recommended_level'] as String,
      description: json['description'] as String,
      successCriteria: json['success_criteria'] as String,
    );
  }

  final String skillId;
  final String subjectId;
  final String areaId;
  final String title;
  final int recommendedAge;
  final String recommendedLevel;
  final String description;
  final String successCriteria;
}

class StageInfo {
  StageInfo({
    required this.stageId,
    required this.subjectId,
    required this.areaId,
    required this.title,
    required this.recommendedAge,
    required this.recommendedLevel,
    required this.description,
    required this.skillIds,
  });

  factory StageInfo.fromJson(Map<String, dynamic> json) {
    return StageInfo(
      stageId: json['stage_id'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      title: json['title'] as String,
      recommendedAge: (json['recommended_age'] as num).toInt(),
      recommendedLevel: json['recommended_level'] as String,
      description: json['description'] as String,
      skillIds: (json['skill_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  final String stageId;
  final String subjectId;
  final String areaId;
  final String title;
  final int recommendedAge;
  final String recommendedLevel;
  final String description;
  final List<String> skillIds;
}

class PlaylistInfo {
  PlaylistInfo({
    required this.playlistId,
    required this.title,
    required this.subjectId,
    required this.areaId,
    required this.recommendedAge,
    required this.recommendedLevel,
    required this.stageIds,
    required this.skillIds,
    required this.durationDays,
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistInfo(
      playlistId: json['playlist_id'] as String,
      title: json['title'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      recommendedAge: (json['recommended_age'] as num).toInt(),
      recommendedLevel: json['recommended_level'] as String,
      stageIds: (json['stage_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      skillIds: (json['skill_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      durationDays: (json['duration_days'] as num).toInt(),
    );
  }

  final String playlistId;
  final String title;
  final String subjectId;
  final String areaId;
  final int recommendedAge;
  final String recommendedLevel;
  final List<String> stageIds;
  final List<String> skillIds;
  final int durationDays;
}

class MaterialInfo {
  MaterialInfo({
    required this.id,
    required this.title,
    required this.kind,
    required this.subjectId,
    required this.areaId,
    required this.skillIds,
    required this.stageIds,
    required this.recommendedAge,
    required this.difficulty,
    required this.estimatedMinutes,
  });

  factory MaterialInfo.fromJson(Map<String, dynamic> json) {
    return MaterialInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: json['type'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      skillIds: (json['skill_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      stageIds: (json['stage_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      recommendedAge: (json['recommended_age'] as num).toInt(),
      difficulty: json['difficulty'] as String,
      estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
    );
  }

  final String id;
  final String title;
  final String kind;
  final String subjectId;
  final String areaId;
  final List<String> skillIds;
  final List<String> stageIds;
  final int recommendedAge;
  final String difficulty;
  final int estimatedMinutes;
}