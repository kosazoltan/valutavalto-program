package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID FROM_BRANCH_ID = UUID.randomUUID();
    private static final UUID TO_BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;

    private Branch fromBranch;
    private Branch toBranch;

    @BeforeEach
    void setUp() {
        Company company = new Company();
        company.setId(COMPANY_ID);

        fromBranch = new Branch();
        fromBranch.setId(FROM_BRANCH_ID);
        fromBranch.setCode("B01");
        fromBranch.setName("Iroda 1");
        fromBranch.setCompany(company);

        toBranch = new Branch();
        toBranch.setId(TO_BRANCH_ID);
        toBranch.setCode("B02");
        toBranch.setName("Iroda 2");
        toBranch.setCompany(company);
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
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

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
                Currency eur = new Currency();
                eur.setId(1L);
                eur.setCode("EUR");
                when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(acceptedEntity));
                when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(FROM_BRANCH_ID, 1L, COMPANY_ID))
                    .thenReturn(Optional.of(createBalance(fromBranch, eur, "10000")));
                when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(TO_BRANCH_ID, 1L, COMPANY_ID))
                    .thenReturn(Optional.of(createBalance(toBranch, eur, "0")));

                TradeDto completed = tradeService.completeTrade(tradeId);

                assertThat(completed.getStatus()).isEqualTo("COMPLETED");
                verify(tradeRepository, atLeast(3)).save(any(Trade.class));
                verify(cashBalanceRepository, times(2)).save(any(CashBalance.class));
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
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

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
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

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
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

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
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(FROM_BRANCH_ID);
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                UUID tradeId = UUID.randomUUID();
                Trade completedTrade = createTradeEntity(tradeId, Trade.TradeStatus.COMPLETED);
                when(tradeRepository.findById(tradeId)).thenReturn(Optional.of(completedTrade));

                assertThatThrownBy(() -> tradeService.acceptTrade(tradeId, WORKER_ID))
                        .isInstanceOf(ValidationException.class)
                        .hasMessageContaining("PROPOSED");
            }
        }
    }

    // ===== HELPER =====

    private CashBalance createBalance(Branch branch, Currency currency, String amount) {
        CashBalance balance = new CashBalance();
        balance.setBranch(branch);
        balance.setCompany(branch.getCompany());
        balance.setCurrency(currency);
        balance.setCurrentBalance(new BigDecimal(amount));
        return balance;
    }

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
