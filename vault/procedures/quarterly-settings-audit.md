---
title: Negyedéves settings.json biztonsági audit
frequency: quarterly (Q1/Q2/Q3/Q4 elején)
owner: Kósa Zoltán
last_run: 2026-06-08
next_run: 2026-09-01
---

# Negyedéves Claude Code biztonsági audit

## Miért szükséges

A YOLO mód (`bypassPermissions`) + hosszú `allow` lista komoly kockázatot jelent, ha elavult, túl tág, vagy nem szándékos engedélyek halmozódnak fel. Negyedévente manuálisan át kell nézni, mit engedünk.

## Audit checklist

### 1. settings.json allow-lista átnézése

```powershell
Get-Content "C:\Users\Kósa Zoltán\.claude\settings.json" | ConvertFrom-Json | 
  Select-Object -ExpandProperty permissions | 
  Select-Object -ExpandProperty allow
```

Minden tételnél kérdezd meg:
- [ ] Még mindig szükséges ez az engedély?
- [ ] Nem tágabb a scope, mint kellene? (`Bash(*)` vs. `Bash(npm test)`)
- [ ] Van-e benne veszélyes minta: `sudo`, `rm -rf`, `curl | sh`, `DROP TABLE`?
- [ ] Elavult projekt-specifikus path? (pl. régi plugin cache útvonal)

### 2. Veszélyes parancsminták ellenőrzése

```powershell
# Keresés veszélyes mintákra az allow listában
$settings = Get-Content "C:\Users\Kósa Zoltán\.claude\settings.json" | ConvertFrom-Json
$dangerous = $settings.permissions.allow | Where-Object { 
    $_ -match 'sudo|rm -rf|curl \| sh|DROP TABLE|format|regedit' 
}
if ($dangerous) { Write-Warning "Veszélyes minták: $dangerous" }
else { Write-Output "OK — nincs veszélyes minta" }
```

### 3. Project-szintű settings.json-ok átnézése

```powershell
Get-ChildItem "D:\repo\*\.claude\settings.json" -Recurse | ForEach-Object {
    Write-Output "=== $($_.FullName) ==="
    Get-Content $_ | ConvertFrom-Json | 
      Select-Object -ExpandProperty permissions | 
      Select-Object -ExpandProperty allow
}
```

### 4. DISABLE_AUTOUPDATER ellenőrzése

```powershell
$val = [System.Environment]::GetEnvironmentVariable("DISABLE_AUTOUPDATER", "User")
if ($val -eq "1") { Write-Output "✅ DISABLE_AUTOUPDATER=1 aktív" }
else { Write-Warning "❌ DISABLE_AUTOUPDATER nincs beállítva — futtasd: [System.Environment]::SetEnvironmentVariable('DISABLE_AUTOUPDATER','1','User')" }
```

### 5. Plugin-engedélyek átnézése

Minden engedélyezett plugin esetén:
- [ ] Valóban aktívan használt?
- [ ] `security-guidance@claude-plugins-official` letiltva maradt? (by design)

### 6. Naplózás

Az audit után frissítsd a `last_run` és `next_run` mezőket ebben a fájlban.

---

## Korábbi audit-találatok

| Dátum | Finding | Akció |
|-------|---------|-------|
| 2026-06-08 | Első audit — baseline rögzítve | Nincs veszélyes minta, DISABLE_AUTOUPDATER beállítva |
