# Modul: Régi Delphi valutaprogram — Kezelési költség, címletezés, engedélyezés

<system_context>
## Rendszerkontextus és Háttér
Ez a modul a régi valutaprogram kezelési-költség-menüjének, a címletezési funkcióknak (kezelési díj és zárások), az egyedi kötésnek (ERB), a havi tablónak, valamint a 10 millió HUF feletti nagy összegű tranzakciók országos ellenőrzésének és vezetői engedélyezésének specifikációja.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | Kezelési díj átvétel/átutalás/jelenlegi készlet megtekintés, címletezés, tranzakció (vásárlás/eladás) rögzítés. | TBD |
| Engedélyező (vezető) | "Engedély megadása" / "Nem engedélyezett" döntések meghozatala a 10M feletti tranzakciókra; "Engedélyező" azonosítás. | TBD (Lásd: TBD-2) |
| Belsőellenőr / Vezető | Havi tabló statisztika, forgalom megtekintés, Excel-riportok exportja. | TBD |

### Hatókör (Scope)
#### IN
- "KEZELÉSI KÖLTSÉGEK" menüpontjai.
- "KEZELÉSI KÖLTSEG CIMLETEZÉSE" címletező felület és HUF címletek szerinti lebontása.
- "Címletezés" zárási almenüi (esti zárás, kezelési díj zárás stb.).
- "EGYEDI KÖTES RB" (ERB) szállítási/átadási űrlap.
- "HAVI TABLÓK KIJELZÉSE" riportmenü és paraméter-kiválasztója.
- "TRANZAKCIÓ ENGEDÉLYEZÉSE" és "AZ ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE" 10 millió feletti folyamata.
- "AZ E-MAILEKET SIKERESEN ELKÜLDTEM" értesítő üzenet vásárláskor.

#### OUT
- A kinyomtatott bizonylatok/nyugták formázása (lásd `b4-bizonylatok.md`).
- A teljes valuta-törzs kezelése (itt csak a címletezésnél megjelenített valuták köre).

### Technológiai verem (Tech Stack)
- Pénztári kliens (`penztar-client`)
- Helyi SQLite mirror az offline rögzítéshez (címletek, lokális tranzakció-napló, engedélykérések állapota)
- Központi Postgres adatbázis a szinkronizációhoz, havi statisztikákhoz és az országos ellenőrzéshez
- SMTP vagy egyéb levelező integráció az engedélykérő emailek küldésére
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-KC-01: Kezelési költségek menü struktúrája
- **Leírás**: A rendszerben elérhetővé kell tenni a "KEZELÉSI KÖLTSÉGEK" menüt az alábbi opciókkal: "KEZELÉSI KÖLTSÉGEK ÁTVÉTELE", "KEZELÉSI KÖLTSÉGEK ÁTUTALÁSA", "A KEZELÉSI KÖLTSÉGEK JELENLEGI KÉSZLETE", "BIZONYLATOK MEGTEKINTÉSE", "VISSZA".
- **Forrás**: `Kezelési költségek.JPG`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás (menüpont kijelölés).
- **Kimenet / Visszajelzés**: A kiválasztott almenü megnyitása.
- **Validációk és Kényszerek**: Nincs.

### FR-KC-02: Kezelési költség címletező képernyő és valuták
- **Leírás**: Meg kell jeleníteni a "KEZELÉSI KÖLTSEG CIMLETEZÉSE" felületet. A bal oldalon valuta-listát kell biztosítani (oszlopok: VNEM, Magyar név, Jelölőnégyzet).
  - A megfigyelt és kezelendő valuták: AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF (kiemelt/piros színnel), ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD.
- **Forrás**: `Kezelési költségek címletezése.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Valuta törzslista (Lásd: TBD-6).
- **Kimenet / Visszajelzés**: Valutalistázó rács.
- **Validációk és Kényszerek**: HUF sor kiemelése kötelező.

### FR-KC-03: Címletenkénti darabszám bevitel HUF-ra
- **Leírás**: A címletező jobb oldalán meg kell valósítani a címletenkénti darabszám bevitelt HUF esetén: 20 000, 10 000, 5 000, 2 000, 1 000, 500, 200, 100, 50, 20, 10, 5 címletekhez. (A 2-es és 1-es címleteknek szürkítettnek/letiltottnak kell lenniük). Minden sorban ki kell számolni és meg kell jeleníteni a Darabszám × Címletérték részösszeget (pl. "2 000-es x 2 = 4 000").
- **Forrás**: `Kezelési költségek címletezése.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Címletenként megadott darabszámok (egész értékek).
- **Kimenet / Visszajelzés**: Részösszegek kiszámítása.
- **Validációk és Kényszerek**: Negatív darabszám nem adható meg.

