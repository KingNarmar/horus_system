-- Issue #351 PR A: immutable issuer identity, without changing the invoice issuance RPC.
-- Additive and compatible with existing clients. No Storage or hosted deployment here.
BEGIN;

ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS tax_registration_number text;

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS issuer_company_name text,
  ADD COLUMN IF NOT EXISTS issuer_business_type text,
  ADD COLUMN IF NOT EXISTS issuer_phone text,
  ADD COLUMN IF NOT EXISTS issuer_email text,
  ADD COLUMN IF NOT EXISTS issuer_address text,
  ADD COLUMN IF NOT EXISTS issuer_city text,
  ADD COLUMN IF NOT EXISTS issuer_country text,
  ADD COLUMN IF NOT EXISTS issuer_tax_registration_number text,
  ADD COLUMN IF NOT EXISTS issuer_logo_path text,
  ADD COLUMN IF NOT EXISTS issuer_snapshot_source text,
  ADD COLUMN IF NOT EXISTS issuer_captured_at timestamptz;

-- Historical invoices have no captured issuer identity in the old schema.
-- This is explicitly a CURRENT-DATA BASELINE, NOT an assertion about the
-- issuer's name, address or logo at the historical issuance timestamp.
UPDATE public.invoices AS invoice_row
SET
  issuer_company_name = company_row.name,
  issuer_business_type = company_row.business_type,
  issuer_phone = company_row.phone,
  issuer_email = company_row.email,
  issuer_address = company_row.address,
  issuer_city = company_row.city,
  issuer_country = company_row.country,
  issuer_tax_registration_number = company_row.tax_registration_number,
  issuer_logo_path = NULL,
  issuer_snapshot_source = 'legacy_baseline',
  issuer_captured_at = pg_catalog.now()
FROM public.companies AS company_row
WHERE invoice_row.company_id = company_row.id
  AND invoice_row.issued_at IS NOT NULL
  AND invoice_row.issuer_snapshot_source IS NULL;

ALTER TABLE public.invoices
  ADD CONSTRAINT invoice_issuer_snapshot_consistency
  CHECK (
    (
      issued_at IS NULL
      AND issuer_snapshot_source IS NULL
      AND issuer_company_name IS NULL
      AND issuer_captured_at IS NULL
    )
    OR
    (
      issued_at IS NOT NULL
      AND issuer_company_name IS NOT NULL
      AND pg_catalog.btrim(issuer_company_name) <> ''
      AND issuer_snapshot_source IN ('issuance', 'legacy_baseline')
      AND issuer_captured_at IS NOT NULL
    )
  );

-- Runs INSIDE the existing atomic issue_invoice transaction.
-- SELECT FOR SHARE coordinates with company-profile updates so an invoice
-- cannot capture a name from one version and a logo from another.
CREATE FUNCTION private.capture_invoice_issuer_identity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog
AS $$
DECLARE
  v_company public.companies%ROWTYPE;
BEGIN
  IF OLD.issued_at IS NULL AND NEW.issued_at IS NOT NULL THEN
    IF OLD.company_id IS DISTINCT FROM NEW.company_id THEN
      RAISE EXCEPTION USING ERRCODE = 'P3514',
        MESSAGE = 'invoice_issuer_identity_immutable';
    END IF;

    SELECT * INTO v_company
    FROM public.companies AS company_row
    WHERE company_row.id = NEW.company_id
      AND company_row.is_active
    FOR SHARE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE = 'P3513',
        MESSAGE = 'invoice_issuer_company_unavailable';
    END IF;

    NEW.issuer_company_name := v_company.name;
    NEW.issuer_business_type := v_company.business_type;
    NEW.issuer_phone := v_company.phone;
    NEW.issuer_email := v_company.email;
    NEW.issuer_address := v_company.address;
    NEW.issuer_city := v_company.city;
    NEW.issuer_country := v_company.country;
    NEW.issuer_tax_registration_number :=
      v_company.tax_registration_number;
    -- Store an immutable private Storage OBJECT KEY, never a signed/public URL.
    NEW.issuer_logo_path := v_company.logo_url;
    NEW.issuer_snapshot_source := 'issuance';
    NEW.issuer_captured_at := pg_catalog.now();
  ELSIF OLD.issued_at IS NOT NULL THEN
    IF OLD.company_id IS DISTINCT FROM NEW.company_id
       OR ROW(
         OLD.issuer_company_name, OLD.issuer_business_type, OLD.issuer_phone,
         OLD.issuer_email, OLD.issuer_address, OLD.issuer_city,
         OLD.issuer_country, OLD.issuer_tax_registration_number,
         OLD.issuer_logo_path, OLD.issuer_snapshot_source,
         OLD.issuer_captured_at
       ) IS DISTINCT FROM ROW(
         NEW.issuer_company_name, NEW.issuer_business_type, NEW.issuer_phone,
         NEW.issuer_email, NEW.issuer_address, NEW.issuer_city,
         NEW.issuer_country, NEW.issuer_tax_registration_number,
         NEW.issuer_logo_path, NEW.issuer_snapshot_source,
         NEW.issuer_captured_at
       ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P3514',
        MESSAGE = 'invoice_issuer_identity_immutable';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.capture_invoice_issuer_identity()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER invoices_capture_issuer_identity
BEFORE UPDATE ON public.invoices
FOR EACH ROW EXECUTE FUNCTION private.capture_invoice_issuer_identity();

COMMENT ON COLUMN public.invoices.issuer_snapshot_source
  IS 'issuance = transaction-time verified identity; legacy_baseline = current company identity at migration, not historical proof';
COMMENT ON COLUMN public.invoices.issuer_logo_path
  IS 'Private, versioned company logo Storage object key captured at issuance; do not replace with a transient signed URL';

COMMIT;
