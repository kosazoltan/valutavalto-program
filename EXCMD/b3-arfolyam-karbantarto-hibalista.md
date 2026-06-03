<system_context>
# Modul: Árfolyam-karbantartó hibalista

## Kontextus
Az Árfolyamkezelő (árfolyam-karbantartó) modulra bejelentett hibák és felhasználói igények javítási követelményekké alakításának leírása a forrás-hibalista alapján. A modul célja a hibás lapreferencia-másolások javítása, a valuták aktív/inaktív állapotkezelése, valamint a cella-szintű UX (billentyűzet-navigáció, kerekítések) fejlesztése a gyorsabb adatbevitel érdekében. A hibák a `3.189.0-20260216` teszt-verzió alapján lettek bejelentve.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`arfolyam-keszito-client`, `penztar-client` a valuta-szűréshez)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Főértéktáros (Main Treasurer) / Rendszeradminisztrátor (System Administrator)**: Jogosult a központi árfolyam-karbantartásra, a képletek beállítására és a valuták aktív/inaktív flagjének módosítására (RBAC érték: `ROLE_TREASURER`, `ROLE_ADMIN`).
- **Kasszás / Pénztáros (Cashier)**: Pénztári modulban csak az aktív valutákkal dolgozhat; árfolyamot kézzel csak supervisori jóváhagyás mellett írhat felül (RBAC érték: `ROLE_CASHIER`).

## Hatókör (Scope)
- **IN**:
  - Sor másolás/beillesztés lapreferencia-hiba javítása.
  - Aktív/inaktív valuták kezelése (megjelenítés, inaktiválás).
  - Cella-műveletek (másolás, kerekítés, billentyűzet-navigáció, enter-bevitel).
  - Ellenőrzés-folyamat (hibalista oszlop, művelet-szétválasztás, log).
  - Munkacsoport-létrehozás automatikus feltöltése.
  - Currency mező HUF egész értékűsége.
- **OUT**:
  - A teszt-verzió belső szoftverarchitektúrájának átalakítása.
  - Más modulok nem érintettek.
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-HL-01] [Sor másolás lapreferencia megőrzése]
- **Leírás**: Sor másolásakor és beillesztésekor a lapreferencia maradjon helyes: a `$LapT01` ne változzon `$LapT3`-ra. A „Copy selected row" -> „Paste to selected row" funkciók után a beillesztett sor képletei az eredeti lapra hivatkozzanak (pl. E oszlop: `=$LapT01!C9+0.1`, G oszlop: `=$LapT01!G9+0.1`), ne dobjanak #ERR hibát a rendszerben.
- **Forrás**: Hibalista: „Hibajelentés – Sor másolásakor helytelen lapreferencia"
- **Prio**: Magas (Kritikus)
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Forrás sor képletei + beillesztési cél
- **Kimenet / Visszajelzés**: Beillesztett sor képletei helyes hivatkozással
- **Validációk és Kényszerek**: A másolt lapreferencia stringnek változatlannak kell maradnia a beillesztés után.

### ### [FR-HL-02] [Lapreferencia-javítás általánossága]
- **Leírás**: A másolási hiba a `LapZ01` munkalapon is reprodukálható, így a javításnak általánosnak kell lennie a teljes sor másolás/beillesztés funkcióra vonatkozóan, nem pedig lapspecifikusnak.
- **Forrás**: Megjegyzések: „LapZ01 lapon is reprodukálható"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Bármely munkalapon végzett másolás
- **Kimenet / Visszajelzés**: Hibamentes beillesztés minden munkalapon
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-03] [Visszavonás (Ctrl+Z) támogatása]
- **Leírás**: Működő visszavonás (Ctrl+Z) funkció biztosítása a beillesztési és szerkesztési műveletek visszaállítására (korábban csak kézi javítás volt lehetséges).
- **Forrás**: Megjegyzések: „nincs működő visszavonás (Ctrl+Z)"
- **Prio**: Közepes
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Ctrl+Z billentyűkombináció
- **Kimenet / Visszajelzés**: Előző cellaállapot / sorállapot visszaállítása
- **Validációk és Kényszerek**: Az undo puffer mérete maximum 50 visszalépést támogasson munkamenetenként.

