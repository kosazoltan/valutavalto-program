package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.service.YearOpeningService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Sprint: C3 evnyito automatikus scheduler.
 *
 * Legacy parity: a Delphi rendszerben a felhasznalo manualisan kattintott
 * evnyitora januar 1-en. A modern SAAS-ben automatikusan futtatjuk:
 *   - naptari napon: januar 1., 00:15 (UTC+1 Europe/Budapest)
 *   - minden ceghez egyszer, idempotensen (YearOpeningService ellenorzi auditlog-bol)
 *
 * Ha a rendszer nem fut januar 1-en (karbantartas, kimaradas), a napi
 * retry (januar 2-8. kozott) elkapja a lemaradt evet.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class YearOpeningScheduler {

    private static final String YEAR_OPENING_ACTION = "YEAR_OPENING";

    private final YearOpeningService yearOpeningService;
    private final CompanyRepository companyRepository;

    @Value("${valuta.scheduler.year-opening.enabled:true}")
    private boolean enabled;

    /**
     * Januar 1-tol 7-ig naponta 00:15-kor fut.
     * Cron: "0 15 0 1-7 1 *" - percek=15, ora=0, napok=1-7, honap=1 (januar)
     *
     * Minden aktiv ceghez lefuttatja az evnyitot, ha meg nem futott az adott evre.
     * Idempotens: ha mar futott, a service dob IllegalStateException-t, azt elkapjuk.
     */
    @Scheduled(cron = "0 15 0 1-7 1 *", zone = "Europe/Budapest")
    public void runAutomaticYearOpening() {
        if (!enabled) {
            log.info("YearOpeningScheduler: kikapcsolva (valuta.scheduler.year-opening.enabled=false)");
            return;
        }

        int currentYear = LocalDate.now().getYear();
        log.info("YearOpeningScheduler: automatikus evnyito inditas - {}", currentYear);

        List<Company> companies = companyRepository.findAll();
        int successCount = 0;
        int skippedCount = 0;
        int errorCount = 0;

        for (Company company : companies) {
            try {
                Map<String, Object> result = yearOpeningService.executeYearOpening(
                        currentYear, company.getId(), "SYSTEM_SCHEDULER");
                log.info("Evnyito SIKERES - company={}, result={}", company.getName(), result);
                successCount++;
            } catch (IllegalStateException alreadyDone) {
                // Mar futott ebben az evben - idempotens skip
                log.info("Evnyito SKIP (mar futott) - company={}: {}", company.getName(), alreadyDone.getMessage());
                skippedCount++;
            } catch (Exception e) {
                log.error("Evnyito HIBA - company={}: {}", company.getName(), e.getMessage(), e);
                errorCount++;
            }
        }

        log.info("YearOpeningScheduler osszesen: {} ceg - SIKERES={}, SKIP={}, HIBA={}",
                companies.size(), successCount, skippedCount, errorCount);
    }
}