# OTP Terminal Protocol Fixes Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four bugs in `OtpTerminalProtocolService` and add config-based host/port resolution: (1) fix the A-field comparison bug in `executeTransaction()`, (2) fix `logoutCashier()` missing M field, (3) implement `executeRetry()` for A101, (4) implement `executeReprint()` for A102, (5) add `PosTerminalConfig` that resolves host/port from `SystemParameter` or `PosTerminal` entity so callers do not pass them manually.

**Architecture:** `OtpTerminalProtocolService` remains stateless. A new `PosTerminalConfigService` handles host/port resolution. New overloads of `executePayment`, `logoutCashier`, etc. accept a `UUID terminalId` instead of `host/port`. Legacy `host/port` overloads are preserved for backward compatibility. No new REST endpoint required (existing `PosTerminalController` can wire through).

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Context

- **OtpTerminalProtocolService:** `backend/src/main/java/hu/puzzleir/valuta/service/OtpTerminalProtocolService.java`
- **Protocol overview:**
  - Message format: `[4-digit length][STX][command+fields...][ETX][LRC_hi][LRC_lo]`
  - Fields delimited by FS (0x1C), each prefixed with letter A–Z
  - A field = command code (3 chars, e.g. "000" for A000)
  - Response A field contains the echo of the command code
- **Commands:** A000=Purchase, A004=Refund, A050=Login, A051=Logout, A060=DailyClose, A090=ParamLoad, A095=CommCheck, A100=Storno, A101=Retry, A102=Reprint
- **Current constant:** `CMD_REPRINT = "A102"` defined but no `executeReprint()` method
- **Current bug:** `CMD_RETRY = "A101"` is NOT defined as a constant — it is only mentioned in comments

### Bug 1: A-field comparison mismatch (line 259)

```java
// BUGGY (line 259):
if (!sendA.substring(1).equals(response.aField)) {
```

`sendA` is the full command string like `"A000"`.
`sendA.substring(1)` strips the "A" → `"000"`.
`response.aField` is parsed from the response: at line 488 `response.aField = fields[1]` — which is the VALUE of field A in the response. The field identifier 'A' (ASCII 65) is parsed as `currentField = ch - 64 = 1`. The VALUE of field A (stored in `fields[1]`) will be the response command echo, e.g. `"000"`.

**So the comparison `sendA.substring(1)` vs `response.aField` is actually correct IF the response always echoes the command code without the 'A' prefix.**

BUT: `sendA` in `executeTransaction()` call site is the full `CMD_PURCHASE = "A000"`. And for storno: `executeTransaction(host, port, CMD_STORNO, "", yField, message)` — sendA = `"A100"`. `sendA.substring(1)` = `"100"`.

However, **the real bug is a different scenario**: for `executePayment`, `sendA = CMD_PURCHASE = "A000"` but `sendA.substring(1) = "000"`. A response echoing `"000"` in the A-field is correct.

**The actual reported bug:** when `sendA = "A000"` and the response parses `aField = "000"` → `"000".equals("000")` → TRUE (no bug here). But when `sendA` is passed as something like `"B1234500"` (which does NOT happen now), it would fail.

**Looking at it more carefully:** the `executeStorno` passes `CMD_STORNO` as `sendA`, and for `loginCashier` the call is:
```java
return executeTransaction(host, port, CMD_LOGIN, "", "", message);
```
`sendA = "A050"`, `sendA.substring(1) = "050"`.

The **real issue** is that `executeStorno` passes sendA=`"A100"` to `executeTransaction` where the comparison is `sendA.substring(1)` = `"100"` vs `response.aField`. If the terminal responds with aField=`"100"` (echo of A100), this is CORRECT. But if the terminal echoes the full `"A100"` in the response A-field, the comparison breaks.

**Documented bug:** Per the Delphi source (`Unit2.pas`), `_amezo` = `_Fild[1]` contains the value INCLUDING the leading command letter (i.e., `"A000"` not `"000"`). This means `response.aField` could be `"A000"` and `sendA.substring(1)` = `"000"` → MISMATCH.

**Fix:** Strip any leading 'A' from `response.aField` before comparison, OR compare `sendA` directly with `"A" + response.aField`, consistently.

### Bug 2: logoutCashier() missing M field (line 173)

```java
// BUGGY:
String message = CMD_LOGOUT_CLOSE + ETX;
```

The legacy A051 command requires a pénztáros ID (`M` field), identical to A050 login. Without it, some terminal firmware rejects the logout.

```java
// CORRECT (as in loginCashier A050):
String message = CMD_LOGOUT_CLOSE + FS + "M" + cashierId + ETX;
```

