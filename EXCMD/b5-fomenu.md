# Modul: Régi Delphi valutaprogram — Főmenü struktúra

<system_context>
## Rendszerkontextus és Háttér
A régi (dekanySoft / Exclusive Best Change ZRT.) Delphi valutaváltó program 04.00 verziójú főmenüjének teljes menüstruktúrája, beleértve az összes menüpontot, a fejléceket, a bal oldali fej-panelt és az alsó (F1–F12 + Esc) funkcióbillentyűket.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | Bejelentkezett felhasználó (a fej-panelen "Bejelentkezett pénztáros: <WORKER_KOD>-<NEV>"). Alapfunkciók elérése, főmenü-navigáció. | TBD (Lásd: TBD-4) |
| Értéktáros / egyéb | TBD — a forrás csak a bejelentkezett pénztárost mutatja. | TBD (Lásd: TBD-4) |

### Hatókör (Scope)
#### IN
- A főmenü két képernyőképe (Főmenü.JPG az első menü-blokk; Főmenü 2.JPG a folytatás/második blokk).
- Bal oldali fej-panel (Verziószám, Munkanap dátuma, Pontos idő, telefon, bejelentkezett pénztáros, egység-azonosító).
- Központi menülista-elemek.
- Alsó funkcióbillentyű-sor (F1–F12, Esc).

#### OUT
- A menüpontok mögötti aldialógusok (ezek részleteit külön specifikációk tartalmazzák: pénztár-mozgások, listák, kezelés/címletezés/engedélyezés).
- Beállítás-képernyők, napzárás-checklist.

### Technológiai verem (Tech Stack)
- Pénztári kliensalkalmazás (`penztar-client` és `kozponti-client`)
- Helyi SQLite mirror a bejelentkezett állapot, az aktív pénztár és a munkanap adatainak lokális tárolásához (offline működés)
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-FM-01: Verziószám megjelenítése
- **Leírás**: A főmenü fejléce vagy fej-panelje megjeleníti az aktuális verziószámot ("Verziószám 04.00").
- **Forrás**: `Főmenü.JPG` (bal felül: "Verziószám 04.00")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rendszer-verzió konfigurációs változó.
- **Kimenet / Visszajelzés**: Verziószám címke a fej-panelen.
- **Validációk és Kényszerek**: Statikus kijelzés.

### FR-FM-02: Munkanap dátumának megjelenítése
- **Leírás**: A fej-panel megjeleníti az aktuális munkanap dátumát (pl. "2024 MÁRCIUS 12 KEDD").
- **Forrás**: `Főmenü.JPG` ("Munkanap dátuma")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rendszer munkanap dátuma az adatbázisból.
- **Kimenet / Visszajelzés**: Dátum szöveg.
- **Validációk és Kényszerek**: Formátum: YYYY HÓNAP DD NAPNÉV.

### FR-FM-03: Pontos idő kijelzése
- **Leírás**: A fej-panel valós időben megjeleníti a pontos időt (pl. "Pontos idő 11:51").
- **Forrás**: `Főmenü.JPG` ("Pontos idő 11:51")
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rendszeróra.
- **Kimenet / Visszajelzés**: Digitális óra kijelzés.
- **Validációk és Kényszerek**: Valós idejű frissülés perces pontossággal.

### FR-FM-04: Egység-azonosító és telefonszám megjelenítése
- **Leírás**: A fej-panel kiemelten (pl. piros színnel) megjeleníti a pénztár/egység azonosítóját (pl. "75") és a kapcsolódó telefonszámot ("Telefon: 06/XX-XXX-XXXX").
- **Forrás**: `Főmenü.JPG` (piros "75" + "Telefon")
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénztár egység konfiguráció.
- **Kimenet / Visszajelzés**: Egység ID és telefon kijelzése.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-05: Bejelentkezett pénztáros adatai
- **Leírás**: A fej-panel megjeleníti a bejelentkezett pénztáros kódját és nevét ("Bejelentkezett pénztáros: <WORKER_KOD>-<NEV>"), valamint a fiók címét ("<VAROS>", "<CIM>").
- **Forrás**: `Főmenü.JPG`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Bejelentkezett felhasználó session adatai, fiókcím adatok.
- **Kimenet / Visszajelzés**: Személyzeti és címadatok.
- **Validációk és Kényszerek**: Üres bejelentkezési adatokkal nem nyílhat meg a főmenü.

