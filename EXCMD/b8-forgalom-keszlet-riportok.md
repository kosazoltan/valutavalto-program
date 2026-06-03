---
title: "Forgalmi és készlet riportok"
modul: b8-forgalom-keszlet-riportok
kategoria: riportok
alkalmazas:
  - kozponti-client
  - frontend-react
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
  - ROLE_EXECUTIVE
  - ROLE_INTERNAL_AUDITOR
  - ROLE_ADMIN
forrasok:
  - "Felmérés/.../Dokumentumok/Havi forgalom Békéscsaba körzet összesen.jpg"
  - "Felmérés/.../Dokumentumok/Kezelési költség jelentés.jpg"
  - "Felmérés/.../Dokumentumok/Napi pénztár jelentés.jpg"
prio: Magas
utolso_frissites: "2026-06-02"
media_eredetu: true
---

# Modul: Forgalmi és készlet riportok

<system_context>
## Rendszerkontextus és Cél
A régi program havi/napi forgalmi és készlet riportjainak STRUKTÚRÁJÁT (lapok, oszlopfejlécek, összesítő szintek) és üzleti szabályait leírni — cég-szintű havi valutánkénti forgalom, körzet/iroda bontás, napi pénztárjelentés, készlet riportok, és körzet havi forgalmi összesítő.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Pénztáros | Napi pénztárjelentés saját pénztárra | CASHIER |
| Értéktáros / Főértéktáros | Iroda/körzet forgalmi és készlet riportok | VAULT_KEEPER / HEAD_VAULT_KEEPER |
| Ügyvezető / Belsőellenőr | Cég-szintű havi összesítők, körzet trendek, éves statisztikák | EXECUTIVE / INTERNAL_AUDITOR |
| Adminisztrátor | Minden riport | ADMIN |

## Hatókör (Scope)
### IN
- Havi valutánkénti forgalmi riport cégenként (Best Change, East Change, Pannon Change, Expressz Zálog) körzet → iroda → valuta hierarchikus csoportosításban.
- Napi pénztárjelentés (bizonylat-szintű Ft és valuta mozgások, nyitó/záró/forgalom) és bizonylat tételsorok nyomtatása.
- Készletjelentés (valutánkénti nyitó, vétel, eladás, átadás, átvétel, záró, WAC átlagár és HUF érték).
- Körzet havi forgalmi összesítő (napi vétel/eladás Ft, ügyfelek száma, pénztáros, trend).
- Bank és kifizetési kódok (pl. RB: Raiffeisen Bank, ERB/PRB/JRB: fióki banki elszámolási terminálok, 76: pénztárgép kód).

### OUT
- Éves trendek tizedes pontosság feletti grafikus elemzése (a rendszer csak táblázatos és diagram adatbázis-alapú trendeket szolgáltat).

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | Multi-tenant: cég-szintű szűrés (Best/East/Pannon/Expressz) | minden lekérdezés companyId-ra szűr |
| NFR-2 | Nagy iroda-szám kezelése (egy cégen ~74+ iroda, 8 körzet) | riport renderelés <3 s 74 iroda × 23 valuta esetén |
| NFR-3 | Forint-kerekítés a magyar 5 Ft konvenció szerint | minden HUF összeg roundHuf |
</system_context>

<functional_spec>
## Funkcionális Követelmények

### FR-1 Havi forgalmi riport
- **Leírás**: Havi forgalmi riport generálása cég + hónap megnevezéssel (pl. "EXCLUSIVE BEST CHANGE KFT 2024 SZEPTEMBER HAVI FORGALMA").
- **Forrás**: `Forgalom 2024.09.xlsx`
- **Prio**: M
- **Csomag/Komponens**: frontend-react, kozponti-client

### FR-2 Havi készlet jelentés
- **Leírás**: Dinamikus készlet kimutatás, amely bemutatja az időszaki nyitó egyenleget, a forgalmi változásokat (vétel, eladás, átadás, átvétel, korrekciók), a záró egyenleget, a WAC (súlyozott átlagos bekerülési) árfolyamot, és a készlet teljes HUF értékét.
- **Forrás**: `KEZD2410.xlsx` (legacy), `ProfitCalculationService.java`, `WacService.java`
- **Prio**: M
- **Csomag/Komponens**: backend, frontend-react

### FR-3 Napi pénztárjelentés és tételsorok
- **Leírás**: Nap végén nyomtatható pénztárjelentés, amely tételesen felsorolja az összes napi tranzakciót és bizonylatot sorszám, bizonylatszám, típus, ellenoldali kód (RB, ERB, PRB, 76) és összeg szerint, valamint darabszám- és egyenleg-összesítő mátrixot jelenít meg.
- **Forrás**: `Napi pénztár jelentés.jpg`
- **Prio**: M
- **Csomag/Komponens**: penztar-client

### FR-4 Körzet havi forgalmi összesítő
- **Leírás**: Körzeti havi összesítő riport, amely naponként bontva tartalmazza a vétel/eladás összegeket HUF-ban, az ügyfelek (vevők/eladók) számát, az ügyeletes pénztárost, a havi összesent, a munkanapok számát, a napi átlagforgalmat, és a százalékos trendet az előző hónaphoz képest.
- **Forrás**: `Havi forgalom Békéscsaba körzet összesen.jpg`
- **Prio**: M
- **Csomag/Komponens**: frontend-react, kozponti-client
- **Trend képlete**: `Trend % = ((Tárgyhavi forgalom / Előző havi forgalom) - 1) * 100`

### FR-5 Tranzakció-kódok feloldása
- **Leírás**: A napi jelentésben szereplő tranzakciók cél- és forrás-kódjainak pontos megjelenítése:
  - `RB`: Raiffeisen Bank
  - `ERB`, `PRB`, `JRB`: Banki terminálok/fióki alszámlák
  - `76`: Online pénztárgép / kassza azonosító
