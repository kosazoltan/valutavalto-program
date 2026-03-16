# VALUTA Legacy Migráció — Hiányzó Modulok Design Spec

## Cél

A legacy Delphi VALUTA rendszer (~80 DLL modul) 1:1 migrációjának befejezése. A meglévő Spring Boot backend 90%-ban kész — ez a spec a 4 azonosított hiányzó modult fedi le, hogy a rendszer teljesen működőképes legyen.

## Architektúra

A meglévő Spring Boot 3.2 + Java 21 architektúrát követjük. Minden új service a `hu.puzzleir.valuta.service` package-be kerül, a meglévő entity-ket és repository-kat felhasználva ahol lehetséges. Új Flyway migrációk a hiányzó táblákhoz.

## Tech Stack

- Java 21, Spring Boot 3.2, Spring Data JPA, PostgreSQL
- jSerialComm 2.10+ (COM port kommunikáció a LED kijelzőkhöz)
- Apache PDFBox 3.0+ (PDF bizonylat generálás — Apache License 2.0, nem AGPL mint iText)
- Meglévő: Apache POI, MapStruct, Lombok

## Multi-tenant szabály

**Minden** service és query companyId-ra szűr a `SecurityUtils.getCurrentCompanyId()` segítségével. Ha egy meglévő entity-ből (pl. WuTransaction, WuBalance, WuCustomer) hiányzik a `company_id` oszlop, a Flyway migráció hozzáadja.

---

## Modul 1: WuTransactionService (Western Union)

### Kontextus

A `WuTransaction` entity, `WuTransactionRepository`, `WuBalance` entity, `WuCustomer` entity és a `WuTransactionStatus` enum már létezik (V91 migráció). A service réteg teljesen hiányzik — nincs üzleti logika a WU tranzakciók feldolgozásához.

Legacy forrás: `Anti/VALUTA/DLL/WUNION/MAKEDLL/Unit2.pas`

### Felelősség

WU pénzküldési és fogadási tranzakciók teljes életciklus-kezelése.

### API

```java
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class WuTransactionService {

    // --- Send Money ---
    public WuTransactionResponse sendMoney(WuSendRequest request);

    // --- Receive Money ---
    public WuTransactionResponse receiveMoney(WuReceiveRequest request);

    // --- Cancel/Reverse ---
    public WuTransactionResponse cancelTransaction(UUID transactionId, String reason);

    // --- Query ---
    public WuTransactionResponse getTransaction(UUID transactionId);
    public List<WuTransactionResponse> listByBranch(UUID branchId, LocalDate date);
    public WuBalanceSummary getBalance(UUID branchId);

    // --- Daily closing support ---
    public WuDailyClosingSummary getDailyClosingSummary(UUID branchId, LocalDate date);
}
```

### Üzleti szabályok (legacy 1:1)

**Fontos:** A WU modul kizárólag USD denominációban működik. Más valutanem nem támogatott. A meglévő entity-ben lévő egyéb típusok (IC_IN, IC_OUT, CUSTOMER_IN, CUSTOMER_OUT) a legacy rendszer belső típusai — az új service SEND, RECEIVE és STORNO típusokat kezel.

1. **Send Money flow:**
   - Ügyfél azonosítás (SanctionScreeningService hívás — kötelező)
   - WU bizonylat szám generálás (ReceiptSequenceService, "W" prefix)
   - Összeg validálás: USD/HUF, árfolyam alkalmazás ExchangeRateService-ből
   - Díj kalkuláció: WU díjtáblázat alapján (összeg-sávos)
   - WuBalance frissítés pessimistic lock-kal (`@Lock(PESSIMISTIC_WRITE)`): USD balance csökkentés, HUF balance növelés
   - Transaction record létrehozás (PENDING → COMPLETED)
   - AuditLog bejegyzés