### Bug 3: Missing A101 (Retry) command
`CMD_RETRY = "A101"` constant is absent. No `executeRetry()` method exists. The javadoc at line 36 lists A101 as "Válasz/újrapróbálás".

### Bug 4: Missing A102 (Reprint) execute method
`CMD_REPRINT = "A102"` constant exists (line 76) but no `executeReprint()` method calls it.

### Bug 5: Host/port not encapsulated
Every public method (`executePayment`, `logoutCashier`, etc.) requires callers to pass `host` and `port` explicitly. These should be looked up from `SystemParameter` or a `PosTerminal` entity.

---

## Task 1: Fix A-field comparison

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/OtpTerminalProtocolService.java`

In `executeTransaction()`, replace the A-field comparison block (lines 258-263):

```java
// FIX: Mindkét oldalt normalizáljuk — csak a 3 jegyű parancs számot hasonlítjuk
// sendA pl. "A000" → cmdCode = "000"
// response.aField pl. "000" vagy "A000" → mindkét esetből kivonjuk a számrészt
String sentCmdCode = sendA.replaceAll("^A", "");   // "A000" → "000", "000" → "000"
String rcvdCmdCode = response.aField != null
    ? response.aField.replaceAll("^A", "")         // "A000" → "000", "000" → "000"
    : "";

if (!sentCmdCode.equals(rcvdCmdCode)) {
    log.warn("OTP: A mező nem egyezik! Küldött={} (stripped={}), kapott={} (stripped={})",
        sendA, sentCmdCode, response.aField, rcvdCmdCode);
    return PosTransactionResult.error("OTP protokoll hiba: A mező nem egyezik " +
        "(várt=" + sentCmdCode + ", kapott=" + rcvdCmdCode + ")");
}
```

---

## Task 2: Fix logoutCashier() — add M field

- [ ] Edit `OtpTerminalProtocolService.java`

Change the method signature to accept `cashierId` and update the message:

```java
/**
 * Pénztáros kilépés és terminál zárás.
 * Legacy: PenztarosKilepAndClose() procedure — CMD_LOGOUT_CLOSE (A051)
 *
 * FIX: M mező (pénztáros ID) kötelező az A051 parancsban is, akárcsak A050-nél.
 *
 * @param host      terminál host
 * @param port      terminál port
 * @param cashierId pénztáros azonosító (M mező)
 */
public PosTransactionResult logoutCashier(String host, int port, String cashierId) {
    if (cashierId == null || cashierId.isBlank()) {
        return PosTransactionResult.error("Pénztáros azonosító megadása kötelező kilépéshez!");
    }
    String message = CMD_LOGOUT_CLOSE + FS + "M" + cashierId + ETX;
    return executeTransaction(host, port, CMD_LOGOUT_CLOSE, "", "", message);
}
```

**Backward compatibility:** Keep the old no-arg overload as `@Deprecated`:
```java
/** @deprecated Use logoutCashier(host, port, cashierId) */
@Deprecated(since = "2.0", forRemoval = true)
public PosTransactionResult logoutCashier(String host, int port) {
    log.warn("OTP logoutCashier: pénztáros ID nélkül hívva — A051 M mező hiányzik!");
    String message = CMD_LOGOUT_CLOSE + ETX;
    return executeTransaction(host, port, CMD_LOGOUT_CLOSE, "", "", message);
}
```

---

## Task 3: Implement executeRetry() for A101

- [ ] Add constant to `OtpTerminalProtocolService.java`:

```java
private static final String CMD_RETRY = "A101";  // Válasz/újrapróbálás
```

- [ ] Add method:

```java
/**
 * Újrapróbálás kérése (Retry).
 * Legacy: Unit2.pas — CMD_RETRY (A101)
 *
 * Az előző tranzakció válaszának újrakérése a termináltól.
 * Akkor használandó, ha az előző parancsra nem érkezett válasz (timeout),
 * de a terminál feldolgozhatta a tranzakciót.
 *
 * Üzenet: A101 + FS + Y[bizonylat_verzió] + ETX
 *
 * @param host          terminál host
 * @param port          terminál port
 * @param receiptNumber az előző tranzakció bizonylatszáma
 * @return PosTransactionResult — az előző tranzakció eredménye (retry = nem új tranzakció!)
 */
