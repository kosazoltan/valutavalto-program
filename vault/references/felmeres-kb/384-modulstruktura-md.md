---
title: modulstruktura.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/load2fit_folyamatok/modulstruktura.md
doc_type: text
---

# modulstruktura.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 21.3 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/load2fit_folyamatok/modulstruktura.md`

## Tartalom

# Load2fit Rendszer - Modul- és Menüstruktúra

## Bevezetés

Ez a dokumentum a Load2fit szállítmányozási bróker rendszer javasolt modul- és menüstruktúráját írja le. A rendszer két különálló alkalmazásból áll:

1. **Központi Adminisztrációs Alkalmazás**: A rendszer felügyeletét, adminisztrációját és a háttérfolyamatok kezelését biztosítja.
2. **Megbízói és Fuvarozói Alkalmazás**: A megbízók és fuvarozók számára biztosít felületet a megbízások és ajánlatok kezelésére.

Mindkét alkalmazás CRUD-alapú (Create-Read-Update-Delete) karbantartókból épül fel, de a komplex üzleti folyamatokat és felhasználói eseteket is támogatja.

## Modulstruktúra

A rendszer két alkalmazása az alábbi fő modulokból épül fel:

## A. Központi Adminisztrációs Alkalmazás moduljai

### 1. Felhasználókezelési és ellenőrzési modul

**Cél:** A rendszer felhasználóinak (Fuvarozók és Megbízók) adminisztrációja, ellenőrzése és jóváhagyása.

**Főbb komponensek:**

- Felhasználó ellenőrzés és jóváhagyás (`user_verification`)
- Felhasználói tevékenység napló (`user_activity_log`)
- Felhasználói értékelések moderálása (`user_rating_moderation`)
- Felhasználói adatok auditálása (`user_data_audit`)

### 2. Jutalék és fizetés adminisztrációs modul

**Cél:** A jutalékok kezelése, számlázás, fizetések nyilvántartása és ellenőrzése.

**Főbb komponensek:**

- Jutalék díjszabás karbantartás (`commission_rate`)
- Jutalék kalkuláció ellenőrzés (`commission_calculation_verification`)
- Számla kiállítás és kezelés (`invoice_management`)
- Fizetés nyilvántartás és ellenőrzés (`payment_tracking`)
- Fizetési emlékeztető kezelés (`payment_reminder`)
- Pénzügyi statisztikák (`financial_statistics`)

### 3. Reklamáció kezelési modul

**Cél:** A felhasználói reklamációk adminisztrációja, feldolgozása és nyomon követése.

**Főbb komponensek:**

- Reklamáció feldolgozás (`complaint_processing`)
- Reklamáció eszkaláció (`complaint_escalation`)
- Reklamáció státuszkövetés (`complaint_status_tracking`)
- Reklamáció statisztikák (`complaint_statistics`)
- Minőségbiztosítás (`quality_assurance`)

### 4. Jelentés és elemzés modul

**Cél:** Átfogó elemzések, kimutatások, jelentések készítése a rendszer működéséről.

**Főbb komponensek:**

- Forgalmi jelentések (`traffic_reports`)
- Bevétel jelentések (`revenue_reports`)
- Felhasználói aktivitás jelentések (`user_activity_reports`)
- Teljesítmény-elemzések (`performance_analysis`)
- Piaci trendek elemzése (`market_trend_analysis`)
- Értékelési statisztikák (`rating_statistics`)

### 5. Rendszeradminisztráció modul

**Cél:** A rendszer üzemeltetésével kapcsolatos adminisztratív feladatok ellátása.

**Főbb komponensek:**

- Rendszerfelhasználó kezelés (`system_user`)
- Jogosultságkezelés (`permission`)
- Rendszerparaméterek beállítása (`system_parameter`)
- Naplóelemzés (`log_analysis`)
- Biztonsági mentések kezelése (`backup_management`)
- Hírlevél kezelés (`newsletter`)
- Rendszermonitorozás (`system_monitoring`)

## B. Megbízói és Fuvarozói Alkalmazás moduljai

### 1. Felhasználói profil modul

**Cél:** A felhasználók (Fuvarozók és Megbízók) saját adatainak kezelése és profilbeállítások.

**Főbb komponensek:**

- Fuvarozó profil kezelés (`carrier_profile`)
- Megbízó profil kezelés (`client_profile`)
- Felhasználói értékelések (`user_rating`)
- Felhasználói preferenciák (`user_preferences`)
- Értesítési beállítások (`notification_settings`)

### 2. Megbízás modul

