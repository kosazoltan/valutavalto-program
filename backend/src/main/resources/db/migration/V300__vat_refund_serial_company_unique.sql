-- V300 (sztornó-audit): ÁFA-visszatérítés sorszám CÉGSZINTŰ egyedisége.
--
-- A korábbi generátor egy statikus AtomicLong-ot használt (System.currentTimeMillis() % 100000 seed),
-- ami backend-újraindításkor azonos napon ÚJRA kezdte a számlálót, és cégfüggetlen volt → ugyanaz a
-- serial_number ütközhetett (azonos cégen belül és cégek között is). A serial_number-en eddig NEM volt
-- semmilyen egyediség-megszorítás. Ez a migráció:
--   1) de-duplikálja a meglévő, azonos (company_id, serial_number) párokat (a legkisebb id marad,
--      a többi -DUP<id> suffixet kap — így visszakövethető marad, de egyedi lesz);
--   2) (company_id, serial_number) COMPOSITE UNIQUE indexet tesz rá, ami a jövőbeni cégszintű,
--      DB-alapú MAX+1 sorszámgenerálás race-backstopja (két cég azonos sorszáma megengedett).
-- Idempotens.

UPDATE vat_refund_transaction t
   SET serial_number = t.serial_number || '-DUP' || t.id
 WHERE EXISTS (
   SELECT 1 FROM vat_refund_transaction t2
    WHERE t2.company_id = t.company_id
      AND t2.serial_number = t.serial_number
      AND t2.id < t.id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_vat_refund_company_serial
    ON vat_refund_transaction (company_id, serial_number);
