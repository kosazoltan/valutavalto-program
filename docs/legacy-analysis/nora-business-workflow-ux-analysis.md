# Legacy Delphi — Pénztáros Napi Üzleti Folyamat & Felhasználói Élmény Elemzés

## 1. Pénztáros Napi Workflow Rekonstrukció (Legacy Delphi 7)

**Tipikus napi folyamat:**

1. **Nap nyitás**: A pénztáros nap kezdetekor indítja a rendszert és végrehajtja a "napi nyitás" funkciót.
    - Fő DFM: VALUTA\DLL\NAPIKEZD\MAKEDLL\Unit2.dfm
    - Ellenőrzi a napzárások állapotát, bejelentkezés/jogosultság után aktiválható
2. **Árfolyam lekérdezés / módosítás**:
    - Árfolyamok betöltése, szükség esetén módosítása
    - Fő DFM: VALUTA\DLL\ESTIZAR\MAKEDLL\Unit2.dfm, IBVALTO\UNIT1.DFM
3. **Tranzakciók**:
    - Eladás/Vásárlás ablakok: egyedi devizaügyletek rögzítése, automatikus ellenőrzések
    - Fő DFM: ELADAS/Unit2.dfm, VASARLAS/Unit2.dfm, FOGLALO/Unit2.dfm, STORNO/Unit2.dfm
    - Ügyféladat bekérés 300e Ft felett (GDPR + jogszabály)
4. **Címlet felvétel/bevitel**:
    - Aktuális címletállomány rögzítése, ellenőrzés visszaváltás zárás előtt
    - Fő DFM: CIMLET/Unit2.dfm
5. **Zárás**:
    - "Napzárás" funkció, státuszok, bizonylatok előkészítése
    - Fő DFM: NAPZAR/Unit2.dfm
    - Automatikus blokk generálás, hibakezelés/hiánylisták
6. **Bizonylat-nyomtatás**:
    - Blokknyomtató kezelés, visszaigazolás, adóhatósági megfelelés
    - Fő DFM: BLOKNYOM/Unit2.dfm

**Kritikus pontok, amik a workflow-ban elérhetőek voltak:**
- Egylépéses, modális ablakok minden tranzakcióhoz
- Műveletek időzítése: csak nap elején/záráskor elérhető funkciók
- Minden művelethez saját form (ablak) — nincs központi "dashboard"

## 2. Legacy UI Elemzés — 10 Fő DFM (Form) Jellemzői

**Áttekintett fő ablakok:**
1. **Napindító (NAPIKEZD, Unit2.dfm)**: Egyszerű dialóg, napnyitás megerősítése.
2. **Esti zárás (ESTIZAR, Unit2.dfm)**: Árfolyamzárás, utolsó frissítési lehetőség.
3. **Eladás (ELADAS, Unit2.dfm)**: Összetett, de modális GUI, bal oldalon ügyféladatok, jobb oldalon címletlista, tranzakció összeg, gombok: Mentés, Storno.
4. **Vásárlás (VASARLAS, Unit2.dfm)**: Eladáshoz hasonló, szerepcserés mezőkkel.
5. **Címlet (CIMLET, Unit2.dfm)**: Dinamikus táblázat, minden címlet mező saját TEdit komponens.
6. **Storno (STORNO, Unit2.dfm)**: Korábbi tranzakció keresése, törlés, módosítás.
7. **Foglaló (FOGLALO, Unit2.dfm)**: Előjegyzések kezelése.
8. **Bizonylat-nyomtatás (BLOKNYOM, Unit2.dfm)**: Utolsó tranzakciók nyomtatása vagy újbóli kiadás.
9. **Ügyfél adatlap (UGYFEL, DEBUG/Unit2.dfm)**: Teljes személyi adat, jogcím és pénznem-választó.
10. **IBVALTO (IBVALTO/UNIT1.DFM)**: Backend kommunikáció, adatfolyam státusz GUI.

