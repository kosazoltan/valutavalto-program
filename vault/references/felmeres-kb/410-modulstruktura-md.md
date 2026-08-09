---
title: modulstruktura.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/modulstruktura.md
doc_type: text
---

# modulstruktura.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 13.7 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/modulstruktura.md`

## Tartalom

# Valutaváltó Rendszer - Modul- és Menüstruktúra

## Bevezetés

Ez a dokumentum a valutaváltó rendszer javasolt modul- és menüstruktúráját írja le. A rendszer CRUD-alapú (Create-Read-Update-Delete) karbantartókból
épül fel, de a komplex üzleti folyamatokat és felhasználói eseteket is támogatja.

## Modulstruktúra

A rendszer az alábbi fő modulokból épül fel:

### 1. Alapadatok modul

**Cél:** A rendszer alapvető törzsadatainak kezelése, karbantartása.

**Főbb komponensek:**

- Devizanem karbantartás (`currency`)
- Devizanem címletek karbantartása (`currency_denomination`)
- Árfolyam karbantartás (`exchange_rate`)
- Fiók karbantartás (`branch`)
- Dolgozók karbantartása (`worker`)
- Pénztárosok karbantartása (`cashier`)
- Általános kódszótárak karbantartása

### 2. Pénztár modul

**Cél:** A napi pénztárműveletek kezelése, a valutaváltási tranzakciók lebonyolítása.

**Főbb komponensek:**

- Valutaváltási tranzakció kezelő (`transaction`)
- Bankjegykészlet nyilvántartás (`banknote_inventory`)
- Kasszanyitás/zárás kezelő (`daily_closing`)
- Pénztári korrekciók
- Címletezési optimalizáció (`denomination_optimization`)
- Címletezési szabályok kezelése (`denomination_rule`)
- Címletezési napló (`denomination_transaction_log`)

### 3. Ügyfélkezelési modul

**Cél:** Az ügyféladatok és ügyféltörténet kezelése.

**Főbb komponensek:**

- Ügyfél karbantartás (`customer`)
- Ügyfélkategória kezelés
- Ügyfélpreferenciák kezelés
- Ügyféltranzakció történet

### 4. Szállítmány modul

**Cél:** A valutaszállítmányok kezelése, a készletoptimalizálás támogatása.

**Főbb komponensek:**

- Szállítmányigény kezelés
- Szállítmány előkészítés
- Szállítmánykövetés
- Készletoptimalizálás
- Szállítmány címletezés

### 5. Jelentés és elemzés modul

**Cél:** Átfogó elemzések, kimutatások, jelentések készítése.

**Főbb komponensek:**

- Forgalmi jelentések
- Árfolyam-nyereség jelentések
- Pénztári zárás riportok
- Hatósági jelentések
- Teljesítmény-elemzések
- Címletezési statisztikák

### 6. Adminisztráció modul

**Cél:** A rendszer üzemeltetésével kapcsolatos adminisztratív feladatok ellátása.

**Főbb komponensek:**

- Felhasználókezelés
- Jogosultságkezelés
- Rendszerparaméterek beállítása
- Naplóelemzés
- Biztonsági mentések kezelése
- Címletezési paraméterek globális beállítása

## Menüstruktúra

### Főmenü

1. **Valutaváltás** - Pénztárkezelő felület
2. **Törzsadatok** - Alapadatok karbantartása
3. **Ügyfélkezelés** - Ügyféladatok kezelése
4. **Szállítmánykezelés** - Szállítmányok kezelése
5. **Jelentések** - Riportok, elemzések
6. **Adminisztráció** - Rendszerbeállítások

### Almenük

#### 1. Valutaváltás

- **Új valutaváltás** - Új tranzakció indítása
- **Kassza nyitása** - Napi kassza nyitás
- **Kassza zárása** - Napi kassza zárás
- **Bankjegykészlet** - Aktuális készlet megtekintése
- **Napi tranzakciók** - Az adott nap tranzakcióinak listája
- **Valutaváltás sztornó** - Tranzakció sztornózása
- **Pénztári korrekció** - Készpénzállomány korrekciója
- **Címletezési javaslat** - Intelligens címletezési javaslatok generálása
- **Címletezési napló** - Tranzakciók címletezési adatainak megtekintése

