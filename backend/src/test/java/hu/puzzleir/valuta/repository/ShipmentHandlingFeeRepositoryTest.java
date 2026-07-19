package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class ShipmentHandlingFeeRepositoryTest {

    @Autowired
    private ShipmentHandlingFeeRepository feeRepository;

    @Autowired
    private ShipmentRequestRepository shipmentRepository;


    @Test
    @DisplayName("Kezelési költség menthető és tenant-szkópoltan visszaolvasható")
    void saveAndFindByShipmentRequestIdAndCompanyId_roundTrip() {
        UUID companyId = UUID.randomUUID();
        ShipmentRequest shipment = shipmentRepository.save(request("KK-REPO-001", companyId));

        ShipmentHandlingFee saved = feeRepository.save(ShipmentHandlingFee.builder()
                .companyId(companyId)
                .shipmentRequestId(shipment.getId())
                .sourceBranchId(shipment.getFromBranchId())
                .hufAmount(new BigDecimal("125000.00"))
                .calculatedFee(new BigDecimal("625.00"))
                .status(ShipmentRequestStatus.DRAFT)
                // TestApplication nem kapcsolja be a JPA auditingot; production-ben @CreatedDate tölti.
                .createdAt(LocalDateTime.of(2026, 7, 14, 8, 5))
                .build());

        assertThat(feeRepository.findByShipmentRequestIdAndCompanyId(shipment.getId(), companyId))
                .contains(saved)
                .get()
                .satisfies(found -> {
                    assertThat(found.getCompanyId()).isEqualTo(companyId);
                    assertThat(found.getShipmentRequestId()).isEqualTo(shipment.getId());
                    assertThat(found.getSourceBranchId()).isEqualTo(shipment.getFromBranchId());
                    assertThat(found.getHufAmount()).isEqualByComparingTo("125000.00");
                    assertThat(found.getCalculatedFee()).isEqualByComparingTo("625.00");
                    assertThat(found.getStatus()).isEqualTo(ShipmentRequestStatus.DRAFT);
                });
    }

    @Test
    @DisplayName("Másik companyId-val a kezelési költség nem olvasható")
    void findByShipmentRequestIdAndCompanyId_wrongCompany_returnsEmpty() {
        UUID companyId = UUID.randomUUID();
        ShipmentRequest shipment = shipmentRepository.save(request("KK-REPO-002", companyId));
        feeRepository.save(ShipmentHandlingFee.builder()
                .companyId(companyId)
                .shipmentRequestId(shipment.getId())
                .sourceBranchId(shipment.getFromBranchId())
                .hufAmount(new BigDecimal("125000.00"))
                .calculatedFee(new BigDecimal("625.00"))
                .status(ShipmentRequestStatus.DRAFT)
                .createdAt(LocalDateTime.of(2026, 7, 14, 8, 5))
                .build());

        assertThat(feeRepository.findByShipmentRequestIdAndCompanyId(
                shipment.getId(), UUID.randomUUID())).isEmpty();
    }

    @Test
    @DisplayName("FR-6: a fogadó branch napi Shipment-kezelési díjai hufAmount alapján összeadódnak")
    void sumDailyReceivedFees_sumsCountedHufAmounts() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 7, 14);

        saveFee(companyId, UUID.randomUUID(), branchId, ShipmentRequestStatus.SUBMITTED,
                date.atTime(8, 5), "625.00", "9999.00");
        saveFee(companyId, UUID.randomUUID(), branchId, ShipmentRequestStatus.DELIVERED,
                date.atTime(16, 30), "875.00", "9999.00");

        assertThat(feeRepository.sumDailyReceivedFees(companyId, branchId, date))
                .isEqualByComparingTo("1500.00");
    }

    @Test
    @DisplayName("FR-6: a napi összeg fee.companyId szerint tenant-izolált és null tenantnál fail-closed")
    void sumDailyReceivedFees_isTenantIsolatedAndNullCompanyFailsClosed() {
        UUID companyA = UUID.randomUUID();
        UUID companyB = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 7, 14);

        saveFee(companyA, UUID.randomUUID(), branchId, ShipmentRequestStatus.SUBMITTED,
                date.atTime(9, 0), "625.00", "100.00");
        saveFee(companyB, UUID.randomUUID(), branchId, ShipmentRequestStatus.SUBMITTED,
                date.atTime(9, 5), "4000.00", "100.00");

        assertThat(feeRepository.sumDailyReceivedFees(companyA, branchId, date))
                .isEqualByComparingTo("625.00");
        assertThat(feeRepository.sumDailyReceivedFees(null, branchId, date))
                .isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("FR-6: csak a fogadó branch díja számít, a küldő és más fogadó branch díja nem")
    void sumDailyReceivedFees_scopesByReceivingBranch() {
        UUID companyId = UUID.randomUUID();
        UUID queriedBranchId = UUID.randomUUID();
        UUID otherBranchId = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 7, 14);

        saveFee(companyId, UUID.randomUUID(), queriedBranchId, ShipmentRequestStatus.APPROVED,
                date.atTime(10, 0), "625.00", "100.00");
        saveFee(companyId, UUID.randomUUID(), otherBranchId, ShipmentRequestStatus.APPROVED,
                date.atTime(10, 5), "1000.00", "100.00");
        saveFee(companyId, queriedBranchId, otherBranchId, ShipmentRequestStatus.APPROVED,
                date.atTime(10, 10), "2000.00", "100.00");

        assertThat(feeRepository.sumDailyReceivedFees(companyId, queriedBranchId, date))
                .isEqualByComparingTo("625.00");
    }

    @Test
    @DisplayName("FR-6: pozitív státusz-whitelist számít bele a napi KPI-ba")
    void sumDailyReceivedFees_countsOnlyWhitelistedStatuses() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 7, 14);

        for (ShipmentRequestStatus status : ShipmentHandlingFeeRepository.KPI_COUNTED_STATUSES) {
            saveFee(companyId, UUID.randomUUID(), branchId, status,
                    date.atTime(11, status.ordinal()), "100.00", "1.00");
        }
        for (ShipmentRequestStatus status : new ShipmentRequestStatus[]{
                ShipmentRequestStatus.DRAFT,
                ShipmentRequestStatus.CANCELLED,
                ShipmentRequestStatus.REJECTED}) {
            saveFee(companyId, UUID.randomUUID(), branchId, status,
                    date.atTime(12, status.ordinal()), "1000.00", "1.00");
        }

        assertThat(feeRepository.sumDailyReceivedFees(companyId, branchId, date))
                .isEqualByComparingTo("400.00");
    }

    @Test
    @DisplayName("FR-6: a napi createdAt ablak kezdete inkluzív, következő éjfél exkluzív")
    void sumDailyReceivedFees_usesHalfOpenCreatedAtWindow() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 7, 14);

        saveFee(companyId, UUID.randomUUID(), branchId, ShipmentRequestStatus.IN_TRANSIT,
                date.atStartOfDay(), "100.00", "1.00");
        saveFee(companyId, UUID.randomUUID(), branchId, ShipmentRequestStatus.IN_TRANSIT,
                date.atTime(23, 59, 59), "200.00", "1.00");
        saveFee(companyId, UUID.randomUUID(), branchId, ShipmentRequestStatus.IN_TRANSIT,
                date.plusDays(1).atStartOfDay(), "400.00", "1.00");

        assertThat(feeRepository.sumDailyReceivedFees(companyId, branchId, date))
                .isEqualByComparingTo("300.00");
    }

    private void saveFee(
            UUID companyId,
            UUID sourceBranchId,
            UUID toBranchId,
            ShipmentRequestStatus status,
            LocalDateTime createdAt,
            String hufAmount,
            String calculatedFee) {
        ShipmentRequest shipment = shipmentRepository.save(request(
                "KK-AGG-" + UUID.randomUUID(), companyId, sourceBranchId, toBranchId));
        feeRepository.save(ShipmentHandlingFee.builder()
                .companyId(companyId)
                .shipmentRequestId(shipment.getId())
                .sourceBranchId(sourceBranchId)
                .hufAmount(new BigDecimal(hufAmount))
                .calculatedFee(new BigDecimal(calculatedFee))
                .status(status)
                .createdAt(createdAt)
                .build());
    }

    private static ShipmentRequest request(String requestNumber, UUID companyId) {
        return request(requestNumber, companyId, UUID.randomUUID(), UUID.randomUUID());
    }

    private static ShipmentRequest request(
            String requestNumber,
            UUID companyId,
            UUID fromBranchId,
            UUID toBranchId) {
        return ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(companyId)
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .requestedById(1L)
                .status(ShipmentRequestStatus.DRAFT)
                .requestDate(LocalDate.of(2026, 7, 14))
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("FKH-018")
                .createdAt(LocalDateTime.of(2026, 7, 14, 8, 0))
                .build();
    }
}
