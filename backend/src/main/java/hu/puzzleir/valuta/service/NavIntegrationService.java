package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.nav.NavSendResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * NAV pénztárgép integráció szolgáltatás.
 * Bridge implementáció: a hardverhívásokat auditálható managed-storage artifactokra fordítja.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NavIntegrationService {

    private final IntegrationTransportProperties integrationTransportProperties;
    private final FileTransportService fileTransportService;

    @Value("${nav.bridge.simulated-success-enabled:false}")
    private boolean bridgeSimulatedSuccessEnabled;

    @jakarta.annotation.PostConstruct
    void warnBridgeMode() {
        log.warn("NAV INTEGRÁCIÓ BRIDGE MÓDBAN FUT — a hardver kommunikáció file-artifact alapú. "
                + "Éles NAV pénztárgép kommunikációhoz valódi serial/API driver szükséges. "
                + "Szimulált siker engedélyezve={}", bridgeSimulatedSuccessEnabled);
    }

    /**
     * Tranzakció küldése a NAV pénztárgépnek.
     */
    public NavSendResult sendTransaction(Long transactionId, String comPort) {
        if (transactionId == null) {
            return NavSendResult.builder()
                .success(false)
                .error("Hiányzó transactionId")
                .build();
        }

        String safeComPort = normalizeComPort(comPort);
        if (!bridgeSimulatedSuccessEnabled) {
            log.warn("NAV tranzakció bridge tiltva, mert nincs éles driver és a szimuláció nincs engedélyezve: "
                    + "transactionId={}, comPort={}", transactionId, safeComPort);
            return NavSendResult.builder()
                .success(false)
                .error(bridgeDisabledMessage("tranzakció küldés"))
                .build();
        }

        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "SEND_TRANSACTION");
            payload.put("transactionId", transactionId);
            payload.put("comPort", safeComPort);
            payload.put("createdAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(resolveNavDir(safeComPort), "nav_tx_" + transactionId, payload);
            String receiptNumber = "NAV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

            log.info("NAV tranzakció bridge artifact létrehozva: transactionId={}, comPort={}, file={}",
                transactionId, safeComPort, artifact);

            return NavSendResult.builder()
                .success(true)
                .receiptNumber(receiptNumber)
                .error(null)
                .build();
        } catch (Exception e) {
            log.error("NAV tranzakció bridge hiba: transactionId={}, comPort={}", transactionId, safeComPort, e);
            return NavSendResult.builder()
                .success(false)
                .error(e.getMessage())
                .build();
        }
    }

    /**
     * Nyugtaszám fogadása a NAV pénztárgéptől.
     */
    public String receiveReceiptNumber(String comPort) {
        String safeComPort = normalizeComPort(comPort);
        if (!bridgeSimulatedSuccessEnabled) {
            log.warn("NAV nyugtaszám bridge tiltva, mert nincs éles driver és a szimuláció nincs engedélyezve: comPort={}",
                    safeComPort);
            return null;
        }

        String receipt = "REC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "RECEIVE_RECEIPT_NUMBER");
            payload.put("comPort", safeComPort);
            payload.put("generatedReceipt", receipt);
            payload.put("createdAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(resolveNavDir(safeComPort), "nav_receipt_poll", payload);
            log.info("NAV nyugtaszám lekérdezés bridge artifact: comPort={}, file={}, receipt={}",
                    safeComPort, artifact, receipt);
        } catch (Exception e) {
            log.warn("NAV nyugtaszám lekérdezés artifact írás sikertelen: comPort={}, error={}",
                    safeComPort, e.getMessage());
        }

        return receipt;
    }

    /**
     * QR kód küldése a NAV pénztárgépnek.
     */
    public boolean sendQrCode(String qrCode, String comPort) {
        if (qrCode == null || qrCode.isBlank()) {
            log.warn("NAV QR kód küldés kihagyva: üres qrCode");
            return false;
        }

        String safeComPort = normalizeComPort(comPort);
        if (!bridgeSimulatedSuccessEnabled) {
            log.warn("NAV QR bridge tiltva, mert nincs éles driver és a szimuláció nincs engedélyezve: comPort={}",
                    safeComPort);
            return false;
        }

        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "SEND_QR");
            payload.put("comPort", safeComPort);
            payload.put("qrCode", qrCode);
            payload.put("qrLength", qrCode.length());
            payload.put("createdAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(resolveNavDir(safeComPort), "nav_qr", payload);
            log.info("NAV QR bridge artifact létrehozva: comPort={}, file={}, qrLength={}",
                    safeComPort, artifact, qrCode.length());
            return true;
        } catch (Exception e) {
            log.error("NAV QR bridge hiba: comPort={}", safeComPort, e);
            return false;
        }
    }

    private String resolveNavDir(String comPort) {
        String safeSyncDir = fileTransportService.sanitizePathSegment(
                integrationTransportProperties.getSync().getDir(), "sync.dir");
        return Paths.get(safeSyncDir, "nav-integration", comPort).toString();
    }

    private String normalizeComPort(String comPort) {
        String fallback = (comPort == null || comPort.isBlank()) ? "COM1" : comPort.trim();
        String normalized = fallback.replaceAll("[^A-Za-z0-9._-]", "_");
        return fileTransportService.sanitizePathSegment(normalized, "comPort");
    }

    private String bridgeDisabledMessage(String action) {
        return "NAV bridge szimuláció tiltva: nincs éles pénztárgép-visszaigazolás (" + action + ")";
    }
}
