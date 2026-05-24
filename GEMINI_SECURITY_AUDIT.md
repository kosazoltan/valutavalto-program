# VALUTAVÁLTÓ PROGRAM — GEMINI BIZTONSÁGI ÉS KÓD AUDIT UTASÍTÁS

> **Verzió:** 2026-05-24 | **Célrendszer:** Google Gemini / Gemini Code Assist / Jules  
> **Auditálni kívánt rendszer:** `valutavalto-program` monorepo (backend + frontend-react + 3 Electron kliens)  
> **Cél:** Független, mélyreható biztonsági és kód-integritás ellenőrzés. Minden megállapítást fájlnévvel + sorszámmal kell alátámasztani.

---

## PROJEKT ÁTTEKINTÉS (olvasd el mielőtt bármit csinálsz)

Magyar valutaváltó / pénzváltó **pénzügyi ERP rendszer**. Multi-tenant (több iroda), offline-képes.

| Modul | Technológia | Fájlok |
|---|---|---|
| `backend/` | Java 21, Spring Boot 4, PostgreSQL, Flyway (255 migráció) | ~1294 .java |
| `frontend-react/` | React 19, TypeScript, Axios, Tailwind | ~362 .ts/.tsx |
| `penztar-client/` | Electron 33, SQLite offline, Node IPC | ~42 .ts |
| `kozponti-client/` | Electron, thin client | ~7 .ts |
| `arfolyam-keszito-client/` | Electron, árfolyam-szerkesztő | ~17 .ts |

**Ez egy éles, production-ban futó pénzügyi alkalmazás.** Az ügyféladatok (személyi igazolvány, tranzakciók, MFA titkok) valódi személyekhez tartoznak. A Pmt. (Pénzmosás-megelőzési törvény) hatálya alá esik.

---

## GEMINI — AUDIT VÉGREHAJTÁSI ÚTMUTATÓ

### Lépések sorrendje

1. Olvasd el ezt a dokumentumot teljes egészében
2. Járd végig a 10 audit-fázist **ebben a sorrendben**
3. Minden lelet esetén töltsd ki a **Lelet-bejelentési formátumot** (a dokumentum végén)
4. A fehér listán szereplő URL-eket NE jelezd le hibásként
5. Ne hagyj ki fázist, ha "úgy tűnik, hogy az OK" — mindenre bizonyítékot kell szállítanod

---

## FEHÉR LISTA — ISMERT LEGITIM KÜLSŐ URL-EK

Ezek az URL-ek szándékosan szerepelnek a kódban. **NE jelezd ezeket** ismeretlen/gyanús linkként:

### Backend (Java)
| URL | Modul | Cél |
|---|---|---|
| `https://excvaluta.com` | `ProductionUrls.java` | Production API (saját domain) |
| `https://excbesttest.com` | CORS config, OpenAPI | Staging szerver (saját domain) |
| `https://scsanctions.un.org/resources/xml/en/consolidated.xml` | `SanctionListScheduler.java` | ENSZ szankciós lista XML (hatóság) |
| `https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content` | `SanctionListScheduler.java` | EU szankciós lista XML (hatóság) |
| `https://www.mnb.hu/arfolyamok.asmx/GetCurrentExchangeRates` | `ExchangeRatePollingService.java` | MNB (Magyar Nemzeti Bank) árfolyam API |
| `http://www.mnb.hu/arfolyamok.asmx` (SOAP) | `MnbExchangeRateService.java` | MNB SOAP végpont |
| `https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml` | `ExchangeRatePollingService.java` | ECB (Európai Központi Bank) árfolyam XML |
| `https://api.github.com/repos/.../issues` | `GitHubIssueAutoCreator.java` | Belső hibajelentés GitHub-ra |

