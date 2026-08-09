---
title: 01_alapfolyamatok.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/load2fit_folyamatok/01_alapfolyamatok.md
doc_type: text
---

# 01_alapfolyamatok.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 7.5 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/load2fit_folyamatok/01_alapfolyamatok.md`

## Tartalom

# Load2fit Rendszer Alapfolyamatai

## Bevezetés

Ez a dokumentum a Load2fit szállítmányozási bróker rendszer alapvető folyamatait írja le, beleértve a regisztrációt, felhasználó-ellenőrzést, megbízások kezelését és az ajánlattételi folyamatot. Az itt leírt folyamatok a rendszer alapvető működésének gerincét alkotják.

## Felhasználói regisztráció és ellenőrzés

### Fuvarozó regisztrációja

1. A Fuvarozó a multiplatformos alkalmazáson keresztül regisztrál a rendszerbe.
2. Megadja a kötelező adatokat:
   - Cégnév (`company_name`)
   - Adószám (`tax_id`)
   - FMCSA engedélyszám (`fmcsa_license_number`)
   - Székhely cím (`headquarters_address`)
   - Telephelyek címei (`location_addresses`) - opcionális, több is lehet
   - Kapcsolattartó adatai (`contact_info`)
   - Szállítói kompetenciák (`carrier_competencies`) - milyen típusú szállításokat vállal
   - Működési terület (`operation_area`) - mely államokban/tartományokban működik
3. A rendszer valós időben ellenőrzi az FMCSA adatbázisban az engedélyszám érvényességét.
4. Sikeres ellenőrzés esetén a Fuvarozó státusza (`carrier_status_did`) "PENDING_APPROVAL" lesz.
5. A rendszeradminisztrátor ellenőrzi a megadott adatokat, és jóváhagyás esetén a státusz "ACTIVE" lesz.

### Megbízó regisztrációja (jogi személy)

1. A Megbízó (jogi személy) a multiplatformos alkalmazáson keresztül regisztrál a rendszerbe.
2. Megadja a kötelező adatokat:
   - Cégnév (`company_name`)
   - Adószám (`tax_id`)
   - Székhely cím (`headquarters_address`)
   - Kapcsolattartó adatai (`contact_info`)
   - Ország (`country_did`) - USA vagy Kanada
3. A rendszer valós időben ellenőrzi az adószám érvényességét:
   - USA esetén a data.gov adatbázisából
   - Kanada esetén a GOV Canada GST/HST adatbázisából
4. Sikeres ellenőrzés esetén a Megbízó státusza (`client_status_did`) "PENDING_APPROVAL" lesz.
5. A rendszeradminisztrátor ellenőrzi a megadott adatokat, és jóváhagyás esetén a státusz "ACTIVE" lesz.

### Megbízó regisztrációja (magánszemély)

1. A Megbízó (magánszemély) a multiplatformos alkalmazáson keresztül regisztrál a rendszerbe.
2. Megadja a kötelező adatokat:
   - Teljes név (`full_name`)
   - Társadalombiztosítási szám (`ssn` vagy `sin`)
   - Lakcím (`address`)
   - Elérhetőségek (`contact_info`)
   - Ország (`country_did`) - USA vagy Kanada
3. A rendszer ellenőrzi a társadalombiztosítási szám érvényességét:
   - USA esetén az SSA rendszerén keresztül
   - Kanada esetén a SIN rendszerén keresztül
4. Sikeres ellenőrzés esetén a Megbízó státusza (`client_status_did`) "PENDING_APPROVAL" lesz.
5. A rendszeradminisztrátor ellenőrzi a megadott adatokat, és jóváhagyás esetén a státusz "ACTIVE" lesz.

## Megbízások kezelése

### Új megbízás létrehozása

1. Az aktív státuszú Megbízó (akár jogi személy/cég, akár magánszemély) új megbízást (`assignment`) hoz létre a rendszerben.
2. Megadja a kötelező adatokat:
   - Megbízás címe (`title`)
   - Részletes leírás (`description`)
   - Szállítási adatok:
     - Feladási hely (`pickup_location`)
     - Célállomás (`delivery_location`)
     - Feladási időablak (`pickup_time_window`)
     - Kézbesítési időablak (`delivery_time_window`)
   - Rakomány adatok:
     - Típus (`cargo_type_did`)
     - Súly (`weight`)
     - Térfogat (`volume`)
     - Speciális kezelési igények (`special_handling_requirements`) - opcionális
   - Árajánlati elvárások:
     - Minimum ár (`min_price`) - opcionális
     - Maximum ár (`max_price`) - opcionális
     - Pénznem (`currency_did`) - USD
   - Megbízás érvényességi ideje (`validity_period`)