### FR-KC-04: Címletezés összesítő és jóváhagyás
- **Leírás**: A címletező alján meg kell jeleníteni az összesített Forint összeget (pl. "HUF 14 405"), és biztosítani kell a "CIMLETEK RENDBEN - TOVÁBB" jóváhagyó gombot, valamint az ablak bezárását ("X").
- **Forrás**: `Kezelési költségek címletezése.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Részösszegek.
- **Kimenet / Visszajelzés**: Összegzett HUF érték.
- **Validációk és Kényszerek**: A "CIMLETEK RENDBEN" gomb csak akkor válik aktívvá, ha a darabszámok alapján kalkulált összeg megegyezik a könyvelendő célösszeggel (NFR-KC-01).

### FR-KC-05: Címletezés - Zárások menü
- **Leírás**: Meg kell jeleníteni a "Címletezés" almenüt a zárási folyamatokhoz: "ESTI ZÁRÁS CÍMLETEZÉSE", "KEZELÉSI DÍJ CÍMLETEZÉSE", "WESTERN UNION CÍMLETEZÉSE" (szürkített/inaktív), "ÁFA PÉNZTÁR CÍMLETEZÉSE" (szürkített/inaktív), "FOGLALÓ KÉSZLET CÍMLETEZÉSE" (szürkített/inaktív), "ELEKTROMOS KERESKEDÉS CIMLETEZÉSE" (szürkített/inaktív). Valamint a "VISSZA" és "KILÉPÉS" gombokat.
- **Forrás**: `Cimletezés menü.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Megfelelő zárási címletezés indítása.
- **Validációk és Kényszerek**: Az inaktív pontok rákattintásra nem indulhatnak el.

### FR-KC-06: Zárások háttér-menü pontjai
- **Leírás**: A zárások képernyő háttér-menüjében (amely a címletező ablak alatt található) meg kell jeleníteni: "KÜLÖNFÉLE CÍ...", "CÍMLETEK KIN...", "A MAI NAPI ZÁRÁS...", "A HAVI ZÁRÁS VÉ...", "MÉGSEM" menüpontokat.
- **Forrás**: `Cimletezés menü.jpeg`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Háttérmenü kiválasztás.
- **Kimenet / Visszajelzés**: A megfelelő záró képernyő megjelenítése.
- **Validációk és Kényszerek**: Nincs.

### FR-KC-07: Egyedi Kötés RB (ERB) űrlap
- **Leírás**: Meg kell valósítani az "EGYEDI KÖTES RB" szállítási/átadási űrlapot az alábbi mezőkkel: TÁRSPÉNZTÁR (előre kitöltve: "ERB / EGYEDI KOTES RB"), SZÁLLÍTÓ NEVE, PLOMBASZÁM, MEGJEGYZÉS; valamint a "KÖNYVELHETŐ" és "MÉGSEM" gombokat.
- **Forrás**: `ERB Egyedi kötés.JPG`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Szállító neve, plomba azonosítója, megjegyzés.
- **Kimenet / Visszajelzés**: Rögzített ERB átadás.
- **Validációk és Kényszerek**: Plombaszám és szállítónév kitöltése kötelező a könyvelhetőséghez.

### FR-KC-08: Havi tablók kijelzése menü
- **Leírás**: Havi adatok megtekintéséhez biztosítani kell az egység (pl. "GYULA") és időszak (pl. "2024 MÁRCIUS") kijelzést, valamint a következő menüpontokat: "HAVI STATISZTIKA", "HAVI FORGALOM", "FORGALMI GRAFIKONOK", "VALUTA KÉSZLETEK", "FORGALOM-EXCEL KÉSZÍTÉSE", "KÉSZLET-EXCEL KÉSZÍTÉSE", "VISSZA A FŐMENÜRE".
- **Forrás**: `Havi tabló.JPG`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Havi kimutatás vagy excel fájl generálás.
- **Validációk és Kényszerek**: Nincs.

### FR-KC-09: Havi tabló paraméterezés
- **Leírás**: A Havi Tabló képernyő jobb oldalán egy "KIJELZETT HÓNAP" választó blokkot (Év, Hónap legördülő lista, "HÓNAP RENDBEN" gomb) és egy "VALUTAVÁLTÓ EGYSÉG" választót kell elhelyezni.
- **Forrás**: `Havi tabló.JPG`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Év, Hónap, Egység azonosító.
- **Kimenet / Visszajelzés**: Kiválasztott időszak és fiók aktiválása.
- **Validációk és Kényszerek**: Csak lezárt időszakok választhatóak ki zárási statisztikához.

