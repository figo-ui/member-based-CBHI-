-- ============================================================
-- Maya City CBHI — Supabase Storage Buckets
-- Configures storage buckets for file uploads.
-- ============================================================

-- Documents bucket (identity docs, birth certificates, claim attachments)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  FALSE,
  52428800, -- 50 MB
  ARRAY[
    'image/jpeg', 'image/png', 'image/webp', 'image/heic',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- Profile photos bucket (beneficiary photos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'photos',
  'photos',
  FALSE,
  10485760, -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- ── Storage RLS Policies ──────────────────────────────────────────────────────
-- Note: Supabase Storage uses its own RLS system.
-- The NestJS backend uses the service role key to bypass RLS for uploads.
-- Direct client access is denied — all file operations go through the API.

-- Deny all direct public access to documents
CREATE POLICY "No public access to documents"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND FALSE);

CREATE POLICY "No public access to photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'photos' AND FALSE);

