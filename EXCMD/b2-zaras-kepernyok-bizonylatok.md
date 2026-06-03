---
title: "Zárás-képernyők és zárási bizonylatok (napi/dekád/havi/értéktári + címletezés)"
modul: b2-zaras-kepernyok-bizonylatok
kategoria: zaras
alkalmazas: penztar-client
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
  - ROLE_SUPERVISOR
  - ROLE_AUDITOR
forrasok:
  - "Felmérés/.../Bizonylatok/Napi zárás.jpg"
  - "Felmérés/.../Bizonylatok/2024. március. 1. havi dekádzárás.jpeg"
  - "Felmérés/.../Bizonylatok/Zárás-Értéktár.jpeg"
  - "Felmérés/.../Képernyőképek/Dekédzárás.jpeg"
  - "Felmérés/.../Képernyőképek/Értéktári zárás előtti check list.JPG"
  - "Felmérés/.../Képernyőképek/Értéktári zárást ellenőrző személy adatai.JPG"
prio: Magas
utolso_frissites: "2026-06-02"
media_eredetu: true
---

<system_context>
# Modul: Zárás-képernyők és zárási bizonylatok (napi/dekád/havi/értéktári + címletezés)

## Kontextus
A valutaváltó program napi, dekád, havi és értéktári zárásaihoz kapcsolódó képernyők, címletezési funkciók, ellenőrző checklistek és a kinyomtatandó bizonylatok struktúrájának leírása. A specifikáció az alábbi forrásképek alapján készült:
- **Bizonylatok**: `Napi zárás.jpg`, `Havi zárás.jpg`, `Havi zárás 2_.jpg`, `Zárás-Értéktár.jpeg`, `2024. március. 1. havi dekádzárás.jpeg`
- **Képernyőképek**: `Dekédzárás.jpeg`, `Címletezés -Zárások menü.jpeg`, `Címletezés - Zárások napi pénztárzárás.jpeg`, `Címletezés Zárások - Cimletezés.JPG`, `Címletezés nyomtatása.jpeg`, `Napi összefoglaló (X).jpeg`, `Értéktári zárás előtti check list.JPG`, `Értéktári zárást ellenőrző személy adatai.JPG`

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`penztar-client`)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Pénztáros** (RBAC: `ROLE_CASHIER`): Napi/dekád/havi pénztárzárás, címletezés, napi összefoglaló (X) lekérése, záró-bizonylatok nyomtatása.
- **Értéktáros** (RBAC: `ROLE_TREASURER`): Értéktári zárás-előtti checklist kitöltése, értéktári zárás végrehajtása.
- **Zárást ellenőrző személy** (RBAC: `ROLE_SUPERVISOR` vagy `ROLE_AUDITOR`): Név + beosztás megadása, a zárószalag ellenőrzése és aláírása.

## Hatókör (Scope)
- **IN**:
  - Címletezés–Zárások menü gombjai: "Különféle címletezések", "Címletek kinyomtatása", "A mai napi zárás végrehajtása", "A havi zárás végrehajtása", "Mégsem".
  - "Címletezés" almenü: Esti zárás, Kezelési díj, Western Union, ÁFA pénztár, Elektromos kereskedés címletezése; "Vissza" / "Kilépés".
  - "Címletek kinyomtatása" párbeszédablak checkboxokkal (Valutaváltás, Kezelési díj aktív; Western Union, ÁFA, Foglalók, Elektromos kereskedés, AXA inaktív).
  - Napi pénztárzárás címletezés-eltérés figyelmeztetés ("A NAV-OS FORINT FIÓKÉRTÉKE ELTÉR A CÍMLETEZÉSTŐL" + kötelező megjegyzés + "E-mail küldése és mehet tovább a zárás" gomb).
  - Dekádzárás dialógus év, hónap, dekád legördülőkkel (10., 20. és hónap utolsó napján történő triggerelés) és "Nyomtatás" / "Mégsem" gombokkal.
  - Napi összefoglaló (X) képernyő teljes adattartalma (záró készlet F9, pillanatnyi pénztárállás, napi forgalom, forint készlet címletbontásban, euró érme készlet, egyedi árfolyamok, KÜLDÖK/KÉREK panelek, Western Union/ÁFA/Kezelési díj/E-kereskedelem záró készletek, jelentés beküldése gombok, délelőtti/délutáni pénztáros neve).
  - Értéktári zárás-előtti checklist 10 pontja.
  - Zárást ellenőrző személy adatai dialógus ("NEVE", "BEOSZTÁSA" + jóváhagyás/elutasítás).
  - Nyomtatott bizonylatok (napi, havi, dekád, értéktári) blokk-struktúrája és szöveges nyilatkozatai.
