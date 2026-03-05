package hu.puzzleir.valuta.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.EnumMap;
import java.util.Map;

/**
 * QR kód generátor szolgáltatás.
 *
 * ZXing (Zebra Crossing) library-val generál QR kódokat különböző célokra:
 * - Tranzakciós nyugta
 * - Napi nyitás
 * - Napi zárás
 *
 * A generált QR kódok PNG formátumú byte tömböt adnak vissza.
 */
@Service
@Slf4j
public class QrCodeService {

    private static final int DEFAULT_QR_SIZE = 300;
    private static final String PNG_FORMAT = "PNG";
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE;

    /**
     * Tranzakciós QR kód generálása.
     *
     * A QR kód tartalma JSON formátumú:
     * {@code {"type":"TRANSACTION","receipt":"B-2026-001234","amount":"150.00","currency":"EUR","ts":"2026-03-05"}}
     *
     * @param receiptNumber bizonylat szám (pl. "B-2026-001234")
     * @param amount        tranzakció összege
     * @param currencyCode  ISO 4217 valutakód (pl. "EUR")
     * @return PNG képfájl byte tömbje
     */
    public byte[] generateTransactionQr(String receiptNumber, BigDecimal amount, String currencyCode) {
        if (receiptNumber == null || receiptNumber.isBlank()) {
            throw new IllegalArgumentException("A bizonylat szám nem lehet üres");
        }
        if (amount == null) {
            throw new IllegalArgumentException("Az összeg nem lehet null");
        }
        if (currencyCode == null || currencyCode.isBlank()) {
            throw new IllegalArgumentException("A valutakód nem lehet üres");
        }

        String content = String.format(
                "{\"type\":\"TRANSACTION\",\"receipt\":\"%s\",\"amount\":\"%s\",\"currency\":\"%s\",\"ts\":\"%s\"}",
                escapeJson(receiptNumber),
                amount.toPlainString(),
                escapeJson(currencyCode.toUpperCase()),
                LocalDate.now().format(DATE_FORMATTER)
        );

        log.debug("Tranzakciós QR generálás: receipt={}, amount={} {}", receiptNumber, amount, currencyCode);
        return generateQrCode(content, DEFAULT_QR_SIZE);
    }

    /**
     * Napi nyitás QR kód generálása.
     *
     * A QR kód tartalma JSON formátumú:
     * {@code {"type":"DAILY_OPEN","branch":"BP-01","date":"2026-03-05"}}
     *
     * @param branchCode iroda kód (pl. "BP-01")
     * @param date       nyitás dátuma
     * @return PNG képfájl byte tömbje
     */
    public byte[] generateDailyOpenQr(String branchCode, LocalDate date) {
        if (branchCode == null || branchCode.isBlank()) {
            throw new IllegalArgumentException("Az iroda kód nem lehet üres");
        }
        if (date == null) {
            throw new IllegalArgumentException("A dátum nem lehet null");
        }

        String content = String.format(
                "{\"type\":\"DAILY_OPEN\",\"branch\":\"%s\",\"date\":\"%s\"}",
                escapeJson(branchCode),
                date.format(DATE_FORMATTER)
        );

        log.debug("Napi nyitás QR generálás: branch={}, date={}", branchCode, date);
        return generateQrCode(content, DEFAULT_QR_SIZE);
    }

    /**
     * Napi zárás QR kód generálása.
     *
     * A QR kód tartalma JSON formátumú:
     * {@code {"type":"DAILY_CLOSE","branch":"BP-01","date":"2026-03-05","turnover":"1234567.00"}}
     *
     * @param branchCode    iroda kód (pl. "BP-01")
     * @param date          zárás dátuma
     * @param totalTurnover napi forgalom összege
     * @return PNG képfájl byte tömbje
     */
    public byte[] generateDailyCloseQr(String branchCode, LocalDate date, BigDecimal totalTurnover) {
        if (branchCode == null || branchCode.isBlank()) {
            throw new IllegalArgumentException("Az iroda kód nem lehet üres");
        }
        if (date == null) {
            throw new IllegalArgumentException("A dátum nem lehet null");
        }
        if (totalTurnover == null) {
            throw new IllegalArgumentException("A forgalom összeg nem lehet null");
        }

        String content = String.format(
                "{\"type\":\"DAILY_CLOSE\",\"branch\":\"%s\",\"date\":\"%s\",\"turnover\":\"%s\"}",
                escapeJson(branchCode),
                date.format(DATE_FORMATTER),
                totalTurnover.toPlainString()
        );

        log.debug("Napi zárás QR generálás: branch={}, date={}, turnover={}", branchCode, date, totalTurnover);
        return generateQrCode(content, DEFAULT_QR_SIZE);
    }

    // ── Belső segédmetódusok ─────────────────────────────────────────────

    /**
     * QR kód generálása a megadott tartalommal.
     *
     * @param content   QR kód tartalma (szöveges)
     * @param size      kép mérete (pixel, négyzetesen)
     * @return PNG byte tömb
     */
    private byte[] generateQrCode(String content, int size) {
        try {
            Map<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
            hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
            hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
            hints.put(EncodeHintType.MARGIN, 2);

            QRCodeWriter writer = new QRCodeWriter();
            BitMatrix bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, size, size, hints);

            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(bitMatrix, PNG_FORMAT, outputStream);

            byte[] result = outputStream.toByteArray();
            log.trace("QR kód generálva: {} byte, {}x{} px", result.length, size, size);
            return result;

        } catch (WriterException e) {
            log.error("QR kód kódolási hiba: {}", e.getMessage(), e);
            throw new RuntimeException("QR kód generálási hiba: " + e.getMessage(), e);
        } catch (IOException e) {
            log.error("QR kód I/O hiba: {}", e.getMessage(), e);
            throw new RuntimeException("QR kód kiírási hiba: " + e.getMessage(), e);
        }
    }

    /**
     * Egyszerű JSON escape: idézőjel és backslash.
     */
    private static String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
