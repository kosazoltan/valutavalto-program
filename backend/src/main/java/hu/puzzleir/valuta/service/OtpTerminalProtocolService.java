package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.*;
import java.math.BigDecimal;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * OTP POS terminál TCP/IP kommunikációs protokoll.
 *
 * Legacy: Anti\VALUTA\DLL\OTP\DEBUG\Unit2.pas — TOTPTERM class
 *
 * Protokoll leírás (a Delphi forráskódból visszafejtve):
 *
 * 1. Üzenet formátum: [4 byte hossz][STX][parancs][FS mezők...][ETX][LRC hi][LRC lo]
 *    - STX = 0x02, ETX = 0x03, FS = 0x1C (mező elválasztó)
 *    - LRC = XOR az STX utáni bájtokról ETX-ig (hex kódolva: hi/lo nibble)
 *    - A 4 byte-os hossz a STX-től számított teljes üzenethossz (decimális string)
 *
 * 2. Parancsok (A mező = funkció kód):
 *    - A000: Vásárlás (kártyás fizetés)
 *    - A004: Áruvisszavét (refund/backpay)
 *    - A050: Pénztáros belépés
 *    - A051: Pénztáros kilépés + terminál zárás
 *    - A060: Terminál napi zárás (esti zárás)
 *    - A090: Paraméter letöltés
 *    - A095: Kommunikáció ellenőrzés (ComCtrl)
 *    - A100: Sztornó (utolsó érvényes bizonylat érvénytelenítése)
 *    - A101: Válasz/újrapróbálás
 *    - A102: Újranyomtatás
 *
 * 3. Mező kódok (A-Z, 1-indexelt):
 *    - A mező (1): Funkció kód (3 digit)
 *    - B mező (2): Összeg (fillérben, pl. "1234500" = 12345 Ft)
 *    - F mező (6): Válasz kód ("00XX" = OK, "LXXX" = lokális hiba)
 *    - G mező (7): Terminál ID
 *    - L mező (12): Hibaüzenet szöveg
 *    - M mező (13): Pénztáros ID
 *    - Y mező (25): Bizonylat szám + verzió
 *
 * 4. Válasz feldolgozás:
 *    - F mező "00..." vagy "L00" → sikeres
 *    - F mező "880" (paraméter letöltésnél) → sikeres
 *    - Egyéb → hiba
 *
 * 5. TCP/IP: host és port a HARDWARE táblából (POSHOST, POSPORT)
 *
 * 6. Logolás: c:\valuta\log\POS[YYMMDD].log
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class OtpTerminalProtocolService {

    private final PosTerminalConfigService posTerminalConfigService;

    // Protokoll karakterek (Legacy: Unit2.pas konstansok)
    private static final char STX = (char) 0x02;
    private static final char ETX = (char) 0x03;
    private static final char FS  = (char) 0x1C;  // Field Separator

    // Parancs kódok (Legacy: _vasarlas, _backpay, stb.)
    private static final String CMD_PURCHASE     = "A000";  // Vásárlás
    private static final String CMD_REFUND       = "A004";  // Áruvisszavét
    private static final String CMD_LOGIN        = "A050";  // Pénztáros belépés
    private static final String CMD_LOGOUT_CLOSE = "A051";  // Pénztáros kilépés + zárás
    private static final String CMD_DAILY_CLOSE  = "A060";  // Terminál napi zárás
    private static final String CMD_PARAM_LOAD   = "A090";  // Paraméter letöltés
    private static final String CMD_COMM_CHECK   = "A095";  // Kommunikáció ellenőrzés
    private static final String CMD_STORNO       = "A100";  // Sztornó
    private static final String CMD_RETRY        = "A101";  // Válasz újrapróbálás
    private static final String CMD_REPRINT      = "A102";  // Újranyomtatás

    // Protokoll verzió (Legacy: _verzio = '2900')
    private static final String PROTOCOL_VERSION = "2900";

    // Timeout (ms)
    private static final int CONNECT_TIMEOUT = 10_000;
    private static final int READ_TIMEOUT    = 60_000;

    // ============ PUBLIKUS API ============

    /**
     * Kártyás fizetés végrehajtása OTP terminálra.
     * Legacy: Vasarlas() procedure
     *
     * Üzenet: A000 + FS + B[összeg fillérben] + FS + HABDEFKLMOPY + FS + Y[bizonylat_verzió] + ETX
     */
    public PosTransactionResult executePayment(String host, int port, BigDecimal amountHuf,
                                                String receiptNumber) {
        if (amountHuf == null || amountHuf.compareTo(BigDecimal.ZERO) <= 0) {
            return PosTransactionResult.error("Nincs kifizetendő összeg");
        }
        if (receiptNumber == null || receiptNumber.isBlank()) {
            return PosTransactionResult.error("Nincs bizonylatszám");
        }

        // Összeg fillérre konvertálás (Legacy: inttostr(_fizetendo)+'00')
        String amountInFiller = amountHuf.setScale(0, java.math.RoundingMode.HALF_UP)
            .toBigInteger().toString() + "00";

        String yField = receiptNumber + "_" + PROTOCOL_VERSION;

        // Üzenet összeállítása (Legacy: _mess := _vasarlas + FS + _ftfiller + FS + ...)
        String message = CMD_PURCHASE + FS + "B" + amountInFiller + FS
            + "HABDEFKLMOPY" + FS + "Y" + yField + ETX;

        return executeTransaction(host, port, CMD_PURCHASE, "B" + amountInFiller, yField, message);
    }

    /**
     * Kártyás fizetés sztornózása (utolsó érvényes bizonylat).
     * Legacy: Storno() procedure — CMD_STORNO (A100)
     *
     * Üzenet: A100 + FS + Y[bizonylat_verzió] + ETX
     */
    public PosTransactionResult executeStorno(String host, int port, String receiptNumber) {
        if (receiptNumber == null || receiptNumber.isBlank()) {
            return PosTransactionResult.error("Nincs bizonylatszám");
        }

        String yField = receiptNumber + "_" + PROTOCOL_VERSION;
        String message = CMD_STORNO + FS + "Y" + yField + ETX;

        return executeTransaction(host, port, CMD_STORNO, "", yField, message);
    }

    /**
     * Válasz újrapróbálás (utolsó tranzakció eredményének ismételt lekérése).
     * Legacy: — CMD_RETRY (A101)
     *
     * Üzenet: A101 + FS + Y[bizonylat_verzió] + ETX
     */
    public PosTransactionResult executeRetry(String host, int port, String receiptNumber) {
        if (receiptNumber == null || receiptNumber.isBlank()) {
            return PosTransactionResult.error("Nincs bizonylatszám");
        }

        String yField = receiptNumber + "_" + PROTOCOL_VERSION;
        String message = CMD_RETRY + FS + "Y" + yField + ETX;

        return executeTransaction(host, port, CMD_RETRY, "", yField, message);
    }

    /**
     * Bizonylat újranyomtatás.
     * Legacy: Ujranyomtatas() procedure — CMD_REPRINT (A102)
     *
     * Üzenet: A102 + FS + Y[bizonylat_verzió] + ETX
     */
    public PosTransactionResult executeReprint(String host, int port, String receiptNumber) {
        if (receiptNumber == null || receiptNumber.isBlank()) {
            return PosTransactionResult.error("Nincs bizonylatszám");
        }

        String yField = receiptNumber + "_" + PROTOCOL_VERSION;
        String message = CMD_REPRINT + FS + "Y" + yField + ETX;

        return executeTransaction(host, port, CMD_REPRINT, "", yField, message);
    }

    /**
     * Áruvisszavét (visszatérítés kártyára).
     * Legacy: Aruvisszavet() procedure — CMD_REFUND (A004)
     *
     * Üzenet: A004 + FS + B[összeg fillérben] + FS + HABDEFKLMOPY + FS + Y[bizonylat_verzió] + ETX
     */
    public PosTransactionResult executeRefund(String host, int port, BigDecimal amountHuf,
                                               String receiptNumber) {
        if (amountHuf == null || amountHuf.compareTo(BigDecimal.ZERO) <= 0) {
            return PosTransactionResult.error("Nincs átutalandó összeg");
        }
        if (receiptNumber == null || receiptNumber.isBlank()) {
            return PosTransactionResult.error("Nincs bizonylatszám");
        }

        String amountInFiller = amountHuf.setScale(0, java.math.RoundingMode.HALF_UP)
            .toBigInteger().toString() + "00";

        String yField = receiptNumber + "_" + PROTOCOL_VERSION;
        String message = CMD_REFUND + FS + "B" + amountInFiller + FS
            + "HABDEFKLMOPY" + FS + "Y" + yField + ETX;

        return executeTransaction(host, port, CMD_REFUND, "B" + amountInFiller, yField, message);
    }

    /**
     * Pénztáros belépés a terminálra.
     * Legacy: PenztarosBelep() procedure — CMD_LOGIN (A050)
     *
     * Üzenet: A050 + FS + M[prosId] + ETX
     */
    public PosTransactionResult loginCashier(String host, int port, String cashierId) {
        String message = CMD_LOGIN + FS + "M" + cashierId + ETX;
        return executeTransaction(host, port, CMD_LOGIN, "", "", message);
    }

    /**
     * Pénztáros kilépés és terminál zárás — cashierId-vel (M mező).
     * Legacy: PenztarosKilepAndClose() procedure — CMD_LOGOUT_CLOSE (A051)
     *
     * Üzenet: A051 + FS + M[cashierId] + ETX
     */
    public PosTransactionResult logoutCashier(String host, int port, String cashierId) {
        String message = CMD_LOGOUT_CLOSE + FS + "M" + cashierId + ETX;
        return executeTransaction(host, port, CMD_LOGOUT_CLOSE, "", "", message);
    }

    /**
     * Pénztáros kilépés M mező nélkül — visszafelé kompatibilis overload.
     * @deprecated Használd a {@link #logoutCashier(String, int, String)} változatot cashierId-vel.
     */
    @Deprecated
    public PosTransactionResult logoutCashier(String host, int port) {
        String message = CMD_LOGOUT_CLOSE + ETX;
        return executeTransaction(host, port, CMD_LOGOUT_CLOSE, "", "", message);
    }

    // ---- UUID-alapú convenience overloadok ----

    /**
     * Kártyás fizetés — terminál UUID alapján (host/port a DB-ből).
     */
    public PosTransactionResult executePayment(UUID terminalId, BigDecimal amountHuf, String receiptNumber) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return executePayment(addr.host(), addr.port(), amountHuf, receiptNumber);
    }

    /**
     * Sztornó — terminál UUID alapján.
     */
    public PosTransactionResult executeStorno(UUID terminalId, String receiptNumber) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return executeStorno(addr.host(), addr.port(), receiptNumber);
    }

    /**
     * Áruvisszavét — terminál UUID alapján.
     */
    public PosTransactionResult executeRefund(UUID terminalId, BigDecimal amountHuf, String receiptNumber) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return executeRefund(addr.host(), addr.port(), amountHuf, receiptNumber);
    }

    /**
     * Retry (A101) — terminál UUID alapján.
     */
    public PosTransactionResult executeRetry(UUID terminalId, String receiptNumber) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return executeRetry(addr.host(), addr.port(), receiptNumber);
    }

    /**
     * Újranyomtatás (A102) — terminál UUID alapján.
     */
    public PosTransactionResult executeReprint(UUID terminalId, String receiptNumber) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return executeReprint(addr.host(), addr.port(), receiptNumber);
    }

    /**
     * Pénztáros belépés — terminál UUID alapján.
     */
    public PosTransactionResult loginCashier(UUID terminalId, String cashierId) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return loginCashier(addr.host(), addr.port(), cashierId);
    }

    /**
     * Pénztáros kilépés — terminál UUID alapján.
     */
    public PosTransactionResult logoutCashier(UUID terminalId, String cashierId) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return logoutCashier(addr.host(), addr.port(), cashierId);
    }

    /**
     * Napi zárás — terminál UUID alapján.
     */
    public PosClosingResult dailyClose(UUID terminalId) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return dailyClose(addr.host(), addr.port());
    }

    /**
     * Kommunikáció ellenőrzés — terminál UUID alapján.
     */
    public boolean checkConnection(UUID terminalId) {
        PosTerminalConfigService.TerminalAddress addr = posTerminalConfigService.resolve(terminalId);
        return checkConnection(addr.host(), addr.port());
    }

    /**
     * Terminál napi zárás.
     * Legacy: TerminalZaras() procedure — CMD_DAILY_CLOSE (A060)
     */
    public PosClosingResult dailyClose(String host, int port) {
        String message = CMD_DAILY_CLOSE + ETX;
        String fullMessage = buildFullMessage(message);

        try {
            String reply = sendAndReceive(host, port, fullMessage);
            OtpResponse response = parseResponse(reply);

            if (response.isSuccessful()) {
                log.info("OTP terminál napi zárás sikeres: {}:{}", host, port);
                return PosClosingResult.success(0, BigDecimal.ZERO);
            } else {
                log.warn("OTP terminál napi zárás sikertelen: {} — {}", response.errorCode, response.errorMessage);
                return PosClosingResult.failure("OTP terminál napi zárás sikertelen: " + response.errorMessage);
            }
        } catch (Exception e) {
            log.error("OTP terminál napi zárás hiba: {}:{} — {}", host, port, e.getMessage());
            return PosClosingResult.failure("Kommunikációs hiba: " + e.getMessage());
        }
    }

    /**
     * Kommunikáció ellenőrzés (ping).
     * Legacy: ComCtrl() procedure — CMD_COMM_CHECK (A095)
     */
    public boolean checkConnection(String host, int port) {
        String message = CMD_COMM_CHECK + ETX;
        String fullMessage = buildFullMessage(message);

        try {
            String reply = sendAndReceive(host, port, fullMessage);
            OtpResponse response = parseResponse(reply);
            boolean ok = response.isSuccessful();
            log.info("OTP terminál ping: {}:{} → {}", host, port, ok ? "OK" : "FAIL");
            return ok;
        } catch (Exception e) {
            log.warn("OTP terminál ping sikertelen: {}:{} — {}", host, port, e.getMessage());
            return false;
        }
    }

    /**
     * Paraméter letöltés.
     * Legacy: Paraletoltes() procedure — CMD_PARAM_LOAD (A090)
     */
    public boolean downloadParameters(String host, int port) {
        String message = CMD_PARAM_LOAD + ETX;
        String fullMessage = buildFullMessage(message);

        try {
            String reply = sendAndReceive(host, port, fullMessage);
            OtpResponse response = parseResponse(reply);
            // Paraméter letöltésnél: F mező = "880" → sikeres (Legacy: if _fmezo='880' then RESULT := True)
            boolean ok = response.isSuccessful() || "880".equals(response.fField);
            log.info("OTP terminál paraméter letöltés: {}:{} → {}", host, port, ok ? "OK" : "FAIL");
            return ok;
        } catch (Exception e) {
            log.error("OTP terminál paraméter letöltés hiba: {}:{} — {}", host, port, e.getMessage());
            return false;
        }
    }

    // ============ PRIVÁT PROTOKOLL IMPLEMENTÁCIÓ ============

    /**
     * Tranzakció végrehajtása a teljes protokoll workflow-val.
     */
    private PosTransactionResult executeTransaction(String host, int port,
                                                     String sendA, String sendB, String sendY,
                                                     String message) {
        String fullMessage = buildFullMessage(message);

        try {
            String reply = sendAndReceive(host, port, fullMessage);
            OtpResponse response = parseResponse(reply);

            // Ellenőrzések (Legacy: FildSelector)
            // 1. A mező egyezik-e? — mindkét oldalt normalizáljuk: vezető 'A' prefix eltávolítása
            String sentCmdCode = sendA.replaceAll("^A", "");
            String rcvdCmdCode = response.aField != null ? response.aField.replaceAll("^A", "") : "";
            if (!sentCmdCode.equals(rcvdCmdCode)) {
                log.warn("OTP: A mező nem egyezik! Küldött={}, kapott={}", sendA, response.aField);
                // Retry lehetőség — de most error
                return PosTransactionResult.error("OTP protokoll hiba: A mező nem egyezik");
            }

            // 2. B mező (összeg) egyezik-e?
            if (!sendB.isEmpty() && response.bField != null) {
                String bDecoded = response.bField.replaceFirst("^0+", "");
                String expectedB = sendB.startsWith("B") ? sendB.substring(1) : sendB;
                if (!bDecoded.equals(expectedB)) {
                    log.warn("OTP: B mező (összeg) nem egyezik! Küldött={}, kapott={}", expectedB, bDecoded);
                    return PosTransactionResult.error("OTP protokoll hiba: összeg nem egyezik");
                }
            }

            // 3. Eredmény kiértékelés
            if (response.isSuccessful()) {
                log.info("OTP tranzakció sikeres: cmd={}, F={}, G={}", sendA, response.fField, response.gField);
                return PosTransactionResult.approved(
                    response.fField != null ? response.fField : "OTP-OK",
                    response.gField != null ? response.gField : ""
                );
            } else {
                String errorMsg = response.errorMessage != null ? response.errorMessage : "Ismeretlen hiba";
                log.warn("OTP tranzakció elutasítva: cmd={}, F={}, hiba={}", sendA, response.fField, errorMsg);
                return PosTransactionResult.error("OTP terminál elutasítás: " + errorMsg);
            }
        } catch (Exception e) {
            log.error("OTP tranzakció kommunikációs hiba: {}:{} — {}", host, port, e.getMessage(), e);
            return PosTransactionResult.error("Nem sikerült csatlakozni a terminálhoz: " + e.getMessage());
        }
    }

    /**
     * Teljes üzenet összeállítása LRC-vel és hosszal.
     * Legacy: GetMessString() + StringToBytetomb()
     *
     * Formátum: [4 digit hossz][STX][üzenet][LRC_hi][LRC_lo]
     */
    private String buildFullMessage(String message) {
        // LRC számítás az üzenet bájtjaira
        int lrcCode = calculateLrc(message);
        int lrcHi = lrcCode / 16;
        int lrcLo = lrcCode % 16;

        // Hex nibble → ASCII (Legacy: 48 + nibble, ha > 57 akkor +7)
        char lrcHiChar = (char) (lrcHi + 48 + (lrcHi > 9 ? 7 : 0));
        char lrcLoChar = (char) (lrcLo + 48 + (lrcLo > 9 ? 7 : 0));

        String withStxAndLrc = STX + message + lrcHiChar + lrcLoChar;

        // 4 karakteres hossz prefix (Legacy: while length(_lens)<4 do _lens := '0' + _lens)
        String lenStr = String.format("%04d", withStxAndLrc.length());

        return lenStr + withStxAndLrc;
    }

    /**
     * LRC (Longitudinal Redundancy Check) számítás.
     * Legacy: GetLrcKod()
     * XOR az összes bájtra az üzenetben.
     */
    private int calculateLrc(String message) {
        int lrc = 0;
        for (int i = 0; i < message.length(); i++) {
            lrc ^= (int) message.charAt(i);
        }
        return lrc & 0xFF;
    }

    /**
     * TCP/IP küldés és válasz olvasása.
     * Legacy: Csatlakozas() + CsomagKuldes() + idTcpClient1.AllData
     *
     * A válasz formátuma: [4 byte hossz prefix][tartalom]
     * A 4 byte-os hossz megmondja, hány bájtnyi tartalom következik.
     * Így biztosan az egész választ beolvassuk, még ha több TCP csomagban is jön.
     */
    private String sendAndReceive(String host, int port, String fullMessage) throws IOException {
        log.debug("OTP → {}:{} : {}", host, port, escapeForLog(fullMessage));

        try (Socket socket = new Socket()) {
            socket.connect(new java.net.InetSocketAddress(host, port), CONNECT_TIMEOUT);
            socket.setSoTimeout(READ_TIMEOUT);

            // Küldés
            OutputStream out = socket.getOutputStream();
            byte[] messageBytes = fullMessage.getBytes(StandardCharsets.ISO_8859_1);
            out.write(messageBytes);
            out.flush();

            // Válasz olvasása — hossz prefix alapján
            InputStream in = socket.getInputStream();

            // 1. Első 4 bájt: hossz prefix (decimális string, pl. "0042")
            byte[] lenBytes = readExact(in, 4);
            String lenStr = new String(lenBytes, StandardCharsets.ISO_8859_1);
            int contentLength;
            try {
                contentLength = Integer.parseInt(lenStr.trim());
            } catch (NumberFormatException e) {
                throw new IOException("Érvénytelen hossz prefix a válaszban: '" + lenStr + "'");
            }

            if (contentLength <= 0 || contentLength > 8192) {
                throw new IOException("Érvénytelen válasz hossz: " + contentLength);
            }

            // 2. Tartalom beolvasása a megadott hossznak megfelelően
            byte[] contentBytes = readExact(in, contentLength);
            String content = new String(contentBytes, StandardCharsets.ISO_8859_1);

            // Teljes válasz összeállítása (prefix + tartalom — parseResponse STX-et keres)
            String reply = lenStr + content;
            log.debug("OTP ← {}:{} : {}", host, port, escapeForLog(reply));

            if (reply.isEmpty()) {
                throw new IOException("Üres válasz a terminálról");
            }

            return reply;
        }
    }

    /**
     * Pontosan N bájt beolvasása az input stream-ből.
     * Több olvasási ciklussal biztosítja, hogy minden bájt megérkezik.
     */
    private byte[] readExact(InputStream in, int count) throws IOException {
        byte[] buffer = new byte[count];
        int totalRead = 0;
        while (totalRead < count) {
            int bytesRead = in.read(buffer, totalRead, count - totalRead);
            if (bytesRead == -1) {
                throw new IOException(String.format(
                    "Váratlan stream vége: %d/%d bájt olvasva", totalRead, count));
            }
            totalRead += bytesRead;
        }
        return buffer;
    }

    /**
     * OTP válasz feldolgozása — mezőkre bontás + LRC validáció.
     * Legacy: FildSelector() — mező szeparálás FS (0x1C) karakter alapján.
     *
     * A válasz formátuma: [4 digit hossz][STX][A mezőkód][adat][FS][B mezőkód][adat]...[ETX][LRC_hi][LRC_lo]
     * A mezőkód az első karakter: 'A'=1, 'B'=2, ..., 'Z'=26
     */
    private OtpResponse parseResponse(String reply) {
        OtpResponse response = new OtpResponse();

        if (reply == null || reply.length() < 6) {
            response.errorMessage = "Túl rövid válasz";
            return response;
        }

        // STX keresése (Legacy: _pp := 6, a 4 byte hossz + STX után)
        int stxPos = reply.indexOf(STX);
        if (stxPos < 0) {
            response.errorMessage = "Nincs STX a válaszban";
            return response;
        }

        // LRC validáció: a válasz utolsó 2 karaktere a hex-kódolt LRC
        int etxPos = reply.indexOf(ETX, stxPos);
        if (etxPos > 0 && etxPos + 2 < reply.length()) {
            // LRC kiszámítása a STX utáni tartalomra (ETX-ig bezárólag)
            String messageContent = reply.substring(stxPos + 1, etxPos + 1);
            int expectedLrc = calculateLrc(messageContent);
            int expectedHi = expectedLrc / 16;
            int expectedLo = expectedLrc % 16;
            char expectedHiChar = (char) (expectedHi + 48 + (expectedHi > 9 ? 7 : 0));
            char expectedLoChar = (char) (expectedLo + 48 + (expectedLo > 9 ? 7 : 0));

            char actualHiChar = reply.charAt(etxPos + 1);
            char actualLoChar = reply.charAt(etxPos + 2);

            if (actualHiChar != expectedHiChar || actualLoChar != expectedLoChar) {
                log.warn("OTP LRC hiba! Kapott: {}{}, Várt: {}{}", actualHiChar, actualLoChar,
                    expectedHiChar, expectedLoChar);
                response.errorMessage = "LRC checksum hiba — sérült válasz a terminálról";
                return response;
            }
        }

        // Mező értékek kinyerése (Legacy: _fild[1..100] tömb)
        String[] fields = new String[27]; // A-Z + 1 extra
        int pos = stxPos + 1;
        int currentField = -1;
        StringBuilder fieldValue = new StringBuilder();

        while (pos < reply.length()) {
            char ch = reply.charAt(pos);

            if (ch == ETX) {
                // Utolsó mező mentése
                if (currentField >= 1 && currentField <= 26) {
                    fields[currentField] = fieldValue.toString();
                }
                break;
            } else if (ch == FS) {
                // Aktuális mező mentése és következő indítása
                if (currentField >= 1 && currentField <= 26) {
                    fields[currentField] = fieldValue.toString();
                }
                fieldValue = new StringBuilder();
                pos++;
                if (pos < reply.length()) {
                    // Következő mező azonosítója (Legacy: _mezoss := ord(_ry[_pp])-64)
                    currentField = reply.charAt(pos) - 64;
                    if (currentField < 1 || currentField > 26) {
                        // Nem mező azonosító — adat
                        fieldValue.append(reply.charAt(pos));
                        currentField = -1;
                    }
                }
            } else if (currentField == -1 && ch >= 'A' && ch <= 'Z') {
                // Első mező azonosítója
                currentField = ch - 64;
            } else {
                fieldValue.append(ch);
            }

            pos++;
        }

        // Mezők kinyerése (Legacy: _amezo = _Fild[1], _bmezo = _Fild[2], stb.)
        response.aField = fields[1];   // A mező: funkció kód
        response.bField = fields[2];   // B mező: összeg
        response.fField = fields[6];   // F mező: válasz kód
        response.gField = fields[7];   // G mező: terminál ID
        response.lField = fields[12];  // L mező: hibaüzenet
        response.yField = fields[25];  // Y mező: bizonylat

        // F mező max 10 karakter (Legacy: if (length(_fmezo))>10 then _fMezo := leftstr(_fmezo,10))
        if (response.fField != null && response.fField.length() > 10) {
            response.fField = response.fField.substring(0, 10);
        }
        if (response.gField != null && response.gField.length() > 10) {
            response.gField = response.gField.substring(0, 10);
        }

        // Hiba meghatározása
        if (response.fField != null && !response.isSuccessful()) {
            if (response.fField.startsWith("L")) {
                response.errorCode = response.fField.substring(1);
                response.errorMessage = "Lokális hiba: " + response.errorCode;
            } else if (response.fField.length() >= 3) {
                response.errorCode = response.fField.substring(1, Math.min(4, response.fField.length()));
                response.errorMessage = getErrorText(response.errorCode);
            }
        }

        return response;
    }

    /**
     * Hibakód szövegesítése.
     * Legacy: GetHibaText() — a leggyakoribb OTP hibakódok.
     */
    private String getErrorText(String errorCode) {
        return switch (errorCode) {
            case "05"  -> "Kártya elutasítva";
            case "12"  -> "Érvénytelen tranzakció";
            case "13"  -> "Érvénytelen összeg";
            case "14"  -> "Érvénytelen kártya szám";
            case "33"  -> "Lejárt kártya";
            case "36"  -> "Korlátozott kártya";
            case "41"  -> "Elveszett kártya";
            case "43"  -> "Lopott kártya";
            case "51"  -> "Nincs fedezet";
            case "54"  -> "Lejárt kártya";
            case "55"  -> "Hibás PIN kód";
            case "61"  -> "Túl nagy összeg";
            case "65"  -> "Napi limit elérve";
            case "75"  -> "PIN próbálkozás túllépve";
            case "91"  -> "Bank nem elérhető";
            case "96"  -> "Rendszerhiba";
            default    -> "Ismeretlen hiba (" + errorCode + ")";
        };
    }

    /**
     * Vezérlőkarakterek escape-elése log-hoz.
     */
    private String escapeForLog(String s) {
        if (s == null) return "null";
        StringBuilder sb = new StringBuilder();
        for (char c : s.toCharArray()) {
            if (c < 32) {
                sb.append(String.format("[%02X]", (int) c));
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    // ============ BELSŐ VÁLASZ OSZTÁLY ============

    /**
     * OTP terminál válasz struktúra.
     * Legacy: _fild[1..100] tömb → A/B/F/G/L/Y mezők
     */
    static class OtpResponse {
        String aField;      // Funkció kód (3 digit)
        String bField;      // Összeg
        String fField;      // Válasz/hiba kód
        String gField;      // Terminál ID
        String lField;      // Hibaüzenet szöveg
        String yField;      // Bizonylat + verzió
        String errorCode;
        String errorMessage;

        /**
         * Sikeres-e a válasz?
         * Legacy: if (leftstr(_fMezo,2)='00') or (_fMezo='L00') then result := true
         *
         * FONTOS: "880" NEM általános sikerkód — csak paraméter letöltésnél (A090) érvényes!
         * Lásd: downloadParameters() metódus.
         */
        boolean isSuccessful() {
            if (fField == null) return false;
            return fField.startsWith("00") || "L00".equals(fField);
        }
    }
}
