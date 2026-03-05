package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.transfer.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
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
public class TransferService {

    private final TransferRepository transferRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;

    @Transactional
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
                .handoverPrinted(false)
                .receiptPrinted(false)
                .notes(dto.getNotes())
                .build();

        transfer = transferRepository.save(transfer);
        return toDto(transfer);
    }

    @Transactional
    public TransferDto receive(Long id, ReceiveTransferDto dto, Long workerId) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING &&
            transfer.getStatus() != Transfer.TransferStatus.IN_TRANSIT) {
            throw new ValidationException("Csak függőben lévő vagy szállítás alatt lévő átadás fogadható!");
        }

        Worker toWorker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        if (toWorker.getBranch() != null && !toWorker.getBranch().getId().equals(transfer.getToBranch().getId())) {
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

        transfer = transferRepository.save(transfer);
        return toDto(transfer);
    }

    @Transactional
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

    @Transactional
    public void cancel(Long id) {
        Transfer transfer = findOrThrow(id);
        if (transfer.getStatus() != Transfer.TransferStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő átadás törölhető!");
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
        return transferRepository.findByStatus(Transfer.TransferStatus.PENDING)
                .stream().map(this::toDto).collect(Collectors.toList());
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
                .handoverPrinted(t.getHandoverPrinted())
                .receiptPrinted(t.getReceiptPrinted())
                .createdAt(t.getCreatedAt() != null ? t.getCreatedAt().toString() : null)
                .hasDifference(t.getDifference() != null && t.getDifference().compareTo(BigDecimal.ZERO) != 0)
                .isCompleted(t.getStatus() == Transfer.TransferStatus.COMPLETED)
                .isPending(t.getStatus() == Transfer.TransferStatus.PENDING)
                .build();
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
