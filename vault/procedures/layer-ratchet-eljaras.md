---
title: Réteg-ratchet eljárás (Clean Architecture függőségi szabály)
type: operational-procedure
tags: architecture, clean-architecture, ratchet, ci-gate, technical-debt, backend
areas: database, tenant, security, deploy
created: 2026-08-11
status: active
---

# Réteg-ratchet eljárás

## Mit véd

A Clean Architecture **függőségi szabályát**: a függőségek befelé mutatnak
(Frameworks → Adapters → Application → Domain). Konkrétan három sértés-osztályt:

| Szabály | Miért baj EBBEN a rendszerben |
|---|---|
| `Controller -> INJECT-Repository` | Átugorja a service-réteget, ahol a **tranzakcióhatár** és a **CashLockOrdering** él. OSIV kikapcsolva → tranzakció nélküli olvasás = lazy-hiba vagy deadlock-kockázat pénzmozgásnál. |
| `Service -> IMPORT-Controller` | Körkörös rétegfüggés, a use-case a delivery-mechanizmustól függ. |
| `Entity -> IMPORT/INJECT Service\|Repository` | A **domain-mag** függene az infrastruktúrától. Ez ma **0** — ezt az állapotot védjük regressziótól. |

## Miért ratchet, és nem sima kapu

Mért kiindulás (2026-08-11): **39 sértés / 23 controller**, 706 annotált
osztályból. Ezt egy PR-ben javítani élő pénzügyi rendszerben felmérhetetlen
blast radius — minden áthelyezés tranzakcióhatárt mozgat.

Ezért: a mért adósság **baseline-ban rögzítve**, és

- **új / nőtt** sértés → `exit 1`, a CI bukik (BLOCKING),
- **megszűnt / csökkent** → `exit 0` + felszólítás a baseline frissítésére,
- **változatlan** → `exit 0`.

A szám **csak lefelé mozdulhat**. Az adósság monoton csökken, mega-PR nélkül.

## Parancsok

```bash
npm run check:layer-ratchet                                          # CI-vel azonos kapu
python scripts/dev-tools/layer-violation-scan.py                     # teljes riport (exit 1 ha van sértés)
python scripts/dev-tools/layer-violation-scan.py --json              # gépi kimenet
python scripts/dev-tools/layer-violation-scan.py --write-baseline    # javítás UTÁN: baseline frissítés
```

CI: `.github/workflows/business-invariant-guard.yml` **#16 (BLOCKING)**.
Baseline: `scripts/dev-tools/layer-violation.baseline.json` (commitolt).

## Ha a kapu bukik

1. **Ne a baseline-t emeld.** A baseline növelése code review-ban indoklás
   nélkül elutasítandó — az az adósság legitimálása.
2. Vezesd a hívást a service-rétegen keresztül: a controller a use-case
   service-t injektálja, a repository-hozzáférés a service `@Transactional`
   metódusán belül marad.
3. Ha az adott végpont tisztán olvasó és tenant-független referencia-adat
   (pl. TEAOR-kódok, szótár), akkor is service-en át megy — a kivételt
   **nevesíteni** kell, nem csendben hagyni.

## Ha javítottál

```bash
python scripts/dev-tools/layer-violation-scan.py --check-baseline   # "IMPROVED" üzenetet ad
python scripts/dev-tools/layer-violation-scan.py --write-baseline   # csökkentett szám
git add scripts/dev-tools/layer-violation.baseline.json
```

## Baseline-kulcs tervezési megjegyzés

A kulcs `(posix relatív út, réteg, szabály)` hármas + darabszám —
**szándékosan nem tartalmaz sorszámot**. Egy sor beszúrása a fájl elejére
nem törheti el a baseline-t, különben hamis regressziót jelentene.

## Kapu-bizonyítás (kötelező minden gate-nél)

A kapu csak akkor kapu, ha bizonyítottan bukik. Igazolt 2026-08-11-én:

```
--check-baseline                              -> exit 0
+ injektált tiltott repo-mező (AuditDiagnosticsController)
--check-baseline                              -> exit 1  [GROWN] 1 -> 2
mutáció visszavonva
--check-baseline                              -> exit 0
```

## Kapcsolódó

- `vault/elvi/mernoki-alapelvek-valutavalto-kontextus.md` (a mögöttes elvek)
- Hermes skill: `architecture-quality-review`
- Testvér-kapuk: `check:platform-boundaries` (#15), `check-version-sync` (#14)
