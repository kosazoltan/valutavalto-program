# MCP Docker Kovetelmenyek (Runtime + Fejlesztes)

Datum: 2026-03-14

## 1) Fontos kulonbseg

- Az alkalmazas futasahoz (backend + frontend + postgres) **nem kotelezo egyetlen MCP server sem**.
- Az MCP-k a fejlesztesi/uzemeltetesi automatizalas es AI-asszisztalt munka miatt kellenek.

## 2) Kotelezo runtime komponensek (MCP nelkul is)

- Docker Desktop / Docker Engine fut
- `docker compose` elerheto
- `postgres` service fut (`docker-compose.yml` alapjan)
- (opcionalis) `pgadmin` service

## 3) Minimum MCP keszlet Dockeres fejleszteshez

Az alabbi MCP szerverek telepitese javasolt a zokkenomentes fejleszteshez:

1. `filesystem` MCP
   - Cel: repo fajlok olvasasa/szerkesztese kontenerbol
   - Miert kell: kodmodositas, config frissites, dokumentalas

2. `terminal/shell` MCP
   - Cel: build, teszt, lint, script futtatas
   - Miert kell: Maven, npm, Docker parancsok automatizalasa

3. `git` MCP
   - Cel: diff, status, branch, commit workflow
   - Miert kell: valtozasok kovetese es review

4. `postgres` MCP
   - Cel: DB schema/tabla/adat ellenorzes, query futtatas
   - Miert kell: Flyway utani validacio, gyors hibakereses

5. `docker` MCP
   - Cel: kontener allapot, logok, restart, health check
   - Miert kell: lokalis futasi problemak gyors diagnosztikaja

6. `fetch/http` MCP
   - Cel: endpoint health/Smoke check, API validacio
   - Miert kell: `http://localhost:8080` gyors elerhetoseg ellenorzes

## 4) Erosen ajanlott MCP-k (nem kotelezo)

1. `playwright` MCP
   - Frontend/Electron UI smoke es regresszios ellenorzes

2. `github` MCP
   - PR/issue workflow, review kommentek, CI allapot

## 5) Kotelezo futtatasi inputok az MCP-khez

- Workspace mount: `d:/repo/valutavalto-program` (read/write)
- Docker socket/daemon eleres
- Postgres kapcsolat:
  - host: `localhost`
  - port: `5432`
  - db: `valuta`
  - user: `valuta_user`
  - password: `valuta_pass`
- Java: JDK 21 (ajanlott: `C:/Program Files/Eclipse Adoptium/jdk-21.0.10.7-hotspot`)

## 6) Gyors ellenorzo lista (DoD)

- `docker compose ps` -> `valuta-postgres` Up
- backend health -> `GET /api/v1/health` status `UP`
- Maven compile + celzott tesztek sikeresek
- filesystem + terminal + postgres + docker MCP-ek aktivak

## 7) Megjegyzes

Ha csak az alkalmazast futtatjuk (AI nelkul), MCP telepites nem blocker.
Ha AI-asszisztalt fejlesztes a cel, a fenti minimum MCP keszletet runtime kovetelmenykent kell kezelni.

## 8) Kesz Compose minta

- Fajl: `docker-compose.mcp.yml`
- A minta jelenleg ezeket a csomagokat hasznalja:
   - `mcp-git` -> `@cyanheads/git-mcp-server`
   - `mcp-fetch` -> `@mokei/mcp-fetch`

Inditas (minimum MCP set + app compose):

```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml up -d
```

Inditas optional MCP-kel (shell + docker):

```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml --profile optional-mcp up -d
```

Leallitas:

```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml down
```