### Frontend / Electron (TypeScript)
| URL | Fájl | Cél |
|---|---|---|
| `https://excvaluta.com/api/v1` | `client.ts`, `main.ts` | Production API (saját domain) |
| `https://api.openai.com/v1/realtime` | `realtimeClient.ts` | Hangsegéd (OpenAI Realtime API) |
| `https://accounts.google.com/o/oauth2/v2/auth` | `google-oauth.ts` | Google OAuth2 (bejelentkezés) |
| `https://oauth2.googleapis.com/token` | `google-oauth.ts` | Google token csere |
| `https://excvaluta.com/api/v1/diagnostics/error-report` | `error-reporter.ts` | Hibajelentés saját backend-re |
| `https://valuta-backend-spbx.onrender.com` | `e2e/` tesztek | Régi staging URL (csak tesztfájlban!) |
| `https://valutavalto.vercel.app` | WebSocket CORS config | Régi Vercel staging (csak CORS allow) |

### Frontend linkek (csak megjelenítés, NEM hálózati hívás)
| URL | Oldal | Cél |
|---|---|---|
| `https://www.otpbank.hu/portal/hu/Arfolyamok/OTP` | `MainRateSheetPage.tsx` | Referencia link (kattintható, NEM automatikus fetch) |
| `https://www.xe.com/currencyconverter/` | `MainRateSheetPage.tsx` | Referencia link (kattintható, NEM automatikus fetch) |
| `https://scsanctions.un.org` | `SanctionPage.tsx` | Linkként megjelenítve a szankciós lista URL-je |
| `https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1` | `SanctionPage.tsx` | Linkként megjelenítve |

---

## FÁZIS 1 — ISMERETLEN KÜLSŐ URL-EK ÉS HIVATKOZÁSOK

**Ez a legfontosabb fázis. Minden URL-t, ami NINCS a fehér listán, jelezni kell.**

### 1.A — Backend Java URL-ek

Keresési parancs:
```bash
grep -rn "https\?://" backend/src/main/java --include="*.java" \
  | grep -v "//.*https\?://" \
  | grep -v "^\s*\*" \
  | grep -v "localhost"
```

**Mit kell ellenőrizni:**
- Minden `http://` vagy `https://` prefix amit Java kódban találsz
- Különösen gyanús: bármilyen URL ami NEM szerepel a fehér listán és NEM saját domain
- `HttpClient`, `RestTemplate`, `WebClient`, `HttpRequest.newBuilder()` hívások célje
- `@Value("${...}")` property-k amik URL-t tárolnak (ellenőrizd az `application.properties`-t is)

### 1.B — Frontend TypeScript URL-ek

```bash
grep -rn "https\?://" frontend-react/src --include="*.ts" --include="*.tsx" \
  | grep -v "localhost" \
  | grep -v "//.*https\?://"
```

**Mit kell ellenőrizni:**
- `fetch()` hívások célpontjai
- `axios.get/post/put/delete()` URL-ek
- `new WebSocket()` célpontjai
- `img src=`, `script src=` külső CDN-ek
- Bármilyen `.env`-ből olvasott `VITE_*` URL env-változó

### 1.C — Electron kliens URL-ek

```bash
grep -rn "https\?://" penztar-client/electron --include="*.ts" \
  | grep -v "localhost" \
  | grep -v "//.*https\?://"

grep -rn "https\?://" kozponti-client --include="*.ts" \
  | grep -v node_modules | grep -v "localhost"

grep -rn "https\?://" arfolyam-keszito-client --include="*.ts" \
  | grep -v node_modules | grep -v "localhost"
```

**Különösen gyanús az Electron kliensben:**
- Bármilyen URL ami NEM `excvaluta.com` és NEM Google/OpenAI/GitHub fehér listán
- `shell.openExternal()` hívások (megnyitja a böngészőt — ellenőrizd a célt)
- `net.request()` / `electron.net` hívások célpontjai
- `loadURL()` / `loadFile()` hívások

### 1.D — Flyway migrációs SQL-ek

```bash
grep -rn "https\?://" backend/src/main/resources/db/migration/ --include="*.sql"
```

URL-nek NEM szabad szerepelni SQL migrációban. Ha van, jelezd kritikusként.

### 1.E — application.properties és konfigurációs fájlok

```bash
grep -rn "https\?://" backend/src/main/resources/ --include="*.properties" --include="*.yml" --include="*.yaml"
grep -rn "https\?://" penztar-client/electron/ --include="*.json" | grep -v node_modules
```

---

## FÁZIS 2 — HITELESÍTÉS ÉS JOGOSULTSÁG-KEZELÉS

