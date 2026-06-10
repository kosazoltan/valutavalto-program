# Modul: Központi kliens – Iroda adatainak szerkesztése (kozponti-client + backend)

## 1. Cél
A Központi munkaállomás Pénztár Törzs Adatbázis moduljában meglévő iroda adatainak szerkesztése, az összes törzsadat-mező módosíthatóságával, státuszváltáskor megerősítő kérdéssel, hogy a Főértéktáros hibás vagy megváltozott adatokat javítani tudjon.

## 2. Scope
### IN
- Szerkesztési form megnyitása a lista nézetből (FK-020) a szerkesztés ikonra kattintva
- A form ugyanazokat az 5 logikai csoportot tartalmazza mint az FK-021, előtöltve a meglévő iroda adataival:
  - **1. Alapadatok:** Pénztár száma/azonosítója, Megjelenítendő név, Rövid név, Iroda típusa (Pénztár / Értéktár)
  - **2. Elérhetőség:** Pénztár pontos címe, Irányítószám, Város, Telefon, Email
  - **3. Területi besorolás:** Terület / Régió hozzárendelése, Bankkód
  - **4. Szolgáltatások:** ÁFA / WU / MG / POS jelölők (checkbox)
  - **5. Nyitvatartás:** Szombaton zárva, Vasárnap zárva, Tartósan zárva
- Minden mező szerkeszthető, beleértve a pénztár kódját is (egyediség ellenőrzéssel)
- Státuszváltáskor (Aktív → Inaktív vagy Inaktív → Aktív) megerősítő kérdés jelenik meg
- Backend: `PUT /api/v1/branches/{id}` végpont az összes mező frissítésével
- Sikeres mentés után visszanavigálás a Pénztár Törzs Adatbázis lista nézetbe (FK-020)
- Audit log rögzítése minden módosításról (előző és új érték)

### OUT
- Új iroda felrögzítése (FK-021)
- Iroda törlése
- Adatmigráció az ügyviteli rendszerből (FK-023)
- Offline cache bővítése a pénztári kliensben (FK-024)
- Képfeltöltés (iroda fotója)

## 3. Szakterületi szereplők (RBAC mátrix kötelező)
| Szerep | olvas | létrehoz | módosít | töröl | publikál | jóváhagy |
|---|---|---|---|---|---|---|
| Admin | ✓ | – | ✓ | – | – | – |
| Főértéktáros | ✓ | – | ✓ | – | – | – |
| Ügyvezető | ✓ | – | ✓ | – | – | – |
| Belső ellenőr | ✓ | – | – | – | – | – |

> Megjegyzés: iroda adatainak módosítása az Admin, Főértéktáros és Ügyvezető jogköre – összhangban a meglévő `@PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")` beállítással.

