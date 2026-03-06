package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SealNumber;
import hu.puzzleir.valuta.entity.SealNumber.SealType;
import hu.puzzleir.valuta.repository.SealNumberRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * SealNumberService UNIT tesztek.
 *
 * Teszteli a GETPLOMB (plomba szám generátor) logikát:
 * - Formátum: {branchCode}-{YYYYMMDD}-{seq:3}
 * - Szekvencia inkrementálás
 * - Dupla felhasználás tiltás
 */
@ExtendWith(MockitoExtension.class)
class SealNumberServiceTest {

    @Mock private SealNumberRepository sealNumberRepository;
    @InjectMocks private SealNumberService sealNumberService;

    @Test
    @DisplayName("Első plomba: BC01-YYYYMMDD-001")
    void shouldGenerateFirstSealNumber() {
        try (MockedStatic<SecurityUtils> mocked = mockStatic(SecurityUtils.class)) {
            UUID branchId = UUID.randomUUID();
            mocked.when(SecurityUtils::getCurrentBranchId).thenReturn(branchId);
            mocked.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);

            when(sealNumberRepository.findLastSealNumberByBranchAndDay(eq(branchId), any(), any()))
                    .thenReturn(Optional.empty());
            when(sealNumberRepository.save(any(SealNumber.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            SealNumber seal = sealNumberService.generate("BC01", SealType.CLOSE, null, null);

            String expectedDate = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            assertThat(seal.getSealNumber()).isEqualTo("BC01-" + expectedDate + "-001");
            assertThat(seal.getSealType()).isEqualTo(SealType.CLOSE);
        }
    }

    @Test
    @DisplayName("Második plomba: szekvencia inkrementálás")
    void shouldIncrementSequence() {
        try (MockedStatic<SecurityUtils> mocked = mockStatic(SecurityUtils.class)) {
            UUID branchId = UUID.randomUUID();
            mocked.when(SecurityUtils::getCurrentBranchId).thenReturn(branchId);
            mocked.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);

            String today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            when(sealNumberRepository.findLastSealNumberByBranchAndDay(eq(branchId), any(), any()))
                    .thenReturn(Optional.of("BC01-" + today + "-003"));
            when(sealNumberRepository.save(any(SealNumber.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            SealNumber seal = sealNumberService.generate("BC01", SealType.OPEN, null, "teszt");

            assertThat(seal.getSealNumber()).isEqualTo("BC01-" + today + "-004");
            assertThat(seal.getNote()).isEqualTo("teszt");
        }
    }

    @Test
    @DisplayName("Dupla felhasználás → ValidationException")
    void shouldRejectDoubleUse() {
        UUID sealId = UUID.randomUUID();
        SealNumber existing = SealNumber.builder()
                .id(sealId)
                .sealNumber("BC01-20260306-001")
                .usedAt(java.time.LocalDateTime.now()) // már felhasználva!
                .build();

        when(sealNumberRepository.findById(sealId)).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> sealNumberService.markAsUsed(sealId, UUID.randomUUID()))
                .hasMessageContaining("már felhasználva");
    }
}
