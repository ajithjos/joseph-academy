create table if not exists team (
    team_id text primary key,
    display_name text not null,
    description text not null
);

create table if not exists user_account (
    user_id text primary key,
    username text not null unique,
    display_name text not null,
    date_of_birth date null,
    sex text null,
    current_level text null,
    notes text null
);

create table if not exists team_membership (
    team_id text not null references team(team_id) on delete cascade,
    user_id text not null references user_account(user_id) on delete cascade,
    role text not null,
    primary key (team_id, user_id)
);

create view learner_profile as
select
    ua.user_id as learner_id,
    tm.team_id,
    ua.user_id,
    ua.display_name,
    ua.date_of_birth,
    ua.sex,
    ua.current_level,
    coalesce(ua.notes, '') as notes
from user_account ua
join team_membership tm on tm.user_id = ua.user_id
where
    tm.role = 'learner'
    and ua.date_of_birth is not null
    and ua.sex is not null
    and ua.current_level is not null;

create table if not exists assignment (
    assignment_id text primary key,
    learner_id text not null references user_account(user_id) on delete cascade,
    playlist_id text not null,
    title text not null,
    start_date date not null,
    end_date date not null,
    status text not null,
    total_sessions integer not null,
    completed_sessions integer not null,
    created_at timestamptz not null
);

create table if not exists session (
    session_id text primary key,
    assignment_id text not null references assignment(assignment_id) on delete cascade,
    learner_id text not null references user_account(user_id) on delete cascade,
    title text not null,
    scheduled_date date not null,
    status text not null,
    day_offset integer not null,
    notes text not null default '',
    completed_at timestamptz null
);

create index if not exists session_assignment_idx on session (assignment_id, scheduled_date);
create index if not exists session_learner_idx on session (learner_id, scheduled_date);

create table if not exists session_material (
    session_material_id text primary key,
    session_id text not null references session(session_id) on delete cascade,
    title text not null,
    skill_id text not null,
    material_id text not null,
    status text not null
);

create table if not exists evidence (
    evidence_id text primary key,
    session_id text not null references session(session_id) on delete cascade,
    learner_id text not null references user_account(user_id) on delete cascade,
    score double precision not null,
    max_score double precision not null,
    duration_minutes integer not null,
    notes text not null,
    recorded_at timestamptz not null
);

create index if not exists evidence_learner_idx on evidence (learner_id, recorded_at desc);
create index if not exists evidence_session_idx on evidence (session_id, recorded_at desc);

create table if not exists evidence_artifact (
    evidence_artifact_id text primary key,
    evidence_id text not null references evidence(evidence_id) on delete cascade,
    learner_id text not null references user_account(user_id) on delete cascade,
    kind text not null,
    storage_path text not null,
    summary text not null
);

create table if not exists learner_skill_progress (
    learner_id text not null references user_account(user_id) on delete cascade,
    skill_id text not null,
    status text not null,
    score_average double precision not null,
    last_score double precision not null,
    total_evidence integer not null,
    last_evidence_at timestamptz null,
    primary key (learner_id, skill_id)
);

create table if not exists review_item (
    review_item_id text primary key,
    learner_id text not null references user_account(user_id) on delete cascade,
    skill_id text not null,
    reason text not null,
    due_date date not null,
    status text not null,
    created_at timestamptz not null
);

create index if not exists review_item_learner_idx on review_item (learner_id, due_date);

