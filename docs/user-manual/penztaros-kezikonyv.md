# Pénztáros kézikönyv — Valutaváltó program

> Ez a kézikönyv a **pénztárosoknak** (valutaváltó kollégáknak) készült. A program asztali változatát (telepített Pénztár kliens) használja.
> Ha bármi nem úgy működik, ahogy itt le van írva, hívja a vezetőjét — **ne próbálkozzon parancssorral, fájl-szerkesztéssel vagy bármilyen műszaki beavatkozással**.

---

## Tartalom

1. [Bejelentkezés a programba](#1-bejelentkezés-a-programba)
2. [A pénztáros főmenü](#2-a-pénztáros-főmenü)
3. [Napnyitás (a nap első teendője)](#3-napnyitás-a-nap-első-teendője)
4. [Valuta vétel — az ügyfél eladja Önnek a valutát](#4-valuta-vétel--az-ügyfél-eladja-önnek-a-valutát)
5. [Valuta eladás — az ügyfél vesz Öntől valutát](#5-valuta-eladás--az-ügyfél-vesz-öntől-valutát)
6. [Konverzió — két valuta cseréje (pl. EUR ↔ USD)](#6-konverzió--két-valuta-cseréje-pl-eur--usd)
7. [Sztornó — mai bizonylat törlése](#7-sztornó--mai-bizonylat-törlése)
8. [Címletezés — a kasszában lévő pénz pontos felsorolása](#8-címletezés--a-kasszában-lévő-pénz-pontos-felsorolása)
9. [Napzárás — a nap végi teendő](#9-napzárás--a-nap-végi-teendő)
10. [Mit tegyen, ha hibát kap](#10-mit-tegyen-ha-hibát-kap)

---

## 1. Bejelentkezés a programba

### Mit lát a képernyőn

Amikor elindítja a Pénztár programot az asztali parancsikonnal (**Valuta Pénztár — Éles kliens**), egy bejelentkezési ablak nyílik meg. Három mezőt lát:

- **Cégkód** — alapértelmezésben már ki van töltve (pl. `EBC`). Ne változtassa meg.
- **Pénztáros kód** — az Ön egyedi azonosítója (pl. `KOVACS_E`). Ha a pénztáros lista legördül, válassza ki magát onnan.
- **Jelszó** — az Ön személyes jelszava (legalább 8 karakter).

### Két módon léphet be

#### A) Pénztáros kóddal és jelszóval (a megszokott út)

1. A **Pénztáros kód** mezőben kattintson a kis lefelé mutató nyílra → válassza ki a saját nevét a listából.
2. A **Jelszó** mezőbe írja be a jelszavát.
3. Kattintson a **Bejelentkezés** gombra.

#### B) Google fiókkal (ha be van állítva)

1. A bejelentkezési ablakban kattintson a **„Bejelentkezés Google-fiókkal"** gombra.
2. Egy Google ablak nyílik meg, ahol válassza ki a céges Google-fiókját.
3. A program automatikusan beengedi.

### Ha a bejelentkezés sikertelen

- **„Hibás kód vagy jelszó"** üzenet → ellenőrizze a Caps Lock-ot, írja be újra a jelszót. Ha háromszor sikertelen, a fiók ideiglenesen zárolódik — hívja a vezetőjét.
- **„Hálózati hiba"** vagy **„Network Error"** → a program automatikusan újrapróbálkozik (3-szor). Ha tartós, hívja a vezetőjét.
- **„Elfelejtett jelszó"** linkre kattintva e-mailt kap a jelszó visszaállításához — csak akkor használja, ha a saját céges e-mail címét tudja.

---

## 2. A pénztáros főmenü

A bejelentkezés után megjelenik a **Pénztáros főmenü**. Ez a baloldali oldalsávból (sidebar) érhető el bármikor.

### A baloldali menüben látható tételek

| Menüpont | Mire való? |
|---|---|
| **Pénztáros főmenü** | A főképernyő — innen indít minden tranzakciót |
| **Napnyitás** | A nap kezdetén egyszer kell megnyomni |
| **Valuta vétel / eladás** | Itt zajlik a vétel és az eladás |
| **Konverzió** | Két valuta cseréje (pl. EUR-ból USD) |
| **Kassza / készlet** | Megnézheti, mennyi pénz van Önnél valutanemenként |
| **Címletezés** | A kasszában lévő pénz részletezése (címlet × darabszám) |
| **Ügyfelek** | Visszatérő ügyfelek adatai (csak ott, ahol releváns) |
| **Úton lévő csomagok** | Az értéktárból Önhöz, vagy Öntől az értéktárhoz tartó csomagok |
| **Napzárás** | A nap végén egyszer kell megnyomni |
| **Árfolyamok (nézet)** | Aktuális vételi/eladási árfolyamok (csak nézet, módosítani nem lehet) |
| **Tranzakciólista** | A mai napi bizonylatok listája |

### Gyorsbillentyűk (a Vétel/Eladás képernyőn)

| Gomb | Funkció |
|---|---|
| **F1** | Vétel mód |
| **F2** | Eladás mód |
| **F5** | Sztornó |
| **F8** | Árfolyam-nézet |
| **F9** | Kedvezmény |
| **Esc** | Mégse / kilépés a képernyőről |
| **Tab** vagy **Enter** | Lépés a következő mezőre |

---

## 3. Napnyitás (a nap első teendője)

> **Naponta egyszer, a nap legelején, MIELŐTT bármilyen vételt vagy eladást rögzítene.**

### Mi az a napnyitás?

A napnyitás nyit egy „pénztári napot" — addig nem lehet valutát venni vagy eladni, amíg ez meg nem történik. A program ezzel ellenőrzi, hogy mennyi pénzzel kezdi a napot, és letárolja a kezdő egyenleget.

### Lépésről-lépésre

1. **Bal oldali menü → „Napnyitás"** menüpont.
2. **Mit lát a képernyőn:** egy lista az összes valutáról (HUF, EUR, USD, GBP stb.), mindegyik mellett egy beviteli mező.
3. **A kasszában lévő nyitó-készlet beírása:**
   - HUF mezőbe: a forint kezdő készlet (címletezve a következő részben).
   - Minden más valutához: a kezdő darabszám / összeg.
4. Ellenőrizze az adatokat, majd kattintson a **„Nap megnyitása"** gombra.
5. A program egy zöld visszaigazoló üzenetet mutat: **„A nap megnyitva."**

### Ha hibát kap

- **„A nap már meg van nyitva ma"** → valaki más már megnyitotta. Nem kell újra. Tovább léphet a tranzakciókhoz.
- **„A nyitó készlet nem egyezik az előző nap záró készletével"** → a vezetőjét hívja. Ne próbálja meg felülírni.

---

## 4. Valuta vétel — az ügyfél eladja Önnek a valutát

> **Naponta többször, ahányszor egy ügyfél valutát hoz be Önhöz.**

### A folyamat röviden

Az ügyfél hozza a valutát (pl. 100 EUR), Ön átveszi, és **forintot ad neki cserébe** a vételi árfolyamon.

### Lépésről-lépésre

1. **Bal oldali menü → „Valuta vétel / eladás"**.
2. A képernyő tetején a **„Vétel"** fül legyen aktív (vagy nyomja meg az **F1**-et).
3. **Mit lát a képernyőn:** egy táblázat 6 üres sorral. Minden sorba egy valuta-tételt vihet be.

### Egy sor kitöltése

1. **Valuta** oszlop: kattintson a sorra, majd kezdje el gépelni a valuta kódját (pl. `EUR`) — a program automatikusan felkínálja a találatokat. Válassza ki a megfelelőt.
2. **Mennyiség** oszlop: írja be, mennyi valutát hoz az ügyfél (pl. `100`).
3. **Tab** vagy **Enter** lenyomására a program automatikusan kiszámítja a HUF értéket az aktuális vételi árfolyam alapján.
4. Ha több valutát is hoz az ügyfél (pl. EUR + USD), a következő sorba folytassa.

### Ügyfél azonosítás (AML — pénzmosás elleni ellenőrzés)

A program a **HUF összegtől** függően **automatikusan eldönti**, hogy milyen ügyfélazonosítás kell:

| HUF összeg | Mit kell tenni? |
|---|---|
| **300 000 Ft alatt** | **Egyszerűsített** — csak a vételi adatokat rögzíti, ügyfél nevét nem kell. |
| **300 000 — 4 500 000 Ft között** | **Egyszerűsített azonosítás** — az ügyfél neve, lakcíme, születési ideje, okmány típusa és száma kell. |
| **4 500 000 Ft felett** | **Teljes körű azonosítás** — minden adat + okmány-másolat (a program kéri a fotót / scan-elést). |

A **jobboldali ügyfél-panelen** a program kijelzi, milyen szintű azonosítás szükséges, és csak akkor enged tovább, ha minden kötelező mező ki van töltve.

### Ha az ügyfél szankciós listán szerepel

Ha az ügyfél neve egyezést mutat a hatósági szankciós listával, a program **piros figyelmeztetést** ad: **„Az ügyfél lehetséges egyezést mutat a szankciós listával."** Ilyenkor:

1. **NE folytassa a tranzakciót.**
2. Hívja azonnal a vezetőjét vagy a Compliance felelőst.
3. Ne adjon ki pénzt és ne fogadjon el valutát.

### Bizonylat nyomtatása

1. Amikor minden adat ki van töltve, kattintson a **„Rögzítés"** (vagy **„Vétel rögzítése"**) gombra.
2. Egy előnézet ablak ugrik elő a bizonylattal — ellenőrizze a számokat.
3. Kattintson a **„Nyomtatás"** gombra. A bizonylatnyomtató kétszer nyomtat: egy példány az ügyfélnek, egy a pénztárnak.
4. A bizonylat formátuma: **V + 3 jegyű iroda-kód + 6 jegyű sorszám** (pl. `V039000123`).

### Ha hibát kap

- **„Az árfolyam lejárt (5 perc)"** → kattintson a **„Frissítés"** gombra a képernyő tetején. Ha nem segít, hívja a vezetőjét.
- **„A nap nincs megnyitva"** → menjen vissza a Napnyitásra (3. fejezet), és nyissa meg.
- **Hálózati hiba (Network Error)** → a program **automatikusan 3-szor újrapróbálkozik** (1, 3, 5 másodperc múlva). Várja meg, ne nyomkodja a gombot. Ha tartósan nem sikerül, a tranzakció **offline módban** rögzül a program memóriájában, és a kapcsolat helyreállása után automatikusan szinkronizál a szerverrel — Ön nyugodtan folytathatja a munkát.

---

## 5. Valuta eladás — az ügyfél vesz Öntől valutát

> Az ügyfél forintot hoz, és Ön valutát ad neki cserébe **eladási árfolyamon**.

### Lépésről-lépésre

1. **Bal oldali menü → „Valuta vétel / eladás"**.
2. A képernyő tetején válassza az **„Eladás"** fület (vagy nyomja meg az **F2**-t).
3. A folyamat ugyanaz, mint a vételnél:
   - Valuta oszlop: válassza ki, milyen valutát kér az ügyfél (pl. EUR).
   - Mennyiség: hány eurót kér.
   - A program kiszámolja, mennyi forintot kell az ügyféltől beszedni.
4. Ügyfél azonosítás: **ugyanaz a sávozás**, mint a vételnél (300 000 Ft, 4 500 000 Ft határok).
5. Rögzítés és bizonylat-nyomtatás: ugyanaz, mint a vételnél. A bizonylatkód: **E + 3 jegyű iroda-kód + 6 jegyű sorszám** (pl. `E039000124`).

### Ha hibát kap

- **„Nincs elég [valuta] a kasszában"** → ellenőrizze a Kassza / készlet menüben a tényleges állományt. Ha a program rosszul számol, hívja a vezetőjét.
- **„Az ügyfél azonosítás hiányos"** → töltse ki a kötelező mezőket a jobb oldali ügyfél-panelen.

---

## 6. Konverzió — két valuta cseréje (pl. EUR ↔ USD)

> Az ügyfél egy valutát hoz be, és **másik valutát** kér helyette (NEM forintot).

### Lépésről-lépésre

1. **Bal oldali menü → „Konverzió"**.
2. **Mit lát a képernyőn:** két oszlop — **„Bejövő valuta"** (amit az ügyfél hoz) és **„Kimenő valuta"** (amit ad neki).
3. **Bejövő oldal:**
   - Válassza ki a valutát (pl. USD).
   - Írja be a mennyiséget (pl. 200).
4. **Kimenő oldal:**
   - Válassza ki a kért valutát (pl. EUR).
5. A program automatikusan kiszámítja, hány EUR-t kap az ügyfél a 200 USD-ért, a két valuta árfolyam-keresztje alapján.
6. Ügyfél azonosítás (AML) ugyanúgy működik, mint vételnél/eladásnál.
7. **„Konverzió rögzítése"** gomb → bizonylat előnézet → **Nyomtatás**.

### Megjegyzés

A konverzió bizonylatkódja **K** betűvel kezdődik (pl. `K039000045`).

---

## 7. Sztornó — mai bizonylat törlése

> **Csak ugyanazon a napon** lehet sztornózni egy bizonylatot. Egy lezárt nap bizonylatait NEM lehet sztornózni — ahhoz a vezető beavatkozása kell.

### Mikor használja?

- Az ügyfél meggondolta magát.
- Hibásan rögzítette a tranzakciót (rossz valuta, rossz összeg).
- A bizonylat nyomtatás közben elakadt és duplikálódott.

### Lépésről-lépésre

1. **Bal oldali menü → „Tranzakciólista"** vagy a Vétel/Eladás képernyőn nyomja meg az **F5**-öt.
2. **Mit lát a képernyőn:** a mai napi bizonylatok listája időrendben.
3. Kattintson a sztornózandó bizonylat sorára.
4. Egy ablak nyílik meg a bizonylat részleteivel és egy **„Sztornó"** gombbal.
5. Kattintson a **„Sztornó"** gombra.
6. A program **kötelezően kéri a sztornó indokát** — válasszon a felkínált listából, vagy írja be saját szavakkal (legalább 5 karakter).
7. **„Megerősítés"** gomb → a program kinyomtat egy sztornó-bizonylatot.

### Mi történik a kasszával?

A sztornó automatikusan visszafordítja a tranzakciót:

- Egy vétel sztornója: a HUF visszakerül a kasszába, a valuta kikerül.
- Egy eladás sztornója: a valuta visszakerül a kasszába, a HUF kikerül.

### Ha hibát kap

- **„A bizonylat nem ezen a napon kelt"** → már lezárt napi bizonylat. Hívja a vezetőjét.
- **„Sztornó indoka kötelező"** → írjon be legalább 5 karaktert.

---

## 8. Címletezés — a kasszában lévő pénz pontos felsorolása

> A címletezés azt jelenti, hogy **címletenként** (pl. 20 000 Ft-os, 10 000 Ft-os, 5 000 Ft-os bankjegyek darabszáma) megmondja, mi van a kasszában.

### Mikor kell címletezni?

- **Napnyitáskor** — a kezdő készlethez.
- **Címletezés megosztása értéktárral** közben (átadáskor).
- **Napzáráskor** — a záró készlethez.
- Bármikor, amikor a kasszát „összeszámolja" (pl. ellenőrzés).

### Lépésről-lépésre

1. **Bal oldali menü → „Címletezés"**.
2. **Mit lát a képernyőn:** egy táblázat HUF címletekkel csökkenő sorrendben:
   - 20 000 Ft, 10 000 Ft, 5 000 Ft, 2 000 Ft, 1 000 Ft, 500 Ft, 200 Ft, 100 Ft, 50 Ft, 20 Ft, 10 Ft, 5 Ft.
3. Minden címlethez írja be a **darabszámot**.
4. A program a sorok mellett mutatja a részösszeget (címlet × darabszám) és alul az összesítést.
5. Ellenőrizze, hogy az összesített Ft-érték megegyezik a kasszában lévő pénzzel.
6. **„Mentés"** gomb.

### Címletezés más valutákhoz

Ha más valutákhoz is kell címletezni (pl. EUR, USD), a Címletezés képernyő tetején válassza ki a valutát egy legördülő listából.

### Tipp

Mindig pontosan számolja meg a pénzt, mielőtt beírja. Ha a program által számolt összeg eltér a kasszában fizikailag lévő összegtől, **ne írjon át semmit** — hívja a vezetőjét.

---

## 9. Napzárás — a nap végi teendő

> **A nap végén, MIUTÁN minden tranzakció lezajlott**, a napzárást kell elindítani.

### Mit csinál a napzárás?

A program **9 lépésből álló ellenőrzési láncot** futtat le:

1. MTCN szám ellenőrzés (Western Union)
2. Esti pénztár címletezése
3. Kezelési díj címletezés
4. Western Union címletezés
5. ÁFA címletezés
6. Foglaló címletezés
7. E-kereskedelem címletezés
8. Egyéb címletezések (AXA, MoneyGram)
9. NAV kontroll és napi jelentés

A pontok közt **megáll** a 2. lépésnél, és bekéri Öntől a HUF címletezést.

### Lépésről-lépésre

1. **Bal oldali menü → „Napzárás"**.
2. **Mit lát a képernyőn:** egy sávos haladás-jelző és a 9 lépés listája.
3. Kattintson a **„Napzárás indítása"** gombra. A program elindítja az 1. lépést automatikusan.
4. **Pause a 2. lépésnél:** a program megáll, és kéri a HUF címletezést.
   - Töltse ki a címletek darabszámát (ugyanúgy, mint a Címletezés menüben).
   - Az összesített HUF összegnek meg kell egyeznie a program által elvárt értékkel.
   - Kattintson a **„Címletezés rögzítése"** gombra.
5. A program automatikusan tovább megy a 3-9. lépéseken.
6. Ha minden lépés zöld pipát kap, kattintson a **„Napzárás lezárása"** gombra.
7. Egy záró bizonylat és napi jelentés készül.

### Ha egy lépés piros pipát kap (failed)

- A program szöveges üzenetben mutatja, mi a baj (pl. „A 100 darab 1000 Ft-os címlet nem egyezik a kasszával").
- **NE zárja le erőszakkal a napot.** Ellenőrizze, mi a probléma — hívja a vezetőjét, ha nem találja az eltérés okát.
- A nap zárás csak akkor véglegesíthető, ha **MINDEN** lépés zöld.

---

## 10. Mit tegyen, ha hibát kap

### Általános szabály

> **Ne próbálja kijavítani műszakilag.** Ne nyúljon a fájlokhoz, ne futtasson parancsokat, ne állítson át a Windows beállításokon.

### Gyakori üzenetek és teendők

| Üzenet a képernyőn | Mi történt? | Mit tegyen? |
|---|---|---|
| **„Network Error"** vagy **„Hálózati hiba"** | A szerver pillanatnyilag nem érhető el | A program **automatikusan újrapróbálkozik 3-szor** (1, 3, 5 mp múlva). Várjon. Ha tartós, hívja a vezetőjét. |
| **„Az árfolyam lejárt"** | A vételi/eladási ráta régi | Kattintson a Frissítés ikonra a képernyő tetején. |
| **„A nap nincs megnyitva"** | Még nem volt napnyitás | Menjen a Napnyitás menüre. |
| **„Ügyfél azonosítás hiányos"** | A jobb oldali ügyfél-panelben hiányoznak kötelező mezők | Töltse ki őket (név, lakcím, okmány stb.). |
| **„Szankciós lista egyezés"** | Az ügyfél neve gyanús | **Azonnal hívja a vezetőjét vagy a Compliance felelőst.** Ne folytassa. |
| **„A nyomtató nem reagál"** | A bizonylat-nyomtató problémája | Ellenőrizze a papírt és a USB kábelt. Ha nem segít, hívja a vezetőjét. |
| **„A program lefagyott"** | Bármi műszaki probléma | Ne csinálja semmit. Hívja a vezetőjét. **Ne zárja be a programot erőszakkal**, mert a folyamatban lévő tranzakció elveszhet. |

### Offline mód

Ha tartós hálózati kiesés van, a program **automatikusan offline módba** vált:

- Ön folytathatja a munkát.
- A tranzakciók a saját gép memóriájában rögzülnek.
- Amikor a kapcsolat helyreáll, a program **automatikusan szinkronizál** a szerverrel.
- A jobb felső sarokban egy ikon jelzi az offline állapotot.

### Mikor hívja a vezetőjét?

- Bármilyen üzenet, amit nem ért.
- Ha a kassza-állomány eltér a program által számolttól.
- Ha az ügyfél szankciós listán szerepel.
- Ha a program lefagyott vagy lassan reagál.
- Ha bizonytalan abban, mi a következő lépés.

---

**Verzió:** 1.0 (2026-05-06)
**Készült:** Valutaváltó ERP v2.5.x
**Hatáskör:** pénztáros kollégák
