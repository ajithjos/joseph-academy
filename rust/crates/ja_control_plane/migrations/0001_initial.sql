create table if not exists team (
    team_id text primary key,
    display_name text not null,
    description text not null
);

create table if not exists user_account (
    user_id text primary key,
    username text not null unique,
    display_name text not null
);

create table if not exists team_membership (
    team_id text not null references team(team_id) on delete cascade,
    user_id text not null references user_account(user_id) on delete cascade,
    role text not null,
    primary key (team_id, user_id)
);

create table if not exists learner (
    learner_id text primary key,
    team_id text not null references team(team_id) on delete cascade,
    user_id text not null references user_account(user_id) on delete cascade,
    display_name text not null,
    date_of_birth date not null,
    sex text not null,
    current_level text not null,
    notes text not null
);

create table if not exists plan_assignment (
    plan_assignment_id text primary key,
    learner_id text not null references learner(learner_id) on delete cascade,
    plan_template_id text not null,
    title text not null,
    start_date date not null,
    end_date date not null,
    status text not null,
    created_at timestamptz not null
);

create table if not exists learning_plan (
    learning_plan_id text primary key,
    plan_assignment_id text not null unique references plan_assignment(plan_assignment_id) on delete cascade,
    learner_id text not null references learner(learner_id) on delete cascade,
    plan_template_id text not null,
    title text not null,
    start_date date not null,
    end_date date not null,
    status text not null,
    total_sessions integer not null,
    completed_sessions integer not null,
    created_at timestamptz not null
);

create table if not exists learning_session (
    session_id text primary key,
    learning_plan_id text not null references learning_plan(learning_plan_id) on delete cascade,
    learner_id text not null references learner(learner_id) on delete cascade,
    title text not null,
    scheduled_date date not null,
    status text not null,
    day_offset integer not null,
    notes text not null default '',
    completed_at timestamptz null
);

create index if not exists learning_session_plan_idx on learning_session (learning_plan_id, scheduled_date);
create index if not exists learning_session_learner_idx on learning_session (learner_id, scheduled_date);

create table if not exists session_activity (
    activity_id text primary key,
    session_id text not null references learning_session(session_id) on delete cascade,
    title text not null,
    capability_id text not null,
    content_id text not null,
    status text not null
);

create table if not exists attempt (
    attempt_id text primary key,
    session_id text not null references learning_session(session_id) on delete cascade,
    learner_id text not null references learner(learner_id) on delete cascade,
    score double precision not null,
    max_score double precision not null,
    duration_minutes integer not null,
    notes text not null,
    recorded_at timestamptz not null
);

create index if not exists attempt_learner_idx on attempt (learner_id, recorded_at desc);
create index if not exists attempt_session_idx on attempt (session_id, recorded_at desc);

create table if not exists evidence_record (
    evidence_id text primary key,
    attempt_id text not null references attempt(attempt_id) on delete cascade,
    learner_id text not null references learner(learner_id) on delete cascade,
    kind text not null,
    storage_path text not null,
    summary text not null
);

create table if not exists learner_capability_state (
    learner_id text not null references learner(learner_id) on delete cascade,
    capability_id text not null,
    status text not null,
    score_average double precision not null,
    last_score double precision not null,
    total_attempts integer not null,
    last_attempted_at timestamptz null,
    primary key (learner_id, capability_id)
);

create table if not exists review_queue_item (
    review_queue_item_id text primary key,
    learner_id text not null references learner(learner_id) on delete cascade,
    capability_id text not null,
    reason text not null,
    due_date date not null,
    status text not null,
    created_at timestamptz not null
);

create index if not exists review_queue_learner_idx on review_queue_item (learner_id, due_date);
