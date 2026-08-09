---
title: README.md
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/v2.0/Markdown/load2fit_folyamatok/README.md
doc_type: text
---

# README.md

**Kategoria:** altalanos  |  **Tipus:** text  |  **Meret:** 2.5 KB
**Eredeti utvonal:** `Felmérés/Valuta/v2.0/Markdown/load2fit_folyamatok/README.md`

## Tartalom

# Load2fit Szállítmányozási Bróker Rendszer

## Bevezetés

A Load2fit egy szállítmányozási bróker rendszer, amely a Fuvarozók és a Megbízók közötti kapcsolat megbízható, gyors, költséghatékony megvalósítását célozza. A rendszer két fő alkalmazásból áll:

1. **Központi web alapú adminisztrációs, üzemeltetői felügyeleti alkalmazás**
2. **Multiplatformos, ügyfeleknek készült alkalmazás**, amelybe a felhasználók regisztrálhatják magukat

## Üzleti felhasználók

A rendszer üzleti felhasználói:

- **Megbízók**: USA-beli vagy kanadai jogi vagy természetes személyek
- **Fuvarozók**: USA-beli vagy kanadai, meghatározott engedéllyel rendelkező jogi személyek

A két felhasználói kör között átfedés is lehet.

## Regisztráció és ellenőrzés

Az üzleti felhasználók regisztrációkor adat ellenőrzésen esnek át:

- **Fuvarozók**: FMCSA adatbázisban ellenőrzés
- **Megbízók (jogi személyek)**: 
  - USA: data.gov adatbázisból ellenőrzés
  - Kanada: GOV Canada GST/HST adatbázisból ellenőrzés
- **Megbízók (magánszemélyek)**:
  - USA: Social Security Administration (SSA) ellenőrzés
  - Kanada: Social Insurance Number (SIN) ellenőrzés

## Alapvető folyamatok

1. **Megbízás létrehozása és publikálása**: A Megbízó létrehozza és publikálja a megbízást, amely tartalmazza a szükséges adatokat, de anonim marad mások számára.
2. **Fuvarozó keresés**: A Megbízó kereshet Fuvarost, de a Fuvaros adatai részben anonimak maradnak.
3. **Megbízás keresés**: A Fuvarozó kereshet megbízást különböző feltételekkel.
4. **Ajánlattétel**: A Fuvarozó ajánlatot tehet a megbízásra.
5. **Ajánlat elbírálása**: A Megbízó elbírálja a beérkezett ajánlatokat.
6. **Kapcsolat létrehozása**: Az elfogadott ajánlatról a Fuvarozó értesítést kap, amit visszaigazolhat.
7. **Jutalék fizetés**: A Load2fit bekéri a jutalékot, számlát állít ki, és sikeres fizetés esetén a megbízás anonimitása megszűnik.
8. **Értékelés**: Mind a Fuvarozó, mind a Megbízó értékelheti a másik felet sikeres kapcsolat esetén.

## Rendszer funkciók

- Reklamáció kezelés
- Jutalék díj karbantartás
- Load2fit rendszer értékelése
- Hírlevelek

## Dokumentáció struktúra

Ez a mappa a Load2fit rendszer folyamatait, modul- és menüstruktúráját, valamint egyéb rendszerszintű dokumentációját tartalmazza. A kapcsolódó entitás definíciók a load2fit_*.figdoc.md fájlokban találhatók.
