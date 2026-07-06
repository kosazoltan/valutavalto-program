package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.config.CreateValueBandConfigRequest;
import hu.puzzleir.valuta.entity.ValueBandConfig;
import hu.puzzleir.valuta.service.ValueBandService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ValueBandControllerTest {

    private final ValueBandService valueBandService = mock(ValueBandService.class);
    private final ValueBandController controller = new ValueBandController(valueBandService);

    @Test
    void listReturnsAllValueBands() {
        ValueBandConfig row = config(UUID.randomUUID(), LocalDate.now());
        when(valueBandService.listAll()).thenReturn(List.of(row));

        ResponseEntity<List<ValueBandConfig>> response = controller.list();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).containsExactly(row);
    }

    @Test
    void effectiveReturnsResolvedSnapshot() {
        ValueBandService.ValueBands bands = new ValueBandService.ValueBands(
                new BigDecimal("100000"), new BigDecimal("300000"), new BigDecimal("10000000"), 8);
        when(valueBandService.getEffectiveBands()).thenReturn(bands);

        ResponseEntity<ValueBandService.ValueBands> response = controller.effective();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(bands);
    }

    @Test
    void createReturnsCreatedValueBand() {
        CreateValueBandConfigRequest request = request(LocalDate.now().plusDays(1));
        ValueBandConfig saved = config(UUID.randomUUID(), request.getEffectiveFrom());
        when(valueBandService.create(request)).thenReturn(saved);

        ResponseEntity<ValueBandConfig> response = controller.create(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(saved);
    }

    @Test
    void updateDelegatesById() {
        UUID id = UUID.randomUUID();
        CreateValueBandConfigRequest request = request(LocalDate.now().plusDays(1));
        ValueBandConfig saved = config(id, request.getEffectiveFrom());
        when(valueBandService.update(id, request)).thenReturn(saved);

        ResponseEntity<ValueBandConfig> response = controller.update(id, request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(saved);
    }

    @Test
    void deleteReturnsNoContent() {
        UUID id = UUID.randomUUID();

        ResponseEntity<Void> response = controller.delete(id);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(valueBandService).delete(id);
    }

    private static CreateValueBandConfigRequest request(LocalDate effectiveFrom) {
        return CreateValueBandConfigRequest.builder()
                .simplifiedIdentificationLimitHuf(new BigDecimal("100000"))
                .identificationLimitHuf(new BigDecimal("300000"))
                .incomeProofLimitHuf(new BigDecimal("10000000"))
                .rollingWindowDays(8)
                .effectiveFrom(effectiveFrom)
                .build();
    }

    private static ValueBandConfig config(UUID id, LocalDate effectiveFrom) {
        return ValueBandConfig.builder()
                .id(id)
                .simplifiedIdentificationLimitHuf(new BigDecimal("100000"))
                .identificationLimitHuf(new BigDecimal("300000"))
                .incomeProofLimitHuf(new BigDecimal("10000000"))
                .rollingWindowDays(8)
                .effectiveFrom(effectiveFrom)
                .build();
    }
}
