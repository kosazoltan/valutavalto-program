# Legacy halasztott döntések — verdikt (2026-06-10)

**Kontextus:** a 2026-05-23-i teljes legacy-verifikáció
(`EXCMD/legacy/06-FEJLESZT-VERIFIKACIO-EREDMENY.md`) néhány tételt „őszintén halasztva"
státuszban hagyott, döntésre várva. A user-direktíva (2026-06-10): a döntéseket a
Pascal-forrásokból kinyert tényanyag alapján kell meghozni. Az alábbi döntések tényalapja
a Pascal-fájlokból bináris szinten generált modul-kivonatok (`EXCMD/legacy/modules*`).

> **Forrás-elérhetőségi tény:** a nyers Pascal-fa (`Anti/`, `forrasok/`) a `.gitignore`
> 32–33. és 105. sora miatt NINCS a git-repóban — csak a lokális gépen él. A kivonatok
> (394 modul-MD) viszont közvetlenül belőlük készültek (archívumok kibontva, 223 egyedi
> .dpr lefedve — ld. `05-TELJES-FORRAS-LEFEDETTSEG.md`), így a döntések forrás-hűek.

## 1. SVISOR — tranzakció in-place adatjavító → VÉGLEGESEN ELVETVE

**Pascal-tényalap** (`fejleszt/uctrl/svisor/unit1.pas`, 45 KB): jogi személyes
bizonylatok (JOGI/JOGIBIZ) in-place javítása — `UPDATE JOGI SET FORINTOSSZEG=…`
(összeg-átírás!), név/okmány/dátum-szintaxis javítók (`NaturSyntaxis`, `OkmTipCtrl`,
`DatumCtrl`), „Természetes személyek adatai megjavítva" visszajelzéssel.

**Döntés: ELVETVE (architektúra-döntés meghozva).** Indok:
- A modern rendszer szándékosan immutable-ledger: az `audit_log`-on UPDATE/DELETE
  trigger-tiltott (CLAUDE.md invariáns), pénzügyi rekord javítása = sztornó + újra-
  rögzítés (StornoService, 4-szem-elv) — Pmt./NAV audit-nyomvonal követelmény.
- Az összeg in-place átírása (`UPDATE … FORINTOSSZEG=`) a mai szabályozási környezetben
  audit-nyomvonal-sértés lenne.
- A legacy adatminőség-javító funkciót (név/okmány-szintaxis) a modern rendszerben az
  ügyfél-törzs szerkesztése fedi (CustomerService, auditált), a tranzakción rögzített
  KYC-pillanatkép pedig szándékosan változatlan marad (a Pmt. szerinti 8 éves megőrzés
  azt őrzi, AMI rögzítésre került).

## 2. STATISZT — 300k+ sztornózott jogi-személy export → ELAVULT, NEM IMPLEMENTÁLANDÓ

**Pascal-tényalap** (`fejleszt/statiszt/unit1.pas`): `WHERE (STORNO=1) AND
(FIZETENDO>=300000)` szűrésű export a `DATA1710` táblába (BF1710/BT1710 forrásból) —
a NAV korabeli '1710-es adatszolgáltatásához készült egyszeri/időszaki kigyűjtő.

**Döntés: ELAVULT.** Indok: a DATA1710/BF1710 táblanevek a korabeli NAV-nyomtatványhoz
kötik a modult; a mai NAV-adatszolgáltatást a `NavClosingService` + `NavAbevXmlGenerator`
stack fedi a hatályos formátumban. A 300k-s küszöbű, sztornó-specifikus jogi-személy
export mai megfelelője nem létező kötelezettség; ha hatósági kérés merül fel, a
tranzakciólista + bizonylat-szűrő (REVERSAL típus + összeg-szűrő + jogi személy) ad-hoc
lefedi.

## 3. MONEGRAM / POSTTERM / TRADE — korábbi verdiktek MEGERŐSÍTVE

- **MONEGRAM**: a forrás-olvasás bizonyította, hogy adat-import eszköz, nem MoneyGram
  pénzátutalás → nincs gap (06-os doksi korrekciója érvényes).
- **POSTTERM**: kártyás-forgalom aggregátor → `MonthlyReportFullDto.cardTurnoverHuf` fedi.
- **TRADE alrendszer** (ETRADE/SETRADE/STRADE/SUMTRADE/PALYADIJ, telefon-feltöltés,
  matrica): szándékos scope-vágás — a cégprofil valutaváltó; a b10-zalog spec szerint a
  zálog (EXZ) külön termék. MARAD scope-on kívül.

## 4. Friss mintavételes legacy↔modern összevetés (2026-06-10, kód-elleni)

| Legacy viselkedés (Pascal-kivonatból) | Modern megfelelő | Verdikt |
|---|---|---|
| FOGLALO: lejárt foglalók takarítása (`DELETE FROM FOGLALOK WHERE (DATUM<`) | `ReservationService.autoExpireReservations` (`:498`): ACTIVE+lejárt → EXPIRED, letét a kasszába, készlet vissza; ütemezve (`SchedulerService:82`), PESSIMISTIC_WRITE idempotencia, tesztelt (T5/T6) | ✅ LEFEDETT (jobb: törlés helyett auditálható státusz) |
| FOGLALO: e-mail értesítések (`EmailekKuldese`, „AZ E-MAILEKET SIKERESEN ELKÜLDTEM") | `ReservationService.sendPreExpiryWarnings` (`:571`): idempotens in-app Notification 24 órával lejárat előtt | ✅ LEFEDETT (infra-csere: e-mail → notification-stack) |
| FOGLALO: „AZ ÜGYFÉL ADATAI ÉRVÉNYTELENEK" validáció | foglaló-létrehozás Customer-kötelező + validáció (`createReservation` ügyfél/lejárat-ellenőrzés `:100`) | ✅ LEFEDETT |

## Összegzés

A 2026-05-23-i „0 fennmaradó implementálható gap" verdikt a mai mintavételes
ellenőrzésen is állt. A halasztott tételek mindegyike döntéssel lezárva (elvetve/
elavult/scope-on kívül) — egyik sem kódteendő. A legacy↔modern paritás nyitott
tételei ezzel: **nincs**.
