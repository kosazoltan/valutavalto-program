---
title: "Beállítások (jelszóval védett konfigurációs képernyők)"
modul: b6-beallitasok
kategoria: beallitasok
alkalmazas: penztar-client
szerepokor:
  - ROLE_ADMIN
  - ROLE_TREASURER
forrasok:
  - "Felmérés/.../Képernyőképek/Beállítások csak jelszóval_ alapfunkció.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ Alapfunkciók.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ Alkalmazások .jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ IP cím beállítás.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ Jelszó beállítások napi jelentéshez.jpg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ nyomtató beállítás.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ szkenner beállítás.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ Árfolyam kijelző beállításai.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások külön jelszóval_ adatok beküldése a szerverre.jpeg"
  - "Felmérés/.../Képernyőképek/Beállítások menü külön jelszóval.jpeg"
prio: Közepes
utolso_frissites: "2026-06-02"
media_eredetu: true
---

# Modul: Beallitasok (jelszoval vedett konfiguracios kepernyok)

<system_context>
## Rendszerkontextus és Háttér
Ez a specifikáció a régi pénztáros program jelszóval védett "Beállítások" konfigurációs képernyőit írja le. A felület bal oldali "Témák" füllistából (12 fül), jobb oldali beállítás-panelből, és az alul elhelyezkedő mentési/kilépési akciógombokból áll.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | A beállítások menü elérése jelszóhoz kötött. A Pénztáros szerep hozzáférhetősége korlátozott lehet (lásd TBD-2). | TBD |
| Értéktáros / Főértéktáros / Admin | Konfigurációs hozzáférés a globális vagy gép-szintű paraméterek beállításához. | TBD |

### Hatókör (Scope)
#### IN
- Beállítás-menü kerete: bal oldali "TEMAK" füllista (12 fül), jobb "BEALLITASOK" tartalom-panel, alsó gombsor (3 gomb).
- A 12 konfigurációs fül részletei: Alapfunkció, Alkalmazások, IP-cím beállítása, Jelszó beállítás (napi jelentés), Kijelzés színe, Futófény, Készletek beküldése, Kezelési költség számítása, Bankkártya fizetés, Nyomtató, Reklám a kijelzőn, Scanner beállítása.
- "Külön jelszóval" és "csak jelszóval" védett képernyőváltozatok.

#### OUT
- A jelszóbekérő dialógusablak konkrét fizikai kinézete (TBD-2).
- A "Reklám a kijelzőn" fül részletes mezőinek felépítése (csak a rádiógombok ismertek).
- A futófény egyedi szövegének szerkesztőfelülete (szövegszerkesztő képernyő).

### Technológiai verem (Tech Stack)
- Pénztári kliens (`penztar-client`)
- Helyi SQLite mirror az offline működéshez és a helyi gép konfigurációs paramétereinek tárolásához
- Központi Postgres konfigurációs táblák (szinkronizálva a klienssel)
- Hardveres integrációk: ESC/POS nyomtató (LPT1/USB), WIA/TWAIN alapú okmányszkenner, COM-portos LED futófény kijelző
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-01: Beállítások keret és alapnavigáció
- **Leírás**: Biztosítani kell a beállítások keretablakot: bal oldalon a 12 fülből álló "TEMAK" listát, jobb oldalon a kiválasztott fülhöz tartozó beállítási panelt. Alsó funkciógombok: "ROGZITES ES KILEPES", "KILEPES MODOSITAS NELKUL", "VISSZA A MENURE".
- **Forrás**: `Beállítások menü külön jelszóval.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Felhasználói fül-kiválasztás, akciógombok kattintása.
- **Kimenet / Visszajelzés**: Panel frissülése vagy ablak bezárása.
- **Validációk és Kényszerek**: A "KILEPES MODOSITAS NELKUL" gombnak az összes el nem mentett változtatást el kell dobnia (FR-14).

### FR-02: ALAPFUNKCIO fül beállításai
- **Leírás**: Az "Alapfunkció" fülön meg kell jeleníteni 3 egymást kizáró rádiógombot a gép fizikai/logikai szerepének beállításához: "PENZTARI GEP" (alapértelmezett), "ERTEKTARI GEP", "AFAS GEP".
- **Forrás**: `Alapfunkciók.jpeg`, `Beállítások csak jelszóval_ alapfunkció.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rádiógomb választás.
- **Kimenet / Visszajelzés**: Kiválasztott üzemmód.
- **Validációk és Kényszerek**: Egyszerre csak egy üzemmód lehet kiválasztva.

