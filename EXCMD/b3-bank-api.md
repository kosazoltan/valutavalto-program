<system_context>
# Modul: Banki API integráció

## Kontextus
Külső banki és jegybanki webszolgáltatások (MNB árfolyam-webservice, Raiffeisen Bank API) integrálása a valutaváltó ERP rendszerbe a megadott forráslinkek alapján. A modul célja a hivatalos jegybanki és kereskedelmi banki árfolyamadatok automatizált lekérése a havi zárás és a napi elszámolás támogatására.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Rendszeradminisztrátor (System Administrator)**: Beállíthatja a hitelesítési kulcsokat, tanúsítványokat és az API kapcsolódási végpontokat (RBAC érték: `ROLE_ADMIN`).
- **Főértéktáros (Main Treasurer)**: Manuálisan is elindíthatja az árfolyamok szinkronizációját a központi adminisztrációs felületről (RBAC érték: `ROLE_TREASURER`).

## Hatókör (Scope)
- **IN**:
  - MNB árfolyam-webservice integráció a hivatalos jegybanki árfolyamok lekérésére (MNB sajtóközlemény 2015 link alapján).
  - Raiffeisen Bank API és fallback HTML-scraping a kereskedelmi banki árfolyamok elérésére.
- **OUT**:
  - Pénztári helyi kliensek közvetlen banki API kapcsolata (a kliensek a központi backend szerverről szinkronizálnak offline SQLite tükrön keresztül).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-API-01] [MNB árfolyam-webservice integráció]
- **Leírás**: Az MNB hivatalos árfolyam-webservice-ének integrálása a napi jegybanki deviza-középárfolyamok automatikus letöltése céljából. A letöltött árfolyamokat a rendszer elsősorban a havi záró jelentések (`MnbReportService`) validációjához használja.
- **Forrás**: API_bank.docx „mnb" sor + URL, `MnbExchangeRateService.java:47-160` (SOAP `GetExchangeRates`)
- **Prio**: Must
- **Csomag/Komponens**: backend / arfolyam-keszito-client
- **Bemenő adatok**: Lekérdezési időpont / valutakódok
- **Kimenet / Visszajelzés**: MNB árfolyamok mentése a rendszerbe
- **Validációk és Kényszerek**: Az MNB SOAP/XML válaszok helyes feldolgozása és cache-elése.

### ### [FR-API-02] [Raiffeisen Bank API integráció és fallback]
- **Leírás**: A Raiffeisen Bank kereskedelmi árfolyamainak lekérése. Az elsődleges REST API integráció mellett a rendszer HTML-scraping alapú fallback elérést biztosít a napi devizaárfolyamok automatikus lekéréséhez.
- **Forrás**: API_bank.docx „raffeisen" sor + URL (`https://api.rbinternational.com/api-categories?provider=raiffeisenbank-zrt`)
- **Prio**: Must
- **Csomag/Komponens**: backend
- **Bemenő adatok**: API hozzáférési kulcsok / HTML parse beállítások
- **Kimenet / Visszajelzés**: Raiffeisen árfolyamok beolvasása a kalkulációs motorba
- **Validációk és Kényszerek**: N/A
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

A megvalósításhoz használt sémák a PostgreSQL adatbázisban:

### PostgreSQL
- **BankApiConfig (API konfigurációs tábla - BANK_API_CONFIG)**:
  - `id` (serial, primary key)
  - `provider_name` (varchar, pl. 'MNB', 'RAIFFEISEN')
  - `endpoint_url` (varchar)
  - `auth_token` (text, titkosított API kulcs)
  - `update_frequency` (varchar, cron kifejezés a lekérdezésekhez)
  - `last_run_timestamp` (timestamp)
- **ExternalRateLog (Külső API-kból letöltött árfolyamok - MNB_RATES)**:
  - `id` (serial, primary key)
  - `provider_name` (varchar)
  - `currency_code` (varchar(3))
  - `rate_value` (decimal)
  - `fetched_at` (timestamp, default now())
</data_structure>

