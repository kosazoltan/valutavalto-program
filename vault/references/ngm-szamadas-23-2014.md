---
name: NGM 23/2014 szigoru szamadasu bizonylatok (Valuta)
description: Magyar szamlazasi jogszabaly kulcstetelek - valutaválto penztar-kontextusra applikalva
type: reference
---

# NGM 23/2014 (VI.30.) — szigoru szamadasu bizonylatok

## Sorszam-szabalyok

- Folyamatos, hezagok nelkuli, egyedi sorszam minden bizonylatra.
- A sorszam az **adoigazgatasi azonositasra alkalmas**.
- Sorszam-gap vagy duplikacio ado-birsagot eredmenyez (adozona.hu).

## Nyilvantartasi kovetelmeny

- Naprakeszen vezetendo, a bizonylat KIALLITAS PILLANATABAN a vegleges
  sorszam rogzitendo - NEM kesobb (vallalkozo.info).
- A nyilvantartas tartalmazza: bizonylat neve/szamjele, beszerzes datuma,
  felhasznalas datuma, selejtezes datuma.

## Offline rendszer implikacioja valutavaltora

- A helyi gepen generalt bizonylatnak mar a kiallitaskor VEGLEGES
  sorszammal kell rendelkeznie.
- A szerverre-szinkron nem adhat uj sorszamot, csak az audit-napot egeszit.
- A "draft" status NEM KONFORM a NGM 23/2014-gyel.

## Penalty (NAV)

- Nem-magan adofizeto eseten **500 000 Ft** birsag bizonylat-hiany vagy
  nyilvantartas-szabalytalansag eseten.

## Jelenlegi architektura allapot (2026-04-20)

- Szerver: `ReceiptSequence` entitas + `ReceiptSequenceService` (PESSIMISTIC
  LOCK, per-branch+prefix, V/E/K formatum). Konform.
- Szerver: `check continuity` logika (napzaras, gap-detect). Konform.
- Electron: korabban `P-{id}-draft` format - NEM konform, javitva L-{id}-re.
- Kovetkezo lepes: SQLite seqNr counter + cash-register backend entitas
  (hosszabb tavu).

## Forrasok

- vallalkozo.info/ado-penzugy/szigoru-szamadasu-nyomtatvanyok-ezekre-figyeljen
- net.jogtar.hu/jogszabaly?docid=a1400023.ngm (NGM 23/2014 hatalyos)
- szamvitelilevelek.hu/levelek/2017/01/12/7175/
