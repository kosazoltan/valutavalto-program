package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
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
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * G3-G4 Sprint 6 — PEP + Jogcím nyilatkozat tesztek
 *
 * Tesztelési területek:
 * 1. BUY/SELL sourceOfFunds + customerIsPep → DB-be menti (TransactionService unit)
 * 2. 300k threshold: 299.999 NEM aktivál, 300.000 IGEN (ReceiptGeneratorService)
 * 3. ESC/POS: PEP + Jogcím szekciók megjelennek a bizonylaton
 * 4. Negatív eset: NULL mezők → customerIsPep=FALSE, sourceOfFunds=NULL
 * 5. TransactionMapper: DTO → inner request mezők átvitele
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PepSourceOfFundsTest {

    // ============ TRANSACTION SERVICE UNIT TESTS ============

    @Nested
    @DisplayName("TransactionService — sourceOfFunds + customerIsPep DB mentés")
    class TransactionServicePepTests {

        private static final UUID COMPANY_ID = UUID.randomUUID();
        private static final UUID BRANCH_ID  = UUID.randomUUID();
        private static final Long WORKER_ID  = 11L;
        private static final Long HUF_ID     = 1L;
        private static final Long EUR_ID     = 4L; // EUR=4 prod ID

        @Mock private WacService wacService;
        @Mock private VaultStockFlowService vaultStockFlowService;
        @InjectMocks private TransactionService transactionService;

        @Mock private TransactionValidationService transactionValidationService;
        @Mock private PmtComplianceValidator pmtComplianceValidator;
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
    @Mock private LicenseService licenseService;
        @Mock private PosTerminalService posTerminalService;
        @Mock private TransactionCalculationService calculationService;
        @Mock private TransactionReversalService reversalService;
        @Mock private TransactionConversionService conversionService;
        @Mock private TransactionMultiLineService multiLineService;

        private Company company;
        private Branch branch;
        private Currency eur;
        private Currency huf;

        @BeforeEach
        void setUp() {
        org.mockito.Mockito.lenient().when(licenseService.validateLicense()).thenReturn(hu.puzzleir.valuta.dto.license.LicenseStatusResponse.builder().status("VALID").build());
            WorkerAuthenticationDetails details =
                    new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
            TestingAuthenticationToken auth =
                    new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
            auth.setDetails(details);
            SecurityContextHolder.getContext().setAuthentication(auth);

            when(dailySessionService.hasOpenSession()).thenReturn(true);

            company = new Company();
            company.setId(COMPANY_ID);
            branch = new Branch();
            branch.setId(BRANCH_ID);
            branch.setCompany(company);
            Worker worker = new Worker();

            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

            huf = currency(HUF_ID, "HUF");
            eur = currency(EUR_ID, "EUR");
            lenient().when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
            lenient().when(currencyRepository.findById(HUF_ID)).thenReturn(Optional.of(huf));
            lenient().when(currencyRepository.findById(EUR_ID)).thenReturn(Optional.of(eur));
            lenient().when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));

            ExchangeRate rate = rate(eur, "395.00", "400.00");
            when(exchangeRateService.getCurrentRate(EUR_ID)).thenReturn(rate);

            when(calculationService.resolveBuyRate(any(), any(), any()))
                    .thenAnswer(inv -> ((ExchangeRate) inv.getArgument(0)).getBaseBuyRate());
            when(calculationService.resolveSellRate(any(), any(), any()))
                    .thenAnswer(inv -> ((ExchangeRate) inv.getArgument(0)).getBaseSellRate());
            when(calculationService.applyBuyDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
            when(calculationService.applySellDiscount(any(), any())).thenAnswer(inv -> inv.getArgument(0));
            when(calculationService.calculateDiscountAmount(any(), any())).thenReturn(BigDecimal.ZERO);

            when(handlingFeeCalculator.calculate(any(), any(), any(), any())).thenReturn(BigDecimal.ZERO);
            when(handlingFeeCalculator.calculateBuyGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));
            when(handlingFeeCalculator.calculateSellGross(any(), any())).thenAnswer(inv -> inv.getArgument(0));

            when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, EUR_ID, COMPANY_ID))
                    .thenReturn(Optional.of(balance(branch, eur, "1000")));
            when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(BRANCH_ID, HUF_ID, COMPANY_ID))
                    .thenReturn(Optional.of(balance(branch, huf, "10000000")));

            AmlService.AmlBasicCheckResult amlOk = AmlService.AmlBasicCheckResult.builder()
                    .approved(true)
                    .requiresApproval(false)
                    .requiresDetailedId(false)
                    .build();
            when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(amlOk);
        }

        // ---- BUY ----

        @Test
        @DisplayName("BUY: sourceOfFunds + customerIsPep=true → Transaction-ban megjelenik")
        void buy_pepAndSourceOfFunds_savedToTransaction() {
            // 300k+ Ft: 1000 EUR * 395 ≈ 395.000 Ft
            TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("1000"))
                    .customerName("Teszt Ügyfél")
                    .customerDocumentNumber("123456AB")
                    .customerAddress("Budapest, Teszt u. 1.")
                    .sourceOfFunds("Munkabér")
                    .customerIsPep(true)
                    .build();

            Transaction result = transactionService.executeBuy(request);

            assertThat(result).isNotNull();
            assertThat(result.getSourceOfFunds()).isEqualTo("Munkabér");
            assertThat(result.getCustomerIsPep()).isTrue();
        }

        @Test
        @DisplayName("BUY: customerIsPep=false → FALSE menti, nem NULL")
        void buy_pepFalse_savedAsFalse() {
            TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("1000"))
                    .customerName("Teszt Ügyfél")
                    .customerDocumentNumber("123456AB")
                    .customerAddress("Budapest, Teszt u. 1.")
                    .sourceOfFunds("Megtakarítás")
                    .customerIsPep(false)
                    .build();

            Transaction result = transactionService.executeBuy(request);

            assertThat(result.getCustomerIsPep()).isFalse();
            assertThat(result.getSourceOfFunds()).isEqualTo("Megtakarítás");
        }

        @Test
        @DisplayName("BUY: NULL customerIsPep → FALSE (Boolean.TRUE.equals védelem)")
        void buy_nullPep_savedAsFalse() {
            TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("10"))
                    .customerIsPep(null)
                    .build();

            Transaction result = transactionService.executeBuy(request);

            assertThat(result.getCustomerIsPep()).isFalse();
            assertThat(result.getSourceOfFunds()).isNull();
        }

        @Test
        @DisplayName("BUY: NULL sourceOfFunds → NULL mentve (nem üres string)")
        void buy_nullSourceOfFunds_savedAsNull() {
            TransactionService.BuyRequest request = TransactionService.BuyRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("10"))
                    .sourceOfFunds(null)
                    .customerIsPep(false)
                    .build();

            Transaction result = transactionService.executeBuy(request);

            assertThat(result.getSourceOfFunds()).isNull();
        }

        // ---- SELL ----

        @Test
        @DisplayName("SELL: sourceOfFunds + customerIsPep=true → Transaction-ban megjelenik")
        void sell_pepAndSourceOfFunds_savedToTransaction() {
            // 300k+ Ft: 1000 EUR * 400 = 400.000 Ft
            TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("1000"))
                    .customerName("Teszt Ügyfél")
                    .customerDocumentNumber("123456AB")
                    .customerAddress("Budapest, Teszt u. 1.")
                    .sourceOfFunds("Ingatlan eladás")
                    .customerIsPep(true)
                    .build();

            Transaction result = transactionService.executeSell(request);

            assertThat(result).isNotNull();
            assertThat(result.getSourceOfFunds()).isEqualTo("Ingatlan eladás");
            assertThat(result.getCustomerIsPep()).isTrue();
        }

        @Test
        @DisplayName("SELL: NULL customerIsPep → FALSE (NULL-safe)")
        void sell_nullPep_savedAsFalse() {
            TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("10"))
                    .customerIsPep(null)
                    .build();

            Transaction result = transactionService.executeSell(request);

            assertThat(result.getCustomerIsPep()).isFalse();
        }

        @Test
        @DisplayName("SELL: sourceOfFunds mentve → sourceOfFunds mező helyes")
        void sell_sourceOfFunds_savedToTransaction() {
            TransactionService.SellRequest request = TransactionService.SellRequest.builder()
                    .currencyId(EUR_ID)
                    .currencyAmount(new BigDecimal("1000"))
                    .customerName("Teszt Ügyfél")
                    .customerDocumentNumber("123456AB")
                    .customerAddress("Budapest, Teszt u. 1.")
                    .sourceOfFunds("Örökség")
                    .customerIsPep(false)
                    .build();

            Transaction result = transactionService.executeSell(request);

            assertThat(result.getSourceOfFunds()).isEqualTo("Örökség");
            assertThat(result.getCustomerIsPep()).isFalse();
        }

        private Currency currency(Long id, String code) {
            Currency c = new Currency();
            c.setId(id);
            c.setCode(code);
            c.setName(code);
            return c;
        }

        private ExchangeRate rate(Currency currency, String buyRate, String sellRate) {
            ExchangeRate r = new ExchangeRate();
            r.setCurrency(currency);
            r.setValidDate(LocalDate.now());
            r.setValidTime(LocalTime.NOON);
            r.setBaseBuyRate(new BigDecimal(buyRate));
            r.setBaseSellRate(new BigDecimal(sellRate));
            return r;
        }

        private CashBalance balance(Branch branch, Currency currency, String amount) {
            CashBalance b = new CashBalance();
            b.setBranch(branch);
            b.setCompany(branch.getCompany());
            b.setCurrency(currency);
            b.setCurrentBalance(new BigDecimal(amount));
            return b;
        }
    }

    // ============ RECEIPT GENERATOR SERVICE — 300K THRESHOLD ============

    @Nested
    @DisplayName("ReceiptGeneratorService — 300k threshold + PEP/Jogcím blokk")
    class ReceiptGeneratorPepTests {

        @InjectMocks private ReceiptGeneratorService service;

        @Mock private TransactionRepository transactionRepository;
        @Mock private ReceiptPdfService receiptPdfService;
        @Mock private EscPosReceiptService escPosReceiptService;

        @BeforeEach
        void setUpMocks() {
            byte[] fakePdf = "%PDF-1.4 fake".getBytes(java.nio.charset.StandardCharsets.UTF_8);
            lenient().when(receiptPdfService.generatePdf(any())).thenReturn(fakePdf);
            byte[] fakeEscPos = "\u001B@ESCPOS\n".getBytes(java.nio.charset.StandardCharsets.UTF_8);
            lenient().when(escPosReceiptService.generateBuyReceipt(any())).thenReturn(fakeEscPos);
            lenient().when(escPosReceiptService.generateSellReceipt(any())).thenReturn(fakeEscPos);
        }

        // ---- 300k threshold ----

        @Test
        @DisplayName("applyPepDeclarationIfNeeded: 299.999 Ft → PEP blokk NEM aktiválódik")
        void pepDeclaration_below300k_notActivated() {
            Transaction tx = txWith(new BigDecimal("299999"), false, null);

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applyPepDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresPepDeclaration()).isFalse();
        }

        @Test
        @DisplayName("applyPepDeclarationIfNeeded: 300.000 Ft → PEP blokk aktiválódik")
        void pepDeclaration_exactly300k_activated() {
            Transaction tx = txWith(new BigDecimal("300000"), false, null);

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applyPepDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresPepDeclaration()).isTrue();
        }

        @Test
        @DisplayName("applyPepDeclarationIfNeeded: 300.000 Ft, isPep=true → szöveg 'kiemelt közszereplő'")
        void pepDeclaration_300k_isPepTrue_textContainsPep() {
            Transaction tx = txWith(new BigDecimal("400000"), true, null);

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applyPepDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresPepDeclaration()).isTrue();
            assertThat(data.getPepStatusText()).contains("kiemelt közszereplő");
        }

        @Test
        @DisplayName("applyPepDeclarationIfNeeded: 300.000 Ft, isPep=false → szöveg 'Nem közszereplő'")
        void pepDeclaration_300k_isPepFalse_textNotPep() {
            Transaction tx = txWith(new BigDecimal("350000"), false, null);

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applyPepDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresPepDeclaration()).isTrue();
            assertThat(data.getPepStatusText()).contains("Nem közszereplő");
        }

        @Test
        @DisplayName("applySourceDeclarationIfNeeded: 299.999 Ft → Jogcím blokk NEM aktiválódik")
        void sourceDeclaration_below300k_notActivated() {
            Transaction tx = txWith(new BigDecimal("299999"), false, "Munkabér");

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applySourceDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresSourceDeclaration()).isFalse();
        }

        @Test
        @DisplayName("applySourceDeclarationIfNeeded: 300.000 Ft → Jogcím blokk aktiválódik")
        void sourceDeclaration_exactly300k_activated() {
            Transaction tx = txWith(new BigDecimal("300000"), false, "Munkabér");

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applySourceDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresSourceDeclaration()).isTrue();
            assertThat(data.getSourceOfFunds()).isEqualTo("Munkabér");
        }

        @Test
        @DisplayName("applySourceDeclarationIfNeeded: 300.000 Ft, NULL sourceOfFunds → blokk aktív, forrás NULL")
        void sourceDeclaration_300k_nullSource_blockActivatedSourceNull() {
            Transaction tx = txWith(new BigDecimal("300000"), false, null);

            ReceiptData.ReceiptDataBuilder builder = ReceiptData.builder();
            service.applySourceDeclarationIfNeeded(builder, tx);
            ReceiptData data = builder.build();

            assertThat(data.getRequiresSourceDeclaration()).isTrue();
            assertThat(data.getSourceOfFunds()).isNull();
        }

        @Test
        @DisplayName("generateBuyReceipt: 300k+ tx → requiresPepDeclaration=true + requiresSourceDeclaration=true")
        void generateBuyReceipt_highValue_pepAndSourceBlocksPresent() {
            Transaction tx = txWith(new BigDecimal("400000"), true, "Befektetési hozam");
            tx.setTransactionType(TransactionType.BUY);

            ReceiptData result = service.generateBuyReceipt(tx);

            assertThat(result.getRequiresPepDeclaration()).isTrue();
            assertThat(result.getRequiresSourceDeclaration()).isTrue();
            assertThat(result.getSourceOfFunds()).isEqualTo("Befektetési hozam");
            assertThat(result.getPepStatusText()).contains("kiemelt közszereplő");
        }

        @Test
        @DisplayName("generateSellReceipt: 300k+ tx → requiresPepDeclaration=true + requiresSourceDeclaration=true")
        void generateSellReceipt_highValue_pepAndSourceBlocksPresent() {
            Transaction tx = txWith(new BigDecimal("500000"), false, "Megtakarítás");
            tx.setTransactionType(TransactionType.SELL);

            ReceiptData result = service.generateSellReceipt(tx);

            assertThat(result.getRequiresPepDeclaration()).isTrue();
            assertThat(result.getRequiresSourceDeclaration()).isTrue();
            assertThat(result.getPepStatusText()).contains("Nem közszereplő");
        }

        @Test
        @DisplayName("generateBuyReceipt: 299.999 Ft tx → PEP + Jogcím blokkok NEM aktívak")
        void generateBuyReceipt_lowValue_noPepNoSourceBlocks() {
            Transaction tx = txWith(new BigDecimal("299999"), false, "Munkabér");
            tx.setTransactionType(TransactionType.BUY);

            ReceiptData result = service.generateBuyReceipt(tx);

            assertThat(result.getRequiresPepDeclaration()).isFalse();
            assertThat(result.getRequiresSourceDeclaration()).isFalse();
        }

        private Transaction txWith(BigDecimal hufAmount, boolean isPep, String sourceOfFunds) {
            return Transaction.builder()
                    .receiptNumber("V-001")
                    .transactionType(TransactionType.BUY)
                    .currencyAmount(new BigDecimal("1000"))
                    .exchangeRate(new BigDecimal("395.00"))
                    .hufAmount(hufAmount)
                    .customerName("Teszt Ügyfél")
                    .customerDocumentNumber("123456AB")
                    .customerIsPep(isPep)
                    .sourceOfFunds(sourceOfFunds)
                    .build();
        }
    }

    // ============ ESC/POS — PEP + Jogcím szekciók bizonylaton ============

    @Nested
    @DisplayName("EscPosReceiptService — PEP + Jogcím szekciók megjelennek")
    class EscPosPepTests {

        private EscPosReceiptService service;

        @BeforeEach
        void setUp() {
            SystemParameterService mockSps = Mockito.mock(SystemParameterService.class);
            Mockito.lenient().when(mockSps.getValue(Mockito.anyString(), Mockito.anyString()))
                    .thenAnswer(inv -> inv.getArgument(1));
            service = new EscPosReceiptService(mockSps);
        }

        private ReceiptData buildReceiptData(boolean requiresPep, String pepText,
                                              boolean requiresSource, String sourceOfFunds) {
            return ReceiptData.builder()
                    .receiptNumber("V-260405-0001")
                    .receiptType("BUY")
                    .companyName("Exclusive Best Change Zrt.")
                    .branchName("Pécs – Főiroda")
                    .workerName("Pénztáros Péter")
                    .currencyCode("EUR")
                    .foreignAmount(new BigDecimal("1000"))
                    .rate(new BigDecimal("395.00"))
                    .hufAmount(new BigDecimal("395000"))
                    .customerName("Teszt Ügyfél")
                    .requiresPepDeclaration(requiresPep)
                    .pepStatusText(pepText)
                    .requiresSourceDeclaration(requiresSource)
                    .sourceOfFunds(sourceOfFunds)
                    .build();
        }

        @Test
        @DisplayName("generateBuyReceipt: requiresPepDeclaration=true → PEP státusz szöveg megjelenik az ügyfél szekcióban")
        void pepDeclarationSectionPresent_inBuyReceipt() {
            ReceiptData data = buildReceiptData(true, "Nem közszereplő", false, null);
            byte[] bytes = service.generateBuyReceipt(data);
            String content = new String(bytes, java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).containsIgnoringCase("közszereplő");
        }

        @Test
        @DisplayName("generateBuyReceipt: customerIsPep=true → 'kiemelt közszereplő' szöveg megjelenik")
        void pepDeclarationIsPep_textContainsPep() {
            ReceiptData data = buildReceiptData(true, "Az ügyfél kiemelt közszereplő", false, null);
            byte[] bytes = service.generateBuyReceipt(data);
            String content = new String(bytes, java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).containsIgnoringCase("kiemelt közszereplő");
        }

        @Test
        @DisplayName("generateBuyReceipt: requiresSourceDeclaration=true → 'JOGCÍM NYILATKOZAT' megjelenik")
        void sourceDeclarationSectionPresent_inBuyReceipt() {
            ReceiptData data = buildReceiptData(false, null, true, "Munkabér");
            byte[] bytes = service.generateBuyReceipt(data);
            String content = new String(bytes, java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).containsIgnoringCase("JOGCÍM NYILATKOZAT");
            assertThat(content).contains("Munkabér");
        }

        @Test
        @DisplayName("generateSellReceipt: PEP + Jogcím → PEP inline + JOGCÍM szekció megjelenik")
        void pepAndSourceSections_inSellReceipt() {
            ReceiptData data = buildReceiptData(true, "Az ügyfél kiemelt közszereplő",
                    true, "Ingatlan eladás");
            byte[] bytes = service.generateSellReceipt(data);
            String content = new String(bytes, java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).containsIgnoringCase("kiemelt közszereplő");
            assertThat(content).containsIgnoringCase("JOGCÍM NYILATKOZAT");
            assertThat(content).contains("Ingatlan eladás");
        }

        @Test
        @DisplayName("generateBuyReceipt: requiresPepDeclaration=false → 'KÖZSZEREPLŐI NYILATKOZAT' NEM jelenik meg")
        void pepDeclarationAbsent_whenNotRequired() {
            ReceiptData data = buildReceiptData(false, null, false, null);
            byte[] bytes = service.generateBuyReceipt(data);
            String content = new String(bytes, java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).doesNotContainIgnoringCase("KÖZSZEREPLŐI NYILATKOZAT");
            assertThat(content).doesNotContainIgnoringCase("JOGCÍM NYILATKOZAT");
        }

        @Test
        @DisplayName("generateBuyReceipt: Jogcím NULL sourceOfFunds → 'Pénzeszközöm forrása' sor NEM jelenik meg")
        void sourceDeclaration_nullSource_noSourceLine() {
            ReceiptData data = buildReceiptData(false, null, true, null);
            byte[] bytes = service.generateBuyReceipt(data);
            String content = new String(bytes, java.nio.charset.Charset.forName("Cp852"));

            // A blokk megjelenik de a forrás sor nem
            assertThat(content).doesNotContain("Pénzeszközöm forrása");
        }

        // ---- Batch2-D (2026-06-12): legacy Jogcimnyilatkozat teljes elem-készlete ----

        @Test
        @DisplayName("Batch2-D: Jogcím blokk → 5 munkanapos klauzula + dedikált ügyfél-aláírás megjelenik")
        void sourceDeclaration_containsFiveDayClauseAndCustomerSignature() {
            ReceiptData data = buildReceiptData(false, null, true, "Munkabér");
            String content = new String(service.generateBuyReceipt(data),
                    java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).contains("Tudomásom van arról, hogy 5 (öt)");
            assertThat(content).contains("eredő kár engem terhel.");
            assertThat(content).contains("ügyfél aláírása");
        }

        @Test
        @DisplayName("Batch2-D: customerIsPep=true + minőség → első személyű PEP-nyilatkozat a Jogcím blokkban")
        void sourceDeclaration_firstPersonPepWithKind() {
            ReceiptData data = ReceiptData.builder()
                    .receiptNumber("V-260405-0002")
                    .receiptType("BUY")
                    .companyName("Exclusive Best Change Zrt.")
                    .currencyCode("EUR")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Teszt Ügyfél")
                    .requiresSourceDeclaration(true)
                    .customerIsPep(true)
                    .customerPepKind("országgyűlési / önkormányzati képviselő")
                    .build();
            String content = new String(service.generateBuyReceipt(data),
                    java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).contains("Kiemelt közszereplő (vagyok),");
            assertThat(content).contains("mint: országgyűlési / önkormányzati képviselő");
        }

        @Test
        @DisplayName("Batch2-D: customerIsPep=false → 'Nem (vagyok) kiemelt közszereplő.' a Jogcím blokkban")
        void sourceDeclaration_firstPersonNotPep() {
            ReceiptData data = ReceiptData.builder()
                    .receiptNumber("V-260405-0003")
                    .receiptType("BUY")
                    .companyName("Exclusive Best Change Zrt.")
                    .currencyCode("EUR")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Teszt Ügyfél")
                    .requiresSourceDeclaration(true)
                    .customerIsPep(false)
                    .build();
            String content = new String(service.generateBuyReceipt(data),
                    java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).contains("Nem (vagyok) kiemelt közszereplő.");
        }

        @Test
        @DisplayName("Batch3-C (V325): jogi személy blokk — cég-adatok + megbízott + tényleges tulajdonosok a legacy sorrendben")
        void legalEntityBlockPrinted() {
            ReceiptData data = ReceiptData.builder()
                    .receiptNumber("V-260405-0005")
                    .receiptType("BUY")
                    .companyName("Exclusive Best Change Zrt.")
                    .currencyCode("EUR")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Kiss Géza")
                    .customerAddress("Szeged, Fő u. 1.")
                    .requiresLegalEntityBlock(true)
                    .legalEntityName("Teszt Kft.")
                    .legalEntitySeat("6722 Szeged, Tisza L. krt 57.")
                    .legalEntityTaxNumber("12345678-2-06")
                    .legalDeedNumber("06-09-123456")
                    .legalRepresentativeName("Kiss Géza")
                    .beneficialOwners(java.util.List.of(
                            hu.puzzleir.valuta.dto.transaction.BeneficialOwnerDto.builder()
                                    .name("Nagy Béla").address("Szeged, Ady tér 2.")
                                    .birthPlace("Szeged").birthDate("1980.01.01")
                                    .nationality("magyar")
                                    .interestNature("tulajdonos").interestExtent("50%")
                                    .isPep(false).build(),
                            hu.puzzleir.valuta.dto.transaction.BeneficialOwnerDto.builder()
                                    .name("Kovács Pál").interestExtent("50%").isPep(true).build()))
                    .build();
            String content = new String(service.generateBuyReceipt(data),
                    java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).contains("Jogi személy neve:");
            assertThat(content).contains("Teszt Kft.");
            assertThat(content).contains("Jogi személy székhelye:");
            assertThat(content).contains("Okiratszám: 06-09-123456");
            assertThat(content).contains("Adószám: 12345678-2-06");
            assertThat(content).contains("Megbízott neve:");
            assertThat(content).contains("Tényleges tulajdonosok adatai:");
            assertThat(content).contains("1. tulajdonos:");
            assertThat(content).contains("Nagy Béla");
            assertThat(content).contains("2. tulajdonos:");
            assertThat(content).contains("A tulaj közszereplő");
            assertThat(content).contains("Nem közszereplő");
        }

        @Test
        @DisplayName("Batch3-C: jogi blokk NEM jelenik meg, ha requiresLegalEntityBlock=false")
        void legalEntityBlockAbsentWhenNotRequired() {
            ReceiptData data = buildReceiptData(false, null, true, "Munkabér");
            String content = new String(service.generateBuyReceipt(data),
                    java.nio.charset.Charset.forName("Cp852"));
            assertThat(content).doesNotContain("Jogi személy neve:");
            assertThat(content).doesNotContain("Tényleges tulajdonosok");
        }

        @Test
        @DisplayName("Batch2-D: orosz állampolgár EUR-ELADÁS 300k+ → kétnyelvű NYILATKOZAT/DECLARATION")
        void russianDeclaration_presentOnSellEurRussian300k() {
            ReceiptData data = ReceiptData.builder()
                    .receiptNumber("V-260405-0004")
                    .receiptType("SELL")
                    .companyName("Exclusive Best Change Zrt.")
                    .currencyCode("EUR")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Ivanov Ivan")
                    .customerNationality("orosz")
                    .build();
            String content = new String(service.generateSellReceipt(data),
                    java.nio.charset.Charset.forName("Cp852"));

            assertThat(content).contains("NYILATKOZAT/DECLARATION");
            assertThat(content).contains("személyes használatra váltottam");
            assertThat(content).contains("for my personal usage");
        }

        @Test
        @DisplayName("Batch2-D: orosz nyilatkozat NEM jelenik meg BUY-nál / nem-EUR-nál / magyar ügyfélnél")
        void russianDeclaration_absentWhenNotTriggered() {
            // BUY (a pénztár vesz) — nincs
            ReceiptData buy = ReceiptData.builder()
                    .receiptType("BUY").currencyCode("EUR")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Ivanov Ivan").customerNationality("orosz")
                    .receiptNumber("V-1").companyName("X").build();
            assertThat(new String(service.generateBuyReceipt(buy),
                    java.nio.charset.Charset.forName("Cp852")))
                    .doesNotContain("NYILATKOZAT/DECLARATION");
            // SELL, de USD — nincs
            ReceiptData usd = ReceiptData.builder()
                    .receiptType("SELL").currencyCode("USD")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Ivanov Ivan").customerNationality("orosz")
                    .receiptNumber("V-2").companyName("X").build();
            assertThat(new String(service.generateSellReceipt(usd),
                    java.nio.charset.Charset.forName("Cp852")))
                    .doesNotContain("NYILATKOZAT/DECLARATION");
            // SELL EUR, de magyar — nincs
            ReceiptData hun = ReceiptData.builder()
                    .receiptType("SELL").currencyCode("EUR")
                    .hufAmount(new BigDecimal("400000"))
                    .customerName("Kiss Géza").customerNationality("Magyar")
                    .receiptNumber("V-3").companyName("X").build();
            assertThat(new String(service.generateSellReceipt(hun),
                    java.nio.charset.Charset.forName("Cp852")))
                    .doesNotContain("NYILATKOZAT/DECLARATION");
            // SELL EUR orosz, de 300k ALATT — nincs
            ReceiptData low = ReceiptData.builder()
                    .receiptType("SELL").currencyCode("EUR")
                    .hufAmount(new BigDecimal("299999"))
                    .customerName("Ivanov Ivan").customerNationality("orosz")
                    .receiptNumber("V-4").companyName("X").build();
            assertThat(new String(service.generateSellReceipt(low),
                    java.nio.charset.Charset.forName("Cp852")))
                    .doesNotContain("NYILATKOZAT/DECLARATION");
        }
    }

    // ============ TRANSACTION MAPPER — DTO → inner request ============

    @Nested
    @DisplayName("TransactionMapper — sourceOfFunds + customerIsPep átvitele")
    class TransactionMapperPepTests {

        private final TransactionMapper mapper = new TransactionMapper();

        @Test
        @DisplayName("toBuyRequest: sourceOfFunds + customerIsPep átmásolódik")
        void toBuyRequest_pepAndSourceCopied() {
            hu.puzzleir.valuta.dto.transaction.BuyRequestDto dto =
                    hu.puzzleir.valuta.dto.transaction.BuyRequestDto.builder()
                            .currencyId(4L)
                            .currencyAmount(new BigDecimal("1000"))
                            .sourceOfFunds("Munkabér")
                            .customerIsPep(true)
                            .build();

            TransactionService.BuyRequest request = mapper.toBuyRequest(dto);

            assertThat(request.getSourceOfFunds()).isEqualTo("Munkabér");
            assertThat(request.getCustomerIsPep()).isTrue();
        }

        @Test
        @DisplayName("toSellRequest: sourceOfFunds + customerIsPep átmásolódik")
        void toSellRequest_pepAndSourceCopied() {
            hu.puzzleir.valuta.dto.transaction.SellRequestDto dto =
                    hu.puzzleir.valuta.dto.transaction.SellRequestDto.builder()
                            .currencyId(4L)
                            .currencyAmount(new BigDecimal("500"))
                            .sourceOfFunds("Örökség")
                            .customerIsPep(false)
                            .build();

            TransactionService.SellRequest request = mapper.toSellRequest(dto);

            assertThat(request.getSourceOfFunds()).isEqualTo("Örökség");
            assertThat(request.getCustomerIsPep()).isFalse();
        }

        @Test
        @DisplayName("toBuyRequest: NULL mezők → NULL/false átmásolódik")
        void toBuyRequest_nullFields_copiedAsNull() {
            hu.puzzleir.valuta.dto.transaction.BuyRequestDto dto =
                    hu.puzzleir.valuta.dto.transaction.BuyRequestDto.builder()
                            .currencyId(4L)
                            .currencyAmount(new BigDecimal("10"))
                            .sourceOfFunds(null)
                            .customerIsPep(null)
                            .build();

            TransactionService.BuyRequest request = mapper.toBuyRequest(dto);

            assertThat(request.getSourceOfFunds()).isNull();
            assertThat(request.getCustomerIsPep()).isNull();
        }

        @Test
        @DisplayName("toSellRequest: NULL mezők → NULL átmásolódik")
        void toSellRequest_nullFields_copiedAsNull() {
            hu.puzzleir.valuta.dto.transaction.SellRequestDto dto =
                    hu.puzzleir.valuta.dto.transaction.SellRequestDto.builder()
                            .currencyId(4L)
                            .currencyAmount(new BigDecimal("10"))
                            .sourceOfFunds(null)
                            .customerIsPep(null)
                            .build();

            TransactionService.SellRequest request = mapper.toSellRequest(dto);

            assertThat(request.getSourceOfFunds()).isNull();
            assertThat(request.getCustomerIsPep()).isNull();
        }
    }
}

