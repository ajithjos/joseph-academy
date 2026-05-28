import React, { useEffect, useState } from 'react';

import styles from './index.module.css';

const viewerStorageKey = 'cornerstone.viewer.username';

function roleLabel(user) {
  if (!user) {
    return 'Signed out';
  }
  return user.role === 'learner' ? 'Student' : 'Parent / Teacher';
}

function normalizeError(error) {
  const message = error instanceof Error ? error.message : 'Request failed';
  if (message === 'Failed to fetch') {
    return 'Unable to reach the integrated session API. Use the shared frontend host to try the content-site login controls.';
  }
  return message;
}

async function request(endpoint, options = {}) {
  const response = await fetch(endpoint, {
    credentials: 'same-origin',
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers ?? {}),
    },
    ...options,
  });

  const contentType = response.headers.get('content-type') ?? '';
  const payload = contentType.includes('application/json')
    ? await response.json()
    : null;

  if (!response.ok) {
    throw new Error(payload?.message ?? 'Request failed');
  }

  return payload;
}

function progressSummary(learner) {
  const counts = Object.entries(learner.progress_status_counts ?? {});
  if (counts.length === 0) {
    return 'No progress has been recorded yet.';
  }
  return counts
    .map(([status, count]) => `${count} ${status.replaceAll('_', ' ')}`)
    .join(' · ');
}

function pendingSessions(detail) {
  return detail?.sessions?.filter((session) => session.status !== 'completed') ?? [];
}

function completedSessions(detail) {
  return detail?.sessions?.filter((session) => session.status === 'completed') ?? [];
}

