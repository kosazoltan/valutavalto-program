package hu.puzzleir.valuta.dto.darius;

import java.util.List;

public record DariusImportFile(String fileName, byte[] content, List<String> skippedBranches) {
}