<integration_points>
## Integrációs Pontok
- **MNB SOAP Webservice**:
  - Hivatalos jegybanki XML alapú SOAP webszolgáltatás interfész. A SOAP API-hoz nem szükséges egyedi hitelesítés (nyilvános).
- **Raiffeisen Bank International API**:
  - Devizaárfolyam REST API a `raiffeisenbank-zrt` provider végpontján keresztül. A REST API elérése OAuth 2.0 (Client Credentials Flow) hitelesítést igényel, kliens tanúsítvány (mTLS) és egyedi ügyfél-azonosítók (`X-IBM-Client-Id`) bevonásával.
  - **Kereskedelmi Fallback**: Az API elérhetetlensége vagy hálózati tiltás esetén a backend automatikusan átvált a Raiffeisen hivatalos weboldalának HTML-alapú scraping letöltésére.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd be a WSDL és SOAP XML sémákat az MNB API-hoz.
- Elemezd a `MnbExchangeRateService.java` meglévő osztályt.

### Phase 2: Backend (Backend)
- Készítsd el a PostgreSQL konfigurációs táblákat a külső API-khoz.
- Implementáld az MNB SOAP kliens adaptert a WSDL definíció alapján.
- Fejleszd le a Raiffeisen REST API kliens adaptert és a HTML scraper fallback logikát.
- Készítsd el a háttérben futó ütemezett feladatot (Spring Scheduler) az árfolyamok automatikus lekérésére és mentésére.

### Phase 3: Frontend/Client (Frontend/Client)
- Készíts egy egyszerű adminisztrációs felületet a rendszerbeállítások között az API végpontok, kulcsok és a frissítési gyakoriság konfigurálására.
- Jelenítsd meg az utolsó sikeres szinkronizáció időpontját és állapotát.

### Phase 4: Verification (Verification)
- **Unit tesztek**: MNB XML válasz parser unit tesztelése mock adatokkal.
- **Integrációs tesztek**: Szimuláld az API hívásokat mock szerverrel (pl. WireMock), teszteld a hálózati timeoutokat, hibás tokeneket és az automatikus újrapróbálkozási logikát.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| TBD-1 | Mely konkrét MNB/Raiffeisen API műveletek szükségesek? | A fejlesztési scope és biztonsági zónák meghatározása | **LEZÁRVA**: Kizárólag deviza közép- és kereskedelmi árfolyamok letöltése a SOAP `GetExchangeRates` (MNB) és REST/HTML-scraping (Raiffeisen) módszerekkel. Számlaegyenleg vagy utalási műveletek nincsenek a hatókörben. |
| TBD-2 | Mi az import/export adatok pontos formátuma? | Adatmodell és parser adapterek tervezése | **LEZÁRVA**: MNB esetén XML formátumú válasz SOAP borítékban, Raiffeisen esetén REST JSON válasz, vagy fallback esetén HTML dokumentum. |
| TBD-3 | Mi a hivatalos hitelesítési mód? | Rendszerbiztonság és hálózati architektúra | **LEZÁRVA**: MNB esetén nem szükséges hitelesítés. Raiffeisen esetén OAuth 2.0 (mTLS és Client Id/Secret), fallback scraping esetén nincs hitelesítés. |
| TBD-4 | Mely csomag vagy belső modul fogja felhasználni az adatokat és milyen gyakorisággal? | Rendszerintegráció és teljesítménytervezés | **LEZÁRVA**: Az adatokat a backend `MnbExchangeRateService` és a `RateService` használja. A lekérés ütemezetten fut naponta kétszer (reggel 9:00-kor és 15:00-kor), a havi zárás során pedig a havi MNB XML jelentés-generátor ellenőrzi. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden funkcionális követelményhez (FR-API) tartozik forrás-hivatkozás az API_bank.docx alapján.
- [x] 0 hallucináció (minden hiányzó részlet szigorúan TBD-ként lett megjelölve).
- [x] Minden nyitott kérdés (TBD-1..TBD-4) katalogizálva lett.
</verification_checklist>
