# Implementacios Terv: Kamera Rendszer & Arfolyam Keszites

**Verzio:** 1.0
**Datum:** 2026-03-06
**Projekt:** Valutavalto Program — uj alrendszerek

---

## TARTALOMJEGYZEK

1. [Jelenlegi Program Allapot vs Legacy Anti Rendszerek](#1-osszehasonlitas)
2. [Kamera Megfigyelo Rendszer](#2-kamera-rendszer)
3. [Arfolyam Keszito Rendszer](#3-arfolyam-keszito)
4. [Adatbazis Migraciok](#4-adatbazis)
5. [Biztonsagi Architektura](#5-biztonsag)
6. [Vegrehajtasi Utemterv](#6-utemterv)

---

## 1. OSSZEHASONLITAS: Jelenlegi Program vs Legacy Anti Rendszerek

### 1.1. Jelenlegi program kepes:
- Tranzakciokezeles (vetel/eladas/konverzio/storno)
- Ugyfel-azonositas (AML, PEP, szankcios lista)
- Arfolyam megjelenites (MNB import, manualis beallitas)
- Penztar menedzsment (nyitas/zaras/denomination/break)
- Jutalek szamitas (tier-alapu, bonusz)
- Havi archivalas
- NAV Online Szamla integracio
- Jogosultsagi rendszer (RBAC, JWT)
- Ertektari modul (treasury)
- Riporting (standard + kiterjesztett)

### 1.2. Anti mappaban talalt, MEG NEM IMPLEMENTALT rendszerek:

| Legacy Rendszer | Jelenlegi Allapot | Prioritas |
|----------------|-------------------|-----------|
| **Kamera felvetel** (CameraCenter, CameraOffice, CameraConfig, CameraPlayer) | Nincs | KRITIKUS |
| **Arfolyam keszito** (ARFOLYAM.exe, XOR-kodolt .dat fajlok, FTP szinkron) | Reszleges (MNB import van, de napi arfolyam-keszites nincs) | MAGAS |

### 1.3. Legacy kamera rendszer elemzese (Anti/CameraCenter, CameraOffice, CameraConfig, CameraPlayer)

A legacy rendszer **4 kulon Java/JavaFX alkalmazasbol** allt:
- **CameraCenter**: Kozponti szerver, binaris C1/C2 fajlok tarolasa, 50 napos auto-torles
- **CameraOffice**: Irodai felvetel-keszito, webcam-capture konyvtar, JPEG frame-ek binaris kontenerben
- **CameraConfig**: Kamera konfiguracio (felbontas, FPS, mentesi utvonal)
- **CameraPlayer**: Visszajatszo, binaris fajl ertelmezese, bizonylatszam szerinti kereses

Legacy binaris formatum (C1/C2):
```
[4 byte: frame meret][3 byte: idopecset][8 byte: bizonylatszam][JPEG adat]
```

### 1.4. Legacy arfolyam-keszito rendszer elemzese (Anti/ARFOLYAM)

A legacy rendszer **Delphi/Pascal alkalmazas** volt:
- XOR 255-tel kodolt binaris .dat fajlok
- 28 valuta x 9 oszlop x 4 tulajdonsag cellankent
- 54 munkacsoport (workgroup) kulon arfolyamokkal
- 3 szintu kedvezmeny csoportonkent
- FTP szinkronizacio a penztarakhoz
- Verzio 15/16 header, kompatibilitasi reteg

---

## 2. KAMERA MEGFIGYELO RENDSZER

### 2.1. Architektura attekintes

```
USB Webkamera (1-2 db/penztargep)
        |
        v
+-------------------+         +-------------------+
| PENZTARGEP (helyi) |  HTTPS  | KOZPONTI SZERVER  |
|                   | ------> |                   |
| Spring Boot       |         | Spring Boot       |
| lokalis szolg.    |         | backend           |
| + helyi tarolas   |         | + szerver tarolas  |
| (50 nap)          |         | (50 nap)          |
+-------------------+         +-------------------+
```

**Dontesi pont:** USB webkamerak hasznalata (nem IP/ONVIF kamerak).

### 2.2. Komponensek

#### 2.2.1. Backend — Kamera modul (`hu.puzzleir.valuta.camera`)

**Uj package struktura:**
```
camera/
  config/
    CameraProperties.java          -- Spring @ConfigurationProperties
    WebcamConfig.java               -- Webcam inicializacio
  service/
    CameraRecordingService.java     -- Felvevesi logika, frame capture
    CameraStorageService.java       -- Helyi fajl tarolas (titkositott)
    CameraUploadService.java        -- Szerver fele feltoltes
    CameraCleanupService.java       -- 50 napos auto-torles (helyi + szerver)
    CameraTransactionLinker.java    -- Tranzakcio-felvetel osszekapcsolas
  controller/
    CameraController.java           -- REST API (lejatszas, kereses, statusz)
    CameraAdminController.java      -- Admin (konfiguracio, torles, statisztika)
  entity/
    CameraRecording.java            -- JPA entity (metaadatok DB-ben)
    CameraFrame.java                -- Opcionalis: frame-szintu index
  repository/
    CameraRecordingRepository.java
  dto/
    CameraStatusDto.java
    RecordingSearchDto.java
    RecordingMetadataDto.java
```

#### 2.2.2. Webcam kezeles — `webcam-capture` konyvtar

**Maven fuggoseg:**
```xml
<dependency>
    <groupId>com.github.sarxos</groupId>
    <artifactId>webcam-capture</artifactId>
    <version>0.3.12</version>
</dependency>
```

**Mukodesi elv:**
1. Alkalmazas indulaskor: `Webcam.getWebcams()` — osszes csatlakoztatott kamera felderitese
2. Konfiguracio szerint kivalasztja a megfelelo kamerat (index vagy nev alapjan)
3. Folyamatos capture loop a teljes nyitvatartasi ido alatt
4. Frame-ek JPEG-be kodolasa es tarolasa

#### 2.2.3. Felvetelek tarolasa — Kettos tarolas

**A) Helyi tarolas (penztargepen):**
```
C:\valuta\camera\
  2026\
    03\
      06\
        cam1_20260306_083000_093000.enc    -- 1 oras szegmensek, titkositva
        cam1_20260306_093000_103000.enc
        ...
```

- AES-256-GCM titkositas (kulcs: szerver-oldali key management)
- 1 oras szegmensek (kezelheto fajlmeret, ~200-500 MB/ora, fugg a felbontastol)
- Fajlnev: `{kameraId}_{datum}_{kezdes}_{veg}.enc`
- Metadata DB-ben tarolva (nem a fajlnevben)

**B) Szerveres tarolas (kozponti):**
- Azonos struktura, de a szerveren
- Feltoltes: hatterben, utemezetten (pl. 5 percenkent)
- Ha a halozat nem elerheto: helyi queue, ujrakuldes ha visszajon
- Mindket helyen 50 napig megorizve

**50 napos torles mehanizmusa:**
```java
@Scheduled(cron = "0 0 2 * * *")  // Minden ejjel 2:00-kor
public void cleanupExpiredRecordings() {
    LocalDate cutoff = LocalDate.now().minusDays(50);
    // 1. DB-bol lekerdezni a lejart rekordokat
    // 2. Fizikai fajlok torlese (helyi)
    // 3. Szerver-oldali fajlok torlese (API hivas)
    // 4. DB rekordok torlese
    // 5. Audit log bejegyzes
}
```

#### 2.2.4. Tranzakcio-felvetel osszekapcsolas

A legacy rendszer a `C:\valuta\aktbizo.txt` fajlbol olvasta a bizonylatszamot.

**Uj megoldas — API-alapu:**
```java
// TransactionService.createTransaction() vegen:
cameraTransactionLinker.linkTransaction(
    transactionId,    // UUID
    branchId,         // UUID
    timestamp,        // LocalDateTime
    receiptNumber     // String (bizonylatszam)
);
```

Ez a CameraRecording entitasban tarolja az osszekapcsolast:
```java
@Entity
@Table(name = "camera_recording")
public class CameraRecording {
    @Id
    private UUID id;
    private UUID branchId;
    private String cameraId;          // "cam1", "cam2"
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String filePath;          // helyi utvonal
    private String serverPath;        // szerveres utvonal
    private Long fileSizeBytes;
    private boolean uploadedToServer;
    private LocalDate expiresAt;      // startTime + 50 nap

    // Tranzakcio linkeles
    @OneToMany(mappedBy = "recording")
    private List<CameraTransactionLink> transactionLinks;
}

@Entity
@Table(name = "camera_transaction_link")
public class CameraTransactionLink {
    @Id
    private UUID id;
    @ManyToOne
    private CameraRecording recording;
    private UUID transactionId;
    private String receiptNumber;
    private LocalDateTime transactionTime;
    private Integer frameOffset;      // hanyadik masodpercnel tortent
}
```

#### 2.2.5. Folyamatos rogzites — Teljes nyitvatartasi ido

```java
@Service
public class CameraRecordingService {

    // Alkalmazas indulaskor automatikusan elindul
    @EventListener(ApplicationReadyEvent.class)
    public void startRecording() {
        // 1. Webcam(ok) megnyitasa
        // 2. Capture thread inditasa kameranként
        // 3. Uj szegmens inditas oranként
    }

    // Alkalmazas leallitasakor leall
    @PreDestroy
    public void stopRecording() {
        // 1. Aktualis szegmens lezarasa
        // 2. Webcam(ok) felszabaditasa
    }

    // Capture loop (kulon szalban, kameranként)
    private void captureLoop(Webcam webcam, String cameraId) {
        while (running) {
            BufferedImage frame = webcam.getImage();
            // JPEG kodolas
            // Titkositott fajlba iras
            // FPS szabalyozas (pl. 5 FPS — eleg az azonositashoz)
            Thread.sleep(200); // 5 FPS
        }
    }
}
```

**FPS es felbontas ajanlasok:**
| Beallitas | Ertek | Indoklas |
|-----------|-------|----------|
| Felbontas | 640x480 | Elegseges arc-azonositashoz, kicsi fajlmeret |
| FPS | 5 | Folyamatos, de takarekos; 1 ora ~ 90.000 frame |
| JPEG minoseg | 70% | Jo minoseg, kezelheto meret |
| Becsult meret | ~200 MB/ora/kamera | 640x480 @ 5fps @ 70% JPEG |

#### 2.2.6. Frontend — Kamera modul

**Uj oldalak:**
```
frontend-react/src/pages/camera/
  CameraLivePage.tsx          -- Elo kamerakep + tranzakcio linkelés
  CameraPlaybackPage.tsx      -- Visszajatszo (datum/ido/bizonylatszam kereses)
  CameraConfigPage.tsx        -- Admin: kamera beallitasok
  CameraStatusPage.tsx        -- Osszes kamera allapota, tarhelyhasznalat
```

**Elo kamerakep megjelenites:**
- MJPEG stream a backend-tol: `GET /api/v1/camera/stream/{cameraId}`
- Vagy WebSocket frame-ek (hatekonabb)
- A penztaros latja a kamerakepet a tranzakcio rogzites kozben

**Visszajatszo:**
- Idovonal (timeline) komponens
- Bizonylatszam szerinti kereses
- Frame-enkenti lepegetés (elore/hatra)
- Export lehetoseg (jogosultsag-korlatos)

#### 2.2.7. REST API vegpontok

```
# Elo stream
GET  /api/v1/camera/stream/{cameraId}          -- MJPEG stream
GET  /api/v1/camera/status                      -- Osszes kamera statusz

# Felvetelek
GET  /api/v1/camera/recordings                  -- Lista (szurokkel)
GET  /api/v1/camera/recordings/{id}             -- Egy felvetel metaadata
GET  /api/v1/camera/recordings/{id}/play        -- Felvetel visszajatszas
GET  /api/v1/camera/recordings/by-receipt/{num} -- Kereses bizonylatszamra
GET  /api/v1/camera/recordings/by-date          -- Kereses datum/idosav

# Admin
POST /api/v1/camera/config                      -- Kamera konfiguracio mentes
GET  /api/v1/camera/storage-stats               -- Tarhely statisztikak
POST /api/v1/camera/cleanup/manual              -- Manualis torles (ADMIN)
```

### 2.3. GDPR es adatvedelmi kovetelmények

1. **Titkositott tarolas**: AES-256-GCM, kulcs nem a felvetellel egyutt tarolva
2. **Hozzaferesi jogosultsag**: Csak MANAGER/ADMIN lathatja a felveteleket
3. **Audit log**: Minden lejatszas/export naplozva
4. **Automatikus torles**: 50 nap utan — NEM konfiguralható felhasznaloi szinten
5. **Adatvedelem**: A felvetelek NEM kereshetők tartalom alapjan (nincs arcfelismeres)
6. **Tajekoztatasi kotelezettseg**: Az ugyfelet tajekoztatni kell (matrica + szobeli)

### 2.4. Megbizhatosag es hibaturés

| Scenario | Megoldas |
|----------|---------|
| Webcam kihuzasa | Auto-reconnect, 5mp-enkent proba, riasztas ha 1 percnel tovabb nem elerheto |
| Lemez megtelik | Figyelmeztetes 90%-nal, leallitas 95%-nal, legoregebbi nem-linkelt felvetel torlese |
| Halozat kiesik | Helyi tarolas folytatodik, feltoltes queue-ba kerul, ujrakuldes ha visszajon |
| Alkalmazas crash | Utolso szegmens lezaratlan — indulaskor recovery |
| Aramszunet | Helyi tarolas elerhetonek kell maradnia ujrainditaskor |

---

## 3. ARFOLYAM KESZITO RENDSZER

### 3.1. Architektura attekintes

```
+---------------------------+
| Foertektaros (bongeszo)   |
| Arfolyam keszito UI       |
+---------------------------+
            |
            v  HTTPS/REST
+---------------------------+
| Kozponti Szerver          |
| Spring Boot Backend       |
| - Arfolyam CRUD           |
| - Munkacsoport kezeles    |
| - Kedvezmeny tier-ek      |
| - Jovahagyas workflow     |
| - Publikalas              |
+---------------------------+
            |
            v  WebSocket / Polling
+---------------------------+
| Penztargepek              |
| Automatikus arfolyam      |
| frissites                 |
+---------------------------+
```

### 3.2. Legacy rendszer lenyege (mit kell kiváltani)

A legacy ARFOLYAM.exe:
1. **Foertektaros** megnyitja a programot
2. **28 valutat** lat tablazatban, mindegyikhez 9 oszlop (vetel/eladas arfolyamok)
3. Minden valutahoz **4 tulajdonsag**: alapar, eladasi felár, veteli felár, kerekites
4. **54 munkacsoport** — kulonbozo irodak/penztarak mas-mas arfolyamot kaphatnak
5. **3 kedvezmenyi szint** csoportonkent (VIP, tozsugyfél, stb.)
6. Megnyomja a "Mentés" gombot → XOR 255-tel kodolt .dat fajl generalodik
7. **FTP-vel** felmasolodik az osszes penztargepre
8. A penztarprogram 30mp-enkent ellenorzi az FTP mappat, es betolti az uj arfolyamot

### 3.3. Uj rendszer — Backend komponensek

**Uj package struktura:**
```
ratemanagement/
  config/
    RateManagementProperties.java
  service/
    RateCreationService.java        -- Arfolyam keszites uzleti logika
    RateWorkgroupService.java       -- Munkacsoport kezeles
    RatePublishService.java         -- Publikalas az osszes penztarhoz
    RateDiscountService.java        -- Kedvezmeny szintek
    RateApprovalService.java        -- Jovahagyasi workflow
  controller/
    RateCreationController.java     -- REST API
  entity/
    RateTemplate.java               -- Arfolyam sablon (foertektaros altal szerkesztve)
    RateWorkgroup.java              -- Munkacsoport definicio
    RateDiscount.java               -- Kedvezmeny szint definicio
    RatePublication.java            -- Publikalasi naplo
  repository/
    RateTemplateRepository.java
    RateWorkgroupRepository.java
    RateDiscountRepository.java
    RatePublicationRepository.java
  dto/
    RateTemplateDto.java
    RatePublishRequestDto.java
    WorkgroupAssignmentDto.java
  websocket/
    RateUpdateWebSocketHandler.java -- Real-time ertesites
```

#### 3.3.1. Entitasok

```java
@Entity
@Table(name = "rate_template")
public class RateTemplate {
    @Id
    private UUID id;
    private UUID currencyId;
    private UUID workgroupId;           // melyik munkacsoporthoz
    private BigDecimal baseBuyRate;      // alap veteli arfolyam
    private BigDecimal baseSellRate;     // alap eladasi arfolyam
    private BigDecimal buySpread;        // veteli felar
    private BigDecimal sellSpread;       // eladasi felar
    private Integer roundingRule;        // kerekites (0, 1, 5, 10)
    private String status;              // DRAFT, APPROVED, PUBLISHED
    private LocalDateTime createdAt;
    private Long createdBy;             // foertektaros workerId
    private LocalDateTime publishedAt;
    private Long approvedBy;
}

@Entity
@Table(name = "rate_workgroup")
public class RateWorkgroup {
    @Id
    private UUID id;
    private String name;                // pl. "Budapest kozpont", "Videki irodak"
    private String code;                // pl. "WG01"
    private Integer legacyGroupNumber;  // legacy 1-54 szam (migracios cel)
    private boolean active;

    @ManyToMany
    private Set<Branch> branches;       // melyik fiokokhoz tartozik
}

@Entity
@Table(name = "rate_discount")
public class RateDiscount {
    @Id
    private UUID id;
    private UUID workgroupId;
    private Integer level;              // 1, 2, 3
    private String name;                // "VIP", "Tozsugyfél", "Kiemelt"
    private BigDecimal buyDiscountPercent;
    private BigDecimal sellDiscountPercent;
    private boolean active;
}
```

#### 3.3.2. Arfolyam keszites workflow

```
1. Foertektaros megnyitja a webes feluletet
2. Latja a 28 valuta tablazatot (vagy amennyit a rendszerben kezelt)
3. MNB kozeparfolyamot automatikusan betolti referenciaként
4. Beallitja: baseBuyRate, baseSellRate, spread, kerekites
5. Kivalasztja a munkacsoporto(ka)t
6. "Mentes mint piszkozat" → DRAFT status
7. "Jovahagyas" → APPROVED status (opcionalis masodik szem)
8. "Publikalas" → PUBLISHED → WebSocket ertesites → penztarak frissulnek
```

#### 3.3.3. Publikalas mechanizmus (FTP helyett)

**Legacy:** FTP-vel masolta a .dat fajlt → penztarprogram 30mp-enkent pollingolta

**Uj megoldas — WebSocket + REST fallback:**

```java
// Szerver oldal — publikalaskor:
@Service
public class RatePublishService {

    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public void publish(UUID templateId) {
        RateTemplate template = // ... betoltes, status PUBLISHED-re allitas

        // 1. Exchange rate tablaba is beirkja (a letezo ExchangeRate entity)
        exchangeRateService.createFromTemplate(template);

        // 2. WebSocket broadcast az osszes csatlakozott penztarhoz
        messagingTemplate.convertAndSend(
            "/topic/rate-updates/" + template.getWorkgroupId(),
            new RateUpdateMessage(template)
        );

        // 3. Publikalasi naplo
        ratePublicationRepo.save(new RatePublication(...));
    }
}
```

**Penztargep oldalon (frontend):**
```typescript
// WebSocket feliratkozas
useEffect(() => {
    const ws = new WebSocket(`wss://${host}/ws/rate-updates`);
    ws.onmessage = (event) => {
        const update = JSON.parse(event.data);
        // Arfolyam tablazat frissitese
        rateStore.updateRates(update.rates);
        // Ertesites a penztarosnak
        toast.info('Uj arfolyamok erkeztek!');
    };
    return () => ws.close();
}, []);
```

**Fallback polling** (ha WebSocket nem elerheto):
```
GET /api/v1/rates/latest?workgroupId={id}&since={timestamp}
// 30 masodpercenkent poll — pont mint a legacy
```

### 3.4. Frontend — Arfolyam keszito oldal

**Uj oldalak:**
```
frontend-react/src/pages/ratemanagement/
  RateCreationDashboard.tsx     -- Foertektaros fo oldal
  RateTemplateEditor.tsx        -- Tablazatos arfolyam szerkeszto
  WorkgroupManager.tsx          -- Munkacsoport kezeles
  DiscountLevelEditor.tsx       -- Kedvezmeny szintek
  RatePublishHistory.tsx        -- Publikalasi elozmények
```

**Tablazatos szerkeszto (RateTemplateEditor):**
- Sorok: valutak (EUR, USD, GBP, CHF, ...)
- Oszlopok: Veteli ar | Eladasi ar | Veteli spread | Eladasi spread | Kerekites | MNB ref. | Kulonbozet
- Inline editing (kattintas → szerkesztes)
- Szines jelzes: ha a spread tul nagy/kicsi
- MNB kozeparfolyam automatikus betoltese referenciaként

### 3.5. REST API vegpontok

```
# Arfolyam sablonok
GET    /api/v1/rate-management/templates                  -- Osszes sablon
POST   /api/v1/rate-management/templates                  -- Uj sablon
PUT    /api/v1/rate-management/templates/{id}              -- Sablon modositas
DELETE /api/v1/rate-management/templates/{id}              -- Sablon torles

# Workflow
POST   /api/v1/rate-management/templates/{id}/approve      -- Jovahagyas
POST   /api/v1/rate-management/templates/{id}/publish       -- Publikalas
POST   /api/v1/rate-management/templates/{id}/revoke        -- Visszavonas

# Munkacsoportok
GET    /api/v1/rate-management/workgroups                  -- Osszes csoport
POST   /api/v1/rate-management/workgroups                  -- Uj csoport
PUT    /api/v1/rate-management/workgroups/{id}              -- Modositas
POST   /api/v1/rate-management/workgroups/{id}/assign-branches  -- Fiok hozzarendeles

# Kedvezmenyek
GET    /api/v1/rate-management/discounts/{workgroupId}     -- Csoport kedvezmenyei
POST   /api/v1/rate-management/discounts                   -- Uj kedvezmeny szint
PUT    /api/v1/rate-management/discounts/{id}               -- Modositas

# Publikalasi naplo
GET    /api/v1/rate-management/publications                -- Elozmények
```

---

## 4. ADATBAZIS MIGRACIOK

### V51 — Kamera rendszer tablak

```sql
-- V51__camera_system_tables.sql

CREATE TABLE camera_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    camera_id VARCHAR(50) NOT NULL,         -- "cam1", "cam2"
    camera_name VARCHAR(100),
    device_index INTEGER DEFAULT 0,
    resolution_width INTEGER DEFAULT 640,
    resolution_height INTEGER DEFAULT 480,
    fps INTEGER DEFAULT 5,
    jpeg_quality INTEGER DEFAULT 70,
    local_storage_path VARCHAR(500),
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(branch_id, camera_id)
);

CREATE TABLE camera_recording (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    camera_id VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    file_path VARCHAR(500),                 -- helyi fajl
    server_path VARCHAR(500),               -- szerveres fajl
    file_size_bytes BIGINT,
    uploaded_to_server BOOLEAN DEFAULT false,
    upload_attempts INTEGER DEFAULT 0,
    expires_at DATE NOT NULL,               -- start_time + 50 nap
    status VARCHAR(20) DEFAULT 'RECORDING', -- RECORDING, COMPLETED, UPLOADED, EXPIRED
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_camera_recording_branch_date ON camera_recording(branch_id, start_time);
CREATE INDEX idx_camera_recording_expires ON camera_recording(expires_at);
CREATE INDEX idx_camera_recording_upload ON camera_recording(uploaded_to_server) WHERE NOT uploaded_to_server;

CREATE TABLE camera_transaction_link (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID NOT NULL REFERENCES camera_recording(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL,
    receipt_number VARCHAR(50),
    transaction_time TIMESTAMP NOT NULL,
    frame_offset_seconds INTEGER,           -- hany mp-nel a szegmens elejetol
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_camera_tx_link_receipt ON camera_transaction_link(receipt_number);
CREATE INDEX idx_camera_tx_link_tx ON camera_transaction_link(transaction_id);

CREATE TABLE camera_access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES camera_recording(id),
    worker_id BIGINT NOT NULL,
    action VARCHAR(30) NOT NULL,            -- VIEW, EXPORT, DELETE
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### V52 — Arfolyam keszito tablak

```sql
-- V52__rate_management_tables.sql

CREATE TABLE rate_workgroup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    legacy_group_number INTEGER,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rate_workgroup_branch (
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    branch_id UUID NOT NULL REFERENCES branch(id),
    PRIMARY KEY (workgroup_id, branch_id)
);

CREATE TABLE rate_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_id UUID NOT NULL REFERENCES currency(id),
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    base_buy_rate NUMERIC(18,6) NOT NULL,
    base_sell_rate NUMERIC(18,6) NOT NULL,
    buy_spread NUMERIC(18,6) DEFAULT 0,
    sell_spread NUMERIC(18,6) DEFAULT 0,
    rounding_rule INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'DRAFT',     -- DRAFT, APPROVED, PUBLISHED, REVOKED
    created_by BIGINT,
    approved_by BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    published_at TIMESTAMP,
    UNIQUE(currency_id, workgroup_id, status) -- egy aktiv PUBLISHED per valuta/csoport
);

CREATE INDEX idx_rate_template_wg_status ON rate_template(workgroup_id, status);

CREATE TABLE rate_discount (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 3),
    name VARCHAR(50) NOT NULL,
    buy_discount_percent NUMERIC(8,4) DEFAULT 0,
    sell_discount_percent NUMERIC(8,4) DEFAULT 0,
    active BOOLEAN DEFAULT true,
    UNIQUE(workgroup_id, level)
);

CREATE TABLE rate_publication (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES rate_template(id),
    workgroup_id UUID NOT NULL,
    published_by BIGINT NOT NULL,
    published_at TIMESTAMP DEFAULT NOW(),
    affected_branches INTEGER DEFAULT 0,
    notes TEXT
);
```

---

## 5. BIZTONSAGI ARCHITEKTURA

### 5.1. Kamera rendszer biztonsag

| Reteg | Megoldas |
|-------|---------|
| **Fajl titkositas** | AES-256-GCM, kulcs a szerveren (nem a penztargepen) |
| **Kulcskezeles** | Indulaskor a szerver kuldi a dekriptalo kulcsot (HTTPS) |
| **Hozzaferes** | MANAGER/ADMIN: lejatszas; ADMIN: konfiguracio, torles |
| **Audit** | Minden lejatszas/export logolva `camera_access_log` tablaba |
| **Halozat** | HTTPS-only kommunikacio szerver fele |
| **Tarolas helye** | Helyi: rejtett/vedett mappa; Szerver: kulonallo kotet |
| **Auto-torles** | 50 nap, nem kikapcsolhato, nem hosszabbitható |
| **Backup** | A kamera felvetelek NEM kerelnek a standard backupba |

### 5.2. Arfolyam keszito biztonsag

| Reteg | Megoldas |
|-------|---------|
| **Jogosultsag** | Csak HEAD_TREASURER / ADMIN role keszithet arfolyamot |
| **Jovahagyas** | Opcionalis masodik szem (4-szem elv) |
| **Visszavonhatosag** | Publikalt arfolyam visszavonhato (uj publikalas kell) |
| **Audit trail** | Minden modositas/publikalas naplozva |
| **Integritás** | Publikalt arfolyam NEM modosithato, csak uj keszitheto |
| **WebSocket auth** | JWT token a WS kapcsolathoz is |

### 5.3. Uj jogosultsagi role-ok

```java
// Meglevo RBAC kiterjesztese:
CASHIER         — Kamera: nincs hozzaferes (csak latja az elo kepet)
SUPERVISOR      — Kamera: lejatszas; Arfolyam: csak olvasas
MANAGER         — Kamera: lejatszas + export; Arfolyam: jovahagyas
HEAD_TREASURER  — Arfolyam: keszites + publikalas (uj role!)
ADMIN           — Minden
```

---

## 6. VEGREHAJTASI UTEMTERV

### Fazis 1: Kamera rendszer — Alap (3-4 het)
1. Adatbazis migracio (V51)
2. `CameraProperties` konfiguracio
3. `CameraRecordingService` — webcam-capture, frame grab, JPEG kodolas
4. Helyi fajl tarolas (titkositatlan elsokent, teszteleshez)
5. 1 oras szegmensek, fajl management
6. `CameraController` — elo MJPEG stream
7. Frontend: `CameraLivePage` — elo kamerakep

### Fazis 2: Kamera rendszer — Tarolas es biztonsag (2-3 het)
1. AES-256-GCM titkositas
2. Szerverre feltoltes mechanizmus
3. 50 napos auto-torles (scheduler)
4. Tranzakcio-felvetel linkeles
5. `CameraPlaybackPage` — visszajatszo
6. Audit log (camera_access_log)
7. Lemezhely figyelés, riasztasok

### Fazis 3: Arfolyam keszito — Alap (2-3 het)
1. Adatbazis migracio (V52)
2. Entity-k, repository-k, service-ek
3. `RateCreationController` — CRUD API
4. Munkacsoport kezeles
5. Frontend: `RateCreationDashboard` + `RateTemplateEditor`

### Fazis 4: Arfolyam keszito — Publikalas (2 het)
1. WebSocket konfiguracio (STOMP)
2. `RatePublishService` — publikalas + WebSocket broadcast
3. Penztaros oldali arfolyam-fogadas (frontend WS kliens)
4. Fallback polling mechanizmus
5. Kedvezmeny szintek
6. Publikalasi elozmények oldal

### Fazis 5: Integracio es teszteles (2 het)
1. End-to-end teszteles (kamera + tranzakcio linkeles)
2. Load teszt (tobb kamera parhuzamosan)
3. Halozat-kiesesi teszteles
4. 50 napos torles verifikacio
5. Biztonsagi audit (titkositas, hozzaferes, GDPR)
6. Felhasznaloi dokumentacio

### Osszesen: ~11-14 het

---

## MEGJEGYZESEK

1. **A webcam-capture konyvtar** (com.github.sarxos) Java-ban kezeli az USB webkamerakat, cross-platform, nincs szukseg nativ driver-re. Azonos konyvtar mint amit a legacy CameraOffice hasznalt.

2. **Miert NEM IP kamera / ONVIF?** A felhasznalo kifejezetten USB webkamerakat kert. Ez egyszerubb (nincs halozati kamera konfig), olcsobb, es a legacy rendszer is igy mukodott.

3. **Miert WebSocket az FTP helyett?** Azonnali arfolyam-frissites (nem kell 30mp-et varni), biztonsagosabb (HTTPS/WSS), nincs szukseg FTP szerverre.

4. **Miert kettos tarolas (helyi + szerver)?** A felhasznalo kifejezetten kerte, hogy mindket helyen 50 napig elerheto legyen. A helyi tarolas biztonsagi halo halozati problema eseten, a szerveres tarolas kozponti hozzaferest biztosit.

5. **INTEGER vs UUID company_id** — A meglevo rendszerben meg INTEGER a company_id. Az uj tablak UUID-t hasznalnak (branch_id). A company_id konverziot kulon migracioval kell megoldani.
