# Árfolyam kezelés javítás — Implementációs terv

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Az árfolyam rögzítés és publikálás egységes pipeline-ba kerüljön (template → approve → publish → outbox → WebSocket push), multi-tenant biztonság, és a limit szintek helyes kezelése.

**Architecture:** A SettlementRateEntry frontend az árfolyamokat a RateTemplate táblába menti (DRAFT → auto-APPROVED → PUBLISHED), nem közvetlenül az exchange_rate-be. A RatePublishService kezeli az outbox event létrehozását, ami az OutboxSyncWorkerService-en keresztül WebSocket-en push-olja a pénztáraknak. Multi-tenant szűrés company_id-val minden rate management táblán.

**Tech Stack:** Java 21, Spring Boot 3.2, PostgreSQL Flyway, React 19 + TypeScript, Zustand

---

## Chunk 1: Adatbázis + Backend javítások

### Task 1: Flyway migráció — multi-tenant + limit mezők

**Files:**
- Create: `backend/src/main/resources/db/migration/V100__rate_management_multi_tenant_and_limits.sql`

- [ ] **Step 1: Migráció fájl létrehozása**

```sql
-- V100: Rate management multi-tenant support + template limit fields

-- 1. rate_workgroup: company_id hozzáadása
ALTER TABLE rate_workgroup ADD COLUMN IF NOT EXISTS company_id UUID;

-- Backfill: ha van company, a legelsőt használjuk
UPDATE rate_workgroup SET company_id = (SELECT id FROM company LIMIT 1) WHERE company_id IS NULL;

ALTER TABLE rate_workgroup ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE rate_workgroup ADD CONSTRAINT fk_rate_workgroup_company FOREIGN KEY (company_id) REFERENCES company(id);
CREATE INDEX IF NOT EXISTS idx_rate_workgroup_company ON rate_workgroup(company_id);

-- 2. rate_template: company_id + limit mezők
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS company_id UUID;
UPDATE rate_template SET company_id = (SELECT company_id FROM rate_workgroup WHERE rate_workgroup.id = rate_template.workgroup_id LIMIT 1) WHERE company_id IS NULL;
-- Ha nincs workgroup match, fallback
UPDATE rate_template SET company_id = (SELECT id FROM company LIMIT 1) WHERE company_id IS NULL;
ALTER TABLE rate_template ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE rate_template ADD CONSTRAINT fk_rate_template_company FOREIGN KEY (company_id) REFERENCES company(id);
CREATE INDEX IF NOT EXISTS idx_rate_template_company ON rate_template(company_id);

-- Limit mezők a template-hez (a régi rendszer 3 limit szintje)
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit1_amount NUMERIC(15,2);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit1_buy_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit1_sell_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit2_amount NUMERIC(15,2);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit2_buy_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit2_sell_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit3_amount NUMERIC(15,2);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit3_buy_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit3_sell_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS official_rate NUMERIC(18,6);

-- 3. rate_publication: company_id
ALTER TABLE rate_publication ADD COLUMN IF NOT EXISTS company_id UUID;
UPDATE rate_publication SET company_id = (SELECT company_id FROM rate_workgroup WHERE rate_workgroup.id = rate_publication.workgroup_id LIMIT 1) WHERE company_id IS NULL;
UPDATE rate_publication SET company_id = (SELECT id FROM company LIMIT 1) WHERE company_id IS NULL;
ALTER TABLE rate_publication ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE rate_publication ADD CONSTRAINT fk_rate_publication_company FOREIGN KEY (company_id) REFERENCES company(id);

-- 4. rate_discount: company_id
ALTER TABLE rate_discount ADD COLUMN IF NOT EXISTS company_id UUID;
UPDATE rate_discount SET company_id = (SELECT company_id FROM rate_workgroup WHERE rate_workgroup.id = rate_discount.workgroup_id LIMIT 1) WHERE company_id IS NULL;
UPDATE rate_discount SET company_id = (SELECT id FROM company LIMIT 1) WHERE company_id IS NULL;
ALTER TABLE rate_discount ALTER COLUMN company_id SET NOT NULL;
```

