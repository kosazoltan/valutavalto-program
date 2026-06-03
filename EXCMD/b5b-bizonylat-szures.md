---
title: "Bizonylatok szűrése képernyő"
modul: b5b-bizonylat-szures
kategoria: bizonylatok
alkalmazas: penztar-client
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
  - ROLE_INTERNAL_AUDITOR
forrasok:
  - "Felmérés/Valuta/Cégesoport felmérése/Képernyőképek/Bizonylatok szűrése.jpeg"
  - "Felmérés/Valuta/Cégesoport felmérése/Képernyőképek/Bizonylatok szűrése2.jpeg"
prio: Közepes
utolso_frissites: "2026-06-02"
media_eredetu: true
tags:
  - bizonylat
  - szűrés
  - ügyfél-azonosítás
  - AML
---

<system_context>
# Modul: Bizonylatok szűrése képernyő

## Kontextus
A pénztári kliens bizonylat-böngésző moduljának szűrési képernyője, amelyről az operátor meghatározhatja, hogy a bizonylatlista milyen bizonylatokat jelenítsen meg (összes, típus szerinti részleges, ügyfél-adatlapon alapuló szűrés). 2 OCR-képernyőkép alapján (Bizonylatok szűrése.jpeg, Bizonylatok szűrése2.jpeg). A szűrési képernyő az ügyfél azonosítási (AML/Pmt.) adatokat is megjeleníti, amelyek a bizonylat szintjén tárolódnak.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot
- **Frontend/Kliens**: Electron kliens (`penztar-client`), React + TS komponens
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Pénztáros (Cashier)**: Megtekinti a bizonylat listát és szűr típus szerint (RBAC: `ROLE_CASHIER`).
- **Értéktáros / Főértéktáros**: Ügyfél-adatlapos részletes szűrési opciókhoz is hozzáfér (RBAC: `ROLE_TREASURER`).
- **Belső ellenőr (Internal Auditor)**: Teljes szűrési hozzáférés, AML-meghaladó bizonylatokhoz is (RBAC: `ROLE_INTERNAL_AUDITOR`).

## Hatókör (Scope)
- **IN**:
  - Bizonylattípus-szűrő vezérlők (radio/select lista: szűrés kikapcsolva; csak ügyfeles; vételi; eladási; konverziós; pénz-átadási; pénz-átvételi; stornózott).
  - Hatókör-választó: „A HÓNAP ÖSSZES BIZONYLATA" vs. „CSAK A VÁLASZTOTT [...]" opció.
  - Ügyfél-adatlap szűrőmezők (természetes személy): NEVE, ANYJA NEVE, LEÁNYKORI NEVE, SZÜLETÉSI HELYE, SZÜLETÉSI IDEJE, ÁLLAMPOLGÁRSÁG, LAKCÍM, OKMÁNYTÍPUS, AZONOSÍTÓ.
  - Jogi személy szűrőmezők: Jogi személy neve, Telephely címe, Képviselő beosztása.
  - AML jelölők a bizonylat szűrőn: 10 TÍZ-MILLIÓ FT küszöb flag, ENGEDÉLYEZŐ neve/beosztása.
  - Ügyfél-adat képernyő második variáns: teljes ügyféladatlap panel (természetes + jogi személy + képviselő mezők egyszerre látható).
- **OUT**:
  - Bizonylatlista renderelése (az a szomszéd képernyő).
  - Mögöttes adatbázis-lekérdezés optimalizálása.
  - Jogosultság-kényszer részletes implementációja (azt a RBAC modul kezeli).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### [FR-BSZUR-01] [Bizonylattípus-szűrő lista]
- **Leírás**: A szűrési képernyőn lista-vezérlő (radio vagy select) jelenik meg a következő szűrési lehetőségekkel, amelyek egyszerre csak egy aktiválható:
  1. Szűrés kikapcsolva (alapértelmezett — az összes bizonylat látszik)
  2. Csak ügyfeles bizonylatok
  3. Csak vételi bizonylatok
  4. Csak eladási bizonylatok
  5. Csak konverziós bizonylatok
  6. Csak pénz-átadási bizonylatok
  7. Csak pénz-átvételi bizonylatok
  8. Csak stornózott bizonylatok
