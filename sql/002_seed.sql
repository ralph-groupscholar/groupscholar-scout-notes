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

INSERT INTO gs_scout_notes.scout_contacts (
  organization_id,
  contact_name,
  role_title,
  email,
  phone,
  relationship_strength,
  notes
)
VALUES
  (1, 'Lena Morales', 'Program Director', 'lena@horizonscholars.example.org', '+1-312-555-0192', 4, 'Warm lead from Midwest STEM coalition.'),
  (2, 'Marcus Holt', 'Fellowship Manager', 'mholt@civicfutures.example.org', '+1-202-555-0147', 3, 'Prefers monthly updates on applicant volume.'),
  (3, 'Priya Nair', 'Innovation Grants Lead', 'priya@globalinnovators.example.org', '+44-20-5555-0101', 5, 'Highly responsive; open to co-hosted info sessions.');

INSERT INTO gs_scout_notes.opportunity_updates (
  opportunity_id,
  update_type,
  update_summary,
  risk_impact,
  next_review_date
)
VALUES
  (1, 'Eligibility', 'Added rural STEM applicants as priority cohort for 2026.', 'Positive: expands reach', '2026-03-15'),
  (2, 'Capacity', 'Tentative plan to add 10 additional fellowship seats.', 'Positive: reduces capacity risk', '2026-03-22'),
  (3, 'Reporting', 'Drafted new quarterly impact reporting template.', 'Neutral: reporting expectations clearer', '2026-03-29');

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

INSERT INTO gs_scout_notes.note_reviews (
  note_id,
  reviewer_name,
  review_score,
  review_summary,
  followup_needed,
  reviewed_at
)
VALUES
  (1, 'Morgan Shaw', 4.6, 'Clear alignment notes; add evidence on rural outreach reach.', true, NOW() - INTERVAL '3 days'),
  (2, 'Taylor Kim', 4.1, 'Solid risk capture; clarify sponsor constraints timeline.', true, NOW() - INTERVAL '5 days'),
  (3, 'Riley Quinn', 4.8, 'Strong insight capture with actionable follow-up.', false, NOW() - INTERVAL '2 days');

INSERT INTO gs_scout_notes.follow_up_tasks (
  note_id,
  owner_name,
  task_summary,
  status,
  due_date
)
VALUES
  (1, 'Avery Reed', 'Collect rural outreach breakdown from Horizon Scholars.', 'open', '2026-02-20'),
  (2, 'Jordan Lee', 'Verify if virtual placements satisfy sponsor requirement.', 'in_progress', '2026-02-18'),
  (3, 'Sam Patel', 'Request reporting template samples from program contact.', 'blocked', '2026-02-25');
