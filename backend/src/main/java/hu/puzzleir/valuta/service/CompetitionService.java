package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.competition.CompetitionDto;
import hu.puzzleir.valuta.dto.competition.CompetitionEntryDto;
import hu.puzzleir.valuta.dto.competition.CreateCompetitionDto;
import hu.puzzleir.valuta.entity.WorkerCompetition;
import hu.puzzleir.valuta.entity.WorkerCompetition.CompetitionStatus;
import hu.puzzleir.valuta.entity.WorkerCompetitionEntry;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerCompetitionEntryRepository;
import hu.puzzleir.valuta.repository.WorkerCompetitionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Pénztáros versenyeztetés szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CompetitionService {

    private final WorkerCompetitionRepository competitionRepository;
    private final WorkerCompetitionEntryRepository entryRepository;
    private final TransactionRepository transactionRepository;
    private final WorkerRepository workerRepository;

    @Transactional(rollbackFor = Exception.class)
    public CompetitionDto createCompetition(CreateCompetitionDto dto) {
        if (dto.getEndDate().isBefore(dto.getStartDate())) {
            throw new ValidationException("A befejezés dátuma nem lehet a kezdés előtt.");
        }

        WorkerCompetition competition = WorkerCompetition.builder()
            .competitionName(dto.getCompetitionName())
            .startDate(dto.getStartDate())
            .endDate(dto.getEndDate())
            .rules(dto.getRules())
            .build();

        competition = competitionRepository.save(competition);
        log.info("Verseny létrehozva: name={}, start={}, end={}",
            dto.getCompetitionName(), dto.getStartDate(), dto.getEndDate());

        return toDto(competition);
    }

    /**
     * Pontszámok kiszámítása a verseny időszakának tranzakcióiból.
     * Pontszám = összforgalom / 1000 + tranzakciók száma × 10
     */
    @Transactional(rollbackFor = Exception.class)
    public List<CompetitionEntryDto> calculateScores(UUID competitionId) {
        WorkerCompetition competition = competitionRepository.findById(competitionId)
            .orElseThrow(() -> new ResourceNotFoundException("Verseny nem található: " + competitionId));

        LocalDateTime from = competition.getStartDate().atStartOfDay();
        LocalDateTime to = competition.getEndDate().atTime(LocalTime.MAX);

        // Töröljük a régi bejegyzéseket
        entryRepository.deleteByCompetitionId(competitionId);

        // Minden dolgozó tranzakcióit összesítjük (multi-tenant szűréssel)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Worker> workers = workerRepository.findByCompanyId(companyId);
        AtomicInteger rankCounter = new AtomicInteger(1);

        List<WorkerCompetitionEntry> entries = workers.stream()
            .map(worker -> {
                BigDecimal volume = transactionRepository.sumHufAmountByWorkerAndPeriod(
                    worker.getId(), from, to);
                long txCount = transactionRepository.countByWorkerAndPeriod(
                    worker.getId(), from, to);

                volume = volume != null ? volume : BigDecimal.ZERO;

                BigDecimal score = volume.divide(new BigDecimal("1000"), 4, java.math.RoundingMode.HALF_UP)
                    .add(new BigDecimal(txCount * 10));

                return WorkerCompetitionEntry.builder()
                    .competition(competition)
                    .workerId(worker.getId())
                    .totalVolume(volume)
                    .transactionCount((int) txCount)
                    .score(score)
                    .build();
            })
            .filter(e -> e.getTransactionCount() > 0 || e.getTotalVolume().compareTo(BigDecimal.ZERO) > 0)
            .sorted((a, b) -> b.getScore().compareTo(a.getScore()))
            .peek(e -> e.setRank(rankCounter.getAndIncrement()))
            .toList();

        entryRepository.saveAll(entries);
        log.info("Verseny pontok kiszámítva: competitionId={}, entries={}", competitionId, entries.size());

        return entries.stream().map(this::toEntryDto).toList();
    }

    @Transactional(readOnly = true)
    public List<CompetitionEntryDto> getLeaderboard(UUID competitionId) {
        return entryRepository.findByCompetitionIdOrderByScoreDesc(competitionId).stream()
            .map(this::toEntryDto)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<CompetitionDto> getAllCompetitions() {
        return competitionRepository.findAllByOrderByCreatedAtDesc().stream()
            .map(this::toDto)
            .toList();
    }

    // ============ HELPER ============

    private CompetitionDto toDto(WorkerCompetition entity) {
        return CompetitionDto.builder()
            .id(entity.getId())
            .competitionName(entity.getCompetitionName())
            .startDate(entity.getStartDate())
            .endDate(entity.getEndDate())
            .status(entity.getStatus().name())
            .rules(entity.getRules())
            .createdAt(entity.getCreatedAt())
            .build();
    }

    private CompetitionEntryDto toEntryDto(WorkerCompetitionEntry entity) {
        String workerName = workerRepository.findById(entity.getWorkerId())
            .map(Worker::getName)
            .orElse("Ismeretlen");

        return CompetitionEntryDto.builder()
            .id(entity.getId())
            .competitionId(entity.getCompetition().getId())
            .workerId(entity.getWorkerId())
            .workerName(workerName)
            .totalVolume(entity.getTotalVolume())
            .transactionCount(entity.getTransactionCount())
            .score(entity.getScore())
            .rank(entity.getRank())
            .build();
    }
}