### 2.A — Missing @PreAuthorize (Spring Security)

Minden REST controller endpointnak `@PreAuthorize` annotációval kell rendelkeznie, KIVÉVE:
- `PublicBranchController` (szándékosan publikus)
- `AuthController` (`/auth/login`, `/auth/refresh`)
- `SetupController` / bootstrap végpontok (első telepítéshez)
- `HealthController` / actuator

**Ellenőrzés:**
```bash
# Controllerek @PreAuthorize NÉLKÜL
grep -rn "@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping" \
  backend/src/main/java/hu/puzzleir/valuta/controller/ \
  --include="*.java" -l | while read f; do
    if ! grep -q "@PreAuthorize" "$f"; then
      echo "HIÁNYZÓ @PreAuthorize: $f"
    fi
  done
```

Alternatívan: keresd az összes `@RestController` osztályt és ellenőrizd, hogy vagy osztály szinten vagy minden metóduson van-e `@PreAuthorize`.

### 2.B — JWT validáció

Ellenőrizd a `JwtAuthFilter.java` / `JwtService.java` / `JwtUtils.java` (vagy hasonló nevű) fájlokat:
- Van-e `alg=none` bypass lehetőség?
- A JWT signature valóban ellenőrzött (NEM csak dekódolt)?
- A `exp` (expiry) claim ellenőrzött?
- A `companyId` claim a tokenből kerül-e ki, vagy felülírható más forrásból?

### 2.C — SecurityUtils.getCurrentWorkerId() / getCurrentCompanyId()

Keresés:
```bash
grep -rn "getCurrentWorkerId\|getCurrentCompanyId\|getCurrentUserId" \
  backend/src/main/java --include="*.java"
```

Minden hely ahol ezeket használják: ellenőrizd, hogy a visszaadott `workerId`/`companyId` NEM felülírható a kérésből (pl. RequestParam, PathVariable) ha az a kritikus adatszűréshez kell.

### 2.D — Admin bypass minták

```bash
grep -rn "ROLE_ADMIN\|hasRole.*ADMIN\|isAdmin\|adminOverride\|skipAuth\|bypassAuth\|noAuth" \
  backend/src/main/java --include="*.java"
```

Gyanús: bármilyen `if (isAdmin) { skip check }` logika, különösen ha az admin státusz nem a JWT-ből jön.

### 2.E — Hardcoded jelszó / token / API kulcs

```bash
grep -rn "password\s*=\s*\"[^\"]\+\"\|apiKey\s*=\s*\"[^\"]\+\"\|secret\s*=\s*\"[^\"]\+" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test\|mock\|Mock"

grep -rn "API_KEY\s*=\s*['\"][^'\"]\+['\"]" \
  frontend-react/src penztar-client/electron --include="*.ts" --include="*.tsx"
```

---

## FÁZIS 3 — MULTI-TENANT IDOR AUDIT

Ez a leggyakoribb pénzügyi alkalmazás-sérülékenység: egy bérlő hozzáfér más bérlő adataihoz.

### 3.A — Repository lekérdezések company-szűrés nélkül

```bash
# Spring Data JPA repository-k amelyek NEM tartalmaznak companyId szűrést
grep -rn "findAll()\|findById\|List<.*> find" \
  backend/src/main/java/hu/puzzleir/valuta/repository/ --include="*.java"
```

Minden `findAll()` és `findById()` hívás potenciálisan veszélyes ha a hívó service nem szűr `companyId`-ra. Ellenőrizd, hogy a service réteg elvégzi-e a szűrést.

### 3.B — PathVariable workerId / branchId ellenőrzés

```bash
grep -rn "@PathVariable.*workerId\|@PathVariable.*branchId\|@PathVariable.*customerId" \
  backend/src/main/java/hu/puzzleir/valuta/controller/ --include="*.java"
```

Minden PathVariable ID esetén: ellenőrizd, hogy a service réteg verifikálja-e, hogy az adott entitás valóban az aktuális `companyId`-hoz tartozik (ne csak létezik-e az adatbázisban).

### 3.C — Admin endpoint IDOR védelem

