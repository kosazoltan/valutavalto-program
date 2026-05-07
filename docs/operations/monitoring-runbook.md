# Production Monitoring runbook — Valutaváltó ERP

> **Hatókör:** `excvaluta.com` (Hetzner production).
> **Célközönség:** rendszergazdák, on-call fejlesztők, DPO.
> **Utolsó frissítés:** 2026-05-06.
> **Kapcsolódó:** `dr-backup-runbook.md` (DR), `compliance-audit-checklist.md` (compliance).

---

## 1. Mit kell monitorozni — KPI lista

| KPI | Cél | Forrás | Alert szint |
|---|---|---|---|
| `bootstrap-status` HTTP 200 uptime | ≥ 99.5% / hó | `https://excvaluta.com/api/v1/auth/bootstrap-status` | **P0**: >5 perc DOWN |
| Backend p99 latency | ≤ 2000 ms | Actuator `/actuator/metrics/http.server.requests` (loopback) | **P1**: p99 > 2 s 5 perc tartósan |
| Backend error rate (5xx) | < 1% / 5 perc | actuator + Caddy log | **P0**: > 5 hiba/perc 3 percig |
| `client_error_log` insert rate | < 10 / óra steady | PostgreSQL `client_error_log` tábla | **P1**: > 30 / óra (egy gépről > 5 / óra is gyanús) |
| GitHub auto-issue create rate | < 3 / nap | `gh issue list -l client-error` | **P1**: > 5 / nap egyazon issue-ra dedup után |
| AML overdue reports | 0 | `aml_report.status='OVERDUE'` | **P0**: bármelyik megjelenése |
| Audit log hash-chain breaks | 0 | `audit_log.entry_hash NULL` count vagy chain mismatch | **P0** (compliance — bármelyik) |
| PostgreSQL connections | < 80% pool | HikariCP metrics (max=40, `application-production.properties:38`) | **P1**: > 32 aktív tartósan |
| Disk space (Hetzner VPS) | > 20% szabad | `df -h /` | **P1**: < 20% / **P0**: < 5% |
| Daily backup success | minden nap zöld | `valuta-pg-backup.sh` exit code | **P0**: > 24 óra óta nincs új dump |

---

## 2. Jelenlegi monitoring komponensek (tényszerű állapot)

### 2.1 Beépített komponensek a kódban

| Komponens | Típus | Aktív? | Forrás |
|---|---|---|---|
| `/actuator/health` | Spring Boot Actuator | **IGEN**, loopback only | `application-production.properties:120-123` |
| `/actuator/prometheus` | Micrometer Prometheus export | **IGEN**, loopback only | `application-production.properties:124` `management.prometheus.metrics.export.enabled=true` |
| `/actuator/metrics`, `/actuator/info` | Actuator | **IGEN**, loopback only | `application-production.properties:121` |
| `DiagnosticsController` `/api/v1/diagnostics/error-report` | egyedi Sentry-szerű ingest endpoint | **IGEN**, public + rate-limited | `backend/.../controller/DiagnosticsController.java` |
| `client_error_log` tábla | client-side error storage | **IGEN**, V182 migration alkalmazva | `backend/.../db/migration/V182__client_error_log_table.sql` |
| `GitHubIssueAutoCreator` | kritikus minta esetén GitHub Issue | **opcionális** (env: `GITHUB_ISSUE_AUTO_CREATE_ENABLED`) | `application-production.properties:109-111` |
| `AmlService.checkAndMarkOverdueReports()` | naponta futó AML overdue scheduler | **IGEN** (`@Scheduled`) | `backend/.../service/AmlService.java:786` |
| Caddy access log | TLS + reverse proxy | **VERIFY** SSH-val (`/var/log/caddy/access.log`) | reverse-proxy frontend |
| Mail health indicator | actuator mail health check | **KIKAPCSOLVA** (SMTP nem mindig elérhető) | `application-production.properties:126` |

### 2.2 Ami NINCS a kódban (gap-elemzés)

| Tétel | Állapot | Megjegyzés |
|---|---|---|
| **Sentry SDK integráció** | **NINCS** | helyette saját `DiagnosticsController` + `client_error_log` |
| **Grafana / Prometheus deploy** | **COMMITTED / VERIFY DEPLOY** | `deploy/hetzner/monitoring/docker-compose.monitoring.yml` + provisioned config |
| **Dedicated alert manager** (Alertmanager / Telegram) | **COMMITTED / VERIFY DEPLOY** | Alertmanager config a monitoring stack része; élő Telegram bot token + `TELEGRAM_CHAT_ID` ellenőrizendő |
| **Uptime monitor külső szolgáltatás** (UptimeRobot / Better Uptime) | **VERIFY** | repoban nincs nyom — DNS/Cloudflare szinten esetleg |
| **APM / distributed tracing** | **NINCS** | nem releváns single-node deploymentnél |