### ### [FR-HL-04] [0-ás lap aktív valuták szűrése]
- **Leírás**: A 0-ás lapon kizárólag az aktív státuszú valuták jelenhetnek meg.
- **Forrás**: Hibalista: „0-ás lapon csak az aktív valuták jelenjenek meg"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Valutalista aktív flaggel
- **Kimenet / Visszajelzés**: Szűrt táblázat sorok
- **Validációk és Kényszerek**: Az inaktív valuták sorai elrejtésre kerülnek.

### ### [FR-HL-05] [Munkalapok és pénztárgép valuta szűrése]
- **Leírás**: Minden munkalapon (táblázatban), valamint a pénztári programban (`penztar-client`) is kizárólag az aktív valuták jelenhetnek meg.
- **Forrás**: Hibalista: „Minden munkalap esetében csak az aktív valuták ... és a pénztári programban is"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client + penztar-client
- **Bemenő adatok**: Valuták státusza
- **Kimenet / Visszajelzés**: Szűrt nézetek a kliensekben
- **Validációk és Kényszerek**: A szűrésnek konzisztensnek kell lennie a teljes ERP rendszerben.

### ### [FR-HL-06] [Valuta inaktiválása]
- **Leírás**: A felhasználónak legyen lehetősége a valutákat inaktívvá tenni a törzsadat-kezelő felületen (korábban nem volt lehetséges).
- **Forrás**: Hibalista: „nem tudok inaktívvá tenni valutákat -> tudjak"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Valuta kiválasztása + aktív flag módosítása
- **Kimenet / Visszajelzés**: Valuta státusz frissülése az adatbázisban
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-07] [Cella másolhatóság]
- **Leírás**: Biztosítani kell a cellák értékének egyedi másolhatóságát a táblázatban.
- **Forrás**: Hibalista: „A cellákat lehessen másolni. 👍"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cellakijelölés + Copy parancs
- **Kimenet / Visszajelzés**: Cellaérték vágólapra helyezése
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-08] [Matematikai kerekítés]
- **Leírás**: A cellákban végzett számítások eredményét a matematikai kerekítés szabályai szerint kell kerekíteni.
- **Forrás**: Hibalista: „Kerekítés matematikai szabály szerint 👍"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Kerekítendő decimal szám
- **Kimenet / Visszajelzés**: Kerekített érték
- **Validációk és Kényszerek**: Tizedesjegy pontosság devizanemenként paraméterezhető.

### ### [FR-HL-09] [Ellenőrző hibalista oszlop]
- **Leírás**: Az ellenőrzés elvégzésekor egy új, dedikált oszlopban jelenjen meg a hibalista a hibás cellák mellett.
- **Forrás**: Hibalista: „Ellenőrzés elvégzésekor egy új oszlopban hibalista"
- **Prio**: Közepes
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Ellenőrzési folyamat futtatása
- **Kimenet / Visszajelzés**: Hibaüzenetek megjelenítése a cellasorok végén
- **Validációk és Kényszerek**: Csak hibás soroknál jelenik meg szöveg.

### ### [FR-HL-10] [Műveletek szétválasztása]
- **Leírás**: Az Ellenőrzés, Mentés és Szétküldés műveleteket logikailag és vizuálisan is külön gombokra / lépésekre kell bontani.
- **Forrás**: Hibalista: „Ellenőrzés, Mentés, Szétküldés szétválasztása"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói kattintások
- **Kimenet / Visszajelzés**: Különálló folyamat-lépések
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-11] [Pénztárankénti naplózás]
- **Leírás**: Naplózási (audit log) funkció megvalósítása pénztáranként, amely tartalmazza a módosító nevét és a módosítás pontos dátumát/időpontját.
- **Forrás**: Hibalista: „Log pénztáranként (név,dátum)"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client + backend
- **Bemenő adatok**: Árfolyam-módosítás mentése
- **Kimenet / Visszajelzés**: Audit log bejegyzés rögzítése
- **Validációk és Kényszerek**: A log bejegyzések nem módosíthatók és nem törölhetők.

