# 2026-05-12 server legacy module inventory

Decision context:

- The planned desktop tool should become a broader "Központi helyi munkaállomás", not only an árfolyamkészítő.
- The cashier application remains separate.
- The server remains a backend/API/background service and source of truth. Operator workflows move into the local Electron workstation where appropriate.

Surveyed path:

- `D:\repo\valutavalto-program\forrasok\SZERVER`

Key findings:

- The legacy tree contains source code for most modules: `.pas`, `.dfm`, `.dpr`, plus built `.exe` and `.dll` artifacts.
- `fejleszt\server\server.exe` is the old central menu shell.
- `newdll` is the released DLL module set; `ujdll` contains its source.
- `fejleszt\recptor\wrecept.exe` is a background receiver that watches incoming cashier closing packages and calls `unpackerrutin`.
- `fejleszt\arfolyam\verzio22\arfolyam.exe` is the latest full standalone legacy rate editor/publisher found here.

Operational split to preserve:

- Backend/server: ingestion, decoding, validation, audit, scheduled jobs, publication authority, cash-desk distribution.
- Central workstation: authenticated UI for főértéktár, internal auditor, central operators, management/reporting.
- Cashier client: separate local cash-desk workflow.

High-priority central workstation modules:

- Árfolyamkészítő.
- Zárás beérkezés dashboard.
- Beérkezett adatok áttekintése.
- MNB/compliance reports.
- Átlagárfolyam and árfolyameltérítés.
- WU/ÁFA/TRB/stornó audit views.
- Dolgozók, jutalék, tranzakciós díjak.
- Iroda/körzet/értéktár maintenance.
- Bank import/export.
- Ügyfél/jogi személy/okmány/internal audit tools.

Security decisions:

- Do not port legacy `userin.dll` login. Replace with Google OAuth + backend roles.
- Do not expose Firebird/database credentials to Electron.
- Do not rely on FTP as the primary modern publication path.
- Keep server-side validation and audit for all privileged writes.
- Use idempotent, auditable command/package submission from the workstation.

Primary architecture document:

- `docs/architecture/central-workstation-legacy-module-inventory.md`

Implementation progress on 2026-05-12:

- `Zárás beérkezés dashboard` is now implemented in the central workstation.
- Legacy equivalents covered in this step: `zarasctrl.dll`, `beerk.dll`,
  `missctrl.dll`, and the missing-closing logic formerly tied to `daybook.fdb`.
- New central route: `/central/closing-control`.
- Backend `ClosingControlService` now returns every active branch for the selected
  date, including synthetic missing rows when no `closing_control` record exists.
- This fixes the dangerous blind spot where a missing closing could be invisible
  because the row itself was missing.
- New installer: `Kozponti-Iranyitokozpont-Setup-2.5.43.exe`.
- Downloads copy:
  `C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.43.exe`.
- SHA256:
  `9D51AF39DA0F408CCB87553FB3B7A924315F5F8AED1483E5841AF888583AD5A9`.

Implementation progress on 2026-05-12, next step:

- `Beérkezett adatok áttekintése` is now implemented in the central workstation.
- Legacy equivalents covered in this step: `beerk.dll`, `datadisp.dll`,
  `getdisp.dll`, and the daily report/received package overview around
  `daybook.fdb`.
- New backend endpoint:
  `GET /api/v1/central/received-data/status?date=YYYY-MM-DD`.
- New central route: `/central/received-data`.
- The backend merges active branches, daily reports, and closing-control rows so
  every active branch is visible even when the daily report is missing.
- New installer: `Kozponti-Iranyitokozpont-Setup-2.5.44.exe`.
- Downloads copy:
  `C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.44.exe`.
- SHA256:
  `0B273FAF1A8CE69870D0B9DD65C6EF59CBBE21B94997E94570B5022A1FD8F056`.
