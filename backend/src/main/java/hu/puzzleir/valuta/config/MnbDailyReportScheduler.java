package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.service.MnbReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
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
    // SZÁNDÉKOSAN cross-tenant rendszer-batch: az MNB napi adatszolgáltatás minden cég
    // minden aktív irodájára kötelező, ezért a GLOBÁLIS findByIsActiveTrue() a helyes
    // (nem egy user-kérés tenant-szűrt lekérdezése). Ez NEM IDOR/tenant-leak. A metódus
    // @Deprecated ("multi-tenant kontextusban NE használd") — itt a használat tudatos.
    @SuppressWarnings("deprecation")
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
                // A service check-then-insert ellenőrzése: erre az irodára+napra már van riport.
                skipped++;
            } catch (DataIntegrityViolationException dive) {
                // Konkurens/több-instance futásnál a check és az insert között beékelődő
                // duplikátum a DB unique indexen (uq_mnb_report_branch_type_date) bukik el.
                // CSAK ezt a konkrét constraint-sértést kezeljük "már létezik" kihagyásként —
                // minden más integritás-hiba (FK / NOT NULL / egyéb) VALÓDI hiba → failed + ERROR log
                // (Codex/Copilot P1 #744: ne maszkoljuk a valós adat-hibákat skipként).
                if (isDuplicateMnbReportViolation(dive)) {
                    skipped++;
                } else {
                    failed++;
                    log.error("MNB napi DRAFT-generálás integritás-hiba (NEM duplikátum): branchId={}, date={}, ok: {}",
                            branch.getId(), date, dive.getMessage(), dive);
                }
            } catch (Exception e) {
                failed++;
                log.error("MNB napi DRAFT-generálás hiba: branchId={}, date={}, ok: {}",
                        branch.getId(), date, e.getMessage(), e);
            }
        }
        return new MnbDraftRunResult(generated, skipped, failed);
    }

    /** Az MNB napi riport branch+típus+dátum unique indexének neve (V6 migráció). */
    static final String MNB_REPORT_UNIQUE_CONSTRAINT = "uq_mnb_report_branch_type_date";

    /**
     * Igaz, ha a kivétel ok-láncában megjelenik a konkrét MNB-riport unique constraint neve
     * — azaz a hiba valóban "már létezik" duplikátum, nem más integritás-sértés.
     */
    static boolean isDuplicateMnbReportViolation(Throwable ex) {
        for (Throwable t = ex; t != null; t = t.getCause()) {
            String msg = t.getMessage();
            if (msg != null && msg.toLowerCase().contains(MNB_REPORT_UNIQUE_CONSTRAINT)) {
                return true;
            }
            if (t.getCause() == t) {
                break;
            }
        }
        return false;
    }

    /** Egy ütemezett futás eredmény-összesítője. */
    record MnbDraftRunResult(int generated, int skipped, int failed) {
    }
}
