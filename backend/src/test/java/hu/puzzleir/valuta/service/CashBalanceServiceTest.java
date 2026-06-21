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
            // #865: getBalanceByCurrency a WithDetails JOIN FETCH variánst használja
            // (lazy branch/currency proxy elkerülése a controller DTO-mappinghez).
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdWithDetails(BRANCH_ID, 999L))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getBalanceByCurrency(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // -----------------------------------------------------------------
    // Audit P0.7 (2026-05-03) regressziovedelem
    // -----------------------------------------------------------------

    @org.junit.jupiter.api.AfterEach
    void clearSecurityContext() {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("initializeBranchBalances — SecurityContext nelkul (startup/async) sikeres")
    void initializeBranchBalances_noSecurityContext_succeeds() {
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch branch = Branch.builder().id(branchId).company(company).build();

        // Pre-auth context: SecurityContextHolder ures
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of());

        assertThatCode(() -> service.initializeBranchBalances(branchId))
                .as("startup/async hivasban sem dobhat ValidationException-t")
                .doesNotThrowAnyException();
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
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(currentCompanyId);
            setAuthenticatedContext("worker-1");
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
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            setAuthenticatedContext("worker-1");
            when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
            when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of());

            assertThatCode(() -> service.initializeBranchBalances(branchId))
                    .doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("Codex P1 PR #354: authentikalt context + hianyzo companyId (malformed JWT) -> ValidationException, NEM bypass")
    void initializeBranchBalances_authenticatedButCompanyIdMissing_throwsValidation() {
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch branch = Branch.builder().id(branchId).company(company).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            // Authentikalt request, de a JWT-bol hianyzik a companyId -> SecurityUtils dob.
            su.when(SecurityUtils::getCurrentCompanyId)
                    .thenThrow(new ValidationException("Nincs bejelentkezett felhasználó!"));
            setAuthenticatedContext("worker-1");
            when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

            assertThatThrownBy(() -> service.initializeBranchBalances(branchId))
                    .as("Codex P1: malformed JWT (companyId hianyzik) NEM bypass-elheti a tenant guard-ot")
                    .isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("FK-032: initializeAllBranchBalancesForCurrentCompany a VAULT_COUNTERPARTY-kizáró metódust hívja (Codex P2 #1195)")
    void initializeAll_excludesVaultCounterparties() {
        UUID companyId = UUID.randomUUID();
        Company company = new Company();
        company.setId(companyId);
        Branch realBranch = new Branch();
        realBranch.setId(BRANCH_ID);
        realBranch.setName("Valódi pénztár");
        realBranch.setCompany(company);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            // A kizáró metódus a valódi branch-et adja vissza (a VAULT_COUNTERPARTY-t a JPQL kizárja).
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId))
                    .thenReturn(List.of(realBranch));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(realBranch));
            when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of()); // 0 új rekord

            var result = service.initializeAllBranchBalancesForCurrentCompany();

            // A bulk-init a KIZÁRÓ metódust hívja (counterparty-mentes) — NEM a sima findByCompanyIdAndIsActiveTrue-t,
            // különben a 10 virtuális partnernek is létrejönne valódi cash_balance sor (FK-032 forrás-gyökér).
            verify(branchRepository).findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);
            verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(companyId);
            assertThat(result.branchCount()).isEqualTo(1);
        }
    }

    @Test
    @DisplayName("FK-038: getCompanyBalances az ÉRTÉKTÁR-kizáró metódust hívja (a Zárási-állapot widget ne listázzon vaultot)")
    void getCompanyBalances_excludesVault() {
        UUID companyId = UUID.randomUUID();
        CashBalance penztarBalance = CashBalance.builder().currentBalance(new BigDecimal("1000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            when(cashBalanceRepository.findByCompanyIdExcludingVault(companyId))
                    .thenReturn(List.of(penztarBalance));

            List<CashBalance> result = service.getCompanyBalances();

            // FK-038 / V334 invariáns: a cég-szintű kassza-nézet (Dashboard TOP Irodák +
            // Zárási állapot widget + StockMatrix forrása) a vault-KIZÁRÓ metódust hívja —
            // NEM a sima findByCompanyId-t, különben egy beszivárgott értéktár cash_balance sor
            // (V247-bug típus) ismét tévesen megjelenne a listán.
            verify(cashBalanceRepository).findByCompanyIdExcludingVault(companyId);
            verify(cashBalanceRepository, never()).findByCompanyId(companyId);
            assertThat(result).hasSize(1);
        }
    }

    @Test
    @DisplayName("FK-038: initializeBranchBalances ÉRTÉKTÁR fiókra 0-t ad és NEM hoz létre cash_balance-t")
    void initializeBranchBalances_vaultBranch_skipped() {
        UUID vaultBranchId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch vault = Branch.builder().id(vaultBranchId).company(company).name("Szeged Értéktár").isVault(true).build();

        // startup/async path (nincs authentikáció) → a tenant-guard kihagyva, egyből a vault-skiphez ér.
        // FK-038 invariáns: értéktárnak nincs cash_balance — a write-oldali gyökér-gate itt áll, így a
        // branch-létrehozás / bulk-init / lazy-init egyike sem hoz létre vault cash_balance sort.
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
        when(branchRepository.findById(vaultBranchId)).thenReturn(Optional.of(vault));

        int created = service.initializeBranchBalances(vaultBranchId);

        assertThat(created).isZero();
        verify(cashBalanceRepository, never()).save(any());
        verify(currencyRepository, never()).findAllActiveOrdered();
    }

    /** Helper: beallit egy authentikalt SecurityContext-et a teszt erejeig. */
    private static void setAuthenticatedContext(String principal) {
        org.springframework.security.authentication.UsernamePasswordAuthenticationToken auth =
                new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        principal, null, java.util.List.of());
        org.springframework.security.core.context.SecurityContext ctx =
                org.springframework.security.core.context.SecurityContextHolder.createEmptyContext();
        ctx.setAuthentication(auth);
        org.springframework.security.core.context.SecurityContextHolder.setContext(ctx);
    }
}
