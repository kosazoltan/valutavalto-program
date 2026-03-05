package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.nav.NavSendResult;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * NAV pénztárgép integráció szolgáltatás.
 * Placeholder implementáció — a tényleges COM port kommunikáció későbbi fejlesztés.
 */
@Service
@Slf4j
public class NavIntegrationService {

    /**
     * Tranzakció küldése a NAV pénztárgépnek.
     * Placeholder: mock válasz.
     */
    public NavSendResult sendTransaction(Long transactionId, String comPort) {
        log.info("NAV tranzakció küldés (placeholder): transactionId={}, comPort={}", transactionId, comPort);

        // Mock response — sikeres küldés szimulálása
        return NavSendResult.builder()
                .success(true)
                .receiptNumber("NAV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .error(null)
                .build();
    }

    /**
     * Nyugtaszám fogadása a NAV pénztárgéptől.
     * Placeholder: mock válasz.
     */
    public String receiveReceiptNumber(String comPort) {
        log.info("NAV nyugtaszám fogadás (placeholder): comPort={}", comPort);

        // Mock response
        return "REC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    /**
     * QR kód küldése a NAV pénztárgépnek.
     * Placeholder: mock válasz.
     */
    public boolean sendQrCode(String qrCode, String comPort) {
        log.info("NAV QR kód küldés (placeholder): comPort={}, qrCode length={}", comPort,
                qrCode != null ? qrCode.length() : 0);

        // Mock response — sikeres
        return true;
    }
}
