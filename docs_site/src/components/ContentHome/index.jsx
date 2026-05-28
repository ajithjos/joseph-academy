import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
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

  const generatedCatalogUrl = useBaseUrl('/generated/catalog-overview');
  const materialsUrl = useBaseUrl('/generated/materials');
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
                : 'Browse generated curriculum content while keeping learner assignments, review load, and progress close at hand.'
              : 'Choose a username to open the parent / teacher content hub or the student-facing progress view. This login is intentionally username-only for now.'}
          </p>
          <div className={styles.actions}>
            <Link className={styles.secondaryButton} to={generatedCatalogUrl}>
              Browse generated catalog
            </Link>
            <Link className={styles.secondaryButton} to={materialsUrl}>
              Browse materials
            </Link>
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
        <aside className={styles.heroPanel}>
          <div className={styles.statGrid}>
            <div className={styles.statCard}>
              <span className={styles.statValue}>
                {session?.available_users?.filter((user) => user.role !== 'learner')
                  .length ?? 0}
              </span>
              <span className={styles.statLabel}>Parent / Teacher users</span>
            </div>
            <div className={styles.statCard}>
              <span className={styles.statValue}>
                {session?.available_users?.filter((user) => user.role === 'learner')
                  .length ?? 0}
              </span>
              <span className={styles.statLabel}>Student users</span>
            </div>
            <div className={styles.statCard}>
              <span className={styles.statValue}>{visibleLearners.length}</span>
              <span className={styles.statLabel}>
                {viewer?.role === 'learner' ? 'Visible learners' : 'Tracked learners'}
              </span>
            </div>
            <div className={styles.statCard}>
              <span className={styles.statValue}>
                {viewer?.role === 'learner'
                  ? completed.length
                  : visibleLearners.reduce(
                      (total, learner) => total + (learner.review_item_count ?? 0),
                      0,
                    )}
              </span>
              <span className={styles.statLabel}>
                {viewer?.role === 'learner'
                  ? 'Completed sessions'
                  : 'Review items'}
              </span>
            </div>
          </div>
          {viewer ? (
            <div className={styles.profileCard}>
              <p className={styles.profileName}>{viewer.display_name}</p>
              <p className={styles.profileMeta}>
                {roleLabel(viewer)} · @{viewer.username}
              </p>
              {viewer.current_level ? (
                <p className={styles.profileNote}>
                  Current level: {viewer.current_level}
                </p>
              ) : null}
            </div>
          ) : (
            <div className={styles.profileCard}>
              <p className={styles.profileName}>Username-only sign-in</p>
              <p className={styles.profileMeta}>
                The parent / teacher account sees household-wide progress. Student accounts see their own pending and completed work.
              </p>
            </div>
          )}
        </aside>
      </section>

      {error ? <div className={styles.errorBanner}>{error}</div> : null}

      {!viewer ? (
        <div className={styles.grid}>
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

          <section className={styles.panel}>
            <h2 className={styles.sectionTitle}>What each view does</h2>
            <div className={styles.itemList}>
              <article className={styles.itemCard}>
                <h3>Parent / Teacher</h3>
                <p>
                  Track every learner, see active assignments, and spot review load before you jump back into the main app.
                </p>
              </article>
              <article className={styles.itemCard}>
                <h3>Student</h3>
                <p>
                  See what is pending, what is already completed, and which parts of the catalog connect to the current learning run.
                </p>
              </article>
              <article className={styles.itemCard}>
                <h3>Catalog browsing</h3>
                <p>
                  The generated docs stay open to everyone, so you can still browse curriculum content even before choosing a username.
                </p>
              </article>
            </div>
          </section>
        </div>
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
                      <p>{material.skill_id}</p>
                      <p className={styles.itemMeta}>Material: {material.material_id}</p>
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
            {learnerDetail?.progress?.length ? (
              <div className={styles.pillList}>
                {learnerDetail.progress.map((state) => (
                  <span className={styles.pill} key={state.skill_id}>
                    {state.skill_id}: {state.status}
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
            <div className={styles.panelHeader}>
              <div>
                <h2 className={styles.sectionTitle}>Household learners</h2>
                <p className={styles.sectionText}>
                  Scan progress, active assignments, and review pressure without leaving the content site.
                </p>
              </div>
              <button
                className={styles.secondaryButton}
                disabled={dataBusy}
                onClick={() => {
                  void refreshAll();
                }}
                type="button"
              >
                {dataBusy ? 'Refreshing…' : 'Refresh'}
              </button>
            </div>
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
          </section>

          <section className={styles.panel}>
            <h2 className={styles.sectionTitle}>Content routes</h2>
            <div className={styles.itemList}>
              <article className={styles.itemCard}>
                <h3>Generated catalog</h3>
                <p>
                  Browse the rendered catalog overview, subjects, stages, skills, playlists, and materials from the repo-owned curriculum files.
                </p>
                <Link className={styles.linkButton} to={generatedCatalogUrl}>
                  Open generated catalog
                </Link>
              </article>
              <article className={styles.itemCard}>
                <h3>Materials browser</h3>
                <p>
                  Jump straight into the generated material pages when you want the authored teaching notes and source-facing content.
                </p>
                <Link className={styles.linkButton} to={materialsUrl}>
                  Open materials
                </Link>
              </article>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}