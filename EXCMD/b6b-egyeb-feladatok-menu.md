---
title: "Egyéb feladatok menü (NAV pénztárgép + OTP POS + adatlapok)"
modul: b6b-egyeb-feladatok-menu
kategoria: penztar-muveletek
alkalmazas: penztar-client
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
  - ROLE_ADMIN
forrasok:
  - "Felmérés/Valuta/Cégesoport felmérése/Képernyőképek/Egyéb feladatok menü.jpeg"
  - "Felmérés/Valuta/Cégesoport felmérése/Képernyőképek/Egyéb feladatok menü(1).jpeg"
prio: Közepes
utolso_frissites: "2026-06-02"
media_eredetu: true
tags:
  - nav-penztar
  - otp-pos
  - adatlapok
  - ugyfel-karbantartas
---

<system_context>
# Modul: Egyéb feladatok menü

## Kontextus
A pénztári kliens „Egyéb feladatok" főmenü-pontja alatt elérhető almenü-képernyő, amelynek tartalma a pénztár konfigurációjától (NAV pénztárgépes vs. OTP POS / adatlap-alapú) függ. 2 OCR-képernyőkép alapján (Egyéb feladatok menü.jpeg, Egyéb feladatok menü(1).jpeg), amelyek két különböző menü-variánst mutatnak ugyanazon menüpont alatt.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot
- **Frontend/Kliens**: Electron kliens (`penztar-client`)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)
- **Külső eszközök**: NAV pénztárgép (soros kommunikáció, COM port), OTP POS terminál (protokoll TBD)

## Szakterületi Szereplők (Roles)
- **Pénztáros (Cashier)**: Napnyitás / napzárás pénztárgépen, COM-port állítás (RBAC: `ROLE_CASHIER`).
- **Értéktáros / Főértéktáros**: Adatlapok kezelése, ügyfél karbantartás (RBAC: `ROLE_TREASURER`).
- **Admin**: Különféle beállítások elérése, pénztárgép valuta-kezelés (RBAC: `ROLE_ADMIN`).

## Hatókör (Scope)
- **IN**:
  - **Variáns 1 (NAV pénztárgépes konfiguráció)**:
    - KÜLÖNFÉLE BEÁLLÍTÁSOK
    - PÉNZTÁRGÉP VALUTÁINAK TÖRLÉSE
    - VALUTÁK BETÖLTÉSE A PÉNZTÁRGÉPBE
    - NAPNYITÁS A PÉNZTÁRGÉPEN
    - NAPZÁRÁS A PÉNZTÁRGÉPEN
    - A PÉNZTÁRGÉP COM-PORTJÁNAK ÁLLÍTÁSA
    - KILÉPÉS AZ EGYÉB FELADATOKBÓL
  - **Variáns 2 (OTP POS / adatlapos konfiguráció)**:
    - KÜLÖNFÉLE BEÁLLÍTÁSOK
    - PÉNZTÁRGÉP UTASÍTÁSAI
    - OTP POS TERMINÁL PARANCSOK
    - ADATLAPOK KEZELÉSE
    - ÜGYFÉL KARBANTARTÁS
    - KILÉPÉS AZ EGYÉB FELADATOKBÓL
- **OUT**:
  - A NAV-protokoll alacsony szintű implementációja.
  - OTP POS terminál belső kommunikációs részletek.
  - Beállítások képernyők részletes tartalma (az `b6-beallitasok.md`-ben specifikálva).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### [FR-EFM-01] [Menü megjelenítése pénztár-konfiguráció szerint]
- **Leírás**: Az „Egyéb feladatok" menüpont megnyitásakor a rendszer a pénztár konfigurációs beállítása (NAV pénztárgép integráció aktív vs. OTP POS / adatlapos mód) alapján automatikusan a megfelelő menü-variánst jeleníti meg.
  - Ha NAV pénztárgép integráció aktív → Variáns 1
  - Ha OTP POS / adatlapos konfiguráció → Variáns 2
- **Forrás**: OCR — Egyéb feladatok menü.jpeg (Variáns 1) + Egyéb feladatok menü(1).jpeg (Variáns 2)
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / EgyebFeladatokMenu
- **Bemenő adatok**: Pénztár konfigurációs flag (NAV pénztárgép aktív / nem aktív)
- **Kimenet / Visszajelzés**: A megfelelő menü-variáns renderelése
- **Validációk és Kényszerek**: A két variáns nem egyszerre látszik; a konfiguráció a Beállítások képernyőn rögzített.

