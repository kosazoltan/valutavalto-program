package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.entity.CashRegisterEvent;
import hu.puzzleir.valuta.entity.CashRegisterEventType;
import hu.puzzleir.valuta.repository.CashRegisterEventRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

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

    private static final UUID BRANCH_ID = UUID.randomUUID();

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
        verify(cashRegisterEventRepository).save(any(CashRegisterEvent.class));
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
        verify(cashRegisterEventRepository).save(any(CashRegisterEvent.class));
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
