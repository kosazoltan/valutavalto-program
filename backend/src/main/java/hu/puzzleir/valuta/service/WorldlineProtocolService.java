package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Worldline POS-terminál ÉLES protokoll-driver — VÁZ (scaffold).
 *
 * <p><b>Állapot:</b> NEM IMPLEMENTÁLT. A valós Worldline terminál-kommunikáció (pl. ep2 /
 * Saferpay protokoll TCP/IP üzenetformátum, framing, titkosítás / vagy a Worldline integrációs
 * REST API) megvalósításához a Worldline <b>integrációs protokoll-specifikáció</b> szükséges,
 * ami jelenleg nem áll rendelkezésre a repóban. Protokoll feltalálása TILOS (hallucináció +
 * éles pénzmozgás-kockázat).
 *
 * <p>Amíg a spec meg nem érkezik, ez a service minden műveletre {@link UnsupportedOperationException}-t
 * dob — NEM ad fake jóváhagyást. A {@link PosTerminalService} csak akkor hívja, ha a
 * {@code pos.terminal.worldline.real-driver-enabled=true} flag be van kapcsolva (alapértelmezetten
 * KIKAPCSOLT → a biztonságos bridge-mód fut). Minta a valós implementációhoz:
 * {@link OtpTerminalProtocolService} (működő TCP/IP driver).
 */
@Service
@Slf4j
public class WorldlineProtocolService {

    private static final String NOT_IMPLEMENTED =
            "Worldline éles fizetési driver nincs implementálva — a megvalósításhoz a Worldline "
            + "integrációs protokoll-specifikáció szükséges (ep2/Saferpay TCP/IP üzenetformátum / "
            + "framing / titkosítás vagy REST API). Addig a bridge-mód az alapértelmezett "
            + "(pos.terminal.worldline.real-driver-enabled=false). Protokoll feltalálása tilos.";

    public PosTransactionResult executePayment(BigDecimal amount, String currency, String terminalId) {
        log.error("Worldline real-driver hívás, de NINCS implementálva (terminalId={})", terminalId);
        throw new UnsupportedOperationException(NOT_IMPLEMENTED);
    }

    public PosTransactionResult executeReversal(String originalRef, String terminalId) {
        log.error("Worldline real-driver reversal hívás, de NINCS implementálva (terminalId={})", terminalId);
        throw new UnsupportedOperationException(NOT_IMPLEMENTED);
    }

    public PosClosingResult executeDailyClose(String terminalId) {
        log.error("Worldline real-driver napi zárás hívás, de NINCS implementálva (terminalId={})", terminalId);
        throw new UnsupportedOperationException(NOT_IMPLEMENTED);
    }
}
