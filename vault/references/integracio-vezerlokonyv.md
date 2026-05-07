---
name: Integrációs vezérlőkönyv (Downloads/integracio-vezerlokonyv.md)
description: Teljes 96k-tokenes útmutató React+Spring Boot+Electron+Hetzner komplex rendszerhez; 43 szekció, 6 playbook, 50-pontos integrációs ellenőrzőlista, 15 AI stop-feltétel
type: reference
---

**Path:** `C:\Users\Kósa Zoltán\Downloads\integracio-vezerlokonyv.md` (5777 sor, 96k token)

**Verzió-célok:** React 19 / Vite 6 / Spring Boot 3.5 / Java 21 / Electron 31 / Node 22 / PostgreSQL 17 / Ubuntu 24.04

**Struktúra (főszekciók):**
- I. rész (1-6): Architektúra + topológia + env-strategy + verziómátrix
- II. rész (7-15): Kommunikáció — REST, WebSocket/STOMP, SSE, Electron IPC, JWT auth, offline queue
- III. rész (16-21): Build — Vite konfig, Maven multi-stage Dockerfile, electron-builder, Docker Compose prod stack, indítási sorrend, hot reload
- IV. rész (22-31): VPS — UFW/fail2ban/Docker, Caddy, PostgreSQL pg_dump+PITR+PgBouncer, Prometheus+Grafana+Loki+Alertmanager, CI/CD, electron-updater, security hardening, disaster recovery
- V. rész (32-37): 6 playbook (React+Spring csatlakoztatás, Electron burkolat, VPS deploy, monitoring setup, Electron release, disaster recovery)
- VI. rész (38-43): 50-pontos integrációs checklist, verziómátrix, port-mátrix, mappa-konvenciók, **15 stop-feltétel**, forráslista

**Amikor hívjam:**
- Új komponens/feature tervezésekor (milyen protokoll, milyen konfig)
- Infra-változáskor (deploy, monitoring, backup)
- Auth-kérdéseknél (JWT, refresh, CORS, CSRF)
- Ha a user kér konkrétan "vezérlőkönyv szerint" valamit
- Checklist 38. és stop-feltételek 42. mindig ellenőrizendő új deploynál

**Ajánlott helyes minták (ezeket preferálja a könyv):**
- Spring Boot: @RestControllerAdvice + ProblemDetail (RFC 7807), record-DTO-k, STATELESS session, BCrypt 12, Actuator port **9090 @ 127.0.0.1**, `management.endpoints.web.exposure.include: health,info,prometheus,metrics`
- Frontend: Axios instance + silent refresh interceptor, TanStack Query v5 (`staleTime: 60_000`, `retry: 3`, `networkMode: offlineFirst`), in-memory access token + HttpOnly refresh cookie (web) / safeStorage (Electron)
- Electron: contextBridge (nem direct ipcRenderer), `sandbox: true`, waitForBackend polling, better-sqlite3 outbox offline queue
- Infra: Docker Compose `depends_on: condition: service_healthy`, Docker secrets NEM .env, Caddy TLS auto, Redis JWT blacklist, PgBouncer transaction pool + `prepareThreshold: 0`, `internal: true` belső DB-network

**Dekompozíció az aktuális Valutavalto projekttel (2026-04-20 Gap):**
- Már megvan: Spring Boot 3.5.13 + Java 21 + React 19, JwtAuthenticationFilter, SecurityConfig, OpenAPI spec /api-docs, Hetzner VPS deploy (GitHub Actions), multi-tenant companyId, Flyway V1-V150, helyi SetupWizard, Vite proxy dev
- Hiányzik a könyv szerint: refresh token / silent refresh (csak rövid JWT), RFC 7807 ProblemDetail, Actuator külön port 127.0.0.1, TanStack Query, Docker Compose prod stack Caddyval, PgBouncer, Redis blacklist, Prometheus+Grafana+Loki monitoring, Alertmanager, electron-updater, Spring Boot DevTools, fail2ban+Tailscale SSH bastion, Unattended upgrades, Backblaze B2 backup (nálunk Nextcloud van)

**15 stop-feltétel (VI/42) — minden éles változtatás előtt nézendő:**
1. Ismeretlen domain/IP (ne guessel-j pelda.hu-t), 2. Hiányzó secret (ne találj ki JWT kulcsot), 3. Éles DB destructive (nincs auto DROP/DELETE), 4. Ütköző CORS origin, 5. Port ütközés, 6. Verzió-inkompatibilitás (2.x→3.x migráció nem triviális), 7. Hiányzó Docker image, 8. Electron code signing cert, 9. HCLOUD_TOKEN hiány, 10. SSH nem működik, 11. Healthcheck tartósan FAIL (5 percen túl), 12. JPA validate hiba (ne auto-update), 13. Let's Encrypt rate limit, 14. Idempotency-key UNIQUE violation, 15. Katasztrófa-helyreállítás bizonytalan backuppal
