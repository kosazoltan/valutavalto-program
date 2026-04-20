# fix-backend-acl.ps1 - v2.1.3 fix
# Backend service LocalSystem fiokon fut (NSIS L795: ObjectName LocalSystem),
# ezert a grantet S-1-5-18 (LocalSystem) kell adni, NEM NetworkService.
# Regi (v1.x) telepitesre hivhato visszamenoleg javitani.

$dataDir = "C:\ProgramData\BestChange"

# LocalSystem (S-1-5-18) = a backend service tulajdonos
icacls "$dataDir\backend"      /grant *S-1-5-18:`(OI`)`(CI`)RX /T /Q
New-Item -ItemType Directory -Force "$dataDir\backend\logs" | Out-Null
icacls "$dataDir\backend\logs" /grant *S-1-5-18:`(OI`)`(CI`)F  /T /Q

# Config read-only
icacls "$dataDir\config"       /grant *S-1-5-18:`(OI`)`(CI`)R  /T /Q

# Removal of incorrect NetworkService grants (if present from old installer)
icacls "$dataDir\backend"      /remove NetworkService  /T /Q 2>$null
icacls "$dataDir\backend\logs" /remove NetworkService  /T /Q 2>$null

Write-Output "Backend ACL fixed v2.1.3: LocalSystem grants applied; NetworkService grants removed."
