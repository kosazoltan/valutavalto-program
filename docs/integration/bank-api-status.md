# Bank API integráció — állapot dokumentum (2026-05-13, v2.5.50+)

> **Forrás:** `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/API_bank.docx`
> A docx 2 URL-t tartalmaz: MNB árfolyam webservice + Raiffeisen API.

## 1. MNB (Magyar Nemzeti Bank) árfolyam integráció

**URL:** <https://www.mnb.hu/sajtoszoba/sajtokozlemenyek/2015-evi-sajtokozlemenyek/tajekoztatas-az-arfolyam-webservice-mukodeserol>

### Implementáció

| Komponens | Útvonal | Állapot |
|---|---|---|
| `MnbApiClient` | `backend/.../service/MnbApiClient.java` | ✅ implementálva |
| `MnbExchangeRateService` | `.../service/MnbExchangeRateService.java` | ✅ implementálva |
| `MnbReportService` | `.../service/MnbReportService.java` | ✅ implementálva |
| `MnbExchangeRateCacheRepository` | `.../repository/MnbExchangeRateCacheRepository.java` | ✅ implementálva |

### Funkciók
- Napi MNB árfolyam letöltés és cache-elés
- Tranzakciókhoz alapérték (compliance ellenőrzés)
- Riport generálás (NAV/AML felé)

## 2. Raiffeisen Bank API integráció

**URL:** <https://api.rbinternational.com/api-categories?provider=raiffeisenbank-zrt>

### Implementáció

| Komponens | Útvonal | Állapot |
|---|---|---|
| `RaiffeisenRateService` | `backend/.../service/RaiffeisenRateService.java` | ✅ árfolyam scraping (napi 8:00 CET, munkanapokon) |
| `RaiffeisenRateScheduler` | `.../config/RaiffeisenRateScheduler.java` | ✅ ütemezett job |
| `BankApiConfigController` | `backend/.../controller/BankApiConfigController.java` | ✅ admin konfiguráció + manuális Raiffeisen fetch |
| `BankApiConfigService` | `backend/.../service/BankApiConfigService.java` | ✅ endpoint/auth mód/utolsó futás státusz, secret maszkolás |
| `bank_api_config` | `backend/.../db/migration/V301__bank_api_config.sql` | ✅ Raiffeisen/MNB seed + titkosított client secret oszlop |
| `DariusReportService` | `.../service/DariusReportService.java` | ⚠️ napi jelentés **outbox-fájlba** (NEM közvetlen API hívás) |
| Adapter REST kliens | nincs | ❌ **JÖVŐ FEJLESZTÉS** (Sprint 3+) |

2026-06-09 kiegészítés: a Raiffeisen árfolyam letöltés már a `bank_api_config`
konfigurált endpointját használja, és `SUCCESS` / `FAILED` / `SKIPPED` utolsó
futási státuszt ír vissza. A `REST_PRIMARY_WITH_HTML_FALLBACK` mód jelenleg
szándékosan HTML fallbacket futtat, mert nincs repóban validált Raiffeisen
REST/OAuth2/mTLS szerződés vagy banki credential. Ez nem minősül kész banki REST
integrációnak.

### Kérdéses funkció: Darius napi beküldés
A `submitToDarius()` metódus most JSON file-t ír egy outbox könyvtárba. **NEM** küldi tényleg a Raiffeisen API-ra. Ez azt jelenti, hogy:
- A 4-eyes approval workflow működik ✅
- A payload generálás működik ✅
- A submit státus átáll `SUBMITTED`-re (formálisan) ✅
- DE a tényleges banki beküldés **emberi továbbítást** igényel (egy compliance kolléga átemeli az outbox-ot a bank felé)

### Tervezett fejlesztés (P3, későbbi sprint)
- Raiffeisen API HTTP klients (auth + retry + signing)
- Tényleges submit a Darius jelentésekre
- Acceptance / rejection feedback
- Webhook fogadás
- Production credential kezelés (Vault / 1Password)

## 3. Bank API monitoring (új, Sprint 2 — v2.5.50)

