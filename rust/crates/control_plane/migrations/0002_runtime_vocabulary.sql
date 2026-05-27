do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'learning_plan'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'assignment'
    ) then
        alter table learning_plan rename to assignment;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'assignment' and column_name = 'learning_plan_id'
    ) then
        alter table assignment rename column learning_plan_id to assignment_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'assignment' and column_name = 'plan_template_id'
    ) then
        alter table assignment rename column plan_template_id to playlist_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'assignment' and column_name = 'plan_assignment_id'
    ) then
        alter table assignment drop constraint if exists learning_plan_plan_assignment_id_fkey;
        alter table assignment drop constraint if exists assignment_plan_assignment_id_fkey;
        alter table assignment drop constraint if exists learning_plan_plan_assignment_id_key;
        alter table assignment drop constraint if exists assignment_plan_assignment_id_key;
        alter table assignment drop column plan_assignment_id;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'plan_assignment'
    ) then
        drop table plan_assignment;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'learning_session'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'session'
    ) then
        alter table learning_session rename to session;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'session' and column_name = 'learning_plan_id'
    ) then
        alter table session rename column learning_plan_id to assignment_id;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'session_activity'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'session_material'
    ) then
        alter table session_activity rename to session_material;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'session_material' and column_name = 'activity_id'
    ) then
        alter table session_material rename column activity_id to session_material_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'session_material' and column_name = 'capability_id'
    ) then
        alter table session_material rename column capability_id to skill_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'session_material' and column_name = 'content_id'
    ) then
        alter table session_material rename column content_id to material_id;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'attempt'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'evidence'
    ) then
        alter table attempt rename to evidence;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'evidence' and column_name = 'attempt_id'
    ) then
        alter table evidence rename column attempt_id to evidence_id;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'evidence_record'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'evidence_artifact'
    ) then
        alter table evidence_record rename to evidence_artifact;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'evidence_artifact' and column_name = 'attempt_id'
    ) then
        alter table evidence_artifact rename column attempt_id to evidence_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'evidence_artifact' and column_name = 'evidence_id'
    ) and not exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'evidence_artifact' and column_name = 'evidence_artifact_id'
    ) then
        alter table evidence_artifact rename column evidence_id to evidence_artifact_id;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'learner_capability_state'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'learner_skill_progress'
    ) then
        alter table learner_capability_state rename to learner_skill_progress;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'learner_skill_progress' and column_name = 'capability_id'
    ) then
        alter table learner_skill_progress rename column capability_id to skill_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'learner_skill_progress' and column_name = 'total_attempts'
    ) then
        alter table learner_skill_progress rename column total_attempts to total_evidence;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'learner_skill_progress' and column_name = 'last_attempted_at'
    ) then
        alter table learner_skill_progress rename column last_attempted_at to last_evidence_at;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'review_queue_item'
    ) and not exists (
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = 'review_item'
    ) then
        alter table review_queue_item rename to review_item;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'review_item' and column_name = 'review_queue_item_id'
    ) then
        alter table review_item rename column review_queue_item_id to review_item_id;
    end if;

    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public' and table_name = 'review_item' and column_name = 'capability_id'
    ) then
        alter table review_item rename column capability_id to skill_id;
    end if;
end $$;

alter index if exists learning_session_plan_idx rename to session_assignment_idx;
alter index if exists learning_session_learner_idx rename to session_learner_idx;
alter index if exists attempt_learner_idx rename to evidence_learner_idx;
alter index if exists attempt_session_idx rename to evidence_session_idx;
alter index if exists review_queue_learner_idx rename to review_item_learner_idx;

create index if not exists session_assignment_idx on session (assignment_id, scheduled_date);
create index if not exists session_learner_idx on session (learner_id, scheduled_date);
create index if not exists evidence_learner_idx on evidence (learner_id, recorded_at desc);
create index if not exists evidence_session_idx on evidence (session_id, recorded_at desc);
create index if not exists review_item_learner_idx on review_item (learner_id, due_date);
