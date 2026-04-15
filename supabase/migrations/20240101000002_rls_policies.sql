-- ============================================================
-- Maya City CBHI — Row Level Security (RLS) Policies
-- Supabase-specific security layer
-- ============================================================
-- NOTE: The NestJS backend connects via the service_role key
-- which bypasses RLS. These policies protect direct Supabase
-- client access (e.g., future mobile SDK integration).
-- ============================================================

-- Enable RLS on all sensitive tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE beneficiaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE coverages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE indigent_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE grievances ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Public read-only tables (no RLS needed for backend service role)
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE benefit_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE benefit_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- ── Allow service_role full access (NestJS backend) ───────────────────────────
-- The backend uses the service_role key which bypasses RLS automatically.
-- These policies are for anon/authenticated Supabase client access.

-- Locations: public read
CREATE POLICY "locations_public_read" ON locations
  FOR SELECT USING (TRUE);

-- Health facilities: public read
CREATE POLICY "health_facilities_public_read" ON health_facilities
  FOR SELECT USING (TRUE);

-- Benefit packages: public read
CREATE POLICY "benefit_packages_public_read" ON benefit_packages
  FOR SELECT USING (TRUE);

CREATE POLICY "benefit_items_public_read" ON benefit_items
  FOR SELECT USING (TRUE);

-- All other tables: deny direct client access (backend only via service_role)
-- This ensures all data access goes through the NestJS API layer
CREATE POLICY "users_deny_direct" ON users
  FOR ALL USING (FALSE);

CREATE POLICY "households_deny_direct" ON households
  FOR ALL USING (FALSE);

CREATE POLICY "beneficiaries_deny_direct" ON beneficiaries
  FOR ALL USING (FALSE);

CREATE POLICY "coverages_deny_direct" ON coverages
  FOR ALL USING (FALSE);

CREATE POLICY "payments_deny_direct" ON payments
  FOR ALL USING (FALSE);

CREATE POLICY "claims_deny_direct" ON claims
  FOR ALL USING (FALSE);

CREATE POLICY "claim_items_deny_direct" ON claim_items
  FOR ALL USING (FALSE);

CREATE POLICY "documents_deny_direct" ON documents
  FOR ALL USING (FALSE);

CREATE POLICY "notifications_deny_direct" ON notifications
  FOR ALL USING (FALSE);

CREATE POLICY "indigent_applications_deny_direct" ON indigent_applications
  FOR ALL USING (FALSE);

CREATE POLICY "grievances_deny_direct" ON grievances
  FOR ALL USING (FALSE);

CREATE POLICY "audit_logs_deny_direct" ON audit_logs
  FOR ALL USING (FALSE);

CREATE POLICY "system_settings_deny_direct" ON system_settings
  FOR ALL USING (FALSE);
