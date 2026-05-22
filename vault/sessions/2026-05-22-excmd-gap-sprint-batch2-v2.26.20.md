# Session 2026-05-22 (folyt.) — EXCMD gap-sprint 2. batch → v2.26.20

## Kontextus

A v2.26.19 (G5/G6+G1+G2+G4) után a felhasználó kötelező utasítása: autonóm módon, megállás nélkül folytatni a gap-javítást. A 2. batch (P1/P2/P3 gapek) szakaszonkénti merge-ekkel.

## 2. batch gapek (mind admin-merged + Hetzner auto-deploy, production HEALTHY)

| Gap | PR | Tartalom | Teszt |
|---|---|---|---|
| G18 | #771 | Havi forgalmi riport készpénzes vs bankkártyás bontás (`MonthlyReportFullDto.cash/cardTurnoverHuf`, PaymentMethod szerint) | MonthlyReportServiceTest 6/6 |
| G21 | #773 | Körlevél szerepkörönkénti visszaigazolás-megoszlás (V255 `acknowledger_role`, `getAcknowledgmentBreakdownByRole`, `GET /circulars/{id}/acknowledgment-breakdown`) | CircularServiceTest 2/2 |
| G12 | #774 | Sztornó jóváhagyás-kérés **AFTER_COMMIT** értesítés (`StornoApprovalNotificationEvent` + `@TransactionalEventListener(AFTER_COMMIT)`+`@Transactional(REQUIRES_NEW)`) — a notification-hiba nem görgetheti vissza a kérést | StornoServiceTest 10/10 |
| G9 | #775 | Pillanatnyi pénztárállás kasszanézet (`LiveCashPositionService`/Controller `GET /reports/live-cash-position`: valutánként NYITÓ/BEVÉTEL/KIADÁS/ZÁRÓ + kez.díj; FE `LiveCashPositionPage` + ReportsPage link) | LiveCashPositionServiceTest 2/2 |

Verzió-bump: PR #776 → **v2.26.20** (4-way, 6 fájl).

## AI-review tanulságok (mind javítva merge előtt/után)

- G12: `try-catch` önmagában nem véd a `@Transactional` rollback-only ellen → AFTER_COMMIT esemény + REQUIRES_NEW listener (Copilot/Sourcery). Branch-bázis hiba: a #771 a G12-t is behozta (a G18 branch tévedésből a G12-ről indult) → követő-fix #774.
- G9: ReportsPage.test.tsx fixen 11 kártyát várt → 12-re (az új live-cash kártya); TZ-safe dátum-megjelenítés (YYYY-MM-DD közvetlenül).
- G21: `Map`/`Collectors` fully-qualified → unqualified (import megvolt).
- G18/G9: PR-méret-plafon (300 LOC/5 fájl) túllépés dokumentált kivétel (BE+FE feature + version-sync).

## Telepítő-szet v2.26.20 (UNSIGNED, Downloads-ban)

- `Penztar-Setup-2.26.20-20260522.exe` — 283.8 MB (SHA-256: lásd CLAUDE.md horgony)
- `Kozponti-Iranyitokozpont-Setup-2.26.20.exe`, `Arfolyamkeszito-Setup-2.26.20.exe`, `Penztar-Eltavolito-2.26.20-20260522.exe` (verzió-független)
- Build: `ALLOW_UNSIGNED_BUILD=1` (DigiCert EV CS cert pending).

## Hátralévő backlog (`EXCMD/_compare/00-KONSZOLIDALT-GAPS.md`)

Döntően FE (futó-ökoszisztémás böngészős verifikáció kell a preview/run mandate szerint) vagy nagy/migrációs feature:
- G7 (RFM validáció-irány), G10 (zárás-wizard típusválasztó), G11 (10M engedélyező — compliance-döntés blokkol-vagy-jelez), G14 (foglaló-bizonylat render), G15 (bizonylat-szűrés bővítés), G16 (forgalmi grafikon), G17 (havi tabló UI), G19 (munkavállaló al-nyilvántartások — migráció), G20 (beállítás-képernyők — migráció), G23 (körzet-szintű havi/trend riport).
- **G3 (NAV zárás-eltérés gate) BLOKKOLT:** zárás-wizard ↔ NavClosing nincs összekötve (nincs `wizardId↔navClosingId` link) → backend-restrukturálás + böngészős verifikáció.
