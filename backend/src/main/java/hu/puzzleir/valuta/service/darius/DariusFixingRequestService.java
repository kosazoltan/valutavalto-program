package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.dto.darius.DariusBankBranchCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusBankBranchDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestLineDto;
import hu.puzzleir.valuta.entity.DariusBankBranch;
import hu.puzzleir.valuta.entity.DariusFixingRequest;
import hu.puzzleir.valuta.entity.DariusFixingRequestLine;
import hu.puzzleir.valuta.entity.DariusFixingRequestStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DariusBankBranchRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestLineRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DariusFixingRequestService {

    private static final Pattern ISO_CURRENCY_CODE = Pattern.compile("[A-Z]{3}");
    private static final int BANK_BRANCH_CODE_MAX_LENGTH = 50;
    private static final int BANK_BRANCH_NAME_MAX_LENGTH = 200;
    private static final int NOTE_MAX_LENGTH = 500;
    private static final int WORKER_CODE_MAX_LENGTH = 100;
    private static final int AMOUNT_MAX_INTEGER_DIGITS = 16;

    private final DariusBankBranchRepository bankBranchRepository;
    private final DariusFixingRequestRepository requestRepository;
    private final DariusFixingRequestLineRepository lineRepository;
    private final CurrencyRepository currencyRepository;
    private final AuditLogService auditLogService;

    @Transactional(readOnly = true)
    public List<DariusBankBranchDto> listBankBranches(boolean includeInactive) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<DariusBankBranch> branches = includeInactive
                ? bankBranchRepository.findByCompanyIdOrderByBankBranchCodeAsc(companyId)
                : bankBranchRepository.findByCompanyIdAndIsActiveTrueOrderByBankBranchCodeAsc(companyId);
        return branches.stream().map(this::toBankBranchDto).toList();
    }

    @Transactional
    public DariusBankBranchDto createBankBranch(DariusBankBranchCreateDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = currentWorkerCode();
        validateBankBranchCreate(dto);

        String code = dto.bankBranchCode();
        if (bankBranchRepository.existsByCompanyIdAndBankBranchCode(companyId, code)) {
            throw new ValidationException("Ezzel a bankfiók-kóddal már létezik bankfiók a cégben: " + code);
        }

        DariusBankBranch branch = DariusBankBranch.builder()
                .companyId(companyId)
                .bankBranchCode(code)
                .name(dto.name().trim())
                .isActive(true)
                .createdBy(workerCode)
                .build();
        DariusBankBranch saved;
        try {
            saved = bankBranchRepository.saveAndFlush(branch);
        } catch (DataIntegrityViolationException exception) {
            throw new ValidationException("Ezzel a bankfiók-kóddal már létezik bankfiók a cégben: " + code);
        }
        auditLogService.logForCompany(
                "DARIUS_BANK_BRANCH_CREATED",
                "Darius bankfiók létrehozva: " + code,
                saved.getId().toString(),
                companyId);
        return toBankBranchDto(saved);
    }

    @Transactional
    public DariusBankBranchDto deactivateBankBranch(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        currentWorkerCode();
        DariusBankBranch branch = findBankBranch(id, companyId);
        branch.setIsActive(false);
        DariusBankBranch saved = bankBranchRepository.save(branch);
        auditLogService.logForCompany(
                "DARIUS_BANK_BRANCH_DEACTIVATED",
                "Darius bankfiók inaktiválva: " + branch.getBankBranchCode(),
                id.toString(),
                companyId);
        return toBankBranchDto(saved);
    }

    @Transactional(readOnly = true)
    public List<DariusFixingRequestDto> listRequests(LocalDate date) {
        if (date == null) {
            throw new ValidationException("A fixing-igény dátuma kötelező");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<DariusFixingRequest> requests =
                requestRepository.findByCompanyIdAndRequestDateOrderByCreatedAtAsc(companyId, date);
        if (requests.isEmpty()) {
            return List.of();
        }
        Set<UUID> bankBranchIds = requests.stream()
                .map(DariusFixingRequest::getBankBranchId)
                .collect(Collectors.toSet());
        Set<UUID> requestIds = requests.stream()
                .map(DariusFixingRequest::getId)
                .collect(Collectors.toSet());
        Map<UUID, DariusBankBranch> branchesById = bankBranchRepository
                .findByCompanyIdAndIdIn(companyId, bankBranchIds)
                .stream()
                .collect(Collectors.toMap(DariusBankBranch::getId, Function.identity()));
        Map<UUID, List<DariusFixingRequestLine>> linesByRequestId = lineRepository
                .findByCompanyIdAndRequestIdInOrderByRequestIdAscCurrencyCodeAsc(companyId, requestIds)
                .stream()
                .collect(Collectors.groupingBy(DariusFixingRequestLine::getRequestId));
        return requests.stream()
                .map(request -> {
                    DariusBankBranch branch = branchesById.get(request.getBankBranchId());
                    if (branch == null) {
                        throw new ResourceNotFoundException(
                                "Darius bankfiók nem található: " + request.getBankBranchId());
                    }
                    return toRequestDto(
                            request,
                            branch,
                            linesByRequestId.getOrDefault(request.getId(), Collections.emptyList()));
                })
                .toList();
    }

    @Transactional
    public DariusFixingRequestDto create(DariusFixingRequestCreateDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = currentWorkerCode();
        if (dto == null) {
            throw new ValidationException("A fixing-igény adatai hiányoznak");
        }
        List<String> errors = new ArrayList<>();
        validateCreateHeader(dto, errors);

        DariusBankBranch branch = dto.bankBranchId() == null
                ? null
                : findBankBranch(dto.bankBranchId(), companyId);
        if (branch != null) {
            validateActiveBankBranch(branch, errors);
        }
        if (dto.bankBranchId() != null
                && dto.requestDate() != null
                && requestRepository.existsByCompanyIdAndRequestDateAndBankBranchIdAndStatusNot(
                        companyId,
                        dto.requestDate(),
                        dto.bankBranchId(),
                        DariusFixingRequestStatus.CANCELLED)) {
            errors.add("erre a napra és bankfiókra már létezik élő fixing-igény");
        }

        validateLines(dto.lines(), errors);
        throwIfErrors(errors);
        DariusFixingRequest request = DariusFixingRequest.builder()
                .companyId(companyId)
                .bankBranchId(dto.bankBranchId())
                .requestDate(dto.requestDate())
                .status(DariusFixingRequestStatus.DRAFT)
                .note(normalizeNullableText(dto.note()))
                .createdBy(workerCode)
                .build();
        DariusFixingRequest saved;
        try {
            saved = requestRepository.saveAndFlush(request);
        } catch (DataIntegrityViolationException exception) {
            throw new ValidationException("Erre a napra és bankfiókra már létezik élő fixing-igény");
        }

        List<DariusFixingRequestLine> lines = buildLines(companyId, saved.getId(), dto.lines());
        saveLines(lines);
        auditLogService.logForCompany(
                "DARIUS_FIXING_REQUEST_CREATED",
                "Darius fixing-igény létrehozva: " + saved.getRequestDate(),
                saved.getId().toString(),
                companyId);
        return toRequestDto(saved, branch, lines);
    }

    @Transactional
    public DariusFixingRequestDto updateLines(UUID id, DariusFixingRequestCreateDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        currentWorkerCode();
        DariusFixingRequest request = findRequestForUpdate(id, companyId);
        requireStatus(request, DariusFixingRequestStatus.DRAFT, "Csak DRAFT fixing-igény módosítható");
        if (dto == null) {
            throw new ValidationException("A fixing-igény adatai hiányoznak");
        }
        List<String> errors = new ArrayList<>();
        validateLines(dto.lines(), errors);
        throwIfErrors(errors);

        List<DariusFixingRequestLine> lines = buildLines(companyId, id, dto.lines());
        lineRepository.deleteByCompanyIdAndRequestId(companyId, id);
        saveLines(lines);
        auditLogService.logForCompany(
                "DARIUS_FIXING_REQUEST_UPDATED",
                "Darius fixing-igény sorai módosítva",
                id.toString(),
                companyId);
        DariusBankBranch branch = findBankBranch(request.getBankBranchId(), companyId);
        return toRequestDto(request, branch, lines);
    }

    @Transactional
    public DariusFixingRequestDto approve(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = currentWorkerCode();
        DariusFixingRequest request = findRequestForUpdate(id, companyId);
        requireStatus(request, DariusFixingRequestStatus.DRAFT, "Csak DRAFT fixing-igény hagyható jóvá");

        request.setStatus(DariusFixingRequestStatus.APPROVED);
        request.setApprovedBy(workerCode);
        request.setApprovedAt(LocalDateTime.now());
        DariusFixingRequest saved = requestRepository.save(request);
        auditLogService.logForCompany(
                "DARIUS_FIXING_REQUEST_APPROVED",
                "Darius fixing-igény jóváhagyva",
                id.toString(),
                companyId);
        return toRequestDto(saved, companyId);
    }

    @Transactional
    public DariusFixingRequestDto cancel(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = currentWorkerCode();
        DariusFixingRequest request = findRequestForUpdate(id, companyId);
        if (request.getStatus() == DariusFixingRequestStatus.INCLUDED) {
            throw new ValidationException("Az INCLUDED fixing-igény terminális, nem vonható vissza");
        }
        if (request.getStatus() != DariusFixingRequestStatus.DRAFT
                && request.getStatus() != DariusFixingRequestStatus.APPROVED) {
            throw new ValidationException("Csak DRAFT vagy APPROVED fixing-igény vonható vissza");
        }

        request.setStatus(DariusFixingRequestStatus.CANCELLED);
        request.setCancelledBy(workerCode);
        request.setCancelledAt(LocalDateTime.now());
        DariusFixingRequest saved = requestRepository.save(request);
        auditLogService.logForCompany(
                "DARIUS_FIXING_REQUEST_CANCELLED",
                "Darius fixing-igény visszavonva",
                id.toString(),
                companyId);
        return toRequestDto(saved, companyId);
    }

    private void validateBankBranchCreate(DariusBankBranchCreateDto dto) {
        List<String> errors = new ArrayList<>();
        if (dto == null) {
            throw new ValidationException("A bankfiók adatai hiányoznak");
        }
        String code = dto.bankBranchCode();
        if (code == null || code.isBlank()) {
            errors.add("a bankfiók-kód kötelező");
        } else {
            if (!code.equals(code.trim()) || code.chars().anyMatch(Character::isWhitespace)) {
                errors.add("a bankfiók-kód nem tartalmazhat whitespace karaktert");
            }
            if (code.length() > BANK_BRANCH_CODE_MAX_LENGTH) {
                errors.add("a bankfiók-kód legfeljebb 50 karakter lehet");
            }
        }
        String name = dto.name();
        if (name == null || name.isBlank()) {
            errors.add("a bankfiók neve kötelező");
        } else if (name.trim().length() > BANK_BRANCH_NAME_MAX_LENGTH) {
            errors.add("a bankfiók neve legfeljebb 200 karakter lehet");
        }
        throwIfErrors(errors);
    }

    private void validateCreateHeader(DariusFixingRequestCreateDto dto, List<String> errors) {
        if (dto.bankBranchId() == null) {
            errors.add("a bankfiók azonosítója kötelező");
        }
        if (dto.requestDate() == null) {
            errors.add("a fixing-igény dátuma kötelező");
        }
        if (dto.note() != null && dto.note().length() > NOTE_MAX_LENGTH) {
            errors.add("a megjegyzés legfeljebb 500 karakter lehet");
        }
    }

    private void validateActiveBankBranch(DariusBankBranch branch, List<String> errors) {
        if (!Boolean.TRUE.equals(branch.getIsActive())) {
            errors.add("a kiválasztott bankfiók inaktív");
        }
        String code = branch.getBankBranchCode();
        if (code == null || code.isBlank() || code.chars().anyMatch(Character::isWhitespace)) {
            errors.add("a kiválasztott bankfiók BANKFIOK_AZONOSITO kódja érvénytelen");
        }
    }

    private void validateLines(List<DariusFixingRequestLineDto> lines, List<String> errors) {
        if (lines == null || lines.isEmpty()) {
            errors.add("legalább egy fixing-igény sor kötelező");
            return;
        }

        Set<String> seenCurrencyCodes = new HashSet<>();
        for (int index = 0; index < lines.size(); index++) {
            DariusFixingRequestLineDto line = lines.get(index);
            String scope = "sor " + (index + 1) + ": ";
            if (line == null) {
                errors.add(scope + "hiányzik");
                continue;
            }

            String currencyCode = line.currencyCode();
            boolean validCurrencyFormat = currencyCode != null
                    && ISO_CURRENCY_CODE.matcher(currencyCode).matches();
            if (!validCurrencyFormat) {
                errors.add(scope + "az ISO valutakód formátuma csak [A-Z]{3} lehet: " + currencyCode);
            } else {
                if (!seenCurrencyCodes.add(currencyCode)) {
                    errors.add(scope + "duplikált valutakód: " + currencyCode);
                }
                if (currencyRepository.findByCodeAndActiveTrue(currencyCode).isEmpty()) {
                    errors.add(scope + "a valuta nem aktív vagy nem létezik: " + currencyCode);
                }
            }

            validateAmount(scope, "beszállított összeg", line.deliveredAmount(), errors);
            validateAmount(scope, "elvitt összeg", line.collectedAmount(), errors);
            if (!positive(line.deliveredAmount()) && !positive(line.collectedAmount())) {
                errors.add(scope + "legalább az egyik összeg pozitív kell legyen");
            }
        }
    }

    private void validateAmount(String scope, String field, BigDecimal amount, List<String> errors) {
        if (amount == null) {
            errors.add(scope + field + " hiányzik");
            return;
        }
        if (amount.signum() < 0) {
            errors.add(scope + field + " nem lehet negatív");
        }
        if (!isIntegral(amount)) {
            errors.add(scope + field + " csak egész lehet");
        }
        if (integerDigits(amount) > AMOUNT_MAX_INTEGER_DIGITS) {
            errors.add(scope + field + " legfeljebb 16 számjegyű lehet");
        }
    }

    private List<DariusFixingRequestLine> buildLines(
            UUID companyId,
            UUID requestId,
            List<DariusFixingRequestLineDto> lineDtos) {
        return lineDtos.stream()
                .map(line -> DariusFixingRequestLine.builder()
                        .companyId(companyId)
                        .requestId(requestId)
                        .currencyCode(line.currencyCode())
                        .deliveredAmount(line.deliveredAmount())
                        .collectedAmount(line.collectedAmount())
                        .build())
                .toList();
    }

    private void saveLines(List<DariusFixingRequestLine> lines) {
        try {
            lineRepository.saveAllAndFlush(lines);
        } catch (DataIntegrityViolationException exception) {
            throw new ValidationException("A fixing-igény sorai adatbázis-korlátot sértenek");
        }
    }

    private DariusFixingRequest findRequestForUpdate(UUID id, UUID companyId) {
        if (id == null) {
            throw new ResourceNotFoundException("Fixing-igény nem található");
        }
        return requestRepository.findForUpdateByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Fixing-igény nem található: " + id));
    }

    private DariusBankBranch findBankBranch(UUID id, UUID companyId) {
        if (id == null) {
            throw new ResourceNotFoundException("Darius bankfiók nem található");
        }
        return bankBranchRepository.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Darius bankfiók nem található: " + id));
    }

    private void requireStatus(
            DariusFixingRequest request,
            DariusFixingRequestStatus expected,
            String message) {
        if (request.getStatus() != expected) {
            throw new ValidationException(message + " (aktuális: " + request.getStatus() + ")");
        }
    }

    private DariusFixingRequestDto toRequestDto(DariusFixingRequest request, UUID companyId) {
        DariusBankBranch branch = findBankBranch(request.getBankBranchId(), companyId);
        List<DariusFixingRequestLine> lines = lineRepository
                .findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(companyId, request.getId());
        return toRequestDto(request, branch, lines);
    }

    private DariusFixingRequestDto toRequestDto(
            DariusFixingRequest request,
            DariusBankBranch branch,
            List<DariusFixingRequestLine> lines) {
        List<DariusFixingRequestLineDto> lineDtos = lines.stream()
                .map(line -> new DariusFixingRequestLineDto(
                        line.getCurrencyCode(),
                        line.getDeliveredAmount(),
                        line.getCollectedAmount()))
                .toList();
        return new DariusFixingRequestDto(
                request.getId(),
                request.getBankBranchId(),
                branch.getBankBranchCode(),
                branch.getName(),
                request.getRequestDate(),
                request.getStatus().name(),
                request.getNote(),
                request.getCreatedBy(),
                request.getCreatedAt(),
                request.getApprovedBy(),
                request.getApprovedAt(),
                request.getIncludedAt(),
                lineDtos);
    }

    private DariusBankBranchDto toBankBranchDto(DariusBankBranch branch) {
        return new DariusBankBranchDto(
                branch.getId(),
                branch.getBankBranchCode(),
                branch.getName(),
                Boolean.TRUE.equals(branch.getIsActive()));
    }

    private String currentWorkerCode() {
        String workerCode = SecurityUtils.getCurrentWorkerCode();
        if (workerCode == null || workerCode.isBlank()) {
            throw new IllegalStateException(
                    "A hitelesített worker-kód hiányzik vagy üres — rendszerállapot-hiba");
        }
        if (workerCode.length() > WORKER_CODE_MAX_LENGTH) {
            throw new IllegalStateException("A hitelesített worker-kód legfeljebb 100 karakter lehet");
        }
        return workerCode;
    }

    private String normalizeNullableText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private boolean isIntegral(BigDecimal value) {
        return value.stripTrailingZeros().scale() <= 0;
    }

    private int integerDigits(BigDecimal value) {
        BigDecimal normalized = value.abs().stripTrailingZeros();
        return Math.max(1, normalized.precision() - normalized.scale());
    }

    private boolean positive(BigDecimal value) {
        return value != null && value.signum() > 0;
    }

    private void throwIfErrors(List<String> errors) {
        if (!errors.isEmpty()) {
            throw new ValidationException(String.join("; ", errors));
        }
    }
}