### Új REST endpoint: `GET /api/v1/admin/bank-integration/status`

Visszaadja a Bank-integráció státusát:

```json
{
  "mnb": {
    "lastFetch": "2026-05-13T08:00:00",
    "lastFetchSuccess": true,
    "rateCount": 30,
    "schedulerNextRun": "2026-05-14T08:00:00"
  },
  "raiffeisen": {
    "schedulerActive": true,
    "scheduledTime": "08:00 CET (munkanapokon)",
    "enabled": true,
    "mode": "HTML_SCRAPING_FALLBACK",
    "endpointConfigured": true,
    "lastRunStatus": "SUCCESS",
    "lastRunTimestamp": "2026-06-09T10:55:00",
    "lastRunMessage": "Raiffeisen árfolyamok cache-elve: 14/14"
  },
  "darius": {
    "currentMonth": "2026-05",
    "pendingReportsCount": 0,
    "failedReportsCount": 0,
    "lastSubmittedAt": "2026-05-12T17:00:00",
    "transportMode": "MANAGED_OUTBOX"
  }
}
```

### Új admin UI tab: `Beállítások → Bank integráció`
- MNB cache állapot (utolsó letöltés, valuta szám)
- Raiffeisen scraping állapot
- Darius outbox státusza (függő, sikertelen, beküldött)
- Retry gomb (failed jelentésekhez)
- Trigger gomb (manuális árfolyam-frissítés)

### Új admin konfigurációs REST endpointok
- `GET /api/v1/bank-api-config`
- `GET /api/v1/bank-api-config/{providerName}`
- `PUT /api/v1/bank-api-config/{providerName}` (`ROLE_ADMIN`)
- `POST /api/v1/bank-api-config/raiffeisen/fetch-now`

A válasz nem tartalmazza a secret értéket; csak `clientSecretConfigured` flaget ad vissza.

## 4. Verifikáció

```bash
# MNB cache check
curl -s -H "Authorization: Bearer $JWT" \
  https://excvaluta.com/api/v1/admin/bank-integration/status | jq '.mnb'

# Darius pending count
curl -s -H "Authorization: Bearer $JWT" \
  https://excvaluta.com/api/v1/admin/bank-integration/status | jq '.darius.pendingReportsCount'

# Raiffeisen config status (secret nelkul)
curl -s -H "Authorization: Bearer $JWT" \
  https://excvaluta.com/api/v1/bank-api-config/raiffeisen | jq '{providerName,mode,enabled,lastRunStatus,clientSecretConfigured}'
```

## 5. Production setup követelmények

A `RaiffeisenRateService` jelenleg publikus webhely scrapingjét végzi (HTTPS GET).
**Nincs szükség Raiffeisen API kulcsra** ehhez a funkcióhoz.

A jövőbeli **Darius API submit** integrációhoz viszont szükséges:
- Raiffeisen API kulcs (Production + Sandbox)
- Authentikáció: OAuth2 client_credentials grant (várható)
- Webhook URL (acceptance/rejection callback)
- SSL client cert (egyes endpointokhoz)

Ezek beszerzése egy üzleti workshop tárgya: **Sprint 3+**.

## 6. Megerősítés a v2.0 spec-pel

A `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/03_tranzakciok.md` szerint:
> "3. A hatósági jelentéseket a megfelelő jogosultsággal rendelkező compliance munkatársak kezelik és továbbítják."

A jelenlegi outbox-fájl-alapú megoldás ezt **EGYBEILLESZTHETŐ** a spec-szel: a compliance kolléga az outbox-ban lévő fájlokat kézzel továbbítja. A jövőbeli API integráció ezt automatizálja.

---

**Sprint 2 verdikt:** A Bank API integráció **80%-ban implementálva** (MNB + Raiffeisen árfolyam + Darius generálás). A **20% hiány** = tényleges API submit transport, ami egy külön diszkrét sprintet igényel banki API kulccsal + sandbox-szal.

**Sprint 2 gyakorlati output:** Bank Integration Status admin UI + REST endpoint a meglévő integrációk monitoringjához.
