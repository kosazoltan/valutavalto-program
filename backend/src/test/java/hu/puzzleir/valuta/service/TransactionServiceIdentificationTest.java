package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * TransactionService — 300K azonosítási limit ellenőrzés UNIT tesztek.
 *
 * NAV jogi követelmény: 300.000 Ft feletti eladási tranzakciónál ügyfél neve
 * és okmányszáma kötelező (a validateIdentification() metódus hívásának ellenőrzése
 * az executeSell()-ben).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionServiceIdentificationTest {
    @Mock private TransactionValidationService transactionValidationService;
    @Mock private PmtComplianceValidator pmtComplianceValidator;
    @Mock private WacService wacService;
    @Mock private VaultStockFlowService vaultStockFlowService;

    @InjectMocks
    private TransactionService transactionService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private DailySessionService dailySessionService;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private HandlingFeeCalculator handlingFeeCalculator;
    @Mock private AmlService amlService;
    @Mock private AmlApprovalService amlApprovalService;
    @Mock private PosTerminalService posTerminalService;
    @Mock private LicenseService licenseService;
    @Mock private TransactionCalculationService calculationService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    @BeforeEach
    void setUp() {
        // License valid stub
        org.mockito.Mockito.lenient().when(licenseService.validateLicense()).thenReturn(
                hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());
        // SecurityContext beállítása
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Napi munkamenet nyitva
        when(dailySessionService.hasOpenSession()).thenReturn(true);

        // Entitások mock-ok
        Company company = new Company();
        Branch branch = new Branch();
        Worker worker = new Worker();

        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        // Valuta: HUF, id=1 (kassza frissítéshez szükséges)
        Currency huf = new Currency();
        huf.setId(1L);
        huf.setCode("HUF");
        when(currencyRepository.findById(1L)).thenReturn(Optional.of(huf));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));

        // Valuta: EUR, id=2
        Currency eur = new Currency();
        eur.setId(2L);
        eur.setCode("EUR");
        when(currencyRepository.findById(2L)).thenReturn(Optional.of(eur));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));

        // EUR árfolyam: eladás 400 HUF/EUR
        ExchangeRate rate = ExchangeRate.builder()
                .id(1L)
                .baseBuyRate(new BigDecimal("395.00"))
                .baseSellRate(new BigDecimal("400.00"))
                .validDate(LocalDate.now())
                .build();
        when(exchangeRateService.getCurrentRate(2L)).thenReturn(rate);

        // CalculationService mock — rate validation + resolve
        when(calculationService.resolveSellRate(any(), any(), any()))
                .thenAnswer(inv -> {
                    ExchangeRate r = inv.getArgument(0);
                    BigDecimal custom = inv.getArgument(2);
                    if (custom != null) {
                        if (custom.compareTo(BigDecimal.ZERO) <= 0) {
                            throw new hu.puzzleir.valuta.exception.ValidationException(
                                "Az egyedi eladási árfolyamnak pozitívnak kell lennie!");
                        }
                        return custom;
                    }
                    return r.getBaseSellRate();
                });
        when(calculationService.resolveBuyRate(any(), any(), any()))
                .thenAnswer(inv -> {
                    ExchangeRate r = inv.getArgument(0);
                    return r.getBaseBuyRate();
                });
        when(calculationService.applySellDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.applyBuyDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
        when(calculationService.calculateDiscountAmount(any(), any())).thenReturn(BigDecimal.ZERO);

        // Kezelési díj: 0 Ft
        when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(handlingFeeCalculator.calculateSellGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));

        // Készlet elegendő
        CashBalance cashBalance = new CashBalance();
        cashBalance.setCurrentBalance(new BigDecimal("10000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(eq(BRANCH_ID), eq(2L), any()))
                .thenReturn(Optional.of(cashBalance));

        // Bizonylat szám
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("E0316-00001");

        // AML: mindig PASS
        AmlService.AmlBasicCheckResult amlOk = AmlService.AmlBasicCheckResult.builder()
                .approved(true)
                .requiresApproval(false)
                .requiresDetailedId(false)
                .build();
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlOk);

        // Transaction save visszaad egy dummy-t
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

        // Cash balance frissítés mock (findByBranchIdAndCurrencyIdAndCompanyIdForUpdate)
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(BRANCH_ID), any(), any()))
                .thenReturn(Optional.of(cashBalance));
    }

    // =====================================================================
    // executeSell — 300K feletti tranzakció, hiányzó ügyfélnév → dobjon kivételt
    // =====================================================================

    @Test
    @DisplayName("executeSell: 300K+ összeg, nincs customerName → ValidationException")
    void executeSell_above300K_missingCustomerName_throws() {
        // 800 EUR * 400 HUF/EUR = 320.000 HUF → 300K felett
        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(2L)
                .currencyAmount(new BigDecimal("800"))
                .customerName(null)
                .customerDocumentNumber("AB123456")
                .build();

        assertThatThrownBy(() -> transactionService.executeSell(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("ügyfél azonosítás kötelező");
    }

    // =====================================================================
    // executeSell — 300K feletti tranzakció, hiányzó okmányszám → dobjon kivételt
    // =====================================================================

    @Test
    @DisplayName("executeSell: 300K+ összeg, nincs documentNumber → ValidationException")
    void executeSell_above300K_missingDocumentNumber_throws() {
        // 800 EUR * 400 HUF/EUR = 320.000 HUF → 300K felett
        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(2L)
                .currencyAmount(new BigDecimal("800"))
                .customerName("Teszt Ügyfél")
                .customerDocumentNumber(null)
                .build();

        assertThatThrownBy(() -> transactionService.executeSell(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("igazolvány szám kötelező");
    }

    // =====================================================================
    // executeSell — 300K alatti tranzakció, nincs ügyfél adat → sikeres
    // =====================================================================

    @Test
    @DisplayName("executeSell: 300K alatti összeg, nincs ügyfél adat → sikeres tranzakció")
    void executeSell_below300K_noCustomer_succeeds() {
        // 100 EUR * 400 HUF/EUR = 40.000 HUF → 300K alatt
        TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                .currencyId(2L)
                .currencyAmount(new BigDecimal("100"))
                .customerName(null)
                .customerDocumentNumber(null)
                .build();

        // Nem dob kivételt
        assertThatCode(() -> transactionService.executeSell(request))
                .doesNotThrowAnyException();

        // Tranzakció mentésre kerül
        verify(transactionRepository, atLeastOnce()).save(any(Transaction.class));
    }

        @Test
        @DisplayName("executeSell: customExchangeRate megadva → egyedi árfolyam kerül alkalmazásra")
        void executeSell_customExchangeRate_applied() {
                // Legacy ARFVALT szabály: eladásnál az egyedi árfolyam ALACSONYABB kell legyen
                // az aktív eladási árfolyamnál (400.00), tehát 350.00 érvényes
                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                                .currencyId(2L)
                                .currencyAmount(new BigDecimal("100"))
                                .customExchangeRate(new BigDecimal("350.00"))
                                .build();

                transactionService.executeSell(request);

                ArgumentCaptor<Transaction> transactionCaptor = ArgumentCaptor.forClass(Transaction.class);
                verify(transactionRepository, atLeastOnce()).save(transactionCaptor.capture());
                Transaction saved = transactionCaptor.getValue();

                assertThat(saved.getExchangeRate()).isEqualByComparingTo("350.00");
                assertThat(saved.getHufAmount()).isEqualByComparingTo("35000");
        }

        @Test
        @DisplayName("executeSell: customExchangeRate <= 0 → ValidationException")
        void executeSell_customExchangeRate_nonPositive_throws() {
                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                                .currencyId(2L)
                                .currencyAmount(new BigDecimal("100"))
                                .customExchangeRate(BigDecimal.ZERO)
                                .build();

                assertThatThrownBy(() -> transactionService.executeSell(request))
                                .isInstanceOf(ValidationException.class)
                                .hasMessageContaining("egyedi eladási árfolyamnak pozitívnak kell lennie");
        }

        // =====================================================================
        // AML felsővezetői jóváhagyás bekötése (Pmt. 14/A.§(4) / MNB 14/2025 V.2.6)
        // =====================================================================

        @Test
        @DisplayName("executeSell: requiresApproval=true + érvényes engedélyező → rögzít és ENGED")
        void executeSell_requiresApproval_withValidApprover_recordsAndProceeds() {
                // AML: jóváhagyás-köteles eredmény
                AmlService.AmlBasicCheckResult needsApproval = AmlService.AmlBasicCheckResult.builder()
                                .approved(true)
                                .requiresApproval(true)
                                .approvalReason("FATF 1/a — felelős vezető jóváhagyása szükséges")
                                .requiresDetailedId(false)
                                .build();
                when(amlService.checkTransaction(any(), any(), any(), any(), any(), any()))
                                .thenReturn(needsApproval);

                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                                .currencyId(2L)
                                .currencyAmount(new BigDecimal("100"))
                                .approverWorkerId(99L)
                                .build();

                assertThatCode(() -> transactionService.executeSell(request)).doesNotThrowAnyException();

                // A jóváhagyás rögzítésre kerül az engedélyező workerId-jával, és a tranzakció elmentődik
                verify(amlApprovalService).recordSeniorApproval(eq(99L), any(), any(), any(), any(), any());
                verify(transactionRepository, atLeastOnce()).save(any(Transaction.class));
        }

        @Test
        @DisplayName("executeSell: threshold requiresManagerApproval + érvényes engedélyező → rögzít és ENGED")
        void executeSell_thresholdManagerApproval_withApprover_recordsAndProceeds() {
                // basicResult OK (requiresApproval=false, setUp default); a threshold-kapu kéri a manager-jóváhagyást
                hu.puzzleir.valuta.dto.aml.AmlCheckResult thr = hu.puzzleir.valuta.dto.aml.AmlCheckResult.builder()
                                .blocked(false)
                                .requiresManagerApproval(true)
                                .managerApprovalReason("TranzTipus 5 — vezetői jóváhagyás szükséges")
                                .build();
                when(amlService.checkAllThresholds(any(), any(), any())).thenReturn(thr);
                when(amlApprovalService.isValidSeniorApprover(99L)).thenReturn(true);

                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                                .currencyId(2L)
                                .currencyAmount(new BigDecimal("100"))
                                .customerId("CUST-1")
                                .approverWorkerId(99L)
                                .build();

                assertThatCode(() -> transactionService.executeSell(request)).doesNotThrowAnyException();
                verify(amlApprovalService).recordSeniorApproval(eq(99L), any(), any(), any(), any(), any());
        }

        @Test
        @DisplayName("executeSell: requiresApproval=true + nincs engedélyező → BLOKKOL, nem rögzít")
        void executeSell_requiresApproval_noApprover_blocks() {
                AmlService.AmlBasicCheckResult needsApproval = AmlService.AmlBasicCheckResult.builder()
                                .approved(true)
                                .requiresApproval(true)
                                .approvalReason("FATF 1/a — felelős vezető jóváhagyása szükséges")
                                .requiresDetailedId(false)
                                .build();
                when(amlService.checkTransaction(any(), any(), any(), any(), any(), any()))
                                .thenReturn(needsApproval);

                TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                                .currencyId(2L)
                                .currencyAmount(new BigDecimal("100"))
                                .approverWorkerId(null)
                                .build();

                assertThatThrownBy(() -> transactionService.executeSell(request))
                                .isInstanceOf(ValidationException.class)
                                .hasMessageContaining("jóváhagyás");
                verify(amlApprovalService, never()).recordSeniorApproval(any(), any(), any(), any(), any(), any());
        }
}


