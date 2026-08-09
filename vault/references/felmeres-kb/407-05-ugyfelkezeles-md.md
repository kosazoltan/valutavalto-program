---
title: 05_ugyfelkezeles.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: ugyfel
original_path: Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/05_ugyfelkezeles.md
doc_type: text
---

# 05_ugyfelkezeles.md

**Kategoria:** ugyfel  |  **Tipus:** text  |  **Meret:** 7.8 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/05_ugyfelkezeles.md`

## Tartalom

# Valutaváltó Rendszer Ügyfélkezelési Folyamatai

## Bevezetés

Ez a dokumentum a valutaváltó rendszer ügyfélkezelési folyamatait írja le, beleértve az ügyfélazonosítást, ügyfélnyilvántartást, ügyfélkategorizálást
és a különleges ügyfélkérések kezelését.

## Ügyfélnyilvántartási folyamatok

### Új ügyfél regisztrációja

1. Az ügyfélazonosítási limit feletti tranzakció esetén, vagy ha az ügyfél maga kéri, a pénztáros kezdeményezi az ügyfélregisztrációt.
2. Az ügyfél adatainak rögzítése a `customer` entitásban:
    - Személyes adatok: név, születési adatok
    - Elérhetőségek: cím, telefon, e-mail
    - Azonosító okmányok adatai
    - Ügyfélbesorolás (`customer_type_did` a megfelelő szótárból)
    - Marketing hozzájárulások

3. A rendszer elvégzi az adatellenőrzést:
    - Adatok formai helyességének ellenőrzése
    - Duplikáció-ellenőrzés (létező ügyfél keresése)
    - Okmányérvényesség-ellenőrzés

4. Sikeres regisztráció esetén egyedi ügyfél-azonosító generálódik.
5. A rendszer opcionálisan törzsvásárlói kártyát generálhat.

### Ügyfél-azonosítás tranzakció során

1. Már regisztrált ügyfél esetén a pénztáros azonosítja az ügyfelet:
    - Név és személyes adatok alapján
    - Törzsvásárlói kártya alapján
    - Azonosító okmányok alapján

2. A rendszer megjeleníti az ügyfél adatait és tranzakciós történetét.
3. Az ügyfél-azonosítás sikeres befejezése után a tranzakció folytatható.
4. Gyanús körülmények esetén fokozott ügyfél-átvilágítás kezdeményezhető.

### Ügyfél adatok karbantartása

1. Az ügyfél kérheti adatai módosítását.
2. A módosítási folyamat során:
    - A pénztáros azonosítja az ügyfelet
    - A módosítandó adatokat frissíti a rendszerben
    - Bizonyos adatmódosítások (pl. név, születési adatok) csak okmányok alapján végezhetők

3. Minden adatmódosítás naplózásra kerül:
    - Ki végezte a módosítást
    - Mit módosított
    - Mikor történt a módosítás
    - Milyen bizonyítékok alapján

4. Az ügyfél kérheti adatai törlését is, ami a jogszabályi kötelezettségek figyelembevételével történik.

## Ügyfélkategorizálás és -elemzés

### Ügyfélkategóriák kezelése

1. Az ügyfelek különböző kategóriákba sorolhatók a `CUSTOMER_TYPE` szótár alapján:
    - REGULAR - Alkalmi ügyfél
    - LOYAL - Törzsvásárló
    - VIP - Kiemelt ügyfél
    - CORPORATE - Vállalati ügyfél
    - PARTNER - Stratégiai partner

2. Az ügyfeleket a rendszer automatikusan kategorizálja:
    - Tranzakciós forgalom alapján
    - Tranzakciók gyakorisága alapján
    - Speciális jellemzők alapján (pl. vállalati státusz)

3. A kategória hatással van:
    - Az alkalmazott árfolyamokra
    - A felszámított jutalékokra
    - A nyújtott szolgáltatások körére

### Ügyfélprofil-elemzés

1. A rendszer elemzi az ügyfelek tranzakciós szokásait:
    - Preferált devizanemek
    - Átlagos tranzakciós méret
    - Tranzakciók gyakorisága
    - Szezonális minták

2. Az elemzések alapján a rendszer:
    - Személyre szabott ajánlatokat generálhat
    - Optimalizálhatja a készleteket
    - Azonosíthatja a szokatlan tranzakciós mintákat

3. Az elemzést csak a megfelelő jogosultsággal rendelkező felhasználók láthatják.

## Speciális ügyfélkérések kezelése

### VIP ügyfélkiszolgálás

1. A VIP ügyfelek különleges kiszolgálást igényelhetnek:
    - Soron kívüli kiszolgálás
    - Kedvezményes árfolyam alkalmazása
    - Különleges címletigények kielégítése
    - Diszkrét ügyintézés

2. A VIP kiszolgálást csak erre jogosult pénztárosok végezhetik.
3. VIP kérés kezelése során a rendszer is speciális folyamatot indít:
    - A kérés prioritást kap (`PRIORITY` = HIGH vagy CRITICAL)
    - Automatikus értesítés megy a fiókvezetőnek
    - A teljesítés minden lépése dokumentálásra kerül

### Előre egyeztetett nagy összegű tranzakciók

1. Az ügyfelek előre jelezhetik nagy összegű valutaváltási igényüket:
    - Online felületen
    - Telefonon
    - Személyesen

2. Az ilyen igények speciális kezelést kapnak:
    - Egyedi árfolyam-kalkuláció
    - Készlet előkészítése
    - Időpontfoglalás
    - Fokozott biztonsági intézkedések

3. A rendszer támogatja az előre egyeztetett tranzakciókat:
    - Előjegyzési naptár
    - Készlettervezés
    - Jóváhagyási folyamat
    - Speciális bizonylatolás

### Ügyfélpanasz-kezelés

1. Az ügyfelek panaszt nyújthatnak be a szolgáltatással kapcsolatban.
2. A panaszokat a rendszer rögzíti:
    - Panasz tárgya
    - Kapcsolódó tranzakció(k)
    - Ügyfél adatai
    - Panasz leírása
    - Kért intézkedés

3. A panaszkezelési folyamat:
    - Panasz rögzítése és visszaigazolása
    - Kivizsgálás
    - Döntéshozatal
    - Válasz az ügyfélnek
    - Esetleges korrekciós intézkedések

4. A rendszer nyomon követi a panaszkezelési határidőket és statisztikákat készít.

## Jogszabályi megfelelési folyamatok

### Ügyfél-átvilágítás

1. A rendszer támogatja a pénzmosás-megelőzési jogszabályoknak megfelelő ügyfél-átvilágítást:
    - Egyszerűsített átvilágítás - alapvető azonosítás
    - Normál átvilágítás - részletesebb adategyeztetés
    - Fokozott átvilágítás - alapos ellenőrzés és kibővített adatkör

2. Az átvilágítás szintje függ:
    - A tranzakció összegétől
    - Az ügyfél kockázati besorolásától
    - Esetleges gyanús körülményektől

3. A rendszer figyelmezteti a pénztárost, ha átvilágítás szükséges, és végigvezeti a megfelelő folyamaton.

### Bejelentési kötelezettségek teljesítése

1. A rendszer automatikusan jelzi a bejelentés-köteles tranzakciókat:
    - Limit feletti készpénztranzakciók
    - Gyanús tranzakciós minták
    - Szankciós listán szereplő ügyfelek

2. A bejelentési folyamat:
    - Automatikus jelzés generálása
    - Compliance officer értesítése
    - A tranzakció részletes elemzése
    - Döntés a bejelentésről
    - Bejelentés elkészítése és továbbítása

3. A bejelentésekkel kapcsolatos minden tevékenység szigorú naplózás alá esik.

### Ügyfélnyilvántartás megőrzése

1. A rendszer a jogszabályi követelményeknek megfelelően tárolja az ügyféladatokat:
    - Az azonosítási adatokat a jogszabályban előírt ideig (általában 8 év)
    - A tranzakciós adatokat a jogszabályban előírt ideig
    - A marketing célú adatokat a hozzájárulás visszavonásáig

2. Az adatmegőrzési szabályok automatikusan érvényesülnek:
    - Archiválási folyamatok
    - Automatikus anonimizálás
    - Törlési ciklusok

3. A rendszer biztosítja az adatok visszakereshetőségét hatósági megkeresés esetén.

## Ügyfélkommunikáció

### Értesítések kezelése

1. A rendszer támogatja az ügyfelek értesítését különböző csatornákon:
    - E-mail
    - SMS
    - Push értesítés (mobil alkalmazás esetén)
    - Postai levél

2. Értesítések típusai:
    - Tranzakciós értesítések
    - Árfolyam-értesítések
    - Marketing célú kommunikáció
    - Jogszabályi tájékoztatók

3. Az értesítési beállítások az ügyfélprofil részét képezik, és a GDPR követelményeknek megfelelően kezelendők.

### Marketing kommunikáció

1. A marketing kommunikáció csak megfelelő hozzájárulással történhet.
2. A rendszer támogatja a célzott marketing kommunikációt:
    - Ügyfélszegmensek szerinti szűrés
    - Preferenciák figyelembevétele
    - Tranzakciós szokások alapján történő ajánlatok

3. Minden marketing kommunikáció tartalmazza a leiratkozási lehetőséget.
4. A marketing tevékenységek eredményei elemezhetők és riportolhatók.