- **Forrás**: OCR — Bizonylatok szűrése.jpeg (szűrési lista panel)
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / BizonylatiSzuroKepernyo
- **Bemenő adatok**: Felhasználó szűrőválasztása
- **Kimenet / Visszajelzés**: Bizonylatlista frissül a választott szűrő szerint
- **Validációk és Kényszerek**: Egyszerre csak egy szűrőtípus aktív. Az „Összes" visszaállítja a szűretlen nézetet.

### [FR-BSZUR-02] [Hatókör-választó: hónap vs. választott időszak]
- **Leírás**: A szűrő képernyőn két opció közül lehet választani:
  - „A HÓNAP ÖSSZES BIZONYLATA" — az aktuális (vagy egy kiválasztott) hónap összes bizonylata megjelenik.
  - „CSAK A VÁLASZTOTT [...]" — operátor által megadott szűkebb időintervallum (dátumtól-ig, TBD ha a képen csak felirat látszott).
- **Forrás**: OCR — Bizonylatok szűrése.jpeg (hatókör panel)
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / BizonylatiSzuroKepernyo
- **Bemenő adatok**: Hatókör-választó radio button
- **Kimenet / Visszajelzés**: A bizonylatlista a kiválasztott hatókörre szűkül
- **Validációk és Kényszerek**: TBD — a pontos időszak-paraméterezés a kép korlátai miatt nem teljes.

### [FR-BSZUR-03] [Természetes személy ügyfél-adatlap szűrőmezők]
- **Leírás**: Az ügyfeles bizonylatszűrési nézeten az alábbi természetes személy mezők jelennek meg (OCR alapján azonosítva):
  - NEVE
  - ANYJA NEVE
  - LEÁNYKORI NEVE
  - SZÜLETÉSI HELYE
  - SZÜLETÉSI IDEJE
  - ÁLLAMPOLGÁRSÁG
  - LAKCÍM
  - OKMÁNYTÍPUS
  - AZONOSÍTÓ (okmányszám)
  Az operátor bármelyik mezőre szűrhet; a lista az egyező ügyfél-bizonylatokat adja vissza.
- **Forrás**: OCR — Bizonylatok szűrése2.jpeg (ügyfél adatlap panel, természetes személy részleg)
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / BizonylatiSzuroKepernyo
- **Bemenő adatok**: Szöveg beírása egy vagy több mezőbe
- **Kimenet / Visszajelzés**: Bizonylatok ügyfél-adatlap tartalom szerint szűrve
- **Validációk és Kényszerek**: Részleges egyezés (LIKE) elfogadott; kis/nagybetű-érzéketlenség TBD.

### [FR-BSZUR-04] [Jogi személy szűrőmezők]
- **Leírás**: A szűrési képernyő jogi személy részlegén az alábbi mezők jelennek meg:
  - Jogi személy neve
  - Telephely címe
  - Képviselő beosztása
- **Forrás**: OCR — Bizonylatok szűrése2.jpeg (jogi személy panel)
- **Prio**: Should
- **Csomag/Komponens**: penztar-client / BizonylatiSzuroKepernyo
- **Bemenő adatok**: Szöveg beírása egy vagy több mezőbe
- **Kimenet / Visszajelzés**: Jogi személy bizonylatai szűrve
- **Validációk és Kényszerek**: TBD — pontos mezőkötés az adatmodellhez.

### [FR-BSZUR-05] [AML-jelölők megjelenítése szűrési nézetben]
- **Leírás**: A bizonylat szűrési képernyőn az alábbi AML-specifikus jelölők is látszódnak:
  - „10 TÍZ-MILLIÓ FT" — küszöbérték-jelölő (jelezheti, hogy az ügyfél 10 M Ft feletti tranzakcióval rendelkezik)
  - ENGEDÉLYEZŐ neve + BEOSZTÁSA mező
  Ezek megjelenítése csak olvasható (szűrési segédadat), nem szerkeszthető ebből a képernyőből.
- **Forrás**: OCR — Bizonylatok szűrése2.jpeg (AML/10M-jelölő és engedélyező mezők)
- **Prio**: Must (AML-jogszabályi megfelelés, Pmt.)
- **Csomag/Komponens**: penztar-client / BizonylatiSzuroKepernyo
- **Bemenő adatok**: —
- **Kimenet / Visszajelzés**: A küszöb-meghaladó bizonylatok vizuálisan jelölve vagy szűrhetők
- **Validációk és Kényszerek**: A 10 M Ft-os AML-küszöb nem kerülhető meg. Naplózás kötelező.
</functional_spec>
