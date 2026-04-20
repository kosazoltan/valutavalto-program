-- V146: Munkakor -> worker.role + worker_role_assignment (V57 RBAC)
-- Dedup: V145 W-kodos duplikatumok deaktivalasa (BORSI/KASZA/KOSA/Madar Zoltan)
-- 194 dolgozo besorolasa xlsx-munkakor szerint:
-- CASHIER (lokal Valutavalto), SUPERVISOR (ertektaros lokal), MANAGER (szerver), ADMIN (ugyvezeto)

-- 1. Duplikatumok deaktivalasa: a V145 xlsx-bol bekerult W-kodos duplikatumokat
--    (amelyeknek neve normalizaltan egyezik a V111 seed BORSI/KASZA/KOSA nevevel)
--    deaktivaljuk. A V111 rovid-kodokat (BORSI/BALI/KASZA/KOSA) tartjuk meg
--    mint legacy fallback-login (bcrypt('1234')).
UPDATE worker SET is_active = false
WHERE company_id = (SELECT id FROM company WHERE code = 'EBC')
  AND code IN ('W-S012', 'W-S085', 'W-S101');  -- Borsi, Kasza, Kosa V145-dupliatumok

-- Madar Zoltan az xlsx-ben ket helyen van (W-S120 + W-S121). A masodikat deaktivaljuk.
UPDATE worker SET is_active = false
WHERE company_id = (SELECT id FROM company WHERE code = 'EBC')
  AND code = 'W-S121';

-- 2. worker.role enum frissites munkakor alapjan (legacy enum)
-- Legacy seed workers (BORSI/BALI/KASZA/KOSA) role-enum - kezi mapping
UPDATE worker SET role = 'CASHIER' WHERE code IN ('BORSI','BALI','KASZA') AND company_id = (SELECT id FROM company WHERE code = 'EBC');
UPDATE worker SET role = 'ADMIN' WHERE code = 'KOSA' AND company_id = (SELECT id FROM company WHERE code = 'EBC');

UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S001' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007570' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014517' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006376' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014519' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S006' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007551' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S008' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007532' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005043' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S011' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S012' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S013' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S014' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S015' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S016' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S017' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014565' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005004' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014594' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005074' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S022' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S023' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005070' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012003' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006305' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S027' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S028' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014588' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S030' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S031' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S032' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S033' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007530' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012006' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S036' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006307' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S038' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S039' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S040' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S041' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014550' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007515' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005006' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S045' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S046' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S047' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S048' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014592' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001058' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005054' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006340' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S053' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014090' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S055' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S056' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004024' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S058' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S059' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012008' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S061' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S062' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012052' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012076' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S065' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S066' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006313' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S068' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W004084' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001036' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006366' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S072' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S073' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S074' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S075' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012077' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006316' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014503' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S079' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S080' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S081' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002085' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S083' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005062' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S085' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S086' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001055' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005009' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S089' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S090' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S091' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S092' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001045' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S094' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S095' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S096' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S097' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006368' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006319' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S100' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'ADMIN' WHERE code = 'W-S101' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001054' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S103' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S104' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012024' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014570' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006374' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002064' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007531' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004008' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S111' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002017' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S113' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S114' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002090' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001009' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S117' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006367' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S119' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S120' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S121' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006370' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007564' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S124' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014596' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S126' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006362' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S128' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S129' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005079' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002019' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S132' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006331' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006375' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012078' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005035' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S137' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004011' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S139' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W014586' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004085' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005018' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004049' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W050102' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006324' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S146' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006359' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S148' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002023' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004040' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004012' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S152' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S153' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002024' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005081' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001057' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S157' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S158' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005077' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005022' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S161' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S162' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012017' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005053' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S165' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S166' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S167' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S168' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S169' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006379' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W006369' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001016' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005080' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005033' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002073' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S176' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002093' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W012020' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004047' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W-S180' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S181' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'MANAGER' WHERE code = 'W014587' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004021' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W001053' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W005082' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S186' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W002003' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W005028' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W007526' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S190' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'W-S191' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S192' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W-S193' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;
UPDATE worker SET role = 'CASHIER' WHERE code = 'W004026' AND company_id = (SELECT id FROM company WHERE code = 'EBC') AND is_active = true;

