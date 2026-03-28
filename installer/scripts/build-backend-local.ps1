Set-Location "D:\repo\valutavalto-program\backend"
$env:JAVA_HOME = "C:\ProgramData\BestChange\jre"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

Write-Output "Java version:"
& "$env:JAVA_HOME\bin\java.exe" -version 2>&1

Write-Output ""
Write-Output "=== Maven build start ==="
& ".\mvnw.cmd" package "-DskipTests" "-q" "--batch-mode" 2>&1
$exitCode = $LASTEXITCODE
Write-Output "=== Maven exit: $exitCode ==="

if ($exitCode -eq 0) {
    $jar = Get-ChildItem "target\*.jar" | Where-Object { $_.Name -notlike "*sources*" } | Select-Object -Last 1
    Write-Output "JAR: $($jar.FullName) ($([Math]::Round($jar.Length/1MB,1)) MB)"
}
exit $exitCode
