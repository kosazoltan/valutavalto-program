---
title: README.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/README.md
doc_type: text
---

# README.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 6.0 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/README.md`

## Tartalom

# Valutaváltó Rendszer Folyamatdokumentáció

## Bevezetés

Ez a dokumentum áttekintést nyújt a valutaváltó rendszer folyamatdokumentációjáról. A dokumentáció az entitás-definíciók alapján készült és
részletesen leírja a rendszer különböző folyamatait.

## Dokumentáció struktúra

A valutaváltó rendszer folyamatai az alábbi dokumentumokba vannak szervezve:

1. [Alapfolyamatok](./01_alapfolyamatok.md) - A rendszer alap működési folyamatai
    - Devizanemek kezelése
    - Árfolyamok kezelése
    - Fiókkezelés

2. [Pénztárkezelés](./02_penztarkezeles.md) - A pénztárkezeléssel kapcsolatos folyamatok
    - Bankjegykészlet nyilvántartása
    - Napi pénztárműveletek
    - Kasszanyitás és -zárás

3. [Tranzakciók kezelése](./03_tranzakciok.md) - A valutaváltási tranzakciók folyamatai
    - Valutaváltási tranzakciók típusai
    - Általános tranzakciós folyamat
    - Speciális tranzakciós folyamatok
    - Tranzakciók ellenőrzése és jelentéskészítés

4. [Szállítmánykezelés](./04_szallitmanykezeles.md) - A valutaszállítmányok kezelésének folyamatai
    - Szállítmánytípusok
    - Szállítmánykezelési folyamatok
    - Készletoptimalizálási folyamatok
    - Szállítmányok nyomonkövetése és jelentéskészítés

5. [Ügyfélkezelés](./05_ugyfelkezeles.md) - Az ügyfelekkel kapcsolatos folyamatok
    - Ügyfélnyilvántartási folyamatok
    - Ügyfélkategorizálás és -elemzés
    - Speciális ügyfélkérések kezelése
    - Jogszabályi megfelelési folyamatok
    - Ügyfélkommunikáció

6. [Rendszeradminisztráció](./06_rendszeradminisztracio.md) - A rendszer adminisztrációs folyamatai
    - Rendszerparaméterek kezelése
    - Felhasználókezelés
    - Jogosultságkezelés
    - Naplózás és audit
    - Rendszer-karbantartás
    - Katasztrófa-elhárítás és üzletmenet-folytonosság
    - Jelentéskészítés és elemzés

7. [Címletezés paraméterezés](./07_cimletkezeles.md) - A címletezési funkciók kezelésének folyamatai
    - Címletkészlet definiálása
    - Címletezési optimalizációs stratégiák
    - Címletezési szabályok definiálása
    - Címletezési folyamatok alkalmazása a napi működésben
    - Címletezési folyamatok ellenőrzése és elemzése
    - Címletezési paraméterek karbantartása


## Entitás-hivatkozások

A dokumentáció a következő entitás-definíciókra hivatkozik:

### Alapentitások

- `currency` - Devizanemek
- `exchange_rate` - Árfolyamok
- `branch` - Fiókok
- `cashier` - Pénztárosok
- `worker` - Dolgozók

### Tranzakciós entitások

- `transaction` - Valutaváltási tranzakciók
- `transaction_banknote` - Tranzakció bankjegy részletek
- `banknote_inventory` - Bankjegykészlet
- `daily_closing` - Napi zárás
- `closing_detail` - Zárás részletek

### Címletezési entitások

- `currency_denomination` - Devizanem címletek
- `denomination_optimization` - Címletezési optimalizációs stratégiák
- `denomination_rule` - Címletezési szabályok
- `denomination_transaction_log` - Címletezési napló

### Kiterjesztett entitások

- `transaction_ext` - Tranzakció kibővített nézet
- `transaction_banknote_ext` - Tranzakció bankjegy kibővített nézet
- `banknote_inventory_ext` - Bankjegykészlet kibővített nézet
- `daily_closing_ext` - Napi zárás kibővített nézet
- `closing_detail_ext` - Zárás részlet kibővített nézet
- `currency_denomination_ext` - Devizanem címlet kibővített nézet
- `denomination_rule_ext` - Címletezési szabály kibővített nézet

### Kódszótárak

- `CURRENCY_STATUS` - Devizanem státuszok
- `ROLE` - Szerepkörök
- `CLOSING_STATUS` - Zárás státuszok
- `PRIORITY` - Prioritások
- `PERIOD` - Időszakok
- `APPROVAL_LEVEL` - Jóváhagyási szintek
- `OVERRIDE_REASON` - Felülbírálási okok
- `RATE_MODIFICATION_TYPE` - Árfolyammódosítás típusok
- `BRANCH_GROUP_TYPE` - Fiókcsoport típusok
- `TRANSACTION_TYPE` - Tranzakció típusok
- `TRANSACTION_STATUS` - Tranzakció státuszok
- `DENOMINATION_AVAILABILITY` - Címlet elérhetőség
- `OPTIMIZATION_STRATEGY` - Optimalizációs stratégia
- `DENOMINATION_RULE_TYPE` - Címletezési szabály típus
- `REPRESENTATIVE_TYPE` - Meghatalmazotti típusok
- `RELATIONSHIP_TYPE` - Kapcsolat típusok
- `AUTHORIZATION_TYPE` - Meghatalmazás típusok
- `AUTHORIZATION_STATUS` - Meghatalmazás státuszok
- `OPERATION_TYPE` - Művelet típusok
- `REPRESENTATIVE_LOG_TYPE` - Meghatalmazotti napló típusok

## Használat

A dokumentáció moduláris felépítésű, így a különböző területekre vonatkozó információk külön fájlokban találhatók. A dokumentáció a valutaváltó
rendszer fejlesztése, bevezetése és üzemeltetése során egyaránt hasznos lehet:

- Fejlesztők számára - Az implementálandó folyamatok megértéséhez
- Tesztelők számára - A tesztesetek kialakításához
- Üzemeltetők számára - A rendszer működésének megértéséhez
- Végfelhasználók számára - A rendszer használatának elsajátításához
- Auditorok számára - A folyamatok és kontrollok ellenőrzéséhez

## Kapcsolódó dokumentumok

- Entitás-definíciós fájlok (`.figdef.md` kiterjesztéssel)
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
