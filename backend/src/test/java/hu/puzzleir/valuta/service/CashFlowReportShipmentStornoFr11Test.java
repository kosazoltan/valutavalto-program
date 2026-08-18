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
 * <p><b>FELÜLÍRÁS (FKH-030 kieg.):</b> az FR-11 két-soros sztornó-megjelenítését a megrendelői
 * döntés felülírta ({@code fejlesztesi-keres-ertektar-fkh030-kiegeszites-sztorno-kizaras.md}
 * §1): a sztornózott tétel egyáltalán nem szerepelhet a riportban. A lekérdezés-szintű
 * kizárás mérvadó bizonyítéka a {@code CashFlowReportStornoExclusionFkh030KiegPostgresTest}
 * (Testcontainers, valós JPQL) — a repository-k itt mockoltak, ezért a kizárás ezen a
 * szinten nem bizonyítható. A régi két-soros esetek helyett ezért az ÚJ szerződést rögzítő
 * esetek szerepelnek; a REJECTED (FR-4) és multi-tenant esetek változatlanok.</p>
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

    /**
     * FKH-030 kieg. FR-2 — ÚJ szerződés: a lekérdezés a CANCELLED szállítmányt már egyáltalán
     * nem adja vissza (query-szintű kizárás), ezért a service elé üres lista érkezik: a
     * riportban sem eredeti, sem {@code -SZ} sor nem keletkezhet. (A tényleges kizárás
     * bizonyítéka a CashFlowReportStornoExclusionFkh030KiegPostgresTest — itt a repository
     * mockolt, ezért a fix-utáni kontraktust rögzítjük.)
     */
    @Test
    @DisplayName("FKH-030 kieg. FR-2: a lekerdezes mar nem ad vissza CANCELLED szallitmanyt — a riportban semmilyen sora nincs")
    void cancelledShipmentNeverReachesTheReport() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of());

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows())
                .as("A sztornózott szállítmány a lekérdezésből kizárva — sem eredeti, sem -SZ sor")
                .isEmpty();
        assertThat(report.getRows().stream()
                .map(CashFlowReportRowDto::getReceiptNumber)
                .filter(r -> r != null && r.endsWith("-SZ")))
                .isEmpty();
    }

    /**
     * FKH-030 kieg. — a shipment-ág sztornó-feltétele {@code cancelledAt != null ÉS
     * status = CANCELLED} (CashFlowReportService). Ha egy DELIVERED szállítmányon beragadt
     * {@code cancelledAt} van, de a státusza nem CANCELLED, az NEM sztornó: pontosan egy
     * sor keletkezik, ellensor nélkül. Ez a service-ág védelme a query-kizárás mellett.
     */
    @Test
    @DisplayName("FKH-030 kieg.: beragadt cancelledAt sem kepez -SZ sort nem-CANCELLED statuszon")
    void staleCancelledAtOnDeliveredShipmentProducesSingleRow() {
        when(shipmentRequestRepository.findCashFlowReportShipments(any(), any(), any(), any()))
                .thenReturn(List.of(shipment(ShipmentRequestStatus.DELIVERED,
                        LocalDateTime.of(2026, 8, 6, 10, 0))));

        CashFlowReportDto report = service.getReport(FROM, TO);

        assertThat(report.getRows())
                .as("Nem-CANCELLED státuszon a beragadt cancelledAt nem sztornó-jel")
                .hasSize(1);
        assertThat(report.getRows().get(0).isStorno()).isFalse();
        assertThat(report.getRows().get(0).getReceiptNumber()).isEqualTo("FF-2026-0001");
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
