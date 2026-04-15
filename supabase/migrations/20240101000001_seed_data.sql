-- ============================================================
-- Maya City CBHI — Seed Data
-- Demo admin, facility staff, location hierarchy, and system settings
-- ============================================================

-- ── Locations: Ethiopian Administrative Hierarchy ─────────────────────────────

-- Regions
INSERT INTO locations (name, "nameAmharic", code, level, "isActive") VALUES
  ('Oromia',              'ኦሮሚያ',              'OR',       'REGION', TRUE),
  ('Amhara',              'አማራ',               'AM',       'REGION', TRUE),
  ('Tigray',              'ትግራይ',              'TI',       'REGION', TRUE),
  ('SNNPR',               'ደቡብ ብሔሮች',          'SN',       'REGION', TRUE),
  ('Somali',              'ሶማሌ',               'SO',       'REGION', TRUE),
  ('Afar',                'አፋር',               'AF',       'REGION', TRUE),
  ('Benishangul-Gumuz',   'ቤኒሻንጉል-ጉሙዝ',        'BG',       'REGION', TRUE),
  ('Gambela',             'ጋምቤላ',              'GA',       'REGION', TRUE),
  ('Harari',              'ሐረሪ',               'HA',       'REGION', TRUE),
  ('Dire Dawa',           'ድሬ ዳዋ',             'DD',       'REGION', TRUE),
  ('Addis Ababa',         'አዲስ አበባ',            'AA',       'REGION', TRUE),
  ('Sidama',              'ሲዳማ',               'SI',       'REGION', TRUE),
  ('South West Ethiopia', 'ደቡብ ምዕራብ ኢትዮጵያ',    'SW',       'REGION', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Oromia Zones
INSERT INTO locations (name, "nameAmharic", code, level, "isActive", "parentId")
SELECT z.name, z."nameAmharic", z.code, 'ZONE', TRUE, l.id
FROM (VALUES
  ('East Hararghe',  'ምስራቅ ሐረርጌ', 'OR-EH'),
  ('West Hararghe',  'ምዕራብ ሐረርጌ', 'OR-WH'),
  ('Arsi',           'አርሲ',        'OR-AR'),
  ('Bale',           'ባሌ',         'OR-BA'),
  ('Borena',         'ቦረና',        'OR-BO'),
  ('Guji',           'ጉጂ',         'OR-GU'),
  ('Jimma',          'ጅማ',         'OR-JI'),
  ('West Shewa',     'ምዕራብ ሸዋ',   'OR-WS'),
  ('North Shewa',    'ሰሜን ሸዋ',    'OR-NS'),
  ('East Shewa',     'ምስራቅ ሸዋ',   'OR-ES')
) AS z(name, "nameAmharic", code)
JOIN locations l ON l.code = 'OR'
ON CONFLICT (code) DO NOTHING;

-- East Hararghe Woredas
INSERT INTO locations (name, "nameAmharic", code, level, "isActive", "parentId")
SELECT w.name, w."nameAmharic", w.code, 'WOREDA', TRUE, l.id
FROM (VALUES
  ('Maya City',       'ማያ ከተማ',   'OR-EH-MC'),
  ('Harar',           'ሐረር',       'OR-EH-HA'),
  ('Dire Dawa Rural', 'ድሬ ዳዋ ገጠር', 'OR-EH-DD'),
  ('Babile',          'ባቢሌ',       'OR-EH-BB'),
  ('Gursum',          'ጉርሱም',      'OR-EH-GU'),
  ('Jarso',           'ጃርሶ',       'OR-EH-JA'),
  ('Kombolcha',       'ቆምቦልቻ',     'OR-EH-KO'),
  ('Chinaksen',       'ቺናክሰን',     'OR-EH-CH')
) AS w(name, "nameAmharic", code)
JOIN locations l ON l.code = 'OR-EH'
ON CONFLICT (code) DO NOTHING;

-- Maya City Kebeles
INSERT INTO locations (name, "nameAmharic", code, level, "isActive", "parentId")
SELECT k.name, k."nameAmharic", k.code, 'KEBELE', TRUE, l.id
FROM (VALUES
  ('Kebele 01', 'ቀበሌ 01', 'OR-EH-MC-01'),
  ('Kebele 02', 'ቀበሌ 02', 'OR-EH-MC-02'),
  ('Kebele 03', 'ቀበሌ 03', 'OR-EH-MC-03'),
  ('Kebele 04', 'ቀበሌ 04', 'OR-EH-MC-04'),
  ('Kebele 05', 'ቀበሌ 05', 'OR-EH-MC-05'),
  ('Kebele 06', 'ቀበሌ 06', 'OR-EH-MC-06'),
  ('Kebele 07', 'ቀበሌ 07', 'OR-EH-MC-07'),
  ('Kebele 08', 'ቀበሌ 08', 'OR-EH-MC-08')
) AS k(name, "nameAmharic", code)
JOIN locations l ON l.code = 'OR-EH-MC'
ON CONFLICT (code) DO NOTHING;

-- ── Health Facility ───────────────────────────────────────────────────────────
INSERT INTO health_facilities (name, "facilityCode", "isAccredited", "locationId")
SELECT 'Maya Referral Hospital', 'FAC-001', TRUE, l.id
FROM locations l WHERE l.code = 'OR-EH-MC'
ON CONFLICT ("facilityCode") DO NOTHING;

-- ── System Settings ───────────────────────────────────────────────────────────
INSERT INTO system_settings (key, label, description, value, "isSensitive") VALUES
  (
    'notifications.sms_enabled',
    'SMS notifications',
    'Controls whether OTP and alert SMS delivery is enabled.',
    '{"enabled": false}',
    FALSE
  ),
  (
    'claims.auto_assign_under_review',
    'Auto mark new claims under review',
    'When enabled, newly submitted claims can automatically enter review.',
    '{"enabled": true}',
    FALSE
  ),
  (
    'membership.default_premium_per_member',
    'Default premium per member',
    'Baseline ETB amount used when the premium is recalculated.',
    '{"amount": 120}',
    FALSE
  ),
  (
    'indigent.income_threshold',
    'Indigent income threshold (ETB)',
    'Monthly income below this amount qualifies for indigent scoring.',
    '{"amount": 1000}',
    FALSE
  ),
  (
    'indigent.approval_threshold',
    'Indigent approval score threshold',
    'Minimum score required for automatic indigent approval.',
    '{"score": 70}',
    FALSE
  ),
  (
    'coverage.renewal_reminder_days',
    'Coverage renewal reminder days',
    'Send renewal reminders this many days before coverage expires.',
    '{"days": [30, 7]}',
    FALSE
  )
ON CONFLICT (key) DO NOTHING;

-- ── Default Benefit Package ───────────────────────────────────────────────────
INSERT INTO benefit_packages (name, description, "isActive", "premiumPerMember", "annualCeiling")
VALUES (
  'Standard CBHI Package',
  'Standard community-based health insurance benefit package for Maya City households.',
  TRUE,
  120.00,
  0.00
) ON CONFLICT DO NOTHING;

-- Add standard covered services
INSERT INTO benefit_items ("serviceName", "serviceCode", category, "maxClaimAmount", "coPaymentPercent", "maxClaimsPerYear", "isCovered", "packageId")
SELECT s."serviceName", s."serviceCode", s.category, s."maxClaimAmount", s."coPaymentPercent", s."maxClaimsPerYear", TRUE, bp.id
FROM (VALUES
  ('Outpatient consultation',     'OPD-001', 'outpatient',  500.00,  0, 12),
  ('Emergency care',              'EMG-001', 'emergency',   2000.00, 0, 0),
  ('Inpatient admission',         'INP-001', 'inpatient',   5000.00, 0, 3),
  ('Malaria treatment',           'MAL-001', 'outpatient',  800.00,  0, 4),
  ('Maternal care (ANC)',         'MAT-001', 'maternal',    1500.00, 0, 8),
  ('Normal delivery',             'DEL-001', 'maternal',    3000.00, 0, 2),
  ('Caesarean section',           'CES-001', 'surgery',     8000.00, 0, 1),
  ('Laboratory tests',            'LAB-001', 'lab',         500.00,  0, 12),
  ('X-ray / Imaging',             'IMG-001', 'lab',         800.00,  0, 6),
  ('Essential medicines',         'PHR-001', 'pharmacy',    300.00,  0, 12),
  ('Tuberculosis treatment',      'TB-001',  'outpatient',  0.00,    0, 0),
  ('HIV/AIDS care',               'HIV-001', 'outpatient',  0.00,    0, 0),
  ('Child immunization',          'IMM-001', 'outpatient',  0.00,    0, 0),
  ('Family planning',             'FP-001',  'outpatient',  200.00,  0, 4),
  ('Minor surgical procedures',   'SRG-001', 'surgery',     2000.00, 0, 2)
) AS s("serviceName", "serviceCode", category, "maxClaimAmount", "coPaymentPercent", "maxClaimsPerYear")
CROSS JOIN benefit_packages bp
WHERE bp.name = 'Standard CBHI Package'
ON CONFLICT DO NOTHING;
