---
title: crud_komponensek.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/crud_komponensek.md
doc_type: text
---

# crud_komponensek.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 9.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/crud_komponensek.md`

## Tartalom

# Valutaváltó Rendszer - CRUD Komponensek Specifikációja

## Bevezetés

Ez a dokumentum részletezi a valutaváltó rendszer CRUD (Create, Read, Update, Delete) komponenseinek specifikációját. Minden fő entitás esetében
létrejönnek ezek az alapvető karbantartó komponensek, amelyek egységes elvek szerint működnek, de tartalmazzák az entitás-specifikus funkciókat is.

## Általános CRUD komponens felépítés

Minden entitáshoz az alábbi standard CRUD komponensek készülnek:

### 1. Lista komponens

- Entitások táblázatos megjelenítése
- Szűrési lehetőségek releváns mezők szerint
- Lapozás és rendezés
- Műveleti gombok: létrehozás, megtekintés, szerkesztés, törlés/inaktiválás
- Exportálási lehetőség (CSV, Excel)

### 2. Részletes nézet komponens

- Entitás összes adatának megjelenítése csak olvasható formában
- Kapcsolódó entitások megjelenítése (tabfüleken vagy accordionokban)
- Műveleti gombok: vissza a listához, szerkesztés, törlés/inaktiválás
- Entitás-specifikus akciógombok

### 3. Szerkesztő/létrehozó komponens

- Űrlap az entitás mezőinek szerkesztésére
- Validáció az entitás szabályai szerint
- Kapcsolódó entitások kiválasztása (legördülő listák, keresők)
- Műveleti gombok: mentés, mégse, entitás-specifikus akciógombok

### 4. Törlés/inaktiválás komponens

- Megerősítési dialógus
- Függőségek ellenőrzése
- Törlés vagy inaktiválás végrehajtása

## Entitás-specifikus CRUD komponensek

Az alábbiakban részletezzük a fő entitások CRUD komponenseinek specifikus tulajdonságait.

### Currency (Devizanem)

#### Lista komponens

- Szűrési lehetőségek: kód, név, aktív státusz
- Rendezés: kód, név, státusz
- Speciális oszlopok: alapdevizanem jelölés, státusz

#### Részletes nézet komponens

- Árfolyam-történet tabfül
- Kapcsolódó tranzakciók tabfül
- Speciális akciógombok: aktiválás/deaktiválás, alapdevizanemmé tétel (csak adminisztrátornak)

#### Szerkesztő/létrehozó komponens

- Speciális validáció: ISO 4217 kód ellenőrzése
- Figyelmeztető üzenet az alapdevizanem megváltoztatásakor

### Exchange Rate (Árfolyam)

#### Lista komponens

- Szűrési lehetőségek: forrás devizanem, cél devizanem, dátum, érvényesség
- Speciális oszlopok: vételi/közép/eladási árfolyam, érvényességi idő

#### Részletes nézet komponens

- Grafikon tabfül az árfolyam-alakulással
- Kapcsolódó tranzakciók tabfül
- Speciális akciógombok: érvényesség módosítása, árfolyam-másolás új dátumra

#### Szerkesztő/létrehozó komponens

- Automatikus számítások: ha pl. középárfolyamot ad meg, javaslatot tesz vételi/eladási árfolyamra
- Figyelmeztetés átfedő érvényességi időszak esetén
- Tömeges importálás lehetősége CSV-ből

### Branch (Fiók)

#### Lista komponens

- Szűrési lehetőségek: kód, név, ország, város, aktív státusz
- Speciális oszlopok: nyitvatartási idő, aktív pénztárosok száma

#### Részletes nézet komponens

- Pénztárosok tabfül
- Bankjegykészlet tabfül
- Tranzakciók tabfül
- Speciális akciógombok: aktiválás/deaktiválás, pénztáros hozzárendelés

#### Szerkesztő/létrehozó komponens

- Térkép komponens a cím kiválasztásához
- Nyitvatartási idők beállítása napi bontásban
- Fiókcsoporthoz rendelés lehetősége

### Cashier (Pénztáros)

#### Lista komponens

- Szűrési lehetőségek: név, fiók, szerepkör, aktív státusz
- Speciális oszlopok: aktuális státusz (bejelentkezett/kijelentkezett), tranzakciószám

#### Részletes nézet komponens

- Tranzakciók tabfül
- Napi zárások tabfül
- Jogosultságok tabfül
- Speciális akciógombok: fiókváltás, szerepkörváltás, aktiválás/deaktiválás

#### Szerkesztő/létrehozó komponens

- Dolgozó kiválasztása (ha már létezik)
- Jogosultságok beállítása
- Fiókok hozzárendelése (egy pénztáros több fiókban is dolgozhat)

### Transaction (Valutaváltási tranzakció)

#### Lista komponens

- Szűrési lehetőségek: dátum, tranzakciószám, fiók, pénztáros, ügyfél, devizanemek, összeg, státusz
- Speciális oszlopok: forrás összeg/deviza, cél összeg/deviza, jutalék, pénztáros

#### Részletes nézet komponens

- Bankjegy részletek tabfül
- Ügyfél adatok tabfül (ha kapcsolódik ügyfél)
- Tranzakció történet tabfül (módosítások, sztornók)
- Speciális akciógombok: sztornó, nyugta újranyomtatás

#### Szerkesztő/létrehozó komponens

- A tényleges tranzakció folyamatához igazított speciális űrlap:
    - Forrás és cél devizanem kiválasztása
    - Összeg megadása
    - Árfolyam automatikus lekérése vagy manuális felülbírálás
    - Jutalék számítása vagy manuális felülbírálás
    - Bankjegy részletek megadása
    - Ügyfél kiválasztása vagy rögzítése

