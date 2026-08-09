---
title: Követelménylista - Árfolyamkészítés.docx
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Árfolyamkészítő programról/Követelménylista - Árfolyamkészítés.docx
doc_type: word
---

# Követelménylista - Árfolyamkészítés.docx

**Kategoria:** altalanos  |  **Tipus:** word  |  **Meret:** 10.3 KB
**Eredeti utvonal:** `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Árfolyamkészítő programról/Követelménylista - Árfolyamkészítés.docx`

## Tartalom

A munkalapok szoros összeköttetésben állnak egymással, köztük egyszerű átjárás.
ÁR001:  Alapárfolyam lap (0-s árfolyam lap) excel tábla
ÁR001-01: Elszámoló árfolyamok (A oszlop)
Kézi beállítás: 
Csak a fő valuták (EUR, USD, GBP, CHF) esetén állítják be kézzel, azonban minden valutánál kézzel állítható az elszámoló árfolyam, de csak a fővalutákat állítják kézzel, mivel a többi képlettel van számolva.
Automatikusan töltődő árfolyamok: 
Valuták amik automatikusan másolják az OTP árfolyamot ebben az oszlopban: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK
Euró alapú valuták (pl. CZK, PLN, RON, RSD, TRY) esetén az EUR keresztárfolyam alapján számolja az árfolyamot.
A dollár alapú valuták (ILS, UAH, RUB, CNY, BAM, THB, BRL, MXN, NZD, RCH) árfolyamát az USD keresztárfolyam alapján számolja.
ÁR001-02: OTP árfolyam (B oszlop)
Iránymutatás a deviza váltáshoz: 
Az OTP árfolyam az irányadó, amelyet kézzel állítanak az OTP hivatalos weboldalán található árfolyam alapján.
Kézi beírás: 
Ez az oszlop teljesen kézzel szerkeszthető, de csak a következő valutanemeknél szerkesztik kézzel: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN.
ÁR001-03: Segédoszlop (C oszlop)
Kézi szorzók beállítása: 
Kézzel állítható Segéd árfolyamokból lehet szorzókat beállítani. 
ÁR001-04: Valutanemek (D oszlop)
EUR
USD
GBP
CHF
AUD
CAD
DKK
JPY
NOK
SEK
CZK
HRK
PLN
RON
RSD
BGN
ILS
UAH
RUB
EUA (euró érme árfolyama. 20%-al nem térhet el, ha többel tér el akkor ki kell írni az ügyfeleknek. példa a képzésre: gyenge árfolyamos euró eladás szorozva 1.2-vel)
TRY
CNY
BAM
THB
BRL
MXN
NZD
RCH
Új valutanem felvétele/törlése:
Jelenleg csak a program módosításával van lehetőség erre. A legjobb az lenne, ha lehetne új valutát felvenni, illetve meglévőt megszüntetni, viszont ezekre kérdezzen rá, akár többször is vagy supervisori jelszóhoz legyen kötve a módosítás.
ÁR001-05: Gyenge árfolyamos multik (a legszélesebb árfolyamú irodák)
ÁR001-05-01: Vétel (E oszlop)
ÁR001-05-02: Eladás (F oszlop)
képletezhető legyen a Vétel (E oszlop)
a Raiffeisen megbízási szerződés alapján középárfolyamtól 10% nem lehet nagyobb az eltérés a vétel és az eladási oldalon. Ez az érték (10%) lehessen szabadon állítható.
Vagy az elszámolóból számolja ki a +/- 10%-ot vagy az OTP-t írja, ezt Tamás dönti el aktuálisan éppen melyiket használja, szezonálisan éppen mi a tendencia. Nincs állandó metódus erre, ahogy a forgalom éppen kívánja.
ÁR001-06: Keresztárfolyamok (G oszlop) (H oszlop)
a G és H oszlopban jelennek meg a keresztárfolyamok a következő valutáknál: CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH
ÁR002: Csoport lap:
ÁR002-01: Elszámoló árfolyam (J oszlop)
ÁR002-02: Valuták (K oszlop)
ÁR002-03: Alsó kedvezményhatár Vétel - Eladás  (L és M oszlop): 
Az alap kiírt árfolyamok, amik a kijelzőkön megjelennek. 
Ezeket kézzel állítják.
ÁR002-04: Középső kedvezmény határ Vétel - Eladás (N és O oszlop)
ÁR002-05: Felső kedvezmény határ Vétel - Eladás (P és Q oszlop)
ÁR002-06: Saját hatáskörű Vét. max. - Elad. min. (R és S oszlop)
A pénztárakban le van limitálva a pénztárosnak, csak napi 5-t adhat. Ennek a képzése: az előtte lévő oszlopokhoz hasonló, képletezve van, az előző értékhez van hozzáadva a kedvezmény mértéke (pl.: az EUR „R” oszlop képlete P+0,25)
ÁR002-07: A csoportba tartozó irodák listája
ÁR002-08:Aktuális függvény
ÁR002-09: Kitöltési segítség (függvények kezelése)
Azonos valutanem oszlopa az alap-árfolyam táblázatban
Azonos valutanem oszlopa az aktuális munkacsoportban
Más valutanem bármely oszlopa
Azonos valutanem egy másik csoportból
Adatmásolás
Adat lehúzás
ÁR002-10:Kedvezmény határok
Ez egyszer be van állítva, nem szokták rendszeresen állítgatni, de jó hogy ha állítható marad.
Az 54 lapon (csoport) mindegyiknél egyedileg állítható.
Az elszámoló árfolyamnál nem lehet kisebb az eladási árfolyam. Ezért figyelmeztetést küld a rendszer ha ki akarja küldeni az árfolyamot és az árfolyam nem megfelelő. 
A vételi árfolyam  pedig az elszámoló árfolyamnál nem lehet magasabb.