**Cél:** A szállítási megbízások kezelése, publikálása, keresése.

**Főbb komponensek:**

- Megbízás karbantartás (`assignment`)
- Megbízás publikálás (`assignment_publication`)
- Megbízás keresés (`assignment_search`)
- Megbízás sablon kezelés (`assignment_template`)
- Megbízás státuszkövetés (`assignment_status_tracking`)
- Kooperatív megbízás kezelés (`cooperative_assignment`)

### 3. Ajánlat modul

**Cél:** A megbízásokra adott ajánlatok kezelése, elbírálása, elfogadása.

**Főbb komponensek:**

- Ajánlat karbantartás (`offer`)
- Ajánlat elbírálás (`offer_evaluation`)
- Ajánlat elfogadás (`offer_acceptance`)
- Ajánlat visszaigazolás (`offer_confirmation`)
- Ajánlat módosítás kérés (`offer_modification_request`)
- Ajánlat státuszkövetés (`offer_status_tracking`)

### 4. Fizetés és jutalék felhasználói modul

**Cél:** A felhasználók számára releváns fizetési és jutalék információk kezelése.

**Főbb komponensek:**

- Jutalék áttekintés (`commission_overview`)
- Fizetési információk (`payment_information`)
- Számla megtekintés (`invoice_view`)
- Fizetési műveletek (`payment_operations`)

### 5. Felhasználói reklamáció modul

**Cél:** A felhasználók által kezdeményezett reklamációk kezelése.

**Főbb komponensek:**

- Reklamáció benyújtás (`complaint_submission`)
- Reklamáció nyomon követés (`complaint_tracking`)
- Reklamáció válaszok megtekintése (`complaint_response_view`)
- Reklamáció lezárás (`complaint_closure`)

## Menüstruktúra

A rendszer két különálló alkalmazásának menüstruktúrája az alábbiakban kerül bemutatásra:

## A. Központi Adminisztrációs Alkalmazás menüstruktúrája

### Főmenü

1. **Felhasználók adminisztrációja** - Felhasználók kezelése és ellenőrzése
2. **Jutalékok és fizetések** - Pénzügyi műveletek adminisztrációja
3. **Reklamációk kezelése** - Reklamációk feldolgozása
4. **Jelentések és elemzések** - Riportok, elemzések
5. **Rendszeradminisztráció** - Rendszerbeállítások és karbantartás

### Almenük

#### 1. Felhasználók adminisztrációja

- **Fuvarozók adminisztrációja**
    - Fuvarozó lista
    - Fuvarozó részletes adatok
    - Fuvarozó jóváhagyás
    - Fuvarozó státuszváltoztatás
    - Fuvarozó értékelések moderálása
    - Fuvarozó tevékenység napló

- **Megbízók adminisztrációja**
    - Megbízó lista
    - Megbízó részletes adatok
    - Megbízó jóváhagyás
    - Megbízó státuszváltoztatás
    - Megbízó értékelések moderálása
    - Megbízó tevékenység napló

- **Felhasználó ellenőrzés**
    - Függőben lévő ellenőrzések
    - Ellenőrzési napló
    - API kapcsolatok állapota
    - Manuális ellenőrzés
    - Felhasználói adatok auditálása

- **Értékelések moderálása**
    - Értékelés lista
    - Értékelés moderálás
    - Értékelési statisztikák
    - Problémás értékelések kezelése

#### 2. Jutalékok és fizetések

- **Jutalék adminisztráció**
    - Jutalék lista
    - Jutalék részletek
    - Jutalék számítás ellenőrzés
    - Jutalék korrekció

- **Jutalék díjszabás**
    - Díjszabás lista
    - Új díjszabás
    - Díjszabás szerkesztése
    - Díjszabás érvényesítése
    - Díjszabás-történet

- **Számlázás**
    - Számla lista
    - Számla részletek
    - Számla generálás
    - Számla küldés
    - Számla sztornózás

- **Fizetések adminisztrációja**
    - Fizetés lista
    - Fizetés ellenőrzése
    - Fizetési emlékeztetők kezelése
    - Fizetési statisztikák
    - Késedelmes fizetések kezelése

#### 3. Reklamációk kezelése

- **Reklamáció adminisztráció**
    - Reklamáció lista
    - Reklamáció részletek
    - Reklamáció státuszkövetés
    - Reklamáció lezárása

- **Reklamáció feldolgozás**
    - Feldolgozandó reklamációk
    - Reklamáció hozzárendelése
    - Reklamáció megválaszolása
    - Reklamáció eszkalálása
    - Minőségbiztosítás

