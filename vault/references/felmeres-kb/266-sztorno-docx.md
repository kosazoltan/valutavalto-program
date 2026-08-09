---
title: sztorno.docx
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/Kósa Szervezés/sztorno.docx
doc_type: word
---

# sztorno.docx

**Kategoria:** altalanos  |  **Tipus:** word  |  **Meret:** 138.8 KB
**Eredeti utvonal:** `Felmérés/Valuta/Kósa Szervezés/sztorno.docx`

## Tartalom

Sztornókezelés folyamata 
1. Alapvető sztornókezelés folyamata
sztornó kezdeményezése: A felhasználó indítja a tranzakció sztornózását a rendszerben vagy a POS terminálon
eredeti tranzakció azonosítása: A felhasználó a rendszerben lekéri és azonosítja az eredeti tranzakció adatait 
a tranzakció időpontját
a vásárolt vagy eladott devizát
az eredeti árfolyamot és az összeget
Sztornó végrehajtása: A felhasználó visszavonja a kiválasztott tranzakciót. Az összeg visszafizetésére az eredeti tranzakció szerint kerül sor, hacsak más árfolyamot nem kell alkalmazni (3. szakasz).
sztornózás a NAV felé (itt a bekötött pénztárgép ezt külön művelet nélkül automatikusan kezeli)
2. Három sztornó utáni külön engedélyezési folyamat
sztornók számlálása: A rendszer automatikusan nyomon követi a nap folyamán végrehajtott sztornók számát
engedélyezési követelmény: Ha egy felhasználó a harmadik sztornó után újabb sztornót kezdeményez, a rendszer azt előzetesen tiltja és külön engedélyt kér a sztornó végrehajtásához
engedélykérés: A rendszer értesíti a pénzügyi vezetőt az engedélyezési kérelemről
engedélyezés folyamata: A pénzügyi vezető jóváhagyja vagy elutasítja a sztornózási kérelmet a rendszerben
jóváhagyás: A rendszer a felhasználó számára lehetővé teszi a sztornó végrehajtását
elutasítás: A rendszer megakadályozza a további sztornókat, amíg nincs megfelelő engedélyezés
3. Eltérő árfolyamon történő sztornókezelés
eredeti árfolyam ellenőrzése: A rendszer ellenőrzi az eredeti tranzakció árfolyamát, amelyen a tranzakció történt
aktuális árfolyam lekérése: A sztornózás pillanatában a rendszer megjeleníti az aktuális valutaárfolyamokat
árfolyam eltérés kezelése:
eltérés feljegyzése: Ha az aktuális árfolyam eltér az eredeti tranzakció árfolyamától, a rendszer rögzíti az árfolyam különbséget
felhasználói értesítés: A rendszer figyelmezteti a felhasználót, hogy az árfolyam eltér az eredetitől, és automatikusan kiszámítja a visszatérítendő összeget az aktuális árfolyam alapján
sztornó végrehajtása eltérő árfolyamon: A sztornó összegének kiszámítása az aktuális árfolyamon történik, és a visszatérítés az új árfolyam szerint történik??
pénztári vagy kártyás visszatérítés: A rendszer, hogy a megfelelő összeget készpénzben vagy kártyás visszatérítéssel egyenlítse ki (vagy csak készpénzben lehetséges, elvileg POS-ban is kötelezően kéne működnie???)
4. POS terminál sztornókezelése
sztornózás a POS terminálon: A POS terminál lehetővé teszi a kártyás tranzakciók sztornózását, az eredeti tranzakció alapján
tranzakció visszahívása: A POS terminál lekéri az eredeti kártyás tranzakció adatait, beleértve az árfolyamot és a fizetett összeget
sztornó végrehajtása: A terminál sztornózza a tranzakciót és visszatéríti az összeget az eredeti tranzakció adatai alapján, vagy a fent említett folyamat alapján (ha eltérő árfolyam van)
5. Sztornózási bizonylatok kezelése
sztornó bizonylat generálása: A rendszer automatikusan generál egy sztornó bizonylatot, amely tartalmazza:
eredeti tranzakció adatait (összeg, deviza, árfolyam)
a sztornózás időpontját és az alkalmazott árfolyamot (ha eltér az eredetitől)
az esetleges árfolyam különbségeket.
Bizonylat nyomtatása: A sztornó bizonylatot a rendszer nyomtatja, amely rögzíti a visszatérítés pontos összegét.
bizonylatok archiválása: A sztornó bizonylatok sorszám alapján archiválódnak.