```bash
grep -rn "@PathVariable Long workerId" \
  backend/src/main/java/hu/puzzleir/valuta/controller/ --include="*.java" -A5 \
  | grep -A3 "disable\|delete\|reset\|force"
```

---

## FÁZIS 4 — KRIPTOGRÁFIAI ELLENŐRZÉS

### 4.A — Gyenge hash algoritmusok

```bash
# MD5 és SHA-1 jelszó/titkosítás célra
grep -rn "MD5\|SHA-1\|SHA1\b\|getInstance.*\"MD5\"\|getInstance.*\"SHA-1\"" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test"

# SHA-256 jelszó/PIN tárolásra (elfogadható üzleti adat hash-elésre, DE NEM jelszóhoz)
grep -rn "getInstance.*\"SHA-256\"" \
  backend/src/main/java --include="*.java"
```

**Várható:** Az MFA backup kódoknál már BCrypt van (PP-16 fix). Ha SHA-256-ot találsz **jelszó jellegű adat** (PIN, backup code, jelszó) hash-eléséhez, az kritikus lelet.

**Elfogadható** SHA-256 használat: audit-log hash-chain (tamper-evidence), IP log sanitize (fingerprint), nem-jelszó adatok integrity check-je.

### 4.B — SecureRandom vs Math.random()

```bash
grep -rn "Math\.random()\|new Random()" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test"
```

Biztonsági célú véletlenszám (token, backup code, salt) csak `SecureRandom`-mal generálható.

### 4.C — IV/nonce újrahasználat (ha AES/GCM titkosítás van)

```bash
grep -rn "AES\|GCM\|IvParameterSpec\|Cipher\." \
  backend/src/main/java --include="*.java"
```

Ha van szimmetrikus titkosítás: ellenőrizd, hogy az IV minden egyes titkosítási művelethez frissen generálódik-e (NEM static final).

---

## FÁZIS 5 — SQL INJECTION ÉS ADATBÁZIS BIZTONSÁG

### 5.A — Native SQL string concatenation

```bash
# JPQL / Native query string összefűzés (potenciális SQL injection)
grep -rn "@Query.*+\|createNativeQuery.*+\|createQuery.*+" \
  backend/src/main/java --include="*.java" | grep -v "//\|*"

# EntityManager raw query string
grep -rn "entityManager\.createNativeQuery\|entityManager\.createQuery" \
  backend/src/main/java --include="*.java" -A2
```

**Elfogadható:** JPA `@Query` annotáció `:param` named paraméterekkel.  
**Gyanús:** String concatenation a query-ben, különösen ha a concatenált rész felhasználói inputból jön.

### 5.B — Flyway migráció SQL injection

```bash
grep -rn "EXECUTE\|EXECUTE IMMEDIATE\|exec\|eval" \
  backend/src/main/resources/db/migration/ --include="*.sql"
```

### 5.C — Adatbázis UPDATE/DELETE trigger védelem (audit_log)

Az audit_log tábla immutable kell legyen (Pmt. megfelelőség). Ellenőrizd:
- Megvan-e a `V234__audit_log_immutable_hash_chain.sql` migráció?
- A trigger tiltja-e az UPDATE és DELETE-et az `audit_log` táblán?

```bash
cat backend/src/main/resources/db/migration/V234__audit_log_immutable_hash_chain.sql 2>/dev/null \
  || find backend/src/main/resources/db/migration -name "*audit*log*" -o -name "*immutable*"
```

---

## FÁZIS 6 — XSS, INJECTION ÉS FRONTEND BIZTONSÁG

### 6.A — dangerouslySetInnerHTML

```bash
grep -rn "dangerouslySetInnerHTML" \
  frontend-react/src --include="*.tsx" --include="*.ts"
```

Minden `dangerouslySetInnerHTML` használat részletes vizsgálatot igényel. Elfogadható csak ha a tartalom: (a) statikus string, (b) nem felhasználói input, (c) sanitized.

### 6.B — eval() és Function() hívások

```bash
grep -rn "\beval\b\s*(\|new Function\s*(" \
  frontend-react/src penztar-client/src penztar-client/electron \
  --include="*.ts" --include="*.tsx" | grep -v node_modules | grep -v "//.*eval"
```

