# Anti bináris végrehajtható fájlok (EXE) — implementáció-verdikt (2026-06-10)

**Hozzáférési tény:** a nyers `Anti/` fa (benne az EXE-kkel) a `.gitignore` miatt csak a
lokális gépen él, a felhő-session nem éri el. A bináris-elemzés azonban dokumentáltan
megtörtént (`EXCMD/legacy/02-ARFOLYAM-binaris-visszafejtes.md`, 2026-05-22: TPF0
form-kinyerés + DFM-parse), és az eredménye a repóban van — ez a verdikt AZT veti össze
a MAI kóddal (a 2026-05-22-i státusz óta ~70 verzió jelent meg).

## EXE/bináris leltár és implementáció-státusz

| Bináris | Funkció (visszafejtésből/forrásból) | Mai implementáció | Verdikt |
|---|---|---|---|
| **Arfolyam.exe** (Delphi 7, 20 beágyazott form) | Árfolyamkészítő (RFM) kliens | ld. form-bontás lent | ✅ TELJES |
| `arfdata.dat` | typed-file árfolyam-rekordok, pozíció-alapú valuta-identitás | `exchange_rate_master` DB + REST publish (infra-csere) | ✅ |
| **IBVALTO.exe** (fő pénztár-kliens) | pénztári tranzakciók | forrása megvolt (`IBVALTO.DPR`+Unit1..18 → modul-MD); `penztar-client` + backend fedi | ✅ |
| **TRADE.exe** termékcsalád | telefon-feltöltés, matrica, e-kereskedés | üzletileg inaktív → szándékos scope-vágás (roadmap + 06-verdikt) | ⛔ scope-on kívül (döntés) |
| `old.zip` (3737 fájl) | adat/bináris, **0 forrásfájl** | n/a | ✅ átvizsgálva, nincs teendő |
| firebird / ibconsole | DB-infra | PostgreSQL + Flyway + BackupService (infra-csere) | ✅ |
| camera Java-alrendszer | kamerafelvétel-kezelés | `CameraController`/`CameraAdminController`/`CameraExportController` + `CameraConfigPage`/`CameraLivePage`/`CameraExportPage` (feature-flag) | ✅ |

## Arfolyam.exe — a 20 visszafejtett form mai státusza

A 2026-05-22-i RE-doksi 6 formot „⚠️ G22 sub-scope"-ként nyitva hagyott. **Mind a 6 azóta
implementálva** (friss kód-elleni ellenőrzés, 2026-06-10):

| Legacy form (binárisból) | 2026-05-22 státusz | MAI bizonyíték | Verdikt |
|---|---|---|---|
| TCSOPORTDISPLAY (54 munkacsoport-rács) | ⚠️ nyitva | `WorkgroupTileListView` (+teszt: tile-view, write-végpontok, branches), `workgroupSheetCompute`, FK02-D #1049 cross-csoport csempenézet | ✅ KÉSZ |
| TLIMITALLITOFORM (kedvezményhatár-állító) | ⚠️ nyitva | `workgroupMaintenance.tsx` + `exchange-rates.ts` API (kedvezményhatár) | ✅ KÉSZ |
| TINTERNETTMKFORM (INTERNET/nagyker oszlop) | ⚠️ nyitva | `MainRateSheetPage.tsx` (INTERNET oszlop) | ✅ KÉSZ |
| THOVAMASOLJAK (FR-RFM-23 kitöltési segítség) | ⚠️ nyitva | `crossGroupCopy.ts` + `fillHelpers.ts` (+tesztek, FR-RFM-23 hivatkozással) | ✅ KÉSZ |
| TGETFUGGVENY (FR-RFM-22 aktuális függvény) | ⚠️ nyitva | `FormulaSyntaxHelp.tsx` + `mainSheetFormula.ts` (+tesztek) | ✅ KÉSZ |
| TIRODANEVLISTA (FR-RFM-21 csoport irodái) | ⚠️ nyitva | `WorkgroupTileListView` branches-lista (teszt: `branches: [{code:'BP1',…}]`) | ✅ KÉSZ |

A többi 14 form már 2026-05-22-én ✅/⚙️ volt (TALAPLAP→MainRateSheetPage,
TADATSZETKULDES→publish G7-gate-tel, login→JWT, segéd-formok→UI).

## Konklúzió

A bináris végrehajtható fájlokból kinyert funkcionalitás a mai programban
**maradéktalanul implementált vagy dokumentált döntéssel scope-on kívül** (TRADE).
A 2026-05-22-i RE-doksi 6 nyitott UI-tétele azóta bezárult — a `02-ARFOLYAM-binaris-
visszafejtes.md` ⚠️ jelölései e verdikt szerint elavultak. Új, implementálatlan
EXE-funkció: **nincs**.

> Ha a lokális `Anti/` fa pushra kerül (a `.gitignore` 32–33/105. sorának törlésével),
> a TPF0/DFM-kinyerés bármely további `.exe`/`.dll`-re közvetlenül innen is futtatható.