### FR-03: ALKALMAZASOK fül beállításai
- **Leírás**: Az "Alkalmazások" fülön egy többszörös választású (checkbox) listát kell biztosítani a gépen futó kiegészítő modulok aktiválásához: "VALUTAVALTAS", "WESTERN UNION", "TESCO AFA", "METRO AFA", "E-KERESKEDELEM".
- **Forrás**: `Beállítások külön jelszóval_ Alkalmazások .jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Jelölőnégyzetek állapota.
- **Kimenet / Visszajelzés**: Aktivált modulok listája.
- **Validációk és Kényszerek**: Nincs.

### FR-04: KIJELZES SZINE fül beállításai
- **Leírás**: Az "AZ ARFOLYAM KIJELZO SZINE" fülön 3 rádiógombot kell elhelyezni: "ZOLD", "SARGA", "PIROS" (alapértelmezett). A panelen meg kell jeleníteni egy élő előnézeti táblázatot (VETEL és ELADAS oszlopok a kiválasztott színű szövegformázással).
- **Forrás**: `Beállítások külön jelszóval_ Árfolyam kijelző beállításai.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Szín kiválasztása.
- **Kimenet / Visszajelzés**: Az előnézeti kép és a fizikai kijelző színének frissülése.
- **Validációk és Kényszerek**: Nincs.

### FR-05: IP-CIM BEALLITASA fül beállításai
- **Leírás**: A szerver elérési IP-címének megadásához 4 különálló numerikus oktett-beviteli mezőt kell biztosítani, valamint az "IP-CIM RENDBEN" és "MEGSEM" gombokat.
- **Forrás**: `Beállítások külön jelszóval_ IP cím beállítás.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: 4 darab IP oktett.
- **Kimenet / Visszajelzés**: Elmentett szerver IP cím (Lásd: TBD-7).
- **Validációk és Kényszerek**: Minden mezőnek 0 és 255 közötti egész számnak kell lennie.

### FR-06: JELSZO BEALLITAS fül beállításai
- **Leírás**: A "NAPI JELENTES JELSZAVA" fülön meg kell jeleníteni az aktuális jelszó értékét ("<JELSZO>"), és biztosítani kell egy "JELSZO MODOSITAS" gombot. Ezen felül itt kell elhelyezni "AZ ERTEKTAR E-MAIL CIME" szöveges mezőt és a "SZOMBATI NYITVATARTAS" rádiógombokat ("SZOMBATON NYITVA", "SZOMBATON ZARVA").
- **Forrás**: `Beállítások külön jelszóval_ Jelszó beállítások napi jelentéshez.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Új jelszó, e-mail cím, nyitvatartási állapot.
- **Kimenet / Visszajelzés**: Mentett biztonsági és e-mail beállítások.
- **Validációk és Kényszerek**: Az e-mail címnek meg kell felelnie a standard e-mail formátumnak.

### FR-07: KESZLETEK BEKULDESE fül beállításai
- **Leírás**: Az adatok szerverre küldésének beállítására egy "Adatok bekuldesenek gyakorisaga: N percenkent" feliratot és egy 0-tól 25 percig skálázott csúszkát kell biztosítani.
- **Forrás**: `Beállítások külön jelszóval_ adatok beküldése a szerverre.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Csúszka értéke (pl. 2 perc).
- **Kimenet / Visszajelzés**: Szinkronizációs gyakoriság beállítása.
- **Validációk és Kényszerek**: A csúszka értéktartománya szigorúan 0 és 25 közötti egész szám lehet.

### FR-08: NYOMTATO fül beállításai
- **Leírás**: A "NYOMTATO TIPUSA" beállítására 2 rádiógombot kell biztosítani: "LPT1 PORTRA CSATLAKOZTATVA" és "USB PORTRA CSATLAKOZTATVA".
- **Forrás**: `Beállítások külön jelszóval_ nyomtató beállítás.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Port-típus kiválasztása.
- **Kimenet / Visszajelzés**: Nyomtatási kimeneti csatorna beállítása.
- **Validációk és Kényszerek**: Nincs.

