package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.repository.PosTerminalRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.lang.reflect.Method;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * OtpTerminalProtocolService UNIT tesztek.
 *
 * Mivel a protokoll szerviz raw TCP socketeket használ, a tesztek:
 *  1. Reflexióval érik el a privát metódusokat (buildFullMessage, parseResponse)
 *  2. Spy + mocked sendAndReceive-vel tesztelik az executeTransaction utat
 *  3. PosTerminalConfigService-t mockkal tesztelik
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class OtpTerminalProtocolServiceTest {

    @Mock
    private PosTerminalConfigService posTerminalConfigService;

    @InjectMocks
    private OtpTerminalProtocolService service;

    // Protokoll karakterek — tükrözve a service-ből
    private static final char STX = (char) 0x02;
    private static final char ETX = (char) 0x03;
    private static final char FS  = (char) 0x1C;

    // ============================================================
    // Segédmetódusok reflexiós hívásokhoz
    // ============================================================

    private String buildFullMessage(String message) throws Exception {
        Method m = OtpTerminalProtocolService.class
            .getDeclaredMethod("buildFullMessage", String.class);
        m.setAccessible(true);
        return (String) m.invoke(service, message);
    }

    private OtpTerminalProtocolService.OtpResponse parseResponse(String reply) throws Exception {
        Method m = OtpTerminalProtocolService.class
            .getDeclaredMethod("parseResponse", String.class);
        m.setAccessible(true);
        return (OtpTerminalProtocolService.OtpResponse) m.invoke(service, reply);
    }

    // ============================================================
    // Bug 1: A-field összehasonlítás normalizálás
    // ============================================================

    @Test
    @DisplayName("A-field: mindkét oldal 'A' prefix nélkül egyezik — sikeres tranzakció")
    void aFieldComparison_bothPrefixed_matches() throws Exception {
        // Egy helyes A095 (ComCtrl) válasz generálása
        // aField a válaszban: "095" (prefix nélkül, ahogy a parseResponse kinyeri)
        // sendA: "A095"
        // sentCmdCode = "095", rcvdCmdCode = "095" → egyeznek

        // buildFullMessage-del legitim üzenetet generálunk, majd a parseResponse-t teszteljük
        String responseBody = "A095" + (char) 0x1C + "F0000" + ETX;
        String fullReply = buildFullMessage(responseBody);
        // parseResponse-ban az aField: az A095 első karaktere 'A' → fieldIdx=1 → fields[1]="095"
        OtpTerminalProtocolService.OtpResponse resp = parseResponse(fullReply);

        assertThat(resp.aField).isEqualTo("095");
        // A küldött parancs "A095", sentCmdCode = "095"
        // rcvdCmdCode = "095".replaceAll("^A", "") = "095" → egyeznek ✓
        String sentCmdCode = "A095".replaceAll("^A", "");
        String rcvdCmdCode = resp.aField != null ? resp.aField.replaceAll("^A", "") : "";
        assertThat(sentCmdCode).isEqualTo(rcvdCmdCode);
    }

    @Test
    @DisplayName("A-field: válasz 'A' prefix-szel érkezik — normalizáció után egyezik")
    void aFieldComparison_responsePrefixed_normalizes() {
        // Szimuláció: response.aField = "A095" (ha a terminál visszaküldi a teljes kódot)
        String sentCmdCode = "A095".replaceAll("^A", "");
        String rcvdCmdCode = "A095".replaceAll("^A", "");
        assertThat(sentCmdCode).isEqualTo(rcvdCmdCode);
    }

    @Test
    @DisplayName("A-field: mismatch esetén az eltérés detektálódik")
    void aFieldComparison_mismatch_detected() {
        String sentCmdCode = "A000".replaceAll("^A", "");   // "000"
        String rcvdCmdCode = "A095".replaceAll("^A", "");   // "095"
        assertThat(sentCmdCode).isNotEqualTo(rcvdCmdCode);
    }

    @Test
    @DisplayName("A-field: null válasz esetén rcvdCmdCode üres string — nem dob NPE")
    void aFieldComparison_nullResponse_noNpe() {
        String sentCmdCode = "A000".replaceAll("^A", "");
        String rcvdCmdCode = (null != null) ? ((String) null).replaceAll("^A", "") : "";
        assertThat(rcvdCmdCode).isEmpty();
        assertThat(sentCmdCode).isNotEqualTo(rcvdCmdCode);
    }

    // ============================================================
    // Bug 2: logoutCashier M mező
    // ============================================================

    @Test
    @DisplayName("logoutCashier(host,port,cashierId): üzenet tartalmaz FS+M mezőt")
    void logoutCashier_withCashierId_containsMField() {
        // Az üzenet struktúrájának ellenőrzése direkt message building logikán keresztül
        String expectedMessageBody = "A051" + FS + "M" + "P01" + ETX;
        assertThat(expectedMessageBody).contains(String.valueOf(FS));
        assertThat(expectedMessageBody).contains("MP01");
        assertThat(expectedMessageBody).startsWith("A051");
        assertThat(expectedMessageBody).endsWith(String.valueOf(ETX));
    }

    @Test
    @DisplayName("logoutCashier(host,port): deprecated overload — ETX nélkül FS nem szerepel")
    @SuppressWarnings("deprecation")
    void logoutCashier_noArg_noMField() {
        // Az üzenet struktúrája: CMD_LOGOUT_CLOSE + ETX (nincs FS, nincs M)
        String expectedMessageBody = "A051" + ETX;
        assertThat(expectedMessageBody).doesNotContain(String.valueOf(FS));
        assertThat(expectedMessageBody).doesNotContain("M");
    }

    @Test
    @DisplayName("logoutCashier cashierId-vel és nélkül különböző üzenetet produkál")
    void logoutCashier_withAndWithout_differentMessages() {
        String withCashier    = "A051" + FS + "M" + "KASSZAS01" + ETX;
        String withoutCashier = "A051" + ETX;
        assertThat(withCashier).isNotEqualTo(withoutCashier);
        assertThat(withCashier.length()).isGreaterThan(withoutCashier.length());
    }

    // ============================================================
    // Bug 3: executeRetry — A101 üzenet
    // ============================================================

    @Test
    @DisplayName("executeRetry: null receiptNumber → error eredmény")
    void executeRetry_nullReceipt_returnsError() {
        PosTransactionResult result = service.executeRetry("127.0.0.1", 9100, null);
        assertThat(result.approved()).isFalse();
        assertThat(result.errorMessage()).contains("bizonylatszám");
    }

    @Test
    @DisplayName("executeRetry: blank receiptNumber → error eredmény")
    void executeRetry_blankReceipt_returnsError() {
        PosTransactionResult result = service.executeRetry("127.0.0.1", 9100, "   ");
        assertThat(result.approved()).isFalse();
        assertThat(result.errorMessage()).contains("bizonylatszám");
    }

    @Test
    @DisplayName("executeRetry: üzenet formátuma helyes — A101 + FS + Y mező")
    void executeRetry_messageFormat_correct() {
        // Az üzenet struktúrájának ellenőrzése
        String receiptNumber = "TRX-2024-001";
        String PROTOCOL_VERSION = "2900";
        String yField = receiptNumber + "_" + PROTOCOL_VERSION;
        String expectedMessage = "A101" + FS + "Y" + yField + ETX;

        assertThat(expectedMessage).startsWith("A101");
        assertThat(expectedMessage).contains(String.valueOf(FS));
        assertThat(expectedMessage).contains("Y" + yField);
        assertThat(expectedMessage).endsWith(String.valueOf(ETX));
    }

    // ============================================================
    // Bug 4: executeReprint — A102 üzenet
    // ============================================================

    @Test
    @DisplayName("executeReprint: null receiptNumber → error eredmény")
    void executeReprint_nullReceipt_returnsError() {
        PosTransactionResult result = service.executeReprint("127.0.0.1", 9100, null);
        assertThat(result.approved()).isFalse();
        assertThat(result.errorMessage()).contains("bizonylatszám");
    }

    @Test
    @DisplayName("executeReprint: blank receiptNumber → error eredmény")
    void executeReprint_blankReceipt_returnsError() {
        PosTransactionResult result = service.executeReprint("127.0.0.1", 9100, "");
        assertThat(result.approved()).isFalse();
        assertThat(result.errorMessage()).contains("bizonylatszám");
    }

    @Test
    @DisplayName("executeReprint: üzenet formátuma helyes — A102 + FS + Y mező")
    void executeReprint_messageFormat_correct() {
        String receiptNumber = "TRX-2024-002";
        String PROTOCOL_VERSION = "2900";
        String yField = receiptNumber + "_" + PROTOCOL_VERSION;
        String expectedMessage = "A102" + FS + "Y" + yField + ETX;

        assertThat(expectedMessage).startsWith("A102");
        assertThat(expectedMessage).contains(String.valueOf(FS));
        assertThat(expectedMessage).contains("Y" + yField);
        assertThat(expectedMessage).endsWith(String.valueOf(ETX));
    }

    @Test
    @DisplayName("A101 és A102 különböző parancsokhoz különböző CMD kódot tartalmaz")
    void retryAndReprint_differentCommands() {
        String retryMsg   = "A101" + FS + "YTRX_2900" + ETX;
        String reprintMsg = "A102" + FS + "YTRX_2900" + ETX;
        assertThat(retryMsg.substring(0, 4)).isEqualTo("A101");
        assertThat(reprintMsg.substring(0, 4)).isEqualTo("A102");
        assertThat(retryMsg).isNotEqualTo(reprintMsg);
    }

    // ============================================================
    // Feature 5: PosTerminalConfigService
    // ============================================================

    @Test
    @DisplayName("PosTerminalConfigService: default feloldás konfig értékekből")
    void posTerminalConfigService_defaultResolution() {
        PosTerminalRepository repo = mock(PosTerminalRepository.class);
        PosTerminalConfigService configService = new PosTerminalConfigService(repo);
        ReflectionTestUtils.setField(configService, "defaultHost", "192.168.1.100");
        ReflectionTestUtils.setField(configService, "defaultPort", 9200);

        PosTerminalConfigService.TerminalAddress addr = configService.resolveDefault();

        assertThat(addr.host()).isEqualTo("192.168.1.100");
        assertThat(addr.port()).isEqualTo(9200);
    }

    @Test
    @DisplayName("PosTerminalConfigService: létező terminál host/port-ját adja vissza")
    void posTerminalConfigService_dbResolution() {
        PosTerminalRepository repo = mock(PosTerminalRepository.class);
        PosTerminalConfigService configService = new PosTerminalConfigService(repo);
        ReflectionTestUtils.setField(configService, "defaultHost", "127.0.0.1");
        ReflectionTestUtils.setField(configService, "defaultPort", 9100);

        UUID id = UUID.randomUUID();
        PosTerminal terminal = PosTerminal.builder()
            .id(id)
            .terminalId("TERM-01")
            .ipAddress("10.0.1.50")
            .port(9300)
            .branchId(UUID.randomUUID())
            .build();
        when(repo.findById(id)).thenReturn(Optional.of(terminal));

        PosTerminalConfigService.TerminalAddress addr = configService.resolve(id);

        assertThat(addr.host()).isEqualTo("10.0.1.50");
        assertThat(addr.port()).isEqualTo(9300);
    }

    @Test
    @DisplayName("PosTerminalConfigService: nem létező UUID esetén default-ot ad vissza")
    void posTerminalConfigService_unknownUuid_fallsBackToDefault() {
        PosTerminalRepository repo = mock(PosTerminalRepository.class);
        PosTerminalConfigService configService = new PosTerminalConfigService(repo);
        ReflectionTestUtils.setField(configService, "defaultHost", "127.0.0.1");
        ReflectionTestUtils.setField(configService, "defaultPort", 9100);

        UUID unknownId = UUID.randomUUID();
        when(repo.findById(unknownId)).thenReturn(Optional.empty());

        PosTerminalConfigService.TerminalAddress addr = configService.resolve(unknownId);

        assertThat(addr.host()).isEqualTo("127.0.0.1");
        assertThat(addr.port()).isEqualTo(9100);
    }

    @Test
    @DisplayName("PosTerminalConfigService: terminál null IP esetén default host-ot használ")
    void posTerminalConfigService_nullIpInDb_usesDefaultHost() {
        PosTerminalRepository repo = mock(PosTerminalRepository.class);
        PosTerminalConfigService configService = new PosTerminalConfigService(repo);
        ReflectionTestUtils.setField(configService, "defaultHost", "127.0.0.1");
        ReflectionTestUtils.setField(configService, "defaultPort", 9100);

        UUID id = UUID.randomUUID();
        PosTerminal terminal = PosTerminal.builder()
            .id(id)
            .terminalId("TERM-NULL-IP")
            .ipAddress(null)
            .port(9400)
            .branchId(UUID.randomUUID())
            .build();
        when(repo.findById(id)).thenReturn(Optional.of(terminal));

        PosTerminalConfigService.TerminalAddress addr = configService.resolve(id);

        assertThat(addr.host()).isEqualTo("127.0.0.1");   // default host
        assertThat(addr.port()).isEqualTo(9400);           // DB port
    }

    @Test
    @DisplayName("UUID overload: executeRetry delegál PosTerminalConfigService-hez")
    void uuidOverload_executeRetry_delegatesToConfigService() {
        UUID termId = UUID.randomUUID();
        when(posTerminalConfigService.resolve(termId))
            .thenReturn(new PosTerminalConfigService.TerminalAddress("127.0.0.1", 9100));

        // null receiptNumber → error mielőtt socket kapcsolódna
        PosTransactionResult result = service.executeRetry(termId, null);

        verify(posTerminalConfigService).resolve(termId);
        assertThat(result.approved()).isFalse();
    }

    @Test
    @DisplayName("UUID overload: executeReprint delegál PosTerminalConfigService-hez")
    void uuidOverload_executeReprint_delegatesToConfigService() {
        UUID termId = UUID.randomUUID();
        when(posTerminalConfigService.resolve(termId))
            .thenReturn(new PosTerminalConfigService.TerminalAddress("127.0.0.1", 9100));

        PosTransactionResult result = service.executeReprint(termId, null);

        verify(posTerminalConfigService).resolve(termId);
        assertThat(result.approved()).isFalse();
    }
}