- **OUT**:
  - A legacy felületek vizuális CSS design-ja (csak a logikai elrendezés és mezők specifikáltak).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-ZARUI-01] [Címletezés-Zárások Főmenü]
- **Leírás**: A Címletezés–Zárások menü megjelenítése az alábbi gombokkal: "Különféle címletezések", "Címletek kinyomtatása", "A mai napi zárás végrehajtása", "A havi zárás végrehajtása", "Mégsem".
- **Forrás**: Címletezés -Zárások menü.jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Menü megnyitása
- **Kimenet / Visszajelzés**: 5 gombos választóablak
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-02] [Címletezés Almenü]
- **Leírás**: A "Címletezés" almenüben 5 típusú címletezés választható: "Esti zárás címletezése", "Kezelési díj címletezése", "Western Union címletezése", "ÁFA pénztár címletezése", "Elektromos kereskedés címletezése", valamint a "Vissza / Kilépés" gombok.
- **Forrás**: Címletezés Zárások - Cimletezés.JPG
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: "Különféle címletezések" kiválasztása
- **Kimenet / Visszajelzés**: 5 címletezési opció gombja
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-03] [Címletek kinyomtatása választó]
- **Leírás**: A "Címletek kinyomtatása" párbeszédablak megjelenítése checkbox-os választókkal: Valutaváltás címletek és Kezelési díj címletek alapértelmezetten bejelöltek és aktívak; míg a Western Union, ÁFA, Foglalók, Elektromos kereskedés és AXA biztosítás címletek inaktívak (szürkítettek). Gombok: "Nyomtatás indul", "Minden kijelölése", "Kilépés".
- **Forrás**: Címletezés nyomtatása.jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: "Címletek kinyomtatása" opció
- **Kimenet / Visszajelzés**: Jelölőnégyzetes párbeszédablak
- **Validációk és Kényszerek**: Az inaktív elemek nem jelölhetők be, kivéve ha az adott funkció engedélyezve van a fiók profiljában (`HARDWARE`).

### ### [FR-ZARUI-04] [NAV-fiókérték eltérés gate]
- **Leírás**: Napi pénztárzárásnál a rendszer ellenőrzi a NAV-os forint fiókérték és a fizikai címletezés egyezőségét. Eltérés esetén piros figyelmeztetés jelenik meg: "A NAV-OS FORINT FIÓKÉRTÉKE ELTÉR A CÍMLETEZÉSTŐL". A zárás folytatásához a pénztárosnak kötelező kitöltenie a megjegyzés mezőt, majd az "E-mail küldése és mehet tovább a zárás" gombra kell kattintania.
- **Forrás**: Címletezés - Zárások napi pénztárzárás.jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: NAV fiókadatok és címletezett forintösszeg
- **Kimenet / Visszajelzés**: Piros figyelmeztetés, kötelező input, e-mail indítás a főértéktár/pénzügy felé a secure sync outbox queue soron keresztül
- **Validációk és Kényszerek**: Üres megjegyzéssel a gomb inaktív.

