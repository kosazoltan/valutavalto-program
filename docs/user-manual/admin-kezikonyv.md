# Adminisztrátor / Ügyvezető kézikönyv — Valutaváltó program

> Ez a kézikönyv az **iroda-** és **cégszintű vezetőknek** (ügyvezető, irodavezető, irodai dolgozó, főértéktáros) készült. A weboldali (böngészős) admin felületen érhető el — `https://excvaluta.com` címen.
> Ha bármi nem úgy működik, ahogy itt le van írva, **forduljon az IT csapathoz** — ne nyúljon műszaki beállításokhoz, fájlokhoz, parancssorhoz.

---

## Tartalom

1. [Bejelentkezés a böngészős admin felületre](#1-bejelentkezés-a-böngészős-admin-felületre)
2. [A főképernyő (Irányítópult)](#2-a-főképernyő-irányítópult)
3. [Dolgozók kezelése](#3-dolgozók-kezelése)
4. [Engedélyek menü — hatósági / üzleti engedélyek](#4-engedélyek-menü--hatósági--üzleti-engedélyek)
5. [Rendszerbeállítások (system parameters)](#5-rendszerbeállítások-system-parameters)
6. [Jogosultság mátrix — ki mit lát és mit tehet](#6-jogosultság-mátrix--ki-mit-lát-és-mit-tehet)
7. [Új iroda létrehozása](#7-új-iroda-létrehozása)
8. [Árfolyamok kezelése (csak főértéktár / ügyvezető)](#8-árfolyamok-kezelése-csak-főértéktár--ügyvezető)
9. [MNB jelentések](#9-mnb-jelentések)
10. [AML / Compliance Dashboard](#10-aml--compliance-dashboard)
11. [Audit napló](#11-audit-napló)
12. [Telepítő küldése új gépre](#12-telepítő-küldése-új-gépre)
13. [Mit tegyen, ha hibát kap](#13-mit-tegyen-ha-hibát-kap)

---

## 1. Bejelentkezés a böngészős admin felületre

### Belépés

1. Nyissa meg a **Google Chrome** vagy **Microsoft Edge** böngészőt.
2. Címsorba: `https://excvaluta.com`.
3. A bejelentkezési ablak ugyanúgy működik, mint a pénztári klienseké:
   - **Cégkód:** `EBC` (vagy a saját cég kódja).
   - **Felhasználói kód:** az Ön azonosítója.
   - **Jelszó:** legalább 8 karakter.
4. **Bejelentkezés** gomb (vagy Google fiókkal, ha be van állítva a céges domain-en).

### Szerep-választás (több szerep esetén)

Ha Önnek több szerepköre van (pl. ügyvezető **és** főértéktáros), a bejelentkezés után egy ablak nyílik meg, ahol válasszon, **mely szerepkörrel jelentkezik be most**. Ezt a kiválasztást a kijelentkezésig megtartja.

### Mit lát a bejelentkezés után

A baloldali menüben (sidebar) az Ön szerepkörének megfelelő funkciók jelennek meg. Egy **ügyvezető** mindent lát; egy **irodavezető** csak az iroda-szintű funkciókat.

---

## 2. A főképernyő (Irányítópult)

**Bal oldali menü → „Főoldal" → „Irányítópult"**.

A dashboard megmutatja:

- **Mai forgalom** — vétel és eladás összesítve, HUF-ban.
- **Aktív irodák száma** — épp most nyitva tartó irodák.
- **Riasztások** — pl. „Az ESET TLS proxy 3 irodán fennakadást okozott", „MNB jelentés még nem küldve".
- **Heti grafikon** — az elmúlt 7 nap forgalma, irodánként színezve.
- **AML események** — szankciós találatok, nagy összegű tranzakciók (300 000 Ft + 4 500 000 Ft határok).

### Gyors gombok a főképernyőn

- **Új tranzakció riport indítása** → Riportok menü.
- **Új AML riport** → Compliance Dashboard.
- **Audit napló** → Audit napló menü.

---

## 3. Dolgozók kezelése

### Két menüpont a hasonló célra

A program két, **egymáshoz közeli, de különálló** dolgozó-menüt használ:

| Menüpont | Mire való? |
|---|---|
| **Dolgozók** | Operatív dolgozó-lista — itt veszi fel és törli az operatív munkavállalókat (pénztáros, értéktáros stb.). |
| **HR (munkavállalók)** | Bővített HR-adatlap — születési idő, lakcím, TAJ, munkaszerződés, fizetési adatok stb. (csak HR-felelős számára). |

### 3.1 Új munkavállaló felvétele

1. **Bal oldali menü → „Adminisztráció" → „Dolgozók"**.
2. **Mit lát a képernyőn:** lista az összes aktív dolgozóról + egy **„Új dolgozó"** gomb a jobb felső sarokban.
3. Kattintson az **„Új dolgozó"** gombra.
4. Az űrlapon töltse ki:
   - **Felhasználói kód** (egyedi, pl. `KOVACS_E`) — később ezzel jelentkezik be.
   - **Teljes név** (pl. `Kovács Erzsébet`).
   - **E-mail cím** (a jelszó-visszaállítás miatt fontos).
   - **Iroda** (legördülő listából — ahova szervezetileg tartozik).
   - **Szerepkör** (legördülő listából — pl. „Pénztáros", „Értéktáros").
   - **Kezdő jelszó** (legalább 8 karakter, a dolgozó az első bejelentkezéskor megváltoztatja).
5. **„Mentés"** gomb.
6. A dolgozó megjelenik a listában, **„AKTÍV"** státusszal.

### 3.2 Több szerepkör hozzárendelése

Egy dolgozónak több szerepköre is lehet (pl. értéktáros + irodavezető):

1. Kattintson a dolgozó sorára → részletes nézet.
2. **„Szerepkörök"** szakaszban kattintson a **„+"** gombra.
3. Válassza ki az új szerepkört a listából.
4. **„Mentés"**.

A dolgozó a következő bejelentkezéskor választhat, melyik szerepkörrel jelentkezik be.

### 3.3 Dolgozó deaktiválása

> **NE törölje a dolgozót**, csak deaktiválja — különben elveszik a hozzá tartozó tranzakció-történet.

1. Kattintson a dolgozó sorára → részletes nézet.
2. Jobb felső sarokban **„Deaktiválás"** gomb.
3. A program rákérdez: **„Biztosan deaktiválja [Név] dolgozót? Onnantól nem tud bejelentkezni."**
4. **„Megerősítés"**.
5. A dolgozó státusza **„DEAKTIVÁLT"** lesz, a listából egy szűrővel kapcsolható ki/be.

### 3.4 Jelszó visszaállítása

Ha egy dolgozó elfelejtette a jelszavát:

1. A dolgozó sorára kattintva → **„Jelszó visszaállítása"** gomb.
2. A program egy egyszer használatos kódot küld a dolgozó e-mail címére.
3. Másik lehetőség: kézi jelszó beállítása — kattintson **„Új jelszó beállítása"** gombra, írjon be egy ideiglenes jelszót, és adja át személyesen.

---

## 4. Engedélyek menü — hatósági / üzleti engedélyek

> **„Engedélyek"** = az iroda működéséhez szükséges **hatósági engedélyek** nyilvántartása (pl. MNB engedély, NAV regisztráció, AML auditok).

### Mit lát a képernyőn

**Bal oldali menü → „Adminisztráció" → „Engedélyek"**.

Egy táblázat:

- **Engedély típusa** (MNB, NAV, AML, helyhatósági stb.).
- **Iroda** — melyik telephelyre vonatkozik.
- **Kezdő dátum**, **Lejárati dátum**.
- **Státusz** (Aktív, Lejárt, Hiányzik).
- **Csatolt dokumentum** — letölthető PDF.

### Új engedély rögzítése

1. **„Új engedély"** gomb.
2. Az űrlapon:
   - **Engedély típusa** (legördülő listából).
   - **Iroda** (kiválasztás).
   - **Engedélyszám** (a hatóság által adott).
   - **Kezdő dátum**, **Lejárati dátum**.
   - **Csatolmány feltöltése** — kattintson a **„Tallózás"** gombra, válassza ki a PDF-et.
3. **„Mentés"**.

### Lejáró engedélyek

A program **automatikusan figyelmezteti** Önt 30, 14, 7 nappal a lejárat előtt — egy piros sáv jelenik meg a dashboardon. Időben intézze az engedély-megújítást.

---

## 5. Rendszerbeállítások (system parameters)

> **Csak az ügyvezető szerepkörrel láthatja és változtathatja.** Ezek olyan beállítások, amik a teljes céget érintik.

### Mit lát a képernyőn

**Bal oldali menü → „Adminisztráció" → „Rendszerbeállítások"**.

Egy beállítás-lista, kategóriákra bontva:

- **Általános:** cégnév, ÁFA-szám, alapértelmezett valuta (HUF), nyelvek.
- **AML:** az egyszerűsített / teljes azonosítás határértékei (alapértelmezett: 300 000 Ft és 4 500 000 Ft).
- **Árfolyam:** árfolyam-frissesség TTL (alapértelmezett: 24 óra), árfolyam publikálás időablaka.
- **Bizonylat:** bizonylat-számozás formátuma, lábléc szövege, fejléc logó.
- **NAV / MNB:** API kulcsok (csak nézet, nem szerkeszthető a felületen — a IT csapat állítja be).
- **E-mail:** értesítési címek (pl. AML értesítés, lejárt engedély értesítés).

### Egy beállítás módosítása

1. Kattintson a beállítás sorára.
2. Egy szerkesztő ablak nyílik meg.
3. Írja át az értéket, kattintson **„Mentés"** gombra.
4. A program **kérdez**: „Biztosan módosítja a [beállítás neve] értékét?". Erősítse meg.
5. A módosítás **azonnal** életbe lép (de nem tranzakciók közben — a már megnyitott napon a régi érték érvényes).

### Tipp

**Ne kísérletezzen**. A rendszerbeállítások közvetlenül hatnak a forgalomra. Ha bizonytalan, **ne módosítson semmit** — kérdezze az IT-t vagy a könyvelőt.

---

## 6. Jogosultság mátrix — ki mit lát és mit tehet

> A **jogosultság mátrix** mondja meg, hogy egy adott szerepkör (pénztáros, értéktáros, irodavezető stb.) **melyik menüpontokat** látja, és **milyen műveleteket** végezhet.

### Mit lát a képernyőn

**Bal oldali menü → „Adminisztráció" → „Jogosultság mátrix"**.

Egy nagy táblázat:

- **Sorok:** a rendszer összes funkciója (pl. „Vétel rögzítése", „Sztornó", „Napzárás", „Új dolgozó", „MNB jelentés letöltése").
- **Oszlopok:** a szerepkörök (pénztáros, értéktáros, irodavezető, ügyvezető, főértéktáros, belső ellenőr stb.).
- **Cellák:** zöld pipa = engedélyezve, piros X = tiltva.

### Egy jogosultság módosítása

1. Kattintson a kívánt cellára.
2. A pipa zöldről pirosra (vagy fordítva) vált.
3. **„Mentés"** gomb a tetején — addig nem véglegesedik.
4. A program rákérdez: **„Biztosan módosítja a jogosultság mátrixot? Az érintett dolgozóknak újra be kell jelentkezniük."**
5. Megerősítés után a változás **a következő bejelentkezéstől** él.

### Fontos

> **Ne vegye el az ügyvezetőtől a Rendszerbeállítások jogosultságot** — különben senki sem fogja tudni visszaállítani! A program védi az ügyvezetőt egy ilyen lépéstől, de óvatosan.

---

## 7. Új iroda létrehozása

> Ha egy új telephely nyílik meg (pl. új város), létre kell hozni az irodát a rendszerben **MIELŐTT** odaküldené a telepítőt.

### Lépésről-lépésre

1. **Bal oldali menü → „Adminisztráció" → „Rendszerbeállítások"** → **„Irodák"** alfül (vagy „Branches", a felülettől függően).
2. **„Új iroda"** gomb.
3. Az űrlapon:
   - **Iroda kód** (egyedi, pl. `BR042` vagy `KORUT`) — később a szervergépek és a kassza-eszközök ezzel azonosítják magukat.
   - **Iroda neve** (pl. `Szeged Korut`).
   - **Város**.
   - **Cím** (utca, házszám).
   - **Iroda vezető** (legördülő listából — egy meglévő dolgozó).
   - **Operatív státusz** (`AKTÍV` / `INAKTÍV`).
   - **Csak értéktár-mód?** — ha az iroda **csak értéktárként** működik (pénztár nincs), pipálja be ezt a checkbox-ot. (v2.5.1 új funkció.)
4. **„Mentés"**.

### Az iroda megjelenése

Az iroda azonnal megjelenik a többi képernyőn (dashboard, riportok, jogosultság-mátrix), és **a Pénztár kliens telepítője a Setup Wizard 2. lépésén automatikusan felkínálja** az új irodát a 60-as listában.

---

## 8. Árfolyamok kezelése (csak főértéktár / ügyvezető)

> **A főértéktáros felelős a napi árfolyamok elkészítéséért és publikálásáért.** A többi szerepkör csak nézheti.

### 8.1 Árfolyam készítés

1. **Bal oldali menü → „Főértéktár" → „Árfolyam készítés"**.
2. **Mit lát a képernyőn:** egy táblázat az összes valutáról.
3. Minden valutához két oszlop:
   - **Vételi árfolyam** (Ön ezen veszi az ügyféltől).
   - **Eladási árfolyam** (Ön ezen adja az ügyfélnek).
4. **Forrás-árfolyamok** segítségként a képernyő tetején (MNB középárfolyam, EBC központi referencia).
5. Töltse ki a vétel és eladás oszlopokat.
6. **„Mentés piszkozatba"** — még nem publikus, csak Ön látja.

### 8.2 Árfolyam publikálás

1. Amikor a piszkozat kész és ellenőrzött:
2. **Bal oldali menü → „Főértéktár" → „Árfolyam publikálás"**.
3. Mit lát a képernyőn: a piszkozat előnézete + egy **„Publikálás"** gomb.
4. **„Publikálás"** gomb → a program rákérdez: **„Biztosan publikálja az árfolyamot? A pénztárosok 10 másodpercen belül elérik."**
5. **Megerősítés** → az árfolyam életbe lép.

### Fontos

- **Naponta minimum egyszer kell árfolyamot publikálni**, különben a pénztárosok lejárt árfolyammal nem tudnak tranzakciót rögzíteni (24 órás TTL).
- Ha egy árfolyam **nagyon eltér** az MNB középárfolyamtól (több mint ±5%), a program figyelmeztetést ad — ellenőrizze, hogy nem írt-e el számot.

### 8.3 Árfolyam történet

**Bal oldali menü → „Árfolyamok" → „Árfolyam történet"**.

Itt visszanézheti a publikált árfolyamokat dátum szerint, exportálhatja Excel-be (pl. könyvelési egyeztetéshez).

---

## 9. MNB jelentések

> A Magyar Nemzeti Bank felé **havi rendszerességgel** be kell adni a forgalom-jelentéseket. Ez a menü generálja le őket.

### Lépésről-lépésre

1. **Bal oldali menü → „Főértéktár" → „MNB jelentések"** (vagy **„Riportok" → „MNB riportok"**).
2. **Mit lát a képernyőn:** egy lista a hónapokról és jelentésekről.
3. A kívánt hónaphoz kattintson a **„Generálás"** gombra.
4. A program kiszámolja az összesítéseket — ez akár 1-2 percig is tarthat.
5. Amikor kész, egy **„Letöltés (XLSX)"** és **„Letöltés (XML)"** gomb jelenik meg.
6. Az **XML** fájlt kell beadni az MNB felületére.

### Fontos

- A jelentést a hónap **lezárása UTÁN** generálja (havi zárás után, lásd Értéktáros kézikönyv 12. fejezet).
- Ha a havi zárás nincs kész, a jelentés hibás lesz vagy nem generálódik.
- A jelentés-XML-t **NEM SZABAD kézzel szerkeszteni** — ha hiba van benne, javítsa a forrásadatokat (pl. egy elfelejtett tranzakció utólagos rögzítését), és generálja újra.

---

## 10. AML / Compliance Dashboard

> Az **AML** = pénzmosás elleni szabályrendszer. A Compliance Dashboard mutatja, hogy az iroda megfelel-e a szabályoknak.

### Mit lát a képernyőn

**Bal oldali menü → „AML / Compliance" → „Compliance Dashboard"**.

A dashboardon:

- **Magas összegű tranzakciók** (4 500 000 Ft felett) — listában, dátum szerint.
- **Szankciós találatok** — ha egy ügyfél lehetséges egyezést mutatott a szankciós listával.
- **Hiányos azonosítások** — tranzakciók, ahol a kötelező adatok hiányoznak.
- **Rendőrségi megkeresések** — beérkezett megkeresések száma, határidők.

### Egy AML eset részletei

1. Kattintson egy sorra → részletes nézet.
2. Látja az ügyfél adatait, a tranzakciót, a pénztárost, a szankciós találat indokát.
3. Akciók a részletes nézetben:
   - **„AML jelentés készítése"** — létrehozza a hivatalos jelentést a NAV/MNB felé.
   - **„Lezárás"** — ha tisztázódott, hogy nem szankciós (pl. névrokon).
   - **„Megjegyzés hozzáadása"** — a Compliance felelős kommentje.

### Szankciós lista (AML)

**Bal oldali menü → „AML / Compliance" → „Szankciós lista (AML)"**.

A program **automatikusan frissíti** az EU és nemzeti szankciós listákat. Itt látja a teljes listát, kereshet név szerint, és ha egy egyezés gyanús, kézzel jelölheti.

### Plomba nyilvántartás

**Bal oldali menü → „AML / Compliance" → „Plomba nyilvántartás"**.

Itt látja az iroda összes plombájának sorszámát, melyik csomaghoz lett használva, mikor.

---

## 11. Audit napló

> Az **audit napló** minden olyan eseményt rögzít, ami a rendszerben történt — bejelentkezések, tranzakciók, beállítás-módosítások, jelszó-cserék.

### Mit lát a képernyőn

**Bal oldali menü → „AML / Compliance" → „Audit napló"**.

Egy hosszú lista:

- **Időpont**, **Felhasználó**, **Esemény típusa**, **Részletek**, **IP cím**, **Kliens** (web / Pénztár kliens / Értéktár kliens).
- **Szűrési lehetőségek:**
  - Dátumtól-dátumig
  - Felhasználó
  - Esemény típusa (pl. „Bejelentkezés", „Sikertelen bejelentkezés", „Tranzakció rögzítve", „Beállítás módosítva")
  - Iroda

### Mire jó az audit napló?

- Ha gyanús tevékenységet (pl. sok sikertelen bejelentkezés egy felhasználónál) észlel.
- Ha egy ügyfél vitatja a tranzakcióját.
- Ha rendőrségi megkeresés érkezik (mit csinált X dolgozó Y nap Z órájában?).
- Ha a könyvelő egy beállítás-módosításra rákérdez.

### Export

A jobb felső sarokban **„Export Excel"** vagy **„Export PDF"** — a szűrt eseményeket fájlba mentheti.

---

## 12. Telepítő küldése új gépre

> Ha egy új gép áll be munkára (pénztáros gép, értéktáros gép), telepítőt kell elküldeni a kollégának.

### Lépésről-lépésre

1. **Készítsen egy új munkavállalót** a 3. fejezet szerint (Dolgozók menü), ha még nincs.
2. **Ellenőrizze az iroda létezését** a 7. fejezet szerint (vagy hozza létre, ha új iroda).
3. **Töltse le a telepítőt:** a vezetők egy közös felhőtárhelyen találják a legfrissebb `.exe` fájlokat:
   - **Penztar-Setup-2.5.x-YYYYMMDD.exe** — a fő telepítő (~280 MB).
   - **Penztar-Eltavolito-2.5.x-YYYYMMDD.exe** — ha eltávolítás szükséges (~60 KB).
4. **Küldje el a kollégának** e-mailen vagy felhőtárhelyről (Google Drive, OneDrive, Wetransfer).
5. **Kísérőlevélben adjon utasítást:**
   - Mentse el a fájlt az asztalra.
   - Dupla-kattintással indítsa.
   - A Windows rákérdez: **„Az alkalmazás módosítást szeretne végezni a számítógépen?"** — kattintson **„Igen"**-re.
   - A telepítés indul, várja meg.
   - A végén megjelenik a **Setup Wizard** — 5 lépés:
     1. **Iroda kiválasztása** a 60 elemes listából.
     2. **Program típusa** (Pénztár / Értéktár / Értékszállító).
     3. **Szerver kapcsolat tesztelése** — kattintson a **„Kapcsolat tesztelése"** gombra (kötelező a továbblépéshez).
     4. **Felhasználó és jelszó** beállítása — válassza ki a kollégát a listából, írjon be egy 8+ karakteres jelszót.
     5. **Telepítés véglegesítése**.
   - Az asztalon megjelennek a **parancsikonok** (pl. `Valuta Pénztár — Éles kliens`).

### Fontos

- A telepítő **automatikusan elvégzi** a DNS cache flush-t, a régi-bundle-eltávolítást, a registry-cleanup-ot, a tűzfal-szabályok hozzáadását.
- A kollégának **NEM kell** parancsot futtatnia, fájlt szerkesztenie, vagy bármilyen műszaki dolgot tennie.
- A kollégának **csak**: dupla-kattintás + UAC „Igen" + esetleg admin jelszó beírása.

### Ha a kolléga hibát kap a telepítés közben

- **„A szerver nem érhető el"** → ellenőrizze az internet-kapcsolatot a kolléga gépén. Ha online, hívja az IT-t.
- **„A felhasználó kód nem található"** → győződjön meg, hogy a Dolgozók menüben felvette-e az illetőt, és hogy az iroda kódja ugyanaz, mint amit a Wizard-ban választott.
- **„Hibás cégkód"** → a Setup Wizard 3. lépésénél a `Cégkód` mezőbe ugyanaz kerül, mint a böngészős admin felületen (`EBC` az alapértelmezett).

---

## 13. Mit tegyen, ha hibát kap

### Általános szabály

> Az adminisztrátor / ügyvezető **nem műszaki szerepkör**. Ne nyúljon szerverhez, fájlhoz, parancssorhoz. Ha a felület hibát ad, **forduljon az IT csapathoz**.

### Gyakori üzenetek

| Üzenet | Mi történt? | Mit tegyen? |
|---|---|---|
| **„Nincs jogosultsága"** | A funkcióhoz a saját szerepköre nem ad engedélyt | Ellenőrizze a Jogosultság mátrixban (vagy másik szerepkörrel jelentkezzen be). |
| **„Hálózati hiba" / „Network Error"** | A szerver pillanatnyilag nem elérhető | Frissítse a böngészőt (F5). Ha tartós, hívja az IT-t. |
| **„A jelszó nem felel meg a követelménynek"** | Túl rövid vagy túl egyszerű | Min. 8 karakter, betű + szám ajánlott. |
| **„A bejelentkezés zárolva"** | Egy dolgozó 3-szor sikertelenül lépett be | Az Audit naplóban nézze meg, ki próbálkozott. Hívja az IT-t a feloldáshoz. |
| **„MNB jelentés generálás sikertelen"** | A havi zárás nincs kész | Ellenőrizze a Havi zárás státuszát az Értéktáros menüben. |
| **„Az iroda nem törölhető, mert tranzakciók kapcsolódnak hozzá"** | A program védi a történetét | Csak deaktiválja az irodát, ne törölje. |

### Mikor hívja az IT-t?

- Bármilyen üzenet, amit nem ért.
- Ha a böngésző fehér / üres oldalt mutat.
- Ha egy dolgozó nem tud bejelentkezni a saját kódjával.
- Ha az MNB jelentés nem generálódik.
- Ha az árfolyam nem publikálódik.
- Ha a Hetzner produktum (`https://excvaluta.com`) elérhetetlen.

### A vállalat IT kapcsolata

- A céges IT kontakt: **a saját céges címlistájuk szerint** (e-mail, telefon).
- Ne küldjön jelszót e-mailben — sem sajátot, sem dolgozóét.

---

**Verzió:** 1.0 (2026-05-06)
**Készült:** Valutaváltó ERP v2.5.x
**Hatáskör:** ügyvezető, irodavezető, irodai dolgozó, főértéktáros