### ### [FR-HL-12] [Nyíl-billentyűs navigáció]
- **Leírás**: A felhasználónak lehetőséget kell biztosítani, hogy a billentyűzet navigációs nyilaival (Fel/Le/Balra/Jobbra) mozoghasson a táblázat cellái között.
- **Forrás**: Hibalista: „Szeretnék a billentyűzet navigációs nyilaival közlekedni a cellák között"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Nyíl billentyűk lenyomása
- **Kimenet / Visszajelzés**: Fókusz áthelyezése a szomszédos cellára
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-13] [Enter billentyűs cellaaktiválás]
- **Leírás**: Cellába történő adatbevitelnél az Enter billentyű lenyomásával lehessen aktiválni a cellát és azonnal írni bele (egér használata nélküli gyors munkavégzés támogatása).
- **Forrás**: Hibalista: „bevitelkor tudjam enterrel aktiválni a cellát..."
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Enter billentyű lenyomása kijelölt cellán
- **Kimenet / Visszajelzés**: Cella szerkesztési módba váltása fókusszal
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-14] [Munkacsoport automatikus feltöltése]
- **Leírás**: Új munkacsoport létrehozásakor a rendszer automatikusan töltse be a valuták elnevezéseit és a hozzájuk tartozó elszámoló árfolyamokat a megfelelő oszlopokba.
- **Forrás**: Hibalista: „Ha új munkacsoportot hozok létre automatikusan tegye be az elszámoló árfolyamokat és a valuta elnevezéseket"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Új munkacsoport létrehozása parancs
- **Kimenet / Visszajelzés**: Új munkalap előre feltöltött valutasorokkal és elszámoló árakkal
- **Validációk és Kényszerek**: N/A

### ### [FR-HL-15] [HUF mező egész szám formátuma]
- **Leírás**: A Currency (pénznem) mező HUF (forint) értékeinek mindig egész számnak kell lenniük, tizedesjegyek nélkül.
- **Forrás**: Hibalista: „Currency mező HUF egész"
- **Prio**: Magas
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: HUF érték beírása vagy kalkulációja
- **Kimenet / Visszajelzés**: Egész számra kerekített forint érték
- **Validációk és Kényszerek**: HUF sorokban a tizedesjegyek megadása és kijelzése tiltott.

### ### [FR-HL-16] [B-csoport valuta sorrendje]
- **Leírás**: A B-csoportos árfolyamlap rácsában (`RateCreationPage.tsx`) a valutáknak szigorúan a Főlap (`MainRateSheetPage.tsx`) alapértelmezett sorrendjében kell megjelenniük: `EUR, USD, GBP, CHF, AUD, CAD, JPY, CZK, PLN, RON, RSD, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD`. (DKK, NOK, SEK, HRK, BGN, RCH inaktív devizák nem jelennek meg).
- **Forrás**: FK02-B audit 1.1 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Szerverről letöltött valuták listája
- **Kimenet / Visszajelzés**: Főlap sorrendjére rendezett rács

### ### [FR-HL-17] [10%-os Eltérés-vizsgálat megerősítő modallal]
- **Leírás**: Cellamódosításkor (pl. fókusz elhagyásakor/onBlur) a rendszernek ellenőriznie kell az eltérést az előző mentett értékhez képest. Ha a kétoldali eltérés eléri a 10%-ot (képlet: `|újÉrték - előzőMentettÉrték| / előzőMentettÉrték >= 0.10`), egy megkerülhetetlen modális ablak kéri a felhasználó jóváhagyását. "Igen" (Confirm) esetén az érték menthető, "Nem" (Cancel) esetén a cella visszaugrik a korábbi perzisztált értékére és a mentés megszakad. Jóváhagyott eltérés esetén az "Ellenőrzés" oszlopban az adott valuta piros hibajelzése nem jelenhet meg.
- **Forrás**: FK02-B audit 1.2 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Új beírt cellaérték és előzőleg elmentett érték
- **Kimenet / Visszajelzés**: Felugró megerősítő dialog vagy cella-visszaállítás

