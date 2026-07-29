package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * FKH-022 kiegészítés — 12. teszt (Security Gate MEDIUM hardening, FR-K12):
 * partner-branch tenant-guard a HUF naplókönyvben.
 *
 * <p>Szimulált korrupt/legacy állapot: a bizonylat a SAJÁT tenanthez tartozik
 * (companyId-szűrt read-path helyesen visszaadja), de a from/to Branch rekord egy
 * MÁSIK tenant companyId-jével van felvéve. Elvárás: a partner-kód SEMMIKÉPP nem
 * mutathatja az idegen branch kódját.</p>
 *
 * <p>Rögzített kontraktus (döntés, 2026-07-29): a bizonylat-sor a listában MARAD
 * (számviteli teljesség — saját tenant bizonylata), de a {@code partnerCode} null
 * (a UI kötőjelet mutat), idegen adat nem kerül a DTO-ba.</p>
 *
 * <p>Szándékosan Mockito-alapú unit teszt (nem Testcontainers-IT): így a RED→GREEN
 * átmenet ezen a gépen (Docker nélkül) is futtatva bizonyítható.</p>
 */
@ExtendWith(MockitoExtension.class)
class HufDaybookPartnerTenantGuardFrK12Test {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);

    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AccessScopeService accessScopeService;
    @InjectMocks private HufDaybookService hufDaybookService;

    private final UUID ownCompanyId = UUID.randomUUID();
    private final UUID foreignCompanyId = UUID.randomUUID();

    private Branch ownBranch;
    private Branch foreignBranch;

    @BeforeEach
    void setUp() {
        ownBranch = Branch.builder()
                .id(UUID.randomUUID())
                .code("BR020")
                .name("Sajat penztar")
                .company(Company.builder().id(ownCompanyId).build())
                .build();
        // Korrupt/legacy állapot: a bizonylat saját tenant-é, de ez a branch IDEGEN tenant-é.
        foreignBranch = Branch.builder()
                .id(UUID.randomUUID())
                .code("BR999")
                .name("Idegen tenant penztara")
                .company(Company.builder().id(foreignCompanyId).build())
                .build();

        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("K12-TESZT", "test", "ROLE_ERTEKTAR");
        authentication.setDetails(new WorkerAuthenticationDetails(
                42L, ownCompanyId, ownBranch.getId(), "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(authentication);

        when(branchRepository.findByIdAndCompanyId(ownBranch.getId(), ownCompanyId))
                .thenReturn(Optional.of(ownBranch));
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        // PRE-FIX út: a "nyers" (companyId-szűrés NÉLKÜLI) batch-betöltés a korrupt idegen
        // branch-rekordot is visszaadná — a javítás után ez az út nem hívódhat (lenient).
        lenient().when(branchRepository.findAllById(any())).thenReturn(List.of(foreignBranch));
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FR-K12/a: shipment-bizonylat idegen tenant-ű partner-branch referenciával — a partner-kód nem szivárogtatja az idegen branch kódját")
    void shipmentWithForeignPartnerBranchDoesNotLeakForeignCode() {
        ShipmentRequest shipment = ShipmentRequest.builder()
                .id(UUID.randomUUID())
                .requestNumber("FF-000701")
                .companyId(ownCompanyId)
                .serialPrefix("FF")
                .serialNumber(701L)
                .fromBranchId(ownBranch.getId())
                .toBranchId(foreignBranch.getId())
                .requestedById(42L)
                .requestDate(DAY)
                .createdAt(DAY.atTime(9, 0))
                .build();
        when(shipmentRequestRepository.findHufDaybookShipmentsForDate(ownCompanyId, ownBranch.getId(), DAY))
                .thenReturn(List.of(shipment));

        HufDaybookDto daybook = hufDaybookService.getDaybook(ownBranch.getId(), DAY);

        HufDaybookRowDto row = requireRow(daybook, "FF-000701");
        assertThat(row.getPartnerCode())
                .as("Az idegen tenant branch-kódja (numerikus alakban sem) nem jelenhet meg")
                .isNotEqualTo("999");
        assertThat(row.getPartnerCode())
                .as("Az idegen tenant nyers branch-kódja nem jelenhet meg")
                .isNotEqualTo("BR999");
        assertThat(row.getPartnerCode())
                .as("Rögzített kontraktus: fel nem oldható (idegen/korrupt) partnernél a "
                        + "partnerCode null — a sor a listában marad, a UI kötőjelet mutat")
                .isNull();
    }

    @Test
    @DisplayName("FR-K12/b: transfer-bizonylat idegen tenant-ű partner-branch-csel — a partner-kód nem szivárogtatja az idegen branch kódját")
    void transferWithForeignPartnerBranchDoesNotLeakForeignCode() {
        Transfer transfer = Transfer.builder()
                .id(1L)
                .transferNumber("FF-000702")
                .companyId(ownCompanyId)
                .fromBranch(ownBranch)
                .toBranch(foreignBranch)
                .transferType(Transfer.TransferType.CASH)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(DAY)
                .transferTime(LocalTime.of(10, 0))
                .amount(new BigDecimal("100000.0000"))
                .hufValue(new BigDecimal("100000.00"))
                .direction(Transfer.TransferDirection.F)
                .createdAt(DAY.atTime(10, 0))
                .build();
        when(transferRepository.findHufDaybookTransfersForDate(ownCompanyId, ownBranch.getId(), DAY))
                .thenReturn(List.of(transfer));

        HufDaybookDto daybook = hufDaybookService.getDaybook(ownBranch.getId(), DAY);

        HufDaybookRowDto row = requireRow(daybook, "FF-000702");
        assertThat(row.getPartnerCode())
                .as("Az idegen tenant branch-kódja (numerikus alakban sem) nem jelenhet meg")
                .isNotEqualTo("999");
        assertThat(row.getPartnerCode())
                .as("Az idegen tenant nyers branch-kódja nem jelenhet meg")
                .isNotEqualTo("BR999");
        assertThat(row.getPartnerCode())
                .as("Rögzített kontraktus: idegen tenant-ű partnernél a partnerCode null — "
                        + "a sor a listában marad, idegen adat nélkül")
                .isNull();
    }

    private static HufDaybookRowDto requireRow(HufDaybookDto daybook, String receiptNumber) {
        return daybook.getRows().stream()
                .filter(r -> receiptNumber.equals(r.getReceiptNumber()))
                .findFirst()
                .orElseThrow(() -> new AssertionError(
                        "A saját tenant bizonylatának a naplóban KELL maradnia: " + receiptNumber));
    }
}