### 6.C — innerHTML direkt beállítás

```bash
grep -rn "\.innerHTML\s*=" \
  frontend-react/src penztar-client --include="*.ts" --include="*.tsx" | grep -v node_modules
```

### 6.D — Electron contextIsolation és nodeIntegration

```bash
grep -rn "contextIsolation\|nodeIntegration\|webSecurity\|allowRunningInsecureContent" \
  penztar-client/electron kozponti-client arfolyam-keszito-client \
  --include="*.ts" --include="*.json" | grep -v node_modules
```

**Elvárás:** `contextIsolation: true`, `nodeIntegration: false`, `webSecurity: true`. Ha ezek közül bármelyik `false` (kivéve tesztben), kritikus lelet.

### 6.E — Electron shell.openExternal() célpontok

```bash
grep -rn "shell\.openExternal\|openExternal" \
  penztar-client kozponti-client arfolyam-keszito-client \
  --include="*.ts" | grep -v node_modules
```

Ellenőrizd: az URL amit megnyit mindig whitelist-elt és validált-e, vagy felhasználói inputból jöhet?

---

## FÁZIS 7 — LOG-SZIVÁRGÁS ÉS PII ADATVÉDELEM

### 7.A — Jelszó/token logolás

```bash
grep -rn "log\.\(info\|debug\|warn\|error\).*password\|log\.\(info\|debug\|warn\|error\).*token\|log\.\(info\|debug\|warn\|error\).*secret" \
  backend/src/main/java --include="*.java" | grep -v "//\|test\|Test"
```

### 7.B — PII közvetlen logolásban

```bash
grep -rn "log\.\(info\|debug\|warn\|error\).*personalId\|log\.\(info\|debug\|warn\|error\).*documentNumber\|log\.\(info\|debug\|warn\|error\).*ssn\|log\.\(info\|debug\|warn\|error\).*birthDate" \
  backend/src/main/java --include="*.java"
```

**Elvárás:** A Logback konfigurációban (`logback-spring.xml`) egy `%replace` pattern redaktálja a PII-t (JWT, kártyaszám, email, IBAN, szig.szám). Ellenőrizd, hogy ez a filter tényleg aktív-e.

```bash
cat backend/src/main/resources/logback-spring.xml 2>/dev/null || \
  find backend/src/main/resources -name "logback*.xml"
```

### 7.C — Frontend console.log PII

```bash
grep -rn "console\.\(log\|info\|warn\|error\).*password\|console\.\(log\|info\|warn\|error\).*token\|console\.\(log\|info\|warn\|error\).*secret" \
  frontend-react/src penztar-client/src penztar-client/electron \
  --include="*.ts" --include="*.tsx" | grep -v node_modules | grep -v "//.*console"
```

---

## FÁZIS 8 — BACKDOOR ÉS "PHONE-HOME" MINTÁK

Ez a fázis a rosszindulatú beágyazott kódot keresi.

### 8.A — Ismeretlen hálózati hívások (nem fehér listán)

```bash
# Java HttpClient / RestTemplate hívások
grep -rn "HttpClient\|RestTemplate\|WebClient\|HttpRequest\.newBuilder\|new URL(" \
  backend/src/main/java --include="*.java" -B2 -A5 | grep -v "test\|Test"
```

Minden hálózati híváshoz: ellenőrizd a célpontot. Ha ismeretlen domain → kritikus lelet.

```bash
# TypeScript fetch / axios hívások
grep -rn "fetch(\|axios\.\(get\|post\|put\|delete\|patch\)(" \
  frontend-react/src penztar-client/electron \
  --include="*.ts" --include="*.tsx" | grep -v node_modules -A2
```

### 8.B — Base64 kódolt URL-ek vagy stringek

```bash
# Base64 kódolt ismeretlen tartalom
grep -rn "atob(\|btoa(\|Buffer\.from.*base64\|Base64\.decode" \
  frontend-react/src penztar-client --include="*.ts" --include="*.tsx" | grep -v node_modules

grep -rn "Base64\.decode\|Base64\.encode" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test\|backup"
```

