param(
    [string]$BaseRef = "",
    [string]$HeadRef = "HEAD"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-GitRefExists {
    param([string]$Ref)
    if ([string]::IsNullOrWhiteSpace($Ref)) { return $false }
    & git cat-file -e "$Ref^{commit}" 2>$null
    return ($LASTEXITCODE -eq 0)
}

# legacy-transfer/: az EXCMD/Anti legacy forrásfa + binárisok (CP1250 Delphi források) —
# a forrasok/Anti/ precedensével azonosan kizárva (szándékosan nem-UTF8 referencia-anyag).
$excludePathRegex = '^(frontend-react/node_modules|penztar-client/node_modules|backend/target|frontend-react/dist|penztar-client/dist|penztar-client/release|\.git|security-reports|mentés|forrasok/Anti/|legacy-transfer/)'
$allowedExtRegex = '\.(java|ts|tsx|js|jsx|json|yml|yaml|md|txt|sql|properties|xml|cmd|bat|ps1|sh)$'

$files = @()
if ((Test-GitRefExists -Ref $BaseRef) -and (Test-GitRefExists -Ref $HeadRef)) {
    $files = @((& git diff --name-only --diff-filter=ACMRT $BaseRef $HeadRef) | Where-Object { $_ })
} else {
    $files = @((& git diff --name-only --diff-filter=ACMRT --cached) | Where-Object { $_ })
    if ($files.Count -eq 0) {
        $files = @((& git diff --name-only --diff-filter=ACMRT) | Where-Object { $_ })
    }
}

$files = @($files |
    Where-Object { $_ -match $allowedExtRegex } |
    Where-Object { $_ -notmatch $excludePathRegex } |
    Sort-Object -Unique)

if ($files.Count -eq 0) {
    Write-Host "UTF-8 guardrail: no applicable files to check."
    exit 0
}

$utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)
$decodeErrors = New-Object System.Collections.Generic.List[string]
$mojibakeHits = New-Object System.Collections.Generic.List[string]
$mojibakeRegex = '\u00C3.|\u00C2.|\u00E2\u20AC|\u00E2\u201A|\u0102.|\u0139.|\uFFFD'
$canDiffScan = ((Test-GitRefExists -Ref $BaseRef) -and (Test-GitRefExists -Ref $HeadRef))

foreach ($file in $files) {
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) {
        continue
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $text = $utf8Strict.GetString($bytes)

        if ($canDiffScan) {
            $tmpDiffFile = [System.IO.Path]::GetTempFileName()
            try {
                & git -c core.quotepath=false -c i18n.logOutputEncoding=utf8 diff --no-color -U0 --output=$tmpDiffFile $BaseRef $HeadRef -- $file
                $diffText = [System.IO.File]::ReadAllText($tmpDiffFile, $utf8Strict)
            }
            finally {
                if (Test-Path -LiteralPath $tmpDiffFile) {
                    Remove-Item -LiteralPath $tmpDiffFile -Force -ErrorAction SilentlyContinue
                }
            }

            $addedLines = $diffText -split "`r?`n" | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' }
            foreach ($line in $addedLines) {
                # -cmatch (case-SENSITIVE) kotelezo: a PowerShell `-match` alapertelmezesben
                # kis-nagybetu-fuggetlen, ezert a NAGYBETUS mojibake-markerek (U+00C3, U+00C2,
                # U+0102, U+0139) illeszkednek a legitim KISBETUS diakritikakra is (U+00E3,
                # U+00E2, U+0103, U+013A) — pl. roman "Agentia Iraniana" vagy portugal "-ao"
                # vegzodes minden nemzetkozi nevlistat megbuktatna. A mojibake definicio
                # szerint a nagybetus alak. (Kodpont-nevek szandekosan: a nyers karakterek
                # ide irva magat ezt a sort tennek talalatta.)
                if ($line -cmatch $mojibakeRegex) {
                    $mojibakeHits.Add($file)
                    break
                }
            }
        }
    }
    catch {
        $decodeErrors.Add($file)
    }
}

if ($decodeErrors.Count -gt 0) {
    Write-Host "UTF-8 decode failures:"
    $decodeErrors | ForEach-Object { Write-Host " - $_" }
}

if ($mojibakeHits.Count -gt 0) {
    Write-Host "Mojibake marker hits:"
    $mojibakeHits | ForEach-Object { Write-Host " - $_" }
}

if ($decodeErrors.Count -gt 0 -or $mojibakeHits.Count -gt 0) {
    Write-Error "UTF-8 guardrail failed. Fix file encoding and broken UTF text before merge."
    exit 1
}

Write-Host "UTF-8 guardrail passed for $($files.Count) file(s)."
exit 0
