# Handoff — FKH-041 értéktár routing + auto-update javítás (round 2, 2026-08-28)

Branch: `pipeline/20260828-fkh041-ertektar-routing-autoupdate` (12 commit, base 94c48665: 6 round-1 + 6 round-2). Terv: `round-2/10-plan.md` (round-1 jóváhagyott része változatlan).

## Round 2: ROLE-ELSŐ telepítési-ablak döntés (a round-1 appMode-only lyuk zárása)
A riportáló terminál SQLite `app_mode='penztar'` mellett futtat értéktárost — ott az
appMode-egyből döntés nem tüzelt. Új szabály: telepítési ablak CSAK akkor nyílik, ha
`appMode='penztar'` ÉS a kanonikus szerep `penztar` (useSuiteUpdate: `activeRole ?? user?.role` kanonizálva, MainLayout-paritás). Minden más (ertektar, foertektar, ertekszallito, ismeretlen, nem-penztar mod) -> SHIFT_OPEN, napi-session API-hívás nélkül; `useAppMode().isLoading` alatt a hook semmit nem jelent.

## Pre-login: localStorage marker + fail-closed
`valuta-suite-update-last-role` marker: a login()/selectRole() írja az utolsó belépés
kanonikus szerepét (üres szerep TÖRLI). Belépőképernyőn csak `penztar` marker mellett
IDLE_BEFORE_OPEN; marker nélkül/értéktáros markerrel fail-closed SHIFT_OPEN. Következmény:
egy soha-be-nem-lépett gépen NINCS pre-login auto-install (elfogadott, Judge ITEM 1b);
az első pénztáros belépés után az ablak újra él (hideg indításkor is).

## C9 bizonyíték — JAVÍTVA (a round-1 képlet hamis volt)
`logger.info` PROD-ban DEV-only (logger.ts:13-17), így a MainLayout info-sor SOSEM kerül
main.log-ba. Éles bizonyíték: (i) a renderer WARN-sor `[SuiteUpdate] Telepitesi ablak
letiltva (FKH-041)...` (warn/error jut csak a main.log-ba) és (ii) az `automatikus
csendes telepites` HIÁNYA (suite-update.ts:396-398,406-407: SHIFT_OPEN alapérték, csak
átmenetkor naplóz -> `muszak-allapot:` sor sincs).

## Round-1 örökség (változatlanul érvényes)
defaultProtectedRoute + App.tsx (role-alapú `/` landolás), MainLayout
shouldRequireDailySession (role-tudatos kapu), LoginPage appModeLoading-guard.
Elfogadott trade-off: értéktár/értéktáros gép sosem auto-telepít; Penztar-Setup marad.
Offline restore (offlineAuthRestore.ts:54-64) meglévő viselkedés, nem regresszió.
