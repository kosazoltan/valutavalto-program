---
title: README.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/README.md
doc_type: text
---

# README.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 4.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/README.md`

## Tartalom

# PuzzleIR-figdocs

## Bevezetés

Ez a repository a PuzzleIR rendszer dokumentációját tartalmazza. A dokumentáció különböző modulok és folyamatok leírását tartalmazza, amelyek segítik a rendszer fejlesztését, bevezetését és üzemeltetését.

## Dokumentáció struktúra

A dokumentáció az alábbi fő részekből áll:

### Modul- és Menüstruktúra

A rendszer modul- és menüstruktúrájának részletes leírása a [modulstruktura.md](./modulstruktura.md) fájlban található. Ez a dokumentum tartalmazza:

- A rendszer moduljainak leírását
- A menüstruktúra részletes bemutatását
- CRUD komponensek működését
- Folyamat-specifikus képernyők leírását
- Kezelőfelületek szerepkörönkénti bemutatását
- Rendszerkialakítási megfontolásokat

### Folyamatdokumentációk

A rendszer folyamatai az alábbi mappákban találhatók:

#### Valutaváltó Folyamatok

A [valuta_folyamatok](./valuta_folyamatok) mappában találhatók a valutaváltó rendszer folyamatainak dokumentációi:

1. [Alapfolyamatok](./valuta_folyamatok/01_alapfolyamatok.md) - A rendszer alap működési folyamatai
2. [Pénztárkezelés](./valuta_folyamatok/02_penztarkezeles.md) - A pénztárkezeléssel kapcsolatos folyamatok
3. [Tranzakciók kezelése](./valuta_folyamatok/03_tranzakciok.md) - A valutaváltási tranzakciók folyamatai
4. [Szállítmánykezelés](./valuta_folyamatok/04_szallitmanykezeles.md) - A valutaszállítmányok kezelésének folyamatai
5. [Ügyfélkezelés](./valuta_folyamatok/05_ugyfelkezeles.md) - Az ügyfelekkel kapcsolatos folyamatok
6. [Rendszeradminisztráció](./valuta_folyamatok/06_rendszeradminisztracio.md) - A rendszer adminisztrációs folyamatai
7. [Címletezés paraméterezés](./valuta_folyamatok/07_cimletkezeles.md) - A címletezési funkciók kezelésének folyamatai

#### Puzzle Folyamatok

A [puzzle_folyamatok](./puzzle_folyamatok) mappában találhatók a Puzzle rendszer specifikus folyamatainak dokumentációi:

1. [Meghatalmazott kezelés](./puzzle_folyamatok/08_meghatalmazott_kezeles.md) - A meghatalmazottak kezelésének folyamatai

### Entitás-definíciók

A repository számos entitás-definíciós fájlt tartalmaz (`.figdoc.md` kiterjesztéssel), amelyek a rendszer adatmodelljét írják le. Ezek a fájlok tartalmazzák az egyes entitások attribútumait, kapcsolatait és működési logikáját.

## Használat

A dokumentáció moduláris felépítésű, így a különböző területekre vonatkozó információk külön fájlokban találhatók. A dokumentáció a rendszer fejlesztése, bevezetése és üzemeltetése során egyaránt hasznos lehet:

- Fejlesztők számára - Az implementálandó folyamatok megértéséhez
- Tesztelők számára - A tesztesetek kialakításához
- Üzemeltetők számára - A rendszer működésének megértéséhez
- Végfelhasználók számára - A rendszer használatának elsajátításához
- Auditorok számára - A folyamatok és kontrollok ellenőrzéséhez

## Kapcsolódó dokumentumok

- Entitás-definíciós fájlok (`.figdoc.md` kiterjesztéssel)
- Rendszer-architektúra dokumentáció
- Felhasználói kézikönyvek
- Telepítési útmutatók

## Új funkciók áttekintése

### Címletezés paraméterezés

A címletezés paraméterezési funkció lehetővé teszi a valutaváltási tranzakciók során a bankjegyek és érmék kiadásának optimalizálását. A rendszer beépített intelligens algoritmusokat használ a legmegfelelőbb címletkombináció meghatározására a különböző üzleti helyzetekben.

Főbb jellemzők:
- Különböző optimalizálási stratégiák (minimális darabszám, minimális érme, egyedi prioritások)
- Fiók-specifikus címletezési szabályok
- Összeg alapú szabályok (nagy és kis összegekre külön stratégiák)
- Automatikus javaslatok tranzakciók és szállítmányok esetén
- Részletes naplózás és statisztikák a címletezési hatékonyság elemzéséhez

### Meghatalmazott kezelés

A meghatalmazott kezelési funkció lehetővé teszi az ügyfelek számára, hogy meghatalmazottakat jelöljenek ki, akik jogosultak a nevükben tranzakciókat végrehajtani. A rendszer biztosítja a meghatalmazottak azonosítását, jogosultságaik kezelését és tevékenységük nyomon követését.

Főbb jellemzők:
- Különböző meghatalmazás-típusok (ideiglenes, állandó, korlátozott)
- Részletes jogosultságkezelés műveletenkénti szinten
- Automatikus érvényesség-ellenőrzés és jogosultság-validálás
- Meghatalmazotti tevékenységek részletes naplózása
- Compliance funkciók a gyanús tevékenységek észlelésére