- [ ] **Step 2: Commit**
```bash
git add backend/src/main/resources/db/migration/V100__rate_management_multi_tenant_and_limits.sql
git commit -m "feat: V100 rate management multi-tenant + template limit fields"
```

### Task 2: RateTemplate entity — limit mezők + company_id

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/entity/RateTemplate.java`

- [ ] **Step 1: Entity frissítése**

Hozzáadandó mezők a RateTemplate.java-hoz:
```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "company_id", nullable = false)
private Company company;

@Column(name = "official_rate", precision = 18, scale = 6)
private BigDecimal officialRate;

@Column(name = "limit1_amount", precision = 15, scale = 2)
private BigDecimal limit1Amount;
@Column(name = "limit1_buy_rate", precision = 18, scale = 6)
private BigDecimal limit1BuyRate;
@Column(name = "limit1_sell_rate", precision = 18, scale = 6)
private BigDecimal limit1SellRate;

@Column(name = "limit2_amount", precision = 15, scale = 2)
private BigDecimal limit2Amount;
@Column(name = "limit2_buy_rate", precision = 18, scale = 6)
private BigDecimal limit2BuyRate;
@Column(name = "limit2_sell_rate", precision = 18, scale = 6)
private BigDecimal limit2SellRate;

@Column(name = "limit3_amount", precision = 15, scale = 2)
private BigDecimal limit3Amount;
@Column(name = "limit3_buy_rate", precision = 18, scale = 6)
private BigDecimal limit3BuyRate;
@Column(name = "limit3_sell_rate", precision = 18, scale = 6)
private BigDecimal limit3SellRate;
```

### Task 3: RateWorkgroup + RatePublication entity — company_id

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/entity/RateWorkgroup.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/entity/RatePublication.java`

- [ ] **Step 1: RateWorkgroup.java — company_id mező**
```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "company_id", nullable = false)
private Company company;
```

- [ ] **Step 2: RatePublication.java — company_id mező**
```java
@Column(name = "company_id", nullable = false)
private UUID companyId;
```

### Task 4: Service-ek multi-tenant szűrése

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/service/RateWorkgroupService.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/service/RateTemplateService.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/repository/RateWorkgroupRepository.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/repository/RateTemplateRepository.java`

- [ ] **Step 1: RateWorkgroupRepository — company szűrés**
```java
List<RateWorkgroup> findByCompanyIdAndActiveTrue(UUID companyId);
List<RateWorkgroup> findByCompanyId(UUID companyId);
```

- [ ] **Step 2: RateTemplateRepository — company szűrés**
```java
List<RateTemplate> findByCompanyIdAndWorkgroupId(UUID companyId, UUID workgroupId);
List<RateTemplate> findByCompanyIdAndStatus(UUID companyId, RateTemplate.RateTemplateStatus status);
```

- [ ] **Step 3: RateWorkgroupService — SecurityUtils.getCurrentCompanyId() használata**

- [ ] **Step 4: RateTemplateService — SecurityUtils.getCurrentCompanyId() használata**

### Task 5: RatePublishService — limit szintek a template-ből

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/service/RatePublishService.java`

- [ ] **Step 1: applyTemplatesToExchangeRates() — limit szintek a template-ből, ne a korábbi rátából**

Az `applyTemplatesToExchangeRates` metódusban a limit mezők a template-ből jönnek:
```java
.limit1Amount(template.getLimit1Amount())
.limit1BuyRate(template.getLimit1BuyRate())
.limit1SellRate(template.getLimit1SellRate())
// ... stb
.officialRate(template.getOfficialRate() != null ? template.getOfficialRate() : resolveOfficialRate(latestRate, buyRate, sellRate))
```