**UI Jellemzők:**
- Statikus, kötött elrendezés (fix koordináták)
- Minden fő funkciónak külön ablak
- Színek: szürke, világoskék, System gombok
- Több dialóg csak jelszó után vagy jogosultság esetén érhető el
- Hibák modális popup-ban (ShowMessage)
- Komponensnevek: TEdit, TButton, TLabel, TComboBox dominancia

## 3. Modern UX (React/Electron) — Fő Elek

**Frontend forrás:** frontend-react/src/, penztar-client/

**Modern workflow főbb jellemzők:**
- **Dashboard-alapú ELK:** Egy főoldali dashboard-ról minden fő funkció elérhető
- **Több tranzakciós ablak egyben**: Eladás, vásárlás, storno, foglaló tabként/szekcióként (nem külön modális formban)
- **Árfolyamok élőben**: Automatikus, háttérben frissülő árfolyam kijelzés
- **Intuitív vizuális visszajelzés**: Tranzakció siker/hibák színes, várakozó állapot, loader animációk
- **Responsív dizájn**: Mobil, asztali, tablet layout támogatás
- **Jogosultság/rol-alapú elérés**: Admin/pénztáros/üzletvezető szerephez kötött page-k, sokkal finomabb jogosultsági mátrix
- **Bizonylat letöltés PDF-ben, visszakereshető tranzakciók**
- **Elektron: nyomtatás közvetlenül, értesítési ablakok, kompakt zárási flow**

**React/TS page-ek főbb példái:**
- Home.tsx (dashboard)
- TransactionsPage.tsx
- ExchangeRatesPage.tsx
- DenominationPage.tsx
- DayOpeningPage.tsx
- DayClosingPage.tsx
- ReceiptPrintModal.tsx
- ClientProfileModal.tsx
- LoginPage.tsx

**UX előnyök:**
- Átláthatóbb, kevesebb modal ablak
- Egységes vizuális nyelv, friss színpaletta, modern betűstílus
- Hibatűrőbb (undo, visszavonás, automata mentések)
- Kontextusos súgó / információk

## 4. Workflow Gap-ek & Hiányok

- **Legacy:**
    - Nincs központi dashboard/napi státusz összefoglaló
    - Funkciók szigorúan időzítve/lefagyasztva (napnyitás, zárás), rugalmatlanság
    - Hibakezelés csak modális popup, automata naplózás hiányzik
    - Jogosultság túl bináris (admin vagy pénztáros)
    - Státuszjelző animációk, vizuális progress feedback hiánya
    - Elavult beviteli mezők (nem context-aware, pl. címletnél)
- **Modern:**
    - Néhány legacy funkció (pl. előjegyzés/foglaló, napi csv export) hiányzik vagy más néven
    - Elektron-nyomtatás nem mindig stabil, múltbeli tranzakció újranyomtatása extra lépés
    - Bizonylattervezés: jogszabályi header/footer testreszabás hiányos

## 5. Javaslatok a penztar-client Electron fejlesztéséhez

1. **Központi "Napi státusz" dashboard azonnali állapottal (nyitott/zárt nap, utolsó tranzakció, készpénzállomány)**
2. **Címletkezelő UX erősítése**: Táblázatos/drag-and-drop felület, billentyűkiosztás optimalizáció
3. **Jogosultság-mátrix finomítása**: Többszintű admin/pénztáros/üzletvezető
4. **Hibakezelés**: Kontextusos, nem modális értesítések, automata naplózás
5. **Bizonylat-nyomtatás pipeline hardening**: Hibás/hiányzó nyomtatások detektálása, újrapróbálkozás, státuszornamentika
6. **Előjegyzés/foglaló workflow integráció vagy modernizáció**: Ügyféloldali emlékeztető, státusz tracking
7. **Árfolyam/jogcím naplózás, gomb-léptető automata**

---

**Dátum:** 2026-04-05
**Készítette:** Nóra (OpenAI GPT-5.3, audit: Junior)
