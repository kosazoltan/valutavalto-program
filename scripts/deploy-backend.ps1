param()
$ErrorActionPreference = "Stop"

$TARGET_JAR = "D:\repo\valutavalto-program\backend\target\valuta-backend-1.0.0-SNAPSHOT.jar"
$DEST_JAR   = "C:\ProgramData\BestChange\backend\valuta-backend.jar"

Write-Host "=== JAR size check ==="
$sizeMB = (Get-Item $TARGET_JAR).Length / 1MB
Write-Host "JAR size: $([math]::Round($sizeMB,1)) MB"
if ($sizeMB -lt 50) { Write-Error "JAR too small"; exit 1 }

Write-Host "=== Stop BestChange-Backend ==="
try { Stop-Service -Name "BestChange-Backend" -Force -ErrorAction Stop; Write-Host "Stopped." }
catch { Write-Host "Stop result: $($_.Exception.Message)" }

Start-Sleep -Seconds 4

Write-Host "=== Copy JAR ==="
Copy-Item -Path $TARGET_JAR -Destination $DEST_JAR -Force
Write-Host "Copied OK"

Write-Host "=== Start BestChange-Backend ==="
Start-Service -Name "BestChange-Backend"
Write-Host "Started."

Write-Host "=== Health check (up to 90s) ==="
$ok = $false
for ($i = 1; $i -le 18; $i++) {
    Start-Sleep -Seconds 5
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/api/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "Attempt $i : $($resp.StatusCode)"
        if ($resp.StatusCode -eq 200) { $ok = $true; break }
    } catch {
        Write-Host "Attempt $i : no response"
    }
}

if ($ok) { Write-Host "SUCCESS: Backend healthy" }
else { Write-Error "FAIL: Backend not healthy after 90s"; exit 1 }