#### 2. Törzsadatok

- **Devizanemek** - Devizanemek karbantartása
    - Devizanem lista
    - Új devizanem
    - Devizanem szerkesztése
    - Devizanem státuszváltoztatás
    
- **Devizanem címletek** - Címletek karbantartása
    - Címlet lista devizanemenként
    - Új címlet
    - Címlet szerkesztése
    - Címlet elérhetőség beállítása
    - Címlet sorrendjének meghatározása

- **Árfolyamok** - Árfolyamok karbantartása
    - Központi árfolyamok
    - Fiókspecifikus árfolyamok
    - Fiókcsoport árfolyamok
    - Új árfolyam rögzítése
    - Árfolyam importálás

- **Fiókok** - Fiókadatok karbantartása
    - Fiók lista
    - Új fiók létrehozása
    - Fiók szerkesztése
    - Fiók státuszváltoztatás
    - Fiókcsoportok kezelése

- **Dolgozók** - Dolgozók adatainak karbantartása
    - Dolgozó lista
    - Új dolgozó
    - Dolgozó szerkesztése
    - Dolgozó státuszváltoztatás

- **Pénztárosok** - Pénztárosok adatainak karbantartása
    - Pénztáros lista
    - Új pénztáros
    - Pénztáros szerkesztése
    - Pénztáros fiókhoz rendelése
    - Pénztáros státuszváltoztatás

- **Kódszótárak** - Kódszótárak karbantartása
    - Szerepkörök (ROLE)
    - Devizanem státuszok (CURRENCY_STATUS)
    - Tranzakció típusok (TRANSACTION_TYPE)
    - Zárás státuszok (CLOSING_STATUS)
    - Címlet elérhetőség (DENOMINATION_AVAILABILITY)
    - Optimalizációs stratégia (OPTIMIZATION_STRATEGY)
    - Címletezési szabály típus (DENOMINATION_RULE_TYPE)
    - Meghatalmazás típusok (REPRESENTATIVE_TYPE)
    - Kapcsolat típusok (RELATIONSHIP_TYPE)
    - Meghatalmazás jogosultság (AUTHORIZATION_TYPE)
    - Meghatalmazás státusz (AUTHORIZATION_STATUS)
    - Művelet típusok (OPERATION_TYPE)
    - További kódszótárak...

#### 3. Ügyfélkezelés

- **Ügyfélkeresés** - Ügyfelek keresése különböző szempontok alapján
- **Új ügyfél** - Új ügyfél létrehozása
- **Ügyfél szerkesztése** - Meglévő ügyféladatok módosítása
- **Ügyfélkategóriák** - Ügyfélkategóriák karbantartása
- **Ügyfélpreferenciák** - Egyedi ügyfélbeállítások kezelése
- **Ügyféltranzakciók** - Ügyfélhez tartozó tranzakciótörténet
- **Ügyfélpanaszok** - Ügyfélpanaszok nyilvántartása, kezelése
- **Ügyfélkommunikáció** - Ügyfélértesítések, komunikáció kezelése

#### 4. Szállítmánykezelés

- **Szállítmányigények** - Szállítmányigények listázása, kezelése
    - Új igény létrehozása
    - Igények jóváhagyása
    - Igények módosítása
    - Igények törlése

- **Aktív szállítmányok** - Előkészítés alatt és szállítás alatt lévő tételek
    - Szállítmány előkészítése
    - Szállítmány indítása
    - Szállítmány fogadása
    - Szállítmányok nyomonkövetése
    - Szállítmány címletezés beállítása

- **Szállítmánytörténet** - Lezárt szállítmányok nyilvántartása
    - Szállítmánytörténet lekérdezése
    - Szállítmányeltérések kezelése
    - Szállítmánydokumentáció