2. **Receive Money flow:**
   - MTCN (Money Transfer Control Number) validálás (10 számjegy)
   - Ügyfél azonosítás + szankciós szűrés
   - Kifizetés: HUF összeg számítás (USD × árfolyam), 5 Ft kerekítés
   - WuBalance frissítés pessimistic lock-kal: USD balance növelés, HUF balance csökkentés
   - Transaction record (PENDING → COMPLETED)

3. **Cancel flow:**
   - Csak COMPLETED státuszú tranzakció vonható vissza
   - WuBalance visszaállítás (ellentétes előjellel, pessimistic lock)
   - Status: COMPLETED → REVERSED
   - Eredeti tranzakcióhoz linkelt reversal record

4. **Compliance:**
   - Napi limit: $10,000 per ügyfél (AML)
   - SanctionScreeningService kötelező hívás minden tranzakció előtt
   - Audit trail minden lépésnél

### REST Controller

```java
@RestController
@RequestMapping("/api/v1/wu-transactions")
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'ADMIN')")
public class WuTransactionController {

    POST /send                      // Send money
    POST /receive                   // Receive money
    POST /{id}/cancel               // Cancel transaction
    GET  /{id}                      // Get transaction details
    GET  /branch/{branchId}         // List by branch + date
    GET  /balance/{branchId}        // WU balance summary
    GET  /daily-closing/{branchId}  // Daily closing summary
}
```

### Flyway migráció (V96)

```sql
-- company_id hozzáadása a WU táblákhoz (multi-tenant)
ALTER TABLE wu_transaction ADD COLUMN company_id UUID REFERENCES company(id);
ALTER TABLE wu_balance ADD COLUMN company_id UUID REFERENCES company(id);
ALTER TABLE wu_customer ADD COLUMN company_id UUID REFERENCES company(id);

-- WuBalance pessimistic lock query-hez index
CREATE INDEX idx_wu_balance_branch_company ON wu_balance(branch_id, company_id);
```

### Függőségek

- `WuTransactionRepository` (létezik)
- `WuBalanceRepository` (létezik)
- `ExchangeRateService` (létezik, FULL)
- `SanctionScreeningService` (létezik, FULL)
- `ReceiptSequenceService` (létezik, FULL)
- `AuditLogService` (létezik)
- `SecurityUtils` (létezik)

### Tesztelés

- Unit tesztek: send/receive/cancel happy path + edge cases
- AML limit túllépés
- Dupla cancel prevention
- WuBalance konzisztencia

---

## Modul 2: ReceiptService (Bizonylat nyomtatás)

### Kontextus

A jelenlegi `ReceiptService` egy 39 soros stub — csak CRUD műveletek (`list()`, `getById()`, `print()`), nincs nyomtatási/formázási logika. A `ReceiptSequenceService` (szekvencia generálás) viszont teljesen kész.

Legacy forrás: `Anti/VALUTA/DLL/BLOKNYOM/MAKEDLL/Unit2.pas`

### Felelősség

Bizonylatok formázása, PDF generálása és nyomtatási audit trail kezelése. A meglévő `list()`, `getById()` és `print()` metódusok megmaradnak — az új metódusok bővítések.