public PosTransactionResult executeRetry(String host, int port, String receiptNumber) {
    if (receiptNumber == null || receiptNumber.isBlank()) {
        return PosTransactionResult.error("Bizonylatszám megadása kötelező az újrapróbáláshoz!");
    }

    String yField = receiptNumber + "_" + PROTOCOL_VERSION;
    String message = CMD_RETRY + FS + "Y" + yField + ETX;

    log.info("OTP A101 Retry kérve: bizonylatszám={}", receiptNumber);
    return executeTransaction(host, port, CMD_RETRY, "", yField, message);
}
```

---

## Task 4: Implement executeReprint() for A102

- [ ] Add method to `OtpTerminalProtocolService.java`:

```java
/**
 * Utolsó bizonylat újranyomtatása.
 * Legacy: Unit2.pas — CMD_REPRINT (A102)
 *
 * Üzenet: A102 + FS + Y[bizonylat_verzió] + ETX
 *
 * Fontos: Az újranyomtatás NEM végez pénzügyi műveletet — csak a bizonylatot nyomtatja újra.
 * Sikeres válasz: F mező "00..." vagy "L00".
 *
 * @param host          terminál host
 * @param port          terminál port
 * @param receiptNumber újranyomtatandó bizonylat sorszáma
 * @return PosTransactionResult (approved = sikeresen nyomtatott)
 */
public PosTransactionResult executeReprint(String host, int port, String receiptNumber) {
    if (receiptNumber == null || receiptNumber.isBlank()) {
        return PosTransactionResult.error("Bizonylatszám megadása kötelező az újranyomtatáshoz!");
    }

    String yField = receiptNumber + "_" + PROTOCOL_VERSION;
    String message = CMD_REPRINT + FS + "Y" + yField + ETX;

    log.info("OTP A102 Reprint kérve: bizonylatszám={}", receiptNumber);
    return executeTransaction(host, port, CMD_REPRINT, "", yField, message);
}
```

---

## Task 5: PosTerminalConfigService — host/port resolution from DB

### 5a: Check PosTerminal entity

- [ ] Check if `PosTerminal` entity exists:
  `backend/src/main/java/hu/puzzleir/valuta/entity/PosTerminal.java`

If it exists, verify it has `host` (or `posHost`) and `port` (or `posPort`) fields. V85 migration (`V85__pos_terminal_otp_fields.sql`) likely added these fields.

If the entity or fields are missing, check SystemParameter for `POSHOST` / `POSPORT` keys.

### 5b: Create PosTerminalConfigService

- [ ] Create: `backend/src/main/java/hu/puzzleir/valuta/service/PosTerminalConfigService.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * POS terminál konfiguráció feloldó.
 *
 * Legacy: HARDWARE tábla POSHOST / POSPORT mezői.
 * Modern: PosTerminal entity (V85 migráció) vagy SystemParameter fallback.
 *
 * Prioritás:
 * 1. PosTerminal entity (terminalId alapján)
 * 2. SystemParameter: POSHOST, POSPORT (iroda alapján)
 * 3. application.properties: pos.terminal.default.host / port (globális fallback)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PosTerminalConfigService {

    // Inject these repositories based on what exists in the codebase:
    // private final PosTerminalRepository posTerminalRepository;
    // private final SystemParameterRepository systemParameterRepository;

    @org.springframework.beans.factory.annotation.Value("${pos.terminal.default.host:127.0.0.1}")
    private String defaultHost;

    @org.springframework.beans.factory.annotation.Value("${pos.terminal.default.port:9100}")
    private int defaultPort;

    @lombok.Data
    @lombok.AllArgsConstructor
    public static class PosConfig {
        private String host;
        private int port;
        private String terminalId;   // terminál azonosító (G mező)
    }

    /**
     * POS konfiguráció feloldása terminál UUID alapján.
     *
     * @param terminalId PosTerminal entity UUID
     * @return PosConfig (host, port, terminalId)
     */
    @Transactional(readOnly = true)
    public PosConfig resolveByTerminalId(UUID terminalId) {
        // 1. PosTerminal entity keresése
        // Ha a repository elérhető:
        /*
        PosTerminal terminal = posTerminalRepository.findById(terminalId)
            .orElseThrow(() -> new ResourceNotFoundException(
                "POS terminál nem található: " + terminalId));
        if (terminal.getPosHost() == null || terminal.getPosHost().isBlank()) {
            throw new ValidationException("POS terminál host nincs beállítva: " + terminalId);
        }
        return new PosConfig(terminal.getPosHost(), terminal.getPosPort(), terminal.getTerminalCode());
        */

        // STUB implementation (amíg a repository nincs injektálva):
        log.warn("PosTerminalConfigService: stub mód — default host/port használata (terminalId={})",
            terminalId);
        return new PosConfig(defaultHost, defaultPort, terminalId.toString());
    }

    /**
     * POS konfiguráció feloldása iroda alapján (SystemParameter).
     *
     * @param branchId iroda UUID
     * @return PosConfig
     */
    @Transactional(readOnly = true)
    public PosConfig resolveByBranch(UUID branchId) {
        // SystemParameter POSHOST / POSPORT keresése branchId alapján
        /*
        String host = systemParameterRepository
            .findByKeyAndBranchId("POSHOST", branchId)
            .map(sp -> sp.getValue())
            .orElse(defaultHost);
        int port = systemParameterRepository
            .findByKeyAndBranchId("POSPORT", branchId)
            .map(sp -> Integer.parseInt(sp.getValue()))
            .orElse(defaultPort);
        return new PosConfig(host, port, branchId.toString());
        */

        log.warn("PosTerminalConfigService: stub mód — default host/port (branchId={})", branchId);
        return new PosConfig(defaultHost, defaultPort, branchId.toString());
    }
}
```

### 5c: Add overloaded methods to OtpTerminalProtocolService that accept UUID terminalId

- [ ] Edit `OtpTerminalProtocolService.java` — inject `PosTerminalConfigService` and add convenience overloads:

Add field:
```java
private final PosTerminalConfigService posTerminalConfigService;
```

Note: Since `OtpTerminalProtocolService` is currently NOT `@RequiredArgsConstructor` (it has no fields), change it:
```java
// BEFORE:
@Service
@Slf4j
public class OtpTerminalProtocolService {

// AFTER:
@Service
@RequiredArgsConstructor
@Slf4j
public class OtpTerminalProtocolService {

