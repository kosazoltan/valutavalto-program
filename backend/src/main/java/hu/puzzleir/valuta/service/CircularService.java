package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
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
    @Transactional
    public CircularDto create(CreateCircularDto dto, Long workerId) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        Circular circular = Circular.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .createdBy(worker)
                .companyId(SecurityUtils.getCurrentCompanyId())
                .urgent(dto.getUrgent() != null ? dto.getUrgent() : false)
                .build();

        circular = circularRepository.save(circular);
        return toDto(circular);
    }

    /**
     * Körlevél tudomásul vétele.
     */
    @Transactional
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
        // companyId-t a branch-ból lehetne de egyszerűsítve null-t küldünk
        return circularRepository.findRelevantForBranch(branchId, null).stream()
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
    @Transactional
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
    @Transactional
    public CircularDto acknowledgeByWorker(Long circularId) {
        Circular circular = findOrThrow(circularId);
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Ellenőrzés: már nyugtázta-e
        if (acknowledgmentRepository.findByCircularIdAndWorkerId(circularId, workerId).isPresent()) {
            throw new ValidationException("Már nyugtáztad ezt a körlevelet!");
        }

        CircularAcknowledgment ack = CircularAcknowledgment.builder()
                .circular(circular)
                .workerId(workerId)
                .acknowledgedAt(LocalDateTime.now())
                .build();

        acknowledgmentRepository.save(ack);

        log.info("Körlevél nyugtázva: circularId={}, workerId={}", circularId, workerId);
        return toDto(circular);
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
    @Transactional
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
    @Transactional
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
    @Transactional
    public CircularDto uploadAttachment(Long circularId, MultipartFile file) throws IOException {
        Circular circular = findOrThrow(circularId);

        // Tárhelykönyvtár létrehozása
        Path basePath = Paths.get(attachmentBasePath);
        Files.createDirectories(basePath);

        // Fájlnév: {circularId}_{eredeti_név}
        String safeFilename = circularId + "_" + file.getOriginalFilename()
                .replaceAll("[^a-zA-Z0-9._-]", "_");
        Path targetPath = basePath.resolve(safeFilename);

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

    private Circular findOrThrow(Long id) {
        return circularRepository.findById(id)
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
