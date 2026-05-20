package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.service.MnbReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

/**
 * MNB napi adatszolgáltatás-előkészítő ütemező (VV-ELVI 9.3 — "MNB 14:30").
 *
 * <p>Munkanapokon 14:30-kor (Europe/Budapest) minden aktív irodához legenerálja a
 * napi MNB riport DRAFT-ot, hogy a kötelező adatszolgáltatás kész legyen
 * emberi jóváhagyásra/beküldésre. <b>Szándékosan NEM küld be automatikusan</b>
 * az MNB-nek — a beküldés továbbra is explicit emberi művelet
 * ({@code POST /api/v1/mnb/reports/{id}/submit}), mert a regulátornak küldött
 * automatikus beküldés nagy kockázatú lenne.
 *
 * <p>Idempotens: ha egy irodához az adott napra már létezik riport, a
 * {@link MnbReportService#generateDailyReport} {@link ValidationException}-t dob,
 * amit kihagyásként kezelünk (nem hiba).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class MnbDailyReportScheduler {

    private static final ZoneId ZONE = ZoneId.of("Europe/Budapest");

    private final BranchRepository branchRepository;
    private final MnbReportService mnbReportService;

    /**
     * Napi MNB DRAFT-generálás — munkanapokon 14:30 (Budapest).
     * Cron: sec min hour day month weekday; MON-FRI = 1-5.
     */
    @Scheduled(cron = "0 30 14 * * MON-FRI", zone = "Europe/Budapest")
    public void scheduledDailyMnbDraftGeneration() {
        LocalDate today = LocalDate.now(ZONE);
        log.info("Ütemezett MNB napi DRAFT-generálás indítása: {} ({})", today, today.getDayOfWeek());
        MnbDraftRunResult result = generateDailyDrafts(today);
        log.info("Ütemezett MNB napi DRAFT-generálás kész: generált={}, kihagyott(létező)={}, hibás={}",
                result.generated(), result.skipped(), result.failed());
    }

    /**
     * Minden aktív irodához megpróbálja legenerálni az adott napi MNB DRAFT-ot.
     * Branch-enként izolált hibakezelés: egy iroda hibája nem állítja le a többit.
     *
     * @return a futás összesítője (generált / kihagyott / hibás darabszámok)
     */
    MnbDraftRunResult generateDailyDrafts(LocalDate date) {
        List<Branch> branches = branchRepository.findByIsActiveTrue();
        int generated = 0;
        int skipped = 0;
        int failed = 0;

        for (Branch branch : branches) {
            try {
                mnbReportService.generateDailyReport(branch.getId(), date);
                generated++;
            } catch (ValidationException alreadyExists) {
                // Az adott napra már létezik riport ehhez az irodához — kihagyás (nem hiba).
                skipped++;
            } catch (Exception e) {
                failed++;
                log.error("MNB napi DRAFT-generálás hiba: branchId={}, date={}, ok: {}",
                        branch.getId(), date, e.getMessage(), e);
            }
        }
        return new MnbDraftRunResult(generated, skipped, failed);
    }

    /** Egy ütemezett futás eredmény-összesítője. */
    record MnbDraftRunResult(int generated, int skipped, int failed) {
    }
}
