WITH org_data AS (
  SELECT * FROM (VALUES
    ('Horizon Scholars Fund', 'https://horizonscholars.example.org', 'STEM scholarships for first-gen students'),
    ('Civic Futures Trust', 'https://civicfutures.example.org', 'Public service and community leadership'),
    ('Global Innovators Guild', 'https://globalinnovators.example.org', 'Entrepreneurship and innovation grants')
  ) AS v(name, website, focus_area)
),
upsert_orgs AS (
  INSERT INTO gs_scout_notes.organizations (name, website, focus_area)
  SELECT name, website, focus_area FROM org_data
  ON CONFLICT (name) DO UPDATE
    SET website = EXCLUDED.website,
        focus_area = EXCLUDED.focus_area,
        updated_at = NOW()
  RETURNING organization_id, name
),
orgs AS (
  SELECT organization_id, name FROM upsert_orgs
  UNION
  SELECT organization_id, name
  FROM gs_scout_notes.organizations
  WHERE name IN (SELECT name FROM org_data)
)
INSERT INTO gs_scout_notes.opportunities (
  organization_id,
  title,
  region,
  deadline_date,
  award_min_usd,
  award_max_usd,
  eligibility_notes
)
SELECT
  orgs.organization_id,
  opp.title,
  opp.region,
  opp.deadline_date,
  opp.award_min_usd,
  opp.award_max_usd,
  opp.eligibility_notes
FROM (
  VALUES
    ('Horizon Scholars Fund', 'Horizon Scholars Cohort', 'US - Midwest', '2026-04-30'::date, 5000, 15000, 'First-gen, GPA 3.3+, STEM majors.'),
    ('Civic Futures Trust', 'Civic Futures Fellowship', 'US - National', '2026-05-15'::date, 3000, 8000, 'Public service commitment, community project required.'),
    ('Global Innovators Guild', 'Global Innovators Seed Grant', 'Global', '2026-06-01'::date, 2000, 10000, 'Early-stage founders with campus ventures.')
) AS opp(org_name, title, region, deadline_date, award_min_usd, award_max_usd, eligibility_notes)
JOIN orgs ON orgs.name = opp.org_name
ON CONFLICT (organization_id, title) DO UPDATE
  SET region = EXCLUDED.region,
      deadline_date = EXCLUDED.deadline_date,
      award_min_usd = EXCLUDED.award_min_usd,
      award_max_usd = EXCLUDED.award_max_usd,
      eligibility_notes = EXCLUDED.eligibility_notes,
      updated_at = NOW();

WITH note_data AS (
  SELECT * FROM (VALUES
    ('Horizon Scholars Fund', 'Horizon Scholars Cohort', 'Avery Reed', 'Strong alignment with our STEM partner schools; early outreach recommended.', 'Limited rural outreach', 'Request rural outreach stats from program lead.', 0.82),
    ('Civic Futures Trust', 'Civic Futures Fellowship', 'Jordan Lee', 'Fellowship requires local sponsor; cohort capacity limited to 40.', 'Capacity constraints', 'Confirm if virtual placements are allowed.', 0.74),
    ('Global Innovators Guild', 'Global Innovators Seed Grant', 'Sam Patel', 'Grant offers flexible funding and mentorship network.', 'Undefined reporting expectations', 'Ask for sample reporting templates.', 0.68)
  ) AS v(org_name, title, scout_name, summary, risk_flags, follow_up_action, confidence_score)
)
INSERT INTO gs_scout_notes.scout_notes (
  opportunity_id,
  scout_name,
  summary,
  risk_flags,
  follow_up_action,
  confidence_score
)
SELECT
  o.opportunity_id,
  nd.scout_name,
  nd.summary,
  nd.risk_flags,
  nd.follow_up_action,
  nd.confidence_score
FROM note_data nd
JOIN gs_scout_notes.organizations org ON org.name = nd.org_name
JOIN gs_scout_notes.opportunities o
  ON o.organization_id = org.organization_id
 AND o.title = nd.title
WHERE NOT EXISTS (
  SELECT 1
  FROM gs_scout_notes.scout_notes sn
  WHERE sn.opportunity_id = o.opportunity_id
    AND sn.scout_name = nd.scout_name
    AND sn.summary = nd.summary
);

WITH contact_data AS (
  SELECT * FROM (VALUES
    ('Horizon Scholars Fund', 'Lena Morales', 'Program Director', 'lena@horizonscholars.example.org', '+1-312-555-0192', 4, 'Warm lead from Midwest STEM coalition.'),
    ('Civic Futures Trust', 'Marcus Holt', 'Fellowship Manager', 'mholt@civicfutures.example.org', '+1-202-555-0147', 3, 'Prefers monthly updates on applicant volume.'),
    ('Global Innovators Guild', 'Priya Nair', 'Innovation Grants Lead', 'priya@globalinnovators.example.org', '+44-20-5555-0101', 5, 'Highly responsive; open to co-hosted info sessions.')
  ) AS v(org_name, contact_name, role_title, email, phone, relationship_strength, notes)
)
INSERT INTO gs_scout_notes.scout_contacts (
  organization_id,
  contact_name,
  role_title,
  email,
  phone,
  relationship_strength,
  notes
)
SELECT
  org.organization_id,
  cd.contact_name,
  cd.role_title,
  cd.email,
  cd.phone,
  cd.relationship_strength,
  cd.notes
