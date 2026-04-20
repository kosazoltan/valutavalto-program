# Valutavalto ERP - Komplex Rendszer Architektura

## Hogyan mukodik egyben a harom komponens

```
+-------------------------------+        +------------------------------+
|  packages/shared-api          |        |  packages/shared-ipc         |
|  (Backend -> TS tipusok)      |        |  (Electron IPC kontraktus)   |
|  +-------------------+        |        |  +----------------------+    |
|  | openapi.d.ts      |        |        |  | IpcRoutes table      |    |
|  | (37460 sor,       |<---+---|        |  | setup:save,          |    |
|  |  746 path,        |    |   |        |  | setup:test-conn,...  |    |
|  |  431 schema)      |    |   |        |  +----------+-----------+    |
|  +-------+-----------+    |   |        |             |                |
|          ^                |   |        |             |                |
+----------|----------------+   |        +-------------|----------------+
           |                    |                      |
   npm run typegen              |                      |
           |                    |                      |
+----------|----------------+   |   +------------------|-----------------+
|  Spring Boot Backend      |   |   |  Electron penztar-client           |
|  (backend/)               |   |   |  (penztar-client/)                 |
|  +-----------------+      |   +-->|  +---------------+                 |
|  | Controllers     |      |       |  | main process  |<-- registers    |
|  | 113 db          |      |       |  | preload.ts    |    IPC handlers |
|  | Entities 165    |      |       |  | renderer      |    tipusosan    |
|  | Services 122    |      |       |  +---------------+                 |
|  +-----------------+      |       |  Electron 41                       |
|  springdoc-openapi        |       +-----------+-----------------------+
|  /api-docs                |                   |
+---------------------------+                   | loads URL http://localhost:3000
           ^                                    v
           | HTTP/REST    +---------------------+-----------------------+
           +--------------|  frontend-react                              |
                          |  (frontend-react/)                           |
                          |  React 19, Vite 8, TypeScript                |
                          |  +-----------------------------+             |
                          |  | import type { components }  |             |
                          |  |   from '@valuta/shared-api' |             |
                          |  | import type { IpcRoutes }   |             |
                          |  |   from '@valuta/shared-ipc' |             |
                          |  +-----------------------------+             |
                          +----------------------------------------------+
```

## Egy paranccsal az egesz indul

```bash
npm run dev:all
```

Indit (szines concurrently output-tal):
1. **db**: PostgreSQL 16 docker container (5432) - a data reteg
2. **backend**: Spring Boot (mvnw spring-boot:run) - var a DB-re `wait-on tcp:5432`
3. **frontend**: Vite dev server (3000) - var a backend-re `wait-on /api/v1/auth/bootstrap-status`
4. **electron**: penztar-client app - var a Vite-ra `wait-on http://localhost:3000`

Minden komponens a masikra vár (wait-on), szóval egyszeri `Ctrl+C` mindegyiket leállítja.

## Tipusos szerzodes ket iranyban

### Backend -> Frontend (REST)
- Forras: Spring Boot `springdoc-openapi` runtime-ban publikalja a spec-et a `/api-docs`-on
- Generator: `npm run typegen` (scripts/typegen.mjs) lekeri JWT-vel, `openapi-typescript` TS-sé konvertálja
- Output: `packages/shared-api/src/openapi.d.ts` (37k sor, 746 endpoint)
- Hasznalat:
  ```typescript
  import type { components } from '@valuta/shared-api'
  type Worker = components['schemas']['WorkerDto']
  ```

### Electron main <-> renderer (IPC)
- Forras: `packages/shared-ipc/src/index.ts` - `IpcRoutes` tabla
- Mindket oldal (main/preload + renderer) ugyanabbol az interface-bol dolgozik
- A channel nevek (`setup:save`, stb.) `IPC_CHANNELS` konstansban
- Hasznalat:
  ```typescript
  import type { IpcRoutes, IpcResponse } from '@valuta/shared-ipc'
  import { IPC_CHANNELS } from '@valuta/shared-ipc'

  // Main:
  ipcMain.handle(IPC_CHANNELS.SETUP_SAVE, (_, req) => {...})

  // Renderer:
  const res: IpcResponse<'setup:save'> =
      await window.electronAPI.setupSave(payload)
  ```

## Development workflow

```bash
# Teljes stack
npm run dev:all

# Csak backend (gyors)
npm run dev:backend-only

# Csak frontend (mock DB)
npm run dev:frontend-only

# Friss TS types backendböl
npm run typegen

# Tesztek
npm test              # frontend + penztar unit
npm run test:backend  # JUnit 5 integration
npm run test:e2e      # Playwright
npm run typecheck     # mindket TS projekt
```

## CI-integracio

A GitHub Actions (`deploy-hetzner.yml`) a backend build-et csinalja es deployol a Hetzner VPS-re (excvaluta.com). A frontend-e2e.yml a Playwright-ot futtatja PR-ra.

Javasolt meg:
- `typegen` step a CI-ban (ha a backend OpenAPI valtozik, regeneralja a TS-t - ha tsc buka, PR blokkolt)
- `packages/shared-api/src/openapi.d.ts` committed a git-be (stabilitasra)
