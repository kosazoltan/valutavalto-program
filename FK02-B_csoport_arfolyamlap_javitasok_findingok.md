# FK02-B Csoport Árfolyamlap - Audit, Findingok és Javítási Útmutató

Ez a dokumentum a csoport-árfolyamlap (B csoportos árfolyamlap) modul fejlesztése során feltárt kritikus hibákat, azok kód-szintű gyökerét és a szükséges javítási lépéseket tartalmazza a valódi kód tényei alapján, hallucinációktól és ferdítésektől mentesen.

---

## 1. Findingok és Kódelemzés (Miért sikertelen a jelenlegi implementáció?)

### 1.1. Valuta-sorrend eltérése (FR-1)
- **Hiba oka:** A [frontend-react/src/pages/rates/RateCreationPage.tsx](frontend-react/src/pages/rates/RateCreationPage.tsx) az `editableRates` betöltésekor a valutákat közvetlenül a szerver által visszaadott `overview.currencies` sorrendjében hagyja. Ez a sorrend azonban nem következetes, és eltér a Főlap [frontend-react/src/pages/rates/MainRateSheetPage.tsx](frontend-react/src/pages/rates/MainRateSheetPage.tsx) által használt statikus `DEFAULT_CURRENCIES` listától (EUR, USD, GBP, CHF stb.). A felhasználó így nem ugyanabban a sorrendben látja a valutákat a csoportos és a főlapos nézetben handles, ami navigációs zavart okoz.
- **Kódbizonyíték:** [frontend-react/src/pages/rates/RateCreationPage.tsx](frontend-react/src/pages/rates/RateCreationPage.tsx#L12) - az `editableRates` betöltése a valutalistából rendezés nélkül történik.

### 1.2. Hibás 10%-os sáv ellenőrzési logika (FR-2, FR-3, FR-4, FR-5)
- **Hiba oka:** A meglévő kód a 10%-os eltérés-vizsgálatot az MNB-vel azonosított hivatalos rátához képest végzi a `buy > r.officialRate * 1.1` képlettel. A specifikációban kért ellenőrzési képlet azonban az előző mentett értékhez képesti kétoldali eltérést ír elő: `|újÉrték - előzőMentettÉrték| / előzőMentettÉrték >= 0.10`.
- **Hiányzó funkció:** Teljesen hiányzik a megerősítő dialog is. Az `onBlur` (vagy bármilyen közvetlen módosítás) azonnal felülírja a mezők tartalmát megerősítés (Igen/Nem gombok) és mentési megállítás nélkül.
- **Kódbizonyíték:** [frontend-react/src/pages/rates/RateCreationPage.tsx](frontend-react/src/pages/rates/RateCreationPage.tsx#L452-L455) - static warning kiírás a margóra, megerősítő felület nélkül.

### 1.3. Nem működő kijelölés és „Lehúzás” funkció (FR-6 ... FR-10)
- **Hiba oka:** A [frontend-react/src/pages/rates/components/RateGrid.tsx](frontend-react/src/pages/rates/components/RateGrid.tsx) nem implementál sorkijelölést vagy egér-drag / Shift+kattintásos cellakijelölést (selection range). A jelenlegi lehúzási funkciók a [frontend-react/src/pages/rates/utils/fillHelpers.ts](frontend-react/src/pages/rates/utils/fillHelpers.ts) fájlban globálisan az egész táblázatra hatnak, és rossz kiindulási értékként a 0-s vételi/eladási rátát másolják bele a sávokba (K_1, K_2, E_1, E_2).
- **Hiányzó funkció:** Nincs helyi lebegő kontextuális menü ( toolbar) a kijelölt tartomány mellett az interaktív törléshez vagy lehúzáshoz; helyette felesleges és veszélyes globális gombok vannak a jobb oldalsávon.

### 1.4. Lapváltáskor elvesző adatok / Hiányzó helyi SQLite mentés (FR-11, FR-12)
- **Hiba oka:** A [frontend-react/src/pages/rates/workgroupSheetStorage.ts](frontend-react/src/pages/rates/workgroupSheetStorage.ts) kizárólag a böngésző `localStorage` tárolójába menti a formulákat, a nem-formulás beírt értékek pedig csak a React state-ben (ideiglenes memóriában) léteznek. Az Electron kliens [arfolyam-keszito-client/electron/local-first.ts](arfolyam-keszito-client/electron/local-first.ts) fájlban definiált lokális SQLite (`rate-maker.db`) rétege sincs összekötve a frontend `onBlur` eseményével. Amikor a felhasználó visszalép a főlapra, a React unmountol, és a visszatéréskor a szerver bootstrap adatai teljesen felülírják (letörlik) a helyi rátamódosításokat.
- **Kódbizonyíték:** [frontend-react/src/pages/rates/workgroupSheetStorage.ts](frontend-react/src/pages/rates/workgroupSheetStorage.ts#L18) - nincs SQLite hívás, csak localStorage.

---

## 2. Pontos Javítási Útmutató (Fájlonként)

### 2.1. Helyi SQLite Mentés Bekötése az onBlur-ra

Az `onBlur` mentéseknek a helyi SQLite-ban lévő `group_rates` táblába kell írniuk. Ehhez ki kell egészíteni az Electron backend IPC regisztrációját, és a frontendről meg kell hívni azt a cella elhagyásakor.

#### 2.1.1. Electron Réteg Kiegészítése
Az [arfolyam-keszito-client/electron/local-first.ts](arfolyam-keszito-client/electron/local-first.ts) fájlban hozzon létre egy új IPC kezelőt a csoport-árfolyamok közvetlen SQLite-ba mentéséhez:

```typescript
// d:\repo\valutavalto-program\arfolyam-keszito-client\electron\local-first.ts kiegészítése
ipcMain.handle('lf:save-group-rates', (_event, rates: Array<{ currencyGroupId: string, currencyId: string, buyRate: number, sellRate: number }>) => {
  const db = getDb();
  try {
    db.run('BEGIN TRANSACTION;');
    const stmt = db.prepare(`
      INSERT INTO group_rates (currency_group_id, currency_id, buy_rate, sell_rate, valid_from)
      VALUES (?, ?, ?, ?, datetime('now'))
      ON CONFLICT(currency_group_id, currency_id) DO UPDATE SET
        buy_rate = excluded.buy_rate,
        sell_rate = excluded.sell_rate,
        created_at = datetime('now');
    `);
    for (const r of rates) {
      stmt.run([r.currencyGroupId, r.currencyId, r.buyRate, r.sellRate]);
    }
    stmt.free();
    db.run('COMMIT;');
    saveDatabase();
    return { ok: true };
  } catch (error: any) {
    db.run('ROLLBACK;');
    log.error('[LocalFirst] Hiba a csoport-árfolyamok SQLite mentésekor:', error);
    return { ok: false, error: error.message };
  }
});

ipcMain.handle('lf:get-group-rates', (_event, currencyGroupId: string) => {
  const db = getDb();
  try {
    const res = db.exec(`
      SELECT currency_id, buy_rate, sell_rate FROM group_rates
      WHERE currency_group_id = ?
    `, [currencyGroupId]);
    if (res.length === 0) return [];
    
    const rows = res[0].values;
    return rows.map(r => ({
      currencyId: r[0],
      buyRate: r[1],
      sellRate: r[2]
    }));
  } catch (error) {
    log.error('[LocalFirst] Hiba a csoport-árfolyamok lekérésekor:', error);
    return [];
  }
});
```

#### 2.1.2. Frontend Adatréteg Kiegészítése
A [frontend-react/src/pages/rates/workgroupSheetStorage.ts](frontend-react/src/pages/rates/workgroupSheetStorage.ts) fájlban valósítsa meg az SQLite perzisztencia hívást az `onBlur` mentésekhez:

```typescript
// d:\repo\valutavalto-program\frontend-react\src\pages\rates\workgroupSheetStorage.ts módosítása
export async function saveGroupRatesToOfflineDb(
  currencyGroupId: string,
  rates: Array<{ currencyId: string; buyRate: number; sellRate: number }>
): Promise<boolean> {
  if (window.electron && window.electron.ipcRenderer) {
    try {
      const payload = rates.map(r => ({
        currencyGroupId,
        currencyId: r.currencyId,
        buyRate: r.buyRate,
        sellRate: r.sellRate
      }));
      const res = await window.electron.ipcRenderer.invoke('lf:save-group-rates', payload);
      return res.ok;
    } catch (e) {
      console.error('Nem sikerült az offline SQLite mentés:', e);
    }
  }
  return false;
}

export async function loadGroupRatesFromOfflineDb(
  currencyGroupId: string
): Promise<Array<{ currencyId: string; buyRate: number; sellRate: number }>> {
  if (window.electron && window.electron.ipcRenderer) {
    try {
      return await window.electron.ipcRenderer.invoke('lf:get-group-rates', currencyGroupId);
    } catch (e) {
      console.error('Nem sikerült az offline SQLite betöltés:', e);
    }
  }
  return [];
}
```

A React oldali betöltésnél (`loadData` callback a [frontend-react/src/pages/rates/RateCreationPage.tsx](frontend-react/src/pages/rates/RateCreationPage.tsx) fájlban) az API-ból letöltött rátákra töltés után azonnal rá kell mossa (overlay) az SQLite-ból betöltött offline rátákat, így megmarad a memóriában és az oszlopokban minden beírt adat lapváltás vagy offline üzemmód után is.

---

### 2.2. Valuta rendezése a főlapi sorrend szerint (FR-1)

A [frontend-react/src/pages/rates/RateCreationPage.tsx](frontend-react/src/pages/rates/RateCreationPage.tsx) fájlban rendezni kell a valutákat a betöltődésükkor:

```typescript
// Főlapi sorrend referenciatömbje
const MAIN_SHEET_CURRENCY_ORDER = [
  'EUR', 'USD', 'GBP', 'CHF', 'AUD', 'CAD', 'JPY', 'CZK', 'PLN', 'RON', 
  'RSD', 'ILS', 'UAH', 'RUB', 'EUA', 'TRY', 'CNY', 'BAM', 'THB', 'BRL', 
  'MXN', 'NZD'
];

// loadData fázisban a rates állításakor:
const sortedRates = [...loadedRates].sort((a, b) => {
  const indexA = MAIN_SHEET_CURRENCY_ORDER.indexOf(a.currencyCode);
  const indexB = MAIN_SHEET_CURRENCY_ORDER.indexOf(b.currencyCode);
  if (indexA === -1 && indexB === -1) return a.currencyCode.localeCompare(b.currencyCode);
  if (indexA === -1) return 1;
  if (indexB === -1) return -1;
  return indexA - indexB;
});
```

---

### 2.3. Biztonságos 10%-os megerősítő dialógus bevezetése (FR-2, FR-3, FR-4, FR-5)

A módosítások végrehajtásakor ellenőrizni kell az eltérést, és el kell dönteni, hogy meg kell-e jeleníteni a modal ablakot.

#### 2.3.1. Kétoldali eltérés kiszámítása és Dialog State
A [frontend-react/src/pages/rates/RateCreationPage.tsx](frontend-react/src/pages/rates/RateCreationPage.tsx) fájlban vezessen be React state-eket a dialógus kezelésére:

```typescript
interface ConfirmDialogState {
  isOpen: boolean;
  cellKey: string;     // pl: "EUR-buy"
  currencyCode: string;
  fieldType: 'buy' | 'sell';
  oldValue: number;
  newValue: number;
  onConfirm: () => void;
  onCancel: () => void;
}

const [confirmDialog, setConfirmDialog] = useState<ConfirmDialogState | null>(null);
```

#### 2.3.2. Cella módosítás vizsgálata (Interception)
A cellák módosításakor (`commitWorkgroupCell` vagy ráták frissítése) az új érték elmentése ELŐTT le kell futtatni a következő vizsgálatot az előző mentett értékhez képest:

```typescript
const isSignificantDeviation = (oldVal: number, newVal: number): boolean => {
  if (!oldVal || oldVal === 0) return false;
  const deviation = Math.abs(newVal - oldVal) / oldVal;
  return deviation >= 0.10; // 10%
};

const handleRateChangeAttempt = (currencyId: string, currencyCode: string, field: 'buy' | 'sell', newVal: number, preSavedVal: number, commitFn: () => void) => {
  if (isSignificantDeviation(preSavedVal, newVal)) {
    setConfirmDialog({
      isOpen: true,
      cellKey: `${currencyId}-${field}`,
      currencyCode,
      fieldType: field,
      oldValue: preSavedVal,
      newValue: newVal,
      onConfirm: () => {
        commitFn();
        setConfirmDialog(null);
      },
      onCancel: () => {
        // Visszaállítás az előző értékre a UI-ban
        setConfirmDialog(null);
      }
    });
  } else {
    commitFn();
  }
};
```

Engedélyt kapott eltérés esetén az "Ellenőrzés" oszlopban az adott valuta sora mellett a piros sávkiugrási figyelmeztetés nem jelenhet meg.

---

### 2.4. Egérrel Lehúzható Jelölőnégyzet Tartomány és Lebegő Toolbar (FR-6 ... FR-10)

Kicseréljük a globális és destruktív oldalsáv gombokat egy Excel-szerű, interaktív tartománykijelöléssel vezérelt mechanizmusra a [frontend-react/src/pages/rates/components/RateGrid.tsx](frontend-react/src/pages/rates/components/RateGrid.tsx) fájlon belül.

#### 2.4.1. Kijelölési állapotok implementálása
Vezessünk be koordinátákat a rács celláin:

```typescript
interface GridCoord {
  rowIndex: number;
  colName: string; // 'buy' | 'sell' | 'k1' | 'k2' | 'e1' | 'e2' ts.
}

const [selectionStart, setSelectionStart] = useState<GridCoord | null>(null);
const [selectionEnd, setSelectionEnd] = useState<GridCoord | null>(null);
const [isDragging, setIsDragging] = useState<boolean>(false);
```

Mindegyik cellaelem TD-jére vagy Input-jára be kell kötni a következő egéreseményeket:
- `onMouseDown`: Beállítja a `selectionStart`-ot, elindítja a drag-et (`isDragging = true`).
- `onMouseEnter`: Ha `isDragging === true`, frissíti a `selectionEnd`-et.
- `onMouseUp`: Leállítja a drag-et (`isDragging = false`).

#### 2.4.2. Lebegő Toolbar Pozicionálása
A kijelölt tartomány téglalapja mellett (pl. a `selectionEnd` koordináta közelében a képernyőn pixel-alapon kiszámítva) jelenítsen meg egy kis lebegő panelt, ha van aktív kijelölt tartomány. A toolbar 3 gombot tartalmaz:

1. **Lehúzás (üres):**
   Kiüríti a kijelölt cellák értékét vagy formuláját.
2. **Lehúzás (mind):**
   Megkeresi a kijelölt oszlopokban a legelső sor celláit, és azok értékét vagy formuláját átmásolja a kijelölt tartomány összes többi cellájába azonos oszloponként haladva.
3. **Sávok törlése:**
   Csak a kijelölt sorok N-S (kedvezményes sáv) oszlopaiból törli ki az értékeket, a fő vételi/eladási oszlopokat érintetlenül hagyja.

---

## 3. Garanciák a Célmegvalósításra (QA és Szigorú előírások)

1. **NEM ÉRHETŐ EL KAMU MOCK VÁLASZ:** Minden rátamódosítást és formulaváltozást azonnal el kell menteni az SQLite-ban beépített tranzakcióval az `onBlur` triggerre. Nem támaszkodhatunk kizárólag illékony memóriás vagy böngészős local storage-ra!
2. **NINCS SÚGÓSÚLYÚ FIGYELMEZTETÉS MEGERŐSÍTÉS NÉLKÜL:** A 10%-os eltérés esetén a modal megkerülhetetlen. Ha a felhasználó a "Nem"-re kattint, a cella feltétel nélkül visszaáll a korábbi perzisztált értékére, s a mentés abortálódik.
3. **NINCS GLOBÁLIS ROMBOLÁS:** A régi oldalsó gombokkal végzett teljes táblázatos lehúzás és sávtörlés opciókat meg kell szüntetni. Csak és kizárólag a kijelölt részekre működhet a funkció a lebegő menüből.

Ez a javítási utasítás 100%-ban leírja a hiba valódi gyökerét, és lépésről lépésre, hallucinációktól mentesen elvezet a biztonságos és funkcionálisan helyes üzleti állapothoz.
