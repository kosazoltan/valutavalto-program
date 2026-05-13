---
title: Helyi árfolyamkészítő architektúra döntés
date: 2026-05-12
author: Kósa Zoltán
priority: critical
status: active
---

# Helyi árfolyamkészítő architektúra döntés

Felhasználói döntés: az árfolyamkészítő ne a szerveren fusson nyitott
szerveroldali szerkesztőként. A főértéktáros külön, helyileg telepített
árfolyamkészítő alkalmazásban készítse el az árfolyamot.

A szerver szerepe:

- hitelesített átvételi pont,
- szerveroldali validáció,
- audit trail,
- idempotens publikálás,
- pénztárak felé terítés,
- pénztári automatikus beolvasás kiszolgálása.

Kötelező fejlesztési irány:

- Új árfolyamkészítő funkciót ne a szerver webes admin UI-jába tegyünk elsődleges
  szerkesztőként.
- A szerver csak ellenőrizzen, naplózzon, tároljon és terítsen.
- A pénztár továbbra is automatikusan, emberi beavatkozás nélkül olvassa be az
  aktuális árfolyamokat.
- A helyi főértéktárosi kliens minden publikálása legyen idempotens és auditált.

2026-05-12 végrehajtás:

- Elkészült a külön `rate-maker` Electron app mód.
- Elkészült az `arfolyam-keszito-client` telepíthető Windows GUI.
- A GUI a szerver felé a helyi auditált csomagpublikáló végpontot használja.
- A szerveres web UI nem elsődleges árfolyamíró felület.

2026-05-12 pontosítás:

- A rate-maker Electron app vezetői belépése Google Desktop OAuth alapú.
- A rate-maker frontend nem a régi `/rate-creation/overview` + `/workgroups`
  párost használja elsődleges betöltésre, hanem a külön
  `/local-rate-maker/bootstrap` szerződést.
- A telepítő build ellenőrizve:
  `arfolyam-keszito-client/release/Arfolyamkeszito-Setup-2.5.41.exe`.
