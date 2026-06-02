-- V286 — FK-ÁLLAMPOLGÁRSÁG (2026-06-02): a teljes nemzetiség/állampolgárság törzs seedelése.
-- A pénztári CustomerPanel eddig CSAK 3 fix opciót adott (Magyar/EU/Egyéb); a user a TELJES
-- állampolgárság-választhatóságot kérte. A NATIONALITY dictionary kategória name_hu = magyar
-- nemzetiség-megnevezés. Idempotens (ON CONFLICT (category, code) DO NOTHING). Magyar elöl,
-- a többi magyar név szerint ábécésorrendben, végén az "Egyéb" gyűjtő.

INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'HU', 'Hungary', 'Magyar', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AF', 'Afghanistan', 'Afgán', 10, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AL', 'Albania', 'Albán', 11, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'DZ', 'Algeria', 'Algériai', 12, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'US', 'United States', 'Amerikai', 13, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AD', 'Andorra', 'Andorrai', 14, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AO', 'Angola', 'Angolai', 15, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AR', 'Argentina', 'Argentin', 16, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AU', 'Australia', 'Ausztrál', 17, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AZ', 'Azerbaijan', 'Azerbajdzsáni', 18, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BH', 'Bahrain', 'Bahreini', 19, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BD', 'Bangladesh', 'Bangladesi', 20, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BY', 'Belarus', 'Belarusz', 21, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BE', 'Belgium', 'Belga', 22, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BG', 'Bulgaria', 'Bolgár', 23, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BA', 'Bosnia and Herzegovina', 'Bosznia-hercegovinai', 24, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'BR', 'Brazil', 'Brazil', 25, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'GB', 'United Kingdom', 'Brit', 26, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CL', 'Chile', 'Chilei', 27, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CY', 'Cyprus', 'Ciprusi', 28, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CZ', 'Czechia', 'Cseh', 29, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'DK', 'Denmark', 'Dán', 30, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'ZA', 'South Africa', 'Dél-afrikai', 31, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'KR', 'South Korea', 'Dél-koreai', 32, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AE', 'United Arab Emirates', 'Egyesült arab emírségekbeli', 33, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'EG', 'Egypt', 'Egyiptomi', 34, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'KP', 'North Korea', 'Észak-koreai', 35, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MK', 'North Macedonia', 'Észak-macedón', 36, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'EE', 'Estonia', 'Észt', 37, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'ET', 'Ethiopia', 'Etióp', 38, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'FI', 'Finland', 'Finn', 39, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'FR', 'France', 'Francia', 40, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PH', 'Philippines', 'Fülöp-szigeteki', 41, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'GR', 'Greece', 'Görög', 42, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'GE', 'Georgia', 'Grúz', 43, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'NL', 'Netherlands', 'Holland', 44, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'HR', 'Croatia', 'Horvát', 45, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'IN', 'India', 'Indiai', 46, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'ID', 'Indonesia', 'Indonéz', 47, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'IE', 'Ireland', 'Ír', 48, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'IQ', 'Iraq', 'Iraki', 49, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'IR', 'Iran', 'Iráni', 50, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'IL', 'Israel', 'Izraeli', 51, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'JP', 'Japan', 'Japán', 52, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'JO', 'Jordan', 'Jordániai', 53, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CA', 'Canada', 'Kanadai', 54, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'QA', 'Qatar', 'Katari', 55, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'KZ', 'Kazakhstan', 'Kazah', 56, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'KE', 'Kenya', 'Kenyai', 57, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CN', 'China', 'Kínai', 58, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CO', 'Colombia', 'Kolumbiai', 59, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CU', 'Cuba', 'Kubai', 60, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'KW', 'Kuwait', 'Kuvaiti', 61, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PL', 'Poland', 'Lengyel', 62, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LV', 'Latvia', 'Lett', 63, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LB', 'Lebanon', 'Libanoni', 64, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LY', 'Libya', 'Líbiai', 65, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LI', 'Liechtenstein', 'Liechtensteini', 66, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LT', 'Lithuania', 'Litván', 67, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LU', 'Luxembourg', 'Luxemburgi', 68, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MY', 'Malaysia', 'Maláj', 69, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MT', 'Malta', 'Máltai', 70, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MA', 'Morocco', 'Marokkói', 71, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MX', 'Mexico', 'Mexikói', 72, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MD', 'Moldova', 'Moldovai', 73, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'MC', 'Monaco', 'Monacói', 74, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'ME', 'Montenegro', 'Montenegrói', 75, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'DE', 'Germany', 'Német', 76, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'NG', 'Nigeria', 'Nigériai', 77, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'NO', 'Norway', 'Norvég', 78, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'IT', 'Italy', 'Olasz', 79, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'RU', 'Russia', 'Orosz', 80, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AT', 'Austria', 'Osztrák', 81, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'AM', 'Armenia', 'Örmény', 82, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PK', 'Pakistan', 'Pakisztáni', 83, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PS', 'Palestine', 'Palesztin', 84, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PA', 'Panama', 'Panamai', 85, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PE', 'Peru', 'Perui', 86, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'PT', 'Portugal', 'Portugál', 87, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'RO', 'Romania', 'Román', 88, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'ES', 'Spain', 'Spanyol', 89, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'LK', 'Sri Lanka', 'Srí lanka-i', 90, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'CH', 'Switzerland', 'Svájci', 91, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'SE', 'Sweden', 'Svéd', 92, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'SA', 'Saudi Arabia', 'Szaúd-arábiai', 93, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'RS', 'Serbia', 'Szerb', 94, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'SG', 'Singapore', 'Szingapúri', 95, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'SY', 'Syria', 'Szíriai', 96, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'SK', 'Slovakia', 'Szlovák', 97, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'SI', 'Slovenia', 'Szlovén', 98, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'TW', 'Taiwan', 'Tajvani', 99, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'TH', 'Thailand', 'Thaiföldi', 100, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'TR', 'Turkey', 'Török', 101, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'TN', 'Tunisia', 'Tunéziai', 102, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'NZ', 'New Zealand', 'Új-zélandi', 103, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'UA', 'Ukraine', 'Ukrán', 104, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'UY', 'Uruguay', 'Uruguayi', 105, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'UZ', 'Uzbekistan', 'Üzbég', 106, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'VE', 'Venezuela', 'Venezuelai', 107, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'VN', 'Vietnam', 'Vietnámi', 108, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'NATIONALITY', 'OTHER', 'Other', 'Egyéb', 9999, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