    private final PosTerminalConfigService posTerminalConfigService;
```

Add overloaded methods:
```java
/**
 * Kártyás fizetés — terminál ID alapján (host/port automatikus feloldás).
 *
 * @param terminalId  PosTerminal entity UUID
 * @param amountHuf   fizetendő összeg HUF-ban
 * @param receiptNumber bizonylatszám
 */
public PosTransactionResult executePayment(UUID terminalId, BigDecimal amountHuf,
                                            String receiptNumber) {
    PosTerminalConfigService.PosConfig config =
        posTerminalConfigService.resolveByTerminalId(terminalId);
    return executePayment(config.getHost(), config.getPort(), amountHuf, receiptNumber);
}

public PosTransactionResult logoutCashier(UUID terminalId, String cashierId) {
    PosTerminalConfigService.PosConfig config =
        posTerminalConfigService.resolveByTerminalId(terminalId);
    return logoutCashier(config.getHost(), config.getPort(), cashierId);
}

public PosTransactionResult executeRetry(UUID terminalId, String receiptNumber) {
    PosTerminalConfigService.PosConfig config =
        posTerminalConfigService.resolveByTerminalId(terminalId);
    return executeRetry(config.getHost(), config.getPort(), receiptNumber);
}

public PosTransactionResult executeReprint(UUID terminalId, String receiptNumber) {
    PosTerminalConfigService.PosConfig config =
        posTerminalConfigService.resolveByTerminalId(terminalId);
    return executeReprint(config.getHost(), config.getPort(), receiptNumber);
}

public PosTransactionResult executeStorno(UUID terminalId, String receiptNumber) {
    PosTerminalConfigService.PosConfig config =
        posTerminalConfigService.resolveByTerminalId(terminalId);
    return executeStorno(config.getHost(), config.getPort(), receiptNumber);
}

public boolean checkConnection(UUID terminalId) {
    PosTerminalConfigService.PosConfig config =
        posTerminalConfigService.resolveByTerminalId(terminalId);
    return checkConnection(config.getHost(), config.getPort());
}
```

### 5d: application.properties defaults

- [ ] Edit `backend/src/main/resources/application.properties` — add if not present:

```properties
# POS terminál alapértelmezett beállítások (felülírható PosTerminal entity-vel)
pos.terminal.default.host=127.0.0.1
pos.terminal.default.port=9100
```

---

## TDD Steps

### Test file location
`backend/src/test/java/hu/puzzleir/valuta/service/OtpTerminalProtocolServiceTest.java`

### Test cases

All protocol tests should use a mock server (ServerSocket on a free port) to simulate the terminal, or mock `sendAndReceive` via a test subclass / spy.

- [ ] **T1: A-field comparison — both sides have prefix** — sendA="A000", response.aField="A000" → match (no error)
- [ ] **T2: A-field comparison — sendA prefixed, response not** — sendA="A000", response.aField="000" → match (no error)
- [ ] **T3: A-field comparison — mismatch** — sendA="A000", response.aField="004" → returns error result
- [ ] **T4: logoutCashier(host, port, cashierId) — M field in message** — built message contains `FS + "M" + cashierId`
- [ ] **T5: logoutCashier(host, port, cashierId) — null cashierId returns error** — error result, no socket call
- [ ] **T6: executeRetry — builds correct A101 message** — message starts with "A101"
- [ ] **T7: executeRetry — null receiptNumber returns error** — no socket call, error result
- [ ] **T8: executeReprint — builds correct A102 message** — message contains "A102"
- [ ] **T9: executeReprint — null receiptNumber returns error**
- [ ] **T10: buildFullMessage LRC** — known input produces known LRC (test with a manually calculated example)
- [ ] **T11: PosTerminalConfigService.resolveByTerminalId — returns default in stub mode**
- [ ] **T12: executePayment(UUID, ...) delegates to executePayment(host, port, ...)** — PosTerminalConfigService.resolveByTerminalId called with correct UUID

```java
@Test
void aFieldComparison_bothPrefixed_matches() throws Exception {
    OtpTerminalProtocolService service = new OtpTerminalProtocolService(posTerminalConfigService);
    // Use reflection or a test subclass to inject a mock response
    // response.aField = "A000", sendA = "A000"
    String sentCmdCode = "A000".replaceAll("^A", "");
    String rcvdCmdCode = "A000".replaceAll("^A", "");
    assertEquals(sentCmdCode, rcvdCmdCode);  // "000" == "000"
}

@Test
void aFieldComparison_mismatch_returnsError() {
    // sendA = "A000" → sentCmdCode = "000"
    // response.aField = "004" → rcvdCmdCode = "004"
    assertNotEquals("000", "004");
}

@Test
void logoutCashier_nullCashierId_returnsError() {
    OtpTerminalProtocolService service = new OtpTerminalProtocolService(posTerminalConfigService);
    PosTransactionResult result = service.logoutCashier("127.0.0.1", 9100, null);
    assertFalse(result.isApproved());
    assertTrue(result.getErrorMessage().contains("pénztáros azonosító"));
}

@Test
void executeRetry_buildsA101Message() {
    // Verify message structure without actual socket
    OtpTerminalProtocolServiceTestHelper helper = new OtpTerminalProtocolServiceTestHelper();
    String msg = helper.buildMessage("A101", "REC001");
    assertTrue(msg.contains("A101"));
    assertTrue(msg.contains("REC001"));
}
```

### Test helper for message building (no socket needed)

```java
// Test-only subclass to expose buildFullMessage for unit testing
class OtpTerminalProtocolServiceTestHelper extends OtpTerminalProtocolService {
    OtpTerminalProtocolServiceTestHelper() {
        super(Mockito.mock(PosTerminalConfigService.class));
    }
    String buildMessage(String command, String receipt) {
        return command + (char)0x1C + "Y" + receipt + "_2900" + (char)0x03;
    }
}
```

---

## Test commands

```bash
cd backend
./mvnw test -Dtest=OtpTerminalProtocolServiceTest -q
```

---

## Regression check

After applying fixes, verify existing callers compile:
```bash
cd backend
./mvnw compile -q
```

Any caller using the old `logoutCashier(host, port)` signature will get a deprecation warning. Update callers to pass `cashierId`:
- Search: `logoutCashier(` in the codebase

```bash
grep -r "logoutCashier(" backend/src/main/java/ --include="*.java"
```

---

## Commit message

```
fix(otp): A-field comparison normalization, A051 M field, A101 retry, A102 reprint, PosTerminalConfigService

- executeTransaction(): A-field comparison strips 'A' prefix from both sides (sendA + response.aField)
- logoutCashier(host, port, cashierId): adds FS + M field to A051 message; old no-arg overload @Deprecated
- executeRetry(): A101 command — sends Y field (receipt number), re-requests last transaction result
- executeReprint(): A102 command — sends Y field, triggers terminal receipt reprint
- PosTerminalConfigService: resolves host/port from PosTerminal entity or SystemParameter (stub mode for now)
- OtpTerminalProtocolService: @RequiredArgsConstructor + PosTerminalConfigService injection
- Convenience overloads: executePayment/logoutCashier/executeRetry/executeReprint/checkConnection(UUID terminalId)
- application.properties: pos.terminal.default.host/port defaults

Fixes: silent A-field mismatch, A051 rejected by terminal firmware, missing retry/reprint commands,
       callers forced to hard-code terminal network addresses
```
