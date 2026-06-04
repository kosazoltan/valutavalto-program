---
title: "Pénztár Törzs Adatbázis - AI ügynök utasításkészlet (2 feladat)"
modul: b2-penztar-torzs-adatbazis-felterkepezes
kategoria: backend-core-data
alkalmazas: backend
szerepokor:
  - ROLE_ADMIN
  - ROLE_FOERTEKTAR
  - ROLE_UGYVEZETO
forrasok:
  - "C:/Users/Kósa Zoltán/Downloads/FELTERKEPEZES_penztar_torzs.md"
  - "EXCMD/_ai-protokoll/OCR-MD-korrekcio-portolhato-playbook.md"
  - "EXCMD/_inventory/docx-text/Kósa Szervezés__Specifikációk__Névtelen dokumentum.docx.txt"
  - "backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java"
  - "backend/src/main/java/hu/puzzleir/valuta/controller/BranchController.java"
  - "backend/src/main/java/hu/puzzleir/valuta/dto/BranchDto.java"
  - "backend/src/main/java/hu/puzzleir/valuta/dto/CreateBranchDto.java"
  - "backend/src/main/java/hu/puzzleir/valuta/dto/UpdateBranchDto.java"
  - "backend/src/main/java/hu/puzzleir/valuta/mapper/BranchMapper.java"
  - "backend/src/main/java/hu/puzzleir/valuta/service/BranchService.java"
  - "backend/src/main/resources/db/migration/V0_1__base_tables.sql"
  - "backend/src/main/resources/db/migration/V174__b6_branch_is_vault_flag.sql"
  - "backend/src/main/resources/db/migration/V240__branch_sync_followup_bank_code_szeged_mora.sql"
prio: Magas
utolso_frissites: "2026-06-03"
media_eredetu: true
---

# Cél
Ez a dokumentum 2 darab, AI ügynök által végrehajtandó feladatot ad meg a Pénztár Törzs Adatbázis modul feltérképezéséhez és javítási előkészítéséhez.

A végrehajtás kizárólag olvasott kód- és dokumentumténnyel dolgozhat.
Tilos a találgatás, a hiányzó adat kitalálása, és a forrás nélküli állítás.

# Kötelező végrehajtási szabályok
1. Csak olyan állítást írj le, amihez konkrét forrásfájl tartozik.
2. Minden megállapításhoz add meg a bizonyítékot fájlútvonallal.
3. Ha valami nem bizonyítható, azt jelöld: NINCS BIZONYÍTÉK.
4. Ne írj át kódot. Ez a csomag kizárólag feltérképezés és javítási utasítás.
5. Lost in the Middle védelem:
- A kimenetet fix, kötelező sorrendben add vissza.
- Minden fejezet végén 3 soros mini-összegzés kötelező.
- A végén legyen globális konzisztencia-ellenőrzés.

# Előzetesen igazolt tények (baseline)
1. A branch alaptábla már tartalmazza a bank_code, phone, email mezőket.
2. A Branch entitásban az isVault mező létezik, és migrációs háttérrel került be.
3. A /api/v1/branches végpontcsalád már létezik listázás/létrehozás/frissítés/törlés műveletekkel.
4. A Branch sok modulból hivatkozott központi entitás (több tucat entity kapcsolat branch_id alapon).
5. A BranchDto tartalmazza a bankCode, phone, email, isVault, region, regionCode mezőket.
6. A Create/Update DTO-k jelenleg nem tartalmazzák a short_name, has_afa, has_wu, has_mg, has_pos, closed_saturday, closed_sunday mezőket.

# Képadat státusz (OCR/ASR forráskezelés)
1. A jelen feladathoz explicit, strukturált kép-JSON nem került átadásra.
2. Az inventoryban elérhető OCR-eredetű szövegforrás felhasználható kiegészítő kontextusként.
3. Ha bármely állítás csak képforrásból vezethető le, de nincs konkrét OCR-tény, kötelező jelölés: NINCS BIZONYÍTÉK.

# Feladat 1 - Tényszerű állapotfelmérés (Pénztár Törzs)

## Cél
A FELTERKEPEZES kérdéssor 4 pontjára bizonyíték-alapú, rövid, döntés-előkészítő választ készíteni.

## Bemenet
- C:/Users/Kósa Zoltán/Downloads/FELTERKEPEZES_penztar_torzs.md
- A forráslistában szereplő backend fájlok.

## Kötelező kimeneti szerkezet
1. Jelenlegi adattárolás
- Mely mezők vannak már most a Branch entitásban és DB-ben.
- Mely kért mezők hiányoznak.