### FR-KC-10: Ügyfél országos ellenőrzése panel
- **Leírás**: A 10 millió HUF feletti váltások esetén megjelenő "AZ ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE" panelen kötelezően meg kell adni és ellenőrizni az ügyfél személyazonosító adatait: ÜGYFÉL NEVE, SZÜLETÉSI CSALÁDI- ÉS UTÓNEVE, LEÁNYKORI NEVE, ANYJA NEVE, SZÜLETÉSI HELY.
- **Forrás**: `Tranzakció engedélyeztetése.jpeg`, `Ügyfél országos ellenőrzése... .jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Ügyfél személyes adatai.
- **Kimenet / Visszajelzés**: Ellenőrzési státusz visszajelzése.
- **Validációk és Kényszerek**: Az adatoknak meg kell egyezniük a hivatalos okmányokkal.

### FR-KC-11: Nagy összegű tranzakció engedélyezése panel
- **Leírás**: A 10 millió HUF feletti tranzakcióknál a rendszernek kötelezően fel kell dobnia a "TRANZAKCIÓ ENGEDÉLYEZÉSE" panelt a következő elemekkel:
  - Figyelmeztető szöveg: "Az ügyfél 10 millió felett vált"
  - "A pénz forrása" kötelező legördülő mező (pl. "JÖVEDELEM") (NFR-KC-03)
  - "Engedélyező" sárga színű jóváhagyási/jelszó beviteli mező (TBD-2)
  - "Engedély megadása" és "Nem engedélyezett" döntési gombok.
- **Forrás**: `Tranzakció engedélyeztetése.jpeg`, `Ügyfél országos ellenőrzése és engedély kérés tranzakciókra.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénz forrása kód, engedélyező jelszó/kód.
- **Kimenet / Visszajelzés**: Tranzakció feloldása vagy elutasítása.
- **Validációk és Kényszerek**: Az "Engedély megadása" gomb letiltott, amíg az Engedélyező és a Pénz forrása mező nincs kitöltve (NFR-KC-02).

### FR-KC-12: Természetes személy azonosítás gyorsbillentyű (F5)
- **Leírás**: Az ügyfél-azonosító felületen a fejlécnek jeleznie kell a "TERMÉSZETES SZEMÉLY" típust. Támogatni kell az országos listás azonosítást az "F5" gyorsbillentyűvel, valamint a kilépést a "Mégsem azonosít" gombbal. Fel kell tüntetni az "Állampolgársága" mezőt (pl. "HU MAGYAR").
- **Forrás**: `Ügyfél országos ellenőrzése és engedély kérés tranzakciókra.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: F5 leütés vagy kattintás.
- **Kimenet / Visszajelzés**: Keresés eredménye az országos listában (TBD-4).
- **Validációk és Kényszerek**: Nincs.

### FR-KC-13: Sikeres email küldés megerősítő üzenet
- **Leírás**: A vásárlás során az engedélykérési e-mailek elküldését követően meg kell jeleníteni egy megerősítő modális ablakot (ablak címe: "ibvalto", szövege: "AZ E-MAILEKET SIKERESEN ELKÜLDTEM", gomb: "OK").
- **Forrás**: `Vásárlás email elküldve üzenet.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Sikeres email küldési státusz a háttérből.
- **Kimenet / Visszajelzés**: Modális felugró ablak.
- **Validációk és Kényszerek**: Az ablak bezárásáig a tranzakciós képernyő inaktív marad.

### FR-KC-14: Tranzakciós Vásárlás (Kliens) képernyő
- **Leírás**: A vásárlás felületen megjelenő oszlopok: DNEM, VALUTA MEGNEVEZÉSE, ÁRFOLYAM, BANKJEGY, FIZETENDŐ.
  - Alul meg kell jeleníteni: "Kezelési díj 3 %" (vagy az aktuális ráta), "Kezelési díj engedmények", "Nettó forint", "Kezelési költség", "Kerekítési kompenzáció", "BLOKKSZÁM" (pl. sorszám), nagy betűs "FIZETENDŐ" végösszeg.
  - Funkciógombok: "Készen van (End)", "Vissza a főmenüre (Escape)".