## 4. Funkcionális követelmények (FR)
| ID | Leírás | Forrás | Prioritás | Csomag | Acceptance (Given/When/Then) |
|---|---|---|---|---|---|
| FR-1 | Szerkesztési form megnyitása előtöltve | Interjú | MUST | kozponti-client | Adott: Főértéktáros a lista nézetben. Amikor: szerkesztés ikonra kattint egy irodánál. Akkor: megnyílik a szerkesztési form az iroda összes aktuális adatával előtöltve, 5 logikai csoportban. |
| FR-2 | Minden mező szerkeszthető | Interjú | MUST | kozponti-client | Adott: szerkesztési form megnyitva. Amikor: bármely mezőt módosítja. Akkor: a módosítás elvégezhető és menthető. |
| FR-3 | Kód mező csak olvasható (nem szerkeszthető) | Interjú | MUST | kozponti-client | Adott: szerkesztési form megnyitva. Amikor: Főértéktáros a pénztár kódját szeretné módosítani. Akkor: a kód mező read-only, nem módosítható a formon. |
| FR-4 | Státuszváltás megerősítő kérdéssel (Aktív → Inaktív) | Interjú | MUST | kozponti-client | Adott: aktív iroda szerkesztési formja. Amikor: „Tartósan zárva" checkboxot bejelöli és a mentés gombra kattint. Akkor: megerősítő kérdés jelenik meg: „Biztosan inaktívra állítja ezt az irodát?" Igen → ment, Nem → visszatér a formhoz. |
| FR-5 | Státuszváltás megerősítő kérdéssel (Inaktív → Aktív) | Interjú | MUST | kozponti-client | Adott: inaktív iroda szerkesztési formja. Amikor: „Tartósan zárva" checkboxot kiveszi és a mentés gombra kattint. Akkor: megerősítő kérdés jelenik meg: „Biztosan aktívra állítja ezt az irodát?" Igen → ment, Nem → visszatér a formhoz. |
| FR-6 | Sikeres mentés után visszanavigálás | Interjú | MUST | kozponti-client | Adott: szerkesztési form módosítva. Amikor: mentés sikeres. Akkor: visszanavigál a lista nézetbe, a módosított iroda frissített adatokkal jelenik meg. |
| FR-7 | Audit log – módosítás előtti és utáni érték | §3 | MUST | backend | Adott: iroda neve módosítva. Amikor: PUT /api/v1/branches/{id} 200-at ad. Akkor: audit_log-ba UPDATE esemény kerül, before_value = régi név, after_value = új név. |
| FR-8 | Belső ellenőr nem tud szerkeszteni | §2 | MUST | backend | Adott: Belső ellenőr JWT. Amikor: PUT /api/v1/branches/{id}. Akkor: 403 + VV-AUTH-001 + audit ACCESS_DENIED. |
| FR-9 | Idegen tenant irodája nem szerkeszthető | §1 | MUST | backend | Adott: T2 tenant JWT, T1 iroda id-je. Amikor: PUT /api/v1/branches/{id}. Akkor: 404 + audit VV-TENANT-001. |
| FR-10 | Kötelező mezők validációja | §6 | MUST | backend | Adott: iroda neve ürítve. Amikor: PUT /api/v1/branches/{id}. Akkor: 400 + VV-VALID-002 + hibaüzenet a formon. |
| FR-11 | Tartósan zárva = Inaktív | Interjú | MUST | backend | Adott: „Tartósan zárva" bejelölve, megerősítve. Amikor: PUT /api/v1/branches/{id}. Akkor: `is_active` = FALSE kerül mentésre. |

## 5. Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | Mentés válaszidő | PUT /api/v1/branches/{id} p95 < 500ms |
| NFR-2 | Lokalizáció | hu-HU minden felirat, megerősítő kérdések magyarul |
| NFR-3 | Validáció | Kötelező mezők: Pénztár száma, Pénztár pontos címe, Terület/Régió hozzárendelése |
| NFR-4 | Audit | Minden módosítás auditálva before_value + after_value-val (§3) |

## 6. Adatmodell-érintettség
- Új tábla / mező szükséges: NEM – a `branch` tábla V293 migrációja már tartalmaz minden szükséges mezőt
- Flyway migráció: NEM szükséges
- SQLite mirror: NEM érintett ebben az FK-ban (FK-024 hatóköre)

## 6.b Biztonsági érintettség (security-standards.md hivatkozással)
- [x] Új jogosultság / szerep (§2 – UPDATE jog: csak Főértéktáros)
- [ ] PII / pénzügyi adat (§3 – email, telefon nem pénzügyi PII)
- [x] Cross-tenant teszt szükséges (§1)
- [x] Új audit-esemény (§3 KAT: VALID action=UPDATE entity=Branch, before+after value)
- [ ] Secret / kulcs kezelést érint (§4)
- [ ] Offline szinkron biztonságát érinti (§5 – FK-024 hatóköre)
- [x] Új végpont (§2 rate limit + @PreAuthorize kötelező – PUT /api/v1/branches/{id})

## 7. Függőségek
- Belső modulok: Pénztár Törzs Adatbázis lista nézet (FK-020) – szerkesztés ikonból nyílik, sikeres mentés után ide navigál vissza
- Érintett más kliensek: backend PUT /api/v1/branches/{id} végpont
- Backend API: PUT /api/v1/branches/{id} (új vagy meglévő végpont kiegészítése az összes mezővel)

## 8. Domain-szótár
| Fogalom | Magyarázat |
|---|---|
| Branch | Iroda – lehet pénztár (is_vault=false) vagy értéktár (is_vault=true) |
| Bankkód | Banki hivatkozási szám – az iroda azonosítója a banki rendszerekben |
| Státuszváltás | Az iroda aktív/inaktív állapotának megváltoztatása – mindkét irányban megerősítés szükséges |
| before_value | Az audit logban tárolt régi érték módosítás előtt |
| after_value | Az audit logban tárolt új érték módosítás után |
| Tartósan zárva | Az iroda véglegesen vagy hosszú távon zárva – is_active = FALSE |

