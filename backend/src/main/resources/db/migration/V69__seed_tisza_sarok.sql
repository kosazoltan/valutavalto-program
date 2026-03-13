-- Company
INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT DO NOTHING;

-- Branch: Tisza Sarok (Szeged)
INSERT INTO branch (id, company_id, name, code, city, address, is_active, created_at)
SELECT gen_random_uuid(), c.id, 'Tisza Sarok', 'TISZA', 'Szeged', 'Tisza Sarok', true, NOW()
FROM company c WHERE c.code = 'EBC'
ON CONFLICT DO NOTHING;

-- Workers
-- Borsi Tamás
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Borsi Tamás', 'BORSI', 'borsi.tamas.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;

-- Bali Henrietta
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Bali Henrietta', 'BALI', 'bali.henriett.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;

-- Kasza Helga
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Kasza Helga', 'KASZA', 'kasza.helga.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;