> **Bizonyíték:** a `DiagnosticsController:130-138` kommentje magyarázza a Jackson 3 dual-stack fallback-et — ez **saját egyedi fejlesztés**, NEM Sentry, NEM Loki. Az iparági standard "Sentry data model + Loki structured-logs" csak inspiráció a kódkommentben (`V182:9`).

---

## 3. Alerting küszöbök

### 3.1 P0 — kritikus, azonnali on-call action

| Esemény | Detekció | Szükséges válasz |
|---|---|---|
| `bootstrap-status` DOWN > 5 perc | külső uptime monitor (UptimeRobot ajánlott — **GAP**) | Hetzner status check + restart workflow (4. szakasz) |
| 5xx error rate > 5/perc 3 percig | Caddy access log + actuator | runbook 4. szakasz, root cause analysis |
| AML report `OVERDUE` megjelenik | naponta SQL: `SELECT COUNT(*) FROM aml_report WHERE status='OVERDUE'` | DPO értesítés + manuális hatósági bejelentés (Pmt. 33.§ 2 munkanap) |
| Audit log hash-lánc törés | naponta SQL (lásd `dr-backup-runbook.md` 4.4) | **compliance incident** — DPO + külső audit |
| Disk usage > 95% | `df -h /` cron alert | log rotate / régi dumpok törlése |

### 3.2 P1 — warning, üzemórában válasz

| Esemény | Detekció | Szükséges válasz |
|---|---|---|
| p99 latency > 2 s 5 percig | Prometheus query | DB slow query log review |
| `client_error_log` > 30 / óra | SQL count query | top component szerinti elemzés (5. szakasz) |
| HikariCP active conns > 32 | actuator metrics | connection leak vizsgálat, pool resize |
| Backup nem futott le 24 órája | Storage Box mtime | DR runbook 2.2 szerint kézi futtatás |

### 3.3 P2 — informatív, hetente review

- Top 10 leggyakoribb `client_error_log` minta.
- Új AML `STANDARD` / `ENHANCED` / `SUSPICIOUS` bejelentések napi átlaga.
- Worker login fail rate (SecurityEventek).

---

## 4. Hol nézhetők a metrikák jelenleg

### 4.1 Backend health (loopback only)

```bash
# SSH a Hetzner VPS-re
ssh root@<hetzner-host>

# Health
curl -s http://127.0.0.1:9090/actuator/health | jq

# Prometheus metrikák raw
curl -s http://127.0.0.1:9090/actuator/prometheus | head -50

# HikariCP pool status
curl -s "http://127.0.0.1:9090/actuator/metrics/hikaricp.connections.active" | jq
curl -s "http://127.0.0.1:9090/actuator/metrics/hikaricp.connections.idle" | jq

# HTTP request stats
curl -s "http://127.0.0.1:9090/actuator/metrics/http.server.requests" | jq
```

> **Fontos:** production-ban a management endpoint **localhost-only** (`management.server.address=127.0.0.1`, `application-production.properties:120`) — szándékosan, hogy publikus internet felől NE legyen kiolvasható (`/actuator/env` szenzitív lehet).

### 4.2 Client error log (PostgreSQL, SSH-val)

```bash
# Top 20 legfrissebb hiba
sudo -u postgres psql -d valuta -c "
  SELECT created_at, component, version, user_identifier,
         LEFT(error_message, 100) AS msg_preview
  FROM client_error_log
  ORDER BY created_at DESC
  LIMIT 20;
"

# Top 10 leggyakoribb hibaminta (24 óra)
sudo -u postgres psql -d valuta -c "
  SELECT component, version,
         LEFT(error_message, 80) AS pattern,
         COUNT(*) AS occurrences,
         COUNT(DISTINCT user_identifier) AS affected_users
  FROM client_error_log
  WHERE created_at > NOW() - INTERVAL '24 hours'
  GROUP BY component, version, LEFT(error_message, 80)
  ORDER BY occurrences DESC
  LIMIT 10;
"
```

### 4.3 GitHub auto-issue feed

```bash
# Locally:
gh issue list -R kosazoltan/valutavalto-program -l client-error --state open

# Egy konkrét hibaminta keresése:
gh issue list -R kosazoltan/valutavalto-program -l client-error \
  --search "in:title Network Error"
```

A `GitHubIssueAutoCreator` dedup-ot tartalmaz (`backend/.../service/GitHubIssueAutoCreator.java:84` `dedup match - skip`), így ugyanaz a hibaminta nem hoz létre duplikált issue-t — ezért az issue szám az **egyedi minták** számára proxy.