### ### [FR-ZARUI-05] [Dekádzárás dialógus]
- **Leírás**: Dekádzárás nyomtatása előtti dialógus: év, hónap (legördülő) és dekád (1. DEKÁD / 2. DEKÁD / 3. DEKÁD legördülő) kiválasztása, majd "Nyomtatás" vagy "Mégsem". A dekád zárás a naptár szerinti 10., 20. és a hónap utolsó napján fut le a napi zárás részeként.
- **Forrás**: Dekédzárás.jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Kiválasztott dátum-paraméterek
- **Kimenet / Visszajelzés**: Bizonylat generálása a megadott időszakra
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-06] [Napi összefoglaló (X) fejléc]
- **Leírás**: Napi összefoglaló (X) képernyő fejléce: az aktuális dátum és a fiók megnevezése (pl. 2024.03.12, Békéscsaba Belváros).
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Rendszeridő és fiókkód
- **Kimenet / Visszajelzés**: Szöveges fejléc adatok
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-07] [Záró készlet összesítő (F9)]
- **Leírás**: "Összesen záró készlet F9" blokk: az F9 billentyű lenyomására vagy kattintásra megjelenik a Forint, a Valuta és a kettő Összesen záró értéke.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: F9 trigger
- **Kimenet / Visszajelzés**: Összesített készletérték három mezőben
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-08] [Pillanatnyi pénztárállás táblázat]
- **Leírás**: Pillanatnyi pénztárállás rács megjelenítése devizanemenkénti bontásban az alábbi oszlopokkal: DNEM, KÉSZLET, VÉTEL, ELADÁS.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Aktuális készletadatok
- **Kimenet / Visszajelzés**: Négyoszlopos táblázat
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-09] [Napi forgalom blokk]
- **Leírás**: Napi forgalom megjelenítése Vétel és Eladás bontásban délelőtt (de), délután (du) és Összesen oszlopokkal.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Forgalmi napló adatai
- **Kimenet / Visszajelzés**: Forgalmi táblázat
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-10] [Forint készlet címletbontása]
- **Leírás**: A fizikai forint készlet darabszámainak megjelenítése az alábbi címletek szerint: 20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5 forintosok, valamint külön sorban az Euró érme készlet értéke.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Címletdarabszámok
- **Kimenet / Visszajelzés**: Címletjegyzék nézet
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-11] [Egyedi árfolyamok blokk]
- **Leírás**: Egyedi (alkudott) árfolyamok listázása a záróképernyőn: Valutanem, Összeg, Árfolyam és a kapcsolódó Bizonylatszám.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Napi egyedi árfolyamos tranzakciók
- **Kimenet / Visszajelzés**: Egyedi árfolyamok táblázat
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-12] [KÜLDÖK/KÉREK panelek]
- **Leírás**: Pénztárak közötti belső készletmozgások (KÜLDÖK és KÉREK irányok) megjelenítése és kezelése a zárás felületén.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Belső mozgások állapota
- **Kimenet / Visszajelzés**: Küldési/kérési indikátorok és összegek. Átadás-átvételi tranzakciók esetén a plomba (seal) számát is meg kell jeleníteni.
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-13] [WU és egyéb készletek megjelenítése]
- **Leírás**: Western Union záró készletek (HUF és USD), ÁFA innova készlet (HUF), Kezelésidíj és Elektromos kereskedelem záró egyenlegeinek megjelenítése. A Western Union egyenlegek (nyitó készlet, bevétel, kiadás és záró készlet) manuálisan kerülnek megadásra a felületen, mivel nincs közvetlen API integráció a Western Union rendszerével.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Western Union adatok (manuális bevitel), ÁFA, Kezelési díj modulok készletértékei
- **Kimenet / Visszajelzés**: Egyedi modul-készlet panelek
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-14] [Jelentés beküldési opciók]
- **Leírás**: Lehetőség biztosítása a zárási jelentés azonnali beküldésére ("Jelentés beküldése") vagy későbbre halasztására ("Most nem küldöm be").
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Kattintási művelet
- **Kimenet / Visszajelzés**: Jelentés elküldése / helyi mentés lezárása
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-15] [Délelőtti/délutáni pénztáros rögzítése]
- **Leírás**: A napi összefoglalón rögzíteni és jelezni kell a délelőtti és délutáni műszakot teljesítő pénztárosok (Ptáros de/du) nevét/kódját.
- **Forrás**: Napi összefoglaló (X).jpeg
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Pénztárosok azonosítói
- **Kimenet / Visszajelzés**: Műszak-adatok rögzítése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-16] [Értéktári zárás checklist]
- **Leírás**: Értéktári zárás-előtti checklist felület megjelenítése a kötelező és eseti (időszakos) ellenőrzési feladatokkal (10 pontos lista), a zárás dátumával és a zárást végző pénztáros nevével.
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checklist betöltése
- **Kimenet / Visszajelzés**: Kipipálható feladatlista (10 pont)
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-17] [Checklist: Pénztár készletek feltöltése]
- **Leírás**: Checklist 1. tétel: "Minden pénztár készlete feltöltve (címletek, fém euró)". Ezt a tételt kötelező ellenőrizni és kipipálni.
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Felhasználói ellenőrzés
- **Kimenet / Visszajelzés**: Checkbox bejelölése
- **Validációk és Kényszerek**: Enélkül az értéktári zárás nem engedélyezett.