## 9. Végrehajtási utasítás az AI-fejlesztő ügynöknek

### 9.1. Előkészítés
1. `cd D:\repo\valutavalto-program`
2. `git checkout -b feature/kozponti-iroda-szerkesztes`

### 9.2. Fázisok

**Fázis 1 – Adatmodell**
- Nem szükséges – branch tábla és V293 migráció már tartalmaz minden mezőt
- Ellenőrzés: `SELECT column_name FROM information_schema.columns WHERE table_name = 'branch'` – szerepel-e `short_name`, `bank_code`, `has_afa`, `has_wu`, `has_mg`, `has_pos`, `closed_saturday`, `closed_sunday`

**Fázis 2 – Backend API**
- Meglévő végpont kiegészítése: `PUT /api/v1/branches/{id}` (`BranchController.java:270-279`)
- `@PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")` – már megvan, nem kell módosítani (§2)
- DTO: `UpdateBranchDto` már létezik – kiegészíteni szükséges: `isVault` és `vaultTerritoryId` mezőkkel, ha hiányoznak
- A `code` mező **nem kerül** az UpdateBranchDto-ba – a kód nem szerkeszthető
- Service: `companyId` szűrés már megvan (§1), audit log hozzáadása szükséges (jelenleg hiányzik)
- Acceptance: `PUT /api/v1/branches/{id}` 200-at ad vissza, az iroda frissített adatokkal jelenik meg a listában

```java
// BranchController.java – meglévő végpont, csak az audit log hozzáadása szükséges a service-ben
@PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
@PutMapping("/{id}")
public ResponseEntity<BranchDto> updateBranch(
        @PathVariable UUID id,
        @Valid @RequestBody UpdateBranchDto req) {
    BranchDto updated = branchService.update(id, req);
    return ResponseEntity.ok(updated);
}

// BranchService.java – audit log hozzáadása (jelenleg hiányzik)
// OSIV=false: minden lazy asszociáció csak @Transactional határon belül olvasható
@Transactional
public BranchDto update(UUID id, UpdateBranchDto req) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();

    // Tenant ellenőrzés (§1) – már megvan
    Branch branch = branchRepository.findByIdAndCompanyId(id, companyId)
        .orElseThrow(() -> new ResourceNotFoundException("VV-TENANT-001"));

    // Audit before – pillanatkép a régi állapotról, mutáció ELŐTT
    BranchDto before = branchMapper.toDto(branch);

    // Mezők frissítése (code NEM frissül)
    branch.setName(req.name());
    branch.setShortName(req.shortName() != null ? req.shortName() : "Pénztár " + branch.getCode());
    branch.setAddress(req.address());
    branch.setZipCode(req.zipCode());
    branch.setCity(req.city());
    branch.setPhone(req.phone());
    branch.setEmail(req.email());
    branch.setBankCode(req.bankCode());
    branch.setVault(req.isVault());
    branch.setActive(req.isActive());
    branch.setHasAfa(req.hasAfa());
    branch.setHasWu(req.hasWu());
    branch.setHasMg(req.hasMg());
    branch.setHasPos(req.hasPos());
    branch.setClosedSaturday(req.closedSaturday());
    branch.setClosedSunday(req.closedSunday());
    branch.setVaultTerritoryId(req.vaultTerritoryId());

    Branch saved = branchRepository.save(branch);

    // Audit after – mentés utáni állapot (§3)
    BranchDto after = branchMapper.toDto(saved);
    auditLogService.logWithDetails(
        "BRANCH_UPDATE", "Branch", id.toString(),
        userId, userName, id.toString(), saved.getName(),
        objectMapper.writeValueAsString(before),   // oldValue
        objectMapper.writeValueAsString(after),    // newValue
        reason, ipAddress);

    return after;
}
```

**Fázis 3 – Frontend**
- Érintett oldal: `frontend-react/src/pages/branches/BranchEditPage.tsx` (**új fájl** – nem létezik, létrehozni szükséges)
- Minta: `BranchCreatePage.tsx` – ez szolgál alapul az új szerkesztő oldalhoz
- Form előtöltése: `GET /api/v1/branches/{id}` alapján
- Form struktúra: azonos az FK-021 5 logikai csoportjával, előtöltött értékekkel
- Státuszváltás megerősítő kérdés logika:

```typescript
// BranchEditPage.tsx – státuszváltás megerősítő kérdés logika

const [confirmModal, setConfirmModal] = useState<{
  visible: boolean;
  message: string;
  onConfirm: () => void;
}>({ visible: false, message: '', onConfirm: () => {} });

const handleSubmit = async (formData) => {
  const originalIsActive = originalBranch.isActive;
  const newIsActive = !formData.tartosanZarva;

  // Státuszváltás ellenőrzés – mindkét irányban megerősítés kell
  if (originalIsActive !== newIsActive) {
    const message = newIsActive
      ? 'Biztosan aktívra állítja ezt az irodát?'
      : 'Biztosan inaktívra állítja ezt az irodát?';

    setConfirmModal({
      visible: true,
      message,
      onConfirm: () => submitUpdate(formData),
    });
    return;
  }

  await submitUpdate(formData);
};

const submitUpdate = async (formData) => {
  const payload = {
    ...formData,
    isActive: !formData.tartosanZarva,
  };
  await branchApi.update(branchId, payload);
  navigate('/admin/branches'); // visszanavigálás FK-020 listára
};

// Megerősítő modal megjelenítése
{confirmModal.visible && (
  <ConfirmModal
    message={confirmModal.message}
    onConfirm={() => {
      confirmModal.onConfirm();
      setConfirmModal({ ...confirmModal, visible: false });
    }}
    onCancel={() => setConfirmModal({ ...confirmModal, visible: false })}
  />
)}
```

```typescript
// frontend-react/src/services/api/settings.ts – branchApi kiegészítés
update: async (id: string, payload: BranchUpdateRequest): Promise<BranchInfo> => {
  const response = await api.put<BranchInfo>(`/branches/${id}`, payload);
  return response.data;
},
```

**Fázis 4 – Tesztek**
- JUnit (backend):
  - `BranchControllerTest.update_success` – happy path, 200
  - `BranchControllerTest.update_400_invalid_name` – kötelező mező ürítve
  - `BranchControllerTest.update_401_unauthenticated` – bejelentkezés nélkül → 401
  - `BranchControllerTest.update_403_belsoe_ellenor` – belső ellenőr nem tud szerkeszteni
  - `BranchControllerTest.update_404_otherTenant` – idegen tenant → 404
  - `BranchControllerTest.update_audit_log_before_after` – audit oldValue/newValue értékek
  - `BranchControllerTest.update_tartosan_zarva_is_inactive` – tartósan zárva → is_active=false
  - `BranchControllerTest.update_activate_branch` – inaktív → aktív státuszváltás
- Vitest (frontend):
  - `BranchEditPage.test.tsx` – form előtöltés, státuszváltás megerősítő modal, validáció
- Playwright E2E:
  - Iroda szerkesztése happy path
  - Aktív → Inaktív státuszváltás megerősítő kérdéssel
  - Inaktív → Aktív státuszváltás megerősítő kérdéssel
  - Megerősítő kérdésnél „Nem" → form visszatér módosítás nélkül
  - Duplikált kód → hibaüzenet jelenik meg
  - Mentés után visszanavigálás a listára, frissített adatok láthatók
- Edge case katalógus:
  - Kód mező read-only a formon – nem küldhető módosítás
  - Kötelező mező ürítve → validációs hibaüzenet
  - Email érvénytelen formátumra módosítva → validációs hiba
  - Státuszváltás megerősítő kérdésnél „Nem" → semmi nem változik az adatbázisban
  - Idegen tenant id → 404 (§1)
  - Belső ellenőr megpróbálja szerkeszteni → 403 + audit ACCESS_DENIED