- **Forrás**: `Vásárlás email elküldve üzenet.jpeg` (háttérben lévő vásárlási képernyő)
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Validációk és Kényszerek**: A kerekítési kompenzációt a HUF készpénzes kerekítési szabályoknak megfelelően kell kalkulálni.

### ### [FR-KC-15] [Kezelési költség konfiguráció jogosultságai]
- **Leírás**: A kezelési költség globális és sávos konfigurációjának módosítását (`HandlingFeeConfigPage.tsx`) a backend oldalon `@PreAuthorize` kapu védi. A hozzáférést a `MANAGER` és `ADMIN` szerepkörökön túl ki kell terjeszteni a `FOERTEKTAR` (Főértéktáros) és `UGYVEZETO` (Ügyvezető) kanonikus szerepkörökre is. Pénztárosi szerepkör számára a konfigurációs felület és API elérése tiltott.
- **Forrás**: 2026-06-02 tranzakciós audit 5. pont
- **Prio**: Magas (P1)
- **Csomag/Komponens**: backend / frontend-react
- **Bemenő adatok**: Felhasználói JWT jogosultságok
- **Kimenet / Visszajelzés**: Hozzáférés megadása vagy 403-as hiba dobása

### ### [FR-KC-16] [Kezelési költség explicit override workflow (F9)]
- **Leírás**: A tranzakciós oldalon az `F9` gombbal kezdeményezett kezelési költség módosításnak egy struktúrált, auditálható munkafolyamatot kell követnie a puszta számbeírás helyett. A dialognak és a backend DTO-knak az alábbi mezőket kell kötelezően kezelniük és validálniuk:
  - `handlingFeeOverrideType`: `NONE` (nincs módosítás), `HALF` (díjfél), `WAIVED` (díj elengedése), `SPECIAL` (speciális fix díj).
  - `handlingFeeOverrideReason`: `MANAGER_APPROVAL` (vezetői jóváhagyás), `CHIEF_VAULT_APPROVAL` (főértéktárosi jóváhagyás), `CUSTOMER_CARD` (ügyfélkártya), `PROMOTION` (akció), `OTHER` (egyéb).
  - `customerCardNumber`: az ügyfélkártya száma, melynek megadása kötelező, ha a módosítás típusa `HALF` és az oka `CUSTOMER_CARD`.
  - `handlingFeeApprovalId`: a jóváhagyás azonosítója (token vagy kód). Speciális díj (`SPECIAL`) alkalmazásához vezetői (`UGYVEZETO`/`FOERTEKTAR`/`ADMIN`) jóváhagyás szükséges.
  - A backend `HandlingFeeCalculator` a fenti struktúra szerint köteles újraszámolni és validálni az eltérést, a kliens által küldött nyers összeget tilos vakon elfogadni szerveroldali ellenőrzés nélkül.
- **Forrás**: 2026-06-02 tranzakciós audit 6. pont
- **Prio**: Magas (P0)
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Kiválasztott override típus, ok, összeg, kártyaszám és jóváhagyás kód
- **Kimenet / Visszajelzés**: Validált kezelési költség alkalmazása
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

### Postgres és SQLite táblák:

#### 1. `kezelesi_koltseg_egyenlegek`
A kezelési díjak pénznemenkénti aktuális egyenlegének követése fiókonként.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `fiok_kod` (VARCHAR(10) NOT NULL)
- `devizanem` (VARCHAR(3) NOT NULL)
- `osszeg` (NUMERIC(15, 2) NOT NULL DEFAULT 0.0)
- `utolso_tranzakcio_id` (INTEGER, Nullable)

#### 2. `kezelesi_koltseg_cimletezesek`
Zárásokhoz és napi kezelési költség elszámoláshoz kapcsolódó darabszámos snapshotok.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `zaras_id` (INTEGER NOT NULL) -- Külső kulcs a zárási/elszámolási tranzakcióhoz
- `devizanem` (VARCHAR(3) NOT NULL)
- `cimlet_ertek` (INTEGER NOT NULL) -- Pl. 20000, 10000, 5000 stb.
- `darabszam` (INTEGER NOT NULL)
- `reszosszeg` (NUMERIC(15, 2) NOT NULL)