### ### [FR-ZARUI-18] [Checklist: Helyettesítés és átadás]
- **Leírás**: Checklist 2. tétel: "Esetleges helyettesítéskor kollégának minden infó átadólapon átadva".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-19] [Checklist: Grafikon kitöltés]
- **Leírás**: Checklist 3. tétel: "Grafikon kitöltve, kifüggesztve, érintetteknek továbbítva".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-20] [Checklist: Konkurencia figyelése]
- **Leírás**: Checklist 4. tétel: "Konkurencia árfolyamainak/készleteinek figyelemmel követése; konkurencia-jelentés megírása (eseti)".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-21] [Checklist: Próbaváltás és havi beszámoló]
- **Leírás**: Checklist 5. tétel: "Próbaváltás (eseti); havi beszámoló megírása, lefűzése (eseti)".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-22] [Checklist: Bizonylatok lefűzése]
- **Leírás**: Checklist 6. tétel: "Bizonylatok párosítása, lefűzése; Kkts/E-ker/jutalék beszedése-befizetése (eseti)".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-23] [Checklist: Táblázatok kitöltése]
- **Leírás**: Checklist 7. tétel: "TRB tábla kitöltése; egyedi árfolyamos tábla kitöltése+továbbítása (eseti); egyedi árfolyamok ellenőrzése+továbbítása (eseti)".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-24] [Checklist: Kártyák és könyvelések]
- **Leírás**: Checklist 8. tétel: "Nagy ügyfélkártyák begyűjtése/összesítése, továbbítása (eseti); könyvelések lenyomtatása, lefűzése, adatainak ellenőrzése (eseti)".
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-25] [Checklist: Hóvégi egyeztetések]
- **Leírás**: Checklist 9. tétel: "Hóvégi egyeztetés területekkel (eseti); hóvégi egyeztetés pénztárakkal; napi jelentések leszavainak elküldése SMS-ben a pénztáraknak/értéktárosoknak stb. (eseti)" (a checklist 9. és 10. pontjának összevont reprezentációja).
- **Forrás**: Értéktári zárás előtti check list.JPG
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Checkbox pipa
- **Kimenet / Visszajelzés**: Állapot mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-26] [Zárást ellenőrző személy dialógus]
- **Leírás**: Értéktári zárás végén felugró ellenőrző személy adatai dialógus: a rendszer bekéri az ellenőrző személy NEVÉT és BEOSZTÁSÁT, továbbá megjeleníti "A zárószalagot kérem aláírni" alcímet. Jóváhagyás: "Ellenőrző személy adatai rendben" gombbal, megszakítás: "Mégsem zárom a napot".
- **Forrás**: Értéktári zárást ellenőrző személy adatai.JPG
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Név, beosztás, gomb kattintás
- **Kimenet / Visszajelzés**: Adatok mentése és a nap lezárása / megszakítás
- **Validációk és Kényszerek**: Üres név vagy beosztás esetén a jóváhagyás nem engedélyezett.