### FR-09: SCANNER BEALLITASA fül beállításai
- **Leírás**: A "A SCANNER BEALLITASA" fülön meg kell jeleníteni a kliensgépen elérhető szkenner-driverek rádiógombos listáját (pl. "CanoScan Lide 120", "WIA-CanoScan Lide 120").
- **Forrás**: `Beállítások külön jelszóval_ szkenner beállítás.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Driver kiválasztása a listából.
- **Kimenet / Visszajelzés**: Mentett szkenner driver profil.
- **Validációk és Kényszerek**: Ha nincs csatlakoztatott szkenner, jelezni kell.

### FR-10: KEZELESI KOLTSEG fül beállításai
- **Leírás**: A "KEZELESI KOLTSEG SZAMITASA" fülön 3 rádiógombot kell biztosítani: "NINCS KEZELESI KOLTSEG", "EZRELEKES KEZELESI KOLTSEG", "SAVOS KEZELESI KOLTSEG". A kijelölt mód alatt meg kell jeleníteni a hozzá tartozó paraméter-panelt (pl. "EZRELEKES KEZELESI KOLTSEG: 3 ezrelek Max: 9990 Ft") és egy "MODOSITAS" gombot (Lásd: TBD-5).
- **Forrás**: `Beállítások csak jelszóval_ Kezelési költség számítások.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Költségszámítási típus, ezrelék érték, maximum Forint érték.
- **Kimenet / Visszajelzés**: Tranzakciós kezelési díj kalkulációs paraméterek frissítése.
- **Validációk és Kényszerek**: Az ezrelék és a maximum értéknek pozitív számnak kell lennie.

### FR-11: FUTOFENY fül beállításai
- **Leírás**: A "FUTOFENY BEALLITASA" panelen a következő beviteli mezőket kell biztosítani:
  - "Hany futofenytabla van: N" (egész szám)
  - "Elso futofenytabla comportja: N"
  - "Masodik futofenytabla comportja: N"
  - Megjelenítési mód választó (rádiógombok): "CSAK ARFOLYAMKIJELZES", "CSAK SZOVEG KIJELZESE" (a "Szoveg szerkesztese" gombbal, Lásd: TBD-4), "VALTAKOZO KIJELZES (Nappal szoveg/Ejjel arfolyam)"
  - "FUTOFENY KIKAPCSOLASA" akciógomb
  - "Futofeny sebessege" csúszka LASSU és GYORS értékek között.
- **Forrás**: `Beállítások csak jelszóval_ futófény beállítások.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Táblaszám, COM-portok, módok, sebesség érték.
- **Kimenet / Visszajelzés**: Futófény soros kommunikációs paramétereinek frissítése.
- **Validációk és Kényszerek**: A COM portoknak egyedi számoknak kell lenniük.

### FR-12: BANKKARTYA FIZETES fül beállításai
- **Leírás**: A "FIZETES BANKKARTYAVAL" fülön 2 rádiógombot kell elhelyezni: "NINCS ENGEDELYEZVE", "ENGEDELYEZVE", valamint egy "ADATOK RENDBEN" jóváhagyó gombot (Lásd: TBD-6).
- **Forrás**: `Beállítások külön jelszóval_ Bankkártyás fizetések.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rádiógomb választása.
- **Kimenet / Visszajelzés**: Bankkártyás fizetés funkció feloldása vagy zárolása a tranzakciós képernyőkön.
- **Validációk és Kényszerek**: Nincs.

### FR-13: REKLAM A KIJELZON fül beállításai
- **Leírás**: Biztosítani kell a "REKLAMOK A KIJELZON" beállítást "NINCS REKLAM A KIJELZON" és "VAN REKLAM A KIJELZON" rádiógombokkal (Lásd: TBD-3).
- **Forrás**: `Beállítások menü külön jelszóval.jpeg` (csak a füllistában látható)
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rádiógomb választás.
- **Kimenet / Visszajelzés**: Másodkijelzőn futó reklámok engedélyezése.
- **Validációk és Kényszerek**: Nincs.

### FR-14: Keret alsó akciógombjainak működése
- **Leírás**: Minden fül megnyitása esetén az alsó gombsornak azonosan kell viselkednie:
  - "ROGZITES ES KILEPES": Minden megváltoztatott paramétert elment a lokális SQLite-ba és a Postgres adatbázisba, majd bezárja a konfigurációs ablakot.
  - "KILEPES MODOSITAS NELKUL": Elveti az összes módosítást a konfiguráció mentése nélkül, és bezárja az ablakot.
  - "VISSZA A MENURE": Mentés nélkül bezárja a beállításokat, visszatér a főmenübe.
