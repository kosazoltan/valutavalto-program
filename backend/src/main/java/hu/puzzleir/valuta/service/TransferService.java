package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.transfer.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class TransferService {

    private final TransferRepository transferRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final ReceiptSequenceService receiptSequenceService;
    private final AuditLogService auditLogService;

    @Transactional(rollbackFor = Exception.class)
    public TransferDto create(CreateTransferDto dto, Long workerId) {
        Worker fromWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));
        Branch fromBranch = fromWorker.getBranch();
        if (fromBranch == null) {
            throw new ValidationException("A dolgozóhoz nincs fiók rendelve!");
        }

        Branch toBranch = branchRepository.findById(UUID.fromString(dto.getToBranchId()))
                .orElseThrow(() -> new ResourceNotFoundException("Célfiók nem található: " + dto.getToBranchId()));

        Currency currency = currencyRepository.findById(dto.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + dto.getCurrencyId()));

        if (fromBranch.getId().equals(toBranch.getId())) {
            throw new ValidationException("A forrás és cél fiók nem lehet azonos!");
        }

        // Direction meghatározása (default: UF)
        Transfer.TransferDirection direction = Transfer.TransferDirection.UF;
        if (dto.getDirection() != null && !dto.getDirection().isBlank()) {
            try {
                direction = Transfer.TransferDirection.valueOf(dto.getDirection());
            } catch (IllegalArgumentException e) {
                throw new ValidationException("Érvénytelen átadás irány: " + dto.getDirection()
                        + ". Lehetséges értékek: F, U, UF, FF");
            }
        }

        String transferNumber = generateTransferNumber();

        Transfer transfer = Transfer.builder()
                .transferNumber(transferNumber)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .transferType(Transfer.TransferType.valueOf(dto.getTransferType()))
                .status(Transfer.TransferStatus.PENDING)
                .transferDate(LocalDate.now())
                .transferTime(LocalTime.now())
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(dto.getHufValue())
                .direction(direction)
                .handoverPrinted(false)
                .receiptPrinted(false)
                .notes(dto.getNotes())
                .carrierName(dto.getCarrierName())
                .sealNumber(dto.getSealNumber())
                .build();

        // #6: több-valutás átadólap — a sorokat a transfer-hez csatoljuk (cascade ALL menti).
        if (dto.getLines() != null && !dto.getLines().isEmpty()) {
            int lineNo = 1;
            for (var lineDto : dto.getLines()) {
                Currency lineCurrency = currencyRepository.findById(lineDto.getCurrencyId())
                        .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + lineDto.getCurrencyId()));
                transfer.getLines().add(TransferLine.builder()
                        .transfer(transfer)
                        .currency(lineCurrency)
                        .amount(lineDto.getAmount())
                        .lineNo(lineNo++)
                        .build());
            }
        }

        transfer = transferRepository.save(transfer);

        // Counter-tranzakciók létrehozása a direction alapján
        createCounterTransactions(transfer, fromWorker, direction);

        // Audit log
        auditLogService.log("TRANSFER_CREATED",
                String.format("Átadás létrehozva: %s, irány: %s, összeg: %s %s, %s -> %s",
                        transferNumber, direction, dto.getAmount(), currency.getCode(),
                        fromBranch.getCode(), toBranch.getCode()),
                transfer.getId());

        return toDto(transfer);
    }

    @Transactional(rollbackFor = Exception.class)
    public TransferDto receive(Long id, ReceiveTransferDto dto, Long workerId) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING &&
            transfer.getStatus() != Transfer.TransferStatus.IN_TRANSIT) {
            throw new ValidationException("Csak függőben lévő vagy szállítás alatt lévő átadás fogadható!");
        }

        Worker toWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        // HIGH FIX #10: Objects.equals használata — biztos összehasonlítás LAZY branch esetén is
        if (toWorker.getBranch() != null && !java.util.Objects.equals(
                toWorker.getBranch().getId(), transfer.getToBranch().getId())) {
            throw new ValidationException("Csak a célfiók dolgozói fogadhatják ezt az átadást!");
        }

        transfer.setToWorker(toWorker);
        transfer.setReceivedAmount(dto.getReceivedAmount());
        transfer.setReceivedDate(LocalDate.now());
        transfer.setReceivedTime(LocalTime.now());
        transfer.setDifference(dto.getReceivedAmount().subtract(transfer.getAmount()));
        transfer.setStatus(Transfer.TransferStatus.COMPLETED);

        if (dto.getNotes() != null) {
            transfer.setNotes((transfer.getNotes() != null ? transfer.getNotes() + "\n" : "") + dto.getNotes());
        }

        Transfer.TransferDirection direction = transfer.getDirection() != null
                ? transfer.getDirection() : Transfer.TransferDirection.UF;

        // Kassza egyenleg frissítés PESSIMISTIC LOCK-kal, direction alapján
        updateCashBalancesOnReceive(transfer, dto.getReceivedAmount(), direction);

        // TRANSFER_IN tranzakció létrehozása a fogadó fióknál (U és FF módot a create már kezelte)
        // Receive-nél csak F és UF módban kell TRANSFER_IN-t létrehozni
        // F mód: a create-nál TRANSFER_OUT jött létre, receive-nél nincs TRANSFER_IN (csak kassza frissül)
        // U mód: a create-nál nincs TRANSFER_OUT, receive-nél TRANSFER_IN jön létre — DE a create-nál már létrejött
        // Valójában: receive-nél nincs új tranzakció, a create-nál már minden létrejött direction szerint
        // KIVÉVE: F mód esetén a fogadó oldal tranzakciója a receive-nél jön létre
        if (direction == Transfer.TransferDirection.F) {
            // F mód: receive-nél a fogadó oldali TRANSFER_IN tranzakció
            createTransferInTransaction(transfer, toWorker, transfer.getToBranch());
            log.info("TRANSFER_IN tranzakció létrehozva receive-nél (F mód): {}", transfer.getTransferNumber());
        }

        transfer = transferRepository.save(transfer);

        // Audit log
        auditLogService.log("TRANSFER_RECEIVED",
                String.format("Átadás fogadva: %s, irány: %s, fogadott összeg: %s, különbözet: %s",
                        transfer.getTransferNumber(), direction,
                        dto.getReceivedAmount(), transfer.getDifference()),
                transfer.getId());

        return toDto(transfer);
    }

    @Transactional(rollbackFor = Exception.class)
    public TransferDto reject(Long id, String reason, Long workerId) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő átadás utasítható el!");
        }

        Worker toWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        transfer.setToWorker(toWorker);
        transfer.setStatus(Transfer.TransferStatus.REJECTED);
        transfer.setNotes((transfer.getNotes() != null ? transfer.getNotes() + "\n" : "") + "Elutasítás oka: " + reason);
        transfer = transferRepository.save(transfer);
        return toDto(transfer);
    }

    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long id) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő átadás törölhető!");
        }

        // IDOR védelem: csak a küldő fiók dolgozói törölhetik
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        if (!transfer.getFromBranch().getId().equals(currentBranchId)) {
            throw new ValidationException("Csak a küldő fiók dolgozói törölhetik az átadást!");
        }

        transfer.setStatus(Transfer.TransferStatus.CANCELLED);
        transferRepository.save(transfer);
    }

    public TransferDto getById(Long id) {
        return toDto(findOrThrow(id));
    }

    public TransferDto getByTransferNumber(String transferNumber) {
        Transfer transfer = transferRepository.findByTransferNumber(transferNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás nem található: " + transferNumber));
        return toDto(transfer);
    }

    public List<TransferDto> getPending() {
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        // Csak az aktuális fiókhoz tartozó bejövő pending átadások
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transferRepository.findByCompanyAndStatus(companyId, Transfer.TransferStatus.PENDING)
                .stream()
                .filter(t -> t.getToBranch().getId().equals(currentBranchId)
                        || t.getFromBranch().getId().equals(currentBranchId))
                .map(this::toDto).collect(Collectors.toList());
    }

    public List<TransferDto> getOutgoing(UUID branchId) {
        return transferRepository.findOutgoingByBranch(branchId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    public List<TransferDto> getIncoming(UUID branchId) {
        return transferRepository.findIncomingByBranch(branchId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    public Page<TransferDto> search(UUID branchId, LocalDate startDate, LocalDate endDate,
                                     Transfer.TransferStatus status, Transfer.TransferType type, Pageable pageable) {
        return transferRepository.search(branchId, startDate, endDate, status, type, pageable)
                .map(this::toDto);
    }

    public long countPending(UUID branchId) {
        return transferRepository.countPendingByBranch(branchId);
    }

    // --- Counter-transaction logic ---

    /**
     * Counter-tranzakciók létrehozása a direction alapján a transfer LÉTREHOZÁSAKOR.
     *
     * F  = Feladó: TRANSFER_OUT a küldő fióknál + kassza csökkentés
     * U  = Vevő: TRANSFER_IN a fogadó fióknál + kassza növelés (fogadó-indítás)
     * UF = Teljes: TRANSFER_OUT + TRANSFER_IN egyszerre + mindkét kassza frissítés
     * FF = Korrekció: két TRANSFER_OUT (mindkét fióknál csökkentés)
     */
    private void createCounterTransactions(Transfer transfer, Worker fromWorker,
                                            Transfer.TransferDirection direction) {
        // #6: soronként könyvelünk (egy-valutás átadásnál egyetlen szintetikus sor a headerből).
        final java.util.List<TransferLine> bookLines = effectiveLines(transfer);
        switch (direction) {
            case F -> {
                for (TransferLine ln : bookLines) {
                    createTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                }
                log.info("F mód — {} sor TRANSFER_OUT: {}", bookLines.size(), transfer.getTransferNumber());
            }
            case U -> {
                for (TransferLine ln : bookLines) {
                    createTransferInTransaction(transfer, fromWorker, transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                    increaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                }
                log.info("U mód — {} sor TRANSFER_IN (fogadó: {}): {}",
                        bookLines.size(), transfer.getFromBranch().getCode(), transfer.getTransferNumber());
            }
            case UF -> {
                for (TransferLine ln : bookLines) {
                    createTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    createTransferInTransaction(transfer, fromWorker, transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                    increaseCashBalance(transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                }
                // UF módban az átadás azonnal COMPLETED
                transfer.setStatus(Transfer.TransferStatus.COMPLETED);
                transfer.setReceivedAmount(transfer.getAmount());
                transfer.setReceivedDate(LocalDate.now());
                transfer.setReceivedTime(LocalTime.now());
                transfer.setDifference(BigDecimal.ZERO);
                log.info("UF mód — {} sor TRANSFER_OUT+IN: {}", bookLines.size(), transfer.getTransferNumber());
            }
            case FF -> {
                for (TransferLine ln : bookLines) {
                    createTransferOutTransaction(transfer, fromWorker, ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getFromBranch(), ln.getCurrency(), ln.getAmount());
                    decreaseCashBalance(transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                }
                createCorrectionTransferOutTransaction(transfer, fromWorker);
                log.info("FF mód — {} sor 2x TRANSFER_OUT: {}", bookLines.size(), transfer.getTransferNumber());
            }
        }
    }

    /**
     * Könyvelendő sorok: ha a transfernek vannak valuta-sorai (#6 multi-line), azokat;
     * különben egyetlen szintetikus sor a header currency+amount-ból (egy-valutás kompat).
     */
    private java.util.List<TransferLine> effectiveLines(Transfer transfer) {
        if (transfer.getLines() != null && !transfer.getLines().isEmpty()) {
            return transfer.getLines();
        }
        return java.util.List.of(TransferLine.builder()
                .currency(transfer.getCurrency())
                .amount(transfer.getAmount())
                .build());
    }

    /**
     * TRANSFER_OUT tranzakció létrehozása a küldő fióknál.
     */
    private Transaction createTransferOutTransaction(Transfer transfer, Worker worker) {
        return createTransferOutTransaction(transfer, worker, transfer.getCurrency(), transfer.getAmount());
    }

    private Transaction createTransferOutTransaction(Transfer transfer, Worker worker, Currency currency, BigDecimal amount) {
        Branch fromBranch = transfer.getFromBranch();
        String receiptNumber = receiptSequenceService.generateReceiptNumber(
                fromBranch.getId(), TransactionType.TRANSFER_OUT);

        Transaction tx = Transaction.builder()
                .company(fromBranch.getCompany())
                .branch(fromBranch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_OUT)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(amount)
                .exchangeRate(BigDecimal.ONE) // Átadásnál nincs árfolyam
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber())
                .notes(String.format("Átadás (%s): %s -> %s [%s]",
                        transfer.getDirection(),
                        fromBranch.getCode(),
                        transfer.getToBranch().getCode(),
                        transfer.getTransferNumber()))
                .build();

        tx = transactionRepository.save(tx);
        log.debug("TRANSFER_OUT tx létrehozva: receipt={}, transfer={}", receiptNumber, transfer.getTransferNumber());
        return tx;
    }

    /**
     * TRANSFER_IN tranzakció létrehozása a megadott fióknál.
     */
    private Transaction createTransferInTransaction(Transfer transfer, Worker worker, Branch atBranch) {
        return createTransferInTransaction(transfer, worker, atBranch, transfer.getCurrency(), transfer.getAmount());
    }

    private Transaction createTransferInTransaction(Transfer transfer, Worker worker, Branch atBranch, Currency currency, BigDecimal amount) {
        Branch sourceBranch = atBranch.getId().equals(transfer.getToBranch().getId())
                ? transfer.getFromBranch() : transfer.getToBranch();
        String receiptNumber = receiptSequenceService.generateReceiptNumber(
                atBranch.getId(), TransactionType.TRANSFER_IN);

        Transaction tx = Transaction.builder()
                .company(atBranch.getCompany())
                .branch(atBranch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_IN)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(amount)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber())
                .notes(String.format("Átvétel (%s): %s <- %s [%s]",
                        transfer.getDirection(),
                        atBranch.getCode(),
                        sourceBranch.getCode(),
                        transfer.getTransferNumber()))
                .build();

        tx = transactionRepository.save(tx);
        log.debug("TRANSFER_IN tx létrehozva: receipt={}, transfer={}", receiptNumber, transfer.getTransferNumber());
        return tx;
    }

    /**
     * FF korrekciós TRANSFER_OUT a fogadó fióknál (második kimenő tranzakció).
     */
    private Transaction createCorrectionTransferOutTransaction(Transfer transfer, Worker worker) {
        Branch toBranch = transfer.getToBranch();
        String receiptNumber = receiptSequenceService.generateReceiptNumber(
                toBranch.getId(), TransactionType.TRANSFER_OUT);

        Transaction tx = Transaction.builder()
                .company(toBranch.getCompany())
                .branch(toBranch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_OUT)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(transfer.getCurrency())
                .currencyAmount(transfer.getAmount())
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(transfer.getHufValue() != null ? transfer.getHufValue() : BigDecimal.ZERO)
                .referenceNumber(transfer.getTransferNumber())
                .notes(String.format("Korrekciós átadás (FF): %s [%s]",
                        toBranch.getCode(), transfer.getTransferNumber()))
                .build();

        tx = transactionRepository.save(tx);
        log.debug("FF korrekciós TRANSFER_OUT tx létrehozva: receipt={}, transfer={}",
                receiptNumber, transfer.getTransferNumber());
        return tx;
    }

    // --- Cash balance updates with pessimistic locking ---

    /**
     * Kassza egyenleg csökkentése PESSIMISTIC LOCK-kal.
     */
    private void decreaseCashBalance(Branch branch, Currency currency, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        String.format("Kassza egyenleg nem található: %s / %s",
                                branch.getCode(), currency.getCode())));

        // Negatív kassza védelem
        if (balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                    "Fiók egyenlege nem elegendő! Iroda: %s, valuta: %s, elérhető: %s, szükséges: %s",
                    branch.getCode(), currency.getCode(), balance.getCurrentBalance(), amount));
        }

        balance.updateBalance(amount, false);
        cashBalanceRepository.save(balance);
        log.debug("Kassza csökkentve: {} {} -= {}", branch.getCode(), currency.getCode(), amount);
    }

    /**
     * Kassza egyenleg növelése PESSIMISTIC LOCK-kal.
     */
    private void increaseCashBalance(Branch branch, Currency currency, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        String.format("Kassza egyenleg nem található: %s / %s",
                                branch.getCode(), currency.getCode())));

        balance.updateBalance(amount, true);
        cashBalanceRepository.save(balance);
        log.debug("Kassza növelve: {} {} += {}", branch.getCode(), currency.getCode(), amount);
    }

    /**
     * Kassza egyenleg frissítés a receive (fogadás) művelet során.
     * Az F módnál a create-nál már megtörtént a fromBranch csökkentés,
     * itt a fogadó oldal történik.
     */
    private void updateCashBalancesOnReceive(Transfer transfer, BigDecimal receivedAmount,
                                              Transfer.TransferDirection direction) {
        switch (direction) {
            case F -> {
                // F mód: a küldő oldal a create-nál már csökkent, itt a fogadó oldal növekszik.
                if (transfer.getLines() != null && !transfer.getLines().isEmpty()) {
                    // #6 multi-line: minden valuta-sor a saját összegével a fogadó kasszájába.
                    for (TransferLine ln : transfer.getLines()) {
                        increaseCashBalance(transfer.getToBranch(), ln.getCurrency(), ln.getAmount());
                        ln.setReceivedAmount(ln.getAmount());
                        ln.setDifference(BigDecimal.ZERO);
                    }
                } else {
                    increaseCashBalance(transfer.getToBranch(), transfer.getCurrency(), receivedAmount);
                }
            }
            case U, UF, FF -> {
                // U/UF/FF: a create-nál már mindkét oldal kassza frissült, receive-nél nincs kassza módosítás
                log.debug("Receive: {} módban nincs további kassza módosítás: {}",
                        direction, transfer.getTransferNumber());
            }
        }
    }

    // --- Helpers ---

    private Transfer findOrThrow(Long id) {
        return transferRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás nem található: " + id));
    }

    private String generateTransferNumber() {
        String prefix = "TR-" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "-";
        long max = transferRepository.findMaxTransferNumber(prefix);
        return prefix + String.format("%04d", max + 1);
    }

    private TransferDto toDto(Transfer t) {
        return TransferDto.builder()
                .id(t.getId())
                .transferNumber(t.getTransferNumber())
                .fromBranchId(t.getFromBranch().getId().toString())
                .fromBranchCode(t.getFromBranch().getCode())
                .fromBranchName(t.getFromBranch().getName())
                .toBranchId(t.getToBranch().getId().toString())
                .toBranchCode(t.getToBranch().getCode())
                .toBranchName(t.getToBranch().getName())
                .fromWorkerId(t.getFromWorker().getId())
                .fromWorkerName(t.getFromWorker().getName())
                .toWorkerId(t.getToWorker() != null ? t.getToWorker().getId() : null)
                .toWorkerName(t.getToWorker() != null ? t.getToWorker().getName() : null)
                .transferType(t.getTransferType().name())
                .transferTypeDisplay(getTransferTypeDisplay(t.getTransferType()))
                .direction(t.getDirection() != null ? t.getDirection().name() : "UF")
                .directionDisplay(getDirectionDisplay(t.getDirection()))
                .status(t.getStatus().name())
                .statusDisplay(getStatusDisplay(t.getStatus()))
                .transferDate(t.getTransferDate().toString())
                .transferTime(t.getTransferTime().toString())
                .receivedDate(t.getReceivedDate() != null ? t.getReceivedDate().toString() : null)
                .receivedTime(t.getReceivedTime() != null ? t.getReceivedTime().toString() : null)
                .currencyId(t.getCurrency().getId())
                .currencyCode(t.getCurrency().getCode())
                .currencyName(t.getCurrency().getName())
                .amount(t.getAmount())
                .hufValue(t.getHufValue())
                .receivedAmount(t.getReceivedAmount())
                .difference(t.getDifference())
                .notes(t.getNotes())
                .carrierName(t.getCarrierName())
                .sealNumber(t.getSealNumber())
                .handoverPrinted(t.getHandoverPrinted())
                .receiptPrinted(t.getReceiptPrinted())
                .createdAt(t.getCreatedAt() != null ? t.getCreatedAt().toString() : null)
                .hasDifference(t.getDifference() != null && t.getDifference().compareTo(BigDecimal.ZERO) != 0)
                .isCompleted(t.getStatus() == Transfer.TransferStatus.COMPLETED)
                .isPending(t.getStatus() == Transfer.TransferStatus.PENDING)
                .lines(mapLines(t))
                .build();
    }

    private java.util.List<hu.puzzleir.valuta.dto.transfer.TransferLineDto> mapLines(Transfer t) {
        if (t.getLines() == null || t.getLines().isEmpty()) {
            return null; // egy-valutás átadás → nincs sor (NON_NULL inclusion miatt kimarad a JSON-ból)
        }
        return t.getLines().stream()
                .sorted(java.util.Comparator.comparing(l -> l.getLineNo() != null ? l.getLineNo() : 0))
                .map(l -> hu.puzzleir.valuta.dto.transfer.TransferLineDto.builder()
                        .currencyId(l.getCurrency().getId())
                        .currencyCode(l.getCurrency().getCode())
                        .currencyName(l.getCurrency().getName())
                        .amount(l.getAmount())
                        .receivedAmount(l.getReceivedAmount())
                        .difference(l.getDifference())
                        .lineNo(l.getLineNo())
                        .build())
                .toList();
    }

    private String getTransferTypeDisplay(Transfer.TransferType type) {
        return switch (type) {
            case CURRENCY -> "Deviza";
            case CASH -> "Készpénz";
            case HANDLING_FEE -> "Kezelési díj";
            case VAULT_DEPOSIT -> "Széf befizetés";
            case VAULT_WITHDRAW -> "Széf kivét";
            case CORRECTION -> "Korrekció";
            case OTHER -> "Egyéb";
        };
    }

    private String getDirectionDisplay(Transfer.TransferDirection direction) {
        if (direction == null) return "Teljes (UF)";
        return switch (direction) {
            case F -> "Feladó (F)";
            case U -> "Vevő (U)";
            case UF -> "Teljes (UF)";
            case FF -> "Korrekció (FF)";
        };
    }

    private String getStatusDisplay(Transfer.TransferStatus status) {
        return switch (status) {
            case PENDING -> "Függőben";
            case IN_TRANSIT -> "Szállítás alatt";
            case RECEIVED -> "Átvéve";
            case COMPLETED -> "Befejezve";
            case REJECTED -> "Elutasítva";
            case CANCELLED -> "Törölve";
        };
    }
}
