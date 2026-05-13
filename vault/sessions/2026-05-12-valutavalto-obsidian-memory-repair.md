---
title: "Valutavalto Obsidian memoria javitas es EXZ elhatarolas"
date: 2026-05-12
repo: "D:\\repo\\valutavalto-program"
vault: "D:\\repo\\valutavalto-program\\vault"
status: "active"
priority: "P0"
---

# Valutavalto Obsidian memoria javitas es EXZ elhatarolas

## Dontes

A `valutavalto-program` memoriaja onallo memoria. Nem keverheto az EXZ repo memoriajaval, akkor sem, ha az Obsidian desktop korabban EXZ vaultot nyitott meg.

Itt a kanonikus vault:

- `D:\repo\valutavalto-program\vault`

Az EXZ vault nem forrasa es nem celpontja a valutavalto fejlesztesi memorianak.

## Javitas

Az Obsidian desktop alkalmazas megtalalva:

- `C:\Users\Kósa Zoltán\AppData\Local\Programs\Obsidian\Obsidian.exe`

A Valutavalto vaultba telepitve es engedelyezve lett az Obsidian Local REST API plugin. A plugin runtime/config mappa nem kerulhet gitbe, mert helyi API kulcsot es tanusitvany-adatokat tartalmaz:

- `vault/.obsidian/`

Ehhez a `.gitignore` tartalmazza a `vault/.obsidian/` tiltast.

A repo lokal `.env` fajlja tartalmazza a Valutavalto-specifikus Obsidian beallitasokat:

- `OBSIDIAN_API_KEY`
- `OBSIDIAN_HOST=127.0.0.1`
- `OBSIDIAN_PORT=27124`
- `OBSIDIAN_PROTOCOL=https`
- `OBSIDIAN_VAULT_PATH=D:\repo\valutavalto-program\vault`

Titok nem kerulhet commitba vagy dokumentacioba.

## Technikai megjegyzes

Az Obsidian 1.12 alatt a community plugin inditashoz nem eleg csak a vault szintu `community-plugins.json`. Az Electron `localStorage` alatt a Valutavalto vault plugin engedelyezesi flagje is kellett:

- `enable-plugin-valutavalto-program-memory=true`

Ez be lett allitva Obsidian DevTools protokollon keresztul, nem LevelDB kezi szerkesztessel.

## Repo memoria script

A `scripts/repo-memory.mjs` frissult:

- betolti a repo lokal `.env` fajljat;
- az `OBSIDIAN_*` valtozoknal a repo sajat `.env` fajlja felulirja a kulso shell kornyezetet, hogy EXZ vagy mas vault kulcsa ne keveredhessen be;
- az `OBSIDIAN_API_KEY` mellett kezeli az `OBSIDIAN_SYNC_TOKEN` es `OBSIDIAN_KEY` fallbackeket is;
- az Obsidian REST base URL-t env alapjan kepzi;
- a Valutavalto Obsidian mirror fajlt a nyitott Obsidian vaultba is masolja;
- a Local REST API onalairt HTTPS tanusitvanyat csak a lokalis Obsidian requestnel kezeli kulon, globalis TLS kikapcsolas nelkul.

Ellenorzes:

- `npm run memory:status` eredmeny: QMD/YAML/Cognee/vector/Obsidian/reports OK
- Obsidian REST: `https://127.0.0.1:27124/` status `200`

## Munkaszabaly

Minden Valutavalto fejlesztesi dontest, auditot es architekturalis felismerest a `D:\repo\valutavalto-program` memoriaretegeibe kell irni. Az EXZ memoria csak EXZ munka eseten hasznalhato.
