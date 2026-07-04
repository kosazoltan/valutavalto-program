package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.LiveCashPositionDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DailySubledgerSnapshot;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DailySubledgerSnapshotRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * LiveCashPositionService (G9) unit tesztek — pillanatnyi pénztárállás.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class LiveCashPositionServiceTest {

    @Mock private DailyBalanceRepository dailyBalanceRepository;
    @Mock private DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    @Mock private CurrencyRepository currencyRepository;

    @InjectMocks private LiveCashPositionService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUpSecurityContext() {
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(new WorkerAuthenticationDetails(1L, COMPANY_ID, BRANCH_ID, "ADMIN"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("G9: valutánkénti NYITÓ/BEVÉTEL/KIADÁS/ZÁRÓ + kezelési-díj egyenleg")
    void getLivePosition_buildsCurrencyLinesAndHandlingFee() {
        Currency eur = new Currency();
        eur.setCode("EUR");
        eur.setName("Euro");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        DailyBalance eurBal = DailyBalance.builder()
                .branchId(BRANCH_ID)
                .currencyCode("EUR")
                .openingBalance(new BigDecimal("1000"))
                .purchases(new BigDecimal("200"))
                .transfersIn(new BigDecimal("50"))
                .sales(new BigDecimal("100"))
                .transfersOut(new BigDecimal("0"))
                .closingBalance(new BigDecimal("1150"))
                .build();
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.any(UUID.class), eq(BRANCH_ID), any()))
                .thenReturn(List.of(eurBal));

        DailySubledgerSnapshot hf = DailySubledgerSnapshot.builder()
                .branchId(BRANCH_ID).subledgerType("HANDLING_FEE").currencyCode("HUF")
                .closingBalance(new BigDecimal("5000"))
                .build();
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("HANDLING_FEE"), eq("HUF")))
                .thenReturn(Optional.of(hf));

        LiveCashPositionDto result = service.getLivePosition(BRANCH_ID);

        assertThat(result.getLines()).hasSize(1);
        LiveCashPositionDto.CurrencyLineDto eurLine = result.getLines().get(0);
        assertThat(eurLine.getCurrencyCode()).isEqualTo("EUR");
        assertThat(eurLine.getCurrencyName()).isEqualTo("Euro");
        assertThat(eurLine.getOpening()).isEqualByComparingTo("1000");
        assertThat(eurLine.getIncome()).isEqualByComparingTo("250");  // 200 + 50
        assertThat(eurLine.getExpense()).isEqualByComparingTo("100"); // 100 + 0
        assertThat(eurLine.getClosing()).isEqualByComparingTo("1150");
        assertThat(result.getHandlingFeeHuf()).isEqualByComparingTo("5000");
    }

    @Test
    @DisplayName("G9: nincs napi mozgás → üres sorok, 0 kezelési díj")
    void getLivePosition_empty() {
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(org.mockito.ArgumentMatchers.any(UUID.class), eq(BRANCH_ID), any())).thenReturn(List.of());
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), eq("HANDLING_FEE"), eq("HUF"))).thenReturn(Optional.empty());

        LiveCashPositionDto result = service.getLivePosition(BRANCH_ID);

        assertThat(result.getLines()).isEmpty();
        assertThat(result.getHandlingFeeHuf()).isEqualByComparingTo("0");
    }
}