- **Készletoptimalizálás** - Készletszint-elemzés, optimalizálás
    - Optimalizálási javaslatok
    - Szezonális készlettervezés
    - Biztonsági készletszintek beállítása
    - Címlet-specifikus optimalizálás

#### 5. Jelentések

- **Napi jelentések**
    - Napi forgalmi kimutatás
    - Napi zárás jelentés
    - Kasszaállomány kimutatás
    - Címletezési hatékonyság

- **Időszaki jelentések**
    - Heti forgalom
    - Havi forgalom
    - Negyedéves/éves forgalom
    - Árfolyamnyereség-kimutatás
    - Jutalékbevétel-kimutatás
    - Címletfelhasználási statisztikák

- **Fiók jelentések**
    - Fiók teljesítmény
    - Fiók készletek
    - Fiók tranzakciók
    - Fiók-specifikus címletstatisztikák

- **Ügyfél-jelentések**
    - Ügyfélaktivitási jelentések

- **Hatósági jelentések**
    - Nagy összegű tranzakciók jelentése
    - Gyanús tranzakciók jelentése
    - Egyéb hatósági jelentések

- **Elemzések**
    - Tranzakciós minták elemzése
    - Ügyfélviselkedés-elemzés
    - Szezonalitás-elemzés
    - Jövedelmezőség-elemzés
    - Címletezési stratégiák hatékonyságelemzése

#### 6. Adminisztráció

- **Felhasználókezelés**
    - Felhasználók listája
    - Új felhasználó létrehozása
    - Felhasználó szerkesztése
    - Felhasználó deaktiválása/aktiválása
    - Jelszókezelés

- **Jogosultságkezelés**
    - Szerepkörök karbantartása
    - Jogosultságok kiosztása
    - Jogosultság-felülvizsgálat

- **Rendszerparaméterek**
    - Általános paraméterek
    - Árfolyam-paraméterek
    - Jutalék-paraméterek
    - Készlethatárok
    - Biztonsági paraméterek
    - Címletezési paraméterek

- **Címletezés adminisztráció**
    - Címletezési stratégiák karbantartása
    - Címletezési szabályok létrehozása/módosítása
    - Optimalizációs algoritmusok beállítása
    - Címletezési tesztelő eszköz

- **Rendszernapló**
    - Napló megtekintése
    - Audit napló
    - Biztonsági események
    - Napló exportálása

- **Rendszer-karbantartás**
    - Biztonsági mentés
    - Adatbázis-karbantartás
    - Verzióinformációk
    - Rendszerteljesítmény

## CRUD komponensek

A rendszer CRUD (Create-Read-Update-Delete) műveletek köré szervezett karbantartó komponensekből épül fel, amelyek az alábbi sablon szerint működnek
minden entitás esetében:

### Lista nézet

- Szűrési és keresési lehetőségek
- Rendezési lehetőségek
- Lapozás nagy mennyiségű adat esetén
- Műveletek: új létrehozása, megtekintés, szerkesztés, törlés/inaktiválás

### Részletes nézet

- Entitás összes adatának megtekintése
- Kapcsolódó entitások adatainak megtekintése
- Változástörténet megtekintése (ha elérhető)
- Műveletek: szerkesztés, törlés/inaktiválás, egyéb entitásspecifikus műveletek

### Létrehozási/szerkesztési űrlap

- Adatbeviteli mezők az entitás minden attribútumához
- Validációs szabályok érvényesítése
- Kapcsolódó entitások kiválasztása (pl. legördülő listákból)
- Kódszótár elemek kiválasztása
- Mentés és mégse műveletek

### Törlés/inaktiválás

- Megerősítés kérése a művelet végrehajtása előtt
- Referenciális integritás ellenőrzése
- Törlés helyett inaktiválás, ha az entitásra más entitások hivatkoznak

## Folyamat-specifikus képernyők

A CRUD alapú képernyők mellett a rendszer tartalmaz speciális, munkafolyamat-orientált képernyőket is:

### Valutaváltási tranzakció képernyő