Ellenőrizd a dekódolt tartalmat: nem tartalmaz-e rejtett URL-t vagy parancsot?

### 8.C — Dinamikus kódfuttatás

```bash
# Runtime compile / exec
grep -rn "Runtime\.getRuntime\|ProcessBuilder\|Process\b\|exec(" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test\|//\|\*"

# Node.js child_process
grep -rn "child_process\|exec(\|spawn(\|execSync\|spawnSync" \
  penztar-client kozponti-client arfolyam-keszito-client \
  --include="*.ts" | grep -v node_modules | grep -v "//.*exec"
```

### 8.D — Rejtett Scheduled Task / Timer

```bash
grep -rn "@Scheduled\|ScheduledExecutorService\|scheduleAtFixedRate\|scheduleWithFixedDelay" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test"
```

Listázd az összes ütemezett feladatot és ellenőrizd a céljukat. Különösen gyanús, ha egy scheduler hálózati hívást végez és az NEM az MNB/ECB/szankciós lista lekérdezéssel függ össze.

### 8.E — Hardcoded admin / backdoor fiók

```bash
grep -rn "admin\|superuser\|backdoor\|debug_user\|master_password" \
  backend/src/main/java --include="*.java" | grep -i "password\|secret\|token" | grep -v "//\|\*\|test"

grep -rn "\"admin\"\s*,\s*\"admin\"\|\"root\"\s*,\s*\"root\"\|\"password\"\s*,\s*\"password\"" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test"
```

### 8.F — Titkosított / obfuszkált kódszakaszok

Gyanús, ha valami nagy méretű Base64 string (`"AAAA..."` jellegű, 50+ karakter) vagy hex string szerepel statikusan:

```bash
grep -rn "\"[A-Za-z0-9+/=]\{60,\}\"" \
  backend/src/main/java --include="*.java" | grep -v "test\|Test"
```

### 8.G — IPC handler lista (Electron)

```bash
grep -rn "ipcMain\.handle\|ipcMain\.on" \
  penztar-client/electron kozponti-client arfolyam-keszito-client \
  --include="*.ts" | grep -v node_modules
```

Listázd az összes IPC channel-t és ellenőrizd: minden channel-nek legítim üzleti funkciója van-e? Van-e olyan channel ami shell parancsot futtat, fájlt olvas tetszőleges helyen, vagy hálózati hívást végez?

---

## FÁZIS 9 — SUPPLY CHAIN ÉS FÜGGŐSÉG INTEGRITÁS

### 9.A — package.json dependency audit

```bash
# Gyanús/ismeretlen csomagok keresése (amiket a projekt nem dokumentál)
cat package.json frontend-react/package.json penztar-client/package.json \
  kozponti-client/package.json arfolyam-keszito-client/package.json 2>/dev/null \
  | grep '"dependencies"\|"devDependencies"' -A 200 | grep "\":" | grep -v "^--$"
```

Ellenőrizd:
- Nincs-e ismeretlen, alul-dokumentált csomag a `dependencies`-ben?
- Nincs-e olyan csomag ami átfed egy népszerű csomag nevével (typosquatting)?
- A csomag verziók pinned-ek-e (`"x.y.z"` formában), vagy wildcard (`"^x.y"`, `"~x.y"`) — utóbbi supply chain kockázat

### 9.B — pom.xml Java függőségek

```bash
grep -rn "<groupId>\|<artifactId>\|<version>" backend/pom.xml \
  | grep -v "<!--\|snapshot\|SNAPSHOT" | grep -v "puzzleir\|valuta" | head -60
```

Különösen gyanús: ismeretlen groupId-k, nem Maven Central-on lévő csomagok.

### 9.C — npm lock file integritás

```bash
# node_modules-ban van-e package.json által nem deklarált csomag?
# (csak spot-check, nem teljes ellenőrzés)
ls node_modules/ 2>/dev/null | head -20
```

---

## FÁZIS 10 — PÉNZÜGYI LOGIKA AUDIT (KÓDHIBA KERESÉS)

### 10.A — HUF kerekítés következetessége

A magyar 5 Ft-os kerekítési szabály MINDEN HUF összeget érint. Keresés:

