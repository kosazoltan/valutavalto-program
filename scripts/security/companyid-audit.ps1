# ==============================================================================
# companyId-audit.ps1 - Multi-tenant boundary checker
# ------------------------------------------------------------------------------
# Cel:
#   Statikus analizissel riportal minden olyan Spring Data JPA repository
#   metodust, amelynek entity-je rendelkezik company_id oszloppal (vagy Company
#   reference-szel), de a metodus maga nem hivatkozik a companyId-ra.
#   A listat code review szamara adja - nem modosit kodot.
#
# Kimenet:
#   security-reports/companyid-audit-<yyyyMMdd-HHmmss>.md
#   security-reports/latest/companyid-audit.md
#
# Futtatas:
#   powershell -ExecutionPolicy Bypass -File scripts/security/companyid-audit.ps1
# ==============================================================================

param(
    [string]$RepoRoot = (Resolve-Path -Path "$PSScriptRoot/../..").Path
)

$ErrorActionPreference = "Stop"
$entityDir = Join-Path $RepoRoot "backend/src/main/java/hu/puzzleir/valuta/entity"
$repoDir   = Join-Path $RepoRoot "backend/src/main/java/hu/puzzleir/valuta/repository"

if (-not (Test-Path $entityDir)) { Write-Error "Entity dir missing: $entityDir"; exit 1 }
if (-not (Test-Path $repoDir))   { Write-Error "Repo dir missing: $repoDir";    exit 1 }

$reportDirBase  = Join-Path $RepoRoot "security-reports"
if (-not (Test-Path $reportDirBase)) { New-Item -ItemType Directory -Path $reportDirBase -Force | Out-Null }
$stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = Join-Path $reportDirBase "companyid-audit-$stamp.md"
$latestDir  = Join-Path $reportDirBase "latest"
if (-not (Test-Path $latestDir)) { New-Item -ItemType Directory -Path $latestDir -Force | Out-Null }
$latestLink = Join-Path $latestDir "companyid-audit.md"

$companyPatterns = @(
    'private\s+(Long|UUID|Integer)\s+companyId',
    '@JoinColumn\s*\([^\)]*company_id',
    '@ManyToOne[^\n]*\s+Company\b',
    'column\s*=\s*"company_id"'
)

# --- 1) Entity felmeres: mely entity-kben van company_id ---------------------
$entityFiles = Get-ChildItem -Path $entityDir -Filter "*.java" -File
$entitiesWithCompany = New-Object System.Collections.Generic.List[PSCustomObject]
foreach ($ef in $entityFiles) {
    $text = Get-Content -Path $ef.FullName -Raw -Encoding UTF8
    $hasCompany = $false
    foreach ($pat in $companyPatterns) {
        if ($text -match $pat) { $hasCompany = $true; break }
    }
    if ($hasCompany) {
        $entityName = [System.IO.Path]::GetFileNameWithoutExtension($ef.Name)
        if ($entityName -in @('Company', 'License', 'Branch', 'OwnCompany', 'Organization', 'Worker', 'Employee')) {
            $note = "self-root or infra entity"
        } else {
            $note = ""
        }
        $entitiesWithCompany.Add([PSCustomObject]@{
            EntityName = $entityName
            File       = $ef.FullName
            Note       = $note
        })
    }
}

Write-Host "Entities with company reference: $($entitiesWithCompany.Count)" -ForegroundColor Cyan

# --- 2) Repository metodus szintu audit --------------------------------------
$methodsTotal   = 0
$methodsFlagged = 0
$byRepoReport   = New-Object System.Collections.Generic.List[PSCustomObject]

# Kivetelek: ilyen metodusokra nem varunk company szurest (globalis / system-wide).
$whitelistPrefixes = @(
    'findById', 'findAll', 'existsById', 'deleteById', 'count', 'save', 'saveAll',
    'findByUuid', 'findByCode', 'delete', 'deleteAll'
)

foreach ($entity in $entitiesWithCompany) {
    $repoFile = Join-Path $repoDir ($entity.EntityName + "Repository.java")
    if (-not (Test-Path $repoFile)) { continue }

    $repoText   = Get-Content -Path $repoFile -Raw -Encoding UTF8
    $flagged    = New-Object System.Collections.Generic.List[string]
    $totalCount = 0

    # @Query("...") metodusok
    $queryPattern = '@Query\s*\(\s*(?:value\s*=\s*)?"(?<sql>[^"]*(?:""[^"]*)*)"[^)]*\)\s*(?:[\w<>?,\s]+)\s+(?<meth>\w+)\s*\('
    $queryMatches = [regex]::Matches($repoText, $queryPattern)
    foreach ($m in $queryMatches) {
        $methodsTotal++
        $totalCount++
        $sql  = $m.Groups['sql'].Value
        $meth = $m.Groups['meth'].Value
        $hasCompany = ($sql -match '(?i)company_id|companyId|company\.id|\.company\b')
        $whitelisted = $false
        foreach ($wp in $whitelistPrefixes) { if ($meth.StartsWith($wp)) { $whitelisted = $true; break } }
        if (-not $hasCompany -and -not $whitelisted) {
            [void]$flagged.Add("@Query $meth(...) -- SQL-ben nincs company_id")
            $methodsFlagged++
        }
    }

    # derivalt findBy / getBy / existsBy / countBy / deleteBy
    $derivedPattern = '(?m)^\s*(?:[\w<>?,\s]+)\s+(?<meth>(find|get|exists|count|delete)By\w+)\s*\('
    $derivedMatches = [regex]::Matches($repoText, $derivedPattern)
    foreach ($m in $derivedMatches) {
        $methodsTotal++
        $totalCount++
        $meth = $m.Groups['meth'].Value
        $hasCompany = ($meth -match '(?i)Company')
        $whitelisted = $false
        foreach ($wp in $whitelistPrefixes) { if ($meth.StartsWith($wp)) { $whitelisted = $true; break } }
        $viaBranch = ($meth -match '(?i)Branch(Id|_)')
        if (-not $hasCompany -and -not $whitelisted -and -not $viaBranch) {
            [void]$flagged.Add("derived $meth(...) -- sem Company, sem Branch nincs a nevben")
            $methodsFlagged++
        }
    }

    if ($totalCount -gt 0) {
        $flaggedList = @($flagged.ToArray())
        $byRepoReport.Add([PSCustomObject]@{
            Entity       = $entity.EntityName
            Repo         = ($entity.EntityName + "Repository.java")
            TotalMethods = $totalCount
            FlaggedCount = $flagged.Count
            FlaggedList  = $flaggedList
            Note         = $entity.Note
        })
    }
}

