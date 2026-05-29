# Valutaváltó — AKTUÁLIS ÁLLAPOT CACHE (token-takarékos, qmd-indexelt)

> Cél: 1 helyen a verifikált aktuális állapot, hogy ne kelljen újra-deriválni commitokból/fájlokból.
> Frissítve: 2026-05-29. Verzió: **v2.27.53** (4-way sync OK, prod ÉLES, FK-005 healthy).
> Telepítő-bundle: **v2.27.52** (a #913 backend-only → auto-deploy, nem kell új telepítő).

## Verzió + deploy
- main = **2.27.52**; backend prod `https://excvaluta.com` ÉLES (`service_version:2.27.52`, bootstrap-status 200).
- Auto-deploy működik (merge → Hetzner). Telepítők unsigned (DigiCert EV CS pending).
- Friss telepítők: Penztar-Setup / Kozponti-Munkaallomas / Penztar-Eltavolito **-2.27.52** (dist/release + Downloads).

## Prod-hozzáférés (TÉNY)
- Hetzner primary `95.216.191.162`, SSH kulcs `~/.ssh/hetzner_ed25519` (root).
- Backend: systemd `valuta-backend` (java -jar /opt/valutavalto/backend, NEM docker).
- Log: logback JSON fájl `/opt/valutavalto/backend/logs/valuta-backend.json.log` (+ Loki/Promtail). journalctl ÜRES (fájl-appender).

## KÉSZ + VERIFIKÁLT (main HEAD-en, tartalom-szinten, nem csak commit-üzenet)
- **FK-04 C/E** (árfolyamkészítő csoport-lapok): csempés UI (#878/#893), képletmotor `workgroupSheetFormula.ts` (#879) + compute `workgroupSheetCompute.ts` (#900) + storage `workgroupSheetStorage.ts` (#901) + protection `workgroupProtection.ts` (#902) + UI-bekötés `RateCreationPage`/`RateGrid` (#906) + backend védelem `RatePublishService.validateRateProtection` (#899, helyreállította a SOSEM-mergelt #885-öt) + D limitek (#884) + E.1 flag (#882).
- **FK-013** értéktári átadás-átvétel területi szűrés (#892/#894/#897) — 8/8 követelmény.
- **FK-006** valutanem központi törzs (#876/#880, V271/V274) — 13/13.
- **FK-005** Országos készlet 0 Ft: prod-verifikált MEGOLDOTT (getAllStock 1156 sor, FOERTEKTAR nincs territory-scope-olva). #895 csak diag-log volt; a #859/#894 deploy javította.
- **FK-003/004** napi forgalom Ft fix (#903), Excel cégcím (#905), snapshot törzs-vezérelt (#880).
- **v2.5.54** kozmetikák: #9 dashboard-dátum, #11 sidebar-highlight (prefix-nav #904), #17 szóköz, #6/#20 ablak-cím (#907).
- **AI-review readback fixek** (#909/#910/#911): templateId-dedup, effektív-ráta védelem (base+spread, 4-tizedes), undo+formulas, kereszt-csoport korrupció (undo-clear csoportváltáskor + stale-snapshot revert).

## DEV-BACKLOG (dokumentáltan halasztott VALÓDI tételek — innen folytatandó)
1. ✅ **KÉSZ (#913, v2.27.53):** FK-003/004 multi-line forgalom a snapshotban — single-line (Transaction) + line (TransactionLine.banknoteCount/hufValue) összeg valutánként. ÚJ backlog ↓:
1b. **DailyBalanceService multi-line** (a napi ZÁRÁS ugyanazt a header-alapú `sumDailyTurnoverByCurrency`-t használja → multi-valutás bizonylatnál téves per-valuta zárás). NAGY kockázat (pénzügyi zárás) → dedikált teszttel, gondosan, külön PR-ben.
2. **FK-003/004 forgalom-időszak**: naptári napra szűr, nem a pénztár nyitás–zárás intervallumára.
3. **FK-003/004 snapshot-jogosultság**: 5 szerepkör; a spec „kizárólag főértéktár".
4. **#899 fallback-official edge**: ha template.officialRate=null, a védelem skippel, de a publish fallback-J-t rendel.
5. **#906 fix-rátás csoport #NN-cél**: a fix-rátás (képlet nélküli) csoport J–S értékei nem mentődnek a #NN snapshotba (revert miatt). Helyes fix: per-csoport rate-reset/scope.
6. **#907 full-mód web cím**: a plain web admin (no flavor) „Valuta Pénztár"-t kap.
7. **FK-006 buy/sell currency-status prompt**: a memóriában „nyitott" — a kódban nem azonosítható; tesztelői képernyőkép kell.

## Munkamód (TÉNY)
- `gh pr merge --squash --admin --delete-branch` **állandó autonóm engedéllyel** (lásd auto-memory `feedback_gh_pr_merge_preauthorized`).
- 300-LOC/5-fájl kontraktus PR-enként → modulhatár-bontás. Verzió-bump 4-way (`scripts/check-version-sync.mjs`).
- Branch-protection `strict:true` + 1 review → a banner-artifact oka; gyengítését NEM teszem user-explicit-policy nélkül.
