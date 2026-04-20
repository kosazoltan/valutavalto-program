-- V145: Real production data seed - 64 branches + 194 workers
-- Source: EBC Zrt. snapshot 2025.12.30 + ID-KOD + 2025.10.06 nyitvatartas

ALTER TABLE branch ADD COLUMN IF NOT EXISTS region VARCHAR(40);
ALTER TABLE worker ADD COLUMN IF NOT EXISTS region VARCHAR(40);
CREATE INDEX IF NOT EXISTS idx_branch_region ON branch(region);
CREATE INDEX IF NOT EXISTS idx_worker_region ON worker(region);

INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'IRODA', 'Central Office', 'Iroda', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'BEKESCSABA', 'Bekescsaba', 'Bekescsaba', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'DEBRECEN', 'Debrecen', 'Debrecen', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'NYIREGYHAZA', 'Nyiregyhaza', 'Nyiregyhaza', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'KECSKEMET', 'Kecskemet', 'Kecskemet', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'SZEGED', 'Szeged', 'Szeged', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'KAPOSVAR', 'Kaposvar', 'Kaposvar', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'PECS', 'Pecs', 'Pecs', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at) VALUES (gen_random_uuid(), 'REGION', 'SZEKSZARD', 'Szekszard', 'Szekszard', 0, true, NOW()) ON CONFLICT (category, code) DO NOTHING;

