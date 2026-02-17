-- Add Urdu, Pashto, and Dari to supported languages
-- Run this in Supabase SQL Editor

INSERT INTO supported_languages (code, name, native_name, enabled) VALUES
('ur', 'Urdu', 'اردو', true),
('ps', 'Pashto', 'پښتو', true),
('fa', 'Dari', 'دری', true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  native_name = EXCLUDED.native_name,
  enabled = EXCLUDED.enabled;
