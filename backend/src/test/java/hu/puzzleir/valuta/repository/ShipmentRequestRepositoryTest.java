package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.config.JacksonConfig;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
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

    @Test
    @DisplayName("save: JSON-deszerializált request itemjeinek back-reference-ét a lifecycle-hook drótozza (prod 2026-07-16 repró)")
    void saveWiresItemBackReferencesAfterJacksonDeserialization() throws Exception {
        JsonMapper mapper = new JacksonConfig().jsonMapper();
        String json = """
                {"fromBranchId":"%s","toBranchId":"%s",
                 "carrierName":"Brink's Hungary Kft.","sealNumber":"ABC-002",
                 "items":[{"currencyId":3,"requestedAmount":1000000.01}]}
                """.formatted(UUID.randomUUID(), UUID.randomUUID());
        ShipmentRequest request = mapper.readValue(json, ShipmentRequest.class);

        // Gyökérok-bizonyíték: a Jackson 3 útvonal NEM hívja az addItem()-et →
        // a back-reference nyersen null (ez a fix UTÁN is igaz — a drótozás a
        // persist-life-cycle felelőssége, nem a deszerializálásé).
        assertThat(request.getItems()).hasSize(1);
        assertThat(request.getItems().get(0).getShipmentRequest()).isNull();

        // A service által kitöltött kötelező mezők (create() analógiája — az
        // items-hez NEM nyúlunk, pont az a lényeg):
        request.setRequestNumber("SHR-20260716-0001");
        request.setRequestedById(1L);
        request.setRequestDate(LocalDate.of(2026, 7, 16));
        request.setStatus(ShipmentRequestStatus.DRAFT);
        request.setCreatedAt(LocalDateTime.of(2026, 7, 16, 18, 29));

        // FIX NÉLKÜL: DataIntegrityViolation a flush-nál (null shipment_request_id)
        // — a 2026-07-16-i éles hiba tükre. FIXSZEL: sikeres insert + drótozott ref.
        ShipmentRequest saved = repository.saveAndFlush(request);

        assertThat(saved.getItems())
                .isNotEmpty()
                .allSatisfy(item -> assertThat(item.getShipmentRequest())
                        .as("item.shipmentRequest a szülőre mutat")
                        .isSameAs(saved));
    }

    @Test
    @DisplayName("save: builder .items(list) konstrukciónál a lifecycle-hook perzisztálható back-reference-et állít be")
    void saveWiresItemBackReferencesForBuilderItemsList() {
        ShipmentRequestItem item = ShipmentRequestItem.builder()
                .currencyId(3L)
                .requestedAmount(new BigDecimal("250000.00"))
                .build();
        ShipmentRequest request = ShipmentRequest.builder()
                .requestNumber("SHR-BUILDER-" + UUID.randomUUID())
                .fromBranchId(UUID.randomUUID())
                .toBranchId(UUID.randomUUID())
                .requestedById(1L)
                .status(ShipmentRequestStatus.DRAFT)
                .requestDate(LocalDate.of(2026, 7, 17))
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("BUILDER-001")
                .createdAt(LocalDateTime.of(2026, 7, 17, 9, 0))
                .items(List.of(item))
                .build();

        assertThat(item.getShipmentRequest())
                .as("a Lombok builder nem hívja az addItem() helpert")
                .isNull();

        ShipmentRequest saved = repository.saveAndFlush(request);

        assertThat(saved.getItems()).singleElement().satisfies(savedItem ->
                assertThat(savedItem.getShipmentRequest()).isSameAs(saved));
    }

    private static ShipmentRequest request(String requestNumber) {
        return ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .fromBranchId(UUID.randomUUID())
                .toBranchId(UUID.randomUUID())
                .requestedById(1L)
                .status(ShipmentRequestStatus.DRAFT)
                .requestDate(LocalDate.of(2026, 5, 7))
                // FK02: carrier_name + seal_number kötelező (@NotBlank) — fixture-ben kitöltve.
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("ABC-001")
                .createdAt(LocalDateTime.of(2026, 5, 7, 8, 0))
                .build();
    }
}
