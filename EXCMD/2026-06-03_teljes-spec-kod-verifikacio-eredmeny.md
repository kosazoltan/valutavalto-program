# 2026-06-03 — Teljes EXCMD spec ↔ kód verifikáció (mind a 30 b*.md)

Készült: 2026-06-03. Módszer: 9 párhuzamos verifikáló ügynök, mindegyik a `b*.md` specek
funkcionális követelményeit (FR-*) a JELEN `main` kódhoz mérte, file:line bizonyítékkal,
szkeptikusan (ha nincs a kódban → OPEN). READ-ONLY felmérés, üzleti kód nem módosult ennél.

> **Fontos kontextus:** a 472 EXCMD MD-ből 457 az `_ai-protokoll/ai-workitems.jsonl` (generált
> ticket-SABLON, nem finding-lista), 30 a valódi `b*.md` követelmény-spec. Ez a fájl a 30 spec
> kimerítő átnézését rögzíti — a korábbi (2026-05-22) 6-ügynökös `00-KONSZOLIDALT-GAPS` (23/23
> gap KÉSZ) FRISSÍTÉSE és kiegészítése FR-szinten.

## Kategóriák

A nyitott elemek NEM mind „bug". Négy kategória:
- **A) Valódi funkcionális hiány, tiszta fix** — érdemes javítani (lásd „Akcióterv").
- **B) By-design eltérés / elavult spec-szöveg** — a kód tudatosan más (dokumentált döntés); NEM bug.
- **C) Credentials/protokoll-gated** — külső banki onboarding/protokoll nélkül nem megvalósítható (Raiffeisen REST, ERB terminál).
- **D) Kozmetikai / legacy-elrendezés / HW-runtime** — a funkció megvan, csak a Delphi vizuál/HW-kötés nem 1:1.

## Spec-enkénti összegzés (nyitott/részben elemek)

### B1 RFM (árfolyamkészítő) — 11 nyitott
- **A:** FR-RFM-12 Raiffeisen ±10% sáv-warning bekötése (a `rfmRules.raiffeisenBand` kész+tesztelt, de nincs hívó) [M]; FR-RFM-13 sáv-bázis választó (elszámoló/OTP) [M]; FR-RFM-19 R/S auto-képlet (P+disc / Q−disc) bekötés [M].
- **C/B:** FR-RFMUI-19/20/21 ARFDATA.DAT + FTP szétküldés → a rendszer HTTP/local-first publishre cserélte (by-design, de spec Must — terméktulajdonosi megerősítés kell).
- **B/D:** FR-RFM-08 (22 vs 28 valuta, dokumentált v2.5.61 döntés); FR-RFM-10 (soft-inactivate hard-delete helyett); FR-RFMUI-08 (1..54 checklista panel), FR-RFMUI-09/10 (5-pontos almenü felirat), FR-RFM-23 (zöld villogás), FR-RFMUI-02/06 (INTERNET oszlop).

### B2 Sztornó/Zárás — 7 nyitott
- **A:** FR-ZARUI-16..26 értéktári checklist + ellenőrző-személy adatmodell hiányzik (`checklist_progress`/`closure_auditor` tábla) [L]; FR-ZARUI-04 NAV-fiókérték eltérés gate + `nav_mismatch_log` + e-mail [M/L]; FR-ZAR-04/05 dekád/havi auto-felajánlás a wizard-indításnál [S/M]; frontend wizard hardcoded lépéslista (nem backend-driven típusfüggő) [M]; FR-ZAR-01/02 korábbi zárások lista + reprint web-UI [M].
- **B (doc-konfliktus):** 🔴 FR-SZT-19 készletpolitika — a spec „BUY-reversal: HUF nem változik" a MEGFIGYELT HIBÁT írta le; a kód STANDARD elszámolása HELYES (lásd `project_transaction_business_rules_2026_06_02`). → **spec-javítás**, NEM kód-átírás.
- **B:** FR-SZT-06 (napi plafon=3 a 4+ supervisor helyett — tudatos 2026-05-31 audit-döntés).

### B3 Bank/Auth — 11 nyitott
- **A:** FR-AUTH-01/02/03/04 egységes engedélykérő-adatlap + `ApprovalItems`/`TransactionApproval` entity (pénztár-azonosító, biz.szám, forintérték, valuta-soros bontás) [M-M-S-M]; FR-AUTH-06 magas-értékű AML supervisor-UI + engedélyező rögzítés [M]; FR-AUTH-08 állampolgárság autocomplete (most sima `<select>`) [S]; WebSocket/HTTP engedély-push a kozponti felé [M].
- **C:** FR-API-02 Raiffeisen REST API (OAuth2/mTLS) — credentials-gated [L]; FR-ERB-01..04 ERB terminál-protokoll [L].
- **B:** `mnb_exchange_rate_cache` source-oszloppal (séma-név eltérés, funkcionálisan lefedve).

