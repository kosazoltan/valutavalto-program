package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.reservation.ReservationDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.Reservation;
import hu.puzzleir.valuta.entity.ReservationStatus;
import hu.puzzleir.valuta.entity.Worker;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ReservationMapperTest {

    private final ReservationMapper mapper = new ReservationMapper();

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }

    @Test
    @DisplayName("Foglaló pénzügyi mezők, státusz és kapcsolt személyek átkerülnek a DTO-ba")
    void mapsFinancialStatusAndReferenceFields() {
        UUID branchId = UUID.fromString("33333333-4444-5555-6666-777777777777");
        LocalDateTime expiresAt = LocalDateTime.now().plusDays(3);
        LocalDateTime createdAt = LocalDateTime.of(2026, 7, 6, 9, 0);
        LocalDateTime fulfilledAt = LocalDateTime.of(2026, 7, 7, 9, 0);
        LocalDateTime cancelledAt = LocalDateTime.of(2026, 7, 8, 9, 0);
        Reservation entity = Reservation.builder()
                .id(20L)
                .customer(Customer.builder().id(100L).name("Foglaló Ügyfél").build())
                .branch(Branch.builder().id(branchId).name("Debrecen").build())
                .worker(Worker.builder().id(200L).name("Pénztáros").build())
                .currencyCode("EUR")
                .reservedAmount(new BigDecimal("1000.00"))
                .exchangeRate(new BigDecimal("392.5000"))
                .depositAmount(new BigDecimal("392500.00"))
                .status(ReservationStatus.ACTIVE)
                .expiresAt(expiresAt)
                .createdAt(createdAt)
                .fulfilledAt(fulfilledAt)
                .cancelledAt(cancelledAt)
                .receiptNumber("F00001")
                .cancellationReceiptNumber("K00001")
                .cancellationReason("teszt")
                .supervisorApproval(true)
                .supervisorWorker(Worker.builder().id(201L).name("Supervisor").build())
                .refundAmount(new BigDecimal("100.00"))
                .notes("megjegyzés")
                .build();

        ReservationDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(20L);
        assertThat(dto.getCustomerId()).isEqualTo(100L);
        assertThat(dto.getCustomerName()).isEqualTo("Foglaló Ügyfél");
        assertThat(dto.getBranchId()).isEqualTo(branchId.toString());
        assertThat(dto.getBranchName()).isEqualTo("Debrecen");
        assertThat(dto.getWorkerId()).isEqualTo(200L);
        assertThat(dto.getWorkerName()).isEqualTo("Pénztáros");
        assertThat(dto.getCurrencyCode()).isEqualTo("EUR");
        assertThat(dto.getReservedAmount()).isEqualByComparingTo("1000.00");
        assertThat(dto.getExchangeRate()).isEqualByComparingTo("392.5000");
        assertThat(dto.getDepositAmount()).isEqualByComparingTo("392500.00");
        assertThat(dto.getStatus()).isEqualTo(ReservationStatus.ACTIVE);
        assertThat(dto.getExpiresAt()).isEqualTo(expiresAt);
        assertThat(dto.getCreatedAt()).isEqualTo(createdAt);
        assertThat(dto.getFulfilledAt()).isEqualTo(fulfilledAt);
        assertThat(dto.getCancelledAt()).isEqualTo(cancelledAt);
        assertThat(dto.getReceiptNumber()).isEqualTo("F00001");
        assertThat(dto.getCancellationReceiptNumber()).isEqualTo("K00001");
        assertThat(dto.getCancellationReason()).isEqualTo("teszt");
        assertThat(dto.getSupervisorApproval()).isTrue();
        assertThat(dto.getSupervisorWorkerId()).isEqualTo(201L);
        assertThat(dto.getSupervisorWorkerName()).isEqualTo("Supervisor");
        assertThat(dto.getRefundAmount()).isEqualByComparingTo("100.00");
        assertThat(dto.getNotes()).isEqualTo("megjegyzés");
        assertThat(dto.getExpired()).isFalse();
    }

    @Test
    @DisplayName("expired csak ACTIVE + múltbeli expiresAt esetén true")
    void mapsExpiredOnlyForActivePastReservation() {
        Reservation activePast = Reservation.builder()
                .status(ReservationStatus.ACTIVE)
                .expiresAt(LocalDateTime.now().minusDays(1))
                .build();
        Reservation activeFuture = Reservation.builder()
                .status(ReservationStatus.ACTIVE)
                .expiresAt(LocalDateTime.now().plusDays(1))
                .build();
        Reservation cancelledPast = Reservation.builder()
                .status(ReservationStatus.CANCELLED_BY_CUSTOMER)
                .expiresAt(LocalDateTime.now().minusDays(1))
                .build();

        assertThat(mapper.toDto(activePast).getExpired()).isTrue();
        assertThat(mapper.toDto(activeFuture).getExpired()).isFalse();
        assertThat(mapper.toDto(cancelledPast).getExpired()).isFalse();
    }

    @Test
    @DisplayName("Hiányzó customer/branch/worker/supervisor → null ID/name mezők NPE nélkül")
    void mapsNullReferencesSafely() {
        Reservation entity = Reservation.builder()
                .customer(null)
                .branch(null)
                .worker(null)
                .supervisorWorker(null)
                .currencyCode("USD")
                .status(ReservationStatus.ACTIVE)
                .expiresAt(LocalDateTime.now().plusDays(1))
                .build();

        ReservationDto dto = mapper.toDto(entity);

        assertThat(dto.getCustomerId()).isNull();
        assertThat(dto.getCustomerName()).isNull();
        assertThat(dto.getBranchId()).isNull();
        assertThat(dto.getBranchName()).isNull();
        assertThat(dto.getWorkerId()).isNull();
        assertThat(dto.getWorkerName()).isNull();
        assertThat(dto.getSupervisorWorkerId()).isNull();
        assertThat(dto.getSupervisorWorkerName()).isNull();
        assertThat(dto.getCurrencyCode()).isEqualTo("USD");
    }
}
