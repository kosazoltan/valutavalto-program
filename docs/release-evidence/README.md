# Release evidence — Product-Ready Verifier

Ez a mappa a **product-ready (élesítési) kapu** emberi bizonyítékait tartalmazza.
A verifier (`scripts/product-ready-verifier.mjs`) **soha nem generál evidence-et** —
csak validálja, amit ember tett ide: kötelező mezők, kitöltetlen placeholder-tiltás,
dátum-épség és frissesség (≤60 nap), repo-keresztellenőrzés (verzió-egyezés,
enforcement-flagek a backend kódból, SHA-256).

## Parancsok

```bash
npm run verify:status                   # áttekintő státusz (nem blokkol)
npm run verify:acceptance:complete      # 1. staging/production acceptance riport
npm run verify:approvals:complete       # 2. product/ops/compliance jóváhagyások
npm run verify:compliance:complete      # 3. compliance döntés + DB export + flag-döntések
npm run verify:dr-drill:complete        # 4. valódi DR restore drill
npm run verify:monitoring:complete      # 5. 168 órás monitoring evidence
npm run verify:installer:complete       # 6. aláírt telepítő + tiszta VM proof
npm run verify:evidence:complete        # 7. final external evidence (összegző sign-off)
npm run verify:internal:complete        # 8. repo-oldali gépi DoD
npm run verify:final-gate               # MIND a 8 kapu; exit 1, ha bármi nem zöld
```

## Munkafolyamat

1. Másold a sablont a `templates/` mappából ide, a `.template` tag nélkül
   (pl. `templates/acceptance-report.template.json` → `acceptance-report.json`).
2. Töltsd ki VALÓS adatokkal. Minden `KITÖLTENDŐ` placeholder bukást okoz —
   ez szándékos: kitöltetlen vagy hasraütéses sablon nem mehet át a kapun.
3. Futtasd a hozzá tartozó `verify:<check>:complete` parancsot.
4. Ha mind a 7 evidence + a gépi `internal` check zöld → `npm run verify:final-gate`
   adja ki a **PRODUCT READY** verdiktet.

## Evidence fájlok

| Fájl | Kapu | Mit igazol |
|---|---|---|
| `acceptance-report.json` | acceptance | Staging/production átvételi teszt: vétel, eladás, sztornó, napzárás, havi zárás forgatókönyvek PASS, a kiadandó verzión |
| `approvals.json` | approvals | Product + ops + compliance szerepű, névvel/dátummal/nyilatkozattal adott APPROVED döntések; a product-jóváhagyás tételesen vállalja a nyitott gap-listát |
| `compliance-decision.json` | compliance | Compliance-döntés + DB-export metaadat (hely + SHA-256, a dump NEM kerül a repóba) + a kódban létező MINDEN `*_ENFORCEMENT` flagről explicit ON/OFF/DEFER döntés |
| `dr-restore-drill.json` | dr-drill | Valódi visszaállítási gyakorlat: mért restore-idő ≤ 60 perc + helyreállítás-utáni ellenőrzések PASS |
| `monitoring-168h.json` | monitoring | Legalább 168 órás (7 nap) folyamatos éles monitoring: uptime ≥ 99%, p99 latency, hibaarány, megoldatlan incidens nincs |
| `signed-installer-vm-proof.json` | installer | Aláírt (időbélyeges) telepítő SHA-256-tal + tiszta VM-en install/launch/uninstall PASS |
| `final-external-evidence.json` | evidence | Összegző sign-off: név/szerep/dátum + a 6 rész-evidence tételes megerősítése |

A 8. kapu (`internal`) nem evidence-fájl, hanem repo-tény: end-user kézikönyvek
(`docs/user-manual/`), DR/monitoring/compliance runbookok (`docs/operations/`),
acceptance test suite megléte, 4-way verzió-szinkron
(`scripts/check-version-sync.mjs`) és 30 napnál frissebb, PASSED security gate
riport (`security-reports/latest/gate-status.json`).

## Kritérium-források (tényalap)

- `vault/references/product-ready-roadmap-2026-05-06.md` — "Done definition (Product Ready)"
  (innen: 7 napos monitoring, 1 órás DR-helyreállítás, acceptance suite, manuálok, compliance check)
- `FEJLESZTESI_IRANY_AUDIT.md` — "Definition of Done" (verzió-szinkron, gate-ek, bizonyíték-elv)
- `EXCMD/2026-06-03_AML-go-live-terv.md` — enforcement-flag go-live döntési sorrend
- `EXCMD/_ai-protokoll/2026-06-04-excmd-teljes-audit-statusz-es-javitas.md` — nyitott gap-lista,
  amelyet a product-jóváhagyásnak tételesen vállalnia kell

## Adatvédelem

DB-dump, ügyféladat, secret **soha** nem kerülhet ebbe a mappába (sem a repóba).
A `compliance-decision.json` csak az export *metaadatát* (hely, hash, időpont,
módszer) rögzíti; ha a megadott útvonal mégis a repón belülre mutat, a verifier
ellenőrzi a hash-t, de PII-tartalmú dump commitolása tilos (CLAUDE.md invariáns).
