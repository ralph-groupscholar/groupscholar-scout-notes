# Group Scholar Scout Notes

A SQL-first data model for capturing scholarship scouting notes, tagging risk signals, and summarizing weekly pipeline health.

## Features
- Normalized schema for organizations, opportunities, scouting notes, and tags
- Contact and update tracking for scouting relationships
- Follow-up task tracking with workload visibility
- Weekly summary view for reporting cadence
- Tag signal and deadline pipeline views for coverage planning
- Review quality tracking with stale-note detection
- Seed data for realistic demo and analytics validation

## Tech Stack
- SQL (PostgreSQL 18+)

## Getting Started
1. Ensure a PostgreSQL database is available.
2. Apply the schema:

```bash
psql "$DATABASE_URL" -f sql/001_schema.sql
```

3. Seed the data:

```bash
psql "$DATABASE_URL" -f sql/002_seed.sql
```

## Example Queries
```sql
SELECT * FROM gs_scout_notes.weekly_summary;

SELECT * FROM gs_scout_notes.tag_signal_summary;

SELECT * FROM gs_scout_notes.deadline_pipeline;

SELECT o.title, sn.summary, sn.confidence_score
FROM gs_scout_notes.scout_notes sn
JOIN gs_scout_notes.opportunities o ON o.opportunity_id = sn.opportunity_id
ORDER BY sn.created_at DESC;

SELECT * FROM gs_scout_notes.open_followups;

SELECT * FROM gs_scout_notes.scout_workload;

SELECT * FROM gs_scout_notes.review_quality_summary;

SELECT * FROM gs_scout_notes.notes_needing_review;
```

## Notes
- Use environment variables (e.g. `DATABASE_URL`) for credentials.
- Each project should keep its own schema to avoid collisions.
