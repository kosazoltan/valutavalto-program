# Legacy bináris-elemzés — dinamikus workflow

Autonóm, újrafuttatható folyamat, amely a legacy Delphi **bináris végrehajtható fájlokat**
(`Arfolyam.exe`, `IBVALTO.exe`, `.dll`-ek) elemzi, és keresztellenőrzi a kinyert
funkcionalitást a jelenlegi kódbázissal.

## Miért dinamikus

A nyers `Anti/` legacy-fa (EXE/DLL + Pascal-források + adat) **gitignore-olt**
(`.gitignore` 105. sor) — proprietárius, nagy méretű, és nem való a publikus repóba.
Ezért az elemzés nem egyszeri kézi munka, hanem **kódba zárt, bárhol újrafuttatható**:
a forrást birtokló gép futtatja a fán, az eredmény (riport) a repóba kerül.

## Komponensek

| Komponens | Szerep |
|---|---|
| `scripts/legacy-binary-analyzer.py` | A motor: TPF0 form-kinyerés a binárisokból + keresztellenőrzés a kód ellen. Stdlib-only, öntesztelt. |
| `scripts/analyze-legacy-local.ps1` | Egykattintásos helyi futtató (Windows) — önteszt → teljes elemzés → riport a repóba. |
| `.github/workflows/legacy-binary-analysis.yml` | CI: az öntesztet minden releváns változásnál futtatja (regresszió-védelem); teljes elemzést, ha az Anti/ fa elérhető (önhostolt runner / `workflow_dispatch`). |
| `docs/legacy-analysis/generated/` | A commitolható riport (JSON + MD) — naprakész marad a gitignore-olt fa nélkül is. |

## Hogyan dönt (implementált / gap / leképezetlen)

Az analyzer minden kinyert legacy-formot a `FORM_IMPLEMENTATION_MAP` leképező-táblán át
keres a kódbázisban (`frontend-react`, `penztar-client`, `arfolyam-keszito-client`,
`kozponti-client`, `backend`):

- **✅ implementált** — a leképezett kód-minta megvan a kódban.
- **⚠️ nyitott gap** — van leképezés, de a minta NINCS meg → implementálandó (CI exit 1).
- **❓ leképezetlen** — új legacy-form, nincs leképezés → emberi besorolás kell (vedd fel a
  leképezést, vagy minősítsd egy `EXCMD/_compare/` verdiktben scope-on kívül / infra-csere).

Ez a tervezés a no-hallucináció elvet követi: a script soha nem állít „implementálva"-t
bizonyíték (kód-minta egyezés) nélkül, és a leképezetlen formot őszintén jelzi, nem
találgat.

## Futtatás

**A forrást birtokló gépen (teljes elemzés):**
```powershell
powershell -ExecutionPolicy Bypass -File scripts/analyze-legacy-local.ps1 `
  -AntiRoot "D:\repo\valutavalto-program\Anti"
git add docs/legacy-analysis/generated/ && git commit -m "chore(legacy): bináris-elemzés frissítés"
```

**Bárhol (önteszt — Anti/ nélkül, regresszió-ellenőrzés):**
```bash
python scripts/legacy-binary-analyzer.py --self-test
```

**CI:** automatikus a fenti path-eken; kézzel a GitHub Actions „Legacy Binary Analysis"
→ Run workflow gombbal (önhostolt runner esetén az `anti_root` megadható).

## Eddigi eredmény (kézi verdiktek, e workflow-t megelőzően)

- `EXCMD/legacy/02-ARFOLYAM-binaris-visszafejtes.md` — Arfolyam.exe 20 form, TPF0-RE.
- `EXCMD/_compare/2026-06-10-binaris-exe-implementacio-verdikt.md` — mind a 6 korábban
  nyitott RFM-form bezárult; a teljes EXE-leltár implementált vagy döntéssel scope-on kívül.

Ez a workflow ezt a kézi munkát teszi **ismételhetővé és regresszió-biztossá**: ha új
legacy-bináris kerül elő, vagy egy implementáció eltűnik a kódból, a riport (és a CI) jelzi.
