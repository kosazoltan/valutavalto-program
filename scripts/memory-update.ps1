# memory-update.ps1
#
# Repo-szintű memóriafrissítő script — 4 memóriarendszer egy paranccsal
#
# Használat:
#   pwsh scripts/memory-update.ps1              # update + embed + status
#   pwsh scripts/memory-update.ps1 -SkipEmbed   # csak update (gyorsabb)
#   pwsh scripts/memory-update.ps1 -Status      # csak állapot lekérdezés
#
# Rendszerek:
#   1. QMD (BM25 + vector search) — Markdown + YAML fájlok
#   2. YAML memória (docs/knowledge/memory/*.yaml) — QMD-be indexelve
#   3. Cognee (Python, ha telepítve) — graph memória
#   4. Vectoros (QMD embedding) — automatikus

[CmdletBinding()]
param(
    [switch]$SkipEmbed,
    [switch]$Status,
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$valutavaltoCollections = @(
    'valutavalto-vault',
    'valutavalto-memory',
    'valutavalto-docs',
    'valutavalto-source',
    'valutavalto-yaml-memory'
)

function Write-Section($title) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

# ----- Pre-flight check -----
Write-Section "1. PRE-FLIGHT — QMD CLI elérhetőség"
$qmdVersion = & qmd --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "QMD nem található. Telepítés: npm install -g @tobilu/qmd" -ForegroundColor Red
    exit 1
}
Write-Host "QMD: $qmdVersion" -ForegroundColor Green

# ----- Status only -----
if ($Status) {
    Write-Section "2. QMD ÁLLAPOT"
    & qmd status
    Write-Section "3. YAML memória"
    $yamls = Get-ChildItem -Path "$repoRoot/docs/knowledge/memory" -Filter "*.yaml" -ErrorAction SilentlyContinue
    Write-Host "  $($yamls.Count) yaml fájl a docs/knowledge/memory/-ban"
    Write-Section "4. Cognee"
    python -c "import cognee; print('  Cognee version:', cognee.__version__)" 2>&1
    exit 0
}

# ----- Cleanup -----
if ($Cleanup) {
    Write-Section "QMD CLEANUP (cache vacuum)"
    & qmd cleanup
    Write-Host "Cleanup kész." -ForegroundColor Green
    exit 0
}

# ----- 1. QMD update (re-index) -----
Write-Section "2. QMD UPDATE (re-index)"
& qmd update
if ($LASTEXITCODE -ne 0) {
    Write-Host "QMD update SIKERTELEN" -ForegroundColor Red
    exit 1
}

# ----- 2. QMD embed (vector generation) -----
if (-not $SkipEmbed) {
    Write-Section "3. QMD EMBED (vector generation)"
    & qmd embed
    if ($LASTEXITCODE -ne 0) {
        Write-Host "QMD embed SIKERTELEN" -ForegroundColor Red
        exit 1
    }
}

# ----- 3. YAML memória ellenőrzés -----
Write-Section "4. YAML MEMÓRIA állapot"
$yamlDir = Join-Path $repoRoot 'docs/knowledge/memory'
if (Test-Path $yamlDir) {
    $yamls = Get-ChildItem -Path $yamlDir -Filter "*.yaml"
    Write-Host "  $($yamls.Count) yaml session-jegyzet (deprecated formátum)"
    Write-Host "  Új session-jegyzetek helye: vault/sessions/"
} else {
    Write-Host "  docs/knowledge/memory/ nem létezik" -ForegroundColor Yellow
}

# ----- 4. Cognee ellenőrzés -----
Write-Section "5. COGNEE állapot (graph memória, opcionális)"
$cogneeOk = $false
try {
    python -c "import cognee" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $cogneeVersion = python -c "import cognee; print(cognee.__version__)" 2>&1
        Write-Host "  Cognee telepítve: $cogneeVersion" -ForegroundColor Green
        $cogneeOk = $true
    }
} catch { }
if (-not $cogneeOk) {
    Write-Host "  Cognee NEM telepítve (opcionális). pip install cognee" -ForegroundColor Yellow
}

# ----- Verifikáció -----
Write-Section "VERIFIKÁCIÓ — valutavalto kollekciók"
$statusOutput = & qmd status 2>&1
foreach ($coll in $valutavaltoCollections) {
    $line = $statusOutput | Select-String -Pattern "  $coll \(" -Context 0,3
    if ($line) {
        $files = ($statusOutput | Select-String -Pattern "  $coll " -Context 0,2).Context.PostContext |
            Where-Object { $_ -match 'Files:\s+(\d+)' } | Select-Object -First 1
        if ($files -match 'Files:\s+(\d+)') {
            Write-Host "  ✓ $coll : $($Matches[1]) fájl" -ForegroundColor Green
        } else {
            Write-Host "  ✓ $coll : létezik" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ $coll : HIÁNYZIK" -ForegroundColor Red
    }
}

# ----- Smoke test -----
Write-Section "SMOKE TEST — 'installer' keresés"
$smokeResult = & qmd search "installer" -c valutavalto-memory 2>&1
if ($smokeResult -match "valutavalto-memory") {
    Write-Host "  ✓ Keresés működik" -ForegroundColor Green
} else {
    Write-Host "  ✗ Keresés HIBA" -ForegroundColor Red
}

Write-Section "KÉSZ"
Write-Host "Használat:" -ForegroundColor Cyan
Write-Host "  qmd query 'kérdés'           # hybrid keresés (BM25 + vector)"
Write-Host "  qmd search 'kulcsszó' -c valutavalto-memory   # BM25 csak"
Write-Host "  qmd vsearch 'fogalom' -c valutavalto-vault    # vektoros csak"
Write-Host "  qmd ls valutavalto-vault                       # tartalom lista"
