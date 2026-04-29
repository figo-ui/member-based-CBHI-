/**
 * Seeds realistic Ethiopian CBHI sample data into the database.
 * Creates households, beneficiaries, coverages, claims, payments,
 * grievances, health facilities, benefit packages, CBHI officers,
 * and facility users.
 *
 * Run: node scripts/seed-sample-data.js
 * Prerequisites: seed-admin.js must have been run first (admin user must exist).
 */
require('dotenv').config({ path: '.env' });
const { Client } = require('pg');
const { createHash, pbkdf2Sync, randomBytes } = require('crypto');

function hashPassword(password) {
  const salt = createHash('sha256')
    .update(randomBytes(32))
    .update(`${Date.now()}:${Math.random()}`)
    .digest('hex');
  const hash = pbkdf2Sync(password, salt, 120000, 64, 'sha512').toString('hex');
  return `${salt}:${hash}`;
}

function randomDate(start, end) {
  return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

function fmt(date) {
  return date.toISOString().split('T')[0];
}

// ── Ethiopian sample data pools ───────────────────────────────────────────

const FIRST_NAMES_M = [
  'Abebe', 'Tesfaye', 'Girma', 'Mulugeta', 'Dawit', 'Yohannes', 'Bekele',
  'Haile', 'Solomon', 'Tadesse', 'Getachew', 'Mekonnen', 'Worku', 'Alemu',
  'Berhane', 'Kebede', 'Negash', 'Tsegaye', 'Amare', 'Lemma',
];

const FIRST_NAMES_F = [
  'Tigist', 'Hiwot', 'Mekdes', 'Selam', 'Bethlehem', 'Yeshi', 'Almaz',
  'Selamawit', 'Firehiwot', 'Meseret', 'Tsehay', 'Azeb', 'Genet', 'Rahel',
  'Aster', 'Birke', 'Zewditu', 'Mulu', 'Tseganesh', 'Wubet',
];

const LAST_NAMES = [
  'Tadesse', 'Bekele', 'Haile', 'Girma', 'Tesfaye', 'Alemu', 'Worku',
  'Kebede', 'Mekonnen', 'Getachew', 'Negash', 'Mulugeta', 'Abebe', 'Dawit',
  'Lemma', 'Tsegaye', 'Berhane', 'Amare', 'Solomon', 'Yohannes',
];

const REGIONS = ['Oromia', 'Amhara', 'SNNPR', 'Tigray', 'Addis Ababa'];

const LOCATIONS = [
  { region: 'Oromia', zone: 'West Hararghe', woreda: 'Chiro', kebele: 'Kebele 01' },
  { region: 'Oromia', zone: 'East Hararghe', woreda: 'Haramaya', kebele: 'Kebele 03' },
  { region: 'Oromia', zone: 'Jimma', woreda: 'Jimma Town', kebele: 'Kebele 05' },
  { region: 'Oromia', zone: 'Bale', woreda: 'Robe', kebele: 'Kebele 02' },
  { region: 'Amhara', zone: 'North Gondar', woreda: 'Gondar Town', kebele: 'Kebele 07' },
  { region: 'Amhara', zone: 'South Wollo', woreda: 'Dessie', kebele: 'Kebele 04' },
  { region: 'Amhara', zone: 'East Gojjam', woreda: 'Debre Markos', kebele: 'Kebele 06' },
  { region: 'SNNPR', zone: 'Sidama', woreda: 'Hawassa', kebele: 'Kebele 08' },
  { region: 'SNNPR', zone: 'Wolaita', woreda: 'Sodo', kebele: 'Kebele 02' },
  { region: 'Tigray', zone: 'Central Tigray', woreda: 'Mekelle', kebele: 'Kebele 01' },
];

const EMPLOYMENT_STATUSES = [
  'farmer', 'merchant', 'daily_laborer', 'employed', 'unemployed',
  'student', 'homemaker', 'pensioner',
];

const MEMBERSHIP_TYPES = ['paying', 'indigent'];
const COVERAGE_STATUSES = ['ACTIVE', 'ACTIVE', 'ACTIVE', 'PENDING_RENEWAL', 'EXPIRED'];
const CLAIM_STATUSES = ['SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PAID', 'ESCALATED'];
const GRIEVANCE_TYPES = [
  'CLAIM_REJECTION', 'FACILITY_DENIAL', 'ENROLLMENT_ISSUE', 'PAYMENT_ISSUE', 'OTHER',
];
const GRIEVANCE_STATUSES = ['OPEN', 'UNDER_REVIEW', 'RESOLVED', 'CLOSED'];
const PAYMENT_METHODS = ['MOBILE_MONEY', 'BANK_TRANSFER', 'EWALLET'];
const RELATIONSHIPS = ['SPOUSE', 'CHILD', 'PARENT', 'SIBLING'];

const SERVICES = [
  { name: 'Medical Consultation', code: 'OPD-001', price: 150 },
  { name: 'Specialist Consultation', code: 'OPD-002', price: 300 },
  { name: 'Essential Medicines', code: 'OPD-003', price: 200 },
  { name: 'Hospitalization (per day)', code: 'IPD-001', price: 800 },
  { name: 'Major Surgery', code: 'IPD-002', price: 5000 },
  { name: 'Antenatal Care (ANC)', code: 'MNCH-001', price: 200 },
  { name: 'Normal Delivery', code: 'MNCH-002', price: 1000 },
  { name: 'Blood Chemistry', code: 'LAB-001', price: 120 },
  { name: 'X-Ray', code: 'LAB-006', price: 300 },
  { name: 'Ultrasound', code: 'LAB-007', price: 500 },
];

const GRIEVANCE_SUBJECTS = [
  'Claim rejected without explanation',
  'Facility refused to accept my CBHI card',
  'Enrollment form was lost',
  'Payment not reflected in my account',
  'Indigent application rejected unfairly',
  'Coverage expired before renewal notice',
  'Wrong beneficiary information on card',
  'Delayed claim processing',
];

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function pickN(arr, n) {
  const shuffled = [...arr].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, n);
}
function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function randPhone() { return `+2519${String(randInt(10000000, 99999999))}`; }
function randMembershipId() { return `MBR-${String(randInt(100000, 999999))}`; }
function randHouseholdCode() { return `HH-${String(randInt(10000, 99999))}`; }
function randClaimNumber() { return `CLM-${String(randInt(100000, 999999))}`; }
function randTxRef() { return `TXN-${String(randInt(1000000, 9999999))}`; }

