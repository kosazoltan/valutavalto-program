# KÖTELEZŐ: Local-first fejlesztési direktíva (2026-05-14)

**User-direktíva:** Kósa Zoltán, 2026-05-14
**Hatály:** Minden Electron kliens (pénztár, értéktár, árfolyamkészítő, központi) + backend sync API

## Szabály

A valutaváltó program MINDEN kliense local-first architektúrával működik:
- A kliens az elsődleges adattároló (SQLite)
- A szerver szinkronizációs/backup/jogosultsági infrastruktúra
- Offline is teljes értékű működés kötelező
- A hálózat opcionális, háttérben szinkronizál

## Készletmodell (domain-kritikus)

- NINCS központi készlet — minden pénztár/értéktár SAJÁT készlettel rendelkezik
- Készlet = SUM(bejövő mozgások) - SUM(kimenő mozgások) devizánként
- Transzferek: párosított esemény minta (mindkét fél lokálisan rögzít, szerver párosít)
- Pénzügyi tranzakciók: append-only, szerverhatóság
- Draft-ok: mezőszintű merge

## Forrás dokumentumok

1. `C:\Users\Kósa Zoltán\Downloads\# Local-first adatszinkronizacio, k.txt`
2. `C:\Users\Kósa Zoltán\Downloads\local-first-ai-system-prompt.md`
3. `C:\Users\Kósa Zoltán\Downloads\local-first-ai-fejlesztesi-utasitas.md`

## Tilos

- Online-only működést szállítani
- Cache-t local-first-nek nevezni
- LWW-t pénzügyi adatoknál
- Központi készletet feltételezni
- Offline/reconnect teszt nélkül késznek jelölni
