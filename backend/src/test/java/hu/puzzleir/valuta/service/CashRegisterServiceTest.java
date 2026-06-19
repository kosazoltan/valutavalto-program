package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCommandRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCommandType;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCurrencyCommandLine;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.dto.nav.NavSendResult;
import hu.puzzleir.valuta.entity.CashRegisterEvent;
import hu.puzzleir.valuta.entity.CashRegisterEventType;
import hu.puzzleir.valuta.repository.CashRegisterEventRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * CashRegisterService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class CashRegisterServiceTest {

    @InjectMocks
    private CashRegisterService service;

    @Mock
    private CashRegisterEventRepository cashRegisterEventRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private NavIntegrationService navIntegrationService;

    @Mock
    private SystemParameterService systemParameterService;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @BeforeEach
    void setUp() {
        lenient().when(systemParameterService.getValue("nav.com-port")).thenReturn("COM1");
        lenient().when(navIntegrationService.sendQrCode(anyString(), anyString())).thenReturn(true);
        lenient().when(navIntegrationService.sendTransaction(anyLong(), anyString())).thenReturn(
                NavSendResult.builder().success(true).receiptNumber("R-2026-0001").build());
    }

    private Branch createBranch() {
        Branch b = new Branch();
        b.setId(BRANCH_ID);
        b.setCode("B01");
        b.setName("Teszt Iroda");
        return b;
    }

    @Test
    @DisplayName("openDay → OPEN event, rawResponse contains OK")
    void testOpenDay() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterEventDto result = service.openDay(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getEventType()).isEqualTo("OPEN");
        assertThat(result.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(result.getRawResponse()).contains("OK");
        verify(navIntegrationService).sendQrCode(CashRegisterService.DAY_OPEN_COMMAND, "COM1");
        verify(cashRegisterEventRepository).save(any(CashRegisterEvent.class));
    }

    @Test
    @DisplayName("openDay → bejelentkezett kontextusban company szerint scope-olt branch lookupot használ")
    void openDayAuthenticatedScopesBranchByCompany() {
        Branch branch = createBranch();
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("W0001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(1L, COMPANY_ID, BRANCH_ID, "SUPERVISOR"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterEventDto result = service.openDay(BRANCH_ID);

        assertThat(result.getBranchId()).isEqualTo(BRANCH_ID);
        verify(branchRepository).findByIdAndCompanyId(BRANCH_ID, COMPANY_ID);
        verify(branchRepository, never()).findById(BRANCH_ID);
    }

    @Test
    @DisplayName("closeDay → CLOSE event, Z jelentés")
    void testCloseDay() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterEventDto result = service.closeDay(BRANCH_ID);

        assertThat(result).isNotNull();
        assertThat(result.getEventType()).isEqualTo("CLOSE");
        assertThat(result.getRawResponse()).contains("Z jelentés");
        verify(navIntegrationService).sendQrCode(CashRegisterService.DAY_CLOSE_COMMAND, "COM1");
        verify(cashRegisterEventRepository).save(any(CashRegisterEvent.class));
    }

    @Test
    @DisplayName("executeCommand → valuta-lista törlés explicit NAV CCL parancs")
    void executeCommandCurrencyListClearUsesExplicitLegacyCommand() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterEventDto result = service.executeCommand(CashRegisterCommandRequest.builder()
                .branchId(BRANCH_ID)
                .commandType(CashRegisterCommandType.CURRENCY_LIST_CLEAR)
                .build());

        assertThat(result.getEventType()).isEqualTo("CURRENCY_LIST_CLEAR");
        assertThat(result.getRawResponse()).contains("CURRENCY_LIST_CLEAR", CashRegisterService.CURRENCY_LIST_CLEAR_COMMAND);
        verify(navIntegrationService).sendQrCode(CashRegisterService.CURRENCY_LIST_CLEAR_COMMAND, "COM1");
    }

    @Test
    @DisplayName("executeCommand → valuta-lista betöltés explicit NAV CYS payload")
    void executeCommandCurrencyListSetBuildsDeterministicLegacyPayload() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterEventDto result = service.executeCommand(CashRegisterCommandRequest.builder()
                .branchId(BRANCH_ID)
                .commandType(CashRegisterCommandType.CURRENCY_LIST_SET)
                .currencies(List.of(
                        CashRegisterCurrencyCommandLine.builder().currencyCode("EUR").displayName("EUR").build(),
                        CashRegisterCurrencyCommandLine.builder().currencyCode("usd").displayName("US|D").build(),
                        CashRegisterCurrencyCommandLine.builder().currencyCode("GBP").cashRegisterKey("gb01").rate(new BigDecimal("1.23456")).build()))
                .build());

        String expectedPayload = CashRegisterService.CURRENCY_LIST_SET_COMMAND
                + "|CY00|EUR|1.0000|1.0000"
                + "|CY01|US/D|1.0000|1.0000"
                + "|GB01|GBP|1.2345|1.2345";
        assertThat(result.getEventType()).isEqualTo("CURRENCY_LIST_SET");
        assertThat(result.getRawResponse()).contains("CURRENCY_LIST_SET", expectedPayload);
        verify(navIntegrationService).sendQrCode(expectedPayload, "COM1");
    }

    @Test
    @DisplayName("executeCommand → CURRENCY_LIST_SET üres valuta-listával fail-fast")
    void executeCommandCurrencyListSetRequiresCurrencies() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(createBranch()));

        assertThatThrownBy(() -> service.executeCommand(CashRegisterCommandRequest.builder()
                .branchId(BRANCH_ID)
                .commandType(CashRegisterCommandType.CURRENCY_LIST_SET)
                .currencies(List.of())
                .build()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("legalább egy valuta");
    }

    @Test
    @DisplayName("printReceipt → RECEIPT event, receipt number set")
    void testPrintReceipt() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterReceiptRequest request = CashRegisterReceiptRequest.builder()
                .branchId(BRANCH_ID)
                .receiptNumber("R-2026-0001")
                .amount(new BigDecimal("500.00"))
                .currencyCode("EUR")
                .amountHuf(new BigDecimal("195000"))
                .build();

        CashRegisterEventDto result = service.printReceipt(request);

        assertThat(result).isNotNull();
        assertThat(result.getEventType()).isEqualTo("RECEIPT");
        assertThat(result.getReceiptNumber()).isEqualTo("R-2026-0001");
        assertThat(result.getCurrencyCode()).isEqualTo("EUR");
        assertThat(result.getAmount()).isEqualByComparingTo(new BigDecimal("500.00"));
        assertThat(result.getAmountHuf()).isEqualByComparingTo(new BigDecimal("195000"));
    }

    @Test
    @DisplayName("printReceipt → sikertelen NAV válasznál nem tölt fallback nyugtaszámot")
    void printReceiptDoesNotSetFallbackReceiptNumberWhenNavFails() {
        Branch branch = createBranch();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(navIntegrationService.sendTransaction(anyLong(), anyString())).thenReturn(
                NavSendResult.builder().success(false).error("NAV bridge szimuláció tiltva").build());
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterReceiptRequest request = CashRegisterReceiptRequest.builder()
                .branchId(BRANCH_ID)
                .receiptNumber("R-LOCAL-0001")
                .amount(new BigDecimal("500.00"))
                .currencyCode("EUR")
                .amountHuf(new BigDecimal("195000"))
                .build();

        CashRegisterEventDto result = service.printReceipt(request);

        assertThat(result.getEventType()).isEqualTo("RECEIPT");
        assertThat(result.getReceiptNumber()).isNull();
        assertThat(result.getRawResponse()).contains("ERROR", "Bizonylat NAV továbbítás sikertelen");
    }

    @Test
    @DisplayName("printStorno → sikertelen NAV válasznál nem tölt fallback sztornó nyugtaszámot")
    void printStornoDoesNotSetFallbackReceiptNumberWhenNavFails() {
        Branch branch = createBranch();
        UUID originalId = UUID.randomUUID();
        CashRegisterEvent original = CashRegisterEvent.builder()
                .id(originalId)
                .branch(branch)
                .eventType(CashRegisterEventType.RECEIPT)
                .receiptNumber("R-2026-0001")
                .amount(new BigDecimal("500.00"))
                .currencyCode("EUR")
                .amountHuf(new BigDecimal("195000"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashRegisterEventRepository.findByIdAndBranchId(originalId, BRANCH_ID)).thenReturn(Optional.of(original));
        when(navIntegrationService.sendTransaction(anyLong(), anyString())).thenReturn(
                NavSendResult.builder().success(false).error("NAV bridge szimuláció tiltva").build());
        when(cashRegisterEventRepository.save(any(CashRegisterEvent.class))).thenAnswer(inv -> {
            CashRegisterEvent e = inv.getArgument(0);
            if (e.getId() == null) e.setId(UUID.randomUUID());
            return e;
        });

        CashRegisterEventDto result = service.printStorno(CashRegisterStornoRequest.builder()
                .branchId(BRANCH_ID)
                .originalReceiptId(originalId)
                .build());

        assertThat(result.getEventType()).isEqualTo("STORNO");
        assertThat(result.getReceiptNumber()).isNull();
        assertThat(result.getRawResponse()).contains("ERROR", "Sztornó NAV továbbítás sikertelen");
        verify(cashRegisterEventRepository).findByIdAndBranchId(originalId, BRANCH_ID);
        verify(cashRegisterEventRepository, never()).findById(originalId);
    }

    @Test
    @DisplayName("getDailyEvents → returns events list for date")
    void testGetDailyEvents() {
        Branch branch = createBranch();
        LocalDate today = LocalDate.now();
        LocalDateTime from = today.atStartOfDay();
        LocalDateTime to = today.atTime(LocalTime.MAX);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .id(UUID.randomUUID())
                .branch(branch)
                .eventType(CashRegisterEventType.OPEN)
                .eventTimestamp(LocalDateTime.now())
                .rawResponse("{\"status\":\"OK\"}")
                .build();

        when(cashRegisterEventRepository.findByBranchIdAndEventTimestampBetweenOrderByEventTimestampDesc(
                eq(BRANCH_ID), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(List.of(event));

        List<CashRegisterEventDto> result = service.getDailyEvents(BRANCH_ID, today);

        assertThat(result).isNotNull();
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getEventType()).isEqualTo("OPEN");
    }
}
