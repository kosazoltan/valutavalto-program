# Legacy bináris-elemzés helyi futtató (Windows / a forrást birtokló gép).
#
# DINAMIKUS WORKFLOW — egykattintásos lépés a fejlesztő gépén:
#   1. Lefuttatja a bináris-elemzőt a helyi Anti/ fán (D:\repo\valutavalto-program\Anti).
#   2. A generált riportot (docs/legacy-analysis/generated/) a repóba teszi —
#      ez commitolható AKKOR is, ha a nyers Anti/ fa gitignore-olt.
#   3. Ha NYITOTT GAP (implementálatlan legacy-form) van, exit 1 + lista.
#
# Használat (a repo gyökeréből):
#   powershell -ExecutionPolicy Bypass -File scripts/analyze-legacy-local.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/analyze-legacy-local.ps1 -AntiRoot "D:\repo\valutavalto-program\Anti"

param(
    [string]$AntiRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) "Anti"),
    [string]$Out = (Join-Path (Split-Path -Parent $PSScriptRoot) "docs\legacy-analysis\generated")
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$analyzer = Join-Path $PSScriptRoot "legacy-binary-analyzer.py"

if (-not (Test-Path -LiteralPath $AntiRoot)) {
    Write-Host "[analyze-legacy-local] Az Anti/ fa nem található: $AntiRoot" -ForegroundColor Yellow
    Write-Host "  Add meg a tényleges utat: -AntiRoot 'D:\repo\valutavalto-program\Anti'"
    exit 2
}

# Windows PowerShell 5.1-kompatibilis (nincs ?? operátor).
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { Write-Host "[analyze-legacy-local] Python nem található a PATH-ban." -ForegroundColor Red; exit 2 }

Write-Host "[analyze-legacy-local] Önteszt…" -ForegroundColor Cyan
& $python.Source $analyzer --self-test
if ($LASTEXITCODE -ne 0) { Write-Host "Önteszt BUKOTT — a kinyerő logika hibás." -ForegroundColor Red; exit 1 }

Write-Host "[analyze-legacy-local] Teljes elemzés a helyi Anti/ fán…" -ForegroundColor Cyan
& $python.Source $analyzer --anti-root $AntiRoot --out $Out
$rc = $LASTEXITCODE

$mdRel = "docs/legacy-analysis/generated/legacy-binary-analysis.md"
Write-Host ""
if ($rc -eq 1) {
    Write-Host "[analyze-legacy-local] ⚠️ NYITOTT GAP — implementálatlan legacy-form. Lásd: $mdRel" -ForegroundColor Yellow
} else {
    Write-Host "[analyze-legacy-local] ✅ Nincs nyitott gap. Riport: $mdRel" -ForegroundColor Green
}
Write-Host "  A generált riport commitolható (a nyers Anti/ fa gitignore-olt marad):"
Write-Host "    git add docs/legacy-analysis/generated/ && git commit -m 'chore(legacy): bináris-elemzés frissítés'"
exit $rc
