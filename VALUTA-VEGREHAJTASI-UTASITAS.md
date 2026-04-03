# VALUTAVÁLTÓ PROGRAM — AI VÉGREHAJTÁSI UTASÍTÁS

> **Cél:** Újraépíteni a teljes Anti rendszer modern architektúrában. Minden szekció végrehajtási forma, AI fejlesztők számára.
> **Referencia:** Eredeti legacy: `Anti/VALUTA` (Delphi7+DLL), folyamatok: lásd antivaluta.GPT-5.4.md.
> **Technológia:** Java Spring Boot backend, React frontend, Electron desktop kliens (backend URL: https://excvaluta.com/api/v1/)

---

## 1. Rendszer Áttekintés
---
- **Építsd újra az Anti (Delphi7) valutaváltó rendszert** modern Java+React stack-re.
- **Fő modulok**:
  - Klasszikus valutaváltás (vétel, eladás, konverzió)
  - Napnyitás/zárás, havi zárás, címletezés
  - Pénztárak közti átadás/átvétel
  - Western Union és kereskedelmi bővítések
  - Bizonylatkezelés, nyomtatás, riport, compliance
  - Integráció: kamera, szerverek, külső API
- **Backend**: REST API, PostgreSQL (Firebird szerű logika), transzparens napállapotgép
- **Frontend**: React SPA, desktop wrapper Electronnal, teljes menümodellel
- **Adatmodell**: relációs, lásd lent
- Szigorú napállapot és jogosultságkezelés

## 2. Üzleti Folyamatok Specifikáció
---
### 2.1. Valuta Vétel
- Implementáld a "Vétel" flow-t:
  1. Tranzakciós tábla előkészítése (`vtemp`-nek megfelelő)
  2. Ügyfél/partner adat bekérés
  3. Árfolyam lekérdezése, vételi paraméterek generálása
  4. Címletezés, jutalék, összeg számítása
  5. Bizonylat (számla) létrehozása
  6. Könyvelés adatbázisba
  7. Készlet állapot frissítés
  8. Nyomtatás triggerelése
- Legacy referencia: vasarlas.dll, FORM1

### 2.2. Valuta Eladás
- Implementáld az "Eladás" flow-t:
  1. Tranzakciós tábla előkészítése
  2. Ügyfél/partner/ellenőrzés
  3. Aktuális eladási árfolyam olvasása
  4. Bizonylat mezők elkészítése
  5. Könyvelés
  6. Nyomtatás
- Legacy referencia: eladas.dll

### 2.3. Konverzió
- Implementáld a "Konverzió" (valuta↔valuta) funkciót:
  1. Vétel+eladás felület és logika
  2. `konverzio=true` flag a folyamatban
  3. Mindkét művelet auditja, bizonylat kezelése
- Legacy referencia: UJKONVERZIO, vasarlas.dll

### 2.4. Pénztárak között Átadás/Átvétel
- Implementáld az átadás/átvétel kétoldalú folyamatait:
  1. Forrás/cél pénztár kiválasztás
  2. Mozgás rögzítése
  3. Bizonylatkezelés két példányban (átadó, átvevő)
  4. Készlet/jutalék/ellenőrző folyamatok
- Legacy referencia: atadvet.dll, atadolap.dll

### 2.5. Sztornó
- Implementáld a "Stornó" funkciót:
  1. Stornózni kívánt tranzakció visszakeresése
  2. Ok, státusz rögzítése, storno bizonylat generálása
  3. Minden kapcsolódó tétel visszaforgatása
  4. Bizonylat újranyomtatás, log update
- Legacy referencia: storno.dll

### 2.6. Árfolyam kezelés
- Implementáld árfolyam beállítást & regisztert:
  1. Lekérdezés/jóváhagyás/szerkesztés/mentés
  2. Árfolyam-történet karbantartás
  3. Jogosultsághoz kötött módosítás
- Legacy referencia: arftmk.dll, getarf.dll, arfreg.dll

### 2.7. Pillanatnyi pénztár és készletállás
- Implementáld a pillanatnyi készlet lekérdezést és megjelenítést (valós, címletbontásos nézetben, szűrési opciókkal).
- Frissítsd automatikusan kapcsolódó pontokban (vétel/eladás/átadás után).

### 2.8. Napi/Havi Zárás
- Implementáld a napnyitás, napzárás, havi zárás workflow-kat:
  1. Állapot-gép megvalósítás; napnyitás státusz, blokkerek kezelése
  2. Időszakváltás (hónapváltás) logika
  3. Címletezés, ellenőrzések, nyomtatás
  4. Integráció terminállal/szerverrel
- Legacy referencia: napzar.dll, havizar.dll, cimlmenu.dll

### 2.9. Bizonylat Tallózás, Újranyomtatás
- Implementáld a történelmi bizonylatok lekér, újranyomtatást (másolat, reprint indokgal, storno kezelés).
- Jogosultság- és indokalapú újranyomtatás.

### 2.10. Riportok, Listák
- Implementáld a fő riportokat: kiadott bizonylatok, napi/havi/pillanatnyi forgalom, TRB-spec, statisztikák.
- Export opciók: CSV, PDF, plain text

### 2.11. Compliance
- Építsd be az ügyfél, terrorlista, supervisor és engedélyezési kontrollt minden releváns flow-ba.
- Kockázatos műveletet jogosultsághoz és felülvizsgálathoz kösd (pl. árfolyam, storno).

### 2.12. Trade & Kiegészítők
- Implementáld:
  - Telefonfeltöltés: top-up flow, audit, nyomtatás
  - Matrica: e-matrica workflow
  - Paysafe/kuponok: buy/sell, riport
  - Minden core legacy funkció (TRADE almodul)

## 3. Menürendszer & Navigáció
---
- Implementáld a főmenü két oldalát (9+9 menüpont)
- Tükrözd a legacy FOMENUFORM/dispatch logikát (lásd antivaluta.GPT-5.4.md főmenü szekció)
- Minden üzleti funkció önálló képernyő (React route/component, Electron view)
- Gyorsgombok: főbb kernelfunkciókat külön button-bárban jelenítsd meg (vétel, eladás, konverzió, napzárás, pillanatnyi állás, supervisor, kilépés, stb.)

## 4. Adatmodell
---
- Implementáld a következő entitásokat/táblákat relációsan:
  - **PENZTAR** (id, név, cím, telefon)
  - **VTEMP** (tranzakciós scratch; lásd főfolyamatok)
  - **ÜGYFEL** (adatbázis)
  - **JELENLET** (aktív státusz)
  - **BLOKKFEJ**, **BLOKKTETEL** (bizonylatok)
  - **PENZTARFORGALOM** (összesítő)
  - **ÉRTÉKTÁR** (ellátó/központi)
  - **TRADyyMM** (TRADE havi könyvelés)
  - **TERRORLISTA** (compliance)
- Minden legacy tábla és feladat legyen mappingolva modern, titkosítást/több-státuszt támogató, auditálható sémára
- `vtemp` minták: shell<->DLL paraméter, tranzakció-időszak scratch

## 5. Bizonylat & Nyomtatás
---
- Implementáld bizonylatpipelinet:
  - Generálj minden művelethez (vétel, eladás, átadás, sztornó, stornozott, címletezés, WU, telefonfeltöltés, matrica, paysafe, stb.) saját bizonylatformátumot
  - Jogszabályi megfelelés KÖTELEZŐ (adóigazolvány, összeg, ÁFA zászló, vevő 300k+ adatok, iroda azonosító)
  - Nyomtatási pipeline legyen REST endpoint-on át is triggerelhető
  - Bizonylat tartalmak: pénztárkód, számlaszám, idő, partner/ügyfél/okmányadat, devizanem, árfolyam, összeg, kezelési díj, jogcím, megjegyzés, engedélyező/státusz, újranyomtatás indoka, stb.
- Legyen támogatva minden másolat/storno/újranyomtatási flow
- Referencia: BLOKNYOM, BIZODISP, storno.dll

## 6. Jogosultságok és Szerepkörök
---
- Valósítsd meg legalább az alábbi szintű role-based access-t:
  - **Pénztáros:** napi műveletek, sztornó jogosultság csak saját tételre
  - **Supervisor:** árfolyam, engedélyezés, sztornó minden tételen, napi/havi zárás
  - **Admin:** minden művelet (report, archiválás, mentés)
- Kockázatos/ritka műveletek explicit supervisor approval-hoz kötve
- API endpointokat és GUI route-okat role-guard őrizze

## 7. Integrációk (Szerver, Kamera, Terminál)
---
- Implementáld a következő integrációkat:
  - Kamera, admin/office (Java, REST vagy proxy call)
  - Remote DB szinkronizáció (ha van, dedikált szerviz)
  - Western Union/OTP terminál (külön backend service, vagy adapter)
  - Topup/matrica/kupon HTTP/FTP kapcsolat
  - Export, bizonylat és média küldés REST vagy fájlszintű pipeline-kon keresztül
  - Szükséges Java helper exe/CLI integrációhoz dedikált wrapper

## 8. Prioritási Sorrend
---
Implementálási sorrend (RE-5+MoSCoW elv szerint):
1. Napnyitás/Napzárás, napállapot-gép, beléptetés (mutex, role-auth, helyes állapotok)
2. Vétel, eladás, sztornó, konverzió full flow (bizonylatképzéssel)
3. Pénztárak közti mozgások
4. Árfolyam és készlet-kezelés
5. Ügyfél/compliance modulok
6. Riportolás, újranyomtatás, lista-funkciók
7. Integrációk (kép, terminál, remote)
8. Kiegészítő szolgáltatások (topup, matrica, paysafe)
9. Admin/dashboard/mentés, migráció/modul export

---

## 9. Legacy Referencia mátrix
---
- **DLL/Funkció mapping:**
  - vasarlas.dll - vétel
  - eladas.dll - eladás
  - storno.dll - sztornó
  - napzar.dll - napi zárás
  - havizar.dll - havi zárás
  - arftmk.dll/getarf.dll/arfreg.dll - árfolyam
  - atadvet.dll/atadolap.dll - átadás/átvétel
  - cimlmenu.dll/cimlnyom.dll - címletezés
  - bizodisp.dll - bizonylat tallózó
  - pillall.dll/pillkesz.dll - készlet
  - prosbe.dll/proski.dll - beléptetés/exit
  - wunion.dll - Western Union
  - terminal.dll - terminál integráció
  - listak.dll - riportok, listák
  - regen.dll - regenerálás
- Minden modul/feature-nél adj referencia mezőt a legacy forrásrendszerhez!

---

> **Kötelező:** Minden itt felsorolt flow és entitás végrehajtása, az eredeti rendszer teljes újrafedésével, RESTful, stateful, role-guarded és auditált architektúrában.