#### 3. `tranzakcio_engedelyek`
10 millió HUF feletti ügyletek jóváhagyásai.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `tranzakcio_sorszam` (VARCHAR(50) UNIQUE NOT NULL)
- `ugyfel_okmanyszam` (VARCHAR(50) NOT NULL)
- `penz_forrasa` (VARCHAR(50) NOT NULL) -- Pl. 'JOVEDELEM'
- `engedelyezo_kod` (VARCHAR(50) NOT NULL) -- A jóváhagyó supervisor kódja
- `engedelyezes_ideje` (TIMESTAMP NOT NULL)
- `statisztika_statusz` (VARCHAR(20) NOT NULL DEFAULT 'ENGEDELYEZETT') -- ENGEDELYEZETT, ELUTASITOTT
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Országos Kereső és AML Szolgáltatás**: Az F5 gyorsbillentyűre lefutó országos ügyfélellenőrzés (szankciós listák, PEP, korábbi váltások összegzése) (FR-KC-10, FR-KC-12).
- **Levelező Rendszer (Email Gateway)**: Az engedélykérések / tranzakciós értesítők kiküldésére használt belső SMTP kliens (FR-KC-13).
- **Zárási és Elszámolási folyamat**: Az esti zárás és a kezelési díj zárás a címletező modulból nyeri ki a darabszámos adatokat (FR-KC-05).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- A `Kezelési költségek címletezése.jpeg` alapján HUF érme- és bankjegy címlet konfiguráció elkészítése.
- Megtervezni a 10M feletti tranzakció-blokkoló modális ablak frontend szerkezetét.

### Fázis 2: Backend megvalósítás
- Az engedélyezési és ellenőrzési API-k lefejlesztése (pénz forrása és engedélyező ellenőrzése).
- Integrálni az SMTP email-küldő modult és hozzárendelni a sikeres státusz visszajelzését.
- Offline SQLite táblák előkészítése a helyi címletezési adatok mentéséhez.

### Fázis 3: Frontend megvalósítás
- Elkészíteni a darabszám-beviteli HUF rácsot a szürkített 2-es és 1-es gombokkal. A darabszám változásakor dinamikusan frissíteni a részösszegeket és az összesítést.
- Implementálni a 10M feletti "országos ellenőrzés" és "tranzakció engedélyezése" paneleket, a sárga engedélyező mező validálásával.

### Fázis 4: Verifikáció és Tesztelés
- Tesztelni, hogy a címletek szorzata és összege pontos-e.
- Tesztelni, hogy 10 millió feletti váltás esetén a rendszer valóban feldobja az engedélyező ablakot és blokkolja a könyvelést addig, amíg az érvényes supervisor jóváhagyás meg nem történik.
- Ellenőrizni az email sikeres kiküldését és a modális visszajelző ablak ("ibvalto") megjelenését.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| ID | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-1 | Pénz forrása legördülő lista | AML törzs | Milyen lehetséges értékeket kell tartalmaznia a legördülő listának a "JÖVEDELEM" mellett (pl. megtakarítás, ingatlanértékesítés)? |
| TBD-2 | Engedélyező mező hitelesítése | Biztonság, Működés | Az "Engedélyező" sárga mezőbe a supervisor jelszavát kell beírni, vagy kártyaolvasást / ujjlenyomatot / PIN kódot vár a rendszer? |
| TBD-3 | Email értesítés címzettje és tartalma | Üzleti folyamat | Kinek megy az email tranzakció engedélyezésekor (pl. compliance csoport, fiókvezető)? Mi az email pontos sablonja? |
| TBD-4 | Országos ellenőrzés belső logikája | AML / Integráció | Milyen adatbázist vagy külső API-t hív meg az országos ellenőrzés az F5 billentyű leütésére? |
| TBD-5 | 10 milliós engedélyezési küszöb | Üzleti szabály | Fixen 10 millió HUF a küszöbérték, vagy ez a jogszabályok változásával konfigurálható paraméterként kezelendő? |
| TBD-6 | Valuta törzs és címletlista más devizákra | Funkcionális lefedettség | A többi devizára (pl. EUR, USD, CHF) milyen címlet-sorokat kell megjeleníteni a darabszám-bevitelhez? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelmény (FR-KC-01-től FR-KC-14-ig) rendelkezik legalább egy képi forrás-hivatkozással.
- [ ] A 10M feletti tranzakció engedélyezési szabály és a Pénz forrása kitöltési kényszer dokumentált (NFR-KC-02, NFR-KC-03).
- [ ] A 6 darab TBD kérdés bekerült a TBD kockázati naplóba.
- [ ] A címletező HUF struktúrája (szürkített 1 és 2 Ft-osok) és a valuták listája pontosan megőrzésre került.
- [ ] Nem történt új üzleti logika kitalálása a meglévő képekhez képest.
</verification_checklist>
