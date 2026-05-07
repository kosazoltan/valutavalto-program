package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

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
class ShipmentRequestRepositoryTest {

    @Autowired
    private ShipmentRequestRepository repository;

    @Test
    @DisplayName("findMaxRequestNumber: csak a napi prefix utani sorszamot castolja")
    void findMaxRequestNumberUsesSuffixAfterPrefix() {
        String todayPrefix = "SHR-20260507-";
        String otherDayPrefix = "SHR-20260506-";

        repository.save(request(todayPrefix + "0001"));
        repository.save(request(todayPrefix + "0002"));
        repository.save(request(otherDayPrefix + "0099"));

        assertThat(repository.findMaxRequestNumber(todayPrefix)).isEqualTo(2);
    }

    private static ShipmentRequest request(String requestNumber) {
        return ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .fromBranchId(UUID.randomUUID())
                .toBranchId(UUID.randomUUID())
                .requestedById(1L)
                .status(ShipmentRequestStatus.DRAFT)
                .requestDate(LocalDate.of(2026, 5, 7))
                .createdAt(LocalDateTime.of(2026, 5, 7, 8, 0))
                .build();
    }
}
