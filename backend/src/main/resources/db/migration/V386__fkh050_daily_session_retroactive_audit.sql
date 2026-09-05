-- =====================================================================
-- FKH-050 / V386 — daily_session: retroactive closing audit columns
-- =====================================================================
-- Retroactive (utolagos) napzaras: a user lezárhat egy korabbi, nem CLOSED
-- napot. A zaras TENYET a daily_session soran rogzitjuk, de KULON a sima
-- zarasi mezoktol (closed_by_worker_id / closed_at), mert:
--   * is_retroactive_closing jeloli, hogy a nap nem a rendes napi zarassal
--     lett lezarva,
--   * retroactive_closed_by_worker_id = ki futtatta az utolagos zarast,
--   * retroactive_closed_at = MIKOR futtatta (vegrehajtasi ido) — ez
--     szerkezetileg kulonbozik a session_date-tol (FR-7).
-- IDEMPOTENS: minden oszlop IF NOT EXISTS-szel all be.
-- =====================================================================

ALTER TABLE daily_session
    ADD COLUMN IF NOT EXISTS is_retroactive_closing BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE daily_session
    ADD COLUMN IF NOT EXISTS retroactive_closed_by_worker_id BIGINT REFERENCES worker(id);

ALTER TABLE daily_session
    ADD COLUMN IF NOT EXISTS retroactive_closed_at TIMESTAMP;
