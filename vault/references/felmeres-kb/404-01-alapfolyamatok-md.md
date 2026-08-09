---
title: 01_alapfolyamatok.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/01_alapfolyamatok.md
doc_type: text
---

# 01_alapfolyamatok.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 4.9 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/01_alapfolyamatok.md`

## Tartalom

# Valutaváltó Rendszer Alapfolyamatai

## Bevezetés

Ez a dokumentum a valutaváltó rendszer alapvető folyamatait írja le, beleértve a devizanemek kezelését, árfolyamok beállítását és a fiókok
működtetését. Az itt leírt folyamatok a rendszer alapvető működésének gerincét alkotják.

## Devizanemek kezelése

### Új devizanem rögzítése

1. A rendszeradminisztrátor az adminisztrációs felületen új devizanemet (`currency`) hoz létre.
2. Megadja a kötelező adatokat:
    - ISO 4217 devizakód (`code`) - egyedi azonosító
    - Teljes név (`name`)
    - Szimbólum (`symbol`) - opcionális
    - Alap devizanem-e (`is_base`) - rendszerenként egy lehet aktív alapdevizanem
    - Státusz (`currency_status_did`) - kezdetben általában "ACTIVE"
3. A rendszer menti az új devizanemet a törzsadatok közé.
4. Egy devizanem státusza (`currency_status_did`) lehet:
    - ACTIVE - aktívan használható
    - INACTIVE - ideiglenesen nem használható
    - SUSPENDED - felfüggesztett (pl. hatósági utasításra)
    - DEPRECATED - kivezetett (történeti adatokban még előfordulhat)

### Devizanem módosítása

1. Az adminisztrátor kiválasztja a módosítani kívánt devizanemet.
2. Módosíthatja a nevet, szimbólumot és a státuszt.
3. Az ISO kód (`code`) módosítása csak különleges esetben, audit mellett engedélyezett.
4. Az alapdevizanem-jelölés (`is_base`) módosítása rendszerszintű hatással jár, és speciális jóváhagyást igényel.

## Árfolyamok kezelése

### Napi központi árfolyamok rögzítése

1. Az árfolyamkezelésért felelős munkatárs az MNB/ECB/egyéb központi forrásból származó napi árfolyamokat (`exchange_rate`) rögzíti a rendszerben.
2. Minden devizanem-párra megadja az alábbi értékeket:
    - Forrás devizanem (`source_currency_id`)
    - Cél devizanem (`target_currency_id`)
    - Árfolyam dátuma (`rate_date`)
    - Vételi árfolyam (`buy_rate`)
    - Közép árfolyam (`mid_rate`)
    - Eladási árfolyam (`sell_rate`)
    - Érvényesség kezdete (`validation_date`)
    - Érvényesség vége (`expiration_date`) - opcionális
3. A rendszer ellenőrzi, hogy egyazon devizanem-párra ne legyen átfedő érvényességi időszak.
4. Az árfolyamok az aktív jelölést (`is_active`) automatikusan megkapják a megadott érvényességi idő alapján.

### Fiókspecifikus árfolyamok beállítása

A rendszer támogatja, hogy a fiókok egyedi árfolyamokat alkalmazzanak, amelyek eltérhetnek a központi árfolyamoktól. Ez a funkció a
`branch_exchange_rate` entitás segítségével valósul meg (a pontos definíció a fájlokból kimaradt, de a hivatkozások alapján létezik).

1. Fiókvezetők vagy kijelölt árfolyamkezelők módosíthatják a helyi árfolyamokat.
2. A módosítás történhet:
    - Rögzített árfolyammal (FIXED)
    - Additív módosítással (ADDITIVE) - a központi árfolyamhoz hozzáadott/kivont érték
    - Multiplikatív módosítással (MULTIPLICATIVE) - százalékos szorzó
3. Minden módosításhoz jóváhagyás szükséges a megfelelő szinten (APPROVAL_LEVEL).

## Fiókkezelés

### Új fiók létrehozása

1. A rendszeradminisztrátor új fiókot (`branch`) hoz létre.
2. Megadja a fiók alapadatait:
    - Kód (`code`) - egyedi azonosító
    - Név (`name`)
    - Cím adatok: utca (`address`), város (`city`), irányítószám (`zip_code`), ország (`country_did`)
    - Elérhetőségek: telefon (`phone`), e-mail (`email`)
    - Nyitvatartási idő: nyitás (`opening_time`), zárás (`closing_time`)
3. A fiók kezdetben inaktív állapotban jön létre, aktiválás előtt további beállítások szükségesek.

### Fiók aktiválása

1. Az adminisztrátor vagy megfelelő jogosultsággal rendelkező vezető aktiválhatja a fiókot (`is_active` = true).
2. Aktiválás előtti ellenőrzőlista:
    - Legalább egy aktív pénztáros hozzárendelése
    - Kezdeti pénzkészlet rögzítése minden devizanemben
    - Árfolyamok ellenőrzése
    - Engedélyek és jogosultságok beállítása

### Pénztárosok hozzárendelése

1. Az adminisztrátor a dolgozói törzsadatban (`worker`) szereplő személyekből pénztárosokat (`cashier`) rendelhet a fiókhoz.
2. Megadja a pénztáros adatait:
    - Dolgozó azonosító (`worker_id`)
    - Fiók azonosító (`branch_id`)
    - Szerepkör (`role_did`) - lehet: ADMIN, MANAGER, CASHIER, SUPERVISOR, AUDITOR vagy READONLY
    - Aktív státusz (`is_active`)
3. A rendszer ellenőrzi a dolgozó megfelelő képesítését és jogosultságát.

### Fiókcsoportok kezelése

A rendszer támogatja a fiókok csoportosítását különböző szempontok szerint. A fiókcsoportok típusai (`BRANCH_GROUP_TYPE`) lehetnek:

- REGIONAL - földrajzi régió alapján
- FUNCTIONAL - funkció alapján
- ORGANIZATIONAL - szervezeti struktúra alapján
- CUSTOM - egyedi csoportosítás

A csoportos árfolyamkezelés a `branch_group_exchange_rate` entitáson keresztül történik.
