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

## Base64-híd: a források áthozatala a felhő-sessionbe (`scripts/legacy-transfer.py`)

**Probléma:** a Claude Code felhő-sessionbe egyetlen adatcsatorna vezet — a git
(file-upload nincs; lokális gépen futó MCP a felhő-sandboxot nem éri el). A nyers
`Anti/` fa gitignore-olt, a binárisok (EXE/DLL) pedig nem szöveg.

**Megoldás:** a Base64 adatkódolás (NEM titkosítás!) pontosan erre való — bináris →
szövegként biztonságosan továbbítható forma. Ugyanezt a mintát használja maga az
MCP-szabvány is (binary resource → base64 `blob`), és az e-mail/JSON/data-URI világ.
Saját, stdlib-only eszközzel csináljuk (harmadik-fél base64-MCP-szolgáltatásnak
proprietárius forrást kiküldeni adatszivárgás lenne):

```
[lokális gép]  python scripts/legacy-transfer.py pack            # Anti/ → legacy-transfer/
               git add legacy-transfer && git commit && git push #   (szöveg: UTF-8-ra konvertált
                                                                 #    .pas; bináris: base64 + sha256)
[felhő/CI]     python scripts/legacy-transfer.py unpack          # legacy-transfer/ → Anti_transfer/
               python scripts/legacy-binary-analyzer.py --anti-root Anti_transfer
```

- **Integritás:** fájlonként SHA-256 a manifesztben; eltérésnél az unpack hibát jelez.
- **Pontosabb beolvasás:** a cp1250-es Delphi-forrás UTF-8-ként, bájthelyesen érkezik
  (nem OCR-en/kivonaton át) — a TPF0-kinyerés pedig az EREDETI bináris bájtjain fut.
- **Guardrail-kompatibilis:** a szöveg-fájlok UTF-8-ak; a base64-blobok `.b64`
  kiterjesztésűek (a UTF-8 guardrail nem ellenőrzi őket).
- **Méret:** 8 MB-os chunkok (b64-ben ~10,7 MB) — GitHub-barát; szelektív `--include`.
- **Adatvédelem:** a becsomagolt tartalom a (privát) repóba kerül és bárki visszafejti,
  aki a repót látja — csak azt csomagold, amit ezzel vállalsz.
- A CI (`legacy-binary-analysis.yml`) a `legacy-transfer/` megjelenésekor automatikusan
  kibont + elemez, és minden futáskor lefuttatja a pack/unpack öntesztet.

## Eddigi eredmény (kézi verdiktek, e workflow-t megelőzően)

- `EXCMD/legacy/02-ARFOLYAM-binaris-visszafejtes.md` — Arfolyam.exe 20 form, TPF0-RE.
- `EXCMD/_compare/2026-06-10-binaris-exe-implementacio-verdikt.md` — mind a 6 korábban
  nyitott RFM-form bezárult; a teljes EXE-leltár implementált vagy döntéssel scope-on kívül.

Ez a workflow ezt a kézi munkát teszi **ismételhetővé és regresszió-biztossá**: ha új
legacy-bináris kerül elő, vagy egy implementáció eltűnik a kódból, a riport (és a CI) jelzi.