- Forrás és cél devizanemek kiválasztása
- Összeg megadása
- Automatikus árfolyam-alkalmazás és jutalékszámítás
- Bankjegycímlet-megadási lehetőség intelligens címletezési javaslatokkal
- Ügyfél kiválasztása/rögzítése
- Tranzakció véglegesítése

### Kasszanyitás/zárás képernyő

- Kezdő/záró állomány rögzítése devizanemenként és címletenként
- Automatikus egyeztetés a várt és tényleges állomány között
- Eltérések kezelése
- Zárási jegyzőkönyv készítése

### Szállítmány-előkészítés képernyő

- Devizanemek és címletek kiválasztása
- Mennyiségek megadása optimális címletezési javaslatokkal
- Csomagolási és biztonsági információk rögzítése
- Kísérőjegyzék nyomtatása

### Készletoptimalizáló képernyő

- Aktuális készletek vizualizációja
- Forgalmi adatok alapján javasolt készletszintek
- Automatikus szállítmányigény-javaslatok
- Szezonális tervezési lehetőségek
- Címlet-specifikus optimalizálás

### Címletezési szabály létrehozása képernyő

- Devizanem kiválasztása
- Szabálytípus meghatározása
- Paraméterek beállítása
- Optimalizációs stratégia kiválasztása
- Szabály tesztelése valós adatokon
- Érvénybeléptetés

## Kezelőfelületek szerepkörönként

A menüstruktúra és a hozzáférési jogosultságok különbözhetnek a felhasználó szerepkörétől függően:

### Pénztáros

- Valutaváltás menü teljes hozzáféréssel
- Ügyfélkezelés korlátozott hozzáféréssel (csak keresés, megtekintés, új létrehozása)
- Jelentések korlátozott hozzáféréssel (csak napi jelentések)

### Fiókvezető

- Valutaváltás menü teljes hozzáféréssel
- Ügyfélkezelés teljes hozzáféréssel
- Szállítmánykezelés teljes hozzáféréssel
- Jelentések bővített hozzáféréssel (fiókszintű jelentések)
- Címletezési szabályok kezelése fiókszinten
- Adminisztráció korlátozott hozzáféréssel (csak felhasználókezelés a saját fiókra vonatkozóan)

### Rendszeradminisztrátor

- Minden modulhoz teljes hozzáférés
- Adminisztráció menü kiemelt fontosságú
- Globális címletezési stratégiák és szabályok konfigurálása

### Auditor

- Minden modulhoz csak olvasási jogosultság
- Jelentések modulhoz teljes hozzáférés
- Rendszernapló és audit napló teljes hozzáféréssel
- Címletezési naplók elemzése

## Megfontolások a rendszer kialakításához

1. **Reszponzív design** - A rendszer minden funkciója használható legyen különböző eszközökön (PC, tablet)

2. **Folyamat-orientált kialakítás** - Bár a rendszer CRUD-komponensekből épül fel, a felhasználói felületet a gyakori munkafolyamatok köré kell
   szervezni

3. **Egységes megjelenés** - Következetes színvilág, ikonok, gombkiosztás minden képernyőn

4. **Gyorsbillentyűk** - Gyakran használt funkciókhoz gyorsbillentyűk definiálása

5. **Kontextusfüggő segítség** - Minden képernyőn elérhető súgó, amely az adott képernyő funkcióit magyarázza

6. **Jogosultságfüggő menük** - Csak azok a menüpontok jelenjenek meg, amelyekhez a felhasználónak jogosultsága van

7. **Dashboard** - A bejelentkezés után szerepkör-specifikus kezdőképernyő (dashboard) fogadja a felhasználót a legfontosabb információkkal:
   - Pénztárosoknak: aktuális árfolyamok, napi tranzakciók, címletezési javaslatok
   - Fiókvezetőknek: forgalmi adatok, készletinformációk
   - Adminisztrátoroknak: rendszerállapot, biztonsági események

8. **Értesítések** - A rendszeren belüli értesítési rendszer, amely a felhasználók számára fontos eseményekről tájékoztat:
   - Árfolyamváltozások
   - Címletkészlet-szintek kritikus értékei
   - Gyanús tevékenységek