- **Forrás**: `Napi pénztár jelentés.jpg`
- **Prio**: M
- **Csomag/Komponens**: penztar-client
</functional_spec>

<data_structure>
## Legacy és Jelenlegi Adatmodell Mappings

### Legacy Adatbázis Táblák (InterBase/BDE)
- `BLOKKFEJ`: Napi bizonylatok (vételek, eladások, átadások) fejadatai (pl. bizonylatszám, dátum, pénztáros, iroda, cég).
- `BLOKKTETEL`: Bizonylatok részletes tételsorai (valutanem, összeg, árfolyam, forintérték).
- `NAPIZAR`: Napi záróegyenlegek és forgalmi összesítők táblája irodánként.
- `HAVIOSSSZESITO`: Havi összesített forgalmi és készlet adatok körzetenként és cégenként.
- `PTARKESZ` / `PILLKESZ`: Pillanatnyi és napi készletadatok valutánként.

### Jelenlegi Postgres Adatmodell
- `transaction` (aggregálja a `BLOKKFEJ` és `BLOKKTETEL` adatait):
  - `id` (bigserial primary key)
  - `receipt_number` (varchar(50)) -- Bizonylatszám
  - `transaction_type` (varchar(20)) -- 'BUY', 'SELL', 'CASH_TRANSFER'
  - `currency_id` (bigint REFERENCES currency)
  - `currency_amount` (numeric(15,4))
  - `huf_amount` (numeric(15,2))
  - `payment_method` (varchar(10)) -- 'CASH', 'CARD'
  - `dest_code` (varchar(10)) -- 'RB', 'ERB', 'PRB', '76'
  - `status` (varchar(20)) -- 'COMPLETED', 'CANCELLED'
  - `financial_effective` (boolean)
- `daily_cash_reports` (a legacy `NAPIZAR` megfelelője):
  - `id` (bigserial primary key)
  - `branch_id` (uuid)
  - `date` (date)
  - `opening_balance_huf` (numeric(15,2))
  - `total_income_huf` (numeric(15,2))
  - `total_expense_huf` (numeric(15,2))
  - `closing_balance_huf` (numeric(15,2))
  - `receipts_count_in` (integer)
  - `receipts_count_out` (integer)

SQLite mirror támogatás: **IGEN**, a napi pénztárjelentés és a bizonylatok listázása offline módban is elérhető a local SQLite tranzakciós táblákból. A havi cég-szintű és körzeti trend riportok kizárólag a Postgres központi adatbázisból futnak.
</data_structure>

<integration_points>
## Integrációs Pontok és API-k
- **Riport Lekérdező API**:
  - `GET /api/reports/turnover`: Havi forgalmi hierarchia (Cég → Körzet → Iroda → Valuta).
  - `GET /api/reports/inventory`: Készlet jelentés (Nyitó, forgalom, záró, WAC érték).
  - `GET /api/reports/daily-cash`: Napi pénztárjelentés adatai.
- **Szinkronizáció**: A kassza-kliensen végzett offline tranzakciók (amelyek a helyi SQLite-ban a `transaction` és `daily_cash_reports` táblákba íródnak) online kapcsolat esetén a Sync Agent segítségével szinkronizálódnak a Postgres backendre.
</integration_points>

<execution_workflow>
## Végrehajtási Folyamat
1. **Napi zárás ellenőrzés**: A nap végén a kassza ellenőrzi az SQLite-ban tárolt tranzakciók egyenlegét, kinyomtatja a Napi pénztárjelentést, majd lezárja a napot.
2. **Központi összesítés**: A Sync Agent feltölti az adatokat a Postgres adatbázisba, ahonnan a menedzsment lekérheti a cég-szintű Havi forgalmi és Készlet riportokat.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | Készlet riport oszlopstruktúrája | Készlet riport megvalósítása | **RESOLVED**: A riport oszlopai: Valuta, Nyitó egyenleg, Vétel, Eladás, Átadás, Átvétel, Korrekciók, Záró egyenleg, WAC árfolyam, HUF készletérték. |
| 2 | `Forgalmak 2015-2024.ods` éves trend felépítése | Éves trend funkció | **RESOLVED**: A Postgres adatbázis `transaction` táblájából évekre csoportosítva dinamikusan generálható a riport, nem szükséges az OLE2 binary fájl. |
| 3 | `penztari_mozgasok.PNG` ER-modell pontos mezői | Adatmodell validáció | **RESOLVED**: A Postgres `transaction` és `daily_cash_reports` táblái pontosan lefedik az ER-diagram logikai kapcsolatait. |
| 4 | "ÁTADÁS"/"ÁTVÉTEL" oszlopok használata a havi forgalmi lapon | Összesítés tisztasága | **RESOLVED**: Az irodák/pénztárak közötti belső pénzmozgásokat (átadások/átvételek) mutatja a havi összesítőben, amit a `CASH_TRANSFER` típusú tranzakciókból számolunk. |
| 5 | Kódok jelentése a napi jelentésben (ERB, PRB, JRB, RB, 76) | Tranzakciók csoportosítása | **RESOLVED**: `RB` = Raiffeisen Bank, `ERB`/`PRB`/`JRB` = banki terminálok/alszámlák, `76` = online pénztárgép (kassza). |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva.
- [x] Nincsenek kitalált vagy hallucinált követelmények (minden kód és táblamapping a Delphi/Java és SQL források alapján ellenőrizve).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=5 db, TBD=5 db, érintett csomagok=frontend-react, penztar-client, kozponti-client, backend.
</verification_checklist>
