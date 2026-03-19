# Audit Daily Execution Checklist

Datum:
Commit:
Auditor:

## Nap 1 - Baseline, quality gate, security

- [ ] Git baseline rogzitve (status, HEAD, sync).
- [ ] Runtime baseline rogzitve (docker compose ps, health endpoint).
- [ ] Backend teljes tesztkor lefutott.
- [ ] Frontend-react lint/build/test gate lefutott.
- [ ] penztar-client test/typecheck/check:ipc gate lefutott.
- [ ] Controller security coverage audit lefutott.
- [ ] Tenancy (companyId) white-box ellenorzes lefutott.
- [ ] Elso finding register feltoltve.

Nap 1 kimenet:

- [ ] PASS/FAIL statusz frissitve.
- [ ] Kritikus findingek (Sev-1/Sev-2) listazva.

## Nap 2 - Uzleti logika, compliance, pontossag

- [ ] Veteleladas/sztorno black-box oracle tesztek lefutottak.
- [ ] AML kuszobok es trigger logika tesztelve.
- [ ] Napnyitas/napzaras/dekad/havi scenariok tesztelve.
- [ ] Treasury aggregacios egyezes tesztelve (branch/group/company).
- [ ] Foglalo eletciklus parity tesztelve.
- [ ] Numerikus pontossag tesztek lefutottak (egyenlet, storno, kerekites).
- [ ] Compliance checkpoint frissitve.

Nap 2 kimenet:

- [ ] Modulonkenti PASS/FAIL matrix frissitve.
- [ ] Minden eltereshez kockazati besorolas megtortent.

## Nap 3 - Integracio, offline/szinkron, vegso minosites

- [ ] NAV/POS/nyomtatas/scanner in-scope tesztek lefutottak vagy N/A formalizalt.
- [ ] Offline/szinkron konfliktus es helyreallitas tesztek lefutottak.
- [ ] Electron cashier manualis smoke checklist lefutott: docs/ELECTRON_CASHIER_SMOKE_CHECKLIST.md
- [ ] Legacy parity delta lista veglegesitve.
- [ ] Finding register veglegesitve.
- [ ] GO/CONDITIONAL GO/NO-GO javaslat letrehozva.

Nap 3 kimenet:

- [ ] Executive summary kesz.
- [ ] Atadando bizonyitekcsomag teljes.

## Vegso atadas check

- [ ] Finding register MD
- [ ] Finding register CSV
- [ ] PASS/FAIL matrix
- [ ] Security/tenancy riport
- [ ] Numerikus pontossagi riport
- [ ] UAT bizonyitek tar
- [ ] Vegso minosites dokumentum
