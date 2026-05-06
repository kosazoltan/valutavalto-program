# Értéktáros kézikönyv — Valutaváltó program

> Ez a kézikönyv az **értéktáros** kollégáknak készült. Az értéktáros felelős az iroda összes pénztárának ellátásáért, a banki tranzakciókért és a napi/havi zárásokért az iroda szintjén.
> Ha bármi nem úgy működik, ahogy itt le van írva, hívja a vezetőjét — **ne nyúljon műszaki beállításokhoz**.

---

## Tartalom

1. [Bejelentkezés értéktár módban](#1-bejelentkezés-értéktár-módban)
2. [Az értéktári főképernyő](#2-az-értéktári-főképernyő)
3. [Pillanatnyi készlet — mi van az értéktárban?](#3-pillanatnyi-készlet--mi-van-az-értéktárban)
4. [Pénztári készletek — mi van a pénztárosoknál?](#4-pénztári-készletek--mi-van-a-pénztárosoknál)
5. [Átadás-átvétel — pénztárosok kiszolgálása](#5-átadás-átvétel--pénztárosok-kiszolgálása)
6. [A pénztárosi átvétel jóváhagyása](#6-a-pénztárosi-átvétel-jóváhagyása)
7. [Bank tranzakciók — bank ↔ értéktár](#7-bank-tranzakciók--bank--értéktár)
8. [Szállítólevelek — másik értéktár, vagy bank felé](#8-szállítólevelek--másik-értéktár-vagy-bank-felé)
9. [Naplókönyv — minden mozgás története](#9-naplókönyv--minden-mozgás-története)
10. [Címletezés](#10-címletezés)
11. [Napi zárás (esti zárás)](#11-napi-zárás-esti-zárás)
12. [Havi zárás](#12-havi-zárás)
13. [Mit tegyen, ha hibát kap](#13-mit-tegyen-ha-hibát-kap)

---

## 1. Bejelentkezés értéktár módban

### Az asztali parancsikon

Az értéktáros gépén a **Pénztár kliens telepítője már „értéktár" módban** lett beállítva — ezt a telepítéskor a Setup Wizard 2. lépésében választották ki.

> **Megjegyzés:** Ha Önnek pénztáros és értéktáros funkciója is van, két különálló parancsikont fog találni az asztalon — válassza azt, amelyikre épp szüksége van.

### A bejelentkezés menete

A bejelentkezés ablak ugyanúgy működik, mint a pénztáros kliensben:

1. **Cégkód** — előre kitöltve (pl. `EBC`).
2. **Felhasználói kód** — válassza ki magát a legördülő listából.
3. **Jelszó** — írja be a saját jelszavát.
4. **Bejelentkezés** gomb (vagy Google fiókkal, ha az adott vállalatnál engedélyezve van).

A program ezután automatikusan az **Értéktári dashboardra** navigál (NEM a pénztáros főmenüre).

---

## 2. Az értéktári főképernyő

### Bal oldali menü — értéktári funkciók

| Menüpont | Mire való? |
|---|---|
| **Értéktári dashboard** | Áttekintő képernyő — készlet, nyitott csomagok, figyelmeztetések |
| **Átadás-átvétel (pénztáraknak)** | Pénztárosok kiszolgálása valutával / forinttal |
| **Átadás bank / másik értéktár** | Bank vagy másik telephely felé történő mozgás |
| **Szállítólevelek** | Az értéktárból kiküldött csomagok bizonylatai |
| **Úton lévő csomagok** | Még nem érkezett vagy még nem fogadott csomagok listája |
| **Értéktári készlet** | Pillanatnyi állomány az értéktárban |
| **Pénztári készletek** | Az iroda összes pénztárosának pillanatnyi készlete |
| **Naplókönyv** | Az összes ki/be mozgás kronologikus listája |
| **Napi zárás** | Esti zárás — az iroda napi készletének átadása másnapra |
| **Havi zárás** | Havi adat-konszolidáció |
| **Ügyfelek** | Visszatérő ügyfelek nyilvántartása (ha releváns) |
| **Árfolyamok (nézet)** | Aktuális vételi/eladási árfolyamok (csak nézet) |

### A dashboard olvasása

A dashboard 3 fő sávra osztott:

1. **Készlet-mátrix** — egy táblázat, ahol a sorok a valuták (HUF, EUR, USD…), az oszlopok pedig az iroda pénztárosai + maga az értéktár. Minden cella mutatja, hogy az adott pénztárosnál vagy az értéktárban mennyi van az adott valutából.
2. **Nyitott csomagok** — a még nem fogadott (úton lévő) csomagok száma + a még nem továbbított banki tételek.
3. **Riasztások / figyelmeztetések** — pl. „A 3-as pénztárnál EUR-készlet kritikusan alacsony", „Ma még nem készült esti zárás", „Plomba egyezés ellenőrizetlen".

---

## 3. Pillanatnyi készlet — mi van az értéktárban?

### Mit lát a képernyőn

**Bal oldali menü → „Értéktári készlet"**.

A képernyőn egy **valuta-mátrix** látható:

- **Sorok:** valuták (HUF, EUR, USD, GBP, CHF, RON stb.)
- **Oszlopok:**
  - **Mennyiség** — a valuta darabszáma vagy összege
  - **HUF érték** — a mai vételi árfolyamon átszámolt forint érték
  - **Részletes** gomb — kattintsa rá, hogy lássa a címletezést (pl. 100 EUR = 5 db 20 EUR-os)

A táblázat alatt látja az **összesített HUF értéket** is.

### Frissítés

A képernyő tetején van egy **„Frissítés"** gomb. Kattintson rá, hogy a legfrissebb állapotot lássa (pl. miután épp átadott valamit egy pénztárosnak).

---

## 4. Pénztári készletek — mi van a pénztárosoknál?

**Bal oldali menü → „Pénztári készletek"**.

Itt látja az iroda összes pénztárosának pillanatnyi készletét — pénztárosonként és valutánként.

### Mit lát a képernyőn

- A táblázat **minden sora egy pénztáros**.
- **Oszlopok:** pénztáros neve, az aktuális valuták állománya, és a HUF összérték.

### Mire jó ez?

- Hogy látja, melyik pénztárosnak fogy a valutakészlete.
- Hogy időben kiszolgálja őket az értéktárból.
- Hogy ellenőrizze: a pénztáros nyitó és záró állománya stimmel-e.

---

## 5. Átadás-átvétel — pénztárosok kiszolgálása

> **A leggyakoribb értéktári művelet.** Amikor egy pénztárosnak elfogy a valuta vagy a forint, az értéktárból kap utánpótlást. Vagy fordítva: ha a pénztárosnál túl sok van, az értéktárba ad le.

### A folyamat

Két irányban történhet:

- **Értéktár → Pénztáros** (kiadás): a pénztáros valutát vagy forintot kér, Ön kiad neki.
- **Pénztáros → Értéktár** (bevétel): a pénztáros lead a kasszájából az értéktárba.

### Lépésről-lépésre — kiadás (értéktár → pénztáros)

1. **Bal oldali menü → „Átadás-átvétel (pénztáraknak)"**.
2. **Mit lát a képernyőn:**
   - Felül egy **„Új átadás"** gomb és egy szűrő (pénztáros, dátum).
   - Alul a már létrehozott átadások listája az aktuális napon.
3. Kattintson az **„Új átadás"** gombra.
4. Egy űrlap nyílik meg:
   - **Pénztáros kiválasztása:** legördülő lista — az iroda aktív pénztárosai.
   - **Irány:** „Értéktár → Pénztáros" (kiadás).
   - **Tételek:** soronként valuta + mennyiség (több sor megengedett).
   - **Megjegyzés** (opcionális).
5. **„Címletezés"** szakasz: címletenként írja be a darabszámot (a program kiszámolja az összértéket).
6. **„Plomba szám"** mező: ha lezárt csomagot ad át (pl. 100 db EUR címlet), írja be a plomba sorszámát.
7. **„Mentés és nyomtatás"** gomb.
8. A program kinyomtat egy **átadás-átvétel bizonylatot** 2 példányban:
   - 1. példány: az értéktárban marad (Ön aláírja).
   - 2. példány: a pénztárosnak adja át, **aki a programban jóváhagyja az átvételt** (lásd 6. fejezet).

### Kiadás vagy bevétel — fontos különbség

| Irány | Mikor használja? |
|---|---|
| **Értéktár → Pénztáros** | Pénztárosnak ad valutát/forintot |
| **Pénztáros → Értéktár** | Pénztárostól kap vissza |

A program a választott irány alapján automatikusan a megfelelő készlet-oldalt frissíti.

---

## 6. A pénztárosi átvétel jóváhagyása

> Az átadás csak akkor **véglegesedik**, ha a pénztáros az ő gépén jóváhagyja az átvételt. Addig **„függőben"** állapotban marad.

### Mit lát a képernyőn

**Bal oldali menü → „Átadás-átvétel"** képernyő, az **átadások listáján**:

- **Zöld pipa** = a pénztáros jóváhagyta, a tranzakció lezárult.
- **Sárga óra ikon** = függőben, a pénztáros még nem hagyta jóvá.
- **Piros felkiáltójel** = elutasítva (a pénztáros valami eltérést talált).

### Mit tegyen, ha a pénztáros elutasítja?

1. Kattintson a sorra → megjelenik a részletes nézet az elutasítás indokával.
2. Egyeztessen személyesen a pénztárossal (pl. címlet eltérés, plomba sérült).
3. Ha valódi eltérés van, készítsen egy **új átadás-átvételt** a korrekt adatokkal, és vonja vissza az eredetit (kattintson a **„Sztornó"** gombra a régi tételen).

### Saját átvétel jóváhagyása (pénztáros → értéktár irányban)

Ha egy pénztáros leadott valutát az értéktárba, a tételen Ön a fogadó fél:

1. A **„Pénztáros → Értéktár"** sorra kattintson.
2. Ellenőrizze a fizikai csomagot (címlet, darabszám, plomba).
3. Ha minden rendben, kattintson a **„Jóváhagyás"** gombra.
4. Ha eltérés van, kattintson az **„Elutasítás"** gombra, és írjon be indoklást (kötelező).

---

## 7. Bank tranzakciók — bank ↔ értéktár

> Amikor az értéktár pénzt küld a banknak (felesleges készlet leadása), vagy a banktól pénzt vesz át (utánpótlás).

### Bank → Értéktár (banktól érkező pénz)

1. **Bal oldali menü → „Átadás bank / másik értéktár"**.
2. **„Új tranzakció"** gomb.
3. Az űrlapon:
   - **Forrás:** „Bank" (fix).
   - **Cél:** „Értéktár" (saját irodája).
   - **Banki referencia:** a bank által adott bizonylatszám (pl. SWIFT, megbízás-szám).
   - **Tételek:** valuta + összeg (több sor lehet).
   - **Címletezés:** soronként a beérkezett címletek darabszáma.
   - **Plomba szám:** a banktól kapott zacskó/zsák plombája.
4. **„Rögzítés"** gomb → a tétel megjelenik az értéktári készletben.

### Értéktár → Bank (felesleg leadása a banknak)

1. **„Új tranzakció"** gomb.
2. **Forrás:** „Értéktár" (Ön).
3. **Cél:** „Bank" (válassza ki a céges bankszámlát a listából).
4. Tételek + címletezés + plomba szám.
5. **„Mentés és nyomtatás"** → készül egy banki feladás-jegy.
6. A bizonylatot a bankári kifizetéssel együtt át kell adni.

### Mit lát a banki tranzakciók listáján?

A képernyő alsó felében az aznapi banki tranzakciók listája:

- **Dátum**, **Forrás → Cél**, **Összeg**, **Plomba**, **Státusz**.
- Státuszok: `KÜLDVE`, `BANKBA ÉRKEZETT`, `JÓVÁÍRVA`.

---

## 8. Szállítólevelek — másik értéktár, vagy bank felé

> Ha a saját irodán **kívülre** ad át (másik telephely értéktárába, vagy bankba), egy **szállítólevél** is keletkezik.

### Lépésről-lépésre

1. **Bal oldali menü → „Szállítólevelek"**.
2. **„Új szállítólevél"** gomb.
3. Az űrlapon:
   - **Cél:** célállomás (másik iroda kódja, vagy bank neve).
   - **Tételek:** soronként valuta + összeg + plomba szám.
   - **Szállító személy:** ki viszi (név, igazolvány-szám).
   - **Kísérő dokumentumok:** ha az értékszállító cég bizonylatot adott.
4. **„Mentés és nyomtatás"** gomb → 3 példány nyomtatódik:
   - **Feladó** (értéktár, marad Önnél).
   - **Címzett** (a fogadó értéktár / bank).
   - **Szállító** (az értékszállító cégnek).
5. Mindhárom példányt **alá kell írni** a szállítóval együtt.

### Mit látnak az úton lévő csomagok között?

**„Úton lévő csomagok"** menüben az összes olyan szállítólevél, ami már elindult, de a fogadó még nem igazolta vissza. Ha egy csomag napokig itt marad, hívja a célállomást és tisztázza, miért nem érkezett meg.

---

## 9. Naplókönyv — minden mozgás története

**Bal oldali menü → „Naplókönyv"**.

Ez egy **kronologikus napló** az iroda összes pénzmozgásáról:

- Pénztárosok vételei és eladásai (összesítve naponta).
- Átadás-átvételek (pénztárosokkal).
- Bank tranzakciók.
- Szállítólevelek.
- Sztornók.

### Szűrési lehetőségek

A képernyő tetején:

- **Dátumtól-dátumig** szűrő.
- **Mozgástípus** szűrő (átadás, bank, szállítólevél stb.).
- **Pénztáros** szűrő (csak az adott pénztáros tételei).
- **Valuta** szűrő (csak az adott valuta).

### Export

A jobb felső sarokban egy **„Export Excel"** vagy **„Export PDF"** gomb. A szűrt adatokat egy fájlba mentheti — pl. ha a könyvelő, a bel-ellenőr vagy a vezető kéri.

---

## 10. Címletezés

> Ugyanúgy, mint a pénztárosnak, az értéktárosnak is naponta többször kell címleteznie.

### Mikor használja?

- Napnyitáskor (a kezdő készlet ellenőrzése).
- Átadás-átvétel közben (mind a kiadáskor, mind a bevételkor a fizikai pénz pontos felsorolása).
- Banki tranzakciónál (a bankjegy-zsákok tartalma).
- Napi és havi zárásnál.

### Lépésről-lépésre

1. **Bal oldali menü → „Címletezés"** (ha külön elérhető) vagy az adott művelet űrlapján belül a „Címletezés" szakasz.
2. **Mit lát a képernyőn:** egy táblázat csökkenő sorrendben (HUF: 20 000 → 5 Ft, EUR: 500 → 5 EUR, USD: 100 → 1 USD).
3. Minden címlethez írja be a darabszámot.
4. A program kiszámolja a részösszeget és az összesítést.
5. **„Mentés"**.

### Tipp

Ha az értéktárban több ezer bankjegyet kell címletezni, használjon **bankjegyszámláló gépet**. A program elfogadja, ha közvetlenül a számlálóból olvassa be az összeget (ha ez a funkció be van állítva).

---

## 11. Napi zárás (esti zárás)

> **A nap végén, MIUTÁN minden pénztáros napzárása lefutott**, az értéktárosnak az iroda szintű zárást kell elvégeznie.

### Mit csinál a napi zárás?

- Összesíti az iroda összes pénztárosának napi forgalmát.
- Az értéktár saját készletét is lezárja.
- Felkészíti az iroda **másnapi nyitókészletét** (az esti záró készlet lesz a holnapi nyitó).
- Csomagokat készít elő a banki feladásra (ha kell).

### Lépésről-lépésre

1. **Bal oldali menü → „Napi zárás"**.
2. **Mit lát a képernyőn:**
   - **Dátum** mező (alapértelmezésben a mai nap).
   - **„Előnézet betöltése"** gomb.
3. Kattintson az **„Előnézet betöltése"** gombra.
4. A program megjelenít egy összefoglalót:
   - **Iroda neve**, **dátum**, **státusz** (`NOT_STARTED` / `PREVIEW` / `SENT` / `CONFIRMED`).
   - **Készlet-egyenlegek** valutánként, címletezve.
   - **Tranzakciók száma**, **vétel összesen HUF**, **eladás összesen HUF**.
   - **Még nem szinkronizált tételek** (pendingSyncs) — ha > 0, várja meg, amíg minden szinkronizál.
   - **Nyitott foglalások** — ha vannak, érdemes lezárni őket.
   - **Csomagok listája** — amit a banknak el kell küldeni.
   - **Figyelmeztetések** (warnings) — pl. „címlet eltérés", „pénztáros nem zárt".
5. Ha **figyelmeztetés van**, ellenőrizze őket. Ha mégis zár (pl. pénztáros napzárása másnap következik), a program rákérdez: **„X figyelmeztetés van. Biztosan elküldi az esti zárást?"**.
6. **„Esti zárás küldése"** gomb.
7. A program elküldi az adatokat a központba (országos értéktár / főértéktár), majd a státusz `SENT`-re vált.
8. Amikor a központ visszaigazolja, a státusz `CONFIRMED` lesz.

### Ha figyelmeztetést kap

**Ne lépjen át rajta**, ellenőrizze:

- Pénztáros nem zárt → szóljon a pénztárosnak, fejezzétek be együtt.
- Címlet eltérés → keresse meg, mi nem stimmel a címletezésben.
- Nyitott csomag → fogadja vagy küldje tovább.

Csak akkor küldje el a zárást, ha minden tisztázódott.

---

## 12. Havi zárás

> **A hónap utolsó munkanapján**, az esti zárás után az iroda **havi zárását** is el kell végezni.

### Lépésről-lépésre

1. **Bal oldali menü → „Havi zárás"**.
2. **Mit lát a képernyőn:** a hónap napjainak listája, az esti zárások státuszával.
3. Ellenőrizze, hogy **MINDEN nap esti zárása** `CONFIRMED` (vagy zöld) státuszú.
4. Ha valamelyik nap pirossal van jelezve, az adott napot újra kell ellenőrizni — hívja a vezetőjét.
5. Ha minden zöld, kattintson a **„Havi zárás véglegesítése"** gombra.
6. A program legenerálja a **havi adatokat a könyveléshez** — ezt a központi főértéktár fogadja.

### Ha hibát kap

- **„Nincs minden nap lezárva"** → keresse meg a piros napot, és előbb azt zárja le.
- **„Az árfolyam-történet hiányos"** → a központi főértéktárosnak kell pótolnia. Hívja a vezetőjét.

---

## 13. Mit tegyen, ha hibát kap

### Általános szabály

> **Ne nyúljon műszaki dolgokhoz.** Ne futtasson parancsot, ne nyisson rendszerablakot, ne szerkesszen fájlt.

### Gyakori üzenetek

| Üzenet | Mi történt? | Mit tegyen? |
|---|---|---|
| **„Network Error" / „Hálózati hiba"** | A szerver pillanatnyilag nem elérhető | A program **automatikusan újrapróbálkozik 3-szor**. Várjon. Ha tartós, hívja a vezetőjét. |
| **„Nyitott függő átadás van"** | Egy pénztárosnál van még jóvá nem hagyott átadás | Egyeztessen a pénztárossal, ő hagyja jóvá az ő gépén. |
| **„A pénztári készlet eltér az értéktártól"** | A nyilvántartás és a tényleges állomány nem egyezik | Ellenőrizze a címletezést, hívja a vezetőjét, ha tartós eltérés. |
| **„Plomba szám már használva"** | Egy plomba sorszámot kétszer adott be | Vegyen elő új plombát, írja be a sorszámát. Soha NE adjon be egy plombát kétszer. |
| **„Nincs aktív árfolyam"** | A főértéktáros még nem közzétette a mai árfolyamot | Hívja a főértéktárost. Tranzakciókat addig NE rögzítsen, mert lejárt árfolyammal nem lehet. |
| **„A nap nincs megnyitva"** | Az iroda napja még nem indult | Először a napnyitást kell elvégezni. |

### Mikor hívja a vezetőjét?

- Bármilyen üzenet, amit nem ért.
- Ha egy átadás-átvétel státusza órákig „függőben" marad.
- Ha az árfolyam nem érkezik meg napnyitáskor.
- Ha a banki tranzakcióhoz hibás bizonylatot kapott.
- Ha a havi zárás nem indul el.
- Ha a program lefagyott vagy lassan reagál.
- Ha a kassza-állomány eltér a programétól.

---

**Verzió:** 1.0 (2026-05-06)
**Készült:** Valutaváltó ERP v2.5.x
**Hatáskör:** értéktáros kollégák