-- 3. worker_role_assignment (V57 RBAC operativ szerepkorok)
DELETE FROM worker_role_assignment WHERE worker_id IN
  (SELECT id FROM worker WHERE company_id = (SELECT id FROM company WHERE code = 'EBC'));

-- Legacy seed RBAC
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code IN ('BORSI','BALI','KASZA') AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC')
ON CONFLICT DO NOTHING;

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'KOSA' AND r.code = 'DIRECTOR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC')
ON CONFLICT DO NOTHING;

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S001' AND r.code = 'REGIONAL_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, false FROM worker w, worker_role_def r
WHERE w.code = 'W-S001' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007570' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014517' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006376' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014519' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S006' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007551' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S008' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007532' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005043' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S011' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S012' AND r.code = 'CHIEF_VAULT'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S013' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S014' AND r.code = 'AUDITOR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S015' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S016' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S017' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014565' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005004' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014594' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005074' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S022' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S023' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005070' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012003' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006305' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S027' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S028' AND r.code = 'OFFICE_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014588' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S030' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S031' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S032' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S033' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007530' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012006' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S036' AND r.code = 'AUDITOR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, false FROM worker w, worker_role_def r
WHERE w.code = 'W-S036' AND r.code = 'REGIONAL_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006307' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S038' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S039' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S040' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S041' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014550' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007515' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005006' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S045' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S047' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S048' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014592' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001058' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005054' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006340' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S053' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014090' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S055' AND r.code = 'OFFICE_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S056' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004024' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S058' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S059' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012008' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S062' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012052' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012076' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S065' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S066' AND r.code = 'REGIONAL_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006313' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S068' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004084' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, false FROM worker w, worker_role_def r
WHERE w.code = 'W004084' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001036' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006366' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S072' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S073' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S074' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S075' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012077' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006316' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014503' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S079' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S080' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S081' AND r.code = 'OFFICE_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002085' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S083' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005062' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S085' AND r.code = 'CHIEF_VAULT'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S086' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001055' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005009' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S089' AND r.code = 'REGIONAL_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S090' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S091' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S092' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001045' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S094' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S095' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S096' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S097' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006368' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006319' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S100' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S101' AND r.code = 'DIRECTOR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001054' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S103' AND r.code = 'REGIONAL_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S104' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012024' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014570' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006374' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002064' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007531' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004008' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S111' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002017' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S113' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S114' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002090' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001009' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S117' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006367' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S119' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S120' AND r.code = 'SECURITY'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S121' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006370' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007564' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S124' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014596' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S126' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006362' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S128' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S129' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005079' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002019' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S132' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006331' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006375' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012078' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005035' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S137' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004011' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014586' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004085' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005018' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004049' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W050102' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006324' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S146' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006359' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S148' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002023' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004040' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004012' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S152' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S153' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002024' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005081' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001057' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S157' AND r.code = 'OFFICE_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S158' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005077' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005022' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S161' AND r.code = 'OFFICE_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S162' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012017' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005053' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S165' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S166' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S168' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S169' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006379' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W006369' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001016' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005080' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005033' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002073' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S176' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002093' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W012020' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004047' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S180' AND r.code = 'OFFICE_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W014587' AND r.code = 'REGIONAL_MGR'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, false FROM worker w, worker_role_def r
WHERE w.code = 'W014587' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004021' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W001053' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005082' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S186' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W002003' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W005028' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, false FROM worker w, worker_role_def r
WHERE w.code = 'W005028' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W007526' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S190' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S191' AND r.code = 'VAULT_KEEPER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W-S193' AND r.code = 'COURIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'W004026' AND r.code = 'CASHIER'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC') AND w.is_active = true
ON CONFLICT DO NOTHING;