### B4 Bizonylat/Foglaló — 22 nyitott (OPEN 11 + RÉSZBEN 11)
- **A (kulcs):** Biz. FR-15/16 **MÉGSEM bizonylat** (megszakított tranzakció, keresztben „MEGSEM" — biz.szám-kiesést előzhet meg) [S/M]; Biz. FR-8 forráskód-enum (GH/MN/IN/OR/AJ/NY/HI strukturált, most szabad string) [M]; Fogl. FR-13 visszafizetési adatok (kifizetés biz.szám/eredeti dátum) [S]; Fogl. FR-2/4/5 entity-mezők (rendeles_napja+jövő-tiltás, arfolyam_egyseg) [S/M].
- **DONE megerősítve:** b4-foglalo FR-16 (50M forrás-igazolás, #1005) — kész+tesztelt; a `_compare/03` régi 🔴 elavult.
- **D:** alternatív/összevont bizonylat-sablonok (FR-3/4/6), KKTG külön átadási/átvételi + címletjegyzék, jogcím külön A4.

### B5 Pénztár — 7 OPEN + 18 RÉSZBEN
- **A (kulcs):** FR-KC-04 címletező **célösszeg-egyezés validáció** („CIMLETEK RENDBEN", NFR-KC-01) [M]; FR-KC-16 override-jogcím `OTHER` + `handlingFeeApprovalId` [M]; FR-BSZUR-03/04 bizonylat-szűrő mezőnkénti (természetes+jogi személy) keresés [M]; FR-FM-01 verziószám a fejlécen [S].
- **DONE(flag):** FR-KC-11 10M jóváhagyás. **DONE:** FR-PM-13 plomba-validáció, FR-KC-15 config-RBAC, FR-PA-05 ügyfeles-szűrő (#1004).
- **L/HW:** FR-PA-11 AEE pénztárgép COM-port parancsok.

### B6 Beállítások — 13 nyitott
- **A:** képernyő-**elérhetőség** (a `/settings/penztar` route létezik, de egyetlen menü sem navigál rá) [S]; FR-06 napi-jelentés-jelszó megjelenítés + módosító gomb [M]; FR-01 „Vissza" gomb/fül-lista [S]; FR-04 élő színes előnézet [S]; FR-10 kez.ktg paraméter-panel deep-link [S].
- **A/L:** FR-11 **futófény** panel (model+UI) [M] + HW-soros [M]; FR-14 SQLite+Postgres perzisztencia (most localStorage-only) [L]; b6b **„Egyéb feladatok" menü** (NAV/OTP variáns) teljes modul hiányzik [L].

### B8 Átadás/Riport/Szankció — 7 nyitott
- **A:** Szankció FR-3 **pontszámok** (kód ALIAS=0.5/PARTIAL=0.7 vs spec 0.9/0.8) — compliance-pontosság [S]; Szankció FR-1 `.txt` (Terrorlista2008.txt) import [M]; manuális EU/UN endpoint szétválasztás [S]; Forgalom FR-5 `dest_code` ember-olvasható lookup (RB/ERB/76→név) [S].
- **B (üzleti döntés):** stale-küszöb 7 vs spec 30 nap (a kód szigorúbb); ÁFA FR-6 AK/AB/AV (Innova) vs spec Tesco(V-)/Metro(AV-); Forgalom FR-2 napi 1–31 mátrix (lehet by-design).
- **DONE megerősítve:** G5/G6 (NFD + ENTITY-import), G18 (készpénz/bankkártya bontás), FR-7/9/10 plomba teljes wire-through.

### B9 Körlevél/Munkavállaló — 8 nyitott
- **A (compliance, fontos):** FR-04 **FATF tier-akció a kassza-flow-ban** — a `FatfCountryRiskService` kész+verziózott, de a tranzakció-idejű AML hívás ország NÉLKÜL fut, és a CustomerPanel nem hívja a `screen`-t (1/a blokk / 1/b EDD nincs kikényszerítve, NFR-01 sérül) [L]; FR-05 source-of-funds **FE docType/docDate** mezők (a #1005 backend gate kész, de a FE nem gyűjti a típust → bekapcsolva mindig blokkolna) [M]; FR-02 körlevél-gate (flag-OFF default, nincs 403, nincs FE-zárolás, nincs IP-rögzítés, nincs offline ack) [L]; FR-03 gyanú-bejelentés/SUSPENDED [M]; NFR-03 medical-checks lista + CSV/Excel export [M]; FR-03(munkavállaló) 3 külön bizonyítvány-mező [M].
- **DONE:** kétlépcsős OAuth (FR-07), vault-worker felvétel (FR-08), szabadság/üzemorvosi al-táblák (V256).

### B7 / B10 — 0 implementálandó kód-FR
- B10 (egyeb-nem-funkcionalis / hardver-felmeres / zalog): mindhárom **FR=0 / scope-OUT** (a saját törzsében deklarálva). B7: projekt/forrás-anyagok, FR-jeik a b1-b6-ba formalizálódtak (G1-G23 backlog = kész); a frissebb FR-89 (SQLite sync-hiba perzisztencia) + FR-90 (vault-stock ERTEKTAR RBAC) verifikáltan DONE.

## Tényszerű korrekciók a korábbi állításokhoz
- A „A4 körlevél-gate (#1003) + FATF (#1002) DONE" PONTOSÍTANDÓ: a kód kész, de **production-default kikapcsolt** + a FATF tier-akció és a tranzakció-idejű hívás (kassza-flow) **nincs bekötve**.
- A b4-foglalo FR-16 (50M) viszont a #1005 óta **ténylegesen DONE** (a `_compare/03` régi 🔴 elavult).
