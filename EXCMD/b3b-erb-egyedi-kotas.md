---
title: "ERB Egyedi kötés (Raiffeisen bankkártyás szerződéskötési képernyő)"
modul: b3b-erb-egyedi-kotas
kategoria: bank-integracio
alkalmazas: penztar-client
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
forrasok:
  - "Felmérés/Valuta/Cégesoport felmérése/Képernyőképek/ERB Egyedi kötés.JPG"
prio: Alacsony
utolso_frissites: "2026-06-02"
media_eredetu: true
tags:
  - raiffeisen
  - erb
  - bankkartyakotes
  - szerzodeskotas
---

<system_context>
# Modul: ERB Egyedi kötés

## Kontextus
A pénztári kliensbe integrált ERB (Raiffeisen Bank / Express/RB) bankkártyás egyedi kötési képernyő. Az OCR-forrás (ERB Egyedi kötés.JPG) alapján a képernyőn az „ERB EGYEDI KÖT[ÉS]" felirat és az RB/Raiffeisen Bank logó látható. Az F3 funkcióbillentyű valószínűleg a kötési folyamat inicializálásához kapcsolódik. A kép részben olvashatatlan volt, de a kontextus egyértelmű: egyedi bankkártyás kötés (szerződéskötési / binding felület) a Raiffeisen ERB rendszerrel.

**Megjegyzés a specifikáció korlátairól**: Az OCR-forrás csak részleges információt tartalmaz (a kép egy részén a szöveg olvashatatlan). Az alábbi specifikáció a látható elemek alapján készült; a pontos mezőkészlet és protokoll részletek mélyebb dokumentációból vagy Raiffeisen API-dokumentumból egészítendő ki.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot
- **Frontend/Kliens**: Electron kliens (`penztar-client`)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)
- **Külső rendszer**: Raiffeisen ERB bankkártyás rendszer (protokoll TBD — valószínűleg soros vagy TCP/IP alapú terminál-kommunikáció)

## Kapcsolódó modulok
- `b3-bank-api.md` — Raiffeisen REST fallback és MNB SOAP integráció (nem ERB egyedi kötés, de ugyanaz a bank-integráció kontextus)
- `b6-beallitasok.md` — Bankkártya fizetés beállítások tab (konfigurációs oldal)

## Szakterületi Szereplők (Roles)
- **Pénztáros (Cashier)**: Egyedi kötés kezdeményezése ügyfél-tranzakcióhoz (RBAC: `ROLE_CASHIER`).
- **Értéktáros (Treasurer)**: Engedélyezési lépések az egyedi kötésnél (RBAC: `ROLE_TREASURER`).

## Hatókör (Scope)
- **IN**:
  - ERB egyedi kötés képernyő megjelenítése a pénztári kliensben.
  - F3 billentyű → kötés inicializálása / megnyitása.
  - Interaktív form a bankkártyás kötési adatok beviteléhez.
  - Kötési eredmény visszajelzése (sikeres / sikertelen kötés).
- **OUT**:
  - A Raiffeisen ERB rendszer belső protokollja és API specifikációja (külső rendszer).
  - Általános bankkártya-fizetés feldolgozás (az `b6-beallitasok.md` Bankkártya fizetés tabja kezeli).
  - MNB SOAP arfolyam integráció (az `b3-bank-api.md`-ben specifikálva).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### [FR-ERB-01] [ERB egyedi kötési képernyő megjelenítése]
- **Leírás**: A pénztári kliensben az ERB bankkártyás egyedi kötés képernyő megnyitható, amelyen az „ERB EGYEDI KÖTÉS" felirat és a Raiffeisen Bank logó jelenik meg a képernyő fejlécében. A képernyő az egyedi szerződéses kötési folyamat UI-felülete.
- **Forrás**: OCR — ERB Egyedi kötés.JPG (fejléc és logó terület)
- **Prio**: Alacsony
- **Csomag/Komponens**: penztar-client / ErbEgyediKotes
- **Bemenő adatok**: Navigáció az ERB kötés menüpontjára
- **Kimenet / Visszajelzés**: ERB kötési képernyő renderelése
- **Validációk és Kényszerek**: Csak `ROLE_CASHIER` vagy magasabb jogosultságú felhasználó érheti el. A Raiffeisen ERB rendszer kapcsolatának aktívnak kell lennie.

### [FR-ERB-02] [F3 — Kötés inicializálása]
- **Leírás**: Az F3 funkcióbillentyű (OCR alapján azonosított gomb a képernyőn) a kötési folyamat megnyitásához / inicializálásához kapcsolódik. A pontos akció a Raiffeisen ERB protokolltól függ (TBD — mélyebb dokumentáció szükséges).
- **Forrás**: OCR — ERB Egyedi kötés.JPG (F3 gomb)
- **Prio**: Alacsony
- **Csomag/Komponens**: penztar-client / ErbEgyediKotes
- **Bemenő adatok**: F3 billentyű lenyomása
- **Kimenet / Visszajelzés**: Kötési folyamat elindítása (TBD — sikeres inicializálás visszajelzés)
- **Validációs és Kényszerek**: TBD — Raiffeisen ERB protokoll dokumentációtól függ.

### [FR-ERB-03] [Kötési adatok beviteli form]
- **Leírás**: A képernyőn interaktív form elemek láthatók a bankkártyás kötési adatok beviteléhez. A pontos mezők az OCR-képről részben olvashatatlanok — a teljes mezőkészlet a Raiffeisen ERB rendszer dokumentációjából egészítendő ki. A valószínűsíthető mezők (analógia alapján):
  - Ügyfélnév / szerződésszám
  - Bankkártya utolsó 4 számjegy (tokenizált, PCI-DSS)
  - Összeg / devizanem
  - Kötés típusa
- **Forrás**: OCR — ERB Egyedi kötés.JPG (form terület — részben olvashatatlan)
- **Prio**: Alacsony
- **Csomag/Komponens**: penztar-client / ErbEgyediKotes
- **Bemenő adatok**: Operátor adatbevitel a form mezőkbe
- **Kimenet / Visszajelzés**: Kötési kérelem összeállítása és küldése az ERB rendszernek
- **Validációk és Kényszerek**:
  - **Bankkártya adatok soha nem tárolódnak plaintext formában** (PCI-DSS kényszer).
  - Tokenizáció a Raiffeisen ERB rendszer felelőssége; a kliens csak az engedélyezett tokenre/referenciára támaszkodik.
  - Hibajelzés és naplózás kötelező, ha az ERB rendszer nem érhető el.

### [FR-ERB-04] [Kötési eredmény visszajelzés]
- **Leírás**: Az ERB rendszer válasza alapján a képernyő visszajelzést ad a kötési folyamat kimenetelről (sikeres / sikertelen kötés). Hiba esetén az operátor tájékoztatást kap a hibaokról.
- **Forrás**: Analógia — általános banki terminál UI konvenció; OCR-ből nem olvasható ki részlet.
- **Prio**: Alacsony
- **Csomag/Komponens**: penztar-client / ErbEgyediKotes
- **Bemenő adatok**: ERB rendszer válasza
- **Kimenet / Visszajelzés**: Sikeres kötésnél megerősítő üzenet + kötésszám megjelenítése. Sikertelen kötésnél hibaüzenet + ERB hibakód (ha elérhető).
- **Validációk és Kényszerek**: Minden kötési kísérlet (sikeres és sikertelen egyaránt) naplózandó az auditnyomvonalhoz.
</functional_spec>
