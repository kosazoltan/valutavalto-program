package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CircularSequence;
import hu.puzzleir.valuta.entity.ReceiptSequence;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CircularSequenceRepository;
import hu.puzzleir.valuta.repository.ReceiptSequenceRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Év-nyitó workflow.
 *
 * Legacy: evnyito/unit1.pas + newyear/unit1.pas + ERTEKTAR/newyear/unit1.pas
 *
 * A modern rendszerben az év-nyitó a következő lépéseket végzi:
 * 1. Körlevél sorszámok nullázása (legacy: UTSORSZAM=0)
 * 2. Bizonylat sorszámok visszaállítása 100000-re (legacy: implicit az éves wrapben)
 * 3. Körlevél archiválás jelölése (legacy: KORLEVEL→LASTYEAR→ARCHIVE táblamásolás)
 * 4. Régi napi zárások archiválása (legacy: DROP TABLE ÉÉVHH táblák)
 * 5. Audit log az egész műveletről
 *
 * FONTOS: Csak ADMIN futtathatja, és egy évben csak egyszer!
 * Idempotencia: az audit log ellenőrzése biztosítja az egyszeri futást.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class YearOpeningService {

    private static final String YEAR_OPENING_ACTION = "YEAR_OPENING";

    private final CircularSequenceRepository circularSequenceRepository;
    private final ReceiptSequenceRepository receiptSequenceRepository;
    private final BranchRepository branchRepository;
    private final DailyClosingArchiveService dailyClosingArchiveService;
    private final CircularService circularService;
    private final AuditLogService auditLogService;

    /**
     * Teljes év-nyitó workflow végrehajtása — manuális, user-context alapú indítás.
     * A {@link SecurityUtils#getCurrentCompanyId()} és {@link SecurityUtils#getCurrentWorkerCode()}
     * adja a tenant kontextust.
     *
     * @param targetYear Az új év (pl. 2027)
     * @return Részletes eredmény-térkép
     */
    @Transactional
    public Map<String, Object> executeYearOpening(int targetYear) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String operator = SecurityUtils.getCurrentWorkerCode();
        return executeYearOpeningInternal(targetYear, companyId, operator);
    }

    /**
     * Teljes év-nyitó workflow végrehajtása — explicit companyId paraméterrel,
     * automata scheduler/system kontextushoz, ahol nincs Spring Security user session.
     *
     * @param targetYear Az új év (pl. 2027)
     * @param companyId  Annak a cégnek az ID-je, amelyikre az év-nyitó fut
     * @param operatorLabel Naplóban megjelenő operator (pl. "SCHEDULER" vagy "system-cron")
     * @return Részletes eredmény-térkép
     */
    @Transactional
    public Map<String, Object> executeYearOpening(int targetYear, UUID companyId, String operatorLabel) {
        if (companyId == null) {
            throw new IllegalArgumentException("executeYearOpening(targetYear, companyId, ...) - companyId nem lehet null");
        }
        String operator = (operatorLabel == null || operatorLabel.isBlank()) ? "SYSTEM" : operatorLabel;
        return executeYearOpeningInternal(targetYear, companyId, operator);
    }

    private Map<String, Object> executeYearOpeningInternal(int targetYear, UUID companyId, String operator) {
        LocalDateTime now = LocalDateTime.now();

        log.info("ÉV-NYITÓ INDÍTÁS: targetYear={}, company={}, operator={}", targetYear, companyId, operator);

        // Validáció: nem futtatható visszamenőleg vagy előre
        int currentYear = LocalDate.now().getYear();
        if (targetYear != currentYear && targetYear != currentYear + 1) {
            throw new IllegalArgumentException(
                "Év-nyitó csak az aktuális (" + currentYear + ") vagy a következő ("
                    + (currentYear + 1) + ") évre futtatható. Kért: " + targetYear);
        }

        // B2 FIX: Idempotencia — ellenőrzés, hogy az adott company-ra/évre már futott-e
        // (a referencia formátum: "<companyId>:<targetYear>", így ugyanaz a year külön company-ra független)
        String idempotencyRef = companyId + ":" + targetYear;
        if (auditLogService.existsByActionAndReference(YEAR_OPENING_ACTION, idempotencyRef)) {
            throw new IllegalStateException(
                "Év-nyitó már végrehajtva a(z) " + companyId + " cégre, " + targetYear + ". évre! Duplikált futtatás nem engedélyezett.");
        }

        // B1/B3 FIX: Tenant-izolált branch ID-k lekérése
        List<UUID> companyBranchIds = branchRepository.findByCompanyId(companyId).stream()
            .map(Branch::getId)
            .collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("targetYear", targetYear);
        result.put("operator", operator);
        result.put("startedAt", now.toString());

        // 1. Körlevél sorszámok nullázása
        int circularSeqReset = resetCircularSequences(companyId);
        result.put("circularSequencesReset", circularSeqReset);
        log.info("ÉV-NYITÓ 1/4: {} körlevél sorszám nullázva", circularSeqReset);

        // 2. Bizonylat sorszámok visszaállítása (tenant-izolált)
        int receiptSeqReset = resetReceiptSequences(companyBranchIds);
        result.put("receiptSequencesReset", receiptSeqReset);
        log.info("ÉV-NYITÓ 2/4: {} bizonylat sorszám visszaállítva", receiptSeqReset);

        // 3. Körlevél archiválás (előző évi → archivált)
        int circularsArchived = archiveCirculars(companyId, targetYear - 1);
        result.put("circularsArchived", circularsArchived);
        log.info("ÉV-NYITÓ 3/4: {} körlevél archiválva ({}. év)", circularsArchived, targetYear - 1);

        // 4. Napi zárások archiválása (2 évnél régebbi, tenant-izolált)
        int closingsArchived = archiveDailyClosings(companyBranchIds, targetYear - 2);
        result.put("dailyClosingsArchived", closingsArchived);
        log.info("ÉV-NYITÓ 4/4: {} napi zárás archiválva ({}. évig)", closingsArchived, targetYear - 2);

        // Audit log (egyben idempotencia-jelölő — referenciakulcs: "<companyId>:<targetYear>")
        auditLogService.log(YEAR_OPENING_ACTION,
            String.format("Év-nyitó végrehajtva: %d. év, company=%s, operator=%s, circularSeq=%d, receiptSeq=%d, circulars=%d, closings=%d",
                targetYear, companyId, operator, circularSeqReset, receiptSeqReset, circularsArchived, closingsArchived),
            idempotencyRef);

        result.put("completedAt", LocalDateTime.now().toString());
        result.put("status", "SUCCESS");

        log.info("ÉV-NYITÓ KÉSZ: targetYear={}, eredmény={}", targetYear, result);
        return result;
    }

    /**
     * Utolsó év-nyitó futás lekérdezése (GET /status-hoz).
     *
     * @return Utolsó futás adatai, vagy üres map ha még nem futott
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getLastExecution() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        int currentYear = LocalDate.now().getYear();
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("currentYear", currentYear);

        boolean ranForCurrentYear = auditLogService.existsByActionAndReference(
            YEAR_OPENING_ACTION, companyId + ":" + currentYear);
        boolean ranForNextYear = auditLogService.existsByActionAndReference(
            YEAR_OPENING_ACTION, companyId + ":" + (currentYear + 1));

        status.put("executedForCurrentYear", ranForCurrentYear);
        status.put("executedForNextYear", ranForNextYear);
        status.put("canExecuteForCurrentYear", !ranForCurrentYear);
        status.put("canExecuteForNextYear", !ranForNextYear);

        return status;
    }

    /**
     * Körlevél sorszámok nullázása.
     * Legacy: UPDATE ADATOK SET UTSORSZAM=0, UTVIPSORSZAM=0, UTZALOGSORSZAM=0
     */
    private int resetCircularSequences(UUID companyId) {
        List<CircularSequence> sequences = circularSequenceRepository.findByCompanyId(companyId);
        if (!sequences.isEmpty()) {
            sequences.forEach(seq -> seq.setLastNumber(0));
            circularSequenceRepository.saveAll(sequences);
        }
        return sequences.size();
    }

    /**
     * Bizonylat sorszámok visszaállítása 100000-re (tenant-izolált).
     * Legacy: implicit — a Delphi rendszerben a sorszámok az éves táblákban voltak.
     *
     * @param branchIds A céghez tartozó irodák ID-i
     */
    private int resetReceiptSequences(List<UUID> branchIds) {
        if (branchIds.isEmpty()) {
            return 0;
        }

        List<ReceiptSequence> sequences = receiptSequenceRepository.findByBranchIdIn(branchIds);
        for (ReceiptSequence seq : sequences) {
            seq.setLastSellReceipt(100000L);
            seq.setLastBuyReceipt(100000L);
            seq.setLastTransferOutReceipt(100000L);
            seq.setLastTransferInReceipt(100000L);
            seq.setLastForintTransferOutReceipt(100000L);
            seq.setLastForintTransferInReceipt(100000L);
            seq.setLastConversionReceipt(100000L);
        }
        receiptSequenceRepository.saveAll(sequences);
        return sequences.size();
    }

    /**
     * Előző évi körlevelek archiválása.
     * Legacy: KORLEVEL→LASTYEAR (táblamásolás), LASTYEAR→ARCHIVE
     * Modern: Archivált flag beállítása.
     */
    private int archiveCirculars(UUID companyId, int archiveYear) {
        return circularService.archiveByYear(companyId, archiveYear);
    }

    /**
     * Régi napi zárások archiválása (tenant-izolált).
     * Legacy: DROP TABLE ARFE1812, BF1812, stb.
     * Modern: Régi snapshot rekordok törlése.
     *
     * @param branchIds A céghez tartozó irodák ID-i
     * @param beforeYear Ennél régebbi év törlése
     */
    private int archiveDailyClosings(List<UUID> branchIds, int beforeYear) {
        if (branchIds.isEmpty()) {
            return 0;
        }
        return dailyClosingArchiveService.archiveBeforeYear(branchIds, beforeYear);
    }
}
