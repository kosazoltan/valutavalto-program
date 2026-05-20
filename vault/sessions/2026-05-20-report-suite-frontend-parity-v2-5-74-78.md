---
date: 2026-05-20
topic: Riport-suite frontend parity + önellenőrzés-erősítés (v2.5.74 → v2.5.78)
prs: ["#712","#713","#714","#715","#716"]
mandates-added: ["C.25-extended","C.26","readback-condition-based"]
---

# Riport-suite frontend parity (v2.5.74 → v2.5.78)

## Kontextus
A user 2026-05-20-i direktívája: "még mindig nagyon sok a CI/Copilot/Sourcery/Codex
hibatalálat... javítsd a saját önellenőrző mechanizmusodat... MIELŐTT PR-t csinálsz".
Erre épült a C.25 pre-PR gate, amit ebben a sessionben élesben alkalmaztam — a
finding/PR arány ~3-4-ről **0-1-re** csökkent (#715, #716: 0 inline finding).

## Mergelt PR-ek
- **#712 (v2.5.74)** — Visszatérő ügyfél AML monitoring riport (backend service +
  controller + DTO + 10 teszt + frontend oldal). Pmt. 16. §. AI-finding: üres-string
  customerId `<> ''`, version-sync teljes set — PR-en belül javítva.
- **#713 (v2.5.75)** — Átlag árfolyam riport frontend (ATLAGARF parity, backend PR #703).
  AI-finding: isoDate UTC, transactionType union — javítva.
- **#714 (v2.5.76)** — `localIsoDate` közös util + UTC dátum off-by-one fix 7 riport-oldalon
  (DRY). 4 unit teszt. AI-finding: flaky default-arg teszt → vi.useFakeTimers.
- **#715 (v2.5.77)** — Napkönyv PDF letöltő oldal (NAPKONYV parity, backend PR #705).
  blob-download + extractBlobError. **0 inline finding.**
- **#716 (v2.5.78)** — Központi konszolidált riportok CSV oldal (daily/weekly/monthly)
  + `getBlobErrorMessage` közös util (DRY, DailyJournal migrálva). **0 inline finding.**

Minden PR: CI zöld, 2-kör saját subagent review (C.25), admin-merge, Hetzner deploy.

## Új/erősített mandate-ek (a session tanulságaiból)
- **C.25 bővítés**: (a) query-szintű sibling-grep (új JPQL → meglévő AML-query extra
  szűrői, `<> ''` nem csak IS NOT NULL); (b) version-sync TELJES set (ROOT package.json
  + pom.xml + 4 kliens + lockfile) + lokális `check-four-area-alignment.mjs`; (c) NE
  utasítsd el subagent-findinget "sibling-consistency" ürüggyel ha valós bug.
- **C.26**: az autonóm folytatás / polling-alatti párhuzamos munka a SAJÁT belső
  törvényem, NEM a user kérése — tilos így framelni.
- **Readback (C.24 finomítás)**: condition-based `until`-loop poll (vár a CI-settle-ig),
  NEM fix `sleep` + korai visszaolvasás.

## v2.5.78 installer checkpoint (KÉSZ, unsigned)
- `Penztar-Setup-2.5.78-20260520.exe` — 282.67 MB, SHA-256 `BA30BEC035BA1E2EDAC57C9445ADF78632D002EB6ABCFF6C05256EE46C4A52B8`
- `Kozponti-Iranyitokozpont-Setup-2.5.78.exe` — 101.05 MB, SHA-256 `DC629AB5F22F212A417886D151DD779E960624850FD06F9C248AA4978FCAB2B7`
- `Arfolyamkeszito-Setup-2.5.78.exe` — 101.05 MB, SHA-256 `110FE859E87FB0F4103EEFAFB384DEA911397AADD10A3569AA802D9D2A6F46B7`
- Eltavolito: verzió-független (2.5.73 a legutóbbi build, jó minden verzióhoz).
- Mind a 4 a `%USERPROFILE%\Downloads\`-ban. UNSIGNED (DigiCert EV CS pending).
- A buildek SZEKVENCIÁLISAN futottak (Penztar → Kozponti → Arfolyam) a frontend-react/dist race elkerülésére.

## Következő (autonóm terv)
- nav-reports frontend (NavReportController /daily + /reportable + /csv,
  SUPERVISOR/MANAGER/ADMIN, NAV_THRESHOLD feletti tranzakciók).
- Maradék legacy parity.
