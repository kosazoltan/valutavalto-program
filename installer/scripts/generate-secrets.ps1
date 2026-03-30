#!/usr/bin/env pwsh
# generate-secrets.ps1 — Installer secret generation (called by NSIS)
# Output: 3 lines — JWT_SECRET, ENCRYPTION_SALT, ENCRYPTION_KEY
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

$rng.Dispose()

# Output each on its own line (NSIS reads all stdout)
Write-Output $jwt
Write-Output $salt
Write-Output $key
