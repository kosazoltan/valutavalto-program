# Aktiv agent mandate index

Frissitve: 2026-06-01

Ez az index korabban tul sok always-on szabalyra hivatkozott. Az uj rendben az
agent nem innen indul minden sessionben; ezt csak akkor kell olvasni, ha a
feladat kifejezetten mandate-et vagy agent-mukodest erint.

## Aktiv forrasok

1. `AGENTS.md` - egyetlen operativ agent munkamod es precedence.
2. `AI_CONTRACT.md` - hard tiltasok: secret, teszt-integritas, git hygiene,
   security mintak.
3. `AI_CONSTITUTION.md` - rovid mukodesi alapelvek es tiltott agent-patternok.
4. `CLAUDE.md` - projekt/domain/parancs kontekstus.

## On-demand forrasok

- `vault/feedback/*.md` - csak konkret user-direktiva vagy historikus ok
  vizsgalatakor.
- `docs/knowledge/memory/*` - csak regi dontes vagy release-tortenet kutatasakor.
- `.cursor/rules/*.mdc` - celzott Cursor workflow, `alwaysApply: false`.

## Hatályon kivul helyezett mukodesi mintak

- Minden session elejen teljes mandate/vault beolvasas.
- Minden kodolasi feladatra automatikus full security gate.
- Minden push nelkuli dokumentacio- vagy lokalis kodvaltozasra GitHub/AI polling.
- Kotelezett ketkoros sajat agent-review normal feladatnal.
- 15 perces polling vagy teljes CI-visszaolvasas ott, ahol nem tortent push/PR.
- Kotelezett hosszu zaro audit-template minden valasz vegen.

## Megmarado kemeny szabalyok

- Nincs hallucinalt sikerallitas.
- Nincs secret vagy eles credential fajlban/chatben.
- Nincs teszt/CI/security gyengites a zold eredmenyert.
- Deploy/release elott teljes relevans gate es evidence kell.
- Ha nincs bizonyitek, azt roviden es oszinten kell jelenteni.