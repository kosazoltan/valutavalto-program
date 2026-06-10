# Generált legacy bináris-elemzés

Ezt a mappát a `scripts/legacy-binary-analyzer.py` tölti fel:

- `legacy-binary-analysis.json` — gépi riport (bináris-leltár, kinyert TPF0 form-ok,
  implementáció-státusz).
- `legacy-binary-analysis.md` — ember-olvasható riport (implementált / nyitott gap /
  leképezetlen form-ok).

A fájlok **commitolhatók**, és akkor is naprakészek maradnak, ha a nyers `Anti/` legacy-fa
gitignore-olt (csak a fejlesztő gépén él). A riportot a forrást birtokló gépen kell
frissíteni:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/analyze-legacy-local.ps1
git add docs/legacy-analysis/generated/ && git commit -m "chore(legacy): bináris-elemzés frissítés"
```

A teljes workflow leírása: `docs/legacy-analysis/BINARY-ANALYSIS-WORKFLOW.md`.