### Task 6: SettlementRateEntry backend — átirányítás a template pipeline-ba

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`

- [ ] **Step 1: publishGroupRate() átírása — template + auto-approve + publish**

A publishGroupRate() metódus NE hívja közvetlenül az ExchangeRateService.createExchangeRate()-et.
Ehelyett:
1. Hozzon létre RateTemplate-eket DRAFT státusszal
2. Automatikusan APPROVED-ra állítsa
3. Hívja a RatePublishService.publish()-t a workgroup-ra

```java
public void publishGroupRate(GroupRateDTO groupRateDTO) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();

    // Workgroup meghatározás: ha groupId nincs, default workgroup
    UUID workgroupId = groupRateDTO.getGroupId();
    RateWorkgroup workgroup;
    if (workgroupId != null) {
        workgroup = workgroupRepository.findById(workgroupId)
            .orElseThrow(() -> new ValidationException("Munkacsoport nem található"));
    } else {
        workgroup = workgroupRepository.findByCompanyIdAndActiveTrue(companyId)
            .stream().findFirst()
            .orElseThrow(() -> new ValidationException("Nincs aktív munkacsoport! Hozzon létre egyet."));
        workgroupId = workgroup.getId();
    }

    List<UUID> templateIds = new ArrayList<>();
    for (GroupRateDTO.RateEntry entry : groupRateDTO.getRates()) {
        // Validáció...
        RateTemplate template = RateTemplate.builder()
            .company(companyRepository.findById(companyId).orElseThrow())
            .currencyId(entry.getCurrencyId())
            .workgroupId(workgroupId)
            .baseBuyRate(entry.getBuyRate())
            .baseSellRate(entry.getSellRate())
            .officialRate(entry.getOfficialRate())
            .limit1Amount(entry.getLimit1Amount())
            // ... limit szintek
            .status(RateTemplate.RateTemplateStatus.APPROVED) // auto-approve
            .createdBy(SecurityUtils.getCurrentWorkerId())
            .approvedBy(SecurityUtils.getCurrentWorkerId())
            .approvedAt(LocalDateTime.now())
            .build();
        template = templateRepository.save(template);
        templateIds.add(template.getId());
    }

    ratePublishService.publish(workgroupId, templateIds, "Árfolyam rögzítés publikálás");
}
```

## Chunk 2: Frontend javítások

### Task 7: SettlementRateEntry — workgroup választó hozzáadása

**Files:**
- Modify: `frontend-react/src/pages/ratemanagement/SettlementRateEntry.tsx`

- [ ] **Step 1: Workgroup select hozzáadása a fejléchez**

Fetch workgroups a betöltéskor, és a payload-ba a kiválasztott workgroup ID-t is küldjük.

### Task 8: RateTemplateEditor — limit szintek hozzáadása

**Files:**
- Modify: `frontend-react/src/pages/ratemanagement/RateTemplateEditor.tsx`

- [ ] **Step 1: RateTemplate interface bővítése limit mezőkkel**
```typescript
interface RateTemplate {
  // ... meglévő mezők
  officialRate: string
  limit1Amount: string
  limit1BuyRate: string
  limit1SellRate: string
  limit2Amount: string
  limit2BuyRate: string
  limit2SellRate: string
  limit3Amount: string
  limit3BuyRate: string
  limit3SellRate: string
}
```

- [ ] **Step 2: Limit szerkesztő UI hozzáadása a form-hoz**

## Chunk 3: Ellenőrzés

### Task 9: Backend compile és tesztfuttatás

- [ ] **Step 1: mvnw compile**
- [ ] **Step 2: mvnw test**
- [ ] **Step 3: Hibák javítása ha van**

### Task 10: Frontend build és lint

- [ ] **Step 1: npm run build (frontend-react)**
- [ ] **Step 2: Hibák javítása ha van**

### Task 11: Commit

- [ ] **Step 1: Összes változás commit**
