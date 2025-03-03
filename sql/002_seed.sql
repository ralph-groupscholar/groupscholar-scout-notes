INSERT INTO gs_scout_notes.organizations (name, website, focus_area)
VALUES
  ('Horizon Scholars Fund', 'https://horizonscholars.example.org', 'STEM scholarships for first-gen students'),
  ('Civic Futures Trust', 'https://civicfutures.example.org', 'Public service and community leadership'),
  ('Global Innovators Guild', 'https://globalinnovators.example.org', 'Entrepreneurship and innovation grants');

INSERT INTO gs_scout_notes.opportunities (
  organization_id,
  title,
  region,
  deadline_date,
  award_min_usd,
  award_max_usd,
  eligibility_notes
)
VALUES
  (1, 'Horizon Scholars Cohort', 'US - Midwest', '2026-04-30', 5000, 15000, 'First-gen, GPA 3.3+, STEM majors.'),
  (2, 'Civic Futures Fellowship', 'US - National', '2026-05-15', 3000, 8000, 'Public service commitment, community project required.'),
  (3, 'Global Innovators Seed Grant', 'Global', '2026-06-01', 2000, 10000, 'Early-stage founders with campus ventures.');

INSERT INTO gs_scout_notes.scout_notes (
  opportunity_id,
  scout_name,
  summary,
  risk_flags,
  follow_up_action,
  confidence_score
)
VALUES
  (1, 'Avery Reed', 'Strong alignment with our STEM partner schools; early outreach recommended.', 'Limited rural outreach', 'Request rural outreach stats from program lead.', 0.82),
  (2, 'Jordan Lee', 'Fellowship requires local sponsor; cohort capacity limited to 40.', 'Capacity constraints', 'Confirm if virtual placements are allowed.', 0.74),
  (3, 'Sam Patel', 'Grant offers flexible funding and mentorship network.', 'Undefined reporting expectations', 'Ask for sample reporting templates.', 0.68);

INSERT INTO gs_scout_notes.tags (label)
VALUES
  ('STEM'),
  ('Leadership'),
  ('Entrepreneurship'),
  ('Capacity Risk'),
  ('Equity Focus');

INSERT INTO gs_scout_notes.note_tags (note_id, tag_id)
VALUES
  (1, 1),
  (1, 5),
  (2, 2),
  (2, 4),
  (3, 3);