3. A rendszer ellenőrzi az adatok helyességét és teljességét.
4. Sikeres ellenőrzés esetén a megbízás státusza (`assignment_status_did`) "DRAFT" lesz.

### Megbízás publikálása

1. A Megbízó a "DRAFT" státuszú megbízást publikálja.
2. A rendszer ellenőrzi, hogy minden kötelező adat ki van-e töltve.
3. Sikeres ellenőrzés esetén a megbízás státusza "PUBLISHED" lesz.
4. A publikált megbízás kereshető lesz a Fuvarozók számára, de a Megbízó adatai anonimak maradnak.

### Megbízás keresése

1. A Fuvarozó különböző feltételek alapján kereshet megbízásokat:
   - Földrajzi hely (feladási/célállomás)
   - Időablak
   - Rakomány típusa
   - Árkategória
   - Egyéb szűrők
2. A Fuvarozó mentheti a keresési feltételeket későbbi használatra.
3. A keresési eredmények listázzák a releváns megbízásokat, de a Megbízók adatai anonimak maradnak.

## Ajánlattételi folyamat

### Ajánlat készítése

1. A Fuvarozó kiválaszt egy "PUBLISHED" státuszú megbízást, és ajánlatot (`offer`) készít.
2. Megadja az ajánlat adatait:
   - Ár (`price`) - USD-ben
   - Szállítási feltételek (`delivery_conditions`)
   - Érvényességi idő (`validity_period`)
   - Megjegyzések (`notes`) - opcionális
3. A rendszer ellenőrzi az ajánlat adatait.
4. Sikeres ellenőrzés esetén az ajánlat státusza (`offer_status_did`) "SUBMITTED" lesz.

### Ajánlat elbírálása

1. A Megbízó értesítést kap a beérkezett ajánlatról.
2. A Megbízó megtekinti az ajánlat részleteit, de a Fuvarozó adatai részben anonimak maradnak (csak a telephelyek nem teljes címei, értékelése, szállítói kompetenciái láthatók).
3. A Megbízó dönthet az ajánlat elfogadásáról, elutasításáról vagy módosítási kéréséről.
4. Elfogadás esetén az ajánlat státusza "ACCEPTED" lesz.
5. Elutasítás esetén az ajánlat státusza "REJECTED" lesz.
6. Módosítási kérés esetén az ajánlat státusza "MODIFICATION_REQUESTED" lesz, és a Fuvarozó értesítést kap.

### Kapcsolat létrehozása

1. A Fuvarozó értesítést kap az elfogadott ajánlatról.
2. A Fuvarozó visszaigazolhatja az elfogadott ajánlatot.
3. Visszaigazolás esetén a Load2fit bekéri a jutalékot az érvényes díjszabás szerint.
4. A rendszer számlát állít ki a jutalékról a Fuvarozónak.
5. Sikeres fizetés esetén:
   - A megbízás anonimitása megszűnik a Fuvarozó számára
   - A Megbízó értesítést kap a kapcsolat létrejöttéről, a Fuvarozó adataival
   - A megbízás státusza "IN_PROGRESS" lesz

### Kooperatív megbízás teljesítés

1. Nagy mennyiségű áru esetén a Megbízó engedélyezheti a kooperatív teljesítést.
2. Ebben az esetben több Fuvarozó ajánlata is elfogadható.
3. A rendszer nyilvántartja, hogy melyik Fuvarozó a rakomány mely részéért felelős.
4. Minden Fuvarozó csak a saját részére vonatkozó jutalékot fizeti.

## Értékelési rendszer

### Fuvarozó értékelése

1. A megbízás teljesítése után a Megbízó értékelheti a Fuvarozót.
2. Az értékelés szempontjai:
   - Pontosság
   - Kommunikáció
   - Áru állapota
   - Általános elégedettség
3. Az értékelés 1-5 skálán történik, szöveges megjegyzéssel kiegészítve.
4. Az értékelések átlaga megjelenik a Fuvarozó profiljában.

### Megbízó értékelése

1. A megbízás teljesítése után a Fuvarozó értékelheti a Megbízót.
2. Az értékelés szempontjai:
   - Pontos információk
   - Kommunikáció
   - Fizetési pontosság
   - Általános elégedettség
3. Az értékelés 1-5 skálán történik, szöveges megjegyzéssel kiegészítve.
4. Az értékelések átlaga megjelenik a Megbízó profiljában.