FROM contact_data cd
JOIN gs_scout_notes.organizations org ON org.name = cd.org_name
ON CONFLICT (organization_id, contact_name) DO UPDATE
  SET role_title = EXCLUDED.role_title,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      relationship_strength = EXCLUDED.relationship_strength,
      notes = EXCLUDED.notes;

WITH update_data AS (
  SELECT * FROM (VALUES
    ('Horizon Scholars Fund', 'Horizon Scholars Cohort', 'Eligibility', 'Added rural STEM applicants as priority cohort for 2026.', 'Positive: expands reach', '2026-03-15'::date),
    ('Civic Futures Trust', 'Civic Futures Fellowship', 'Capacity', 'Tentative plan to add 10 additional fellowship seats.', 'Positive: reduces capacity risk', '2026-03-22'::date),
    ('Global Innovators Guild', 'Global Innovators Seed Grant', 'Reporting', 'Drafted new quarterly impact reporting template.', 'Neutral: reporting expectations clearer', '2026-03-29'::date)
  ) AS v(org_name, title, update_type, update_summary, risk_impact, next_review_date)
)
INSERT INTO gs_scout_notes.opportunity_updates (
  opportunity_id,
  update_type,
  update_summary,
  risk_impact,
  next_review_date
)
SELECT
  o.opportunity_id,
  ud.update_type,
  ud.update_summary,
  ud.risk_impact,
  ud.next_review_date
FROM update_data ud
JOIN gs_scout_notes.organizations org ON org.name = ud.org_name
JOIN gs_scout_notes.opportunities o
  ON o.organization_id = org.organization_id
 AND o.title = ud.title
ON CONFLICT (opportunity_id, update_type, update_summary) DO UPDATE
  SET risk_impact = EXCLUDED.risk_impact,
      next_review_date = EXCLUDED.next_review_date;

INSERT INTO gs_scout_notes.tags (label)
VALUES
  ('STEM'),
  ('Leadership'),
  ('Entrepreneurship'),
  ('Capacity Risk'),
  ('Equity Focus')
ON CONFLICT (label) DO NOTHING;

WITH note_tag_data AS (
  SELECT * FROM (VALUES
    ('Avery Reed', 'Strong alignment with our STEM partner schools; early outreach recommended.', 'STEM'),
    ('Avery Reed', 'Strong alignment with our STEM partner schools; early outreach recommended.', 'Equity Focus'),
    ('Jordan Lee', 'Fellowship requires local sponsor; cohort capacity limited to 40.', 'Leadership'),
    ('Jordan Lee', 'Fellowship requires local sponsor; cohort capacity limited to 40.', 'Capacity Risk'),
    ('Sam Patel', 'Grant offers flexible funding and mentorship network.', 'Entrepreneurship')
  ) AS v(scout_name, summary, tag_label)
)
INSERT INTO gs_scout_notes.note_tags (note_id, tag_id)
SELECT
  sn.note_id,
  t.tag_id
FROM note_tag_data ntd
JOIN gs_scout_notes.scout_notes sn
  ON sn.scout_name = ntd.scout_name
 AND sn.summary = ntd.summary
JOIN gs_scout_notes.tags t
  ON t.label = ntd.tag_label
ON CONFLICT (note_id, tag_id) DO NOTHING;

WITH review_data AS (
  SELECT * FROM (VALUES
    ('Avery Reed', 'Strong alignment with our STEM partner schools; early outreach recommended.', 'Morgan Shaw', 4.6, 'Clear alignment notes; add evidence on rural outreach reach.', true, NOW() - INTERVAL '3 days'),
    ('Jordan Lee', 'Fellowship requires local sponsor; cohort capacity limited to 40.', 'Taylor Kim', 4.1, 'Solid risk capture; clarify sponsor constraints timeline.', true, NOW() - INTERVAL '5 days'),
    ('Sam Patel', 'Grant offers flexible funding and mentorship network.', 'Riley Quinn', 4.8, 'Strong insight capture with actionable follow-up.', false, NOW() - INTERVAL '2 days')
  ) AS v(scout_name, summary, reviewer_name, review_score, review_summary, followup_needed, reviewed_at)
)
INSERT INTO gs_scout_notes.note_reviews (
  note_id,
  reviewer_name,
  review_score,
  review_summary,
  followup_needed,
  reviewed_at
)
SELECT
  sn.note_id,
  rd.reviewer_name,
  rd.review_score,
  rd.review_summary,
  rd.followup_needed,
  rd.reviewed_at
FROM review_data rd
JOIN gs_scout_notes.scout_notes sn
  ON sn.scout_name = rd.scout_name
 AND sn.summary = rd.summary
WHERE NOT EXISTS (
  SELECT 1
  FROM gs_scout_notes.note_reviews nr
  WHERE nr.note_id = sn.note_id
    AND nr.reviewer_name = rd.reviewer_name
);