```bash
# Backend: roundHuf / round5 nem alkalmazott HUF összegnél
grep -rn "hufAmount\|totalHuf\|feeTotalHuf" \
  backend/src/main/java --include="*.java" | grep -v "round\|Round" | grep -v "test\|Test\|//\|\*"

# Frontend: 5 Ft kerekítés hiánya
grep -rn "hufAmount\|totalHuf" \
  frontend-react/src --include="*.ts" --include="*.tsx" | grep -v "round\|Round\|//\|\*"
```

### 10.B — Negatív összeg védelem

```bash
grep -rn "amount\s*<\s*0\|amount\s*<=\s*0\|negativeAmount\|validateAmount" \
  backend/src/main/java --include="*.java" -l
```

Ellenőrizd: minden tranzakció-végrehajtás előtt van-e pozitív összeg validáció?

### 10.C — Osztás nullával (ArithmeticException)

```bash
grep -rn "\.\s*/\s*\." backend/src/main/java --include="*.java" | grep -v "test\|Test\|//\|\*"
```

Különösen gyanús: árfolyam-számításban `amount / rate` ahol a `rate` nulla is lehet.

### 10.D — CompanyId multi-tenant szűrés hiánya lekérdezésben

```bash
# Service metódusok amelyek nem tartalmaznak companyId paramétert de tranzakciókat kezelnek
grep -rn "findBy\|List<Transaction>\|List<DailyBalance>" \
  backend/src/main/java/hu/puzzleir/valuta/repository/ --include="*.java" \
  | grep -v "companyId\|company_id\|branchId"
```

### 10.E — AML ellenőrzés kikerülhetősége

```bash
grep -rn "checkAml\|amlCheck\|sanctionScreen\|performAmlCheck" \
  backend/src/main/java/hu/puzzleir/valuta/service/ --include="*.java"
```

Ellenőrizd: az AML és szankciós ellenőrzés minden tranzakció-útvonalon fut-e (buy, sell, conversion, reversal, transfer)?

---

## LELET-BEJELENTÉSI FORMÁTUM

Minden megállapítást az alábbi formátumban kell bejelenteni:

```
### [LELET-ID] — [TÍPUS] — [SÚLYOSSÁG: KRITIKUS/MAGAS/KÖZEPES/ALACSONY]

**Fájl:** `relatív/fájl/elérési/út.java` (sor: NNN)
**Kategória:** [URL-szivárgás / Biztonsági sérülékenység / Kódhiba / Gyanús minta / Pénzügyi logika hiba]
**Leírás:** Egy mondatban mit talált.
**Bizonyíték:** A gyanús kódrészlet idézése (max 10 sor).
**Kockázat:** Mi a legrosszabb esetben bekövetkező következmény?
**Javasolt javítás:** Konkrét lépés.
```

---

## ELLENŐRZÉSI ELVÁRÁS — MINDEN FÁZISHOZ KÖTELEZŐ VISSZAJELZÉS

Minden fázis végén nyilatkozz:
- ✅ **RENDBEN:** Nem találtam problémát ebben a fázisban. [rövid indoklás]
- ⚠️ **FIGYELEM:** Talált elemek listája a fenti formátumban.
- 🔴 **KRITIKUS:** Azonnali javítást igénylő lelet.

Ha egy fázist technikai korlát miatt (pl. fájlméret, kontextus) nem tudtál teljesen elvégezni, jelezd expliciten melyik részeket hagytad ki és miért.

---

## KIZÁRÁSOK (NE vizsgáld ezeket)

- `node_modules/` könyvtárak (third-party kód, külön supply chain audit tárgya)
- `*.test.ts`, `*Test.java`, `*.spec.ts` tesztfájlok — ezek más szabályok szerint értékelendők (mock URL-ek elfogadhatók)
- `e2e/` könyvtárak — integrációs tesztek, staging URL-ek elfogadhatók
- `vault/` könyvtár — belső dokumentáció, NEM futtatható kód
- `EXCMD/`, `Anti/`, `Felmérés/` könyvtárak — üzleti dokumentáció, NEM kód

---

*Audit utasítás készítette: Claude Sonnet 4.6 | 2026-05-24 | Valutaváltó ERP v2.26.35*
