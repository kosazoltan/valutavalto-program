# fix-backend-acl.ps1 — S6-05 ACL fix for existing installs
$dataDir = "C:\ProgramData\BestChange"
icacls "$dataDir\backend" /grant "NT AUTHORITY\NetworkService:(OI)(CI)RX" /T /Q
New-Item -ItemType Directory -Force "$dataDir\backend\logs" | Out-Null
icacls "$dataDir\backend\logs" /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T /Q
Write-Output "Backend ACL fixed: RX base, F logs"
