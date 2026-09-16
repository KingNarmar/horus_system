-- Issue #231 / PC-07 - align persisted freight precision with company currency.
--
-- Company currency supports up to four fraction digits. Preserve the existing
-- twelve integer digits while widening the monetary scale from 2 to 4.
-- Physical column names remain unchanged for invoice/report compatibility.

ALTER TABLE public.routes
  ALTER COLUMN default_freight_price TYPE numeric(16, 4)
  USING default_freight_price::numeric(16, 4);

ALTER TABLE public.trips
  ALTER COLUMN freight_price TYPE numeric(16, 4)
  USING freight_price::numeric(16, 4),
  ALTER COLUMN agreed_freight_rate_per_ton TYPE numeric(16, 4)
  USING agreed_freight_rate_per_ton::numeric(16, 4);