- **Forrás**: Minden beállítási képernyőkép alsó sávja.
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Gomb leütések vagy kattintások.
- **Kimenet / Visszajelzés**: Mentés és/vagy navigáció a főmenübe.
- **Validációk és Kényszerek**: - "ROGZITES ES KILEPES" előtt le kell futtatni az összes fülön lévő adatvalidációt (IP formátum, COM portok száma stb.).

### FR-15: Kezelési költség konfiguráció jogosultságai
- **Leírás**: A kezelési költség konfigurációját (`FR-10` és `HandlingFeeConfigPage`) a backend oldalon a `MANAGER` és `ADMIN` szerepkörökön túl a `FOERTEKTAR` (Főértéktáros) és `UGYVEZETO` (Ügyvezető) szerepköröknek is engedélyezni kell. A kasszás szerepkör számára a beállítások letiltottak.
- **Forrás**: 2026-06-02 tranzakciós audit 5. pont
- **Prio**: Magas (P1)
- **Csomag/Komponens**: backend / frontend-react
- **Bemenő adatok**: Felhasználói szerepkör
- **Kimenet / Visszajelzés**: API hozzáférés engedélyezése vagy 403-as hiba
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

### Postgres és SQLite táblák:

#### 1. `gep_konfiguracio`
A helyi gép konfigurációs paramétereinek tárolása.
- `id` (INTEGER PRIMARY KEY)
- `gep_szerep` (VARCHAR(20) NOT NULL DEFAULT 'PENZTAR') -- PENZTAR, ERTEKTAR, AFA
- `valutavaltas_aktiv` (BOOLEAN DEFAULT TRUE)
- `western_union_aktiv` (BOOLEAN DEFAULT FALSE)
- `tesco_afa_aktiv` (BOOLEAN DEFAULT FALSE)
- `metro_afa_aktiv` (BOOLEAN DEFAULT FALSE)
- `ekereskedelem_aktiv` (BOOLEAN DEFAULT FALSE)
- `kijelzo_szin` (VARCHAR(10) DEFAULT 'PIROS') -- ZOLD, SARGA, PIROS
- `szerver_ip_cim` (VARCHAR(15) DEFAULT '127.0.0.1')
- `napi_jelentes_jelszo` (VARCHAR(100)) -- Hashelt jelszó
- `ertektar_email` (VARCHAR(100))
- `szombati_nyitvatartas` (BOOLEAN DEFAULT FALSE)
- `szinkronizacio_gyakorisag_perc` (INTEGER DEFAULT 2)
- `nyomtato_port` (VARCHAR(10) DEFAULT 'LPT1') -- LPT1, USB
- `scanner_driver` (VARCHAR(100))
- `kezelesi_koltseg_tipus` (VARCHAR(20) DEFAULT 'EZRELEKES') -- NINCS, EZRELEKES, SAVOS
- `kezelesi_koltseg_ezrelek` (INTEGER DEFAULT 3)
- `kezelesi_koltseg_max_huf` (NUMERIC(15, 2) DEFAULT 9990.0)
- `futofeny_darab` (INTEGER DEFAULT 0)
- `futofeny_com1` (INTEGER)
- `futofeny_com2` (INTEGER)
- `futofeny_megjelenites_mod` (VARCHAR(20) DEFAULT 'ARFOLYAM') -- ARFOLYAM, SZOVEG, VALTAKOZO
- `futofeny_sebesseg` (INTEGER DEFAULT 5) -- 1-10 közötti skála
- `bankkartya_fizetes_aktiv` (BOOLEAN DEFAULT FALSE)
- `reklam_kijelzon_aktiv` (BOOLEAN DEFAULT FALSE)
- `utolso_modositas` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Hardveres periféria API-k**: Soros port vezérlő (COM) a futófény és a kijelző színeinek átadásához (FR-04, FR-11). Windows WIA/TWAIN interfész a szkenner driverek lekérdezéséhez (FR-09).
- **Tranzakciós modul és Zárás**: A kezelési költség számítási paraméterei (ezrelék, max limit) közvetlenül befolyásolják a váltások kalkulációját (FR-10). A napi zárási jelszó a zárási workflow indítását védi (FR-06).
- **Hálózati réteg**: A megadott IP-cím határozza meg, hogy a kliens melyik központi Postgres szerver felé továbbítja a tranzakciókat és készlet adatokat (FR-05, FR-07).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Elkészíteni az SQLite/Postgres migrációs szkriptet a `gep_konfiguracio` táblához alapértelmezett seed értékekkel.
- Összegyűjteni a teszteléshez használható virtuális COM port és nyomtató port eszközöket.

