---
title: 03_tranzakciok.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/03_tranzakciok.md
doc_type: text
---

# 03_tranzakciok.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 6.6 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/03_tranzakciok.md`

## Tartalom

# Valutaváltó Rendszer Tranzakciós Folyamatai

## Bevezetés

Ez a dokumentum a valutaváltó rendszer tranzakciós folyamatait írja le részletesen, beleértve a különböző tranzakciótípusok kezelését, a
jutalékszámítást és a tranzakciók ellenőrzését.

## Valutaváltási tranzakciók típusai

A rendszer a következő tranzakciótípusokat támogatja a `TRANSACTION_TYPE` szótár alapján (a teljes szótár a rendszerben található, itt csak a főbb
típusokat szerepeltetjük):

1. **Valutaváltás** - Standard valutaváltási művelet
2. **Visszaváltás** - Korábbi váltásból származó valuta visszaváltása
3. **Nagytételű váltás** - Speciális kezelést igénylő, nagy összegű tranzakció
4. **Készpénzbefizetés** - Pénztár feltöltése
5. **Készpénzkifizetés** - Pénzkészlet csökkentése (pl. szállítmány előkészítés)

## Általános tranzakciós folyamat

### Tranzakció indítása

1. A pénztáros az ügyfél kérésére új tranzakciót (`transaction`) indít.
2. A rendszer automatikusan generál egy egyedi tranzakció számot (`transaction_number`).
3. A pénztáros kiválasztja a tranzakció típusát (`transaction_type_did`).
4. Megadja a forrás devizanemet (`source_currency_id`) és összeget (`source_amount`).
5. Kiválasztja a cél devizanemet (`target_currency_id`).

### Árfolyam meghatározása

1. A rendszer meghatározza az alkalmazandó árfolyamot a következő prioritás szerint:
    - Fiókspecifikus árfolyam (`branch_exchange_rate_id`)
    - Fiókcsoport árfolyam (`branch_group_exchange_rate_id`)
    - Központi árfolyam (`exchange_rate_id`)

2. Az árfolyam típusa a tranzakció irányától függ:
    - Vétel esetén a vételi árfolyam (`buy_rate`)
    - Eladás esetén az eladási árfolyam (`sell_rate`)
    - Speciális esetekben a középárfolyam (`mid_rate`)

3. A rendszer kiszámítja és megjeleníti a cél összeget (`target_amount`).

### Jutalék számítása

1. A rendszer a beállított jutalékszabályok alapján kiszámítja a tranzakciós jutalékot (`fee_amount`).
2. A jutalék függhet:
    - A tranzakció típusától
    - Az összeg nagyságától
    - Az ügyfél típusától (törzsügyfél kedvezményt kaphat)
    - A devizanemtől
    - A fiók egyedi beállításaitól

3. A jutalék devizaneme (`fee_currency_id`) külön beállítható, általában:
    - A forrás devizanem
    - A cél devizanem
    - A fiók alap devizaneme

### Bankjegy részletek kezelése

1. A pénztáros rögzíti a tranzakcióhoz tartozó bankjegy részleteket (`transaction_banknote`):
    - A bevételezett bankjegyek esetén (`is_input` = true)
    - A kiadott bankjegyek esetén (`is_input` = false)

2. Minden bankjegyre megadja:
    - Devizanem (`currency_id`)
    - Címlet (`denomination`)
    - Mennyiség (`quantity`)
    - Érme-e (`is_coin`)

3. A rendszer ellenőrzi, hogy a megadott bankjegyek összege megegyezik-e a tranzakció összegével.

### Ügyfél-azonosítás

1. A rendszer ellenőrzi, hogy a tranzakció összege meghaladja-e az ügyfél-azonosítási limitet.
2. Limit feletti összeg esetén kötelező az ügyfél azonosítása és adatainak rögzítése.
3. A pénztáros rögzíti vagy kiválasztja az ügyfél adatait (`customer_id`).
4. Nagy összegű vagy gyanús tranzakció esetén fokozott ügyfél-átvilágítás szükséges.

