-- V267: Konverzió visszajáró forint (HIBA 2026-05-26, Fabulya Zsuzsanna)
--
-- A konverziónál ha a pénztáros a cél valuta összegét lefelé módosítja (címletezés),
-- a fennmaradó forint-fedezetet KÉSZPÉNZBEN vissza kell adni az ügyfélnek, és fel kell
-- tüntetni a bizonylaton. A visszajáró HUF a parent CONVERSION sorra kerül.
--
-- Idempotens (IF NOT EXISTS), DEFAULT 0 a meglévő sorokra.
ALTER TABLE transaction
    ADD COLUMN IF NOT EXISTS returned_huf NUMERIC(18, 2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN transaction.returned_huf IS
    'Konverziónál a cél-összeg lefelé kerekítéséből adódó, készpénzben visszaadott forint (visszajáró).';
