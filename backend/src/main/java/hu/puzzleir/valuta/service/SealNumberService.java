package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.SealNumber;
import hu.puzzleir.valuta.entity.SealNumber.SealType;
import hu.puzzleir.valuta.repository.SealNumberRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/**
 * Plomba szám generátor és nyilvántartás.
 *
 * Legacy: GETPLOMB — pénztárnyitás/zárás során a plomba szám
 * rögzítése (páncélszekrény biztosítás).
 *
 * Formátum: {branchCode}-{YYYYMMDD}-{seq:3}
 * Példa: "BC01-20260306-001", "BC01-20260306-002"
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class SealNumberService {

    private final SealNumberRepository sealNumberRepository;
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * Következő plomba szám lekérése (NEM menti el — csak preview).
     */
    @Transactional(readOnly = true)
    public String getNextSealNumber(String branchCode) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return generateSealNumber(branchCode, branchId);
    }

    /**
     * Plomba szám generálása és mentése.
     */
    public SealNumber generate(String branchCode, SealType sealType, UUID sessionId, String note) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        String sealNumber = generateSealNumber(branchCode, branchId);

        SealNumber seal = SealNumber.builder()
                .branchId(branchId)
                .sealNumber(sealNumber)
                .sealType(sealType)
                .sessionId(sessionId)
                .workerId(workerId)
                .note(note)
                .build();

        seal = sealNumberRepository.save(seal);
        log.info("Plomba szám generálva: {} (típus: {}, branch: {}, session: {})",
                sealNumber, sealType, branchCode, sessionId);

        return seal;
    }

    /**
     * Plomba felhasználásának rögzítése.
     */
    public SealNumber markAsUsed(UUID sealId, UUID sessionId) {
        SealNumber seal = sealNumberRepository.findById(sealId)
                .orElseThrow(() -> new ResourceNotFoundException("Plomba nem található: " + sealId));

        if (seal.getUsedAt() != null) {
            throw new ValidationException("Ez a plomba már felhasználva: " + seal.getSealNumber());
        }

        seal.setUsedAt(LocalDateTime.now());
        seal.setSessionId(sessionId);
        return sealNumberRepository.save(seal);
    }

    /**
     * Irodához tartozó mai plomba számok listázása.
     */
    @Transactional(readOnly = true)
    public List<SealNumber> listToday(UUID branchId) {
        LocalDateTime dayStart = LocalDate.now().atStartOfDay();
        LocalDateTime dayEnd = LocalDate.now().atTime(LocalTime.MAX);
        return sealNumberRepository.findByBranchIdAndCreatedAtBetweenOrderByCreatedAtDesc(
                branchId, dayStart, dayEnd);
    }

    /**
     * Felhasználatlan plomba számok listázása.
     */
    @Transactional(readOnly = true)
    public List<SealNumber> listUnused(UUID branchId) {
        return sealNumberRepository.findByBranchIdAndUsedAtIsNullOrderByCreatedAtDesc(branchId);
    }

    // === PRIVÁT ===

    private String generateSealNumber(String branchCode, UUID branchId) {
        String datePart = LocalDate.now().format(DATE_FMT);

        LocalDateTime dayStart = LocalDate.now().atStartOfDay();
        LocalDateTime dayEnd = LocalDate.now().atTime(LocalTime.MAX);

        // Utolsó szekvencia szám lekérése
        int nextSeq = 1;
        var lastSeal = sealNumberRepository.findLastSealNumberByBranchAndDay(branchId, dayStart, dayEnd);
        if (lastSeal.isPresent()) {
            try {
                String last = lastSeal.get();
                String seqPart = last.substring(last.lastIndexOf('-') + 1);
                nextSeq = Integer.parseInt(seqPart) + 1;
            } catch (Exception e) {
                log.warn("Szekvencia szám parse hiba: {}", e.getMessage());
            }
        }

        return String.format("%s-%s-%03d", branchCode, datePart, nextSeq);
    }
}
