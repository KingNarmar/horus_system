-- #345 reference seed only: no Development UUIDs, users or business/test data.
-- Intentionally mirrors the Development Basic/Pro/Enterprise *capability*
-- configuration, not subscription customer records. Monthly prices are
-- zero-valued placeholders in Development and NOT launch pricing approval.
INSERT INTO public.subscription_plans
  (code,name,monthly_price,max_users,max_vehicles,max_trips_per_month,
   has_driver_app,has_advanced_reports,has_document_upload,has_maintenance,
   has_whatsapp_notifications,is_active)
VALUES
  ('basic','Basic',0.00,3,5,100,false,false,false,false,false,true),
  ('pro','Pro',0.00,10,25,1000,false,true,true,false,false,true),
  ('enterprise','Enterprise',0.00,NULL,NULL,NULL,true,true,true,true,true,true);
