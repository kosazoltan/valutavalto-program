-- V363: FK-065 (Codex HIGH) — optimista lock (@Version) a closing_wizard táblán
--
-- Tényalap:
--  * A scheduler-oldali auto-lejárat (transitionIfStale) atomikus, feltételes UPDATE,
--    de a user-facing írási utak (finalizeClosing/cancel/navigate/complete) sima
--    save()-vel írtak — a két oldal versenyét eddig csak a scheduler-oldal védte.
--  * A @Version mező mindkét irányban lezárja a versenyt: az elavult példányra
--    történő írás OptimisticLock-konfliktust ad (409, "frissítsd az oldalt").
--
-- Idempotens: ADD COLUMN IF NOT EXISTS, default 0, NOT NULL (a meglévő sorok 0-t kapnak).

ALTER TABLE closing_wizard
    ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
