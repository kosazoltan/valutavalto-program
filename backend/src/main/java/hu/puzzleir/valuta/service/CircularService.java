package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.LegacyCompanyIdentityCodec;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Körlevél service — CRUD + acknowledge.
 *
 * Legacy: korlev.dll — központi utasítások a pénztáraknak.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CircularService {

    private final CircularRepository circularRepository;
    private final CircularAcknowledgmentRepository acknowledgmentRepository;
    private final CircularReplyRepository replyRepository;
    private final CircularSequenceRepository sequenceRepository;
    private final WorkerRepository workerRepository;

    @Value("${circular.attachment.path:./data/circulars}")
    private String attachmentBasePath;

    /**
     * Összes körlevél listázása.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findAll() {
        return circularRepository.findAllOrderByCreatedAtDesc().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Egy körlevél lekérdezése.
     */
    @Transactional(readOnly = true)
    public CircularDto findById(Long id) {
        return toDto(findOrThrow(id));
    }

    /**
     * Körlevél létrehozása.
     */
    @Transactional(rollbackFor = Exception.class)
    public CircularDto create(CreateCircularDto dto, Long workerId) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        Circular circular = Circular.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .createdBy(worker)
                .companyId(SecurityUtils.getCurrentCompanyId())
                .urgent(dto.getUrgent() != null ? dto.getUrgent() : false)
                .requiresAcknowledgment(dto.getRequiresAcknowledgment() != null && dto.getRequiresAcknowledgment())
                .allowsReply(dto.getAllowsReply() != null && dto.getAllowsReply())
                .build();

        circular = circularRepository.save(circular);
        return toDto(circular);
    }

    /**
     * Körlevél tudomásul vétele.
     */
    @Transactional(rollbackFor = Exception.class)
    public CircularDto acknowledge(Long circularId) {
        Circular circular = findOrThrow(circularId);

        if (Boolean.TRUE.equals(circular.getAcknowledged())) {
            throw new ValidationException("A körlevél már tudomásul lett véve!");
        }

        circular.setAcknowledged(true);
        circular.setAcknowledgedAt(LocalDateTime.now());
        circular = circularRepository.save(circular);
        return toDto(circular);
    }

    /**
     * Még nem nyugtázott körlevelek.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findUnacknowledged() {
        return circularRepository.findUnacknowledged().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Típus szerinti szűrés.
     * Legacy: KORLEV mappák szerinti szétválasztás
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findByType(CircularType type) {
        return circularRepository.findByType(type).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Irodához releváns körlevelek — szűri a célcsoportot.
     * Legacy: KorlevelOlvasas — a pénztáros bejelentkezéskor
     * kapta meg a rá vonatkozó körleveleket.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findRelevantForCurrentBranch() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Integer legacyCompanyId = LegacyCompanyIdentityCodec.toLegacyInt(SecurityUtils.getCurrentCompanyId());
        return circularRepository.findRelevantForBranch(branchId, legacyCompanyId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Körlevél létrehozása típussal és célcsoporttal.
     *
     * Legacy: A szerver oldalon (KORLEV\SERVER\Unit1.pas) az értéktáras
     * készítette a körleveleket ODT/DOCX formátumban és FTP-n terjesztette.
     * Az új rendszerben REST API-n keresztül történik.
     */
    @Transactional(rollbackFor = Exception.class)
    public CircularDto createTyped(CreateCircularDto dto, Long workerId,
                                    CircularType type,
                                    CircularType.CircularTarget target,
                                    CircularType.CircularPriority priority,
                                    UUID targetBranchId,
                                    Integer targetCompanyId,
                                    String registrationNumber) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        Circular circular = Circular.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .createdBy(worker)
                .companyId(SecurityUtils.getCurrentCompanyId())
                .circularType(type)
                .target(target != null ? target : type.getDefaultTarget())
                .priority(priority != null ? priority : type.getDefaultPriority())
                .urgent(priority == CircularType.CircularPriority.URGENT
                        || (dto.getUrgent() != null && dto.getUrgent()))
                .requiresAcknowledgment(dto.getRequiresAcknowledgment() != null && dto.getRequiresAcknowledgment())
                .allowsReply(dto.getAllowsReply() != null && dto.getAllowsReply())
                .targetBranchId(targetBranchId)
                .targetCompanyId(targetCompanyId)
                .registrationNumber(registrationNumber)
                .validFrom(LocalDate.now())
                .build();

        circular = circularRepository.save(circular);
        log.info("Körlevél létrehozva: id={}, type={}, target={}, priority={}, title={}",
                circular.getId(), type, target, priority, dto.getTitle());

        return toDto(circular);
    }

    /**
     * Iktatószám keresés.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> searchByRegistrationNumber(String query) {
        return circularRepository.findByRegistrationNumberContainingIgnoreCase(query).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Összes elérhető körlevél típus listázása.
     */
    public List<Map<String, Object>> listTypes() {
        return Arrays.stream(CircularType.values())
                .map(t -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("type", t.name());
                    m.put("description", t.getDescription());
                    m.put("defaultTarget", t.getDefaultTarget().name());
                    m.put("defaultPriority", t.getDefaultPriority().name());
                    return m;
                })
                .collect(Collectors.toList());
    }

    // ============ V88: LEGACY PARITÁS — PER-WORKER NYUGTÁZÁS ============

    /**
     * Per-worker nyugtázás.
     * Legacy: AT.xxx fájlba beírta a dolgozó nevét és az időpontot.
     * Modern: circular_acknowledgment táblába kerül.
     */
    @Transactional(rollbackFor = Exception.class)
    public CircularDto acknowledgeByWorker(Long circularId) {
        Circular circular = findOrThrow(circularId);
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Ellenőrzés: már nyugtázta-e
        if (acknowledgmentRepository.findByCircularIdAndWorkerId(circularId, workerId).isPresent()) {
            throw new ValidationException("Már nyugtáztad ezt a körlevelet!");
        }

        // G21: a nyugtázó szerepkörének rögzítése a szerepkörönkénti megoszlás-riporthoz.
        String ackRole = SecurityUtils.getActiveOperationalRole();
        if (ackRole == null || ackRole.isBlank()) {
            ackRole = SecurityUtils.getCurrentRole();
        }

        CircularAcknowledgment ack = CircularAcknowledgment.builder()
                .circular(circular)
                .workerId(workerId)
                .acknowledgedAt(LocalDateTime.now())
                .acknowledgerRole(ackRole)
                .build();

        acknowledgmentRepository.save(ack);

        log.info("Körlevél nyugtázva: circularId={}, workerId={}, szerepkör={}", circularId, workerId, ackRole);
        return toDto(circular);
    }

    // ============ FS-C: KÉTIRÁNYÚ VÁLASZ ============

    /** FS-C (Center FS-1): pénztárosi válasz — csak allowsReply=true körlevélre. */
    @Transactional(rollbackFor = Exception.class)
    public CircularReplyDto reply(Long circularId, String replyText) {
        Circular circular = findOrThrow(circularId); // cég-szűrt (IDOR F-6)

        if (!Boolean.TRUE.equals(circular.getAllowsReply())) {
            throw new ValidationException("Erre a körlevélre nem küldhető válasz!");
        }
        String text = replyText == null ? "" : replyText.trim();
        if (text.isEmpty()) {
            throw new ValidationException("A válasz szövege nem lehet üres!");
        }
        if (text.length() > 4000) {
            throw new ValidationException("A válasz legfeljebb 4000 karakter lehet!");
        }

        CircularReply reply = CircularReply.builder()
                .circular(circular)
                .workerId(SecurityUtils.getCurrentWorkerId())
                .companyId(SecurityUtils.getCurrentCompanyId())
                .branchId(SecurityUtils.getCurrentBranchIdOrNull())
                .replyText(text)
                .createdAt(LocalDateTime.now())
                .build();
        reply = replyRepository.save(reply);

        log.info("Körlevél-válasz rögzítve: circularId={}, workerId={}", circularId,
                reply.getWorkerId());
        return toReplyDto(reply, circularId);
    }

    /** FS-C: a körlevél válaszai (center-nézet) — cég-szűrt. */
    @Transactional(readOnly = true)
    public List<CircularReplyDto> getReplies(Long circularId) {
        findOrThrow(circularId); // 404 cross-tenant/nem létező esetén
        return replyRepository
                .findByCircularIdAndCompanyId(circularId, SecurityUtils.getCurrentCompanyId())
                .stream()
                .map(r -> toReplyDto(r, circularId))
                .collect(Collectors.toList());
    }

    private CircularReplyDto toReplyDto(CircularReply r, Long circularId) {
        String workerName = workerRepository.findById(r.getWorkerId())
                .map(Worker::getName).orElse(null);
        return CircularReplyDto.builder()
                .id(r.getId())
                .circularId(circularId)
                .workerId(r.getWorkerId())
                .workerName(workerName)
                .branchId(r.getBranchId() != null ? r.getBranchId().toString() : null)
                .replyText(r.getReplyText())
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                .build();
    }

    /**
     * G21: körlevél nyugtázásainak szerepkörönkénti megoszlása (EXCMD b9-korlevelek FR-2).
     * A null/üres szerepkörű (régi) nyugtázások az "ISMERETLEN" kulcs alá kerülnek.
     *
     * @return szerepkör → nyugtázások száma
     */
    @Transactional(readOnly = true)
    public Map<String, Long> getAcknowledgmentBreakdownByRole(Long circularId) {
        findOrThrow(circularId); // 404, ha nincs ilyen körlevél
        return acknowledgmentRepository.findByCircularId(circularId).stream()
                .collect(Collectors.groupingBy(
                        a -> (a.getAcknowledgerRole() == null || a.getAcknowledgerRole().isBlank())
                                ? "ISMERETLEN" : a.getAcknowledgerRole(),
                        Collectors.counting()));
    }

    /**
     * Adott dolgozóhoz még nem nyugtázott körlevelek.
     * Legacy: bejelentkezéskor a pénztáros kapta a rá vonatkozó, nem olvasott körleveleket.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findUnacknowledgedForCurrentWorker() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return circularRepository.findUnacknowledgedForWorker(companyId, workerId, branchId, null)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Körlevél nyugtázási státusza (hány dolgozó nyugtázta).
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getAcknowledgmentStatus(Long circularId) {
        Circular circular = findOrThrow(circularId);
        List<CircularAcknowledgment> acks = acknowledgmentRepository.findByCircularId(circularId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("circularId", circularId);
        result.put("title", circular.getTitle());
        result.put("totalAcknowledged", acks.size());
        result.put("acknowledgments", acks.stream().map(a -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("workerId", a.getWorkerId());
            m.put("acknowledgedAt", a.getAcknowledgedAt().toString());
            return m;
        }).collect(Collectors.toList()));

        return result;
    }

    // ============ V88: AUTO-SORSZÁMOZÁS ============

    /**
     * Auto-sorszám generálás.
     * Legacy: FZS001, FZS002, BT008, KI001 — prefix + 3 számjegy.
     */
    @Transactional(rollbackFor = Exception.class)
    public String generateRegistrationNumber(UUID companyId, String prefix) {
        CircularSequence seq = sequenceRepository.findForUpdate(companyId, prefix)
                .orElseGet(() -> {
                    CircularSequence newSeq = CircularSequence.builder()
                            .companyId(companyId)
                            .prefix(prefix)
                            .lastNumber(0)
                            .build();
                    return sequenceRepository.save(newSeq);
                });

        seq.setLastNumber(seq.getLastNumber() + 1);
        sequenceRepository.save(seq);

        return prefix + String.format("%03d", seq.getLastNumber());
    }

    // ============ V88: KATEGÓRIÁK ============

    /**
     * Körlevelek kategória szerint (GENERAL, VIP, ZALOG).
     * Legacy: almappák a KORLEVEL könyvtárban.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findByCategory(String category) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return circularRepository.findByCategoryAndCompanyId(companyId, category)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ V88: ARCHIVÁLÁS ============

    /**
     * Körlevél archiválása.
     * Legacy: LASTYEAR mappába kerültek az előző évi körlevelek,
     * ARCHIVE mappába a régebbiek.
     */
    @Transactional(rollbackFor = Exception.class)
    public CircularDto archive(Long circularId) {
        Circular circular = findOrThrow(circularId);

        if (Boolean.TRUE.equals(circular.getArchived())) {
            throw new ValidationException("A körlevél már archiválva van!");
        }

        circular.setArchived(true);
        circular.setArchivedAt(LocalDateTime.now());
        circular.setArchiveYear(LocalDate.now().getYear());

        log.info("Körlevél archiválva: id={}, year={}", circularId, circular.getArchiveYear());
        return toDto(circularRepository.save(circular));
    }

    /**
     * Archivált körlevelek listázása.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findArchived() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return circularRepository.findArchivedByCompanyId(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Adott évi körlevelek tömeges archiválása (év-nyitó workflow).
     * Legacy: KORLEVEL→LASTYEAR (newyear/unit1.pas)
     *
     * @param companyId Cég azonosító
     * @param year Az archiválandó év
     * @return Archivált körlevelek száma
     */
    @Transactional
    public int archiveByYear(UUID companyId, int year) {
        List<Circular> circulars = circularRepository.findByCompanyIdAndYear(companyId, year);
        int count = 0;
        for (Circular c : circulars) {
            if (!Boolean.TRUE.equals(c.getArchived())) {
                c.setArchived(true);
                c.setArchivedAt(LocalDateTime.now());
                c.setArchiveYear(year);
                circularRepository.save(c);
                count++;
            }
        }
        log.info("Körlevelek archiválva: company={}, year={}, count={}", companyId, year, count);
        return count;
    }

    /**
     * Archívum év szerint.
     * Legacy: ARC2019 fájl, LASTYEAR mappa.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findByArchiveYear(Integer year) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return circularRepository.findByArchiveYear(companyId, year)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ V88: FÁJL FELTÖLTÉS/LETÖLTÉS ============

    /**
     * Csatolmány feltöltése körlevélhez.
     * Legacy: ODT/DOCX/PDF fájlok a KORLEVEL mappában.
     */
    @Transactional(rollbackFor = Exception.class)
    public CircularDto uploadAttachment(Long circularId, MultipartFile file) throws IOException {
        Circular circular = findOrThrow(circularId);

        // Tárhelykönyvtár létrehozása (audit-iter3 P0 CodeQL java/path-injection fix, 2026-04-27):
        // basePath canonicalize - toAbsolutePath().normalize() symlink + relative path eliminálása
        Path basePath = Paths.get(attachmentBasePath).toAbsolutePath().normalize();
        Files.createDirectories(basePath);

        // Fájlnév sanitizálás 2 lépésben:
        // 1) "../" path-traversal sequence cseréje (a regex "[^a-zA-Z0-9._-]" megengedte a "."-t,
        //    igy "../" eredeti "_../"-ra masolt volna, de a ".." átmaradna szegmenskent)
        // 2) maradék veszélyes karakterek cseréje
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "unknown";
        String safeFilename = circularId + "_" + original
                .replace("..", "_")
                .replaceAll("[^a-zA-Z0-9._-]", "_");
        // Defense in depth: normalize + startsWith check - garantáljuk hogy a final path
        // a basePath-on belül marad. Ha nem, throw - path-injection NEM lehetséges.
        Path targetPath = basePath.resolve(safeFilename).normalize();
        if (!targetPath.startsWith(basePath)) {
            throw new ValidationException("Tilos path-traversal kíserlet a fájlnévben: " + original);
        }

        Files.copy(file.getInputStream(), targetPath);

        circular.setAttachmentFilename(file.getOriginalFilename());
        circular.setAttachmentMimeType(file.getContentType());
        circular.setAttachmentPath(targetPath.toString());
        circular.setAttachmentSize(file.getSize());

        log.info("Csatolmány feltöltve: circularId={}, file={}, size={}",
                circularId, file.getOriginalFilename(), file.getSize());

        return toDto(circularRepository.save(circular));
    }

    /**
     * Csatolmány letöltése.
     */
    @Transactional(readOnly = true)
    public Path getAttachmentPath(Long circularId) {
        Circular circular = findOrThrow(circularId);
        if (circular.getAttachmentPath() == null) {
            throw new ResourceNotFoundException("Nincs csatolmány ehhez a körlevélhez: " + circularId);
        }
        Path path = Paths.get(circular.getAttachmentPath());
        if (!Files.exists(path)) {
            throw new ResourceNotFoundException("A csatolmány fájl nem található: " + circular.getAttachmentFilename());
        }
        return path;
    }

    /**
     * Aktív körlevelek (company szűréssel).
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findActiveForCompany() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return circularRepository.findActiveByCompanyId(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    /**
     * IDOR-fix (F-6): cég-szűrt körlevél-betöltés. Minden hívó (findById, acknowledge,
     * acknowledgeByWorker, getAcknowledgmentBreakdownByRole, getAcknowledgmentStatus,
     * archive, uploadAttachment, getAttachmentPath) ezen az egy ponton védve.
     * Cross-tenant és nem létező id egyformán ResourceNotFoundException → nincs
     * id-enumerációs oldalcsatorna. Mind a 8 hívó request-scoped, auth-olt controller
     * végpontról fut (nincs @Scheduled/belső auth-mentes hívó), így a getCurrentCompanyId()
     * mindig kontextusban van.
     */
    private Circular findOrThrow(Long id) {
        return circularRepository.findByIdAndCompanyId(id, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Körlevél nem található: " + id));
    }

    private CircularDto toDto(Circular c) {
        // Per-worker nyugtázás ellenőrzése (ha van bejelentkezett felhasználó)
        boolean isAcknowledgedByCurrentWorker = false;
        long ackCount = 0;
        try {
            Long workerId = SecurityUtils.getCurrentWorkerId();
            isAcknowledgedByCurrentWorker = acknowledgmentRepository
                    .findByCircularIdAndWorkerId(c.getId(), workerId).isPresent();
            ackCount = acknowledgmentRepository.countByCircularId(c.getId());
        } catch (Exception ignored) {
            // Ha nincs bejelentkezett user, marad false
        }

        return CircularDto.builder()
                .id(c.getId())
                .title(c.getTitle())
                .content(c.getContent())
                .createdById(c.getCreatedBy().getId())
                .createdByName(c.getCreatedBy().getName())
                .urgent(c.getUrgent())
                .requiresAcknowledgment(c.getRequiresAcknowledgment())
                .allowsReply(Boolean.TRUE.equals(c.getAllowsReply()))
                .acknowledged(isAcknowledgedByCurrentWorker || Boolean.TRUE.equals(c.getAcknowledged()))
                .acknowledgedAt(c.getAcknowledgedAt() != null ? c.getAcknowledgedAt().toString() : null)
                .createdAt(c.getCreatedAt() != null ? c.getCreatedAt().toString() : null)
                // Típus rendszer
                .circularType(c.getCircularType() != null ? c.getCircularType().name() : null)
                .circularTypeDescription(c.getCircularType() != null ? c.getCircularType().getDescription() : null)
                .target(c.getTarget() != null ? c.getTarget().name() : null)
                .priority(c.getPriority() != null ? c.getPriority().name() : null)
                .registrationNumber(c.getRegistrationNumber())
                .attachmentFilename(c.getAttachmentFilename())
                .validFrom(c.getValidFrom() != null ? c.getValidFrom().toString() : null)
                .validTo(c.getValidTo() != null ? c.getValidTo().toString() : null)
                // V88 bővítés
                .category(c.getCategory())
                .archived(c.getArchived())
                .archiveYear(c.getArchiveYear())
                .attachmentSize(c.getAttachmentSize())
                .acknowledgmentCount(ackCount)
                .build();
    }
}