```java
// BranchControllerTest.java – mintateszt-vázak

@Test
void update_success() {
    // Adott: Főértéktáros JWT, meglévő iroda, érvényes payload
    // Amikor: PUT /api/v1/branches/{id}
    // Akkor: 200 + frissített adatok visszaadva
    mockMvc.perform(put("/api/v1/branches/" + existingBranchId)
            .header("Authorization", "Bearer " + foertektarosToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content(validUpdateJson()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.code").value("BR100"));
}

@Test
void update_401_unauthenticated() {
    // Adott: nincs Authorization header
    // Amikor: PUT /api/v1/branches/{id}
    // Akkor: 401
    mockMvc.perform(put("/api/v1/branches/" + existingBranchId)
            .contentType(MediaType.APPLICATION_JSON)
            .content(validUpdateJson()))
        .andExpect(status().isUnauthorized());
}

@Test
void update_403_belsoe_ellenor() {
    // Adott: Belső ellenőr JWT
    // Amikor: PUT /api/v1/branches/{id}
    // Akkor: 403 + VV-AUTH-001
    mockMvc.perform(put("/api/v1/branches/" + existingBranchId)
            .header("Authorization", "Bearer " + belsoEllenorToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content(validUpdateJson()))
        .andExpect(status().isForbidden());
}

@Test
void update_404_otherTenant() {
    // Adott: T2 tenant JWT, T1 iroda id-je
    // Amikor: PUT /api/v1/branches/{id}
    // Akkor: 404 + audit VV-TENANT-001
    mockMvc.perform(put("/api/v1/branches/" + t1BranchId)
            .header("Authorization", "Bearer " + otherTenantToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content(validUpdateJson()))
        .andExpect(status().isNotFound());
}

@Test
void update_audit_log_before_after() {
    // Adott: iroda neve „Régi Név", módosítás „Új Név"-re
    // Amikor: PUT /api/v1/branches/{id}
    // Akkor: audit_log BRANCH_UPDATE esemény, oldValue.name="Régi Név", newValue.name="Új Név"
    mockMvc.perform(put("/api/v1/branches/" + existingBranchId)
            .header("Authorization", "Bearer " + foertektarosToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content(updateJsonWithName("Új Név")))
        .andExpect(status().isOk());
    // audit ellenőrzés:
    AuditLog audit = auditLogRepository.findLatestByEntityId(existingBranchId);
    assertThat(audit.getAction()).isEqualTo("BRANCH_UPDATE");
    assertThat(audit.getOldValue()).contains("Régi Név");
    assertThat(audit.getNewValue()).contains("Új Név");
}
```

### 9.3. Pipeline (Definition of Done)
1. `lint` PASS (eslint + checkstyle)
2. `mvn verify` PASS
3. `npm run test` (Vitest) PASS, coverage ≥80%
4. `npm run e2e` (Playwright) PASS
5. `gitleaks` secret-scan PASS (§4)
6. `grep -r "@Disabled\|@Ignore\|skip("` → 0 találat új kódon
7. Code review PR (1 reviewer)
8. `merge` → `push` → `deploy` → új telepítő generálása

## 10. Kockázatok / Nyitott kérdések (TBD)
| # | Kérdés | Státusz | Eredmény |
|---|---|---|---|
| 1 | PUT /api/v1/branches/{id} végpont már létezik-e? | ✅ MEGVÁLASZOLVA | Létezik – `BranchController.java:270-279`. Csak audit log hozzáadása szükséges. |
| 2 | BranchEditPage.tsx létezik-e már? | ✅ MEGVÁLASZOLVA | Nem létezik – új fájlként kell létrehozni. Minta: `BranchCreatePage.tsx`. |
| 3 | Branch.copy() metódus létezik-e az audit before_value-hoz? | ✅ MEGVÁLASZOLVA | Nem létezik. Megoldás: `branchMapper.toDto(branch)` a mutáció előtt, `auditLogService.logWithDetails()` `oldValue`/`newValue` JSON-nal. |

## 11. Kapcsolódó modulok
- [ ] Árfolyamkészítő
- [x] Központi kliens (elsődleges)
- [ ] Pénztári felület
- [ ] Értéktári felület

## 12. Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás (Interjú / §X)
- [x] Minden FR-hez Acceptance Given/When/Then
- [x] NFR-ek számszerűsítve (500ms, 80% coverage)
- [x] Nincs hallucináció (csak interjúban elhangzott + §referencia)
- [x] TBD-ek külön jelölve
- [x] Adatmodell konkrét (branch tábla, V293 migráció, mezők listája)
- [x] Flyway migráció: nem szükséges
- [x] Pipeline + Definition of Done teljes
- [x] Cross-tenant teszt megírva (§1)
- [x] @PreAuthorize minden új végponton (§2)
- [x] Audit-esemény jelölve (§3 KAT: VALID action=UPDATE entity=Branch before+after)
- [x] Nincs hard-coded secret (§4)
- [x] Offline biztonság (§5) – FK-024 hatóköre, itt nem érintett
- [x] Input DTO @Valid Bean Validation (§6)
- [x] Ha más klienst is érint: egyeztetés jelölve (11. szekció + 10. TBD)

---
FR-ek száma: 11 db
TBD-ek száma: 0 db (mind megválaszolva Code-feltérképezéssel)
Érintett csomagok: kozponti-client, backend
