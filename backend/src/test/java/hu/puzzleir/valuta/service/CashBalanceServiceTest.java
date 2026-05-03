package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CashBalanceServiceTest {

    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @InjectMocks private CashBalanceService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Test
    @DisplayName("validateSufficientBalance — elegendo keszlet")
    void testValidateSufficientBalance_ok() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance balance = CashBalance.builder()
                .currency(eur)
                .currentBalance(new BigDecimal("5000"))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, 4L))
                    .thenReturn(Optional.of(balance));

            assertThatCode(() -> service.validateSufficientBalance(4L, new BigDecimal("3000")))
                    .doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("validateSufficientBalance — nem elegendo keszlet")
    void testValidateSufficientBalance_insufficient() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance balance = CashBalance.builder()
                .currency(eur)
                .currentBalance(new BigDecimal("100"))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, 4L))
                    .thenReturn(Optional.of(balance));

            assertThatThrownBy(() -> service.validateSufficientBalance(4L, new BigDecimal("500")))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Nincs elegendő");
        }
    }

    @Test
    @DisplayName("getCurrentBranchBalances — lista visszaadas")
    void testGetCurrentBranchBalances() {
        CashBalance b1 = CashBalance.builder().currentBalance(BigDecimal.TEN).build();
        CashBalance b2 = CashBalance.builder().currentBalance(BigDecimal.ONE).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(List.of(b1, b2));

            List<CashBalance> result = service.getCurrentBranchBalances();
            assertThat(result).hasSize(2);
        }
    }

    @Test
    @DisplayName("getBalanceByCurrency — nem letezo valuta")
    void testGetBalanceByCurrency_notFound() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, 999L))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getBalanceByCurrency(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // -----------------------------------------------------------------
    // Audit P0.7 (2026-05-03) regressziovedelem
    // -----------------------------------------------------------------

    @Test
    @DisplayName("initializeBranchBalances — SecurityContext nelkul (startup/async) sikeres")
    void initializeBranchBalances_noSecurityContext_succeeds() {
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch branch = Branch.builder().id(branchId).company(company).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            // Pre-auth context: getCurrentCompanyIdOrNull == null (startup/async hook)
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(null);
            when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
            when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of());

            assertThatCode(() -> service.initializeBranchBalances(branchId))
                    .as("startup/async hivasban sem dobhat ValidationException-t")
                    .doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("initializeBranchBalances — cross-tenant tiltva AccessDeniedException-nel")
    void initializeBranchBalances_crossTenant_throwsAccessDenied() {
        UUID branchId = UUID.randomUUID();
        UUID branchCompanyId = UUID.randomUUID();
        UUID currentCompanyId = UUID.randomUUID();  // Mas company a kontextusban
        Company branchCompany = Company.builder().id(branchCompanyId).build();
        Branch branch = Branch.builder().id(branchId).company(branchCompany).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(currentCompanyId);
            when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

            assertThatThrownBy(() -> service.initializeBranchBalances(branchId))
                    .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                    .hasMessageContaining("cross-tenant tiltott");
        }
    }

    @Test
    @DisplayName("initializeBranchBalances — saját company branch-ere mukodik")
    void initializeBranchBalances_sameTenant_succeeds() {
        UUID branchId = UUID.randomUUID();
        UUID companyId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch branch = Branch.builder().id(branchId).company(company).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
            when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of());

            assertThatCode(() -> service.initializeBranchBalances(branchId))
                    .doesNotThrowAnyException();
        }
    }
}
