# Modul: Forgalmi és készlet riportok  (forrás: `Felmérés/Valuta/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Dokumentumok/Forgalom 2024.09.xlsx`, `.../Forgalmak 2015-2024.ods`, `.../KEZD2410.xlsx`, `.../Havi forgalom Békéscsaba körzet összesen.jpg`, `.../Napi pénztár jelentés.jpg`, `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Segédanyagok Valuta/forgalom 2024 02 hó.xlsx`, `Felmérés/Valuta/penztari_mozgasok.PNG`)

## 1. Cel (egy mondat)
A régi program havi/napi forgalmi és készlet riportjainak STRUKTÚRÁJÁT (lapok, oszlopfejlécek, összesítő szintek) hűen leírni — cég-szintű havi valutánkénti forgalom, körzet/iroda bontás, napi pénztárjelentés és körzet havi forgalmi összesítő.

## 2. Scope
### IN
- Havi valutánkénti forgalmi riport cégenként (Best Change, East Change, Pannon Change, Expressz Zalog) — `forgalom 2024 02 hó.xlsx` (5 lap), `Forgalom 2024.09.xlsx` (1 cég, 1 lap "Munka1").
- Körzet → iroda → valuta hierarchikus bontás egy lapon belül.
- Napi pénztárjelentés (bizonylat-szintű forint mozgások, nyitó/záró/forgalom) — `Napi pénztár jelentés.jpg`.
- Körzet havi forgalmi összesítő (napi vétel/eladás Ft, vevők/eladók száma, pénztáros, trend) — `Havi forgalom Békéscsaba körzet összesen.jpg`.
### OUT
- Készlet riport tényleges adattartalma → `KEZD2410.xlsx` (régi OLE2 binary), `Készletek 2024 09`, `Készlet 2024 02` (TBD, nem kinyerhető / nem létezik).
- `Forgalmak 2015-2024.ods` éves trend tartalma (titkosított/binary content.xml → TBD).
- `penztari_mozgasok.PNG` ER-diagram pontos mező-szintű tartalma (kis felbontás → TBD).
- Bármilyen árfolyamszámítás / kerekítési logika (külön modul).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Napi pénztárjelentés saját pénztárra | CASHIER |
| Értéktáros / Főértéktáros | Iroda/körzet forgalmi riport | VAULT_KEEPER / HEAD_VAULT_KEEPER |
| Ügyvezető / Belsőellenőr | Cég-szintű havi összesítő, körzet trend | EXECUTIVE / INTERNAL_AUDITOR |
| admin | Minden riport | ADMIN |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Havi forgalmi riport fejléc cég + hónap megnevezéssel (pl. "EXCLUSIVE BEST CHANGE KFT 2024 SZEPTEMBER HAVI FORGALMA") | `Forgalom 2024.09.xlsx` R0 sharedStrings | M | frontend-react, kozponti-client |
| FR-2 | Oszlopfejlécek: VALUTA NEME, VALUTA VÉTEL, VALUTA ELADÁS, VALUTA ÁTADÁS, VALUTA ÁTVÉTEL, ÖSSZEGE, FT ÉRTÉKE, KÉSZPÉNZES, BANKKÁRTYÁS | `Forgalom 2024.09.xlsx` R1–R2 | M | frontend-react |
| FR-3 | Soronkénti bontás valutánként (AUD, BAM, BGN, CAD, CHF, CZK, EUR, GBP, HUF, ILS, JPY, NZD, PLN, RON, RSD, TRY, USD, CNY, RUB, THB, MXN, BRL, UAH ...) | `Forgalom 2024.09.xlsx` + `forgalom 2024 02 hó.xlsx` SS | M | frontend-react |
| FR-4 | Hierarchikus csoportosítás: KÖRZET → iroda (sorszámozott, pl. "10. SZEKSZÁRD ÉRTÉKTÁR", "11. BONYHÁD") → valuta-sorok → "ÖSSZESEN:" iroda-szinten | `Forgalom 2024.09.xlsx` R3–R4 + SS | M | frontend-react |
| FR-5 | Körzetek: SZEKSZÁRDI, SZEGEDI, KECSKEMÉTI, DEBRECENI, NYÍREGYHÁZAI, BÉKÉSCSABAI, PÉCSI, KAPOSVÁRI (+ ZÁLOGI körzet az Expressz Zalog lapon) | `forgalom 2024 02 hó.xlsx` SS | M | frontend-react |
| FR-6 | Cég-szintű összesítő sor ("Best Change Kft Összesítése:", "East Change...", "Pannon Change...", "Expressz Zalog Kft Összesítése:") + záró "Ö S S Z E S E N :" | `forgalom 2024 02 hó.xlsx` SS | M | frontend-react |
| FR-7 | Több cég külön munkalapon (Best Change / East Change / Pannon Change / Expressz Zalog / Munka1 összesítő) | `forgalom 2024 02 hó.xlsx` sheet names | S | frontend-react |
| FR-8 | Napi pénztárjelentés fejléc: cégnév + "NAPI PÉNZTÁR JELENTÉS" + iroda (pl. "BÉKÉSCSABA ÉRTÉKTÁR"), cím, dátum (nap+hét napja) | `Napi pénztár jelentés.jpg` | M | penztar-client |
| FR-9 | Napi pénztárjelentés tételsor oszlopok: Sorszám, Bizonylatszám, Tranzakció, Bank/ptár, Bevétel, Kiadás | `Napi pénztár jelentés.jpg` | M | penztar-client |
| FR-10 | Tranzakció-típusok a jelentésben: "forint - átvétel <kód>", "forint - átadás <kód>" (kód pl. ERB, PRB, JRB, RB, 76) | `Napi pénztár jelentés.jpg` tételsorok | M | penztar-client |
| FR-11 | Napi pénztárjelentés alsó összesítő: BEVÉTELI BIZONYLATOK (darab) + KIADÁSI BIZONYLATOK (darab); FORGALOM / NYITÓ / ZÁRÓ / ÖSSZESEN mátrix bevétel- és kiadás-oszloppal (záró=nyitó+bevétel-kiadás logika) | `Napi pénztár jelentés.jpg` | M | penztar-client |
| FR-12 | Napi pénztárjelentés lábléc: helyszín + dátum + "pénztáros" aláírás-vonal | `Napi pénztár jelentés.jpg` | S | penztar-client |
| FR-13 | Körzet havi forgalmi összesítő fejléc: "<KÖRZET> KÖRZET <ÉV> <HÓNAP> FORGALMI ADATAI" + "<KÖRZET> KÖRZET ÖSSZESEN" | `Havi forgalom Békéscsaba körzet összesen.jpg` | M | frontend-react, kozponti-client |
| FR-14 | Körzet havi riport oszlopok: Dátum, Vétel (Ft), Eladás (Ft), Ügyfelek száma (Vevők / Eladók), Pénztáros neve | `Havi forgalom Békéscsaba körzet összesen.jpg` | M | frontend-react |
| FR-15 | Körzet havi riport ÖSSZESEN sor (vétel/eladás/vevők/eladók) + Munkanap (nap), Átl.forg (átlagos napi forgalom vétel/eladás), Trend (%, előző hóhoz), Előzőhó (referencia) | `Havi forgalom Békéscsaba körzet összesen.jpg` | M | frontend-react |
| FR-16 | Forint-összegek formátuma "X.XXX.XXX.- Ft" (napi jelentés) ill. szóköz-ezres "X XXX XXX" (körzet riport) | `Napi pénztár jelentés.jpg`, `Havi forgalom Békéscsaba körzet összesen.jpg` | S | penztar-client, frontend-react |
| FR-17 | Éves (több éves, 2015–2024) forgalmi trend riport | `Forgalmak 2015-2024.ods` (csak fájlnév + felépítés ismert) | C | kozponti-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Multi-tenant: cég-szintű szűrés (Best/East/Pannon/Expressz) | minden lekérdezés companyId-ra szűr |
| NFR-2 | Nagy iroda-szám kezelése (egy cégen ~74+ iroda, 8 körzet) | riport renderelés <3 s 74 iroda × 23 valuta esetén |
| NFR-3 | Forint-kerekítés a magyar 5 Ft konvenció szerint | minden HUF összeg roundHuf |

