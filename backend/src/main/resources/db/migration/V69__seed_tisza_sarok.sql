-- Company: Exclusive Best Change Zrt.
INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT DO NOTHING;

-- Branch: Tisza Sarok (Szeged)
INSERT INTO branch (id, company_id, name, code, bank_code, city, address, is_active, created_at)
SELECT gen_random_uuid(), c.id, 'Tisza Sarok', 'TISZA', 'TISZA', 'Szeged', 'Tisza Sarok, Szeged', true, NOW()
FROM company c WHERE c.code = 'EBC'
ON CONFLICT DO NOTHING;

-- Worker: Borsi Tamas
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Borsi Tamas', 'BORSI', 'borsi.tamas.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;

-- Worker: Bali Henrietta
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Bali Henrietta', 'BALI', 'bali.henriett.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;

-- Worker: Kasza Helga
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Kasza Helga', 'KASZA', 'kasza.helga.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;
