# Dev helper scripts

## `verify-stack.ps1`

Checks that the stack comes up:

1. Optional: `docker compose up -d postgres`
2. Starts Spring Boot (`test` profile, local Postgres `valuta` / `valuta_user` / `valuta_pass`)
3. Polls `http://127.0.0.1:8080/actuator/health` until HTTP 200 (default 180s)
4. Stops the JVM tree unless `-KeepBackendRunning`

```powershell
# Postgres already running
.\scripts\dev\verify-stack.ps1 -SkipDocker

# Full check from clean slate
.\scripts\dev\verify-stack.ps1

# Leave backend running after success
.\scripts\dev\verify-stack.ps1 -SkipDocker -KeepBackendRunning
```

Prerequisites: Docker (for Postgres), JDK 21 on PATH or used by `mvnw`.
