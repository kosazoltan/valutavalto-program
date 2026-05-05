-- =====================================================================
-- V182: client_error_log tábla — kliens-oldali hibajelentések fogadása
-- =====================================================================
-- 2026-05-05 user-direktíva: a kollégák gépén történő hibákat (Penztar.exe
-- uncaught exception, renderer JS error, NSIS install fail, axios 4xx/5xx)
-- AUTOMATIKUSAN a backend endpoint-jára küldjük HTTPS POST-tal, és itt
-- tároljuk PostgreSQL-ben. A fejlesztő (Kosa Zoltan) SSH-val bármikor
-- lekérdezheti, NEM kell a kollégákhoz manuális debug-utasítást küldeni.
--
-- Iparági standard inspiráció: Sentry data model + Loki structured-logs.

CREATE TABLE IF NOT EXISTS client_error_log (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- A hiba forrása: 'electron-main' | 'electron-renderer' | 'nsis-installer' | 'axios-http'
    component VARCHAR(80) NOT NULL,

    -- Penztar / Setup verziója (pl. '2.5.13')
    version VARCHAR(40),

    -- Operációs rendszer build (pl. 'Windows 11 Pro 10.0.26200')
    os_info VARCHAR(200),

    -- Felhasználó-azonosító (Google email / worker code) — ha elérhető
    user_identifier VARCHAR(150),

    -- A hiba rövid üzenete (max 1000 char a tárolásra)
    error_message VARCHAR(1000) NOT NULL,

    -- Teljes stack trace (max 8000 char)
    stack_trace TEXT,

    -- Strukturált kontextus JSONB (URL, HTTP-status, branch_code, install_mode, stb.)
    context JSONB,

    -- A kliens IP-je (audit + rate-limiting)
    client_ip INET,

    -- A user-agent (Penztar.exe Electron, vagy curl, vagy másmi)
    user_agent VARCHAR(300)
);

-- Index a leggyakoribb lekérdezésre (legfrissebb hibák először)
CREATE INDEX IF NOT EXISTS idx_client_error_log_created_at
    ON client_error_log(created_at DESC);

-- Index komponens szerinti szűréshez
CREATE INDEX IF NOT EXISTS idx_client_error_log_component
    ON client_error_log(component);

-- Index user-identifier szerint (egy adott kolléga gépén történő hibák)
CREATE INDEX IF NOT EXISTS idx_client_error_log_user_identifier
    ON client_error_log(user_identifier)
    WHERE user_identifier IS NOT NULL;

-- TTL-szerű cleanup: 90 nap után törlés (külön cron-job feladata)
COMMENT ON TABLE client_error_log IS
    'Kliens-oldali hibajelentések. Retention: 90 nap (cron-job: DELETE FROM client_error_log WHERE created_at < NOW() - INTERVAL ''90 days'').';