function humanizeLabel(value) {
  return value
    .split(/[_\-\s]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function progressBuckets(detail) {
  const counts = new Map();
  (detail?.progress ?? []).forEach((state) => {
    counts.set(state.status, (counts.get(state.status) ?? 0) + 1);
  });
  return Array.from(counts.entries());
}

function loadStoredUsername() {
  if (typeof window === 'undefined') {
    return '';
  }
  return window.localStorage.getItem(viewerStorageKey) ?? '';
}

function persistStoredUsername(username) {
  if (typeof window === 'undefined') {
    return;
  }
  window.localStorage.setItem(viewerStorageKey, username);
}

function clearStoredUsername() {
  if (typeof window === 'undefined') {
    return;
  }
  window.localStorage.removeItem(viewerStorageKey);
}

function sessionEndpoint(username = '') {
  const trimmedUsername = username.trim();
  if (!trimmedUsername) {
    return '/api/v1/session';
  }
  return `/api/v1/session?username=${encodeURIComponent(trimmedUsername)}`;
}

export default function ContentHome() {
  const [session, setSession] = useState(null);
  const [dashboard, setDashboard] = useState(null);
  const [learnerDetail, setLearnerDetail] = useState(null);
  const [username, setUsername] = useState('');
  const [loading, setLoading] = useState(true);
  const [authBusy, setAuthBusy] = useState(false);
  const [dataBusy, setDataBusy] = useState(false);
  const [error, setError] = useState('');

  const viewer = session?.current_user ?? null;
  const visibleLearners =
    viewer?.role === 'learner' && viewer?.learner_id
      ? (dashboard?.learners ?? []).filter(
          (learner) => learner.learner_id === viewer.learner_id,
        )
      : dashboard?.learners ?? [];
  const pending = pendingSessions(learnerDetail);
  const completed = completedSessions(learnerDetail);
  const nextSession = pending[0] ?? null;
  const progressCounts = progressBuckets(learnerDetail);

  function applySession(nextSessionState, fallbackUsername = '') {
    setSession(nextSessionState);
    setUsername(
      nextSessionState?.current_user?.username ??
        fallbackUsername,
    );
  }

  async function refreshAll({ fullScreen = false, preferredUsername } = {}) {
    if (fullScreen) {
      setLoading(true);
    }
    setDataBusy(true);
    setError('');

    try {
      const restoredUsername = (preferredUsername ?? loadStoredUsername()).trim();
      const nextSessionState = await request(sessionEndpoint(restoredUsername));
      applySession(
        nextSessionState,
        nextSessionState.current_user ? '' : restoredUsername,
      );

      if (!nextSessionState.current_user && restoredUsername) {
        clearStoredUsername();
      }

      if (!nextSessionState.current_user) {
        setDashboard(null);
        setLearnerDetail(null);
        return;
      }

      const nextDashboard = await request('/api/v1/dashboard');
      setDashboard(nextDashboard);

      if (
        nextSessionState.current_user.role === 'learner' &&
        nextSessionState.current_user.learner_id
      ) {
        const nextLearnerDetail = await request(
          `/api/v1/learners/${nextSessionState.current_user.learner_id}`,
        );
        setLearnerDetail(nextLearnerDetail);
      } else {
        setLearnerDetail(null);
      }
    } catch (requestError) {
      setDashboard(null);
      setLearnerDetail(null);
      setError(normalizeError(requestError));
      setSession((current) => current ?? {
        status: 'error',
        team: null,
        current_user: null,
        available_users: [],
      });
    } finally {
      setLoading(false);
      setDataBusy(false);
      setAuthBusy(false);
    }
  }

  useEffect(() => {
    let cancelled = false;

    async function initialize() {
      setLoading(true);
      setDataBusy(true);
      setError('');
      try {
        const restoredUsername = loadStoredUsername().trim();
        const nextSessionState = await request(
          sessionEndpoint(restoredUsername),
        );
        if (cancelled) return;
        applySession(
          nextSessionState,
          nextSessionState.current_user ? '' : restoredUsername,
        );

        if (!nextSessionState.current_user && restoredUsername) {
          clearStoredUsername();
        }

        if (!nextSessionState.current_user) {
          setDashboard(null);
          setLearnerDetail(null);
          return;
        }

        const nextDashboard = await request('/api/v1/dashboard');
        if (cancelled) return;
        setDashboard(nextDashboard);

        if (
          nextSessionState.current_user.role === 'learner' &&
          nextSessionState.current_user.learner_id
        ) {
          const nextLearnerDetail = await request(
            `/api/v1/learners/${nextSessionState.current_user.learner_id}`,
          );
          if (cancelled) return;
          setLearnerDetail(nextLearnerDetail);
        } else {
          setLearnerDetail(null);
        }
      } catch (requestError) {
        if (cancelled) return;
        setDashboard(null);
        setLearnerDetail(null);
        setError(normalizeError(requestError));
        setSession({
          status: 'error',
          team: null,
          current_user: null,
          available_users: [],
        });
      } finally {
        if (cancelled) return;
        setLoading(false);
        setDataBusy(false);
      }
    }

    void initialize();
    return () => {
      cancelled = true;
    };
  }, []);

  async function handleLogin(nextUsername = username) {
    const requestedUsername = nextUsername.trim();
    if (!requestedUsername) {
      setError('Enter a username to continue.');
      return;
    }

    setAuthBusy(true);
    setError('');
    try {
      const nextSessionState = await request('/api/v1/session', {
        method: 'POST',
        body: JSON.stringify({ username: requestedUsername }),
      });
      if (nextSessionState.current_user?.username) {
        persistStoredUsername(nextSessionState.current_user.username);
      }
      applySession(nextSessionState);

      const nextDashboard = await request('/api/v1/dashboard');
      setDashboard(nextDashboard);

      if (
        nextSessionState.current_user?.role === 'learner' &&
        nextSessionState.current_user?.learner_id
      ) {
        const nextLearnerDetail = await request(
          `/api/v1/learners/${nextSessionState.current_user.learner_id}`,
        );
        setLearnerDetail(nextLearnerDetail);
      } else {
        setLearnerDetail(null);
      }
    } catch (requestError) {
      setError(normalizeError(requestError));
    } finally {
      setLoading(false);
      setDataBusy(false);
      setAuthBusy(false);
    }
  }

  async function handleLogout() {
    setAuthBusy(true);
    setError('');
    try {
      clearStoredUsername();
      setUsername('');
      await refreshAll();
    } catch (requestError) {
      setError(normalizeError(requestError));
      setAuthBusy(false);
    }
  }

  if (loading) {
    return (
      <div className={styles.shell}>
        <div className={styles.loadingPanel}>Loading the content workspace…</div>
      </div>
    );
  }

  return (
    <div className={styles.shell}>
      <section className={styles.hero}>
        <div className={styles.heroCopy}>
          <p className={styles.eyebrow}>Cornerstone Content</p>
          <h1 className={styles.title}>
            {viewer
              ? `${viewer.display_name} content workspace`
              : session?.team?.display_name ?? 'Household content workspace'}
          </h1>
          <p className={styles.lede}>
            {viewer
              ? viewer.role === 'learner'
                ? 'See what is pending, what is completed, and which learning materials sit closest to the current assignment.'
                : 'Keep the learning picture in view without all the technical noise.'
              : 'Choose a username to open the parent / teacher content hub or the student-facing progress view. This login is intentionally username-only for now.'}
          </p>
          <div className={styles.actions}>
            {viewer ? (
              <button
                className={styles.primaryButton}
                disabled={authBusy}
                onClick={() => {
                  void handleLogout();
                }}
                type="button"
              >
                {authBusy ? 'Signing out…' : 'Log out'}
              </button>
            ) : null}
          </div>
        </div>
        <div className={styles.heroPanel}>
          <div className={styles.statGrid}>
            {!viewer ? (
              <>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>{session?.available_users?.length ?? 0}</span>
                  <span className={styles.statLabel}>Profiles ready</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>No password</span>
                  <span className={styles.statLabel}>Sign-in mode</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>Signed out</span>
                  <span className={styles.statLabel}>Default state</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>Simple</span>
                  <span className={styles.statLabel}>Just pick a username</span>
                </article>
              </>
            ) : viewer.role === 'learner' ? (
              <>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>{pending.length}</span>
                  <span className={styles.statLabel}>Pending sessions</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>{completed.length}</span>
                  <span className={styles.statLabel}>Completed sessions</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>{progressCounts.length}</span>
                  <span className={styles.statLabel}>Progress groups</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>{nextSession?.materials?.length ?? 0}</span>
                  <span className={styles.statLabel}>Materials next</span>
                </article>
              </>
            ) : (
              <>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>{visibleLearners.length}</span>
                  <span className={styles.statLabel}>Learners</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>
                    {visibleLearners.reduce(
                      (sum, learner) => sum + (learner.review_item_count ?? 0),
                      0,
                    )}
                  </span>
                  <span className={styles.statLabel}>Review items</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>
                    {visibleLearners.filter((learner) => learner.active_assignment).length}
                  </span>
                  <span className={styles.statLabel}>Active assignments</span>
                </article>
                <article className={styles.statCard}>
                  <span className={styles.statValue}>
                    {visibleLearners.filter((learner) => learner.today_session).length}
                  </span>
                  <span className={styles.statLabel}>Sessions today</span>
                </article>
              </>
            )}
          </div>

          <div className={styles.profileCard}>
            <p className={styles.profileName}>
              {viewer ? viewer.display_name : 'Username-based sign in'}
            </p>
            <p className={styles.profileMeta}>
              {viewer
                ? `${roleLabel(viewer)} · @${viewer.username}`
                : 'Choose a profile below or type the username directly.'}
            </p>
            {viewer?.current_level ? (
              <p className={styles.profileNote}>Current level: {viewer.current_level}</p>
            ) : null}
            {!viewer ? (
              <p className={styles.profileNote}>
                The content site stays simple: sign in, view progress, and log out.
              </p>
            ) : viewer.notes && viewer.notes.toLowerCase() !== 'owner' ? (
              <p className={styles.profileNote}>{viewer.notes}</p>
            ) : null}
          </div>
        </div>
      </section>

      {error ? <div className={styles.errorBanner}>{error}</div> : null}

      {!viewer ? (
        <section className={`${styles.panel} ${styles.loginPanel}`}>
          <h2 className={styles.sectionTitle}>Continue with username</h2>
          <p className={styles.sectionText}>
            Pick a household profile below or type the username directly.
          </p>
          <div className={styles.inputRow}>
            <input
              className={styles.input}
              onChange={(event) => setUsername(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  void handleLogin();
                }
              }}
              placeholder="Username"
              type="text"
              value={username}
            />
            <button
              className={styles.primaryButton}
              disabled={authBusy}
              onClick={() => {
                void handleLogin();
              }}
              type="button"
            >
              {authBusy ? 'Signing in…' : 'Enter content hub'}
            </button>
          </div>
          <div className={styles.quickList}>
            {(session?.available_users ?? []).map((user) => (
              <button
                className={styles.quickButton}
                key={user.user_id}
                onClick={() => {
                  setUsername(user.username);
                  void handleLogin(user.username);
                }}
                type="button"
              >
                <span>
                  <strong>{user.display_name}</strong>
                  <span className={styles.quickMeta}>
                    {roleLabel(user)} · @{user.username}
                  </span>
                </span>
                <span className={styles.badge}>Use this profile</span>
              </button>
            ))}
          </div>
        </section>
      ) : viewer.role === 'learner' ? (
        <div className={styles.grid}>
          <section className={styles.panel}>
            <h2 className={styles.sectionTitle}>What is next</h2>
            {nextSession ? (
              <>
                <p className={styles.sectionText}>
                  {nextSession.title} · {nextSession.scheduled_date}
                </p>
                <div className={styles.itemList}>
                  {nextSession.materials.map((material, index) => (
                    <article className={styles.itemCard} key={material.session_material_id}>
                      <p className={styles.itemEyebrow}>Step {index + 1}</p>
                      <h3>{material.title}</h3>
                      <p className={styles.itemMeta}>Ready for today&apos;s practice</p>
                    </article>
                  ))}
                </div>
              </>
            ) : (
              <p className={styles.emptyState}>
                No active session is waiting right now.
              </p>
            )}
          </section>

          <section className={styles.panel}>
            <h2 className={styles.sectionTitle}>Pending work</h2>
            {pending.length === 0 ? (
              <p className={styles.emptyState}>No pending sessions at the moment.</p>
            ) : (
              <div className={styles.itemList}>
                {pending.map((item) => (
                  <article className={styles.itemCard} key={item.session_id}>
                    <h3>{item.title}</h3>
                    <p>{item.notes || 'Still pending'}</p>
                    <p className={styles.itemMeta}>{item.scheduled_date}</p>
                  </article>
                ))}
              </div>
            )}
          </section>

          <section className={styles.panel}>
            <h2 className={styles.sectionTitle}>Completed work</h2>
            {completed.length === 0 ? (
              <p className={styles.emptyState}>No completed sessions are recorded yet.</p>
            ) : (
              <div className={styles.itemList}>
                {completed.map((item) => (
                  <article className={styles.itemCard} key={item.session_id}>
                    <h3>{item.title}</h3>
                    <p>{item.notes || 'Completed'}</p>
                    <p className={styles.itemMeta}>
                      {item.latest_evidence
                        ? `${item.latest_evidence.score}/${item.latest_evidence.max_score}`
                        : item.scheduled_date}
                    </p>
                  </article>
                ))}
              </div>
            )}
          </section>

          <section className={styles.panel}>
            <h2 className={styles.sectionTitle}>Skill progress</h2>
            {progressCounts.length ? (
              <div className={styles.pillList}>
                {progressCounts.map(([status, count]) => (
                  <span className={styles.pill} key={status}>
                    {count} {humanizeLabel(status)}
                  </span>
                ))}
              </div>
            ) : (
              <p className={styles.emptyState}>No skill progress is recorded yet.</p>
            )}
          </section>
        </div>
      ) : (
        <div className={styles.grid}>
          <section className={styles.panel}>
            <div>
              <h2 className={styles.sectionTitle}>Household learners</h2>
              <p className={styles.sectionText}>
                See each learner&apos;s current assignment, next step, and overall progress at a glance.
              </p>
            </div>
            {visibleLearners.length === 0 ? (
              <p className={styles.emptyState}>No learners are available in this household yet.</p>
            ) : (
              <div className={styles.cardGrid}>
                {visibleLearners.map((learner) => (
                  <article className={styles.learnerCard} key={learner.learner_id}>
                    <div className={styles.learnerCardHeader}>
                      <div>
                        <h3>{learner.display_name}</h3>
                        <p>{learner.current_level}</p>
                      </div>
                      <span className={styles.badge}>
                        Review: {learner.review_item_count}
                      </span>
                    </div>
                    <p className={styles.sectionText}>{progressSummary(learner)}</p>
                    <ul className={styles.factList}>
                      <li>
                        Active assignment:{' '}
                        {learner.active_assignment?.title ?? 'No active assignment'}
                      </li>
                      <li>
                        Next session:{' '}
                        {learner.today_session?.title ?? 'No session lined up'}
                      </li>
                      <li>
                        Latest evidence:{' '}
                        {learner.latest_evidence
                          ? `${learner.latest_evidence.score}/${learner.latest_evidence.max_score}`
                          : 'Nothing recorded yet'}
                      </li>
                    </ul>
                  </article>
                ))}
              </div>
            )}
          </section>
        </div>
      )}
    </div>
  );
}