### 4.4 Caddy access log

```bash
# 5xx response-ok az utolsó órában
ssh root@<hetzner-host> \
  "grep 'status\":5' /var/log/caddy/access.log \
   | tail -100 | jq -c '{ts, status, request: .request.uri}'"
```

---

## 5. Heti error log review (P2 ütem)

Minden hétfő 09:00-kor (vagy legalább hetente egyszer):

```bash
# Top 10 leggyakoribb hiba (utolsó 7 nap)
sudo -u postgres psql -d valuta -c "
  SELECT component, LEFT(error_message, 100) AS pattern,
         COUNT(*) AS occurrences,
         COUNT(DISTINCT user_identifier) AS affected_users,
         MIN(created_at) AS first_seen,
         MAX(created_at) AS last_seen
  FROM client_error_log
  WHERE created_at > NOW() - INTERVAL '7 days'
  GROUP BY component, LEFT(error_message, 100)
  ORDER BY occurrences DESC
  LIMIT 10;
"
```

A `D:\valutavalto-vault\sessions\YYYY-MM-DD-error-review.md` fájlba dokumentálni a top patterneket + javítási tervet (ha P0/P1, azonnali fix az egész code review mandate (CLAUDE.md "AI Review Zero-Tolerance Mandate") szerint).

**Cleanup:** 90 nap után automatikus törlés (`V182__client_error_log_table.sql:58` COMMENT). A repo tartalmaz systemd timer-t:

- `deploy/hetzner/scripts/setup-client-error-cleanup.sh`
- `deploy/hetzner/scripts/cleanup-client-error-log.sh`
- `deploy/hetzner/systemd/valuta-client-error-cleanup.service`
- `deploy/hetzner/systemd/valuta-client-error-cleanup.timer`

Telepítés után verifikáció:

```bash
sudo systemctl list-timers valuta-client-error-cleanup.timer
sudo systemctl start valuta-client-error-cleanup.service
sudo journalctl -u valuta-client-error-cleanup -n 20 --no-pager
```

---

## 6. Új monitoring dashboard javaslat (Grafana + Prometheus)

### 6.1 Indoklás

A backend **már exportál Prometheus metrikákat** (`management.prometheus.metrics.export.enabled=true`, `application-production.properties:124`). Csak a scrape + dashboard hiányzik.

### 6.2 Deploy lépések

```bash
# 1. Prometheus telepítése (Docker Compose, ugyanazon a Hetzner VPS-en)
mkdir -p /opt/monitoring && cd /opt/monitoring

cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    ports:
      - "127.0.0.1:9091:9090"   # csak loopback — Caddy reverse proxy-zza
    restart: unless-stopped

  grafana:
    image: grafana/grafana-oss:latest
    depends_on: [prometheus]
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASS}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "127.0.0.1:3001:3000"   # Caddy: monitoring.excvaluta.com -> 3001
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
EOF

# 2. Prometheus scrape config — a backend loopback actuator-ja
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
  - job_name: 'valuta-backend'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['host.docker.internal:9090']  # Linux: 172.17.0.1:9090 vagy network_mode: host
EOF

# 3. Caddy reverse proxy a Grafana elé (HTTPS + basic auth + Cloudflare Access ajánlott)
# /etc/caddy/Caddyfile -ben:
# monitoring.excvaluta.com {
#   reverse_proxy 127.0.0.1:3001
#   basicauth { admin <bcrypt-hash> }
# }

# 4. Indítás
docker compose up -d

# 5. Grafana dashboard import: ID 4701 (JVM (Micrometer)) + 11378 (Spring Boot 2.x Statistics)
```

### 6.3 Alerting

Iparági standard Alertmanager helyett a **GitHub Issue auto-create** jelenleg részben kiváltja:

- **GitHubIssueAutoCreator** kliens-oldali kritikus hibákra (`uncaughtException`, `Network Error`, setup wizard fail) — `backend/.../service/GitHubIssueAutoCreator.java:24`.
- **Server-oldalra** Grafana Alerting (built-in) ajánlott — webhook-on keresztül szintén GitHub Issue-t nyithat egységes flow-ban.

**Sentry-alternatíva:** a saját DiagnosticsController + GitHub Issue eskaláció a kliens-oldali hibákat **lefedi**. Server-oldali strukturált hibalogot Grafana/Loki képes pótolni — de ez nem P0, mert az `audit_log` tábla a kritikus üzleti eseményeket eleve tartalmazza (`AuditLogService.logSecurityEvent()`).

---

## 7. Runbook: "szerver elérhetetlen" jelzés

