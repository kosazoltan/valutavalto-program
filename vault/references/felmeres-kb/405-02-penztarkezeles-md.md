---
title: 02_penztarkezeles.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/02_penztarkezeles.md
doc_type: text
---

# 02_penztarkezeles.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 5.7 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/02_penztarkezeles.md`

## Tartalom

# Valutaváltó Rendszer Pénztárkezelési Folyamatai

## Bevezetés

Ez a dokumentum a valutaváltó rendszer pénztárkezelési folyamatait írja le, beleértve a bankjegykészlet nyilvántartását, a kasszanyitást és -zárást,
valamint az egyéb pénztárműveleteket.

## Bankjegykészlet nyilvántartása

### Bankjegykészlet rögzítése

1. A pénztáros vagy pénztárvezető rögzíti a fiók bankjegykészletét (`banknote_inventory`).
2. Minden devizanem minden címletére megadja:
    - Devizanem (`currency_id`)
    - Címlet (`denomination`)
    - Mennyiség (`quantity`)
    - Fiók azonosító (`branch_id`)
    - Érme-e (`is_coin`) - jelölés, hogy érméről vagy bankjegyről van szó
3. A rendszer automatikusan frissíti az utolsó frissítés dátumát (`last_updated`).
4. A bankjegykészlet állománya real-time nyomon követhető a kibővített nézeten (`banknote_inventory_ext`) keresztül.

### Készletmozgások követése

1. A rendszer a tranzakciók alapján automatikusan vezeti a bankjegykészlet változásait.
2. Minden valutaváltási tranzakció után a rendszer:
    - Csökkenti a forrásdeviza készletét a kiadott címletek alapján
    - Növeli a céldeviza készletét a bevételezett címletek alapján
3. A készletváltozásokat a `transaction_banknote` entitáson keresztül követi a rendszer.

## Napi pénztárműveletek

### Kasszanyitás

1. A pénztáros a munkanap kezdetén megnyitja a pénztárat.
2. A rendszer rögzíti a nyitás időpontját és a nyitó pénztáros azonosítóját.
3. A pénztáros ellenőrzi és megerősíti a nyitó készpénzállományt, amely az előző napi záróállománnyal egyezik.
4. Eltérés esetén a pénztáros jegyzőkönyvet vesz fel, és azonnali felülvizsgálatot kezdeményez.
5. A nyitás után a pénztár tranzakciókésszé válik.

### Valutaváltási tranzakció

1. A pénztáros rögzíti a valutaváltási tranzakciót (`transaction`):
    - Tranzakció száma (`transaction_number`) - rendszer által generált
    - Fiók (`branch_id`)
    - Tranzakció dátuma (`transaction_date`)
    - Tranzakció típusa (`transaction_type_did`) - a valutaváltó-szótárból
    - Forrás devizanem (`source_currency_id`)
    - Cél devizanem (`target_currency_id`)
    - Forrás összeg (`source_amount`)
    - Cél összeg (`target_amount`) - rendszer által kalkulált
    - Árfolyam (`exchange_rate`) - rendszer által megállapított a megfelelő forrásból
    - Jutalék összege (`fee_amount`) és devizaneme (`fee_currency_id`)
    - Ügyfél (`customer_id`) - nagyobb összeg esetén kötelező
    - Pénztáros (`cashier_id`) - automatikusan a bejelentkezett felhasználó
    - Státusz (`status_did`) - kezdetben "PROCESSING"

2. A rendszer ellenőrzi az adatok helyességét:
    - Árfolyam érvényességét
    - Pénztár elegendő készletét
    - Ügyfél-azonosítás szükségességét (limitek alapján)
    - Tranzakció szabályosságát

3. A pénztáros rögzíti a bankjegy-részleteket (`transaction_banknote`):
    - Tranzakció azonosító (`transaction_id`)
    - Devizanem (`currency_id`)
    - Címlet (`denomination`)
    - Mennyiség (`quantity`)
    - Bevétel/kiadás jelölése (`is_input`)
    - Érme jelölése (`is_coin`)

4. A tranzakció végrehajtása után a státusza "COMPLETED"-re változik.
5. A rendszer automatikusan frissíti a bankjegykészletet.

### Kasszazárás

1. A pénztáros a munkanap végén kezdeményezi a napi zárást (`daily_closing`).
2. A rendszer összesíti a napi forgalmat:
    - Összes tranzakció száma (`total_transactions`)
    - Összes vételi volumen (`total_buy_volume`)
    - Összes eladási volumen (`total_sell_volume`)
    - Összes jutalék (`total_fees`)

3. A pénztáros rögzíti a záró készpénzállományt devizanemenként és címletenként (`closing_detail`):
    - Várható mennyiség (`expected_quantity`) - rendszer által számolt
    - Tényleges mennyiség (`actual_quantity`) - pénztáros által számolt

4. A rendszer összehasonlítja a várható és tényleges értékeket:
    - Egyezés esetén a zárás státusza "CLOSED" lesz
    - Eltérés esetén a státusz "ERROR", és felelős vezető jóváhagyása szükséges

5. A zárás adatai:
    - Fiók (`branch_id`)
    - Zárás dátuma (`closing_date`)
    - Zárást végző pénztáros (`cashier_id`)
    - Nyitó készpénzállomány (`opening_cash`)
    - Záró készpénzállomány (`closing_cash`)
    - Státusz (`status_did`)
    - Megjegyzések (`notes`) - különösen eltérések esetén
    - Zárás időpontja (`closing_time`)

6. A vezető ellenőrzi a zárást, és jóváhagyás esetén a státusz "VERIFIED"-re változik.

## Rendkívüli pénztárműveletek

### Készpénzkorrekció

1. Supervisor vagy manager jogosultsággal rendelkező felhasználó kezdeményezhet készpénzkészlet-korrekciót.
2. A korrekció oka (`OVERRIDE_REASON`) lehet:
    - ERROR_CORRECTION - Hibajavítás
    - MANAGEMENT_APPROVAL - Vezetői jóváhagyás
    - OTHER - Egyéb, részletes indoklással

3. Minden korrekcióhoz kötelező jegyzőkönyv készül, amely tartalmazza:
    - A korrekció előtti és utáni állapotot
    - A korrekciót végző személyt
    - A jóváhagyó vezetőt
    - Részletes indoklást

4. A korrekció után a rendszer frissíti a bankjegykészletet és audit naplóbejegyzést készít.

### Rendkívüli napi zárás

1. Műszaki hiba, áramszünet vagy egyéb rendkívüli esemény esetén rendkívüli napi zárás kezdeményezhető.
2. A folyamat hasonló a normál záráshoz, de a státusz "PROCESSING" marad, amíg supervisor nem ellenőrzi.
3. A rendkívüli zárás után kötelező teljes pénztárellenőrzés következik a következő nyitás előtt.