# --- 3) Riport -------------------------------------------------------------
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Multi-tenant companyId audit')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('**Generalva:** ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
[void]$sb.AppendLine('**Repo root:** `' + $RepoRoot + '`')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Osszefoglalo')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Metrika | Ertek |')
[void]$sb.AppendLine('|---|---|')
[void]$sb.AppendLine(('| Entity company ref-fel | {0} |' -f $entitiesWithCompany.Count))
[void]$sb.AppendLine(('| Repository auditalva | {0} |' -f $byRepoReport.Count))
[void]$sb.AppendLine(('| Metodusok osszesen | {0} |' -f $methodsTotal))
[void]$sb.AppendLine(('| Gyanus (flagged) metodus | {0} |' -f $methodsFlagged))
[void]$sb.AppendLine('')
[void]$sb.AppendLine('A "gyanus" metodusok olyan @Query vagy derivalt findBy/getBy/existsBy/countBy/deleteBy hivasok, amelyeknek sem neveben, sem SQL-jeben nincs company_id vagy branch szuro. Kezi review szukseges annak eldonteseben, hogy a tenant izolaciot a service reteg biztositja-e vagy valodi resbol van szo.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('**Whitelist (nem flagelt prefixek):** ' + ($whitelistPrefixes -join ', '))
[void]$sb.AppendLine('')

if ($byRepoReport.Count -eq 0) {
    [void]$sb.AppendLine('Nincs tenant-referencias repository query - az audit minden pontban zold.')
} else {
    [void]$sb.AppendLine('## Reszletes repository lista')
    [void]$sb.AppendLine('')
    $sortedRows = $byRepoReport | Sort-Object -Property FlaggedCount -Descending
    foreach ($row in $sortedRows) {
        [void]$sb.AppendLine('### ' + $row.Repo)
        [void]$sb.AppendLine(('- **Metodus osszesen:** {0} | **Gyanus:** {1}' -f $row.TotalMethods, $row.FlaggedCount))
        if ($row.Note) {
            [void]$sb.AppendLine('- **Jelzes:** ' + $row.Note + ' (system-wide / root entity, lehet tenant-agnostic)')
        }
        if ($row.FlaggedCount -gt 0) {
            [void]$sb.AppendLine('- **Review-ra:**')
            foreach ($f in $row.FlaggedList) {
                [void]$sb.AppendLine('  - `' + $f + '`')
            }
        } else {
            [void]$sb.AppendLine('- Minden metodus company/branch dimenzios vagy whitelisten.')
        }
        [void]$sb.AppendLine('')
    }
}

[void]$sb.AppendLine('## Rekonstrukcios ellenorzolista')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Egy metodus rendben van, ha egyik teljesul:')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('1. A **neveben** van Company vagy Branch (pl. findByCompanyIdAndDate)')
[void]$sb.AppendLine('2. A @Query **SQL-jeben** van company_id, companyId, vagy .company hivatkozas')
[void]$sb.AppendLine('3. A metodus **whitelisten** van (globalis technikai operacio: findById, save, stb.)')
[void]$sb.AppendLine('4. A hivo **service reteg** garantalja a szurest (pl. SecurityUtils.getCurrentCompanyId() parametert ad at)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Ha egyik sem teljesul, a metodus **multi-tenant boundary leak** kockazatot hordoz.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('_Statikus audit riport - a valodi javitas / suppress kezi review-t igenyel._')

$sb.ToString() | Out-File -FilePath $reportFile -Encoding UTF8
Copy-Item -Path $reportFile -Destination $latestLink -Force

Write-Host ""
Write-Host "=== Multi-tenant companyId audit ===" -ForegroundColor Cyan
Write-Host ("Entity-k company ref-fel:   {0}" -f $entitiesWithCompany.Count)
Write-Host ("Repository-k auditalva:     {0}" -f $byRepoReport.Count)
Write-Host ("Metodusok osszesen:         {0}" -f $methodsTotal)
Write-Host ("Gyanus (flagged) metodusok: {0}" -f $methodsFlagged)
Write-Host ""
Write-Host ("Riport: {0}" -f $reportFile)
Write-Host ("Latest: {0}" -f $latestLink)

exit 0
