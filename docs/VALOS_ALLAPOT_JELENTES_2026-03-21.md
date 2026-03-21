# Valós Állapot Jelentés (File-szintű)

Dátum: 2026-03-21
Módszer: csak olvasásos audit, kódmódosítás nélkül

## ✅ Ténylegesen kész (kódban bizonyított)

1. Kamera-tranzakció automatikus linkelés be van kötve a mentési folyamatba.
- [backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java](backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java#L240)
- [backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java](backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java#L380)
- [backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java](backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java#L632)

2. Kamera export hash-chain ellenőrzés backend és frontend oldalon is elérhető.
- [backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java#L102)
- [backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java#L107)
- [frontend-react/src/services/api.ts](frontend-react/src/services/api.ts#L3634)

3. Kamera feltöltés managed storage-be implementált.
- [backend/src/main/java/hu/puzzleir/valuta/service/CameraUploadService.java](backend/src/main/java/hu/puzzleir/valuta/service/CameraUploadService.java#L90)

4. Zárási folyamat legacy 16-lépéses struktúrája implementált.
- [backend/src/main/java/hu/puzzleir/valuta/service/ClosingWizardService.java](backend/src/main/java/hu/puzzleir/valuta/service/ClosingWizardService.java#L425)
- [backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java](backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java#L176)

## ❌ Késznek állítva, de ténylegesen nem kész (ellentmondás)

1. Túlzó globális készültségi állítás.
- Állítás: [REPO_STATE.md](REPO_STATE.md#L10)
- Ellentétes bizonyíték: [docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md](docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md#L345)
- Ellentétes bizonyíték: [docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md](docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md#L346)
- Ellentétes bizonyíték: [docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md](docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md#L350)

2. Darius „nem kell” állítás ütközik a kötelező scope-pal és a placeholder implementációval.
- Állítás: [REPO_STATE.md](REPO_STATE.md#L45)
- Kötelezőként definiálva: [docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md](docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md#L15)
- Kötelezőként definiálva: [docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md](docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md#L261)
- Kódbizonyíték (adapter placeholder): [backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java](backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java#L231)

3. „Nincs mock/simplified P0 folyamatban” állítás nem igaz.
- Állítás: [docs/AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md](docs/AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md#L230)
- Ellenbizonyíték: [backend/src/main/java/hu/puzzleir/valuta/service/FtpSyncService.java](backend/src/main/java/hu/puzzleir/valuta/service/FtpSyncService.java#L25)
- Ellenbizonyíték: [backend/src/main/java/hu/puzzleir/valuta/service/SynchronizationService.java](backend/src/main/java/hu/puzzleir/valuta/service/SynchronizationService.java#L30)

4. API route-kontraktus eltérések (frontend vs backend).
- Darius frontend útvonal: [frontend-react/src/services/api.ts](frontend-react/src/services/api.ts#L3605)
- Darius backend base: [backend/src/main/java/hu/puzzleir/valuta/controller/DariusReportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/DariusReportController.java#L23)
- Kamera export frontend base: [frontend-react/src/services/api.ts](frontend-react/src/services/api.ts#L3624)
- Kamera export backend base: [backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java#L27)
- Sync kliens hívás: [penztar-client/electron/sync-engine.ts](penztar-client/electron/sync-engine.ts#L927)
- Ezzel szemben backend endpoint: [backend/src/main/java/hu/puzzleir/valuta/controller/ErtektarController.java](backend/src/main/java/hu/puzzleir/valuta/controller/ErtektarController.java#L316)

## ⚠️ Részben kész, de nem lezárt

1. Darius state és outbox artifact létezik, de teljes külső transport nincs lezárva.
- [backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java](backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java#L272)
- [backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java](backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java#L289)

2. Kamera titkosítás/hash komponensek megvannak, de end-to-end bekötés nem bizonyított.
- [backend/src/main/java/hu/puzzleir/valuta/service/CameraEncryptionService.java](backend/src/main/java/hu/puzzleir/valuta/service/CameraEncryptionService.java#L57)
- [backend/src/main/java/hu/puzzleir/valuta/service/CameraHashChainService.java](backend/src/main/java/hu/puzzleir/valuta/service/CameraHashChainService.java#L56)
- [backend/src/main/java/hu/puzzleir/valuta/config/CameraProperties.java](backend/src/main/java/hu/puzzleir/valuta/config/CameraProperties.java#L31)

## Rövid végkövetkeztetés

A „minden kész” állítás jelen formában nem tartható. Több kritikus terület részben kész vagy ellentmondásos státuszban van, miközben vannak valóban elkészült, stabil elemek is.

---

## 2026-03-21 végrehajtási update (kód+doc korrekció)

Az alábbi, auditban jelölt ellentmondások közül a közvetlenül javíthatók javítva:

1. **Route-kontraktus mismatch javítva (backend kompatibilitás bővítés):**
   - Darius endpoint kapott `/api/v1` kompatibilis base path-et, legacy path megtartva.
   - Fájl: `backend/src/main/java/hu/puzzleir/valuta/controller/DariusReportController.java`
   - Módosítás: `@RequestMapping({"/api/v1/darius", "/api/darius"})`

2. **Kamera export endpoint kapott `/api/v1` kompatibilitást:**
   - Fájl: `backend/src/main/java/hu/puzzleir/valuta/controller/CameraExportController.java`
   - Módosítás: `@RequestMapping({"/api/v1/camera/export", "/api/camera/export"})`

3. **Electron SyncEngine route mismatch javítva backend alias-szal:**
   - Sync kliens hívja: `/api/v1/ertektar/branches/status`
   - Backend most már kiszolgálja alias endpointtal.
   - Fájl: `backend/src/main/java/hu/puzzleir/valuta/controller/ErtektarController.java`
   - Új endpoint: `GET /api/v1/ertektar/branches/status`

4. **Globális túlzó készültségi állítások dokumentumban visszafogva / truth-aligned:**
   - Fájl: `REPO_STATE.md`
   - „~98% kész” és „Darius nem kell” állítások korrigálva részben kész/nyitott státuszra.

5. **Mock/simplified P0 ellentmondás dokumentálás pontosítva:**
   - Fájl: `docs/AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md`
   - Delta DoD blokkhoz explicit megjegyzés: célállapot, jelenleg még nem teljesült.

### Nyitva maradt (egy körben nem zárható teljesen)

- **Darius teljes külső transport E2E** továbbra is részben kész (jelenleg outbox artifact + státusz, de nincs teljes bank oldali adapter/protokoll bizonyítás).
  - Fájl: `backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java`
- **Kamera evidence lánc E2E bizonyítás** (titkosítás+hash+transport teljes igazolás) továbbra is külön validációs feladat.
  - Fájlok: `backend/src/main/java/hu/puzzleir/valuta/service/CameraEncryptionService.java`, `backend/src/main/java/hu/puzzleir/valuta/service/CameraHashChainService.java`, kapcsolódó end-to-end teszt hiányok.
