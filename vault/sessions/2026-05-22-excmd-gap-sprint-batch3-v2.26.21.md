# EXCMD gap-sprint 3. batch — v2.26.21 (2026-05-22)

## Kontextus
A v2.26.19 (G1/G2/G4/G5/G6) és v2.26.20 (G9/G12/G18/G21) batch-ek után a 3. batch a fennmaradó P1/P2/P3 frontend- és riport-tételeket vitte végig, szakaszonkénti merge-csel (CLAUDE.md mandate: AI-review zero-tolerance + 2 ellenőrzési kör).

## Merged PR-ek (mind admin-merged main-be, Hetzner auto-deploy, production HEALTHY)

| Gap | PR | Tartalom |
|-----|----|----|
| G10 | #778 | Zárás-típus választó (DAILY/DECADE/MONTHLY/POS) a ClosingWizard-ban (FE; backend kész volt) |
| G17 | #779 | Havi tabló dedikált FE oldal (`MonthlyTabloPage`, `GET /closing/monthly/{branchId}/{yearMonth}/full`) |
| G15 | #780 | Bizonylat-szűrés: `TransactionTypeName` kanonikus union + átadási/átvételi (TRANSFER_OUT/IN) szűrő + típus-címke |
| G16 | #781 | Forgalmi grafikon: függőség-mentes inline `HorizontalBarChart` (profit + tranzakciószám valutánként) a DailyTurnoverPage-en |
| G23 | #782 | Körzet-szintű havi forgalmi/trend riport (backend `RegionTurnoverReportService` régió GROUP BY + előző-hó trend% + FE oldal) |
| G14 | #783 | Foglaló-bizonylat (FOGLALÓ ÁTVÉTELE / VISSZAFIZETÉSE) + ügyfél-pillanatkép, PDF endpoint + FE letöltő gomb |

## AI-review tanulságok (mind javítva merge előtt)
- **G17**: UTC `toISOString()` hónap-eltolódás → helyi dátum; `mnbRate` opcionális; redundáns "Lekérdezés" gomb törölve (useEffect auto-tölt).
- **G15**: kanonikus `TransactionTypeName` union (drift-mentes); `typeFilter` típusos; TRANSFER címke-render.
- **G16**: konfigurálható `ariaLabel`; egyedi React key (`label-index`); locale-független teszt; "div/CSS" komment.
- **G23**: O(1) előző-hó Map (O(n²) helyett); `previousTotalTurnoverHuf` MINDEN előző-régiót összegez; `YearMonth.parse` hibás formátum → `ValidationException` (HTTP 400); `BigDecimal` string-konstruktor (double-kerekítés ellen).
- **G14**: bizonylat-dátum domain-timestampből (createdAt/cancelledAt); központi dátumformázó; null refundAmount → "—".

## Verzió + telepítő (v2.26.21, UNSIGNED build, Downloads-ban)
- `Penztar-Setup-2.26.21-20260522.exe` — 283.83 MB, SHA-256 `2B0A85E4B648E99491ACB56479C3705E915280BBC2E0555BB06D8F58E312DED2`
- `Kozponti-Iranyitokozpont-Setup-2.26.21.exe` — 101.06 MB, SHA-256 `AA1F60C67224559AA6C9C7D851C5AE3869793F5D9349719279A5B345DEB9AC26`
- `Arfolyamkeszito-Setup-2.26.21.exe` — 101.06 MB, SHA-256 `CF83B1D1741BAC54241C49BBCF4C20DDA5C0ACB5E1FDB135119AA96DE3616E91`
- `Penztar-Eltavolito-2.26.21-20260522.exe` — verzió-független, SHA-256 `5D84BE6AA024D9543B5B13F9E846255A6E05F700D8AE4750007E97539B5BDFB4`

## Gap-backlog állapot (15/23 KÉSZ)
- **KÉSZ:** G1, G2, G4, G5, G6, G9, G10, G12, G14, G15, G16, G17, G18, G21, G23
- **BLOKKOLT:** G3 (wizard↔NavClosing architektúra-link kell)
- **Üzleti/kliens döntés:** G8 (fix 5% letét?), G11 (10M hard-block supervisor-approval UI a pénztárgépen — a backend már flageli `requiresManagerApproval`-t)
- **RFM-kliens (kockázatos, futó-app verifikáció):** G7, G22
- **Nagy (új entitás/migráció + UI):** G19 (munkavállaló al-nyilvántartások), G20 (beállítás-képernyők)
- **Részben:** G13 (UN ENTITY kész; EU-lista ENTITY bővítés hátra)

Részletes backlog: `EXCMD/_compare/00-KONSZOLIDALT-GAPS.md`.
