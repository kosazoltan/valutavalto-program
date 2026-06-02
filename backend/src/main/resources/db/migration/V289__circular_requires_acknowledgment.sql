-- V289: Körlevél kötelező-nyugtázás flag (A4 — b9-korlevelek FR-02, 2026-06-02 EXCMD újra-audit)
--
-- A Pmt. szerint bizonyos körleveleket a pénztárosnak nyugtáznia kell, mielőtt tranzaktálhat.
-- Ez az oszlop jelöli a KÖTELEZŐ-nyugtázandó körleveleket. A tényleges tranzakció-blokkolást a
-- CIRCULAR_ACK_BLOCKING_ENFORCEMENT feature-flag vezérli (default false = nem blokkol — production-
-- biztos; a TransactionService.performAmlCheck csak bekapcsolt flag mellett kérdezi le és blokkol).
--
-- Idempotens: ADD COLUMN IF NOT EXISTS, NOT NULL DEFAULT false (a meglévő körlevelek nem blokkolnak).

ALTER TABLE circular ADD COLUMN IF NOT EXISTS requires_acknowledgment BOOLEAN NOT NULL DEFAULT false;
