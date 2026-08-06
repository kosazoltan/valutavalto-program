package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
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
    @Mock private AuditLogService auditLogService;
    @InjectMocks private CashBalanceService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

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
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
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
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));

            assertThatThrownBy(() -> service.validateSufficientBalance(4L, new BigDecimal("500")))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Nincs elegendő");
        }
    }


    @Test
    @DisplayName("validateSufficientBalance — cross-tenant: a JWT-companyId-szűrt lookup üres → fail-closed ResourceNotFoundException")
    void testValidateSufficientBalance_crossTenantRowUnreachable() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            // A (branch, currency) sor létezik az adatbázisban, de MÁS cég alatt —
            // a tenant-szűrt query ezért üres.
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.validateSufficientBalance(4L, new BigDecimal("500")))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Kassza egyenleg nem található");
            verify(cashBalanceRepository).findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID);
            verify(cashBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("getCurrentBranchBalances — lista visszaadas (FK-074 FR-1/FR-2: SZŰRT cashdesk-query)")
    void testGetCurrentBranchBalances() {
        CashBalance b1 = CashBalance.builder().currentBalance(BigDecimal.TEN).build();
        CashBalance b2 = CashBalance.builder().currentBalance(BigDecimal.ONE).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            // FK-074 (2026-08-06): a pénztári „Kassza / készlet" lista (GET /cash-balances)
            // a SZŰRT queryt használja — inaktív+nulla sorok rejtve, inaktív+nem-nulla látszik.
            when(cashBalanceRepository.findByBranchIdAndCompanyIdForCashDesk(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of(b1, b2));

            List<CashBalance> result = service.getCurrentBranchBalances();
            assertThat(result).hasSize(2);
            // A pénztári lista NEM térhet vissza a szűretlen queryre (ClosingWizard/riportoké) —
            // különben az inaktív+nulla sorok újra megjelennének a Kassza oldalon.
            verify(cashBalanceRepository).findByBranchIdAndCompanyIdForCashDesk(BRANCH_ID, COMPANY_ID);
            verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID);
        }
    }

    @Test
    @DisplayName("getBalanceByCurrency — nem letezo valuta")
    void testGetBalanceByCurrency_notFound() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            // #865: getBalanceByCurrency a WithDetails JOIN FETCH variánst használja
            // (lazy branch/currency proxy elkerülése a controller DTO-mappinghez).
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdWithDetails(BRANCH_ID, 999L, COMPANY_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getBalanceByCurrency(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("getBalanceByCurrency — cross-tenant: companyId-szűrt WithDetails üres → fail-closed ResourceNotFoundException")
    void testGetBalanceByCurrency_crossTenantRowUnreachable() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdWithDetails(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getBalanceByCurrency(4L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Kassza egyenleg nem található");
            verify(cashBalanceRepository, never()).save(any());
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
    @DisplayName("FKH-029 kieg.: getCompanyTotals a vault-kizáró queryt hívja — az értéktári könyvelési sorok nem folynak be a pénztári összesítőbe")
    void getCompanyTotals_excludesVault() {
        UUID companyId = UUID.randomUUID();
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance penztarEur = CashBalance.builder().currency(eur).currentBalance(new BigDecimal("100")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            when(cashBalanceRepository.findByCompanyIdExcludingVault(companyId))
                    .thenReturn(List.of(penztarEur));

            var totals = service.getCompanyTotals();

            // FKH-029 kieg. (FR-6 kiterjesztés): a V371 óta minden Értéktárnak van cash_balance
            // KÖNYVELÉSI sora, és a Transfer forgalmat is könyvel rá. A pénztári cégösszesítő
            // (GET /cash-balances/company-totals — TreasuryDashboard valutaszám-kártya) ezért a
            // vault+VAULT_COUNTERPARTY-kizáró queryből aggregál, különben a vault-forgalom
            // beömlene, és a /treasury/dashboard (FR-6-szűrt) számaival is szétcsúszna.
            verify(cashBalanceRepository).findByCompanyIdExcludingVault(companyId);
            verify(cashBalanceRepository, never()).findByCompanyId(companyId);
            assertThat(totals).hasSize(1);
            assertThat(totals.get(0).getCurrencyCode()).isEqualTo("EUR");
            assertThat(totals.get(0).getTotalBalance()).isEqualByComparingTo("100");
        }
    }

    @Test
    @DisplayName("FKH-029 kieg.: getCompanyCashPosition a vault-kizáró queryt hívja — a fő „Összes készletérték\" pénztár-only")
    void getCompanyCashPosition_excludesVault() {
        UUID companyId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Branch penztar = Branch.builder().id(BRANCH_ID).build();
        CashBalance hufRow = CashBalance.builder()
                .currency(huf).branch(penztar).currentBalance(new BigDecimal("1000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            when(cashBalanceRepository.findByCompanyIdExcludingVault(companyId))
                    .thenReturn(List.of(hufRow));

            var pos = service.getCompanyCashPosition();

            // A TreasuryDashboard fő számának (GET /cash-balances/company-position) forrása —
            // a /treasury/dashboard FR-6-kizárásával konzisztensen vault nélkül aggregál.
            verify(cashBalanceRepository).findByCompanyIdExcludingVault(companyId);
            verify(cashBalanceRepository, never()).findByCompanyId(companyId);
            assertThat(pos.getGrandTotalHuf()).isEqualByComparingTo("1000");
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

    // =================================================================
    // FK Batch3-followup: mutation-coverage a pénz-út metódusokra
    // (adjustBalance, setLimits, getBranchSummary, getDetailedCashPosition,
    //  getCompanyCashPosition, getCompanyTotals, getBalanceBy*) — erős
    //  asszertálással a túlélő NegateConditionals/Math/NullReturn/VoidCall mutánsok ölésére.
    // =================================================================

    @Test
    @DisplayName("adjustBalance — nem-manager → ValidationException")
    void adjustBalance_notManager_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(false);
            var req = CashBalanceService.AdjustBalanceRequest.builder()
                    .currencyId(4L).amount(new BigDecimal("100")).incoming(true).build();

            assertThatThrownBy(() -> service.adjustBalance(req))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("manager");
            verify(cashBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("adjustBalance — incoming feltöltés növeli az egyenleget és auditál")
    void adjustBalance_incoming_addsSavesAndAudits() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        Branch branch = Branch.builder().id(BRANCH_ID).name("Teszt iroda").build();
        CashBalance balance = CashBalance.builder()
                .id(10L).currency(eur).branch(branch).currentBalance(new BigDecimal("1000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("MGR001");
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));
            when(cashBalanceRepository.save(any(CashBalance.class))).thenAnswer(i -> i.getArgument(0));

            var req = CashBalanceService.AdjustBalanceRequest.builder()
                    .currencyId(4L).amount(new BigDecimal("250")).incoming(true).build();
            CashBalance result = service.adjustBalance(req);

            assertThat(result.getCurrentBalance()).isEqualByComparingTo("1250");
            verify(cashBalanceRepository).save(balance);
            verify(auditLogService).logWithDetails(
                    eq("CASH_BALANCE_ADJUST"),
                    eq("CASH_BALANCE"),
                    eq("10"),
                    eq("42"),
                    eq("MGR001"),
                    eq(BRANCH_ID.toString()),
                    eq("Teszt iroda"),
                    eq("1000"),
                    eq("1250"),
                    argThat(message -> message.contains("feltöltés")
                            && message.contains("250")
                            && message.contains("EUR")),
                    isNull());
        }
    }

    @Test
    @DisplayName("adjustBalance — kimenő levonás elég készlettel csökkenti az egyenleget és auditál")
    void adjustBalance_outgoing_sufficient_subtractsAndAudits() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        Branch branch = Branch.builder().id(BRANCH_ID).name("Teszt iroda").build();
        CashBalance balance = CashBalance.builder()
                .id(11L).currency(eur).branch(branch).currentBalance(new BigDecimal("1000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(43L);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("MGR002");
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));
            when(cashBalanceRepository.save(any(CashBalance.class))).thenAnswer(i -> i.getArgument(0));

            var req = CashBalanceService.AdjustBalanceRequest.builder()
                    .currencyId(4L).amount(new BigDecimal("300")).incoming(false).build();
            CashBalance result = service.adjustBalance(req);

            assertThat(result.getCurrentBalance()).isEqualByComparingTo("700");
            verify(cashBalanceRepository).save(balance);
            verify(auditLogService).logWithDetails(
                    eq("CASH_BALANCE_ADJUST"),
                    eq("CASH_BALANCE"),
                    eq("11"),
                    eq("43"),
                    eq("MGR002"),
                    eq(BRANCH_ID.toString()),
                    eq("Teszt iroda"),
                    eq("1000"),
                    eq("700"),
                    argThat(message -> message.contains("levonás")
                            && message.contains("300")
                            && message.contains("EUR")),
                    isNull());
        }
    }

    @Test
    @DisplayName("adjustBalance — kimenő levonás NEM elég készlettel → ValidationException (service-guard), NEM ment")
    void adjustBalance_outgoing_insufficient_throws() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance balance = CashBalance.builder()
                .currency(eur).currentBalance(new BigDecimal("100")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));

            var req = CashBalanceService.AdjustBalanceRequest.builder()
                    .currencyId(4L).amount(new BigDecimal("500")).incoming(false).build();

            assertThatThrownBy(() -> service.adjustBalance(req))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Nincs elegendő");
            assertThat(balance.getCurrentBalance()).isEqualByComparingTo("100"); // változatlan
            verify(cashBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("adjustBalance — egyenleg nem található → ResourceNotFoundException")
    void adjustBalance_notFound_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 9L, COMPANY_ID))
                    .thenReturn(Optional.empty());

            var req = CashBalanceService.AdjustBalanceRequest.builder()
                    .currencyId(9L).amount(BigDecimal.TEN).incoming(true).build();

            assertThatThrownBy(() -> service.adjustBalance(req))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("setLimits — nem-manager → ValidationException")
    void setLimits_notManager_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(false);
            var req = CashBalanceService.SetLimitsRequest.builder()
                    .currencyId(4L).minBalance(BigDecimal.ONE).build();

            assertThatThrownBy(() -> service.setLimits(req))
                    .isInstanceOf(ValidationException.class);
            verify(cashBalanceRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("setLimits — min+max beállítás, ment")
    void setLimits_minAndMax_setsAndSaves() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance balance = CashBalance.builder().currency(eur).currentBalance(BigDecimal.TEN).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));
            when(cashBalanceRepository.save(any(CashBalance.class))).thenAnswer(i -> i.getArgument(0));

            var req = CashBalanceService.SetLimitsRequest.builder()
                    .currencyId(4L).minBalance(new BigDecimal("100")).maxBalance(new BigDecimal("9000")).build();
            CashBalance result = service.setLimits(req);

            assertThat(result.getMinBalance()).isEqualByComparingTo("100");
            assertThat(result.getMaxBalance()).isEqualByComparingTo("9000");
            verify(cashBalanceRepository).save(balance);
        }
    }

    @Test
    @DisplayName("setLimits — csak min (max marad null)")
    void setLimits_onlyMin() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance balance = CashBalance.builder().currency(eur).currentBalance(BigDecimal.TEN)
                .maxBalance(new BigDecimal("5000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));
            when(cashBalanceRepository.save(any(CashBalance.class))).thenAnswer(i -> i.getArgument(0));

            var req = CashBalanceService.SetLimitsRequest.builder()
                    .currencyId(4L).minBalance(new BigDecimal("200")).build();
            CashBalance result = service.setLimits(req);

            assertThat(result.getMinBalance()).isEqualByComparingTo("200");
            assertThat(result.getMaxBalance()).isEqualByComparingTo("5000"); // érintetlen
        }
    }

    @Test
    @DisplayName("getBranchSummary — HUF-egyenleg + low/high alertek pontos számlálása")
    void getBranchSummary_countsAlerts() {
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        Currency usd = Currency.builder().id(5L).code("USD").build();
        // HUF: 500000; EUR: low (current<=min); USD: high (current>=max)
        CashBalance hufB = CashBalance.builder().currency(huf).currentBalance(new BigDecimal("500000")).build();
        CashBalance eurLow = CashBalance.builder().currency(eur).currentBalance(new BigDecimal("50"))
                .minBalance(new BigDecimal("100")).build();
        CashBalance usdHigh = CashBalance.builder().currency(usd).currentBalance(new BigDecimal("9000"))
                .maxBalance(new BigDecimal("8000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(List.of(hufB, eurLow, usdHigh));

            var summary = service.getBranchSummary();

            assertThat(summary.getTotalCurrencies()).isEqualTo(3);
            assertThat(summary.getHufBalance()).isEqualByComparingTo("500000");
            assertThat(summary.getLowBalanceAlerts()).isEqualTo(1);
            assertThat(summary.getHighBalanceAlerts()).isEqualTo(1);
            assertThat(summary.getBalances()).hasSize(3);
        }
    }

    @Test
    @DisplayName("getDetailedCashPosition — deviza árfolyammal: hufValue, midRate, dailyChange pontos")
    void getDetailedCashPosition_withRate() {
        UUID companyId = UUID.randomUUID();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        CashBalance eurB = CashBalance.builder().currency(eur).branch(branch)
                .currentBalance(new BigDecimal("100")).openingBalance(new BigDecimal("80")).build();
        // buy=400, sell=420 → mid=410; hufValue=100*410=41000; dailyChange=20
        ExchangeRate er = ExchangeRate.builder()
                .baseBuyRate(new BigDecimal("400")).baseSellRate(new BigDecimal("420")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, companyId)).thenReturn(List.of(eurB));
            when(exchangeRateRepository.findLatestRate(companyId, 4L, BRANCH_ID))
                    .thenReturn(Optional.of(er));

            var pos = service.getDetailedCashPosition();

            assertThat(pos.getItems()).hasSize(1);
            var item = pos.getItems().get(0);
            assertThat(item.getMidRate()).isEqualByComparingTo("410");
            assertThat(item.getHufValue()).isEqualByComparingTo("41000");
            assertThat(item.getDailyChange()).isEqualByComparingTo("20");
            assertThat(pos.getTotalHufValue()).isEqualByComparingTo("41000");
            assertThat(pos.getCurrencyCount()).isEqualTo(1);
        }
    }

    @Test
    @DisplayName("getDetailedCashPosition — nincs árfolyam → rate marad 1 (hufValue=balance)")
    void getDetailedCashPosition_noRate() {
        UUID companyId = UUID.randomUUID();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        CashBalance eurB = CashBalance.builder().currency(eur).branch(branch)
                .currentBalance(new BigDecimal("100")).openingBalance(new BigDecimal("100")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, companyId)).thenReturn(List.of(eurB));
            when(exchangeRateRepository.findLatestRate(companyId, 4L, BRANCH_ID))
                    .thenReturn(Optional.empty());

            var pos = service.getDetailedCashPosition();

            assertThat(pos.getItems().get(0).getMidRate()).isEqualByComparingTo("1");
            assertThat(pos.getItems().get(0).getHufValue()).isEqualByComparingTo("100");
        }
    }

    @Test
    @DisplayName("getCompanyTotals — valutánkénti összesítés több iroda azonos valutával")
    void getCompanyTotals_aggregates() {
        UUID companyId = UUID.randomUUID();
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance b1 = CashBalance.builder().currency(eur).currentBalance(new BigDecimal("1000")).build();
        CashBalance b2 = CashBalance.builder().currency(eur).currentBalance(new BigDecimal("500")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            // FKH-029 kieg.: a totals a vault-kizáró queryből aggregál (spec-váltás, ld. lentebb).
            when(cashBalanceRepository.findByCompanyIdExcludingVault(companyId)).thenReturn(List.of(b1, b2));

            var totals = service.getCompanyTotals();

            assertThat(totals).hasSize(1);
            assertThat(totals.get(0).getCurrencyCode()).isEqualTo("EUR");
            assertThat(totals.get(0).getTotalBalance()).isEqualByComparingTo("1500");
        }
    }

    @Test
    @DisplayName("getCompanyCashPosition — deviza összesítés árfolyammal + grandTotalHuf")
    void getCompanyCashPosition_withRate() {
        UUID companyId = UUID.randomUUID();
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        // Két KÜLÖNBÖZŐ iroda ugyanazzal a valutával — a CashBalance egyedi (branch,currency) kulcsú,
        // így egy valutához branchenként 1 sor tartozik → branchCount = distinct irodák száma (=2).
        Branch branch1 = Branch.builder().id(BRANCH_ID).build();
        Branch branch2 = Branch.builder().id(UUID.randomUUID()).build();
        CashBalance b1 = CashBalance.builder().currency(eur).branch(branch1).currentBalance(new BigDecimal("100")).build();
        CashBalance b2 = CashBalance.builder().currency(eur).branch(branch2).currentBalance(new BigDecimal("100")).build();
        ExchangeRate er = ExchangeRate.builder()
                .baseBuyRate(new BigDecimal("400")).baseSellRate(new BigDecimal("420")).build(); // mid=410

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            // FKH-029 kieg.: a position a vault-kizáró queryből aggregál (spec-váltás, ld. lentebb).
            when(cashBalanceRepository.findByCompanyIdExcludingVault(companyId)).thenReturn(List.of(b1, b2));
            // A production a csoport ELSŐ elemének branch-ét használja az árfolyam-lekéréshez (b1 = BRANCH_ID).
            when(exchangeRateRepository.findLatestRate(companyId, 4L, BRANCH_ID))
                    .thenReturn(Optional.of(er));

            var pos = service.getCompanyCashPosition();

            assertThat(pos.getCurrencyPositions()).hasSize(1);
            var cp = pos.getCurrencyPositions().get(0);
            assertThat(cp.getTotalBalance()).isEqualByComparingTo("200");
            assertThat(cp.getBranchCount()).isEqualTo(2);
            assertThat(cp.getHufValue()).isEqualByComparingTo("82000"); // 200*410
            assertThat(pos.getGrandTotalHuf()).isEqualByComparingTo("82000");
        }
    }

    @Test
    @DisplayName("getBalanceByCurrency — létező valuta visszaadása")
    void getBalanceByCurrency_found() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        CashBalance balance = CashBalance.builder().currency(eur).currentBalance(new BigDecimal("777")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdWithDetails(BRANCH_ID, 4L, COMPANY_ID))
                    .thenReturn(Optional.of(balance));

            CashBalance result = service.getBalanceByCurrency(4L);
            assertThat(result.getCurrentBalance()).isEqualByComparingTo("777");
        }
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
