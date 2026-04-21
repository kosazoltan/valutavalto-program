# Manualis Teszt Checklist — 2026-04-21 C-wave

## Belepesi adatok

- URL: http://localhost:5173
- Company code: `EBC`
- Worker code: `ADMIN`
- Password: `Admin1234!`

## I. Bejelentkezes + alap smoke

- [ ] http://localhost:5173 megnyilik, login form jelenik meg
- [ ] EBC / ADMIN / Admin1234! sikeres bejelentkezes
- [ ] Dashboard (főoldal) betöltődik
- [ ] Menu bal oldalon latszik (csoportok: Főértéktár, AML/Compliance, Adminisztráció stb.)

## II. C1 — Szankcios lista (AML)

Menu: "AML / Compliance" -> **"Szankciós lista (AML)"**  
URL: http://localhost:5173/sanction

- [ ] Status widget: "Aktív bejegyzések" szám + utolsó frissítés dátum
- [ ] **Szűrés tab:**
  - [ ] Név nelkul: submit gomb disabled
  - [ ] Név: "Kovacs Janos" + submit → CLEAR eredmény (zöld panel)
  - [ ] Név: "Kim Jong Un" + submit → esetleg találat (UN lista)
- [ ] **Listázás tab:** tábla jelenik meg bejegyzéseikkel (ha üres, "Nincs adat")
- [ ] **Admin/Import tab:** XML upload form + linkek a forrásokra

## III. C2 — Munkaido nyilvantartas

Menu: "Adminisztráció" -> **"Munkaidő nyilvántartás"**  
URL: http://localhost:5173/attendance

- [ ] Summary cards: bejelentkezések szám, nyitott session, ossz. munkaido
- [ ] Date range selector: default = utolsó 7 nap
- [ ] **Sajat naplom tab:** saját ADMIN bejelentkezesek láthatók
- [ ] **Csapattag tab:** worker select dropdown → valaszt mást → lista betölt
- [ ] Aktív session zöld háttér

## IV. C3 — Jogosultsag matrix

Menu: "Adminisztráció" -> **"Jogosultság mátrix"**  
URL: http://localhost:5173/settings/permission-matrix

- [ ] Grid megjelenik: rows = roles, columns = permissions (csoportositva module szerint)
- [ ] Role sor első oszlop sticky (scrollkor látszik)
- [ ] Checkbox-ok kattinthatók — változtatás után "modified" badge
- [ ] "Mentés (N)" gomb N = dirty role-ok száma
- [ ] "Elvetés" gomb visszaállítja az eredetit
- [ ] Filter input: ha "RATE" → csak RATE kódú permissions láthatók

## V. Korábbi wave-ek regresszió-teszt

### B2 Pénztáros KPI
URL: http://localhost:5173/statistics/cashier-kpi
- [ ] 4 KPI card (Összforgalom, Vétel/Eladás, Sztornó arány, Aktív pénztárosok)
- [ ] Quick range: Ma / Utolso 7 nap / Ez a honap / Egyeni
- [ ] Sort dropdown működik (nev / forgalom / tx / sztorno%)

### B1 Audit log
URL: http://localhost:5173/audit-log
- [ ] Tábla betölt: akció, entitás, pénztáros, IP
- [ ] Szűrés: akció típus, dátum, pénztáros ID, branch
- [ ] Részletek modal: régi↔új érték diff

### B3 Banki tranzakció
URL: http://localhost:5173/treasury/bank
- [ ] Tranzakciók listázása
- [ ] Új tranzakció modal
- [ ] Detail modal-ban: Deviza beerkezett + HUF atutalva workflow gombok (ha !COMPLETED)

### B4 MNB jelentesek
URL: http://localhost:5173/mnb/reports
- [ ] Year/month selector
- [ ] Generált jelentések listázva (ha van)

### B7 Arfolyam workflow
URL: http://localhost:5173/rate-management/workflow
- [ ] 3-tab: DRAFT / APPROVED / PUBLISHED
- [ ] Status badge-ek + distribution grid

## VI. Error check

- [ ] Bal alsó/jobb felső toast: nincs unexpected error
- [ ] Browser DevTools Console: nincs piros error
- [ ] Network tab: minden `/api/v1/*` 200/2xx (401-es csak a auth hiányzó hivásokra)

## VII. Logout + re-login

- [ ] Kilépés → login screen jelenik
- [ ] Visszalépés (EBC/ADMIN/Admin1234!) → dashboard

---

## Ismeretesen mukodo dolgok

- Multi-tenant: minden query companyId-ra szurve (PR #75, #76, #83)
- AI review auto-fix: PR-eken automatikusan fut (PR #88-91)
- Audit trail: RATE + STORNO eventek loggolva (PR #74)

## Ismeretesen nem-implementalt (future work)

- POS terminal eles driver (Borgun, Worldline)
- Worker Sync lock-mechanizmus (edge case)
- Installer acceptance test friss Windows VM-en
- Spring Boot 3.5.14 upgrade (amint kiad)