### Banknote Inventory (Bankjegykészlet)

#### Lista komponens

- Szűrési lehetőségek: fiók, devizanem, címlet, érmék/bankjegyek
- Speciális oszlopok: mennyiség, érték helyi valutában, utolsó frissítés

#### Részletes nézet komponens

- Készletváltozás-történet tabfül
- Kapcsolódó tranzakciók tabfül
- Speciális akciógombok: készletkorrekció, leltár

#### Szerkesztő/létrehozó komponens

- Fiók és devizanem kiválasztása
- Címletek megadása táblázatos formában
- Mennyiségek megadása
- Korrekció esetén indoklás megadása

### Daily Closing (Napi zárás)

#### Lista komponens

- Szűrési lehetőségek: dátum, fiók, pénztáros, státusz
- Speciális oszlopok: tranzakciószám, forgalom, záró készpénzállomány

#### Részletes nézet komponens

- Zárás részletek tabfül (devizanemenként, címletenként)
- Tranzakciók tabfül
- Eltérések tabfül
- Speciális akciógombok: jóváhagyás, visszanyitás (csak supervisor), zárási jegyzőkönyv nyomtatása

#### Szerkesztő/létrehozó komponens

- A zárási folyamathoz igazított speciális űrlap:
    - Pénztár kiválasztása
    - Záró pénzkészlet rögzítése devizanemenként, címletenként
    - Automatikus egyeztetés a várt készlettel
    - Eltérések rögzítése és indoklása
    - Zárási megjegyzések rögzítése

### Customer (Ügyfél)

#### Lista komponens

- Szűrési lehetőségek: név, azonosító, kategória, regisztráció dátuma
- Speciális oszlopok: tranzakciók száma, utolsó tranzakció dátuma

#### Részletes nézet komponens

- Személyes adatok tabfül
- Tranzakciók tabfül
- Preferenciák tabfül
- Megjegyzések tabfül
- Speciális akciógombok: kategória módosítás, inaktiválás, dokumentumok megtekintése

#### Szerkesztő/létrehozó komponens

- Személyes adatok űrlap
- Azonosító okmányok adatainak rögzítése
- Marketing preferenciák beállítása
- Dokumentumok feltöltése (személyi igazolvány, egyéb azonosítók)

## Rendszerparaméter-specifikus komponensek

A rendszerparaméterek nem standard CRUD komponensekkel kezelendők, hanem kategóriákra bontott konfigurációs képernyőkkel:

### Általános paraméterek

- Rendszer neve, verziója
- Alapértelmezett nyelv
- Alapértelmezett devizanem
- Naplózási beállítások

### Árfolyam paraméterek

- Alapértelmezett jutaléksávok
- Alapértelmezett árfolyam-marzsok
- Árfolyam-frissítési időpontok
- Árfolyam-kerekítési szabályok

### Biztonsági paraméterek

- Jelszó komplexitási követelmények
- Bejelentkezési kísérletek száma
- Munkamenet időtúllépés
- Kétfaktoros hitelesítés beállításai

### Üzleti szabály paraméterek

- Ügyfél-azonosítási limitek
- Tranzakció jóváhagyási limitek
- Készletszint határértékek
- Napi limitek felhasználónként

## Jogosultságkezelés a CRUD műveletekhez

A CRUD műveletek jogosultságai finom granularitással beállíthatók:

### Olvasási jogosultság szintek

- Nincs hozzáférés
- Csak saját adatok (pl. pénztáros csak a saját tranzakcióit láthatja)
- Fiókhoz tartozó adatok (pl. fiókvezető láthatja a fiók összes tranzakcióját)
- Teljes hozzáférés (pl. adminisztrátor minden adatot láthat)

### Írási/módosítási jogosultság szintek

- Nincs jogosultság
- Csak létrehozás
- Létrehozás és saját adatok módosítása
- Létrehozás és fiókhoz tartozó adatok módosítása
- Teljes módosítási jogosultság

### Törlési jogosultság szintek

- Nincs jogosultság
- Csak saját adatok törlése/inaktiválása
- Fiókhoz tartozó adatok törlése/inaktiválása
- Teljes törlési jogosultság

### Jóváhagyási jogosultság szintek

- Nincs jogosultság
- Fiókszintű jóváhagyás
- Régiószintű jóváhagyás
- Teljes jóváhagyási jogosultság

## CRUD komponensek technikai megfontolásai

1. **Újrafelhasználható komponensek** - A CRUD komponensek újrafelhasználhatóan, paraméterezhető módon készülnek

2. **Validációs keretrendszer** - Egységes validációs keretrendszer használata minden entitás űrlapjához

3. **Reakciógyorsaság** - Nagyméretű listák esetén lap alapú betöltés és virtuális görgetés

4. **Audit naplózás** - Minden módosítás automatikus audit naplózása

5. **Formulák mezőközi függőségek kezelésére** - Számított mezők és mezők közötti függőségek dinamikus kezelése

6. **Testreszabható listák** - A felhasználó testreszabhatja a listanézetek oszlopait és a rendezést

7. **Gyorsbillentyűk** - Standard gyorsbillentyűk a CRUD műveletekhez (pl. Ctrl+S mentéshez)

8. **Offline működés** - Kritikus komponensek esetében korlátozott offline működés támogatása

9. **Többnyelvűség** - Minden komponens támogatja a többnyelvűséget

10. **Akadálymentesség** - WCAG 2.1 AA szintű akadálymentesség minden komponensnél
