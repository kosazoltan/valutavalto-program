# SZERVER Legacy Üzleti Logika Teljes Migráció — Master Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A legacy Delphi 102 DLL-modul teljes üzleti logikájának 1:1 átültetése a modern Spring Boot backend-be — minden hiányzó és hibás implementáció pótlása.

**Architecture:** A meglévő service réteg kiterjesztése és javítása. Nincs szükség új modulokra — a service-ek már léteznek, de sok helyen üresek, hibásak vagy hiányosak. A javítások a meglévő fájlokban történnek, a legacy logika pontos átültetésével.

**Tech Stack:** Java 21, Spring Boot 3.2, Spring Data JPA, PostgreSQL, Flyway, JUnit 5 + Mockito

---

## Prioritás mátrix

| Prioritás | Terület | Alplan fájl |
|-----------|---------|-------------|
| P0-KRITIKUS | Tranzakciós hibák (NAV szabály!) | `plan-01-transaction-fixes.md` |
| P0-KRITIKUS | Napi forgalom valutánkénti bontás | `plan-02-turnover-currency-breakdown.md` |
| P0-KRITIKUS | Napi zárás hiányzó lépések | `plan-03-daily-closing-completion.md` |
| P0-KRITIKUS | Esti zárás csomag küldés | `plan-04-evening-closing-send.md` |
| P0-KRITIKUS | Dekád forintkontroll javítás | `plan-05-decade-report-fixes.md` |
| P1-MAGAS | Havi zárás + archív | `plan-06-monthly-closing-archive.md` |
| P1-MAGAS | AML göngyölés + terrorlista | `plan-07-aml-completion.md` |
| P1-MAGAS | WU teljes logika | `plan-08-western-union-full.md` |
| P1-MAGAS | Foglalás teljesítés | `plan-09-reservation-fulfill.md` |
| P1-MAGAS | OTP terminál bug + hiányzó parancsok | `plan-10-otp-terminal-fixes.md` |
| P2-KÖZEPES | MNB riport beküldés | `plan-11-mnb-report-submit.md` |
| P2-KÖZEPES | Címletezés javítás | `plan-12-denomination-fixes.md` |
| P2-KÖZEPES | Inventory 4-szem elv | `plan-13-inventory-controls.md` |
| P2-KÖZEPES | Report N+1 és export | `plan-14-report-optimization.md` |
| P3-ALACSONY | Sztornó részleges visszatérítés | `plan-15-partial-refund.md` |
| P3-ALACSONY | DailyBalance nyitóegyenleg cascade | `plan-16-balance-cascade.md` |

---

## Végrehajtási sorrend

A tervek egymásra épülnek:
1. **P0 tervek** (01-05): Párhuzamosan végrehajthatók, egymástól függetlenek
2. **P1 tervek** (06-10): Párhuzamosan végrehajthatók, de 01-05 után
3. **P2 tervek** (11-14): P1 után
4. **P3 tervek** (15-16): Bármikor

Becsült összidő: ~40-60 task, ~4-8 óra gépi munka.
