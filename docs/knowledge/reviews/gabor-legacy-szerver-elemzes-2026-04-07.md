# Gábor (Design & UX) — Legacy Delphi VCL Kódbázis Elemzés

## 1. Helyzetkép és Vizuális Architektúra

A `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\` alatt található legacy Delphi 7 kód egy klasszikus, 90-es/2000-es évek eleji vastagkliens (VCL) UI architektúrát tükröz. A vizuális megjelenítés és a formok felépítése erősen kötött.

### Megfigyelések (VCL `.dfm` és `.pas` fájlok alapján)
*   **Abszolút Pozicionálás:** A komponensek (gombok, beviteli mezők, grid-ek) X/Y koordinátákkal és fix szélességgel/magassággal (Width/Height) vannak lehorgonyozva. Nincs valódi reszponzivitás (responsive design). Képernyőfelbontás-váltásnál a formok vagy torzulnak, vagy irreális üres területek keletkeznek.
*   **Monolitikus UI:** A logika és a prezentáció szorosan össze van kötve (`FormCreate`, `ButtonClick` eseménykezelőkben közvetlen adatbázis hívások). A nézetek nem újrafelhasználhatóak.
*   **Vizuális Hierarchia:** Tipikus MDI (Multiple Document Interface) vagy modális ablakrengeteg, amely megszakítja a felhasználói folyamatot (workflow).
*   **Színek és Tipográfia:** Rendszerfüggő (OS-szintű) színek és betűtípusok (pl. `clBtnFace`, `MS Sans Serif`). Nincs egységes Design System vagy téma (Theme) támogatás.

## 2. UX és Használhatósági Problémák (Pain Points)

*   **Kognitív Túlterhelés:** A régi UI-ok jellemzően "minden adatot egy képernyőre" elvet követték. A grid-ek és mezők sűrűsége megnehezíti a fókuszálást az érdemi tranzakcióra.
*   **Modális Pokol:** Hibajelzések, megerősítések, és al-folyamatok (pl. címletválasztás, ügyfél-azonosítás) mind felugró ablakokat használnak, megakasztva a gyors (power-user) munkavégzést.
*   **Hozzáférhetőség (Accessibility - a11y):** Semmilyen modern a11y szabványnak (WCAG) nem felel meg. Nincsenek szemantikus címkék, a kontrasztarányok az operációs rendszertől függnek.
*   **Navigáció:** A menüstruktúrák túlzsúfoltak, hiányzik a modern "keresés-vezérelt" (search-first) vagy parancs-alapú (Command Palette) navigáció.

## 3. Irányelvek a Modernizációhoz (React + Electron)

A migráció során nem szabad a régi UI-t egy-az-egyben (pixel-perfect) átmásolni. Az új rendszernek az alábbi Design és UX alapelvekre kell épülnie:

### 1. Komponens-alapú Design System
*   **Zárt vizuális keret:** Taildwind CSS vagy egy modern UI könyvtár (pl. Shadcn/ui, MUI) használata.
*   **Újrafelhasználhatóság:** Az input mezőknek, táblázatoknak (DataGrid), és gomboknak egységes állapotai (hover, focus, disabled, error) kell legyenek.

### 2. Reszponzív és Áramló (Fluid) Layout
*   Bár az Electron app asztali környezetben fut, flexbox és CSS grid alapú elrendezéseket kell alkalmazni, hogy az ablak átméretezésekor a tartalom dinamikusan alkalmazkodjon. 

### 3. "Power-User" Elsőkörös (Keyboard-First) Interakció
*   A valutaváltó pénztárosoknak gyorsan kell dolgozniuk. A modális ablakokat (Alert, Confirm) értesítési sávokra (Toasts/Snackbars) vagy in-line validációra kell cserélni.
*   Minden fő tranzakciónak billentyűkombinációval (Shortcut) elérhetőnek kell lennie.

### 4. Állapotkezelés (State Management) Szétválasztása
*   A UI-nak pusztán reagálnia kell az állapotra (React). A szerver logika (ami eddig a `.pas` fájlokban volt) egy tiszta API réteg mögé (Java Spring Boot vagy Node.js) kell kerüljön.

## 4. Összegzés a Tervezés Szemszögéből

A legacy kódbázis vizuális szempontból egy "technikai adósság". A feladat nem a régi formok újraalkotása, hanem a mögöttük meghúzódó **üzleti folyamatok** megértése, és azok öntése egy modern, tiszta, fókuszált felhasználói felületbe. A tervezés fókuszában a sebesség, az átláthatóság, és az adatbeviteli hibák minimalizálása kell álljon.
