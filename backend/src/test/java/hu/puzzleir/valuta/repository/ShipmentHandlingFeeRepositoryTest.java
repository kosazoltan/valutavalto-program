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

    private static ShipmentRequest request(String requestNumber, UUID companyId) {
        return ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(companyId)
                .fromBranchId(UUID.randomUUID())
                .toBranchId(UUID.randomUUID())
                .requestedById(1L)
                .status(ShipmentRequestStatus.DRAFT)
                .requestDate(LocalDate.of(2026, 7, 14))
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("FKH-018")
                .createdAt(LocalDateTime.of(2026, 7, 14, 8, 0))
                .build();
    }
}
