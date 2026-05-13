-- V212: Bizonylat szövegek mint SystemParameter (admin UI-ból szerkeszthető)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES
  (gen_random_uuid(), 'RECEIPT_BANK_PARTNER_NAME', 'Raiffeisen Bank Zrt.', 'STRING', 'RECEIPT', 'Bankpartner neve a bizonylaton (300k+ Ft)', true, now(), 'SYSTEM'),
  (gen_random_uuid(), 'RECEIPT_BANK_PARTNER_SUBTITLE', 'KIEMELT KÖZVETÍTŐJE', 'STRING', 'RECEIPT', 'Bankpartner alcím a bizonylaton', true, now(), 'SYSTEM'),
  (gen_random_uuid(), 'RECEIPT_MARKETING_TITLE', 'EXCLUSIVE CHANGE', 'STRING', 'RECEIPT', 'Marketing cím a bizonylaton (300k+ Ft)', true, now(), 'SYSTEM'),
  (gen_random_uuid(), 'RECEIPT_MARKETING_SLOGAN', 'KEDVEZŐBB,\nGYORSABB,\nBIZTONSÁGOSABB', 'STRING', 'RECEIPT', 'Marketing szlogen a bizonylaton (soronként \\n)', true, now(), 'SYSTEM'),
  (gen_random_uuid(), 'RECEIPT_FOOTER_THANKS', 'Köszönjük, hogy minket választott!', 'STRING', 'RECEIPT', 'Lábléc köszöntő szöveg', true, now(), 'SYSTEM'),
  (gen_random_uuid(), 'RECEIPT_FOOTER_LEGAL', 'A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.', 'STRING', 'RECEIPT', 'Lábléc jogi szöveg', true, now(), 'SYSTEM'),
  (gen_random_uuid(), 'RECEIPT_VAT_EXEMPTION', 'Szj - 67.13.10.0\nAdómentes  a szolgáltatás nyújtása a 2007\nM.Á.A. evi CXVII tv. 86 § e) alapján\nmentes az adó alól', 'STRING', 'RECEIPT', 'ÁFA-mentességi szöveg', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;
