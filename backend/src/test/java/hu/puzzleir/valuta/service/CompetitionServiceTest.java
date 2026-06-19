package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerCompetition;
import hu.puzzleir.valuta.entity.WorkerCompetitionEntry;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerCompetitionEntryRepository;
import hu.puzzleir.valuta.repository.WorkerCompetitionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CompetitionServiceTest {

    @Mock
    private WorkerCompetitionRepository competitionRepository;
    @Mock
    private WorkerCompetitionEntryRepository entryRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private WorkerRepository workerRepository;

    @InjectMocks
    private CompetitionService service;

    @Test
    void getLeaderboardUsesCompanyScopedWorkerLookupForNames() {
        UUID companyId = UUID.randomUUID();
        UUID competitionId = UUID.randomUUID();
        WorkerCompetition competition = WorkerCompetition.builder()
                .id(competitionId)
                .build();
        WorkerCompetitionEntry entry = WorkerCompetitionEntry.builder()
                .id(UUID.randomUUID())
                .competition(competition)
                .workerId(7L)
                .totalVolume(new BigDecimal("1000.00"))
                .transactionCount(2)
                .score(new BigDecimal("21.0000"))
                .rank(1)
                .build();
        Worker worker = Worker.builder()
                .id(7L)
                .name("Teszt Pénztáros")
                .build();

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(entryRepository.findByCompetitionIdOrderByScoreDesc(competitionId)).thenReturn(List.of(entry));
            when(workerRepository.findByIdAndCompanyId(7L, companyId)).thenReturn(Optional.of(worker));

            var leaderboard = service.getLeaderboard(competitionId);

            assertThat(leaderboard).hasSize(1);
            assertThat(leaderboard.get(0).getWorkerName()).isEqualTo("Teszt Pénztáros");
            verify(workerRepository).findByIdAndCompanyId(7L, companyId);
            verify(workerRepository, never()).findById(7L);
        }
    }
}