2. Bővíthetőség (zero-downtime szempont)
- Kizárólag additive migrációs javaslatok listája (NULL-oszlop + backfill + index + API-fázisok).
- Kockázati pontok: globális unique code, multi-tenant scope, mapper/DTO kompatibilitás.

3. Meglévő API végpontok
- Pontos felsorolás a már meglévő Branch API műveletekről.
- Külön jelölni: listázás, create, update, delete, special endpointok.

4. Hivatkozási hatókör
- Mely fő modulok/entitások hivatkoznak Branch-re.
- Hatásbesorolás: magas/közepes/alacsony.

## Kötelező táblák
1. Mező-állapot tábla
- oszlopok: mezo, kert_tipus, jelenlegi_allapot, forras, megjegyzes

2. API-lefedettség tábla
- oszlopok: endpoint, metoda, cel, letezik, forras

3. Függőségi tábla
- oszlopok: modul_vagy_entity, kapcsolat_tipusa, branch_hivatkozas, kockazat

## Kötelező mini-összegzés
A fejezet végén pontosan 3 sor:
- Mi biztosan kész.
- Mi hiányzik.
- Mi a legnagyobb kockázat.

# Feladat 2 - Javító utasításkészlet (AI-végrehajtásra optimalizált)

## Cél
A feltárt hiányokhoz készíts futtatható, ügynökbarát javítási utasításokat implementáció nélkül.

## Kötelező felosztás
1. Schema réteg
- Mely új oszlopok javasoltak a Branch táblába.
- Melyik oszlop legyen nullable az első rolloutban.
- Milyen index javasolt és miért.

2. Backend domain réteg
- Branch entitás bővítési pontok.
- Create/Update DTO bővítési pontok.
- Mapper bővítési pontok.
- Service validációs pontok.

3. API szerződés réteg
- Visszafelé kompatibilis request/response stratégia.
- Optional mezők kezelésének szabálya.

4. Modulhatás réteg
- Mely modulokat kell célzottan regressziósan ellenőrizni (átadás-átvétel, zárás-beérkezés, készlet-kimutatás, értéktári folyamatok).

5. Tesztstratégia
- Migráció smoke ellenőrzés.
- CRUD API szerződés tesztek.
- Multi-tenant izolációs ellenőrzések.
- Branch-függő modul smoke lista.

## Kötelező output formátum
1. Végrehajtási terv (fázisokra bontva)
- Fazis 1: DB additive változások
- Fazis 2: Backend model + DTO + mapper
- Fazis 3: API és validáció
- Fazis 4: Regresszió és kiadási check

2. Minden fázisnál legyen
- bemenet
- muvelet
- elvart_kimenet
- rollback_terv
- elfogadasi_kriterium

3. Kötelező risk register
- oszlopok: risk_id, leiras, valoszinuseg, hatas, mitigacio, bizonyitek

## Kötelező mini-összegzés
A fejezet végén pontosan 3 sor:
- Mi valósítható meg azonnal.
- Mi igényel döntést.
- Mi blokkolhat rollout közben.

# Bizonyítékjegyzék (kötelezően hivatkozandó források)
- backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java
- backend/src/main/java/hu/puzzleir/valuta/controller/BranchController.java
- backend/src/main/java/hu/puzzleir/valuta/dto/BranchDto.java
- backend/src/main/java/hu/puzzleir/valuta/dto/CreateBranchDto.java
- backend/src/main/java/hu/puzzleir/valuta/dto/UpdateBranchDto.java
- backend/src/main/java/hu/puzzleir/valuta/mapper/BranchMapper.java
- backend/src/main/java/hu/puzzleir/valuta/service/BranchService.java
- backend/src/main/resources/db/migration/V0_1__base_tables.sql
- backend/src/main/resources/db/migration/V174__b6_branch_is_vault_flag.sql
- backend/src/main/resources/db/migration/V240__branch_sync_followup_bank_code_szeged_mora.sql
- C:/Users/Kósa Zoltán/Downloads/FELTERKEPEZES_penztar_torzs.md
- EXCMD/_ai-protokoll/OCR-MD-korrekcio-portolhato-playbook.md

# Tiltások
1. Tilos kódot módosítani.
2. Tilos migrációt ténylegesen futtatni.
3. Tilos forrás nélküli következtetés.
4. Tilos a scope-on kívüli refaktor.

# Végső kimenet kötelező ellenőrzőlista
- [ ] Mindkét feladat külön, jól látható fejezetben szerepel.
- [ ] Minden állításhoz van bizonyítékfájl.
- [ ] A hiányzó mezők explicit listázva vannak.
- [ ] A függőségi hatókör táblázatosan szerepel.
- [ ] A javító terv fázisonként rollbackkel szerepel.
- [ ] A dokumentum nem tartalmaz hallucinált entitást vagy endpointot.