- **Reklamáció statisztikák**
    - Reklamáció típusok
    - Megoldási idők
    - Elégedettségi mutatók
    - Reklamációs trendek

#### 4. Jelentések és elemzések

- **Forgalmi jelentések**
    - Napi forgalom
    - Heti forgalom
    - Havi forgalom
    - Éves forgalom
    - Egyedi időszak elemzése

- **Bevétel jelentések**
    - Jutalékbevételek
    - Bevétel előrejelzés
    - Bevétel elemzés
    - Pénzügyi teljesítmény mutatók

- **Felhasználói jelentések**
    - Felhasználói aktivitás
    - Új regisztrációk
    - Felhasználói elégedettség
    - Értékelési trendek
    - Felhasználói viselkedés elemzése

- **Teljesítmény jelentések**
    - Rendszerteljesítmény
    - Válaszidők
    - Hibaarányok
    - Terhelési statisztikák

- **Piaci elemzések**
    - Piaci trendek
    - Árazási trendek
    - Szezonális minták
    - Versenytárs elemzés
    - Piaci előrejelzések

#### 5. Rendszeradminisztráció

- **Rendszerfelhasználó kezelés**
    - Felhasználók listája
    - Új felhasználó létrehozása
    - Felhasználó szerkesztése
    - Felhasználó deaktiválása/aktiválása
    - Jelszókezelés

- **Jogosultságkezelés**
    - Szerepkörök karbantartása
    - Jogosultságok kiosztása
    - Jogosultság-felülvizsgálat
    - Jogosultság audit

- **Rendszerparaméterek**
    - Általános paraméterek
    - Jutalék-paraméterek
    - Értesítési paraméterek
    - Biztonsági paraméterek
    - Integrációs paraméterek

- **Hírlevél kezelés**
    - Hírlevél lista
    - Új hírlevél
    - Hírlevél szerkesztése
    - Hírlevél küldése
    - Hírlevél statisztikák

- **Rendszernapló**
    - Napló megtekintése
    - Audit napló
    - Biztonsági események
    - Napló exportálása
    - Napló elemzés

- **Rendszer-karbantartás**
    - Biztonsági mentés
    - Adatbázis-karbantartás
    - Verzióinformációk
    - Rendszerteljesítmény
    - Rendszermonitorozás

## B. Megbízói és Fuvarozói Alkalmazás menüstruktúrája

### Főmenü

1. **Profil** - Felhasználói profil kezelése
2. **Megbízások** - Megbízások kezelése
3. **Ajánlatok** - Ajánlatok kezelése
4. **Pénzügyek** - Jutalékok és fizetések kezelése
5. **Reklamációk** - Felhasználói reklamációk kezelése

### Almenük

#### 1. Profil

- **Saját adatok** - Profil adatok kezelése
    - Profil megtekintése
    - Profil szerkesztése
    - Jelszó módosítása
    - Értesítési beállítások

- **Értékelések** - Felhasználói értékelések
    - Kapott értékelések
    - Adott értékelések
    - Új értékelés írása
    - Értékelési statisztikák

- **Preferenciák** - Felhasználói beállítások
    - Megbízás preferenciák
    - Ajánlat preferenciák
    - Értesítési preferenciák
    - Megjelenítési beállítások

#### 2. Megbízások

- **Megbízás kezelés** - Megbízások karbantartása
    - Megbízás lista
    - Új megbízás
    - Megbízás szerkesztése
    - Megbízás publikálása
    - Megbízás visszavonása
    - Megbízás lezárása

- **Megbízás keresés** - Megbízások keresése
    - Egyszerű keresés
    - Részletes keresés
    - Keresési sablonok
    - Keresési előzmények
    - Mentett keresések

- **Kooperatív megbízások** - Több fuvarozós megbízások
    - Kooperatív megbízás lista
    - Kooperatív megbízás létrehozása
    - Kooperatív megbízás részletei
    - Résztvevők kezelése

- **Megbízás sablonok** - Gyakran használt sablonok
    - Sablon lista
    - Új sablon
    - Sablon szerkesztése
    - Sablon törlése
    - Sablon használata

#### 3. Ajánlatok

- **Ajánlat kezelés** - Ajánlatok karbantartása
    - Ajánlat lista
    - Új ajánlat
    - Ajánlat szerkesztése
    - Ajánlat visszavonása
    - Ajánlat másolása