### FR-FM-06: Egység nevének megjelenítése a háttérben
- **Leírás**: A főmenü háttérképe felett kiemelten meg kell jeleníteni a fizikai egység nevét és típusát (pl. "BÉKÉSCSABA ÉRTÉKTÁR").
- **Forrás**: `Főmenü.JPG`, `Főmenü 2.JPG`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Egység neve.
- **Kimenet / Visszajelzés**: Vízjel-szerű vagy háttérben futó kiemelt felirat.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-07: Pénztárak közötti átadás-átvétel menüpont
- **Leírás**: Főmenüpont: "PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL". Aktiválásakor megnyitja a pénztárközi bizonylatoló felületet.
- **Forrás**: `Főmenü.JPG` (1. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`, `kozponti-client`
- **Bemenő adatok**: Felhasználói választás (kattintás / billentyű).
- **Kimenet / Visszajelzés**: Átadás-átvételi képernyő megnyitása.
- **Validációk és Kényszerek**: Jogosultság ellenőrzése.

### FR-FM-08: Mai bizonylat sztornója menüpont
- **Leírás**: Főmenüpont: "MAI BIZONYLAT SZTORNÓJA". Megnyitja a napi bizonylatok kereső- és sztornó felületét.
- **Forrás**: `Főmenü.JPG` (2. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Sztornó képernyő.
- **Validációk és Kényszerek**: Csak mai dátumú bizonylatok listázása.

### FR-FM-09: Pillanatnyi pénztár állása menüpont
- **Leírás**: Főmenüpont: "A PILLANATNYI PÉNZTÁR ÁLLÁSA", amely mellett lapozó nyilakkal ( "<<<" / ">>>" ) lehet váltani a nézetek között.
- **Forrás**: `Főmenü.JPG` (3. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás vagy nyíl-billentyű.
- **Kimenet / Visszajelzés**: Pénztár állás részletes panel.
- **Validációk és Kényszerek**: Real-time készlet adatok.

### FR-FM-10: Napi- és havizárás, címletezés menüpont
- **Leírás**: Főmenüpont: "A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS". Megnyitja a zárási workflow-t.
- **Forrás**: `Főmenü.JPG` (4. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Címletező és záró dialógus.
- **Validációk és Kényszerek**: Nyitott tranzakciók megléte esetén figyelmeztetés.

### FR-FM-11: Bizonylatok megtekintése menüpont
- **Leírás**: Főmenüpont: "BIZONYLATOK MEGTEKINTÉSE". Biztosítja a korábbi napok bizonylatainak keresését és megtekintését.
- **Forrás**: `Főmenü.JPG` (5. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Bizonylattár/Kereső felület.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-12: Kilépés a főmenüből menüpont
- **Leírás**: Menüpont vagy gomb: "KILÉPÉS A FŐMENÜBŐL". Bezárja a főmenüt és kijelentkezteti a pénztárost.
- **Forrás**: `Főmenü.JPG`, `Főmenü 2.JPG`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás (kattintás / Esc gomb).
- **Kimenet / Visszajelzés**: Kijelentkezés, alkalmazás bezárása / bejelentkező ablak.
- **Validációk és Kényszerek**: Megerősítő kérdés.

### FR-FM-13: Menü-blokkok közötti lapozás
- **Leírás**: A főmenü lapozható (navigációs nyilakkal: "<<<" / ">>>") a menü-blokkok (1. és 2. oldal) között.
- **Forrás**: `Főmenü.JPG` és `Főmenü 2.JPG` (a két különböző menükészlet jelzi a lapozhatóságot)
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Lapozó gombok vagy bal/jobb nyilak.
- **Kimenet / Visszajelzés**: Menüpontok cseréje a képernyőn.
- **Validációk és Kényszerek**: Csak 2 oldal van.

### FR-FM-14: Társpénztárak karbantartása menüpont (2. oldal)
- **Leírás**: Főmenüpont a második oldalon: "TÁRSPÉNZTÁRAK KARBANTARTÁSA". Megnyitja a társpénztárak (fiókon belüli kasszák) listáját és beállításait.
- **Forrás**: `Főmenü 2.JPG` (1. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Társpénztárak képernyő.
- **Validációk és Kényszerek**: Jogosultságfüggő (TBD-4).

### FR-FM-15: Különféle listák nyomtatása menüpont (2. oldal)
- **Leírás**: Főmenüpont a második oldalon: "KÜLÖNFÉLE LISTÁK NYOMTATÁSA". Megnyitja a riportok és listák nyomtatási menüjét.
- **Forrás**: `Főmenü 2.JPG` (2. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Nyomtatási listák választója.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-16: Pénztárosok, jelszavak karbantartása menüpont (2. oldal)
- **Leírás**: Főmenüpont a második oldalon: "PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA".
- **Forrás**: `Főmenü 2.JPG` (3. sor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Felhasználókezelő felület.
- **Validációk és Kényszerek**: Csak Supervisor jogosultsággal érhető el (Lásd: TBD-4).

### FR-FM-17: Régebbi nap zárásának újranyomtatása menüpont (2. oldal)
- **Leírás**: Főmenüpont a második oldalon: "RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA". Archív zárási bizonylatok újranyomtatása.
- **Forrás**: `Főmenü 2.JPG` (4. sor)
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Zárási dátum kiválasztása.
- **Kimenet / Visszajelzés**: Nyomtatás elindítása.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-18: Western Union és áfa tranzakciók menüpont (2. oldal)
- **Leírás**: Főmenüpont a második oldalon: "WESTERN UNION ÉS ÁFA TRANZAKCIÓK". Megnyitja a Western Union felületet és az ÁFA-visszaigénylések kezelését.
- **Forrás**: `Főmenü 2.JPG` (5. sor)
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói választás.
- **Kimenet / Visszajelzés**: Western Union / Áfa-ügyintézés képernyő.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-19: Alsó funkcióbillentyű sor (F1-F12 + Esc)
- **Leírás**: A képernyő legalsó sorában folyamatosan elérhető billentyűparancsok:
  - F1: ÁRFOLYAM
  - F2: FOGLALÓ
  - F3: TERMINÁL
  - F4: ÁFA TÁBLA
  - F5: MAI FORG.
  - F6: (TESCO ÁFA — szürkített/inaktív)
  - F7: SUPERVISOR
  - F8: (Üres)
  - F9: KÉSZLET
  - F10: ÁTADÓLAP
  - F11: (METRO ÁFA / W.UNION — szürkített/inaktív)
  - F12: W.UNION
  - Esc: KILÉPÉS
- **Forrás**: `Főmenü 2.JPG` (alsó gombsor)
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Billentyűleütés (F1–F12, Esc).
- **Kimenet / Visszajelzés**: A megfelelő modul vagy felület megnyitása.
- **Validációk és Kényszerek**: A szürkített gomboknak leütésre nem szabad reagálniuk (Lásd: TBD-1).

### FR-FM-20: Alsó középső funkciópanelek
- **Leírás**: A háttérkép felett elhelyezkedő gyorsgombok: "NAPI JELENTÉS", "ÁTADÓLAP", "KÖRLEVELEK", "HAVI TABLÓK", "KÉSZLETEK", "ENGEDMÉNYEK", "PÉNZTÁRAK", "KILÉPÉS", "ZÁRÁS BEKÉSZÍTÉSE", "SUPERVISOR".
- **Forrás**: `Főmenü.JPG` (alsó gombsor)
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Egérkattintás a gombokon.
- **Kimenet / Visszajelzés**: Modul megnyitása.
- **Validációk és Kényszerek**: Nincs.

### FR-FM-21: Kiegészítő információs panelek és számlálók
- **Leírás**: Meg kell jeleníteni az alábbi jelzőpaneleket és értékeket a főmenüben: "NÉVTELEN BEJELENTÉS", "FUTÓFÉNY", "PÉNZTÁR SZÜNET", "KÖRLEVELEK" jelzés, valamint a "Napi stornózott bizonylat darab" aktuális számlálója (pl. értéke: 6).
- **Forrás**: `Főmenü.JPG`, `Pénztárak karbantartása` képek alsó sávja
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Aktuális napi stornózott bizonylatok száma az adatbázisból.
- **Kimenet / Visszajelzés**: Számlálók és állapotjelzők.
- **Validációk és Kényszerek**: Real-time szinkronizált számláló.
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

A főmenü megjelenítéséhez szükséges lokális session és számláló állapotok SQLite mirror-ban tárolandók az offline működéshez.

### Javasolt tábla:

#### 1. `fomenu_allapot_snapshot`
- `id` (INTEGER PRIMARY KEY)
- `alkalmazott_kod` (VARCHAR(50))
- `alkalmazott_nev` (VARCHAR(100))
- `fiok_kod` (VARCHAR(10))
- `fiok_nev` (VARCHAR(100))
- `fiok_cim` (VARCHAR(200))
- `telefon` (VARCHAR(50))
- `munkanap_datuma` (DATE)
- `napi_storno_darab` (INTEGER DEFAULT 0)
- `utolso_frissites` (TIMESTAMP)
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Pénztár és Készletkezelés**: Pillanatnyi készletinfók lekérdezése (F9 Készlet, FR-FM-09).
- **Tranzakciós és Sztornó modulok**: Napi stornó darabszám számlálása, sztornó képernyő (FR-FM-08, FR-FM-21).
- **Supervisor és Jogosultságkezelés**: F7 Supervisor mód és a pénztáros jelszó karbantartás (FR-FM-16, FR-FM-19).
- **Western Union és ÁFA modul**: Kapcsolat az integrált Western Union klienssel (F12, FR-FM-18, FR-FM-19) és a külső POS terminálokkal (F3).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- A `Főmenü.JPG` és `Főmenü 2.JPG` képek alapján a dizájn elemek és elrendezés (fej-panel, központi gombok, alsó funkciógombok) drótvázának elkészítése.

### Fázis 2: Backend megvalósítás
- Olyan API végpontok kialakítása, amelyek visszaadják a bejelentkezett session adatait és a napi stornózott bizonylatok számát (`napi_storno_darab`).

### Fázis 3: Frontend / Kliens megvalósítás
- A kétoldalas menü lapozási logikájának lekódolása a `penztar-client`-ben.
- A gyorsbillentyű-események (F1–F12, Esc) lehallgatása (key listener) és a megfelelő dialógusok/útvonalak meghívása.
- Valós idejű óra és stornó-számláló frissítési ciklus beprogramozása.

### Fázis 4: Verifikáció és Tesztelés
- Tesztelni, hogy a funkcióbillentyűk (F1, F2 stb.) lenyomására a megfelelő felületek nyílnak-e meg.
- Validálni, hogy a szürkített billentyűkre (F6, F11) nem történik művelet végrehajtás.
- Ellenőrizni, hogy offline módban (SQLite-ból olvvasva) is pontosan töltődnek-e be a fej-panel fiók- és pénztáros adatai.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| ID | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-1 | Szürkített funkcióbillentyűk (F6, F11) viselkedése | Felhasználói felület | A képeken a TESCO ÁFA és METRO ÁFA/W.UNION gombok szürkítettek. Ezek állandóan inaktívak, vagy bizonyos jogosultság/fióktípus esetén aktívvá válnak? |
| TBD-2 | "NÉVTELEN BEJELENTÉS" és "FUTÓFÉNY" gombok | Funkcionális lefedettség | A gombok funkciója a képek alapján nem azonosítható. Mit kell tenniük (pl. névtelen visszaélés-bejelentő form küldése, árfolyam futószalag ki/bekapcsolás)? |
| TBD-3 | Verziószám különbségek | Kliens verziókövetés | A főmenü képen a verziószám 04.00, míg a Társpénztárak karbantartása képen a fejlécben 35.25 szerepel. Mi ennek az eltérésnek a pontos oka? |
| TBD-4 | Menüpontok RBAC jogosultságai | Biztonság, Jogosultságok | Mely menüpontok érhetőek el normál Pénztáros és melyek csak Supervisor szerepkörrel (pl. Pénztárosok karbantartása)? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden főmenüponthoz (FR-FM-07-től FR-FM-21-ig) hozzá van rendelve a képi forrás-dokumentum hivatkozása.
- [ ] Az alsó billentyűzet-parancsok (F1-F12, Esc) pontos listája megőrzésre került.
- [ ] A 4 darab TBD kérdés pontosan dokumentálva van a kockázati naplóban.
- [ ] Nincsenek önkényesen kitalált új menüpontok vagy funkciók.
- [ ] A bejelentkezett session és a napi stornózott számláló adatszerkezete rögzítésre került.
</verification_checklist>
