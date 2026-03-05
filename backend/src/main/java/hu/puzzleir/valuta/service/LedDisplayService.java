package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.led.LedDisplayDto;
import hu.puzzleir.valuta.entity.LedDisplay;
import hu.puzzleir.valuta.entity.LedDisplayType;
import hu.puzzleir.valuta.repository.LedDisplayRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * LED kijelző service.
 *
 * Placeholder — a fizikai LED vezérlés (RS-232 / USB) későbbi fejlesztés.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LedDisplayService {

    private final LedDisplayRepository ledDisplayRepository;
    private final BranchRepository branchRepository;

    /**
     * Árfolyam tábla frissítése LED kijelzőre.
     */
    @Transactional
    public LedDisplayDto updateRateBoard(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        LedDisplay display = ledDisplayRepository.findByBranchIdAndDisplayType(
                        branchId, LedDisplayType.RATE_BOARD)
                .orElse(LedDisplay.builder()
                        .branch(branch)
                        .displayType(LedDisplayType.RATE_BOARD)
                        .build());

        // Placeholder — az árfolyamokat JSON formátumba generáljuk
        display.setContent("{\"type\":\"RATE_BOARD\",\"message\":\"Árfolyam tábla frissítve\",\"timestamp\":\""
                + LocalDateTime.now() + "\"}");
        display.setLastUpdated(LocalDateTime.now());

        display = ledDisplayRepository.save(display);
        log.info("LED árfolyam tábla frissítve: branch={}", branch.getCode());
        return toDto(display);
    }

    /**
     * Futó szöveg beállítása.
     */
    @Transactional
    public LedDisplayDto updateScrollingText(UUID branchId, String text) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        LedDisplay display = ledDisplayRepository.findByBranchIdAndDisplayType(
                        branchId, LedDisplayType.SCROLLING_TEXT)
                .orElse(LedDisplay.builder()
                        .branch(branch)
                        .displayType(LedDisplayType.SCROLLING_TEXT)
                        .build());

        display.setContent("{\"type\":\"SCROLLING_TEXT\",\"text\":\""
                + text.replace("\"", "\\\"") + "\",\"timestamp\":\""
                + LocalDateTime.now() + "\"}");
        display.setLastUpdated(LocalDateTime.now());

        display = ledDisplayRepository.save(display);
        log.info("LED futó szöveg frissítve: branch={}, text={}", branch.getCode(), text);
        return toDto(display);
    }

    /**
     * LED kijelző státusz lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<LedDisplayDto> getStatus(UUID branchId) {
        return ledDisplayRepository.findByBranchId(branchId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private LedDisplayDto toDto(LedDisplay d) {
        return LedDisplayDto.builder()
                .id(d.getId().toString())
                .branchId(d.getBranch().getId().toString())
                .displayType(d.getDisplayType().name())
                .content(d.getContent())
                .lastUpdated(d.getLastUpdated() != null ? d.getLastUpdated().toString() : null)
                .build();
    }
}
