package hu.puzzleir.valuta.dto.darius;

import java.util.UUID;

public record DariusBankBranchDto(UUID id, String bankBranchCode, String name, boolean active) {}
