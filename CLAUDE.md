# Valutavalto ERP - Claude/agent projektkontekstus

Elsodleges agent-szabaly: `AGENTS.md`. Ez a fajl csak a projekt legfontosabb
domain- es parancskontekstusa, hogy az agent ne vesszen el hosszu mandate-ekben.

## Projekt

Magyar valutavalto / penzvalto ERP. Domain: vetel, eladas, storno, napzaras,
cimletezes, arfolyam, atadas-atvetel, foglalo.

## Munkamod ebben a repoban

- Builder-first: a cel mukodo kod vagy celzott dokumentaciojavitas.
- Olvass celzottan, kodolj, majd ellenorizz kockazataranyosan.
- Ne tolts be minden `vault/**` vagy historikus mandate fajlt session-startkor.
- Teljes security/deploy gate csak deploy/release vagy security/auth/dependency/CI
  valtozasnal kotelezo.
- Ha ugyanaz a hiba ket kor utan megmarad, valts diagnosztikai tengelyt; ne
  futtasd ujra ugyanazt a gate-et.

## Nem-informatikus vegfelhasznalo elv

Kollegaknak nem adunk parancssort vagy manualis rendszergazdai lepeseket. A
telepito/diagnosztika vegezze el automatikusan, amit lehet. Vegfelhasznaloi
deliverable csak akkor adható ki, ha a fejlesztoi oldali javitas es validacio
tenyszeruen megtortent.

## Tech stack

- Backend: Java 21, Spring Boot, PostgreSQL, Flyway, multi-tenant.
- Frontend: React + TypeScript + Vite.
- Desktop: Electron kliensek (`penztar-client`, `kozponti-client`,
  `arfolyam-keszito-client`).

## Fontos invariansok

- Multi-tenant: minden vedett adat `companyId` szerint izolalt.
- OSIV kikapcsolva: lazy asszociaciot service tranzakcion belul kell rendezni.
- HUF kerekites: 5 Ft-os kerekites.
- AML/Pmt. es arfolyam TTL szabalyok nem kerulhetok meg.
- Secret soha nem kerulhet kodba, chatbe vagy memoriaba.

## Gyakori parancsok

```powershell
cd backend; .\mvnw.cmd test
cd frontend-react; npm run typecheck; npm test
cd penztar-client; npm run typecheck; npm test
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

A security gate parancs deploy/release vagy security-sensitive valtozas elott
kell, nem minden apro kod- vagy dokumentacios szerkeszteshez.

## Release megjegyzes

`merge != telepito`. Telepito-build csak Electron/nativ reteg valtozasnal vagy
milestone release-nel kell.