### ### [FR-ZARUI-27] [Nyomtatott Napi Zárás bizonylat]
- **Leírás**: A kinyomtatott Napi Zárás bizonylatnak tartalmaznia kell: cégfejléc, zárás dátuma, valuta vásárlások/eladások összesítve, belső pénztárközi mozgások (DNEM, Átadott, Átvett bontásban) plomba adatokkal, napi valutaárfolyamok (vétel/eladás), napi záró- és nyitókészletek, napi forgalmi kimutatás I–II., kezelési költség listák, valamint a "Büntetőjogi felelősségem tudatában..." nyilatkozat és a pénztáros aláírás helye.
- **Forrás**: Bizonylatok/Napi zárás.jpg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Lezárt nap adatai
- **Kimenet / Visszajelzés**: Generált nyomtatott bizonylat dokumentum
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-28] [Nyomtatott Havi Zárás bizonylat]
- **Leírás**: A kinyomtatott Havi Zárás bizonylatnak tartalmaznia kell: cégfejléc, havi időszak határai (kezdő/záró dátum), valutánkénti nyitó, növekedés, csökkenés és záró készletértékek, belső pénztárközi mozgások havi összesítése, havi bankjegy-forgalmi kimutatás I–II., havi záró készlet valutánként, Western Union havi forgalom (USD/HUF) kézzel beírt adatok alapján összesítve, ÁFA adatok, kezelési költségek havi bontása, valamint a havi ügyfélforgalom statisztikái.
- **Forrás**: Bizonylatok/Havi zárás.jpg; Havi zárás 2_.jpg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Lezárt havi adatok
- **Kimenet / Visszajelzés**: Generált nyomtatott havi zárás dokumentum
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-29] [Nyomtatott Havi Dekádzárás bizonylat]
- **Leírás**: A kinyomtatott Dekádzárás bizonylatnak tartalmaznia kell: fiókfejléc, "havi 1./2./3. dekádzárás" megnevezés, dekád időszak (pl. 2024.03.01–2024.03.10), napi bontású táblázat (Sor, Nap, Bizonylatszám, Forint átvétel, Forint átadás, Valuta vétel, Valuta eladás), dekád forgalom összesen, nyitó/záró/összes forint értékek, valamint a pénztáros aláírása.
- **Forrás**: Bizonylatok/2024. március. 1. havi dekádzárás.jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Lezárt dekád adatai
- **Kimenet / Visszajelzés**: Generált nyomtatott dekádzárás dokumentum
- **Validációk és Kényszerek**: N/A

### ### [FR-ZARUI-30] [Nyomtatott Értéktári Zárás bizonylat]
- **Leírás**: Az Értéktári Zárás bizonylat egy egybefüggő, többhasábos nyomtatvány, melynek tartalmaznia kell: cégfejléc, napi/időszaki záró tételek, bankjegy-forgalmi kimutatás I–II. (nyitó, átvett, átadott, záró oszlopokkal), pénztárközi mozgások értéktári összesítése, Western Union forgalom, gép-visszatérítendő és ügyfélforgalmi összesítések, valamint a pénztáros aláírása.
- **Forrás**: Bizonylatok/Zárás-Értéktár.jpeg
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Lezárt értéktári adatok
- **Kimenet / Visszajelzés**: Generált nyomtatott értéktári zárás dokumentum
- **Validációk és Kényszerek**: N/A
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

A zárások és bizonylatok adatszerkezetének rögzítéséhez az alábbi Postgres és SQLite mirror sémákat javasoljuk:

### PostgreSQL
- **CashDenomination (Címletezés napló)**:
  - `id` (serial, primary key)
  - `closure_id` (int, foreign key -> Closure)
  - `denomination_type` (varchar, pl. 'ESTI_ZARAS', 'KEZELESI_DIJ', 'WU', 'AFA', 'E_KERESKEDELEM')
  - `currency_code` (varchar(3), default 'HUF')
  - `denom_20000` (int, default 0)
  - `denom_10000` (int, default 0)
  - `denom_5000` (int, default 0)
  - `denom_2000` (int, default 0)
  - `denom_1000` (int, default 0)
  - `denom_500` (int, default 0)
  - `denom_200` (int, default 0)
  - `denom_100` (int, default 0)
  - `denom_50` (int, default 0)
  - `denom_20` (int, default 0)
  - `denom_10` (int, default 0)
  - `denom_5` (int, default 0)
  - `euro_coins` (decimal, default 0)
- **NavMismatchLog (NAV eltérés napló)**:
  - `id` (serial, primary key)
  - `closure_id` (int, foreign key -> Closure)
  - `nav_value` (decimal)
  - `physical_value` (decimal)
  - `cashier_comment` (text)
  - `email_sent` (boolean, default false)
- **ChecklistProgress (Értéktári checklist állapota)**:
  - `id` (serial, primary key)
  - `closure_id` (int, foreign key -> Closure)
  - `task_key` (varchar, pl. 'CASH_FILLED', 'HANDOVER_DONE', 'GRAPH_OK', 'COMPETITOR_CHECK', 'TRIAL_EXCHANGE', 'RECEIPTS_FILED', 'TRB_TABLE', 'CARDS_COLLECTED', 'MONTHLY_RECONCILE')
  - `is_checked` (boolean, default false)
- **ClosureAuditor (Zárás ellenőrző személy)**:
  - `id` (serial, primary key)
  - `closure_id` (int, foreign key -> Closure)
  - `auditor_name` (varchar)
  - `auditor_title` (varchar)

### SQLite (Offline mirror a kliensen)
- A címletezés, a checklistek haladása, valamint az ellenőrző személyek adatai offline is rögzíthetők kell legyenek a kliens oldali SQLite adatbázisban a zárási folyamat biztonságos elvégzéséhez.

### Legacy adatbázis leképezés (Legacy Mappings)
- `CIMT` (Címletek darabszámait rögzítő tábla)
- `ADATLAP` (Pénztári adatlap és belső mozgások tárolója)
- `NAPIOSSZESITO` / `NAPIZAR` (Napi zárások összesítő táblája)
- `HAVIOSSSZESITO` / `ELOHAVI` (Havi zárások összesítő táblája)
- `BLOKKFEJ` / `BLOKKTETEL` (Bizonylatok és tranzakciók forrástáblái)
- `HARDWARE` (Fiók hardver és modul konfigurációs táblája)
</data_structure>

<integration_points>
## Integrációs Pontok
- **NAV (Online Pénztárgép adatszolgáltató)**:
  - Lekérdezési csatorna a NAV-os forint fiókérték kinyerésére (FR-ZARUI-04).
- **E-mail küldő szolgáltatás**:
  - Automatikus riasztó e-mail kiküldése a pénzügynek NAV-fiókérték eltérés esetén (FR-ZARUI-04) a secure sync outbox queue kimenő soron keresztül.
- **Western Union és ÁFA innova rendszerek**:
  - A Western Union záró készletek kézi beviteli felülete (mivel közvetlen API kapcsolat nincs). ÁFA készlet adatok beolvasása az ÁFA modulból.
- **Bizonylat-nyomtató meghajtó (kliens)**:
  - A fizikai nyomtatási parancsok átadása a bizonylat-nyomtatónak (FR-ZARUI-27..FR-ZARUI-30).
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Tekintsd át a forrás-képernyőképeket és bizonylat-blokkokat.
- Tisztázd a checklist tételek szöveges elrendezését.

### Phase 2: Backend (Backend)
- Készítsd el a PostgreSQL adatbázis migrációs szkripteket (címletezés, NAV eltérés, checklist, ellenőrző személy, legacy tábla hivatkozások).
- Fejleszd le az eltérést ellenőrző validációs végpontot.
- Valósítsd meg az e-mail küldési mechanizmust hiba esetére az outbox queue segítségével.
- Készítsd el a bizonylatok (napi/dekád/havi/értéktári) PDF generáló szolgáltatását.