### ### [FR-HL-18] [Cella-kijelölés és lebegő toolbar]
- **Leírás**: A csoportos árfolyamlap táblázatában (`RateGrid.tsx`) a cellák kijelölésének támogatnia kell a tartomány alapú kijelölést egérrel történő vonszolással (drag) vagy Shift+kattintással. A kijelölt tartomány mellett egy kontextuális lebegő eszköztárnak kell megjelennie, amely az alábbi három funkciót kínálja:
  - "Lehúzás (üres)": a kijelölt cellák értékének vagy képletének törlése.
  - "Lehúzás (mind)": a kijelölt tartomány legelső sorának értékeit vagy képleteit másolja végig az oszlop többi kijelölt cellájába.
  - "Sávok törlése": csak a kijelölt sorok N-S (kedvezményes sáv) oszlopaiból törli a rátákat, a fő vételi/eladási oszlopokat (L-M) békén hagyja.
- **Forrás**: FK02-B audit 1.3 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cella egeres drag/Shift-kattintás koordináták
- **Kimenet / Visszajelzés**: Lebegő toolbar akciókkal a kijelölt rács mellett

### ### [FR-HL-19] [Helyi SQLite Perzisztencia onBlur]
- **Leírás**: Az `onBlur` cella-mentéseknek a helyi SQLite-ban lévő `group_rates` táblába kell írniuk a beírt rátákat (vételi/eladási). Az adatok betöltésekor a szerverről kapott rátákra azonnal rá kell tölteni (overlay) az SQLite-ból betöltött offline adatokat, így lapváltás, unmount vagy offline üzemmód esetén sem veszhetnek el a beírt ráták.
- **Forrás**: FK02-B audit 1.4 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cellakijelölés elhagyása (onBlur)
- **Kimenet / Visszajelzés**: SQLite mentés és visszatöltéskor felülírás (overlay)
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

A hibalista javításaihoz az alábbi adatmodell-módosítások szükségesek, figyelembe véve a legacy adatbázis táblákat:

### PostgreSQL
- **Currency (módosítás - DEVIZA)**:
  - `is_active` (boolean, default true) - A valuták inaktiválhatóságához (FR-HL-06).
- **CashierAuditLog (Audit napló - HRKNAPLO / ARFLOG)**:
  - `id` (serial, primary key)
  - `branch_id` (int) -- Fiókkód (`PENZTAR.KOD`)
  - `user_name` (varchar, a módosító neve, pl. 'Kovács János')
  - `action_details` (text, a módosított árfolyam-rekord részletei)
  - `created_at` (timestamp, default now())

### Kapcsolódó Legacy Táblák
- **BLOKKFEJ**: A bizonylatok fejadatai (pl. `BIZONYLATSZAM`, `TIPUS`, `DATUM`, `IDO`, `STORNO`). Az inaktív valuták korábbi tranzakcióinak lekérdezésekor ezt a táblát össze kell tudni kapcsolni a deviza törzzsel.
- **BLOKKTETEL**: A bizonylatok tételes sorai (pl. `BIZONYLATSZAM`, `DEVIZA`, `ARFOLYAM`, `ERTEK`).
- **ARFOLYAM**: Az árfolyamok napi történetét tároló legacy tábla.

### SQLite (Offline mirror a kliensen)
- A kliens oldali SQLite `Currency` táblájának is tartalmaznia kell az `is_active` oszlopot, hogy a pénztári programban (`penztar-client`) szűrni lehessen az inaktív valutákat (FR-HL-05) offline üzemmódban is.
</data_structure>

<integration_points>
## Integrációs Pontok
- **Pénztári kliens (penztar-client)**:
  - A szűrt valutalista átadása a pénztári tranzakciós modulnak az aktív/inaktív állapot szinkronizációjával (FR-HL-05). Az inaktív valuták eltűnnek a napi tranzakció-indítási listákból, de a korábbi bizonylatokban (`BLOKKFEJ` / `BLOKKTETEL`) megjeleníthetőek maradnak.
- **Elsődleges/Másodlagos FTP Szerver**:
  - Az ellenőrzés, mentés és szétküldés elkülönített gombokkal indul (FR-HL-10). A szétküldés a passzív bináris FTP kapcsolaton keresztül írja ki az `ARFDATA.DAT` fájlt a szerverre.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd el a követelménylistát és elemezd a meglévő táblázat-másoló motort az `arfolyam-keszito-client` csomagban.
