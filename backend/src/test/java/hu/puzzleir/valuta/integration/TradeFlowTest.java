package hu.puzzleir.valuta.integration;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.trade.ProposeTradeDto;
import hu.puzzleir.valuta.dto.trade.TradeDto;
import hu.puzzleir.valuta.entity.Trade;
import hu.puzzleir.valuta.repository.TradeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TradeService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
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
 * TradeFlow integrációs tesztek — devizakereskedés irodák között.
 */
@ExtendWith(MockitoExtension.class)
class TradeFlowTest {

    @InjectMocks
    private TradeService tradeService;

    @Mock private TradeRepository tradeRepository;
    @Mock private BranchRepository branchRepository;

    private static final UUID FROM_BRANCH_ID = UUID.randomUUID();
    private static final UUID TO_BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;

    private Branch fromBranch;
    private Branch toBranch;

    @BeforeEach
    void setUp() {
        fromBranch = new Branch();
        fromBranch.setId(FROM_BRANCH_ID);
        fromBranch.setCode("B01");
        fromBranch.setName("Iroda 1");

        toBranch = new Branch();
        toBranch.setId(TO_BRANCH_ID);
        toBranch.setCode("B02");
        toBranch.setName("Iroda 2");
    }

    @Nested
    @DisplayName("Trade propose → accept → complete")
    class ProposeAcceptCompleteTests {

        @Test
        @DisplayName("testTradeFlow_propose_accept_complete — teljes trade ciklus")
        void testTradeFlow_propose_accept_complete() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(FROM_BRANCH_ID);

                when(branchRepository.findById(FROM_BRANCH_ID)).thenReturn(Optional.of(fromBranch));
                when(branchRepository.findById(TO_BRANCH_ID)).thenReturn(Optional.of(toBranch));

                UUID tradeId = UUID.randomUUID();
                when(tradeRepository.save(any(Trade.class))).thenAnswer(inv -> {
                    Trade t = inv.getArgument(0);
                    t.setId(tradeId);
                    return t;
                });

                // 1. Propose
                ProposeTradeDto proposeDto = ProposeTradeDto.builder()
                        .fromBranchId(FROM_BRANCH_ID)
                        .toBranchId(TO_BRANCH_ID)
                        .currencyCode("EUR")
                        .amount(new BigDecimal("10000"))
                        .rate(new BigDecimal("395.50"))
                        .notes("Napi készlet kiegészítés")
                        .build();

                TradeDto proposed = tradeService.proposeTrade(proposeDto);

                assertThat(proposed).isNotNull();
                assertThat(proposed.getStatus()).isEqualTo("PROPOSED");
                assertThat(proposed.getCurrencyCode()).isEqualTo("EUR");
                assertThat(proposed.getAmount()).isEqualByComparingTo(new BigDecimal("10000"));
                assertThat(proposed.getFromBranchName()).isEqualTo("Iroda 1");
                assertThat(proposed.getToBranchName()).isEqualTo("Iroda 2");

                // 2. Accept
                Trade proposedEntity = createTradeEntity(tradeId, Trade.TradeStatus.PROPOSED);
                when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(proposedEntity));

                TradeDto accepted = tradeService.acceptTrade(tradeId, WORKER_ID);

                assertThat(accepted.getStatus()).isEqualTo("ACCEPTED");
                assertThat(accepted.getAcceptedBy()).isEqualTo(WORKER_ID);