## 6. Adatmodell-erintettseg
- Forgalom = aggregáció tranzakciókból (vétel/eladás/átadás/átvétel) valuta × iroda × nap dimenzión. Postgres: tranzakció entitás már létezik; riport read-only nézet/aggregáció.
- Körzet (régió) → iroda (branch) → cég (company) hierarchia; iroda-sorszám + név.
- Napi pénztárjelentés: nyitó/záró/forgalom forint-egyenleg pénztáranként + naponta, bizonylat-tételek.
- SQLite mirror: IGEN a napi pénztárjelentéshez (penztar-client offline), NEM a cég-szintű havi összesítőhöz (központi). Migráció: TBD (a meglévő tranzakció-séma elégséges-e az aggregációhoz, ellenőrzendő).

## 7. Fuggosegek
- Belső: tranzakció modul (vétel/eladás/átadás/átvétel), iroda/körzet/cég törzs, árfolyam (Ft érték számításhoz).
- Külső API: nincs (kizárólag belső tranzakciós adat).
- Adatbázis: Postgres (aggregáció), SQLite (napi pénztár offline).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Körzet | Földrajzi régió, irodák csoportja (pl. Szekszárdi körzet) |
| Értéktár | Körzet központi készpénz-tárolója (pl. "10. SZEKSZÁRD ÉRTÉKTÁR") |
| Átadás / Átvétel | Pénztár ↔ értéktár forint-mozgás (kiadás/bevétel oldal) |
| Nyitó / Záró | Napi kezdő- és végegyenleg forintban |
| Forgalom | Napi bevétel- és kiadás-oldali összforgalom |
| Készpénzes / Bankkártyás | Fizetési mód bontás a forgalmi riportban |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd a forrás xlsx fejléceket (sharedStrings + sheet1 első 5 sor) és a 3 képet a fenti FR-ekhez.
- A régi OLE2/titkosított fájlok adattartalma NEM elérhető → ne találgass, TBD.
### 9.2 Fazisok
- F1: Havi valutánkénti forgalmi riport (FR-1..7) — acceptance: körzet→iroda→valuta fa renderelődik, cégenkénti és záró összesítő helyes.
- F2: Napi pénztárjelentés (FR-8..12,16) — acceptance: bizonylat-tételek + nyitó/záró/forgalom mátrix + darab-számok megjelennek, aláírás-vonal a láblécen.
- F3: Körzet havi forgalmi összesítő (FR-13..16) — acceptance: ÖSSZESEN + munkanap/átlag/trend/előzőhó számított sorok helyesek.
### 9.3 Tesztes
- Unit: aggregáció valuta×iroda×nap; nyitó+bevétel-kiadás=záró invariáns; trend% = aktuális/előzőhó.
- Integration: 74 iroda × 23 valuta riport generálás.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | Készlet riport oszlopstruktúrája | a feladat kérte, de a forrás nem kinyerhető | `KEZD2410.xlsx` OLE2 binary; `Készletek 2024 09` / `Készlet 2024 02` nem létezik a forrásban |
| 2 | `Forgalmak 2015-2024.ods` éves trend felépítése | több éves összehasonlítás | a content.xml titkosított/binary, nem olvasható |
| 3 | `penztari_mozgasok.PNG` ER-modell pontos mezői | adatmodell-validáció | kis felbontású diagram, tábla/mező-nevek olvashatatlanok |
| 4 | "ÁTADÁS"/"ÁTVÉTEL" oszlopok 0 értékkel — használatban vannak-e a havi forgalmi lapon | oszlop megtartás vs elhagyás | a mintában mind 0; külön átadás-átvétel modul fedi (b8-atadas-atvetel) |
| 5 | Kódok jelentése a napi jelentésben (ERB, PRB, JRB, RB, 76) | tranzakció-cél azonosítás | TBD (valószínűleg cél-iroda/bank rövidítés, nem dokumentált) |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (nem kinyerhető adat = TBD)
- [x] minden TBD jelölt
VERIFIKACIO: FR=17 db, TBD=5 db, érintett csomag(ok)=frontend-react, penztar-client, kozponti-client
