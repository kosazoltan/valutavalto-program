$kill_pg = "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '*BestChange*' } | Stop-Process -Force -ErrorAction SilentlyContinue"
$kill_java = "Get-Process java -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '*BestChange*' } | Stop-Process -Force -ErrorAction SilentlyContinue"
$check_pg = "if (Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '*BestChange*' }) { exit 1 } else { exit 0 }"
$check_java = "if (Get-Process java -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '*BestChange*' }) { exit 1 } else { exit 0 }"

Write-Host "KILL_PG_CMD: $kill_pg"
Write-Host "KILL_PG_B64:"
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($kill_pg))
Write-Host ""
Write-Host "KILL_JAVA_B64:"
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($kill_java))
Write-Host ""
Write-Host "CHECK_PG_B64:"
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($check_pg))
Write-Host ""
Write-Host "CHECK_JAVA_B64:"
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($check_java))

# Verify by decoding back
Write-Host ""
Write-Host "VERIFY_KILL_PG_DECODED:"
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($kill_pg))
[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($b64))