### Phase 3: Frontend/Client (Frontend/Client)
- Fejleszd le a Címletezés Főmenüt és az 5-típusú Címletezés Almenüt a darabszám-bevitelre.
- Építsd be a piros figyelmeztető bannert és a kötelező komment-mezőt a NAV-eltérés kezeléséhez.
- Készítsd el a Napi összefoglaló (X) részletes rács-nézetét, a manuális Western Union bevitelt és az F9 összesítést.
- Készítsd el a 10 pontos kipipálható értéktári checklist és az ellenőrző személy adatait bekérő modalt.
- Valósítsd meg a bizonylatok nyomtatási előnézetét és a fizikai nyomtatás vezérlését.

### Phase 4: Verification (Verification)
- **Unit tesztek**: Teszteld a NAV eltérés vizsgálatát (egyezésnél nincs gate, eltérésnél komment és e-mail gomb kötelező).
- **Unit tesztek**: Ellenőrizd a címletösszeg-számító matematikai logikát (darabszámok szorzata a címletértékekkel).
- **Integrációs tesztek**: Ellenőrizd az értéktári zárás-előtti checklist mentését és az ellenőrző személy adatainak helyes rögzítését a zárási objektumban.
- **Snapshot tesztek**: Ellenőrizd a generált zárási bizonylat PDF dokumentumok szerkezeti egyezését a forrásképek alapján.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | A NAV-eltérés "E-mail küldése" címzettje, tartalma és csatornája | Biztonsági riasztás működése | **LEZÁRVA**: Az e-mail a központi treasury/pénzügy címére megy, a secure sync outbox queue kimenő soron keresztül. |
| TBD-2 | A pénztáros / értéktáros / ellenőrző személy konkrét RBAC szerepkör-értéke | Biztonságos jogosultság-ellenőrzés | **LEZÁRVA**: Pénztáros (`ROLE_CASHIER`), Értéktáros (`ROLE_TREASURER`), Ellenőrző személy (`ROLE_SUPERVISOR` vagy `ROLE_AUDITOR`). |
| TBD-3 | Címletezés/összefoglaló/checklist/bizonylat pontos adatmodellje + SQLite mirror mezők | Offline konzisztencia | **LEZÁRVA**: Lokálisan az SQLite `CashDenomination`, `NavMismatchLog`, `ChecklistProgress`, `ClosureAuditor` táblákban tárolva. Legacy leképezések: `CIMT`, `ADATLAP`, `NAPIOSSZESITO`, `HAVIOSSSZESITO`/`ELOHAVI`. |
| TBD-4 | A szürkített címlet-nyomtatási opciók (WU, ÁFA, AXA stb.) aktiválási feltétele | Felhasználói felület viselkedése | **LEZÁRVA**: A checkboxok akkor aktívak, ha a fiók profiljában (`HARDWARE` tábla) a hozzájuk tartozó modul engedélyezve van. |
| TBD-5 | Az értéktári checklist tételek pontos, teljes és végleges szövege | Felület hűsége | **LEZÁRVA**: A 10 pontos ellenőrzési lista véglegesítve (lásd: FR-ZARUI-16..FR-ZARUI-25). |
| TBD-6 | Bizonylat-minták kézzel írt és javított számainak kezelése | Bizonylatok adatintegritása | **LEZÁRVA**: A nyomtatott elrendezés a strukturált adatbázis adatokat követi, a kézzel írt javítások csak illusztrációk. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden funkcionális követelmény (FR-ZARUI) visszakövethető a screenshotok és bizonylatképek alapján és a verifikált tényekre.
- [x] 0 hallucináció (minden mező, checkbox és bizonylatblokk szigorúan a képek alapján került leírásra).
- [x] Minden kép-olvashatósági korlát és egyéb bizonytalanság (TBD-5, TBD-6) feloldásra és rögzítésre került.
</verification_checklist>