async function main() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false },
  });

  await client.connect();
  console.log('Connected to database');

  // ── 1. Benefit Packages ─────────────────────────────────────────────────
  console.log('\n── Seeding benefit packages...');

  const packageRows = await client.query(`
    INSERT INTO benefit_packages (name, description, "premiumPerMember", "annualCeiling", "isActive")
    VALUES
      ('Standard Package', 'Basic CBHI coverage for paying members. Covers OPD, IPD, MNCH, and diagnostics.', 120.00, 10000.00, TRUE),
      ('Indigent Package', 'Subsidized coverage for qualifying low-income households. Zero premium.', 0.00, 10000.00, TRUE),
      ('Enhanced Package', 'Extended coverage including specialist referrals and advanced diagnostics.', 240.00, 20000.00, TRUE)
    ON CONFLICT DO NOTHING
    RETURNING id, name
  `);
  console.log(`  ✓ ${packageRows.rowCount} benefit packages`);

  // Get package IDs
  const pkgRes = await client.query(`SELECT id, name FROM benefit_packages WHERE name IN ('Standard Package','Indigent Package','Enhanced Package')`);
  const pkgMap = {};
  for (const row of pkgRes.rows) pkgMap[row.name] = row.id;

  // Benefit items for Standard Package
  if (pkgMap['Standard Package']) {
    await client.query(`
      INSERT INTO benefit_items ("serviceName", "serviceCode", category, "maxClaimAmount", "coPaymentPercent", "maxClaimsPerYear", "isCovered", "packageId")
      VALUES
        ('Medical Consultation', 'OPD-001', 'outpatient', 150.00, 10, 12, TRUE, $1),
        ('Specialist Consultation', 'OPD-002', 'outpatient', 300.00, 20, 6, TRUE, $1),
        ('Essential Medicines', 'OPD-003', 'pharmacy', 200.00, 10, 0, TRUE, $1),
        ('Minor Procedure', 'OPD-004', 'outpatient', 500.00, 15, 4, TRUE, $1),
        ('Hospitalization (per day)', 'IPD-001', 'inpatient', 800.00, 10, 30, TRUE, $1),
        ('Major Surgery', 'IPD-002', 'inpatient', 5000.00, 20, 2, TRUE, $1),
        ('Minor Surgery', 'IPD-003', 'inpatient', 1500.00, 15, 4, TRUE, $1),
        ('Antenatal Care (ANC)', 'MNCH-001', 'maternal', 200.00, 0, 8, TRUE, $1),
        ('Normal Delivery', 'MNCH-002', 'maternal', 1000.00, 0, 2, TRUE, $1),
        ('Caesarean Section', 'MNCH-003', 'maternal', 4000.00, 10, 1, TRUE, $1),
        ('Blood Chemistry', 'LAB-001', 'laboratory', 120.00, 10, 12, TRUE, $1),
        ('HIV Screening', 'LAB-003', 'laboratory', 80.00, 0, 2, TRUE, $1),
        ('Malaria Test', 'LAB-004', 'laboratory', 60.00, 0, 6, TRUE, $1),
        ('X-Ray', 'LAB-006', 'radiology', 300.00, 20, 4, TRUE, $1),
        ('Ultrasound', 'LAB-007', 'radiology', 500.00, 20, 4, TRUE, $1),
        ('CT Scan', 'LAB-008', 'radiology', 2500.00, 30, 2, TRUE, $1)
      ON CONFLICT DO NOTHING
    `, [pkgMap['Standard Package']]);
    console.log('  ✓ Standard Package benefit items');
  }

  // ── 2. Health Facilities ────────────────────────────────────────────────
  console.log('\n── Seeding health facilities...');

  const facilityData = [
    { name: 'Maya City Referral Hospital', code: 'FAC-001', level: 'GENERAL_HOSPITAL', phone: '+251116600001', address: 'Maya City, Oromia', lat: '9.0250', lng: '38.7469' },
    { name: 'Chiro General Hospital', code: 'FAC-002', level: 'GENERAL_HOSPITAL', phone: '+251256600002', address: 'Chiro, West Hararghe, Oromia', lat: '9.0850', lng: '40.8700' },
    { name: 'Haramaya Health Center', code: 'FAC-003', level: 'HEALTH_CENTER', phone: '+251256600003', address: 'Haramaya, East Hararghe, Oromia', lat: '9.1800', lng: '41.9900' },
    { name: 'Jimma University Medical Center', code: 'FAC-004', level: 'SPECIALIZED_HOSPITAL', phone: '+251471600004', address: 'Jimma, Oromia', lat: '7.6700', lng: '36.8300' },
    { name: 'Gondar University Hospital', code: 'FAC-005', level: 'SPECIALIZED_HOSPITAL', phone: '+251581600005', address: 'Gondar, North Gondar, Amhara', lat: '12.6000', lng: '37.4700' },
    { name: 'Dessie Referral Hospital', code: 'FAC-006', level: 'GENERAL_HOSPITAL', phone: '+251331600006', address: 'Dessie, South Wollo, Amhara', lat: '11.1300', lng: '39.6400' },
    { name: 'Hawassa University Comprehensive Hospital', code: 'FAC-007', level: 'SPECIALIZED_HOSPITAL', phone: '+251462600007', address: 'Hawassa, Sidama, SNNPR', lat: '7.0500', lng: '38.4800' },
    { name: 'Sodo General Hospital', code: 'FAC-008', level: 'GENERAL_HOSPITAL', phone: '+251461600008', address: 'Sodo, Wolaita, SNNPR', lat: '6.8500', lng: '37.7500' },
    { name: 'Mekelle Hospital', code: 'FAC-009', level: 'GENERAL_HOSPITAL', phone: '+251344600009', address: 'Mekelle, Central Tigray', lat: '13.4900', lng: '39.4700' },
    { name: 'Robe Health Center', code: 'FAC-010', level: 'HEALTH_CENTER', phone: '+251226600010', address: 'Robe, Bale, Oromia', lat: '7.1200', lng: '40.0000' },
  ];

  for (const f of facilityData) {
    await client.query(`
      INSERT INTO health_facilities (name, "facilityCode", "serviceLevel", "phoneNumber", "addressLine", latitude, longitude, "isAccredited")
      VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
      ON CONFLICT ("facilityCode") DO NOTHING
    `, [f.name, f.code, f.level, f.phone, f.address, f.lat, f.lng]);
  }
  console.log(`  ✓ ${facilityData.length} health facilities`);

  const facilityRes = await client.query(`SELECT id, "facilityCode" FROM health_facilities WHERE "facilityCode" LIKE 'FAC-%'`);
  const facilityIds = facilityRes.rows.map(r => r.id);
  const facilityByCode = {};
  for (const r of facilityRes.rows) facilityByCode[r.facilityCode] = r.id;

  // ── 3. CBHI Officers ────────────────────────────────────────────────────
  console.log('\n── Seeding CBHI officers...');

  const officerData = [
    { first: 'Lemlem', last: 'Haile', phone: '+251900000010', email: 'lemlem.haile@cbhi.maya.gov.et', title: 'Senior CBHI Officer', level: 'WOREDA' },
    { first: 'Biruk', last: 'Tadesse', phone: '+251900000011', email: 'biruk.tadesse@cbhi.maya.gov.et', title: 'Claims Reviewer', level: 'WOREDA' },
    { first: 'Meron', last: 'Bekele', phone: '+251900000012', email: 'meron.bekele@cbhi.maya.gov.et', title: 'Indigent Assessor', level: 'KEBELE' },
    { first: 'Yonas', last: 'Girma', phone: '+251900000013', email: 'yonas.girma@cbhi.maya.gov.et', title: 'Finance Officer', level: 'WOREDA' },
  ];

  const officerHash = hashPassword('Officer@1234');
  for (const o of officerData) {
    await client.query(`
      INSERT INTO users ("firstName", "lastName", "phoneNumber", email, "passwordHash", role, "preferredLanguage", "isActive", "identityVerificationStatus")
      VALUES ($1, $2, $3, $4, $5, 'CBHI_OFFICER', 'am', TRUE, 'VERIFIED')
      ON CONFLICT ("phoneNumber") DO NOTHING
    `, [o.first, o.last, o.phone, o.email, officerHash]);

    await client.query(`
      INSERT INTO cbhi_officers ("officeName", "officeLevel", "positionTitle", "canApproveClaims", "canManageSettings", "userId")
      SELECT 'Maya City CBHI Office', $1, $2, TRUE, FALSE, u.id
      FROM users u WHERE u."phoneNumber" = $3
      ON CONFLICT ("userId") DO NOTHING
    `, [o.level, o.title, o.phone]);
  }
  console.log(`  ✓ ${officerData.length} CBHI officers`);

  // ── 4. Facility Staff Users ─────────────────────────────────────────────
  console.log('\n── Seeding facility staff...');

  const staffData = [
    { first: 'Abiy', last: 'Worku', phone: '+251900000020', email: 'abiy.worku@maya-hospital.gov.et', facilityCode: 'FAC-001', role: 'CLAIMS_OFFICER' },
    { first: 'Hana', last: 'Alemu', phone: '+251900000021', email: 'hana.alemu@chiro-hospital.gov.et', facilityCode: 'FAC-002', role: 'CLAIMS_OFFICER' },
    { first: 'Dawit', last: 'Negash', phone: '+251900000022', email: 'dawit.negash@haramaya-hc.gov.et', facilityCode: 'FAC-003', role: 'REGISTRAR' },
    { first: 'Tigist', last: 'Mekonnen', phone: '+251900000023', email: 'tigist.mekonnen@jimma-umc.gov.et', facilityCode: 'FAC-004', role: 'VERIFIER' },
    { first: 'Robel', last: 'Solomon', phone: '+251900000024', email: 'robel.solomon@gondar-uh.gov.et', facilityCode: 'FAC-005', role: 'CLAIMS_OFFICER' },
  ];

  const staffHash = hashPassword('Staff@1234');
  for (const s of staffData) {
    await client.query(`
      INSERT INTO users ("firstName", "lastName", "phoneNumber", email, "passwordHash", role, "preferredLanguage", "isActive", "identityVerificationStatus")
      VALUES ($1, $2, $3, $4, $5, 'HEALTH_FACILITY_STAFF', 'am', TRUE, 'VERIFIED')
      ON CONFLICT ("phoneNumber") DO NOTHING
    `, [s.first, s.last, s.phone, s.email, staffHash]);

    if (facilityByCode[s.facilityCode]) {
      await client.query(`
        INSERT INTO facility_users (role, "isActive", "facilityId", "userId")
        SELECT $1, TRUE, $2, u.id
        FROM users u WHERE u."phoneNumber" = $3
        ON CONFLICT ("userId") DO NOTHING
      `, [s.role, facilityByCode[s.facilityCode], s.phone]);
    }
  }
  console.log(`  ✓ ${staffData.length} facility staff`);