### Tranzakció véglegesítése

1. A pénztáros ellenőrzi a tranzakció részleteit.
2. Az ügyfél elfogadja az árfolyamot és a jutalékot.
3. A pénztáros véglegesíti a tranzakciót, a státusz (`status_did`) "COMPLETED"-re változik.
4. A rendszer:
    - Frissíti a bankjegykészletet (`banknote_inventory`)
    - Naplózza a tranzakciót
    - Nyomtatja a bizonylatot

## Speciális tranzakciós folyamatok

### Nagytételű váltás

1. Egy előre meghatározott limit feletti tranzakciók nagytételű váltásnak minősülnek.
2. A nagytételű váltás további jóváhagyást igényel egy supervisortól vagy managertől.
3. A jóváhagyási folyamat során ellenőrzik:
    - A bankjegykészlet elegendőségét
    - Az ügyfél-azonosítás megfelelőségét
    - A pénzmosás-gyanús jeleket
4. A jóváhagyást követően a tranzakció a normál folyamat szerint folytatódik.

### Kedvezményes árfolyam alkalmazása

1. Bizonyos ügyfelek (törzsügyfelek, VIP ügyfelek) jogosultak lehetnek kedvezményes árfolyamra.
2. A pénztáros kiválaszthatja a kedvezmény okát (`OVERRIDE_REASON`):
    - SPECIAL_CUSTOMER - Kiemelt ügyfél
    - BUSINESS_NEED - Üzleti érdek
    - MANAGEMENT_APPROVAL - Vezetői jóváhagyás

3. A kedvezményes árfolyam alkalmazása jóváhagyási szintet (`APPROVAL_LEVEL`) igényel:
    - CASHIER - Kisebb kedvezmények esetén
    - SUPERVISOR - Közepes kedvezmények esetén
    - MANAGER - Jelentősebb kedvezmények esetén
    - DIRECTOR - Különleges esetekben

4. A jóváhagyást követően a kedvezményes árfolyam alkalmazható a tranzakcióra.

### Tranzakció sztornózása

1. Hibás tranzakció esetén a pénztáros sztornózhatja a tranzakciót.
2. Sztornózás csak az alábbi feltételek mellett lehetséges:
    - A tranzakció még nem része a napi zárásnak
    - A sztornózást megfelelő jogosultsággal rendelkező személy végzi
    - A sztornózás okát kötelezően rögzítik

3. A sztornózás új tranzakciót hoz létre ellentétes előjellel, ami a korábbi tranzakcióra hivatkozik.
4. A rendszer frissíti a bankjegykészletet és naplózza a sztornó műveletet.

## Tranzakciók ellenőrzése és jelentéskészítés

### Napi ellenőrzés

1. A napi zárás során a rendszer ellenőrzi az összes tranzakciót.
2. Az ellenőrzés kiterjed:
    - A tranzakciók összegének egyezőségére
    - A bankjegykészlet változásainak helyességére
    - A jutalékok megfelelő számítására

3. Eltérés esetén a záró riport hibát jelez, és manuális ellenőrzés szükséges.

### Időszaki jelentések

1. A rendszer különböző időszakokra (napi, heti, havi - `PERIOD`) készít tranzakciós jelentéseket.
2. A jelentések tartalmazhatnak:
    - Forgalmi adatokat devizanemenként
    - Jutalékbevétel kimutatást
    - Árfolyamnyereség-elemzést
    - Pénztáros teljesítmény-statisztikákat

3. A jelentéseket a megfelelő jogosultsággal rendelkező vezetők tekinthetik meg.

### Hatósági jelentéskészítés

1. A rendszer támogatja a hatósági jelentések automatikus generálását.
2. A jelentések kitérnek:
    - Nagy összegű tranzakciókra
    - Gyanús tranzakciós mintázatokra
    - Limit feletti ügyféltranzakciókra

3. A hatósági jelentéseket a megfelelő jogosultsággal rendelkező compliance munkatársak kezelik és továbbítják.