DO $$ DECLARE v_cid UUID; v_tid UUID; v_coid UUID; v_sid UUID; BEGIN
  SELECT id INTO v_cid FROM company WHERE code = 'EBC' LIMIT 1;
  SELECT id INTO v_tid FROM dictionary WHERE category='BRANCH_TYPE' AND code='PENZTAR' LIMIT 1;
  SELECT id INTO v_coid FROM dictionary WHERE category='COUNTRY' AND code='HU' LIMIT 1;
  SELECT id INTO v_sid FROM dictionary WHERE category='BRANCH_STATUS' AND code='ACTIVE' LIMIT 1;
  IF v_cid IS NULL THEN RAISE EXCEPTION 'EBC company missing'; END IF;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Békéscsaba Belváros', 'BR076', 'BR076', 'Békéscsaba', 'Békéscsaba Belváros', 'BEKESCSABA', '5600', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Békéscsaba Tesco', 'BR074', 'BR074', 'Békéscsaba', 'Békéscsaba Tesco', 'BEKESCSABA', '5600', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Gyula Belváros', 'BR071', 'BR071', 'Gyula', 'Gyula Belváros', 'BEKESCSABA', '5600', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Gyula Tesco', 'BR077', 'BR077', 'Gyula', 'Gyula Tesco', 'BEKESCSABA', '5600', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szarvas Tesco', 'BR079', 'BR079', 'Szarvas', 'Szarvas Tesco', 'BEKESCSABA', '5600', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Debrecen Plaza', 'BR092', 'BR092', 'Debrecen', 'Debrecen Plaza', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Debrecen Tesco', 'BR060', 'BR060', 'Debrecen', 'Debrecen Tesco', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Debrecen Fórum', 'BR102', 'BR102', 'Debrecen', 'Debrecen Fórum', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Hajdúböszörmény', 'BR052', 'BR052', 'Hajdúböszörmény', 'Hajdúböszörmény', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Debrecen Kálvin tér', 'BR094', 'BR094', 'Debrecen', 'Debrecen Kálvin tér', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Berettyóújfalu Tesco', 'BR067', 'BR067', 'Berettyóújfalu', 'Berettyóújfalu Tesco', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Karcag', 'BR056', 'BR056', 'Karcag', 'Karcag', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Tiszaújváros Tesco', 'BR093', 'BR093', 'Tiszaújváros', 'Tiszaújváros Tesco', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Debrecen Új Bajcsy', 'BR091', 'BR091', 'Debrecen', 'Debrecen Új Bajcsy', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Bajcsy II', 'BR090', 'BR090', 'Bajcsy', 'Bajcsy II', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Hajdúszoboszló', 'BR066', 'BR066', 'Hajdúszoboszló', 'Hajdúszoboszló', 'DEBRECEN', '4024', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nyíregyháza Tesco', 'BR057', 'BR057', 'Nyíregyháza', 'Nyíregyháza Tesco', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nyíregyháza Országzászló', 'BR086', 'BR086', 'Nyíregyháza', 'Nyíregyháza Országzászló', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nyíregyháza Belváros', 'BR085', 'BR085', 'Nyíregyháza', 'Nyíregyháza Belváros', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nyíregyháza Plaza', 'BR062', 'BR062', 'Nyíregyháza', 'Nyíregyháza Plaza', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nyíregyháza Korzó', 'BR061', 'BR061', 'Nyíregyháza', 'Nyíregyháza Korzó', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kisvárda Tesco', 'BR064', 'BR064', 'Kisvárda', 'Kisvárda Tesco', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Mátészalka Tesco', 'BR084', 'BR084', 'Mátészalka', 'Mátészalka Tesco', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Sátoraljaújhely Tesco', 'BR087', 'BR087', 'Sátoraljaújhely', 'Sátoraljaújhely Tesco', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nyírbátor', 'BR081', 'BR081', 'Nyírbátor', 'Nyírbátor', 'NYIREGYHAZA', '4400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kecskemét Tesco', 'BR046', 'BR046', 'Kecskemét', 'Kecskemét Tesco', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kecskemét Alföld Áruház', 'BR043', 'BR043', 'Kecskemét', 'Kecskemét Alföld Áruház', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Cegléd Tesco', 'BR044', 'BR044', 'Cegléd', 'Cegléd Tesco', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szolnok Plaza', 'BR047', 'BR047', 'Szolnok', 'Szolnok Plaza', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szolnok Auchan', 'BR041', 'BR041', 'Szolnok', 'Szolnok Auchan', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kiskunhalas Tesco', 'BR045', 'BR045', 'Kiskunhalas', 'Kiskunhalas Tesco', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kiskőrös Tesco', 'BR089', 'BR089', 'Kiskőrös', 'Kiskőrös Tesco', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kiskunfélegyháza Tesco', 'BR049', 'BR049', 'Kiskunfélegyháza', 'Kiskunfélegyháza Tesco', 'KECSKEMET', '6000', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szeged Tesco-Rókusi', 'BR027', 'BR027', 'Szeged', 'Szeged Tesco-Rókusi', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szeged Shell Site-Móra', 'BR026', 'BR026', 'Szeged', 'Szeged Shell Site-Móra', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szeged Tisza 1', 'BR036', 'BR036', 'Szeged', 'Szeged Tisza 1', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szeged Tisza Sarok', 'BR035', 'BR035', 'Szeged', 'Szeged Tisza Sarok', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szeged Árkád 1', 'BR039', 'BR039', 'Szeged', 'Szeged Árkád 1', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szeged Árkád 2', 'BR033', 'BR033', 'Szeged', 'Szeged Árkád 2', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szentes Tesco', 'BR023', 'BR023', 'Szentes', 'Szentes Tesco', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Hódmezővásárhely Tesco', 'BR038', 'BR038', 'Hódmezővásárhely', 'Hódmezővásárhely Tesco', 'SZEGED', '6720', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kaposvár Dorottya Ház', 'BR150', 'BR150', 'Kaposvár', 'Kaposvár Dorottya Ház', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kaposvár Tesco', 'BR149', 'BR149', 'Kaposvár', 'Kaposvár Tesco', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kaposvár Ady', 'BR148', 'BR148', 'Kaposvár', 'Kaposvár Ady', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Dombóvár Tesco', 'BR009', 'BR009', 'Dombóvár', 'Dombóvár Tesco', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Dombóvár Spar', 'BR019', 'BR019', 'Dombóvár', 'Dombóvár Spar', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Nagyatád', 'BR141', 'BR141', 'Nagyatád', 'Nagyatád', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Siófok Tesco', 'BR139', 'BR139', 'Siófok', 'Siófok Tesco', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Siófok Plaza', 'BR146', 'BR146', 'Siófok', 'Siófok Plaza', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Marcali Tesco', 'BR136', 'BR136', 'Marcali', 'Marcali Tesco', 'KAPOSVAR', '7400', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Pécs Tesco', 'BR013', 'BR013', 'Pécs', 'Pécs Tesco', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Pécs Árkád', 'BR125', 'BR125', 'Pécs', 'Pécs Árkád', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Pécs Árkád 2', 'BR126', 'BR126', 'Pécs', 'Pécs Árkád 2', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Pécs Irgalmas', 'BR124', 'BR124', 'Pécs', 'Pécs Irgalmas', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Pécs Plaza', 'BR143', 'BR143', 'Pécs', 'Pécs Plaza', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Komló Tesco', 'BR018', 'BR018', 'Komló', 'Komló Tesco', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szigetvár Tesco', 'BR128', 'BR128', 'Szigetvár', 'Szigetvár Tesco', 'PECS', '7621', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szekszárd Belváros', 'BR012', 'BR012', 'Szekszárd', 'Szekszárd Belváros', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Szekszárd Tesco', 'BR016', 'BR016', 'Szekszárd', 'Szekszárd Tesco', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Bonyhád Tesco', 'BR011', 'BR011', 'Bonyhád', 'Bonyhád Tesco', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Baja Tesco', 'BR017', 'BR017', 'Baja', 'Baja Tesco', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Paks Tesco', 'BR014', 'BR014', 'Paks', 'Paks Tesco', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Mohács Tesco', 'BR099', 'BR099', 'Mohács', 'Mohács Tesco', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
  INSERT INTO branch (id, company_id, name, code, bank_code, city, address, region, zip_code, opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at) VALUES (gen_random_uuid(), v_cid, 'Kalocsa Belváros', 'BR100', 'BR100', 'Kalocsa', 'Kalocsa Belváros', 'SZEKSZARD', '7100', CURRENT_DATE, true, v_tid, v_coid, v_sid, NOW()) ON CONFLICT (code) DO UPDATE SET region = EXCLUDED.region, name = EXCLUDED.name;