- Készíts minimal reprodukciót a lapreferencia eltolódásról ($LapT01 -> $LapT3).

### Phase 2: Backend (Backend)
- Készítsd el a PostgreSQL migrációt az `is_active` mező hozzáadásához és az audit napló táblához.
- Implementáld a szerver oldali audit log rögzítő API-t.

### Phase 3: Frontend/Client (Frontend/Client)
- Javítsd ki a sor másolás/beillesztés parse logikáját a táblázatban, biztosítva, hogy a `$Lap...` kezdetű lapreferenciák abszolút hivatkozásként legyenek kezelve és ne változzanak a cél-sor indexének megfelelően.
- Implementáld a Ctrl+Z undo/redo history puffert a táblázat cellaváltozásaira.
- Építsd be a valuták aktív/inaktív szűrését a 0-ás és a csoport lapokra.
- Implementáld a billentyűzet-figyelőt a nyíl navigációhoz és az Enter-es gyors cella-aktiváláshoz.
- Formázd a HUF oszlopok/cellák bemeneteit egész számra.

### Phase 4: Verification (Verification)
- **Unit tesztek**: Írj tesztet a sor-másoló képlet-elemzőhöz. Ellenőrizd, hogy a `$LapT01!C9` a beillesztés után is `$LapT01!C9` marad.
- **Unit tesztek**: Teszteld a HUF értékek egész számra kerekítését különböző tizedes bemenetek esetén.
- **Integrációs tesztek**: Ellenőrizd, hogy a valuta inaktiválása után az eltűnik-e az árfolyamtáblázatból és a pénztári tranzakciós listából is.
- **UI tesztek**: Teszteld a billentyűzet navigációt (nyilak és enter szerkesztési fókusz).
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| TBD-1 | Melyik szerepkör (Főértéktáros, admin) végezheti az árfolyam-karbantartást és a valuta inaktiválást? | Jogosultsági kapuk beállítása | **LEZÁRVA**: A jogosultsági értékek: `ROLE_TREASURER` (Főértéktáros) és `ROLE_ADMIN` (Adminisztrátor). |
| TBD-2 | Mi a "Munkacsoport" pontos üzleti definíciója és az elszámoló árak forrása (FR-HL-14)? | Új munkalap generálás logika | **LEZÁRVA**: A 54 munkacsoport egyedi irodacsoportokat képvisel. Új csoport létrehozásakor a valutanemek és az elszámoló árfolyamok bázisa a 0-ás alaplapról (`A` oszlop) öröklődik. |
| TBD-3 | A pénztárankénti audit log pontos adattartalma és biztonsági követelményei | Adatmodell és compliance | **LEZÁRVA**: A kliens oldalon rögzített audit log (`CashierAuditLog` / legacy `HRKNAPLO` mintájára) rögzíti a fiókkódot, a felhasználó nevét, a módosítás tartalmát és az időbélyeget. A logok módosítása és törlése tiltott. |
| TBD-4 | A szétküldési (FR-HL-10) folyamat végpontjai és protokollja | Hálózati integráció | **LEZÁRVA**: Passzív FTP átvitel a `wininet.dll` API-n keresztül a békéscsabai fő szerverre és a pécsi fallback szerverre. |
| TBD-5 | Inaktív valuta kezelése korábbi tranzakcióknál (történeti adatok megjelenítése) | Adatintegritás és riportálás | **LEZÁRVA**: A tranzakció-történetben és bizonylat-lekérdezéseknél (`BLOKKFEJ`/`BLOKKTETEL` alapján) az inaktív valuták továbbra is megjelennek a történeti pontosság érdekében, de új tranzakció nem indítható velük. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden bejelentett hiba (FR-HL-01..FR-HL-15) javítási követelményként felvételre került a forrás alapján.
- [x] 0 hallucináció (csak a dokumentumban megfogalmazott hibajelenségek és igények szerepelnek).
- [x] Minden nyitott kérdés (TBD-1..TBD-5) pontosan dokumentált.
</verification_checklist>
