package hu.puzzleir.valuta.dto.darius;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record DariusFixingRequestDto(
        UUID id,
        UUID bankBranchId,
        String bankBranchCode,
        String bankBranchName,
        LocalDate requestDate,
        String status,
        String note,
        String createdBy,
        LocalDateTime createdAt,
        String approvedBy,
        LocalDateTime approvedAt,
        LocalDateTime includedAt,
        List<DariusFixingRequestLineDto> lines) {}
