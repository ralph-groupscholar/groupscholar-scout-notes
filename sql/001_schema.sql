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

CREATE TABLE IF NOT EXISTS gs_scout_notes.tags (
  tag_id BIGSERIAL PRIMARY KEY,
  label TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS gs_scout_notes.note_tags (
  note_id BIGINT NOT NULL REFERENCES gs_scout_notes.scout_notes(note_id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES gs_scout_notes.tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, tag_id)
);

CREATE OR REPLACE VIEW gs_scout_notes.weekly_summary AS
SELECT
  date_trunc('week', sn.created_at)::date AS week_start,
  COUNT(*) AS notes_count,
  COUNT(DISTINCT sn.scout_name) AS scouts_active,
  ROUND(AVG(sn.confidence_score), 2) AS avg_confidence
FROM gs_scout_notes.scout_notes sn
GROUP BY 1
ORDER BY 1 DESC;
