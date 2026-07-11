package hu.puzzleir.valuta.dto.darius;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record DariusFixingRequestCreateDto(
        UUID bankBranchId,
        LocalDate requestDate,
        String note,
        List<DariusFixingRequestLineDto> lines) {}
