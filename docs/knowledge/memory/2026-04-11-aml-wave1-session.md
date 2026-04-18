---
type: session-log
scope: workspace-shared
version: 2026-04-11
format: structured-lookup
encoding: utf-8
description: "Session memory for AML wave 1 parity closure and gate stabilization"
load: on-demand
---

# 2026-04-11 AML Wave 1 Session Memory

## S1 SESSION_GOAL

Cel:

- az AML / BIGCTRL / KYC / sanctions parity elso hullamanak tenyleges lezarsa
- a WU-specifikus AML bypassok megszuntetese
- a parity bizonyitekok es a security gate ujraszinkronizalasa

## S2 SESSION_DELIVERABLES

Ebben a sessionben lezart elemek:

1. `AmlService.checkTransaction(..., currencyCode)` tranzakcios hivaslancba kotve.
2. Foreign USD blokk parity bizonyitva klasszikus tranzakcios es WU hivaslancban.
3. `WesternUnionService` IC_IN / IC_OUT AML gate aktiv lett.
4. WU AML HUF-hiany eseten USD * exchangeRate becslessel fut.
5. WU AML fail-closed lett, ha van USD, de nincs HUF es nincs ervenyes arfolyam.
6. Aktiv belso tiltolista-egyezes blokkolja a tranzakciot.
7. Szankcios talalat prioritasat regresszios teszt bizonyitja a blacklist ellenorzessel szemben.
8. AML parity markdown + generated CSV a valos allapothoz lett huzva.
9. Security gate ujrafuttatva es PASS allapotba visszahozva.

## S3 CRITICAL_CODE_LEARNINGS

Tartos tanulsagok:

- Az AML parityt nem eleg az `AmlService.classifyTransaction` szintjen bizonyitani; a teljes caller chainre kell teszt.
- A WU IC utaknal a "nincs HUF, akkor nincs AML" viselkedes veszelyes. Itt fail-closed policy kell.
- A szankcios screeningnek rovidzarnia kell a tovabbi customer-control ellenorzeseket.
- A blacklist akkor hasznos parity-bizonyitek, ha tranzakcio-elutasitasban is megjelenik, nem csak CRUD szintu servicekent letezik.
- A security gate regi reportjai felrevezethetnek; mindig friss futast kell nezni, nem snapshotot.

## S4 THREE_LAYER_MEMORY

### L1 EPISODIC

- Session-fokusz: AML wave 1 closure.
- Fobb lepesek: currency propagation -> WU IC AML -> blacklist block -> sanctions priority -> WU fail-closed -> gate verification.

### L2 SEMANTIC

Tartos szabalyok:

- `R-type--1`: foreign customer cannot get USD.
- `R-blacklist`: active internal prohibition must block transaction flow.
- `R-sanctions`: sanctions check has priority over blacklist follow-up.
- `R-WU-aml`: WU AML must cover send/receive and IC channels, and must fail closed without computable AML base amount.

### L3 EXECUTION

Kovetkezo huzasok:

- `reconcile-sources`: parity review es gap doc statuszok osszehuzasa.
- `close-wave1-transactions`: transaction / fee / rounding / storno parity regression wave.
- P0 nyitott AML gap mar csak: `R-conversion-double`.

## S5 VERIFICATION_EVIDENCE

Bizonyitek:

- PASS: `AmlBigctrlC1C2C3Test`
- PASS: `AmlControllerCheckAllThresholdsTest`
- PASS: `AmlServiceTest`
- PASS: `AmlDeadlineTrackingTest`
- PASS: `AmlFlowTest`
- PASS: `AmlServiceCompletionTest`
- PASS: `WesternUnionServiceTest`
- PASS: `scripts/security/run-security-gate.ps1`

## S6 STATE_AFTER_SESSION

Aktualis allapot:

- AML / BIGCTRL / KYC / sanctions elso hullam: lezart
- Security gate: `PASSED`
- Kovetkezo fo munkafolyam: tranzakcios parity hullam