### API

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptService {

    // --- Generate receipt content ---
    public ReceiptContent generateReceipt(UUID transactionId);
    public ReceiptContent generateTransferReceipt(UUID transferId);
    public ReceiptContent generateWuReceipt(UUID wuTransactionId);
    public ReceiptContent generateStornoReceipt(UUID transactionId);
    public ReceiptContent generateDenominationReceipt(UUID denominationId);

    // --- PDF output ---
    public byte[] generatePdf(UUID transactionId);

    // --- Print tracking ---
    public void recordPrint(UUID receiptId, String printerName, UUID workerId);
    public boolean isCopy(UUID receiptId);  // true ha már nyomtatták
    public List<ReceiptPrintAudit> getPrintHistory(UUID receiptId);

    // --- Reprint ---
    public byte[] reprint(UUID receiptId);  // "MÁSOLAT" jelöléssel
}
```

### Bizonylat típusok (legacy 1:1)

| Típus | Prefix | Tartalom |
|-------|--------|----------|
| Vételi blokk | V | Valuta vásárlás részletei |
| Eladási blokk | E | Valuta eladás részletei |
| Átadási blokk | F | Kimenő transfer |
| Átvételi blokk | U | Bejövő transfer |
| Sztornó blokk | S | Visszavonás részletei |
| Árfolyam módosítás | — | Árfolyam változás dokumentáció |
| Címlet blokk | — | Címletezés eredménye |
| WU blokk | W | Western Union tranzakció |

### Bizonylat formátum

```
[CÉG NÉV - központosított]
[IRODA NÉV - központosított]
[CÍM - központosított]
─────────────────────────────
Bizonylat: V0101-000042
Dátum: 2026.03.16  Idő: 14:32
Pénztáros: Kovács Anna
─────────────────────────────
Valutanem    Mennyiség    Árfolyam    Ft érték
EUR          500.00       405,32      202 660
USD          200.00       375,20       75 040
─────────────────────────────
Összesen:                             277 700 Ft
Kezelési díj:                              0 Ft
Fizetendő:                            277 700 Ft
─────────────────────────────
[QR kód - NAV nyugtaszám]
[Aláírási vonal]
```

### Függőségek

- `TransactionRepository` (létezik)
- `TransferRepository` (létezik)
- `WuTransactionRepository` (létezik)
- `BranchRepository` (létezik)
- `CompanyRepository` (létezik)
- `ReceiptSequenceService` (létezik, FULL)
- Apache PDFBox 3.0+ (PDF generálás — Apache License 2.0)

### Tesztelés

- Unit tesztek: minden bizonylat típus generálás
- PDF output validálás (méret, nem üres)
- Másolat jelölés
- Print audit trail

---

## Modul 3: SealTrackingService (Plomba/pecsét nyomkövetés)

### Kontextus

A `TransferService` (278 sor) működik: branch-to-branch transfer, státusz flow, CashBalance frissítés pessimistic lock-kal. A plomba/pecsét nyomkövetés hiányzik.

Legacy forrás: `Anti/VALUTA/DLL/ATADVET/MAKEDLL/Unit2.pas` (plomba részek)

### Felelősség

Fizikai szállítmányok pecsét-alapú nyomkövetése a transfer flow-ban.

### Adatmodell

```sql
-- V97 migráció
CREATE TABLE seal_tracking (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL REFERENCES company(id),
    transfer_type   VARCHAR(20) NOT NULL,  -- 'VAULT_TRANSFER' vagy 'TRANSFER'
    transfer_id     BIGINT NOT NULL,       -- polimorf FK (vault_transfer.id VAGY transfer.id)
    seal_number     VARCHAR(50) NOT NULL UNIQUE,
    sealed_at       TIMESTAMP NOT NULL,
    sealed_by       BIGINT NOT NULL REFERENCES worker(id),
    opened_at       TIMESTAMP,
    opened_by       BIGINT,
    transit_status  VARCHAR(20) NOT NULL DEFAULT 'SEALED',
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

CREATE INDEX idx_seal_tracking_transfer ON seal_tracking(transfer_type, transfer_id);
CREATE INDEX idx_seal_tracking_number ON seal_tracking(seal_number);
CREATE INDEX idx_seal_tracking_company ON seal_tracking(company_id);
```

**Megjegyzés:** A `transfer_id` polimorf FK — `transfer_type` határozza meg, hogy `vault_transfer` (BIGINT id) vagy `transfer` (UUID→BIGINT mapping) táblára vonatkozik. Ez lehetővé teszi, hogy mindkét transfer típusnál használható legyen a plomba tracking.

### API

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class SealTrackingService {

    // --- Seal lifecycle ---
    public SealRecord seal(Long transferId, String sealNumber);
    public SealRecord startTransit(Long transferId);
    public SealRecord confirmArrival(Long transferId, Long openedByWorkerId);

    // --- Query ---
    public Optional<SealRecord> getBySealNumber(String sealNumber);
    public Optional<SealRecord> getByTransferId(Long transferId);
    public List<SealRecord> getInTransit();

    // --- Validation ---
    public boolean validateSealIntegrity(Long transferId, String expectedSealNumber);
}
```

### Státusz flow

```
SEALED → IN_TRANSIT → ARRIVED → OPENED
```

### Integráció

A meglévő `TransferService` és `VaultTransferService` opcionálisan hívja a `SealTrackingService`-t:
- `initiateTransfer()` után → `seal()` ha fizikai szállítmány
- `completeTransfer()` előtt → `confirmArrival()` + `validateSealIntegrity()`

Minden lifecycle eseménynél `AuditLogService.log()` hívás (plomba felnyitása/zárása pénzügyi biztonsági esemény).

### Tesztelés

- Unit tesztek: teljes lifecycle
- Seal number uniqueness
- Integritás validálás (rossz seal number)
- IN_TRANSIT lekérdezés
- Multi-tenant szűrés (companyId)

---

## Modul 4: LedDisplayService (Fényújság / LED kijelző)

### Kontextus

A legacy rendszerben 15+ külön DLL variáns kezelte az iroda-specifikus LED kijelzőket (ALAP, BAJCSY, BCSABA, DIANA, FERENCES, SZOBOSZLO, SPEC8085, IRGALMAS, OROS, DUPLACOM, DUPOTHER, NOSPEED, UJTIPUS, DOMBOVAR, MAKEDLL). A modern rendszerben egyetlen konfigurálható service váltja ki az összeset.

Legacy forrás: `Anti/VALUTA/DLL/FNYUJSAG/*/MAKEDLL/Unit2.pas` (15+ variáns)

### Felelősség

LED árfolyam-kijelző táblák vezérlése soros COM porton keresztül, per-branch konfigurációval.

### Soros protokoll (byte-szintű, 1:1 legacy)

```
Inicializálás:  [21, 18, 5]
Sebesség (opt): [92('\\'), 70('F'), 83('S'), 48+speed]
Adat:           ASCII karakterek (árfolyam sorok vagy szöveg)
Végjelzés:      [254] vagy [254, 255]
```

Minden variáns: **9600 baud, 8 data bits, 1 stop bit, no parity**

### Adatmodell

```sql
-- V98 migráció
CREATE TABLE led_display_config (
    id                  BIGSERIAL PRIMARY KEY,
    branch_id           UUID NOT NULL REFERENCES branch(id),
    display_type        VARCHAR(30) NOT NULL DEFAULT 'STANDARD',
    com_ports           VARCHAR(100) NOT NULL DEFAULT 'COM1',
    currencies          VARCHAR(200) NOT NULL DEFAULT 'EUR,USD,GBP,CHF',
    show_bank_card      BOOLEAN NOT NULL DEFAULT false,
    speed_command        BOOLEAN NOT NULL DEFAULT true,
    speed               INTEGER NOT NULL DEFAULT 5,
    end_markers         VARCHAR(20) NOT NULL DEFAULT '254',
    decimal_separator   CHAR(1) NOT NULL DEFAULT ',',
    custom_text         TEXT,
    display_ids         VARCHAR(50),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP
);

CREATE UNIQUE INDEX idx_led_display_branch ON led_display_config(branch_id);
```

### Display típusok

```java
public enum LedDisplayType {
    STANDARD,      // EUR/USD/GBP/CHF (ALAP, MAKEDLL, IRGALMAS)
    CENTRAL_EU,    // EUR/USD/CZK/PLN (FERENCES, SZOBOSZLO)
    EXTENDED,      // 14+ valuta (NOSPEED)
    TEXT_ONLY,     // Marketing szöveg (BCSABA, OROS, SPEC8085)
    MIXED,         // Árfolyam + szöveg (UJTIPUS — LEZARTNAP alapján vált)
    DUAL_SAME,     // 2 kijelző, azonos tartalom (DUPLACOM)
    DUAL_DIFF      // 2 kijelző, eltérő tartalom (DUPOTHER — árfolyam + "CHANGE - WESTERN UNION")
}
```

### API

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class LedDisplayService {

    // --- Refresh ---
    public void refreshDisplay(UUID branchId);
    public void refreshAllActive();

    // --- Config ---
    public LedDisplayConfigDto getConfig(UUID branchId);
    public LedDisplayConfigDto updateConfig(UUID branchId, LedDisplayConfigDto config);

    // --- Status ---
    public LedDisplayStatus getStatus(UUID branchId);
    public List<LedDisplayStatus> getAllStatuses();

    // --- Manual text ---
    public void sendCustomText(UUID branchId, String text);
}
```

### Belső komponensek

```java
// COM port kommunikáció
public class LedSerialPortDriver {
    public void open(String portName);
    public void send(byte[] data);
    public void close();
}

// Byte-szintű protokoll kódolás
public class LedProtocolEncoder {
    public byte[] encode(LedDisplayConfig config, List<ExchangeRateDto> rates);
    public byte[] encodeText(LedDisplayConfig config, String text);

    // Legacy formázás 1:1
    String formatRate(BigDecimal rate, String decimalSeparator);
    // "405.32" → "405,32" (magyar) vagy "405.32" (BAJCSY)
}
```

### Árfolyam formázás (legacy 1:1)

```java
// 3 egész + tizedesjel + 2 tizedes = 6 karakter
// Példa: 405,32 (EUR vételi)
// JPY speciális: 10× szorzó → "3,752" (nem "375,20")
String formatRate(BigDecimal rate, String decimalSeparator) {
    String s = rate.setScale(2, RoundingMode.HALF_UP).toPlainString();
    // leftstr(s,3) + decimalSeparator + midstr(s,4,2)
}
```

### Integráció

- `ExchangeRateService` — árfolyamok lekérése
- `@EventListener(ExchangeRateUpdatedEvent.class)` — automatikus frissítés árfolyam változáskor
- `@Scheduled(fixedRate = 60000)` — fallback percenkénti frissítés
- `BranchRepository` — per-branch konfig

### REST Controller

```java
@RestController
@RequestMapping("/api/v1/led-display")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
public class LedDisplayController {

    POST /refresh/{branchId}        // Manuális frissítés
    POST /refresh-all               // Összes aktív kijelző frissítés
    GET  /config/{branchId}         // Konfig lekérdezés
    PUT  /config/{branchId}         // Konfig módosítás
    GET  /status/{branchId}         // Kijelző állapot
    GET  /status                    // Összes kijelző állapot
    POST /text/{branchId}           // Egyedi szöveg küldés
}
```

### Tech

- **jSerialComm 2.10+** — Pure Java soros port library (Maven: `com.fazecast:jSerialComm:2.10.4`)
- Nincs JNI/native dependency, Windows/Linux/Mac támogatás
- Thread-safe port kezelés

### Tesztelés

- Unit tesztek: protokoll kódolás minden display típusra
- Árfolyam formázás (magyar vessző, BAJCSY pont, JPY speciális)
- Byte buffer validálás (init + speed + data + end marker)
- Config CRUD
- Mock serial port (teszteléskor nem kell fizikai kijelző)

---

## Összesítés

| Modul | Új fájlok | Flyway | Becsült sorok |
|-------|-----------|--------|---------------|
| WuTransactionService | 3 (service + DTO-k + controller) | — | ~450 |
| ReceiptService | 3 (service + template + controller update) | — | ~300 |
| SealTrackingService | 3 (entity + repo + service) | V96 | ~200 |
| LedDisplayService | 6 (service + driver + encoder + entity + repo + controller) | V98 | ~500 |
| **Összesen** | **~15 fájl** | **2 migráció** | **~1450 sor + tesztek** |

## Nem implementálandó (YAGNI)

- TRADE modul (PaySafeCard, e-matrica, mobilfeltöltés) — elavult üzleti funkció
- GEPSETUP (hardver konfig) — webes admin felületen kezelt
- COPY2FTP — REST API váltja ki
- VERZFRIS — CI/CD pipeline kezeli