- **Ajánlat elbírálás** - Beérkezett ajánlatok elbírálása
    - Elbírálandó ajánlatok
    - Ajánlat elfogadása
    - Ajánlat elutasítása
    - Módosítási kérés küldése
    - Ajánlatok összehasonlítása

- **Ajánlat visszaigazolás** - Elfogadott ajánlatok visszaigazolása
    - Visszaigazolásra váró ajánlatok
    - Visszaigazolás
    - Visszaigazolás elutasítása
    - Feltételek egyeztetése

- **Ajánlat statisztikák** - Ajánlatokkal kapcsolatos statisztikák
    - Elfogadási arány
    - Átlagos ajánlati ár
    - Ajánlati trendek
    - Személyes teljesítmény

#### 4. Pénzügyek

- **Jutalék áttekintés**
    - Aktuális jutalékok
    - Jutalék előzmények
    - Jutalék részletek
    - Jutalék kalkulátor

- **Fizetések**
    - Fizetendő tételek
    - Fizetési előzmények
    - Fizetési mód beállítása
    - Fizetési értesítések

- **Számlák**
    - Számla lista
    - Számla részletek
    - Számla letöltése
    - Számla fizetése

#### 5. Reklamációk

- **Reklamáció kezelés**
    - Reklamáció lista
    - Új reklamáció
    - Reklamáció részletek
    - Reklamáció lezárása

- **Reklamáció nyomon követés**
    - Folyamatban lévő reklamációk
    - Reklamáció válaszok
    - Reklamáció státuszok
    - Reklamáció eszkalálás

## CRUD komponensek

A rendszer CRUD (Create-Read-Update-Delete) műveletek köré szervezett karbantartó komponensekből épül fel, amelyek az alábbi sablon szerint működnek minden entitás esetében:

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

### Megbízás létrehozási képernyő

- Megbízás alapadatainak megadása
- Szállítási adatok részletes megadása
- Rakomány adatok megadása
- Árajánlati elvárások beállítása
- Megbízás érvényességi idejének beállítása
- Előnézet és publikálás

### Ajánlattételi képernyő

- Megbízás részleteinek megtekintése
- Ajánlati ár megadása
- Szállítási feltételek megadása
- Érvényességi idő beállítása
- Ajánlat beküldése

### Ajánlat elbírálási képernyő

- Beérkezett ajánlatok összehasonlítása
- Ajánlattevők értékeléseinek megtekintése
- Ajánlat elfogadása/elutasítása/módosítási kérés
- Döntés indoklása

### Jutalék fizetési képernyő

- Fizetendő jutalék részleteinek megtekintése
- Fizetési mód kiválasztása
- Fizetés végrehajtása
- Fizetési bizonylat letöltése

### Értékelési képernyő

- Értékelési szempontok kitöltése
- Szöveges értékelés megadása
- Értékelés beküldése
- Korábbi értékelések megtekintése

### Reklamáció kezelési képernyő

- Reklamáció részleteinek megtekintése
- Válasz megfogalmazása
- Megoldási javaslat rögzítése
- Reklamáció lezárása/eszkalálása

## Kezelőfelületek szerepkörönként

A rendszer két különálló alkalmazásának hozzáférési jogosultságai különböznek a felhasználó szerepkörétől függően:

## A. Központi Adminisztrációs Alkalmazás szerepkörei

### Rendszeradminisztrátor

- Minden modulhoz teljes hozzáférés
- Rendszeradminisztráció menü kiemelt fontosságú
- Felhasználó ellenőrzés és jóváhagyás
- Rendszerparaméterek beállítása
- Hírlevél kezelés
- Rendszermonitorozás és karbantartás

### Ügyfélszolgálati munkatárs

- Felhasználók adminisztrációja menü olvasási jogosultsággal
- Reklamációk kezelése menü teljes hozzáféréssel
- Jelentések és elemzések menü korlátozott hozzáféréssel (csak ügyfélszolgálati jelentések)
- Felhasználói értékelések moderálása

### Pénzügyi munkatárs

- Jutalékok és fizetések menü teljes hozzáféréssel
- Jelentések és elemzések menü korlátozott hozzáféréssel (csak pénzügyi jelentések)
- Felhasználók adminisztrációja menü olvasási jogosultsággal

### Felhasználó ellenőr

- Felhasználók adminisztrációja menü teljes hozzáféréssel
- Felhasználó ellenőrzés és jóváhagyás
- Felhasználói adatok auditálása
- Jelentések és elemzések menü korlátozott hozzáféréssel (csak felhasználói jelentések)

### Minőségbiztosítási munkatárs

