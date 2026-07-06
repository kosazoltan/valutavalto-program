package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.config.CreateValueBandConfigRequest;
import hu.puzzleir.valuta.entity.ValueBandConfig;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ValueBandConfigRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ValueBandServiceTest {

    @Mock
    private ValueBandConfigRepository valueBandConfigRepository;

    @InjectMocks
    private ValueBandService service;

    @Test
    @DisplayName("getEffectiveBands: üres repo esetén törvényi DEFAULTS értékeket ad")
    void getEffectiveBands_emptyRepository_returnsDefaults() {
        when(valueBandConfigRepository.findTopByEffectiveFromLessThanEqualOrderByEffectiveFromDesc(any()))
                .thenReturn(Optional.empty());

        ValueBandService.ValueBands bands = service.getEffectiveBands();

        assertBands(bands, "100000", "300000", "10000000", 8);
    }

    @Test
    @DisplayName("getEffectiveBands: repo hiba esetén fail-closed DEFAULTS, nem propagál")
    void getEffectiveBands_repositoryThrows_returnsDefaults() {
        when(valueBandConfigRepository.findTopByEffectiveFromLessThanEqualOrderByEffectiveFromDesc(any()))
                .thenThrow(new RuntimeException("db down"));

        ValueBandService.ValueBands bands = service.getEffectiveBands();

        assertBands(bands, "100000", "300000", "10000000", 8);
    }

    @Test
    @DisplayName("getEffectiveBands: legfrissebb hatályos sor értékeit adja vissza")
    void getEffectiveBands_effectiveRow_returnsConfiguredValues() {
        ValueBandConfig config = ValueBandConfig.builder()
                .simplifiedIdentificationLimitHuf(new BigDecimal("150000"))
                .identificationLimitHuf(new BigDecimal("250000"))
                .incomeProofLimitHuf(new BigDecimal("9000000"))
                .rollingWindowDays(7)
                .effectiveFrom(LocalDate.now().minusDays(1))
                .build();
        when(valueBandConfigRepository.findTopByEffectiveFromLessThanEqualOrderByEffectiveFromDesc(any()))
                .thenReturn(Optional.of(config));

        ValueBandService.ValueBands bands = service.getEffectiveBands();

        assertBands(bands, "150000", "250000", "9000000", 7);
    }

    @Test
    @DisplayName("resolve(null): DEFAULTS értékeket ad")
    void resolve_nullService_returnsDefaults() {
        ValueBandService.ValueBands bands = ValueBandService.resolve(null);

        assertBands(bands, "100000", "300000", "10000000", 8);
    }

    @Test
    @DisplayName("create: mai effectiveFrom elutasítva, csak jövőbeli lehet")
    void create_todayEffectiveFrom_rejected() {
        CreateValueBandConfigRequest req = validRequest(LocalDate.now());

        assertThatThrownBy(() -> service.create(req))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jövőbeli");
    }

    @Test
    @DisplayName("create: simplified > identification elutasítva")
    void create_simplifiedGreaterThanIdentification_rejected() {
        CreateValueBandConfigRequest req = validRequest(LocalDate.now().plusDays(1));
        req.setSimplifiedIdentificationLimitHuf(new BigDecimal("300001"));
        req.setIdentificationLimitHuf(new BigDecimal("300000"));

        assertThatThrownBy(() -> service.create(req))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("egyszerűsített");
    }

    @Test
    @DisplayName("create: azonos effectiveFrom már létezik → ValidationException")
    void create_duplicateEffectiveFrom_rejected() {
        CreateValueBandConfigRequest req = validRequest(LocalDate.now().plusDays(1));
        when(valueBandConfigRepository.existsByEffectiveFrom(req.getEffectiveFrom())).thenReturn(true);

        assertThatThrownBy(() -> service.create(req))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("már létezik");
    }

    @Test
    @DisplayName("update/delete: múltbeli vagy mai effectiveFrom-ú sor nem szerkeszthető")
    void updateAndDelete_currentOrPastRows_rejected() {
        UUID id = UUID.randomUUID();
        ValueBandConfig today = ValueBandConfig.builder()
                .id(id)
                .effectiveFrom(LocalDate.now())
                .build();
        when(valueBandConfigRepository.findById(id)).thenReturn(Optional.of(today));

        assertThatThrownBy(() -> service.update(id, validRequest(LocalDate.now().plusDays(2))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem módosítható");
        assertThatThrownBy(() -> service.delete(id))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem módosítható");
    }

    @Test
    @DisplayName("update: jövőbeli soron repo.save hívódik")
    void update_futureRow_saves() {
        UUID id = UUID.randomUUID();
        ValueBandConfig existing = ValueBandConfig.builder()
                .id(id)
                .simplifiedIdentificationLimitHuf(new BigDecimal("100000"))
                .identificationLimitHuf(new BigDecimal("300000"))
                .incomeProofLimitHuf(new BigDecimal("10000000"))
                .rollingWindowDays(8)
                .effectiveFrom(LocalDate.now().plusDays(1))
                .build();
        CreateValueBandConfigRequest req = validRequest(LocalDate.now().plusDays(2));
        when(valueBandConfigRepository.findById(id)).thenReturn(Optional.of(existing));
        when(valueBandConfigRepository.save(any(ValueBandConfig.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.update(id, req);

        ArgumentCaptor<ValueBandConfig> captor = ArgumentCaptor.forClass(ValueBandConfig.class);
        verify(valueBandConfigRepository).save(captor.capture());
        assertBands(captor.getValue(), "100000", "300000", "10000000", 8);
        assertThat(captor.getValue().getEffectiveFrom()).isEqualTo(req.getEffectiveFrom());
    }

    private static CreateValueBandConfigRequest validRequest(LocalDate effectiveFrom) {
        return CreateValueBandConfigRequest.builder()
                .simplifiedIdentificationLimitHuf(new BigDecimal("100000"))
                .identificationLimitHuf(new BigDecimal("300000"))
                .incomeProofLimitHuf(new BigDecimal("10000000"))
                .rollingWindowDays(8)
                .effectiveFrom(effectiveFrom)
                .build();
    }

    private static void assertBands(ValueBandService.ValueBands bands,
                                    String simplified,
                                    String identification,
                                    String incomeProof,
                                    int rollingDays) {
        assertThat(bands.simplifiedIdentificationLimitHuf()).usingComparator(BigDecimal::compareTo)
                .isEqualTo(new BigDecimal(simplified));
        assertThat(bands.identificationLimitHuf()).usingComparator(BigDecimal::compareTo)
                .isEqualTo(new BigDecimal(identification));
        assertThat(bands.incomeProofLimitHuf()).usingComparator(BigDecimal::compareTo)
                .isEqualTo(new BigDecimal(incomeProof));
        assertThat(bands.rollingWindowDays()).isEqualTo(rollingDays);
    }

    private static void assertBands(ValueBandConfig config,
                                    String simplified,
                                    String identification,
                                    String incomeProof,
                                    int rollingDays) {
        assertThat(config.getSimplifiedIdentificationLimitHuf()).usingComparator(BigDecimal::compareTo)
                .isEqualTo(new BigDecimal(simplified));
        assertThat(config.getIdentificationLimitHuf()).usingComparator(BigDecimal::compareTo)
                .isEqualTo(new BigDecimal(identification));
        assertThat(config.getIncomeProofLimitHuf()).usingComparator(BigDecimal::compareTo)
                .isEqualTo(new BigDecimal(incomeProof));
        assertThat(config.getRollingWindowDays()).isEqualTo(rollingDays);
    }
}