A kollégától / monitortól érkező "nem érem el az `excvaluta.com`-ot" report esetén az alábbi sorrendben:

### 7.1 Külső reachability

```bash
# 1. DNS
dig +short excvaluta.com
dig +short www.excvaluta.com
# Elvárt: ugyanaz az IP, ami a Hetzner instance-é

# 2. Hetzner status page
# https://status.hetzner.com/  -> ellenőrizd a régiót (Falkenstein / Helsinki / Nuremberg)

# 3. Cloudflare status
# https://www.cloudflarestatus.com/

# 4. HTTPS reachability külső pontról
curl -sI https://excvaluta.com/api/v1/auth/bootstrap-status
# Elvárt: HTTP/2 200, vagy 401/403 ha auth kell — DE NEM connect-timeout
```

### 7.2 SSH-val a Hetzner VPS-en

```bash
# 5. Backend service status
sudo systemctl status valuta-backend

# 6. Backend log (utolsó 200 sor)
sudo journalctl -u valuta-backend -n 200 --no-pager

# 7. Caddy státusz
sudo systemctl status caddy
sudo journalctl -u caddy -n 100 --no-pager

# 8. PostgreSQL státusz
sudo systemctl status postgresql
sudo -u postgres pg_isready -h localhost

# 9. Health endpoint loopback
curl -s http://127.0.0.1:9090/actuator/health | jq
```

### 7.3 Restart eljárás (defenzív)

```bash
# Ha a 7.2 alapján a backend nem felel:
sudo systemctl restart valuta-backend
sleep 30
curl -s http://127.0.0.1:9090/actuator/health | jq

# Ha a Caddy a probléma:
sudo systemctl restart caddy

# Ha a DB:
# CSAK ha biztos vagy benne, hogy nincs futó tranzakció — különben pool starvation
sudo systemctl restart postgresql
sudo systemctl restart valuta-backend   # backend kell az újra-poolinghoz
```

### 7.4 Eszkaláció

Ha 15 percen belül NEM zöld a smoke test (lásd `dr-backup-runbook.md` 4. szakasz):
- **Failover scenario** (`dr-backup-runbook.md` 6. szakasz).
- **Incident report** a vault-ba: `D:\valutavalto-vault\sessions\YYYY-MM-DD-incident-<rovid-leiras>.md`.
- **Kollégák értesítése** a 9. szakasz sablonjával.

---

## 8. Fő hivatkozások

- `backend/src/main/resources/application-production.properties:117-126` — Actuator + management port konfiguráció.
- `backend/src/main/resources/application.properties:97-104` — dev Actuator (port 9090, 0.0.0.0).
- `backend/src/main/java/hu/puzzleir/valuta/controller/DiagnosticsController.java` — kliens hibajelentés ingest.
- `backend/src/main/java/hu/puzzleir/valuta/service/GitHubIssueAutoCreator.java` — kritikus minta GitHub Issue auto-create.
- `backend/src/main/resources/db/migration/V182__client_error_log_table.sql` — error log tábla DDL + 90 napos retention comment.
- `backend/src/main/java/hu/puzzleir/valuta/service/AuditLogService.java:135` — hash-lánc tamper-evidence.
- `config/production-urls.json` — production URL SSOT.
- `D:\valutavalto-vault\feedback\session-closing-protocol-mandatory.md` — 9 lépéses session-zárás (push utáni külső monitor visszaolvasás kötelező).
- `CLAUDE.md` "AI Review Zero-Tolerance Mandate" — minden P0/P1 azonnal javítandó.

**Gap-list (P0 / P1 / P2):**

| Gap | Prioritás | Javasolt fix |
|---|---|---|
| Külső uptime monitor (`bootstrap-status` ping) | P0 | UptimeRobot / Better Uptime, 1 perces interval |
| Grafana + Prometheus deploy élő verifikáció | P1 | `deploy/hetzner/bootstrap-vps.sh` monitoring lépés + Grafana login/scrape check |
| `client_error_log` 90 napos cleanup timer élő verifikáció | P1 | `sudo systemctl list-timers valuta-client-error-cleanup.timer` |
| Caddy access log retention + rotate | P2 | logrotate config |
| HikariCP exhausted alert | P2 | Grafana alert rule + GitHub Issue webhook |
| AML overdue daily SQL alert | P0 | naponta 08:00 cron + ha COUNT > 0 → email DPO |

**Lezárás:** a backend Prometheus metrikákat **már most exportálja** — a hiányzó réteg a scrape + dashboard + alerting. A kliens-oldali hibajelentés saját megoldással (DiagnosticsController + V182 + GitHub auto-issue) **lefedett**, Sentry NEM szükséges.