### Fázis 2: Backend megvalósítás
- Megvalósítani a konfigurációs mentési és betöltési API végpontokat a validációkkal együtt.
- Elkészíteni a jelszó-hashelő funkciót a napi jelentések védelméhez.

### Fázis 3: Frontend megvalósítás
- Lefejleszteni a 12 füles oldalsávos struktúrát a `penztar-client` alkalmazásban.
- Megírni az IP cím beviteli mező (4 oktett) beviteli maszkját és validációját.
- Lekódolni a futófény sebesség-csúszkáját és a gyakoriság-csúszkáját.
- Implementálni a színválasztó előnézeti rácsát az árfolyam-kijelzőnek.

### Fázis 4: Verifikáció és Tesztelés
- Unit tesztekkel verifikálni, hogy a mentett értékek (pl. a csúszkák vagy rádiógombok állapotai) megegyeznek-e a visszatöltöttekkel.
- Tesztelni, hogy a "KILEPES MODOSITAS NELKUL" megnyomására a konfiguráció valóban változatlan marad-e.
- IP cím oktett formátum ellenőrzése és jelszó módosítás helyességének tesztelése.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-1 | A "külön jelszóval" és "csak jelszóval" közötti eltérés | Felhasználói hozzáférés | Mi a pontos funkcionális különbség a két konfigurációs belépési mód között (pl. eltérő mezők szerkeszthetősége)? |
| TBD-2 | Beállítások belépő jelszava | Biztonság | Milyen alapértelmezett jelszó védi a beállítások menüt? Honnan származik az ellenőrzés logikája? |
| TBD-3 | "Reklám a kijelzőn" fül további paraméterei | Teljes körű konfiguráció | Milyen beállítások jelennek meg még a reklám fülön, ha a "VAN REKLÁM A KIJELZŐN" opciót választja a felhasználó? (Nincs képünk róla). |
| TBD-4 | "Szöveg szerkesztese" futófény felület | Funkcionális lefedettség | Hogyan néz ki a futófényre kiírandó egyedi szövegek szerkesztő felülete, és milyen korlátai vannak (pl. maximális karakterszám)? |
| TBD-5 | "Sávos kezelési költség" beállításai | Pénzügyi modul | **RESOLVED**: A sávos kezelési költség paramétereit (ezrelékes sávok, maximum összegek, sávhatárok) a `handling_fee_bracket` táblában kell tárolni és a backend oldali calculator konfigurációja szerint kell érvényesíteni. |
| TBD-6 | Bankkártyás fizetések paraméterei | POS integráció | Ha a bankkártyás fizetés "ENGEDÉLYEZVE" van, milyen terminál-konfigurációs mezők (pl. terminál ID, IP port) jelennek meg a felületen? |
| TBD-7 | Szerver elérés portja és protokollja | Hálózati szinkron | Az IP cím mellett megadható-e egyedi hálózati port is, vagy a rendszer rögzített standard portot használ a szerverkapcsolathoz? |
| TBD-8 | Lokális vs. központi konfiguráció | Adatmodell | A beállítások kizárólag a kliens gépen (SQLite) tárolódnak, vagy szinkronizálásra kerülnek a központi adatbázissal (Postgres) is a gép azonosítója alapján? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelmény (FR-01-től FR-14-ig) tartalmazza a megfelelő képi forrás-hivatkozást.
- [ ] A 12 darab fül struktúrája és azok beállítási opciói pontosan megőrzésre kerültek.
- [ ] A 8 darab nyitott kérdés rögzítve lett a TBD kockázati naplóban.
- [ ] Nem lettek új üzleti vagy konfigurációs szabályok kitalálva (csak a képeken látható beállítások).
- [ ] Az IP beviteli mezők száma és a csúszkák percmértékei pontosak (FR-05, FR-07).
</verification_checklist>
