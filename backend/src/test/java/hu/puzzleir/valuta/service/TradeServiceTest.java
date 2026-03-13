package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.trade.ProposeTradeDto;
import hu.puzzleir.valuta.dto.trade.TradeDto;
import hu.puzzleir.valuta.entity.Trade;
import hu.puzzleir.valuta.repository.TradeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * TradeService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class TradeServiceTest {

    @InjectMocks
    private TradeService service;

    @Mock
    private TradeRepository tradeRepository;

    @Mock
    private BranchRepository branchRepository;

    private static final UUID FROM_BRANCH_ID = UUID.randomUUID();
    private static final UUID TO_BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;

    private Branch createBranch(UUID id, String code, String name) {
        Branch b = new Branch();
        b.setId(id);
        b.setCode(code);
        b.setName(name);
        return b;
    }

    private Trade createTrade(UUID id, Trade.TradeStatus status) {
        Branch from = createBranch(FROM_BRANCH_ID, "B01", "Iroda 1");
        Branch to = createBranch(TO_BRANCH_ID, "B02", "Iroda 2");
        return Trade.builder()
                .id(id)
                .fromBranch(from)
                .toBranch(to)
                .currencyCode("EUR")
                .amount(new BigDecimal("1000"))
                .rate(BigDecimal.ONE)
                .status(status)
                .proposedBy(WORKER_ID)
                .proposedAt(LocalDateTime.now())
                .build();
    }

    // =====================================================================
    // proposeTrade
    // =====================================================================
    @Test
    @DisplayName("proposeTrade → PROPOSED státusz, mentve")
    void testProposeTrade() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(FROM_BRANCH_ID);

            Branch from = createBranch(FROM_BRANCH_ID, "B01", "Iroda 1");
            Branch to = createBranch(TO_BRANCH_ID, "B02", "Iroda 2");

            when(branchRepository.findById(FROM_BRANCH_ID)).thenReturn(Optional.of(from));
            when(branchRepository.findById(TO_BRANCH_ID)).thenReturn(Optional.of(to));
            when(tradeRepository.save(any(Trade.class))).thenAnswer(inv -> {
                Trade t = inv.getArgument(0);
                t.setId(UUID.randomUUID());
                return t;
            });

            ProposeTradeDto dto = ProposeTradeDto.builder()
                    .fromBranchId(FROM_BRANCH_ID)
                    .toBranchId(TO_BRANCH_ID)
                    .currencyCode("EUR")
                    .amount(new BigDecimal("5000"))
                    .rate(new BigDecimal("395.50"))
                    .notes("Teszt trade")
                    .build();

            TradeDto result = service.proposeTrade(dto);

            assertThat(result).isNotNull();
            assertThat(result.getStatus()).isEqualTo("PROPOSED");
            assertThat(result.getCurrencyCode()).isEqualTo("EUR");
            assertThat(result.getAmount()).isEqualByComparingTo(new BigDecimal("5000"));
            assertThat(result.getFromBranchName()).isEqualTo("Iroda 1");
            assertThat(result.getToBranchName()).isEqualTo("Iroda 2");
            verify(tradeRepository).save(any(Trade.class));
        }
    }

    // =====================================================================
    // acceptTrade
    // =====================================================================
    @Test
    @DisplayName("acceptTrade → ACCEPTED státusz, acceptedBy kitöltve")
    void testAcceptTrade() {
        UUID tradeId = UUID.randomUUID();
        Trade trade = createTrade(tradeId, Trade.TradeStatus.PROPOSED);

        when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(trade));
        when(tradeRepository.save(any(Trade.class))).thenAnswer(inv -> inv.getArgument(0));

        TradeDto result = service.acceptTrade(tradeId, WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("ACCEPTED");
        assertThat(result.getAcceptedBy()).isEqualTo(WORKER_ID);
        verify(tradeRepository).save(any(Trade.class));
    }

    // =====================================================================
    // rejectTrade
    // =====================================================================
    @Test
    @DisplayName("rejectTrade → REJECTED, reason kitöltve")
    void testRejectTrade() {
        UUID tradeId = UUID.randomUUID();
        Trade trade = createTrade(tradeId, Trade.TradeStatus.PROPOSED);

        when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(trade));
        when(tradeRepository.save(any(Trade.class))).thenAnswer(inv -> inv.getArgument(0));

        TradeDto result = service.rejectTrade(tradeId, "Túl magas árfolyam");

        assertThat(result.getStatus()).isEqualTo("REJECTED");
        assertThat(result.getNotes()).contains("Elutasítás: Túl magas árfolyam");
        verify(tradeRepository).save(any(Trade.class));
    }

    // =====================================================================
    // completeTrade
    // =====================================================================
    @Test
    @DisplayName("completeTrade → COMPLETED státusz")
    void testCompleteTrade() {
        UUID tradeId = UUID.randomUUID();
        Trade trade = createTrade(tradeId, Trade.TradeStatus.ACCEPTED);

        when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(trade));
        when(tradeRepository.save(any(Trade.class))).thenAnswer(inv -> inv.getArgument(0));

        TradeDto result = service.completeTrade(tradeId);

        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        verify(tradeRepository).save(any(Trade.class));
    }

    // =====================================================================
    // acceptTrade — already COMPLETED → exception
    // =====================================================================
    @Test
    @DisplayName("acceptTrade — COMPLETED státuszú → ValidationException")
    void testAcceptTrade_alreadyCompleted() {
        UUID tradeId = UUID.randomUUID();
        Trade trade = createTrade(tradeId, Trade.TradeStatus.COMPLETED);

        when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(trade));

        assertThatThrownBy(() -> service.acceptTrade(tradeId, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("PROPOSED");
    }
}
