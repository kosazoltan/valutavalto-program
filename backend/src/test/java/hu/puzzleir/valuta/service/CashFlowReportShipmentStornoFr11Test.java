package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.CashFlowReportDto;
import hu.puzzleir.valuta.dto.report.CashFlowReportRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-030 FR-11: a Pénzforgalom riport shipment-oldali SZTORNÓ-kezelése, valamint a
 * multi-tenant (companyId) izoláció bizonyítása a riport-lekérdezéseken.
 *
 * <p>Az ellenor1 (GLM-5.2) review blokkolója: a visszavont (CANCELLED) FF/UF szállítmány
 * korábban KIZÁRÓLAG az eredeti, pozitív összegével jelent meg, sztornó-ellensor nélkül —
 * így a pénzforgalmi összesítő felfelé torzult. A transfer-ág (FR-11) már helyesen képezte
 * az előjeles {@code -SZ} párt; ezek a tesztek a shipment-ág azonos viselkedését rögzítik.</p>
 *
 * <p>Docker NÉLKÜL fut: a sorképzés a repository-k mockolásával teljesen kiváltható.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CashFlowReportShipmentStornoFr11Test {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OWN_BRANCH_ID = UUID.randomUUID();
    private static final UUID PARTNER_BRANCH_ID = UUID.randomUUID();
    private static final LocalDate FROM = LocalDate.of(2026, 8, 1);
    private static final LocalDate TO = LocalDate.of(2026, 8, 31);
    private static final LocalDate REQUEST_DATE = LocalDate.of(2026, 8, 5);

    @Mock
    private TransferRepository transferRepository;
    @Mock
    private ShipmentRequestRepository shipmentRequestRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private AccessScopeService accessScopeService;

    @InjectMocks
    private CashFlowReportService service;

    @BeforeEach
    void setUp() {
        // Repo-minta (CashBalanceServiceTest): a SecurityContext explicit takarítása mindkét
        // irányban — enélkül egy másik teszt beragadt kontextusa céget cserélne alattunk.
        SecurityContextHolder.clearContext();
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("W001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(1L, COMPANY_ID, OWN_BRANCH_ID, "WORKER"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(java.util.Set.of(OWN_BRANCH_ID));
        when(transferRepository.findCashFlowReportTransfers(any(), any(), any(), any()))
                .thenReturn(List.of());
        when(branchRepository.findAllById(any())).thenReturn(List.of(partnerBranch()));
        when(currencyRepository.findAllById(any())).thenReturn(List.of(currency(1L, "EUR")));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FR-11: a sztornózott FF szállítmány EREDETI és NEGÁLT '-SZ' sort is kap")
    void cancelledShipmentProducesNegatedStornoRow() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment(ShipmentRequestStatus.CANCELLED,
                        LocalDateTime.of(2026, 8, 6, 10, 0))));

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows())
                .as("Egy tételes sztornózott szállítmány két sort ad: eredeti + sztornó")
                .hasSize(2);

        CashFlowReportRowDto original = rowByReceipt(report, "FF-2026-0001");
        CashFlowReportRowDto storno = rowByReceipt(report, "FF-2026-0001-SZ");

        assertThat(original.getHandedOverAmount())
                .as("Az eredeti sor a leszállított összeget mutatja")
                .isEqualByComparingTo("1000.00");
        assertThat(original.isStorno()).isFalse();

        assertThat(storno.getHandedOverAmount())
                .as("FR-11: a sztornó-sor ELŐJELES ellensor — enélkül a riport felfelé torzul")
                .isEqualByComparingTo("-1000.00");
        assertThat(storno.isStorno()).isTrue();
        assertThat(storno.getCurrency())
                .as("A sztornó-sor ugyanazt a valutát viszi, mint az eredeti")
                .isEqualTo("EUR");
    }

    /**
     * A javítás lényege számokban: a két sor összege NULLA. Ez az az invariáns, amit a
     * hiányzó sztornó-ág megsértett (1000 maradt a pénzforgalmi összesítőben).
     */
    @Test
    @DisplayName("FR-11: a sztornózott szállítmány NETTÓ hatása nulla a pénzforgalomra")
    void cancelledShipmentNetsToZero() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment(ShipmentRequestStatus.CANCELLED,
                        LocalDateTime.of(2026, 8, 6, 10, 0))));

        CashFlowReportDto report = service.getReport(FROM, TO);

        BigDecimal net = report.getRows().stream()
                .map(CashFlowReportRowDto::getHandedOverAmount)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        assertThat(net)
                .as("Az eredeti és a sztornó-sor kioltja egymást")
                .isEqualByComparingTo("0.00");
    }

    /**
     * Fail-closed kontroll: a NEM sztornózott szállítmány viselkedése VÁLTOZATLAN.
     * Ez bizonyítja, hogy a sztornó-ág nem képez fantom-ellensorokat élő tételekre.
     */
    @Test
    @DisplayName("FR-11 kontroll: az élő (DELIVERED) szállítmány továbbra is EGY sort ad")
    void deliveredShipmentProducesSingleRow() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment(ShipmentRequestStatus.DELIVERED, null)));

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        assertThat(report.getRows().get(0).isStorno()).isFalse();
        assertThat(report.getRows().get(0).getReceiptNumber()).isEqualTo("FF-2026-0001");
    }

    /**
     * A REJECTED (elutasítás) külön üzleti folyamat: nem tölt {@code cancelledAt}-ot, és
     * NEM sztornó. Ha valamiért mégis lenne időbélyege, a státusz-feltétel véd.
     */
    @Test
    @DisplayName("FR-11: a REJECTED szállítmány NEM kap sztornó-sort (az elutasítás nem sztornó)")
    void rejectedShipmentIsNotTreatedAsStorno() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment(ShipmentRequestStatus.REJECTED,
                        LocalDateTime.of(2026, 8, 6, 10, 0))));

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows())
                .as("Az elutasítás nem pénzmozgás-visszafordítás, ezért nincs ellensora")
                .hasSize(1);
        assertThat(report.getRows().get(0).isStorno()).isFalse();
    }

    @Test
    @DisplayName("FR-11: több valutás sztornózott szállítmány TÉTELENKÉNT kap ellensort")
    void multiCurrencyCancelledShipmentNegatesEachItem() {
        when(currencyRepository.findAllById(any()))
                .thenReturn(List.of(currency(1L, "EUR"), currency(2L, "USD")));
        ShipmentRequest shipment = shipment(ShipmentRequestStatus.CANCELLED,
                LocalDateTime.of(2026, 8, 6, 10, 0));
        shipment.setItems(List.of(
                item(1L, new BigDecimal("1000.00")),
                item(2L, new BigDecimal("250.00"))));
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment));

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows()).hasSize(4);
        assertThat(report.getRows().stream().filter(CashFlowReportRowDto::isStorno).count())
                .as("Mindkét valuta-tétel külön ellensort kap")
                .isEqualTo(2);
        BigDecimal net = report.getRows().stream()
                .map(CashFlowReportRowDto::getHandedOverAmount)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        assertThat(net).isEqualByComparingTo("0.00");
    }

    // ============================ MULTI-TENANT ============================

    /**
     * Az invariáns, aminek megsértése cégek közti adatszivárgás lenne: MINDKÉT riport-query
     * a bejelentkezett felhasználó companyId-jével hívódik — nem a kérés paraméteréből.
     */
    @Test
    @DisplayName("Multi-tenant: mindkét riport-lekérdezés a bejelentkezett cég companyId-jével fut")
    void bothRepositoryQueriesAreCompanyScoped() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of());

        service.getReport(FROM, TO);

        verify(transferRepository)
                .findCashFlowReportTransfers(eq(COMPANY_ID), any(), eq(FROM), eq(TO));
        verify(shipmentRequestRepository)
                .findCashFlowReportShipments(eq(COMPANY_ID), any(), eq(FROM), eq(TO));
    }

    /**
     * A partner-fiókok feloldása is tenant-szűrt kell legyen: idegen cég fiókja fel sem
     * oldódhat, különben a partner NEVE szivárogna át a riportba.
     */
    @Test
    @DisplayName("Multi-tenant: az idegen cégű partner-fiók NEM oldódik fel névvel")
    void foreignTenantPartnerIsNotResolved() {
        Branch foreign = Branch.builder()
                .id(PARTNER_BRANCH_ID)
                .code("PRB")
                .company(company(UUID.randomUUID()))
                .branchType(dictionary("VAULT_COUNTERPARTY"))
                .build();
        when(branchRepository.findAllById(any())).thenReturn(List.of(foreign));
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment(ShipmentRequestStatus.DELIVERED, null)));

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        assertThat(report.getRows().get(0).getPartnerCategory())
                .as("Idegen tenant partnere nem sorolható be — fail-closed 'Egyéb'")
                .isEqualTo(CashFlowReportService.CATEGORY_OTHER);
    }

    // ============================ FIXTURE ============================

    private static CashFlowReportRowDto rowByReceipt(CashFlowReportDto report, String receiptNumber) {
        return report.getRows().stream()
                .filter(r -> receiptNumber.equals(r.getReceiptNumber()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Nincs ilyen bizonylatszámú sor: " + receiptNumber));
    }

    private static ShipmentRequest shipment(ShipmentRequestStatus status, LocalDateTime cancelledAt) {
        ShipmentRequest shipment = ShipmentRequest.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .requestNumber("FF-2026-0001")
                .serialPrefix("FF")
                .requestDate(REQUEST_DATE)
                .fromBranchId(OWN_BRANCH_ID)
                .toBranchId(PARTNER_BRANCH_ID)
                .status(status)
                .build();
        shipment.setCancelledAt(cancelledAt);
        shipment.setCreatedAt(LocalDateTime.of(2026, 8, 5, 9, 0));
        shipment.setItems(List.of(item(1L, new BigDecimal("1000.00"))));
        return shipment;
    }

    private static ShipmentRequestItem item(Long currencyId, BigDecimal delivered) {
        return ShipmentRequestItem.builder()
                .currencyId(currencyId)
                .deliveredAmount(delivered)
                .build();
    }

    private static Branch partnerBranch() {
        return Branch.builder()
                .id(PARTNER_BRANCH_ID)
                .code("PRB")
                .company(company(COMPANY_ID))
                .branchType(dictionary("VAULT_COUNTERPARTY"))
                .build();
    }

    private static Company company(UUID id) {
        Company company = new Company();
        company.setId(id);
        return company;
    }

    private static Currency currency(Long id, String code) {
        Currency currency = new Currency();
        currency.setId(id);
        currency.setCode(code);
        return currency;
    }

    private static Dictionary dictionary(String code) {
        Dictionary d = new Dictionary();
        d.setCategory("BRANCH_TYPE");
        d.setCode(code);
        return d;
    }
}