                // 3. Complete
                Trade acceptedEntity = createTradeEntity(tradeId, Trade.TradeStatus.ACCEPTED);
                when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(acceptedEntity));

                TradeDto completed = tradeService.completeTrade(tradeId);

                assertThat(completed.getStatus()).isEqualTo("COMPLETED");
                verify(tradeRepository, atLeast(3)).save(any(Trade.class));
            }
        }
    }

    @Nested
    @DisplayName("Trade propose → reject")
    class ProposeRejectTests {

        @Test
        @DisplayName("testTradeFlow_propose_reject — trade ajánlat elutasítása")
        void testTradeFlow_propose_reject() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(FROM_BRANCH_ID);

                when(branchRepository.findById(FROM_BRANCH_ID)).thenReturn(Optional.of(fromBranch));
                when(branchRepository.findById(TO_BRANCH_ID)).thenReturn(Optional.of(toBranch));

                UUID tradeId = UUID.randomUUID();
                when(tradeRepository.save(any(Trade.class))).thenAnswer(inv -> {
                    Trade t = inv.getArgument(0);
                    t.setId(tradeId);
                    return t;
                });

                // 1. Propose
                ProposeTradeDto proposeDto = ProposeTradeDto.builder()
                        .fromBranchId(FROM_BRANCH_ID)
                        .toBranchId(TO_BRANCH_ID)
                        .currencyCode("USD")
                        .amount(new BigDecimal("5000"))
                        .build();

                TradeDto proposed = tradeService.proposeTrade(proposeDto);
                assertThat(proposed.getStatus()).isEqualTo("PROPOSED");

                // 2. Reject
                Trade proposedEntity = createTradeEntity(tradeId, Trade.TradeStatus.PROPOSED);
                proposedEntity.setCurrencyCode("USD");
                when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(proposedEntity));

                TradeDto rejected = tradeService.rejectTrade(tradeId, "Túl magas árfolyam");

                assertThat(rejected.getStatus()).isEqualTo("REJECTED");
                assertThat(rejected.getNotes()).contains("Elutasítás");
            }
        }
    }

    @Nested
    @DisplayName("Trade validation errors")
    class ValidationTests {

        @Test
        @DisplayName("testTradeFlow_sameBranch — forrás és cél azonos → hiba")
        void testTradeFlow_sameBranch() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(FROM_BRANCH_ID);

                when(branchRepository.findById(FROM_BRANCH_ID)).thenReturn(Optional.of(fromBranch));

                ProposeTradeDto dto = ProposeTradeDto.builder()
                        .fromBranchId(FROM_BRANCH_ID)
                        .toBranchId(FROM_BRANCH_ID)
                        .currencyCode("EUR")
                        .amount(new BigDecimal("1000"))
                        .build();

                assertThatThrownBy(() -> tradeService.proposeTrade(dto))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("azonos");
            }
        }

        @Test
        @DisplayName("testTradeFlow_zeroAmount — nulla összeg → hiba")
        void testTradeFlow_zeroAmount() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(FROM_BRANCH_ID);

                when(branchRepository.findById(FROM_BRANCH_ID)).thenReturn(Optional.of(fromBranch));
                when(branchRepository.findById(TO_BRANCH_ID)).thenReturn(Optional.of(toBranch));

                ProposeTradeDto dto = ProposeTradeDto.builder()
                        .fromBranchId(FROM_BRANCH_ID)
                        .toBranchId(TO_BRANCH_ID)
                        .currencyCode("EUR")
                        .amount(BigDecimal.ZERO)
                        .build();

                assertThatThrownBy(() -> tradeService.proposeTrade(dto))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("pozitív");
            }
        }

        @Test
        @DisplayName("testTradeFlow_acceptNonProposed — nem PROPOSED trade elfogadása → hiba")
        void testTradeFlow_acceptNonProposed() {
            UUID tradeId = UUID.randomUUID();
            Trade completedTrade = createTradeEntity(tradeId, Trade.TradeStatus.COMPLETED);
            when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(completedTrade));

            assertThatThrownBy(() -> tradeService.acceptTrade(tradeId, WORKER_ID))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("PROPOSED");
        }
    }

    // ===== HELPER =====

    private Trade createTradeEntity(UUID id, Trade.TradeStatus status) {
        return Trade.builder()
                .id(id)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .currencyCode("EUR")
                .amount(new BigDecimal("10000"))
                .rate(new BigDecimal("395.50"))
                .status(status)
                .proposedBy(WORKER_ID)
                .proposedAt(LocalDateTime.now())
                .build();
    }
}
