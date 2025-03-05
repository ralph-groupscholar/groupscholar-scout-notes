-- Schema for Group Scholar scholarship scout notes
CREATE SCHEMA IF NOT EXISTS gs_scout_notes;

CREATE TABLE IF NOT EXISTS gs_scout_notes.organizations (
  organization_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  website TEXT,
  focus_area TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.opportunities (
  opportunity_id BIGSERIAL PRIMARY KEY,
  organization_id BIGINT NOT NULL REFERENCES gs_scout_notes.organizations(organization_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  region TEXT NOT NULL,
  deadline_date DATE,
  award_min_usd INT,
  award_max_usd INT,
  eligibility_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.scout_notes (
  note_id BIGSERIAL PRIMARY KEY,
  opportunity_id BIGINT NOT NULL REFERENCES gs_scout_notes.opportunities(opportunity_id) ON DELETE CASCADE,
  scout_name TEXT NOT NULL,
  summary TEXT NOT NULL,
  risk_flags TEXT,
  follow_up_action TEXT,
  confidence_score NUMERIC(4,2) NOT NULL DEFAULT 0.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.scout_contacts (
  contact_id BIGSERIAL PRIMARY KEY,
  organization_id BIGINT NOT NULL REFERENCES gs_scout_notes.organizations(organization_id) ON DELETE CASCADE,
  contact_name TEXT NOT NULL,
  role_title TEXT,
  email TEXT,
  phone TEXT,
  relationship_strength INT NOT NULL DEFAULT 3,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.opportunity_updates (
  update_id BIGSERIAL PRIMARY KEY,
  opportunity_id BIGINT NOT NULL REFERENCES gs_scout_notes.opportunities(opportunity_id) ON DELETE CASCADE,
  update_type TEXT NOT NULL,
  update_summary TEXT NOT NULL,
  risk_impact TEXT,
  next_review_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.follow_up_tasks (
  task_id BIGSERIAL PRIMARY KEY,
  note_id BIGINT NOT NULL REFERENCES gs_scout_notes.scout_notes(note_id) ON DELETE CASCADE,
  owner_name TEXT NOT NULL,
  task_summary TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  due_date DATE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT follow_up_tasks_status_check CHECK (status IN ('open', 'in_progress', 'blocked', 'done'))
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.tags (
  tag_id BIGSERIAL PRIMARY KEY,
  label TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.note_tags (
  note_id BIGINT NOT NULL REFERENCES gs_scout_notes.scout_notes(note_id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES gs_scout_notes.tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, tag_id)
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.note_reviews (
  review_id BIGSERIAL PRIMARY KEY,
  note_id BIGINT NOT NULL REFERENCES gs_scout_notes.scout_notes(note_id) ON DELETE CASCADE,
  reviewer_name TEXT NOT NULL,
  review_score NUMERIC(4,2) NOT NULL DEFAULT 0.0,
  review_summary TEXT,
  followup_needed BOOLEAN NOT NULL DEFAULT FALSE,
  reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS scout_notes_created_at_idx
  ON gs_scout_notes.scout_notes(created_at DESC);

CREATE INDEX IF NOT EXISTS scout_notes_opportunity_idx
  ON gs_scout_notes.scout_notes(opportunity_id);

CREATE UNIQUE INDEX IF NOT EXISTS organizations_name_uidx
  ON gs_scout_notes.organizations(name);

CREATE UNIQUE INDEX IF NOT EXISTS opportunities_org_title_uidx
  ON gs_scout_notes.opportunities(organization_id, title);

CREATE UNIQUE INDEX IF NOT EXISTS scout_contacts_org_name_uidx
  ON gs_scout_notes.scout_contacts(organization_id, contact_name);

CREATE UNIQUE INDEX IF NOT EXISTS opportunity_updates_key_uidx
  ON gs_scout_notes.opportunity_updates(opportunity_id, update_type, update_summary);

CREATE INDEX IF NOT EXISTS opportunities_deadline_idx
  ON gs_scout_notes.opportunities(deadline_date);

CREATE INDEX IF NOT EXISTS note_tags_tag_idx
  ON gs_scout_notes.note_tags(tag_id);

CREATE INDEX IF NOT EXISTS follow_up_tasks_status_idx
  ON gs_scout_notes.follow_up_tasks(status);

CREATE INDEX IF NOT EXISTS follow_up_tasks_due_date_idx
  ON gs_scout_notes.follow_up_tasks(due_date);

CREATE INDEX IF NOT EXISTS note_reviews_note_idx
  ON gs_scout_notes.note_reviews(note_id);

CREATE INDEX IF NOT EXISTS note_reviews_reviewed_at_idx
  ON gs_scout_notes.note_reviews(reviewed_at DESC);

CREATE OR REPLACE VIEW gs_scout_notes.weekly_summary AS
SELECT
  date_trunc('week', sn.created_at)::date AS week_start,
  COUNT(*) AS notes_count,
  COUNT(DISTINCT sn.scout_name) AS scouts_active,
  ROUND(AVG(sn.confidence_score), 2) AS avg_confidence
FROM gs_scout_notes.scout_notes sn
GROUP BY 1
ORDER BY 1 DESC;

CREATE OR REPLACE VIEW gs_scout_notes.tag_signal_summary AS
SELECT
  t.label AS tag,
  COUNT(*) AS notes_tagged,
  ROUND(AVG(sn.confidence_score), 2) AS avg_confidence,
  MAX(sn.created_at) AS last_noted_at
FROM gs_scout_notes.note_tags nt
JOIN gs_scout_notes.tags t ON t.tag_id = nt.tag_id
JOIN gs_scout_notes.scout_notes sn ON sn.note_id = nt.note_id
GROUP BY 1
ORDER BY notes_tagged DESC, tag ASC;

CREATE OR REPLACE VIEW gs_scout_notes.review_quality_summary AS
SELECT
  sn.scout_name,
  COUNT(nr.review_id) AS reviews_count,
  ROUND(AVG(nr.review_score), 2) AS avg_review_score,
  MAX(nr.reviewed_at) AS last_reviewed_at,
  COUNT(*) FILTER (WHERE nr.followup_needed) AS followup_flags
FROM gs_scout_notes.note_reviews nr
JOIN gs_scout_notes.scout_notes sn ON sn.note_id = nr.note_id
GROUP BY sn.scout_name
ORDER BY avg_review_score DESC NULLS LAST, reviews_count DESC, sn.scout_name;

CREATE OR REPLACE VIEW gs_scout_notes.deadline_pipeline AS
SELECT
  date_trunc('month', o.deadline_date)::date AS month_start,
  o.region,
  COUNT(*) AS opportunities_due,
  COUNT(DISTINCT o.organization_id) AS orgs_active
FROM gs_scout_notes.opportunities o
WHERE o.deadline_date IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;

CREATE OR REPLACE VIEW gs_scout_notes.notes_needing_review AS
SELECT
  sn.note_id,
  sn.scout_name,
  sn.summary,
  sn.created_at,
  MAX(nr.reviewed_at) AS last_reviewed_at,
  CASE
    WHEN MAX(nr.reviewed_at) IS NULL THEN 'not_reviewed'
    WHEN MAX(nr.reviewed_at) < CURRENT_DATE - INTERVAL '30 days' THEN 'stale_review'
    ELSE 'current'
  END AS review_status
FROM gs_scout_notes.scout_notes sn
LEFT JOIN gs_scout_notes.note_reviews nr ON nr.note_id = sn.note_id
GROUP BY sn.note_id, sn.scout_name, sn.summary, sn.created_at
HAVING MAX(nr.reviewed_at) IS NULL
   OR MAX(nr.reviewed_at) < CURRENT_DATE - INTERVAL '30 days'
ORDER BY sn.created_at DESC;

CREATE OR REPLACE VIEW gs_scout_notes.open_followups AS
SELECT
  fut.task_id,
  fut.owner_name,
  fut.task_summary,
  fut.status,
  fut.due_date,
  sn.scout_name,
  o.title AS opportunity_title,
  org.name AS organization_name
FROM gs_scout_notes.follow_up_tasks fut
JOIN gs_scout_notes.scout_notes sn ON sn.note_id = fut.note_id
JOIN gs_scout_notes.opportunities o ON o.opportunity_id = sn.opportunity_id
JOIN gs_scout_notes.organizations org ON org.organization_id = o.organization_id
WHERE fut.status <> 'done'
ORDER BY fut.due_date NULLS LAST, fut.created_at DESC;

CREATE OR REPLACE VIEW gs_scout_notes.scout_workload AS
SELECT
  fut.owner_name,
  COUNT(*) FILTER (WHERE fut.status <> 'done') AS open_tasks,
  COUNT(*) FILTER (
    WHERE fut.status <> 'done'
      AND fut.due_date IS NOT NULL
      AND fut.due_date <= CURRENT_DATE + INTERVAL '7 days'
  ) AS due_soon,
  COUNT(*) FILTER (WHERE fut.status = 'blocked') AS blocked_tasks,
  MAX(fut.updated_at) AS last_task_update
FROM gs_scout_notes.follow_up_tasks fut
GROUP BY fut.owner_name
ORDER BY open_tasks DESC, fut.owner_name;
