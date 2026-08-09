---
title: 07_cimletkezeles.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: cimletkezes
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/07_cimletkezeles.md
doc_type: text
---

# 07_cimletkezeles.md

**Kategoria:** cimletkezes  |  **Tipus:** text  |  **Meret:** 9.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/07_cimletkezeles.md`

## Tartalom

# Valutaváltó Rendszer - Címletezés Paraméterezési Folyamatok

## Bevezetés

Ez a dokumentum a valutaváltó rendszer címletezési paraméterezési folyamatait írja le, amelyek lehetővé teszik a rugalmas és optimalizált címletkezelést különböző üzleti helyzetekben.

## Címletezés paraméterezés adminisztrációs folyamatai

### Címletkészlet definiálása

1. A rendszeradminisztrátor minden devizanemhez definiálja az elérhető címleteket (`currency_denomination`):
   - Devizanem kiválasztása (`currency_id`)
   - Címlet értékének megadása (`denomination`)
   - Érme vagy bankjegy jelölése (`is_coin`)
   - Aktív státusz beállítása (`is_active`)
   - Rendezési sorrend beállítása (`sorting_order`) a címletek logikus megjelenítéséhez
   - Elérhetőség kategóriájának megadása (`availability_did`) a `DENOMINATION_AVAILABILITY` szótárból:
     - COMMON - Gyakori címlet
     - STANDARD - Általános címlet
     - RARE - Ritka címlet
     - OBSOLETE - Elavult címlet
     - SPECIAL - Speciális/Gyűjtői címlet

2. A címletkészlet karbantartása a devizanem-kezelés részét képezi, és a rendszeradminisztrátor felelőssége.
3. Új címlet bevezetésekor vagy régi kivonásakor a címletkészlet módosítható, ami automatikusan hatással van a címletezési optimalizációs folyamatokra.

### Címletezési optimalizációs stratégiák definiálása

1. A rendszerben különböző címletezési optimalizációs stratégiák definiálhatók (`denomination_optimization`):
   - Stratégia neve (`name`) és leírása (`description`)
   - Stratégia típusának kiválasztása (`strategy_did`) a `OPTIMIZATION_STRATEGY` szótárból:
     - GREEDY - Mohó algoritmus (legnagyobb címletekkel kezdve)
     - DYNAMIC - Dinamikus programozás (minimális darabszámra optimalizálva)
     - MIN_COINS - Minimum érme kiadása
     - MIN_BANKNOTES - Minimum bankjegy kiadása
     - MIN_TOTAL - Minimum összes darabszám
     - CUSTOM - Egyedi algoritmus
     - BRANCH_SPECIFIC - Fiókspecifikus optimalizálás

2. A stratégiákhoz további paraméterek állíthatók be:
   - Prioritási sorrend a címletekre (`priority_order`) JSON formátumban
   - Érmeminimalizálás bekapcsolása (`min_coins`)
   - Bankjegyminimalizálás bekapcsolása (`min_banknotes`)
   - Összes darabszám minimalizálása (`min_total_count`)
   - Alapértelmezett stratégia jelölése (`is_default`)

3. Az optimalizációs stratégiák konfigurálásához rendszeradminisztrátori jogosultság szükséges.
4. Az optimalizációs stratégiák tesztelése és finomhangolása a bevezetés előtt ajánlott.

### Címletezési szabályok definiálása

1. Különböző üzleti helyzetekre specifikus címletezési szabályok hozhatók létre (`denomination_rule`):
   - Szabály neve (`rule_name`) és devizanem (`currency_id`)
   - Szabály típusának kiválasztása (`rule_type_did`) a `DENOMINATION_RULE_TYPE` szótárból:
     - FIXED - Fix címletezés
     - AMOUNT_BASED - Összeg alapú
     - CUSTOMER_TYPE - Ügyfél típus alapú
     - TRANSACTION_TYPE - Tranzakció típus alapú
     - BRANCH_DEFAULT - Fiók alapértelmezett
     - TIME_BASED - Időszak alapú
     - AVAILABILITY - Készlet alapú
     - PRIORITY - Prioritás alapú

2. A szabályokhoz beállítható paraméterek:
   - Összeghatárok (`min_amount`, `max_amount`)
   - Szabály konfigurációja JSON formátumban (`rule_config`)
   - Fiókspecifikus alkalmazás (`branch_id`)
   - Használandó optimalizációs stratégia (`optimization_id`)

3. A szabályok definiálásához szükséges jogosultsági szint: SUPERVISOR vagy MANAGER.
4. A szabályok aktiválása/deaktiválása az `is_active` mező segítségével történik.

## Címletezési folyamatok alkalmazása a napi működésben

### Tranzakciós címletezés

1. Valutaváltási tranzakció során a rendszer az alábbi lépéseket követi a címletezés meghatározásához:
   - A tranzakció típusa és összege alapján meghatározza az alkalmazandó címletezési szabályt
   - A fiók-specifikus szabályokat előnyben részesíti az általános szabályokkal szemben
   - Az ügyfél típusa és a tranzakció jellege befolyásolhatja a címletezési szabály kiválasztását

2. A címletezési szabály által meghatározott optimalizációs stratégia alapján a rendszer:
   - Kiszámítja az optimális címletkombinációt
   - Figyelembe veszi a fiók aktuális készletét
   - Jelzi, ha az optimális címletezés nem lehetséges a készlethiány miatt

3. A pénztáros a javasolt címletezést:
   - Elfogadhatja és alkalmazhatja
   - Módosíthatja, ha az ügyfélnek specifikus címletigénye van
   - Felülbírálhatja különleges esetekben, megfelelő jogosultsággal

4. A rendszer rögzíti a kiválasztott címletezési szabályt (`denomination_rule_id`) a tranzakcióban és naplózza a teljes címletezési folyamatot (`denomination_transaction_log`).

### Pénztárkezelésben való alkalmazás

1. Pénztárnyitáskor a rendszer az alapértelmezett címletezési szabályt társítja a pénztár munkamenethez:
   - A pénztár alapértelmezett szabálya (`cashier_desk.denomination_rule_id`)
   - A fiók alapértelmezett szabálya, ha a pénztárnak nincs specifikus szabálya
   - A rendszer általános alapértelmezett szabálya, ha egyik sincs definiálva

2. A pénztáros a munkamenet során:
   - Használhatja az alapértelmezett címletezési szabályt
   - Ideiglenesen másik szabályt választhat specifikus tranzakciókhoz
   - Egyedi címletezést alkalmazhat a rendszer javaslatától eltérően

3. A címletezéssel kapcsolatos összes döntés naplózásra kerül.

### Készpénzátadások címletezése

1. Pénztárak közötti készpénzátadás során:
   - A rendszer optimális címletezési ajánlást készít a `cash_transfer.denomination_rule_id` alapján
   - A címletezés figyelembe veszi mindkét pénztár aktuális készletét
   - A címleteket tételesen rögzítik a `cash_transfer_detail` entitásban, hivatkozva a megfelelő `currency_denomination_id`-ra

2. Az átadás során a címletek darabszáma pontosan rögzítésre kerül és a készletek automatikusan frissülnek.

### Szállítmányok címletezése

1. Fiók közötti szállítmányoknál:
   - A szállítmányhoz társított címletezési szabály (`branch_transfer.denomination_rule_id`) meghatározza az optimális címletkombinációt
   - A szabály figyelembe veszi a küldő és fogadó fiók igényeit és készletét
   - A szállítmány tételeit a `branch_transfer_item` entitásban rögzítik, hivatkozva a `currency_denomination_id`-ra

2. Ütemezett szállítmányoknál:
   - Az ütemezett szállítás alapértelmezett címletezési szabálya (`scheduled_transfer.denomination_rule_id`) érvényesül
   - A tényleges szállítmányok létrehozásakor ez a szabály öröklődik

## Címletezési folyamatok ellenőrzése és elemzése

### Címletezési napló elemzése

1. A címletezési folyamatok naplózása a `denomination_transaction_log` entitásban történik:
   - Rögzítésre kerül a kért összeg és a tényleges kiadott összeg
   - Tárolódik az eredeti kérés és a végső címletezés
   - A manuális felülbírálások jelölésre kerülnek (`manual_override`)

2. A napló elemzésével a vezetők:
   - Értékelhetik a címletezési szabályok hatékonyságát
   - Azonosíthatják a gyakori felülbírálási mintákat
   - Optimalizálhatják a címletkészletet a valós igények alapján

### Címletezési statisztikák

1. A rendszer rendszeres statisztikákat készít a címletezésről:
   - Címletenként kiadott és bevételezett mennyiségek
   - Címletezési szabályok alkalmazási gyakorisága
   - Optimalizációs stratégiák eredményességi mutatói
   - Felülbírálások gyakorisága és okai

2. Ezek a statisztikák segítik:
   - A címletezési stratégiák finomhangolását
   - A készletgazdálkodás optimalizálását
   - A pénztárosok képzési igényeinek azonosítását
   - A különleges ügyfélpreferenciák megismerését

## Címletezési paraméterek karbantartása

### Rendszeres felülvizsgálat

1. A címletezési paramétereket rendszeresen felül kell vizsgálni:
   - Negyedévente a szabályok és stratégiák teljesítmény-értékelése
   - Félévente teljes körű hatékonyság-elemzés
   - Évente a teljes paraméterrendszer újraértékelése

2. A felülvizsgálat során különös figyelmet kell fordítani:
   - A ritkán használt vagy hatékonytalan szabályokra
   - Az ügyfelek által gyakran felülbírált címletezési ajánlásokra
   - A fiók-specifikus igények változásaira

### Változások bevezetése

1. A címletezési paraméterek módosítása kontrollált folyamat:
   - A változtatásokat először teszt környezetben kell ellenőrizni
   - A módosítások előtt szimulációkat kell végezni valós tranzakciós adatokon
   - A változtatásokat fokozatosan kell bevezetni (például először csak egy fiókban)

2. A paraméterek módosítása után:
   - A pénztárosokat tájékoztatni kell a változásokról
   - A változtatások hatását szorosan nyomon kell követni
   - Az esetleges problémákat azonnal kezelni kell

### Extrém helyzetek kezelése

1. Rendkívüli helyzetekre specifikus címletezési szabályok definiálhatók:
   - Pénzhiány vagy többlet esetére
   - Új címletek bevezetésekor
   - Régi címletek kivonásakor
   - Szezonális csúcsterhelés idejére

2. A rendkívüli szabályokat:
   - Előre el kell készíteni
   - Tesztelni kell
   - Szükség esetén azonnal aktiválni lehet
   - A helyzet normalizálódása után deaktiválni kell
