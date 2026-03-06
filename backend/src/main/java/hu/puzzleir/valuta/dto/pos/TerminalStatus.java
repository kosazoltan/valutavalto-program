package hu.puzzleir.valuta.dto.pos;

import java.time.LocalDateTime;

/**
 * POS terminál státusz lekérdezés eredménye.
 */
public record TerminalStatus(
    String terminalId,
    String terminalName,
    String terminalType,
    boolean active,
    boolean reachable,
    LocalDateTime lastTransactionAt,
    String statusMessage
) {

    public static TerminalStatus online(String terminalId, String terminalName, String terminalType,
                                        LocalDateTime lastTransactionAt) {
        return new TerminalStatus(terminalId, terminalName, terminalType, true, true,
                lastTransactionAt, "Terminál elérhető");
    }

    public static TerminalStatus offline(String terminalId, String terminalName, String terminalType,
                                         String reason) {
        return new TerminalStatus(terminalId, terminalName, terminalType, true, false,
                null, reason);
    }

    public static TerminalStatus inactive(String terminalId) {
        return new TerminalStatus(terminalId, null, null, false, false, null, "Terminál inaktív");
    }
}