END $$;

DO $$ DECLARE v_cid UUID; v_bid UUID; v_acol TEXT; BEGIN
  SELECT id INTO v_cid FROM company WHERE code = 'EBC' LIMIT 1;
  SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='worker' AND column_name='is_active') THEN 'is_active' ELSE 'active' END INTO v_acol;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S001') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S001', 'Apaceller-Marcsik Brigitta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007570') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007570', 'Bainé Priskin Erzsébet', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014517') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014517', 'Barabás Marietta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006376') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006376', 'Belej Hanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014519') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014519', 'Bencze Ildikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S006') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S006', 'Benka László', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007551') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007551', 'Bezdán Nikolett', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S008') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S008', 'Blochné Sarkadi Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007532') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007532', 'Bodonyi Gabriella', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005043') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005043', 'Bognárné Dominyák Dóra', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S011') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S011', 'Borossebesiné Bali Henriett Anita', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S012') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S012', 'Borsi Tamás', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S013') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S013', 'Börcsök Éva Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S014') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S014', 'Brandt Zsuzsanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'ADMIN', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S015') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S015', 'Bürgés József', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S016') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S016', 'Cziczinger Antal Sándorné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S017') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S017', 'Cziráki Rita', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014565') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014565', 'Csák Melinda', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005004') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005004', 'Csepák Klára', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014594') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014594', 'Cser Tímea Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005074') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005074', 'Csige-Kiss Eszter', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S022') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S022', 'Csókási Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S023') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S023', 'Dakos Gergő', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005070') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005070', 'Dancs Tiborné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012003') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012003', 'Dávid Viktória', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006305') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006305', 'Dávidné Péczeli Erika', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S027') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S027', 'Dedics József Jánosné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S028') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S028', 'Dékány Tímea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014588') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014588', 'Durczi Dalma', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S030') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S030', 'Endre Magdolna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S031') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S031', 'Erb Levente', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S032') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S032', 'Erdélyi Tibor', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S033') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S033', 'Erdey János', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007530') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007530', 'Érfalvi-Tenkei Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012006') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012006', 'Erős Brigitta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S036') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S036', 'Fabulya Zsuzsanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006307') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006307', 'Fássi Csaba', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S038') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S038', 'Fazekas József Jánosné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S039') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S039', 'Felczán Gyula', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S040') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S040', 'Fellegváriné Kádas Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S041') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S041', 'Felletár Dániel Emil', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014550') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014550', 'Fias Tímea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007515') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007515', 'Földesi Istvánné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005006') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005006', 'Földvári Gyuláné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S045') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S045', 'Gál Gyula', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S046') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S046', 'Gál Józsefné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S047') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S047', 'Gálfi János', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S048') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S048', 'Gallusz Gábor József', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014592') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014592', 'Gazdig Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001058') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001058', 'Gecő Erzsébet', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005054') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005054', 'Geraszimec Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006340') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006340', 'Gerzsenyi Margit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S053') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S053', 'Grásl Diána', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014090') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014090', 'Gubián Kitti', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S055') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S055', 'Gyántiné Vadász Tímea Zsuzsanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S056') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S056', 'Háber Tamásné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004024') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004024', 'Havasi Szilvia', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S058') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S058', 'Hayfron Williamné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S059') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S059', 'Hefler Éva Margit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012008') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012008', 'Herczeg Zsuzsanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S061') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S061', 'Hirschné Tóth Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S062') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S062', 'Holes Andrea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012052') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012052', 'Horváth Gábor', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012076') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012076', 'Horváth Ágnes', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S065') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S065', 'Hosnyánszki-Bölcsföldi Zsuzsanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S066') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S066', 'Hrabina Krisztián', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006313') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006313', 'Hruskáné Kiss Judit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S068') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S068', 'Iglódi Attila Ferenc', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004084') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004084', 'Igyártó Judit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001036') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001036', 'Imre Melinda', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006366') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006366', 'Jackánics Laura', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S072') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S072', 'Jankovicsné Dallos Sarolta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S073') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S073', 'Jékel Ella Ida', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S074') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S074', 'Juhász Csaba', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S075') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S075', 'Juhos Lőrinc', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012077') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012077', 'Kádas István', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006316') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006316', 'Kalauz Edit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014503') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014503', 'Kanizsai Mária', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S079') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S079', 'Kántor-Gombos Mária Adrienn', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S080') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S080', 'Karácsonyi József', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S081') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S081', 'Kardos Ildikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002085') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002085', 'Kardos Andrea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S083') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S083', 'Kassai Lajos Róbert', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005062') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005062', 'Kasuba Ádám', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S085') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S085', 'Kasza Helga', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S086') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S086', 'Kaszás János Péter', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001055') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001055', 'Kelemen Dorka', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005009') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005009', 'Kenéz Adrienn', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S089') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S089', 'Kenéz Éva', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S090') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S090', 'Kerekes Zoltán Imréné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S091') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S091', 'Kisné Kecskés Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S092') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S092', 'Kispál Attila', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001045') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001045', 'Kiss Julianna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S094') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S094', 'Kiss Kornél', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S095') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S095', 'Kiss Károly Balázs', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S096') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S096', 'Klobucsár Judit Márta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S097') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S097', 'Kocsis Angéla', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006368') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006368', 'Kocsisné Palicska Rita', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006319') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006319', 'Kojsza Zsuzsanna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S100') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S100', 'Koncz Andrea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S101') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S101', 'Kósa Zoltán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001054') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001054', 'Kósa Veronika', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S103') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S103', 'Kósa-Gallusz Ildikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S104') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S104', 'Kosztyu Csaba', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012024') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012024', 'Kovács Mercedes', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014570') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014570', 'Kovács Renáta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006374') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006374', 'Kovács Anita', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002064') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002064', 'Kovácsi Luca Ágnes', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007531') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007531', 'Kovalovszki Anikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004008') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004008', 'Kozla Zsolt Tamásné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S111') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S111', 'Kőhegyi-Balogh Zita Mária', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002017') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002017', 'Kracsin Attila', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S113') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S113', 'Krisztián Tibor', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S114') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S114', 'Kun Éva Ildikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002090') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002090', 'Lehoczki Andrea Éva', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001009') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001009', 'Lengyel Adrienn', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S117') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S117', 'Lipák Csilla Mária', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006367') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006367', 'Lizákné Nagy Mária', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S119') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S119', 'Lovász János', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S120') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S120', 'Madár Zoltán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S121') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S121', 'Madár Zoltán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006370') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006370', 'Magyar Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007564') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007564', 'Mahler Zoltán László', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S124') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S124', 'Marosiné Fang Dóra', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014596') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014596', 'Marosi-Pintér Nikoletta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S126') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S126', 'Márton Péterné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006362') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006362', 'Máté Györgyné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S128') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S128', 'Maxi Attila Gábor', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S129') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S129', 'Méhész Tibor', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005079') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005079', 'Molnár Edit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002019') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002019', 'Molnárné Buka Mariann', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S132') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S132', 'Nagy Zoltán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006331') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006331', 'Nagy Attiláné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006375') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006375', 'Nagy Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012078') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012078', 'Nagy Tímea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005035') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005035', 'Nagyné Árvai Erzsébet', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S137') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S137', 'Nagyné Marsi Viktória', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004011') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004011', 'Narancsik Zsanett', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S139') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S139', 'Németh Zsuzsa', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014586') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014586', 'Novák Anita', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004085') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004085', 'Nyitrainé Feke Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005018') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005018', 'Oksz Attila', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004049') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004049', 'Orbán Melinda', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W050102') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W050102', 'Ősz Viktória', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006324') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006324', 'Pakot Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S146') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S146', 'Pál Heléna Marianna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006359') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006359', 'Paládi Erika', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S148') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S148', 'Piatkó Zoltán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002023') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002023', 'Pongor Natália', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004040') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004040', 'Porok László', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004012') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004012', 'Puskásné Gál Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S152') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S152', 'Putnoki Mariann', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S153') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S153', 'Radics Rita', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002024') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002024', 'Rengei Marianna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005081') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005081', 'Sain Tímea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001057') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001057', 'Sáy Zoltán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S157') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S157', 'Schnellné Balogh Edit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S158') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S158', 'Schumacher Tímea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005077') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005077', 'Sebestyén Andrea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005022') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005022', 'Sinai Éva', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S161') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S161', 'Somos Andrea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'IRODA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S162') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S162', 'Staviarszki Istvánné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012017') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012017', 'Stefán Katalin', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005053') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005053', 'Steinbinder Eszter', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S165') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S165', 'Szabó Katalin Jolán', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S166') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S166', 'Szabó László Donát', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S167') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S167', 'Szabó Rudolfné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S168') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S168', 'Szabó Mihály László', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S169') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S169', 'Szilágyi István', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006379') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006379', 'Szulics-Tóth Henrietta', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W006369') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W006369', 'Takács Jánosné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001016') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001016', 'Takácsné Auth Anikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005080') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005080', 'Tamas Tímea', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005033') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005033', 'Tenkely Viktória', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002073') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002073', 'Tóth Andrásné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S176') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S176', 'Tóth Ágnes', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002093') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002093', 'Tóth Judit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W012020') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W012020', 'Türk Mátyás', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004047') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004047', 'Varga Éva Veronika', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S181') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S181', 'Varga Ildikó Anna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR150' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W014587') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W014587', 'Vargáné Nagy Viktória', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'MANAGER', 'KAPOSVAR', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004021') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004021', 'Vári Istvánné', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W001053') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W001053', 'Városi István', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005082') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005082', 'Vécseiné Stáhl Edit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S186') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S186', 'Verebné Szín Rozália Tünde', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR027' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W002003') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W002003', 'Vida Veronika', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEGED', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR092' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W005028') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W005028', 'Vince Ildikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'DEBRECEN', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR076' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W007526') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W007526', 'Virág Margit', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'BEKESCSABA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S190') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S190', 'Vízi-Molnár Anikó', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR012' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S191') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S191', 'Zatykóné Sebestyén Ramóna', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'SZEKSZARD', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR013' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S192') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S192', 'Zomi Dominika', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'PECS', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR057' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W-S193') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W-S193', 'Zsidai Sándor', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'NYIREGYHAZA', NULL;
  END IF;
  SELECT id INTO v_bid FROM branch WHERE code = 'BR046' AND company_id = v_cid LIMIT 1;
  IF v_bid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM worker WHERE company_id = v_cid AND code = 'W004026') THEN
    EXECUTE format('INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, email, %I, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())', v_acol)
      USING v_cid, v_bid, 'W004026', 'Zsigmond Tamás', '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie', 'CASHIER', 'KECSKEMET', NULL;
  END IF;
END $$;

UPDATE worker SET region = 'SZEGED' WHERE code IN ('BORSI','BALI','KASZA','KOSA') AND region IS NULL;
UPDATE branch SET region = 'SZEGED' WHERE code IN ('TISZA','KORUT') AND region IS NULL;