- Reklamációk kezelése menü teljes hozzáféréssel
- Felhasználói értékelések moderálása
- Jelentések és elemzések menü korlátozott hozzáféréssel (minőségbiztosítási jelentések)

## B. Megbízói és Fuvarozói Alkalmazás szerepkörei

### Megbízó

- Profil menü teljes hozzáféréssel (saját adatok)
- Megbízások menü teljes hozzáféréssel
- Ajánlatok menü korlátozott hozzáféréssel (csak a saját megbízásokra érkezett ajánlatok)
- Pénzügyek menü korlátozott hozzáféréssel (csak saját pénzügyi adatok)
- Reklamációk menü korlátozott hozzáféréssel (csak saját reklamációk)

### Fuvarozó

- Profil menü teljes hozzáféréssel (saját adatok)
- Megbízások menü korlátozott hozzáféréssel (csak keresés, megtekintés)
- Ajánlatok menü teljes hozzáféréssel
- Pénzügyek menü korlátozott hozzáféréssel (csak saját pénzügyi adatok)
- Reklamációk menü korlátozott hozzáféréssel (csak saját reklamációk)

## Megfontolások a rendszer kialakításához

### Általános megfontolások

1. **Reszponzív design** - Mindkét alkalmazás minden funkciója használható legyen különböző eszközökön (PC, tablet, mobil)

2. **Folyamat-orientált kialakítás** - Bár mindkét alkalmazás CRUD-komponensekből épül fel, a felhasználói felületet a gyakori munkafolyamatok köré kell szervezni

3. **Egységes megjelenés** - Következetes színvilág, ikonok, gombkiosztás mindkét alkalmazás minden képernyőjén, de vizuálisan megkülönböztethető design a két alkalmazás között

4. **Gyorsbillentyűk** - Gyakran használt funkciókhoz gyorsbillentyűk definiálása mindkét alkalmazásban

5. **Kontextusfüggő segítség** - Minden képernyőn elérhető súgó, amely az adott képernyő funkcióit magyarázza

6. **Jogosultságfüggő menük** - Csak azok a menüpontok jelenjenek meg, amelyekhez a felhasználónak jogosultsága van

### Két alkalmazás specifikus megfontolások

7. **Adatszinkronizáció** - A két alkalmazás közötti adatszinkronizáció biztosítása, különös tekintettel a valós idejű adatokra (pl. megbízások, ajánlatok státusza)

8. **Egységes bejelentkezés** - Single Sign-On (SSO) megoldás biztosítása, hogy a felhasználóknak ne kelljen külön bejelentkezniük a két alkalmazásba

9. **Konzisztens üzleti logika** - Az üzleti szabályok konzisztens érvényesítése mindkét alkalmazásban

10. **Moduláris fejlesztés** - A két alkalmazás közös komponenseinek moduláris fejlesztése, újrafelhasználható komponensek kialakítása

11. **API-alapú kommunikáció** - Jól definiált API-k kialakítása a két alkalmazás közötti kommunikációhoz

### Dashboard kialakítás

12. **Dashboard** - A bejelentkezés után szerepkör-specifikus kezdőképernyő (dashboard) fogadja a felhasználót a legfontosabb információkkal:

   **Megbízói és Fuvarozói Alkalmazásban:**
   - Megbízóknak: aktív megbízások, beérkezett ajánlatok, értékelések
   - Fuvarozóknak: elérhető megbízások, elfogadott ajánlatok, fizetendő jutalékok

   **Központi Adminisztrációs Alkalmazásban:**
   - Adminisztrátoroknak: rendszerállapot, függőben lévő jóváhagyások, biztonsági események
   - Ügyfélszolgálati munkatársaknak: új reklamációk, feldolgozandó ügyek
   - Pénzügyi munkatársaknak: pénzügyi összesítők, függő fizetések
   - Felhasználó ellenőröknek: ellenőrizendő felhasználók, függőben lévő jóváhagyások

### Értesítési rendszer

13. **Értesítések** - Alkalmazás-specifikus értesítési rendszer, amely a felhasználók számára fontos eseményekről tájékoztat:

   **Megbízói és Fuvarozói Alkalmazásban:**
   - Új ajánlatok
   - Elfogadott ajánlatok
   - Fizetési emlékeztetők
   - Új értékelések
   - Megbízás státuszváltozások

   **Központi Adminisztrációs Alkalmazásban:**
   - Új felhasználói regisztrációk
   - Rendszeresemények
   - Kritikus hibák
   - Feldolgozandó reklamációk
   - Biztonsági figyelmeztetések
