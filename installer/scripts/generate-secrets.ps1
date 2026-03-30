#!/usr/bin/env pwsh
# generate-secrets.ps1 — Installer secret generation (called by NSIS)
# Output: 4 lines — JWT_SECRET, ENCRYPTION_SALT, ENCRYPTION_KEY, DB_PASSWORD
# Compatible with PowerShell 5.1 (Windows built-in)

$ErrorActionPreference = "Stop"

$rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()

# JWT Secret — 48 random bytes -> 64 char Base64 (>= 32 byte requirement)
$jwtBytes = New-Object byte[] 48
$rng.GetBytes($jwtBytes)
$jwt = [Convert]::ToBase64String($jwtBytes)

# Encryption Salt — 16 random bytes -> 32 char hex (Spring Encryptors.standard expects hex)
$saltBytes = New-Object byte[] 16
$rng.GetBytes($saltBytes)
$salt = [BitConverter]::ToString($saltBytes).Replace('-','').ToLower()

# Encryption Key — 32 random bytes -> 44 char Base64
$keyBytes = New-Object byte[] 32
$rng.GetBytes($keyBytes)
$key = [Convert]::ToBase64String($keyBytes)

# DB Password — 24 random bytes -> 32 char Base64 (unique per install, no hardcode)
$dbPwBytes = New-Object byte[] 24
$rng.GetBytes($dbPwBytes)
# Use only alphanumeric chars to avoid SQL/shell escaping issues
$dbPw = [Convert]::ToBase64String($dbPwBytes) -replace '[+/=]',''
# Ensure minimum 16 chars (trim to 24 for consistency)
if ($dbPw.Length -gt 24) { $dbPw = $dbPw.Substring(0, 24) }
if ($dbPw.Length -lt 16) {
    # Fallback: generate more bytes
    $extra = New-Object byte[] 16
    $rng.GetBytes($extra)
    $dbPw += ([Convert]::ToBase64String($extra) -replace '[+/=]','')
    $dbPw = $dbPw.Substring(0, 24)
}

$rng.Dispose()

# Output each on its own line (NSIS reads all stdout)
Write-Output $jwt
Write-Output $salt
Write-Output $key
Write-Output $dbPw
