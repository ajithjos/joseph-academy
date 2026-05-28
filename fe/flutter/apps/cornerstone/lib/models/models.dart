class DashboardPayload {
  DashboardPayload({required this.learners, this.team, this.library});

  factory DashboardPayload.fromJson(Map<String, dynamic> json) {
    return DashboardPayload(
      team: json['team'] == null
          ? null
          : TeamInfo.fromJson(json['team'] as Map<String, dynamic>),
      library: json['library'] == null
          ? null
          : LibraryReport.fromJson(json['library'] as Map<String, dynamic>),
      learners: (json['learners'] as List<dynamic>)
          .map((item) => LearnerDashboard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final TeamInfo? team;
  final LibraryReport? library;
  final List<LearnerDashboard> learners;
}

class ViewerSessionPayload {
  ViewerSessionPayload({
    required this.status,
    required this.availableUsers,
    this.team,
    this.currentUser,
    this.developerDocsUrl,
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
      developerDocsUrl: json['developer_docs_url'] as String?,
      availableUsers: (json['available_users'] as List<dynamic>)
          .map((item) => ViewerUser.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String status;
  final TeamInfo? team;
  final ViewerUser? currentUser;
  final String? developerDocsUrl;
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

class LibraryDocumentsPayload {
  LibraryDocumentsPayload({required this.status, required this.documents});

  factory LibraryDocumentsPayload.fromJson(Map<String, dynamic> json) {
    return LibraryDocumentsPayload(
      status: json['status'] as String,
      documents: (json['documents'] as List<dynamic>)
          .map(
            (item) => LibraryDocumentSummary.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String status;
  final List<LibraryDocumentSummary> documents;
}

class LibraryDocumentPayload {
  LibraryDocumentPayload({required this.status, required this.document});

  factory LibraryDocumentPayload.fromJson(Map<String, dynamic> json) {
    return LibraryDocumentPayload(
      status: json['status'] as String,
      document: LibraryDocumentData.fromJson(
        json['document'] as Map<String, dynamic>,
      ),
    );
  }

  final String status;
  final LibraryDocumentData document;
}

class LibraryDocumentSummary {
  LibraryDocumentSummary({
    required this.routePath,
    required this.sourcePath,
    required this.kind,
    required this.documentId,
    required this.title,
    required this.subjectId,
    required this.areaId,
    required this.pathwayId,
    required this.description,
  });

  factory LibraryDocumentSummary.fromJson(Map<String, dynamic> json) {
    return LibraryDocumentSummary(
      routePath: json['route_path'] as String,
      sourcePath: json['source_path'] as String,
      kind: json['kind'] as String,
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      pathwayId: json['pathway_id'] as String,
      description: json['description'] as String,
    );
  }

  final String routePath;
  final String sourcePath;
  final String kind;
  final String documentId;
  final String title;
  final String subjectId;
  final String areaId;
  final String pathwayId;
  final String description;
}

class LibraryDocumentData extends LibraryDocumentSummary {
  LibraryDocumentData({
    required super.routePath,
    required super.sourcePath,
    required super.kind,
    required super.documentId,
    required super.title,
    required super.subjectId,
    required super.areaId,
    required super.pathwayId,
    required super.description,
    required this.body,
  });

  factory LibraryDocumentData.fromJson(Map<String, dynamic> json) {
    return LibraryDocumentData(
      routePath: json['route_path'] as String,
      sourcePath: json['source_path'] as String,
      kind: json['kind'] as String,
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      subjectId: json['subject_id'] as String,
      areaId: json['area_id'] as String,
      pathwayId: json['pathway_id'] as String,
      description: json['description'] as String,
      body: json['body'] as String,
    );
  }

  final String body;
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
  factory ViewerUser.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    final canManageHousehold =
        json['can_manage_household'] as bool? ?? role != 'learner';
    return ViewerUser(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      role: role,
      currentLevel: json['current_level'] as String?,
      notes: json['notes'] as String? ?? '',
      learnerId: json['learner_id'] as String?,
      canManageHousehold: canManageHousehold,
      canReadLibrary:
          json['can_read_library'] as bool? ?? canManageHousehold,
      canViewAllLearners:
          json['can_view_all_learners'] as bool? ?? canManageHousehold,
      canOpenDeveloperDocs:
          json['can_open_developer_docs'] as bool? ?? role == 'owner',
    );
  }

  ViewerUser({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.notes,
    required this.canManageHousehold,
    required this.canReadLibrary,
    required this.canViewAllLearners,
    required this.canOpenDeveloperDocs,
    this.currentLevel,
    this.learnerId,
  });

  final String userId;
  final String username;
  final String displayName;
  final String role;
  final String notes;
  final String? currentLevel;
  final String? learnerId;
  final bool canManageHousehold;
  final bool canReadLibrary;
  final bool canViewAllLearners;
  final bool canOpenDeveloperDocs;

  bool get isLearner => role == 'learner';
  bool get isOwner => role == 'owner';
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
    required this.materialId,
    required this.kind,
    required this.estimatedMinutes,
    required this.skillIds,
    required this.status,
    this.runtime,
  });

  factory SessionMaterial.fromJson(Map<String, dynamic> json) {
    return SessionMaterial(
      sessionMaterialId: json['session_material_id'] as String,
      title: json['title'] as String,
      materialId: json['material_id'] as String,
      kind: json['kind'] as String,
      estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
      skillIds: (json['skill_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      status: json['status'] as String,
      runtime: json['runtime'] == null
          ? null
          : SessionMaterialRuntimeSummary.fromJson(
              json['runtime'] as Map<String, dynamic>,
            ),
    );
  }

  final String sessionMaterialId;
  final String title;
  final String materialId;
  final String kind;
  final int estimatedMinutes;
  final List<String> skillIds;
  final String status;
  final SessionMaterialRuntimeSummary? runtime;
}

class SessionMaterialRuntimeSummary {
  SessionMaterialRuntimeSummary({
    required this.engineId,
    required this.templateId,
    required this.executable,
  });

  factory SessionMaterialRuntimeSummary.fromJson(Map<String, dynamic> json) {
    return SessionMaterialRuntimeSummary(
      engineId: json['engine_id'] as String,
      templateId: json['template_id'] as String,
      executable: json['executable'] as bool? ?? true,
    );
  }

  final String engineId;
  final String templateId;
  final bool executable;
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
    required this.sessions,
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    final sessionPattern = json['session_pattern'] as Map<String, dynamic>?;
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
      sessions: ((sessionPattern?['sessions'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => PlaylistSessionInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
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
  final List<PlaylistSessionInfo> sessions;
}

class PlaylistSessionInfo {
  PlaylistSessionInfo({
    required this.dayOffset,
    required this.title,
    required this.skillIds,
    required this.materialIds,
  });

  factory PlaylistSessionInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistSessionInfo(
      dayOffset: (json['day_offset'] as num).toInt(),
      title: json['title'] as String,
      skillIds: (json['skill_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      materialIds: (json['material_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  final int dayOffset;
  final String title;
  final List<String> skillIds;
  final List<String> materialIds;
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
    this.runtime,
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
      runtime: json['runtime'] == null
          ? null
          : MaterialRuntimeInfo.fromJson(
              json['runtime'] as Map<String, dynamic>,
            ),
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
  final MaterialRuntimeInfo? runtime;
}

class MaterialRuntimeInfo {
  MaterialRuntimeInfo({
    required this.engineId,
    required this.specVersion,
    required this.templateId,
    required this.parameters,
    this.scoring,
    this.persistence,
  });

  factory MaterialRuntimeInfo.fromJson(Map<String, dynamic> json) {
    return MaterialRuntimeInfo(
      engineId: json['engine_id'] as String,
      specVersion: (json['spec_version'] as num).toInt(),
      templateId: json['template_id'] as String,
      parameters:
          (json['parameters'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      scoring: json['scoring'] == null
          ? null
          : MaterialRuntimeScoringInfo.fromJson(
              json['scoring'] as Map<String, dynamic>,
            ),
      persistence: json['persistence'] == null
          ? null
          : MaterialRuntimePersistenceInfo.fromJson(
              json['persistence'] as Map<String, dynamic>,
            ),
    );
  }

  final String engineId;
  final int specVersion;
  final String templateId;
  final Map<String, dynamic> parameters;
  final MaterialRuntimeScoringInfo? scoring;
  final MaterialRuntimePersistenceInfo? persistence;
}

class MaterialRuntimeScoringInfo {
  MaterialRuntimeScoringInfo({
    this.passAccuracy,
    this.softTimeLimitSeconds,
  });

  factory MaterialRuntimeScoringInfo.fromJson(Map<String, dynamic> json) {
    return MaterialRuntimeScoringInfo(
      passAccuracy: (json['pass_accuracy'] as num?)?.toDouble(),
      softTimeLimitSeconds: (json['soft_time_limit_seconds'] as num?)?.toInt(),
    );
  }

  final double? passAccuracy;
  final int? softTimeLimitSeconds;
}

class MaterialRuntimePersistenceInfo {
  MaterialRuntimePersistenceInfo({
    required this.storeResponseLog,
    required this.storeSummary,
  });

  factory MaterialRuntimePersistenceInfo.fromJson(Map<String, dynamic> json) {
    return MaterialRuntimePersistenceInfo(
      storeResponseLog: json['store_response_log'] as bool? ?? false,
      storeSummary: json['store_summary'] as bool? ?? true,
    );
  }

  final bool storeResponseLog;
  final bool storeSummary;
}

class ActivityStartPayload {
  ActivityStartPayload({required this.status, required this.activity});

  factory ActivityStartPayload.fromJson(Map<String, dynamic> json) {
    return ActivityStartPayload(
      status: json['status'] as String,
      activity: ActivityInstance.fromJson(json['activity'] as Map<String, dynamic>),
    );
  }

  final String status;
  final ActivityInstance activity;
}

class ActivityInstance {
  ActivityInstance({
    required this.activityInstanceId,
    required this.sessionId,
    required this.sessionMaterialId,
    required this.materialId,
    required this.materialTitle,
    required this.engineId,
    required this.templateId,
    required this.instructions,
    required this.estimatedMinutes,
    required this.scoring,
    required this.prompts,
  });

  factory ActivityInstance.fromJson(Map<String, dynamic> json) {
    return ActivityInstance(
      activityInstanceId: json['activity_instance_id'] as String,
      sessionId: json['session_id'] as String,
      sessionMaterialId: json['session_material_id'] as String,
      materialId: json['material_id'] as String,
      materialTitle: json['material_title'] as String,
      engineId: json['engine_id'] as String,
      templateId: json['template_id'] as String,
      instructions: json['instructions'] as String,
      estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
      scoring: ActivityScoringSummary.fromJson(
        json['scoring'] as Map<String, dynamic>,
      ),
      prompts: (json['prompts'] as List<dynamic>)
          .map((item) => ActivityPrompt.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String activityInstanceId;
  final String sessionId;
  final String sessionMaterialId;
  final String materialId;
  final String materialTitle;
  final String engineId;
  final String templateId;
  final String instructions;
  final int estimatedMinutes;
  final ActivityScoringSummary scoring;
  final List<ActivityPrompt> prompts;
}

class ActivityScoringSummary {
  ActivityScoringSummary({
    this.passAccuracy,
    this.softTimeLimitSeconds,
  });

  factory ActivityScoringSummary.fromJson(Map<String, dynamic> json) {
    return ActivityScoringSummary(
      passAccuracy: (json['pass_accuracy'] as num?)?.toDouble(),
      softTimeLimitSeconds: (json['soft_time_limit_seconds'] as num?)?.toInt(),
    );
  }

  final double? passAccuracy;
  final int? softTimeLimitSeconds;
}

class ActivityPrompt {
  ActivityPrompt({
    required this.promptId,
    required this.prompt,
    required this.answerKind,
  });

  factory ActivityPrompt.fromJson(Map<String, dynamic> json) {
    return ActivityPrompt(
      promptId: json['prompt_id'] as String,
      prompt: json['prompt'] as String,
      answerKind: json['answer_kind'] as String,
    );
  }

  final String promptId;
  final String prompt;
  final String answerKind;
}

class CompleteActivityResponse {
  CompleteActivityResponse({
    required this.status,
    required this.evidence,
    required this.updatedProgress,
    required this.activitySummary,
  });

  factory CompleteActivityResponse.fromJson(Map<String, dynamic> json) {
    return CompleteActivityResponse(
      status: json['status'] as String,
      evidence: EvidenceSummary.fromJson(json['evidence'] as Map<String, dynamic>),
      updatedProgress: (json['updated_progress'] as List<dynamic>)
          .map((item) => SkillProgressSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      activitySummary: ActivitySummary.fromJson(
        json['activity_summary'] as Map<String, dynamic>,
      ),
    );
  }

  final String status;
  final EvidenceSummary evidence;
  final List<SkillProgressSummary> updatedProgress;
  final ActivitySummary activitySummary;
}

class ActivitySummary {
  ActivitySummary({
    required this.attemptedCount,
    required this.correctCount,
    required this.promptCount,
    required this.accuracy,
    required this.passed,
    required this.completionReason,
    required this.weakGroups,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      attemptedCount: (json['attempted_count'] as num).toInt(),
      correctCount: (json['correct_count'] as num).toInt(),
      promptCount: (json['prompt_count'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
      passed: json['passed'] as bool,
      completionReason: json['completion_reason'] as String,
      weakGroups: (json['weak_groups'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }

  final int attemptedCount;
  final int correctCount;
  final int promptCount;
  final double accuracy;
  final bool passed;
  final String completionReason;
  final List<String> weakGroups;
}