### [FR-EFM-02] [Variáns 1: NAV pénztárgép parancsok]
- **Leírás**: NAV pénztárgépes konfiguráció esetén az alábbi menüpontok elérhetők:
  1. **KÜLÖNFÉLE BEÁLLÍTÁSOK** — átnavigál a Beállítások képernyőre (jelszóval védett)
  2. **PÉNZTÁRGÉP VALUTÁINAK TÖRLÉSE** — a pénztárgép memóriájában tárolt valutákat törli
  3. **VALUTÁK BETÖLTÉSE A PÉNZTÁRGÉPBE** — az aktuális valutalistát betölti a pénztárgépbe
  4. **NAPNYITÁS A PÉNZTÁRGÉPEN** — napi nyitási parancs küldése a NAV pénztárgépnek
  5. **NAPZÁRÁS A PÉNZTÁRGÉPEN** — napi zárási parancs küldése a NAV pénztárgépnek
  6. **A PÉNZTÁRGÉP COM-PORTJÁNAK ÁLLÍTÁSA** — soros port kiválasztása / tesztelése
  7. **KILÉPÉS AZ EGYÉB FELADATOKBÓL** — visszatérés a főmenübe
- **Forrás**: OCR — Egyéb feladatok menü.jpeg
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / NavPenztar parancs-vezérlő
- **Bemenő adatok**: Felhasználó menüpont-választása
- **Kimenet / Visszajelzés**: Megfelelő NAV-pénztárgép parancs futtatása és visszajelzés (sikeres/sikertelen)
- **Validációk és Kényszerek**: COM-port beállítás szükséges a kommunikációhoz. Napi nyitás/zárás csak a beállított COM-porton keresztül működik.

### [FR-EFM-03] [Variáns 2: OTP POS + adatlapok + ügyfél karbantartás]
- **Leírás**: OTP POS / adatlapos konfiguráció esetén az alábbi menüpontok elérhetők:
  1. **KÜLÖNFÉLE BEÁLLÍTÁSOK** — átnavigál a Beállítások képernyőre (jelszóval védett)
  2. **PÉNZTÁRGÉP UTASÍTÁSAI** — pénztárgép-specifikus parancsok almenüje (TBD — pontos tartalom a képernyőn nem volt teljes)
  3. **OTP POS TERMINÁL PARANCSOK** — bankkártyás terminál-vezérlő almenü (pl. napzárás, teszt tranzakció — TBD)
  4. **ADATLAPOK KEZELÉSE** — ügyfél-adatlapok nyomtatása, újranyomtatása, archiválása
  5. **ÜGYFÉL KARBANTARTÁS** — ügyfél-törzsadatok szerkesztése / keresése
  6. **KILÉPÉS AZ EGYÉB FELADATOKBÓL** — visszatérés a főmenübe
- **Forrás**: OCR — Egyéb feladatok menü(1).jpeg
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / OtpPosParancsok + AdatlapKezelo + UgyfelKarbantarto
- **Bemenő adatok**: Felhasználó menüpont-választása
- **Kimenet / Visszajelzés**: Megfelelő almenü vagy dialógus megjelenítése
- **Validációk és Kényszerek**: OTP POS kommunikációs részletek TBD. ÜGYFÉL KARBANTARTÁS jogosultság-ellenőrzést igényel (legalább `ROLE_TREASURER`).

### [FR-EFM-04] [Kilépés az egyéb feladatokból]
- **Leírás**: Mindkét variánsban az utolsó menüpont „KILÉPÉS AZ EGYÉB FELADATOKBÓL", amely visszanavigál a pénztár főmenüjébe. Az operátor bármikor visszatérhet mentés / végrehajtás nélkül.
- **Forrás**: OCR — mindkét menü-képernyőkép, utolsó menüpont
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / EgyebFeladatokMenu
- **Bemenő adatok**: Menüpont kattintás / billentyűparancs
- **Kimenet / Visszajelzés**: Visszanavigálás a főmenübe
- **Validációk és Kényszerek**: Nincs megerősítő dialógus szükséges kilépésnél.
</functional_spec>
