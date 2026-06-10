#Requires -Version 5.1
<#
.SYNOPSIS
  Összegyűjti az összes TODO/FIXME/HACK/NOSONAR/DEBT kommentet a kódbázisból.

Replaces: AI review "unresolved TODO" findings + kézi kódátvizsgálás.

.PARAMETER Type
  Szűrés: todo, fixme, hack, nosonar, debt, all (default: all)

.PARAMETER Module
  Szűrés modul/könyvtárnévre (pl. "backend", "frontend-react")

.PARAMETER Summary
  Csak összesítő, fájl-lista nélkül.

.EXAMPLE
  .\scripts\dev-tools\todo-harvest.ps1
  .\scripts\dev-tools\todo-harvest.ps1 -Type fixme -Module backend
  .\scripts\dev-tools\todo-harvest.ps1 -Summary

Exit: 0 = nincs találat, 1 = van találat
#>
param(
    [ValidateSet("todo","fixme","hack","nosonar","debt","all")]
    [string]$Type = "all",
    [string]$Module = "",
    [switch]$Summary
)

$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')

$Patterns = switch ($Type) {
    "todo"   { @("TODO") }
    "fixme"  { @("FIXME") }
    "hack"   { @("HACK") }
    "nosonar"{ @("NOSONAR") }
    "debt"   { @("TECH[-_]?DEBT", "TECHDEBT") }
    "all"    { @("TODO", "FIXME", "HACK", "NOSONAR", "TECH[-_]?DEBT") }
}

$SearchPath = if ($Module) { Join-Path $Root $Module } else { $Root }
$IgnoreGlobs = @(
    "--glob", "!**/node_modules/**",
    "--glob", "!**/target/**",
    "--glob", "!**/dist/**",
    "--glob", "!**/dist-electron/**",
    "--glob", "!**/.git/**",
    "--glob", "!**/coverage/**",
    "--glob", "!**/*.min.js",
    "--glob", "!**/security-reports/**"
)

$AllHits = [System.Collections.Generic.List[PSCustomObject]]::new()
$WIN_RE  = [regex]'^(.+?):(\d+):(.*)'

foreach ($pat in $Patterns) {
    $lines = & rg --no-heading --line-number --color=never `
        --glob "*.java" --glob "*.ts" --glob "*.tsx" --glob "*.py" --glob "*.ps1" `
        @IgnoreGlobs -e $pat -i $SearchPath 2>$null
    foreach ($line in $lines) {
        $m = $WIN_RE.Match($line)
        if (-not $m.Success) { continue }
        $file    = $m.Groups[1].Value
        $lineno  = $m.Groups[2].Value
        $content = $m.Groups[3].Value.Trim()
        # Normalize to relative path (case-insensitive root strip for Windows)
        $rel = $file
        if ($file.ToLower().StartsWith($Root.ToString().ToLower())) {
            $rel = $file.Substring($Root.ToString().Length).TrimStart('\', '/')
        }
        $parts  = $rel -split '[/\\]'
        $module_name = if ($parts.Count -gt 1) { $parts[0] } else { "." }
        $AllHits.Add([PSCustomObject]@{
            Module  = $module_name
            File    = $rel
            Line    = [int]$lineno
            Content = $content
            Tag     = if ($content -match '(?i)(TODO|FIXME|HACK|NOSONAR|TECH.?DEBT)') { $Matches[1].ToUpper() } else { $pat }
        })
    }
}

# Dedup (same file+line)
$AllHits = $AllHits | Sort-Object File, Line | Group-Object { "$($_.File):$($_.Line)" } |
    ForEach-Object { $_.Group[0] }

$Total = @($AllHits).Count
Write-Host "todo-harvest: $Total hit(s)" -ForegroundColor Cyan
if ($Total -eq 0) { exit 0 }

if ($Summary) {
    $AllHits | Group-Object Tag | Sort-Object Count -Descending |
        ForEach-Object { Write-Host ("  {0,-10} {1,4}" -f $_.Name, $_.Count) }
    Write-Host ""
    $AllHits | Group-Object Module | Sort-Object Count -Descending |
        ForEach-Object { Write-Host ("  [{0}]  {1}" -f $_.Name, $_.Count) }
    exit 1
}

Write-Host ""
$AllHits | Group-Object Module | Sort-Object Name | ForEach-Object {
    $mod  = $_.Name
    $hits = $_.Group | Sort-Object File, Line
    Write-Host "  [$mod] ($($hits.Count))" -ForegroundColor Yellow
    foreach ($h in $hits | Select-Object -First 20) {
        $tag_color = switch ($h.Tag) {
            "FIXME"   { "Red" }
            "HACK"    { "Magenta" }
            "NOSONAR" { "DarkYellow" }
            default   { "White" }
        }
        Write-Host ("    {0,-8} {1}:{2}" -f $h.Tag, $h.File, $h.Line) -ForegroundColor $tag_color
        if (-not $Summary) {
            Write-Host ("           {0}" -f $h.Content.Substring(0, [math]::Min(100, $h.Content.Length))) -ForegroundColor DarkGray
        }
    }
    if ($hits.Count -gt 20) {
        Write-Host "    ... ($($hits.Count - 20) more)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

exit 1
