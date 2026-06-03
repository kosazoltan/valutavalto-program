# AI fejlesztesi protokoll (EXCMD alapu)

Cel: az EXCMD utasitasfajlokbol reprodukalhato modon keszuljon
1) ticket,
2) implementacios spec,
3) teszt,
4) kod,
5) validacio.

Hataly: valutavalto-program repo, backend + frontend + electron kliensek.

## 0. Bemenet (Single Source of Truth)

Kotelezo forrasok:
- EXCMD modul fajl (pl. b1, b2, b3b, b5b, legacy module md)
- kapcsolodo media kivonat (ha van)
- kapcsolodo inventory/audit fajl (ha relevans)

Szabaly:
- Egy fejlesztesi ciklus = egy modul vagy egy nagyon szuk almodul.
- Ne keverj 2-3 kulon domain modult egy ticketbe.

## 1. Modul kivalasztas

Valassz egyetlen EXCMD modult.
Kotelezo mezok kinyerese:
- title
- modul
- kategoria
- alkalmazas
- szerepkor
- forrasok
- functional_spec FR pontok

Kimenet: Modul Input Card (MIC)

Template:

```md
MIC
- Modul: <modul>
- Kategoria: <kategoria>
- Alkalmazas: <alkalmazas>
- Fobb FR-ek: <FR-... lista>
- Fuggosegek: <backend/frontend/db/external>
- Kockazat: Alacsony/Kozepes/Magas
```

## 2. Ticket generalas (Issue format)

Minden MIC-bol 1-3 ticket keszulhet, de egy ticket csak egy konkret ertekadas.

Ticket template:

```md
Cim: [<modul>] <egy konkret fejlesztes>

Leiras:
- Uzleti cel: <1-2 mondat>
- Scope IN: <pontok>
- Scope OUT: <pontok>
- Erintett FR: <FR kodok>

Elfogadasi kriteriumok:
1. ...
2. ...
3. ...

Technikai erintettseg:
- Backend: <igen/nem + csomagok>
- Frontend: <igen/nem + oldalak/komponensek>
- DB: <igen/nem + tabla/oszlop/migracio>

Biztonsag/megfeleles:
- tenant izolacio (companyId)
- audit log
- AML/Pmt szabaly (ha relevans)
```

## 3. Implementacios spec generalas

A ticketbol keszul egy rovid, kodkozeli spec.

Spec template:

```md
Implementacios spec - <ticket cim>

1. Architekturadontes
- Miert ez a megoldas?
- Milyen alternativat vetettunk el?

2. Adatmodell
- Uj/valtozo DTO/entity/repo
- Migracio igen/nem

3. API/Service szerzodes
- Endpoint / method / input / output
- Hibakodok

4. UI viselkedes
- Mezo validaciok
- Jogosultsagok
- Hibaallapotok

5. Nem-funkcionalis elvaras
- Teljesitmeny
- Naplozas
- Traceability
```

## 4. Teszt generalas (kod elott)

Sorrend kotelezo:
1. Unit teszt
2. Integracios teszt (ha van API/DB)
3. UI/component teszt (ha van kepernyo valtozas)

Minimalis tesztcsomag:
- 1 happy path
- 1 jogosultsagi tiltott eset
- 1 validacios hiba
- 1 regresszios eset az erintett FR-re

Teszt-nev konvencio:
- `should_<elvart_viselkedes>_when_<feltetel>`

## 5. Kod generalas

Kodolas szabalyai:
- Minimalis diff, nincs felesleges refaktor.
- Publikus API csak indokolt esetben valtozzon.
- tenant szuro kotelezo (companyId) minden vedett adatra.
- Nema catch tilos.
- String osszefuzeses SQL tilos.

Kimenet:
- Backend kod
- Frontend kod (ha kell)
- Migracio (ha kell)
- Tesztek

## 6. Validacio (Definition of Done)

Kotelezo ellenorzes ticket zaras elott:
1. Erintett tesztek zold
2. Typecheck/lint zold (erintett projektre)
3. FR kriteriumok kipipalva
4. Security alapszabalyok teljesulnek
5. Dokumentacio frissitve (ha szerzodes valtozott)

DoD template:

```md
DoD - <ticket cim>
- [ ] AC1 teljesult
- [ ] AC2 teljesult
- [ ] AC3 teljesult
- [ ] Tesztek zold
- [ ] Lint/typecheck zold
- [ ] Tenant izolacio ellenorizve
- [ ] Audit log ellenorizve (ha relevans)
```

## 7. Agent workflow (futtathato uzemmod)

Javasolt pipeline egy modulra:
1. EXCMD olvasas -> MIC
2. MIC -> ticket draft
3. ticket -> implementacios spec
4. spec -> tesztvaz + tesztfajlok
5. tesztekhez igazodva kod implementalas
6. lokalis validacio
7. rovid changelog bejegyzes

## 8. Prompt sablonok AI ugynokoknek

### 8.1 Ticket generator prompt

```text
Feladat: Keszits issue ticketet az alabbi EXCMD modul alapjan.
Bemenet: <EXCMD modul tartalom>
Kimenet: cim, scope in/out, AC-k, technikai erintettseg, kockazatok.
Szabaly: csak teny, ne talalj ki uj uzleti kovetelmenyt.
```

### 8.2 Spec generator prompt

```text
Feladat: Keszits implementacios specet a ticketbol.
Bemenet: <ticket>
Kimenet: architekturadontes, API/Service szerzodes, adatmodell, UI, hibakezeles, tesztstrategia.
Szabaly: minimalis valtozas, meglvo kodstilus kovetese.
```

### 8.3 Test-first prompt

```text
Feladat: Ird meg eloszor a teszteket a ticket AC alapjan.
Bemenet: <ticket + spec>
Kimenet: unit/integration/ui tesztek, negativ esetekkel.
Szabaly: legalabb 1 jogosultsagi es 1 validacios negativ teszt kotelezo.
```

### 8.4 Code implementation prompt

```text
Feladat: Implementald a kodot ugy, hogy a mar meglevo tesztek atmenjenek.
Bemenet: <ticket + spec + tesztek>
Kimenet: minimalis diffu kodmodositas.
Szabaly: tenant izolacio, audit, secure coding kotelezo.
```

## 9. Javasolt fajl-elhelyezes

- Ticket: docs/superpowers/plans/
- Implementacios spec: docs/superpowers/specs/
- Teszt: erintett modul test konyvtara
- Osszegzes: rovid bejegyzes a megfelelo changelog/notes fajlba

## 10. Exit kriterium

A protokoll akkor tekintheto sikeresnek, ha:
- az EXCMD FR pontokbol visszavezeto, teszttel bizonyitott kod keszul,
- a valtozasok reprodukalhatoak,
- a kovetkezo ugynok ugyanebbol a dokumentumbol ugyanazt a folyamatot vegig tudja futni.
