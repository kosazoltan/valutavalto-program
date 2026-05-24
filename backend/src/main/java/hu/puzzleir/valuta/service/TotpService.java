package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import com.warrenstrange.googleauth.GoogleAuthenticator;
import com.warrenstrange.googleauth.GoogleAuthenticatorKey;
import hu.puzzleir.valuta.entity.WorkerMfa;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerMfaRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * TOTP (Time-based One-Time Password, RFC 6238) szolgáltatás.
 *
 * <p>Google Authenticator, Authy, Microsoft Authenticator kompatibilis.</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 3 (P2-A — MFA).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class TotpService {

    private final WorkerMfaRepository mfaRepository;
    private final WorkerRepository workerRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;
    private final GoogleAuthenticator gAuth = new GoogleAuthenticator();
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.mfa.issuer:Valutavalto Penztar}")
    private String mfaIssuer;

    /**
     * Enrollment kezdés: új secret generálás (még NEM enabled, csak ENROLLED).
     * Visszaadja a Base32 secret + Google-Auth Otpauth URL + QR code Base64 PNG.
     */
    public EnrollmentResponse startEnrollment(Long workerId) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));

        // Codex P1 #568: ha már enrolled+enabled, NE írjuk felül a meglévő secret-et
        // (a worker véletlenül lock-olná ki magát). Csak ha még nincs aktív MFA, vagy
        // explicit admin disable után engedjük az új enrollment-et.
        Optional<WorkerMfa> existing = mfaRepository.findByWorkerId(workerId);
        if (existing.isPresent() && existing.get().getIsEnrolled() && existing.get().getIsEnabled()) {
            throw new ValidationException(
                    "Az MFA már aktív enrollment állapotban van. Először tiltsd le (admin disable), majd indítsd újra.");
        }

        GoogleAuthenticatorKey key = gAuth.createCredentials();
        String secret = key.getKey();

        // Otpauth URL — saját implementáció (NE használjuk a googleauth getOtpAuthURL-jét,
        // mert az egy api.qrserver.com URL-t ad vissza, ami a SECRET-et harmadik félnek küldené!)
        String otpAuthUrl = buildOtpAuthUrl(mfaIssuer, worker.getCode(), secret);

        // QR code PNG generálás Base64-ben (frontend img tag-ben megjeleníthető)
        String qrPng = generateQrPng(otpAuthUrl);

        // Mentés a DB-be — enrolled=false, enabled=false
        WorkerMfa mfa = existing.orElseGet(() -> WorkerMfa.builder().workerId(workerId).build());
        mfa.setSecret(secret);
        mfa.setType("TOTP");
        mfa.setIsEnrolled(false);
        mfa.setIsEnabled(false);
        mfa.setEnrolledAt(null);
        mfaRepository.save(mfa);

        log.info("MFA enrollment elindítva — workerId={}, issuer={}", workerId, mfaIssuer);
        return EnrollmentResponse.builder()
                .secret(secret)
                .otpAuthUrl(otpAuthUrl)
                .qrCodePngBase64(qrPng)
                .build();
    }

    /**
     * Enrollment befejezés: a user megadta az első TOTP kódot a Google Authenticator-ból,
     * validáljuk + enrolled=true + enabled=true + 8 backup kód generálása.
     */
    public EnrollmentCompleteResponse completeEnrollment(Long workerId, int verificationCode) {
        WorkerMfa mfa = mfaRepository.findByWorkerId(workerId)
                .orElseThrow(() -> new ValidationException("Először indítsd el az enrollment-et"));

        if (mfa.getIsEnrolled()) {
            throw new ValidationException("Az MFA már enrolled állapotban van — disable szükséges az újra-enrolláláshoz");
        }

        if (!gAuth.authorize(mfa.getSecret(), verificationCode)) {
            throw new ValidationException("Érvénytelen TOTP kód — ellenőrizd, hogy a telefonon az óra szinkronban van-e");
        }

        // 8 backup kód generálása (8 számjegyű, bcrypt-elt hash)
        List<String> backupCodesPlain = generateBackupCodes(8);
        String backupCodesHashJson = hashBackupCodes(backupCodesPlain);

        mfa.setIsEnrolled(true);
        mfa.setIsEnabled(true);
        mfa.setEnrolledAt(LocalDateTime.now());
        mfa.setLastVerifiedAt(LocalDateTime.now());
        mfa.setLastUsedCode(String.valueOf(verificationCode));
        mfa.setBackupCodesHashJson(backupCodesHashJson);
        mfaRepository.save(mfa);

        log.info("MFA enrollment befejezve — workerId={}", workerId);

        return EnrollmentCompleteResponse.builder()
                .backupCodes(backupCodesPlain)
                .message("MFA sikeresen aktiválva. Mentsd el a backup kódokat biztonságos helyre!")
                .build();
    }

    /**
     * Bejelentkezéskor a TOTP validálása.
     *
     * @return true ha érvényes, false egyébként (replay protection a `lastUsedCode` ellenőrzésével)
     */
    public boolean verify(Long workerId, int code) {
        Optional<WorkerMfa> mfaOpt = mfaRepository.findByWorkerId(workerId);
        if (mfaOpt.isEmpty() || !mfaOpt.get().getIsEnabled()) {
            return false;
        }
        WorkerMfa mfa = mfaOpt.get();
        String codeStr = String.valueOf(code);

        // Replay protection: ugyanaz a kód egymás után nem használható
        if (codeStr.equals(mfa.getLastUsedCode())) {
            log.warn("MFA replay attempt — workerId={}, code={}", workerId, code);
            return false;
        }

        if (gAuth.authorize(mfa.getSecret(), code)) {
            mfa.setLastVerifiedAt(LocalDateTime.now());
            mfa.setLastUsedCode(codeStr);
            mfaRepository.save(mfa);
            return true;
        }
        return false;
    }

    /**
     * MFA letiltása (admin parancs).
     */
    public void disable(Long workerId) {
        WorkerMfa mfa = mfaRepository.findByWorkerId(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker MFA nem található: " + workerId));
        mfa.setIsEnabled(false);
        mfaRepository.save(mfa);
        log.warn("MFA letiltva — workerId={}", workerId);
    }

    /**
     * Van-e enabled MFA a workerhez?
     */
    @Transactional(readOnly = true)
    public boolean isMfaRequired(Long workerId) {
        return mfaRepository.existsByWorkerIdAndIsEnabledTrue(workerId);
    }

    // ==========================================================================
    // Helper-ek
    // ==========================================================================

    /**
     * Otpauth URL építés a Google Authenticator spec szerint.
     * Spec: <a href="https://github.com/google/google-authenticator/wiki/Key-Uri-Format">Key-Uri-Format</a>
     */
    private String buildOtpAuthUrl(String issuer, String accountName, String base32Secret) {
        String encodedIssuer = java.net.URLEncoder.encode(issuer, java.nio.charset.StandardCharsets.UTF_8);
        String encodedAccount = java.net.URLEncoder.encode(accountName, java.nio.charset.StandardCharsets.UTF_8);
        return String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s&algorithm=SHA1&digits=6&period=30",
                encodedIssuer, encodedAccount, base32Secret, encodedIssuer);
    }

    private String generateQrPng(String otpAuthUrl) {
        try {
            QRCodeWriter writer = new QRCodeWriter();
            Map<EncodeHintType, Object> hints = Map.of(
                    EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M,
                    EncodeHintType.MARGIN, 1);
            BitMatrix matrix = writer.encode(otpAuthUrl, BarcodeFormat.QR_CODE, 240, 240, hints);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(matrix, "PNG", baos);
            return Base64.getEncoder().encodeToString(baos.toByteArray());
        } catch (Exception e) {
            log.error("QR code generálás hiba", e);
            throw new RuntimeException("QR code generálás sikertelen", e);
        }
    }

    private List<String> generateBackupCodes(int count) {
        return java.util.stream.IntStream.range(0, count)
                .mapToObj(i -> String.format("%08d", secureRandom.nextInt(100_000_000)))
                .toList();
    }

    // PP-16: BCrypt 12-es erősség — offline brute-force ellen védett (10^8 kombináció, de lassú hash)
    private String hashBackupCodes(List<String> codes) {
        try {
            List<String> hashed = new ArrayList<>();
            for (String code : codes) {
                hashed.add(passwordEncoder.encode(code));
            }
            return objectMapper.writeValueAsString(hashed);
        } catch (Exception e) {
            log.error("Backup kódok hashelése sikertelen", e);
            throw new RuntimeException("Backup kód generálása sikertelen", e);
        }
    }

    /**
     * MFA backup kód ellenőrzése bejelentkezéskor (ha a TOTP eszköz nem elérhető).
     * A kód egyszeri felhasználású — sikeres ellenőrzés után törlődik a tárolt listából.
     *
     * @param workerId a bejelentkezni próbáló worker azonosítója
     * @param code     a felhasználó által megadott 8 jegyű backup kód
     * @return true ha érvényes és felhasználható kód
     */
    public boolean verifyBackupCode(Long workerId, String code) {
        Optional<WorkerMfa> mfaOpt = mfaRepository.findByWorkerId(workerId);
        if (mfaOpt.isEmpty() || !mfaOpt.get().getIsEnabled()) {
            return false;
        }
        WorkerMfa mfa = mfaOpt.get();
        String json = mfa.getBackupCodesHashJson();
        if (json == null || json.isBlank()) {
            return false;
        }
        try {
            List<String> hashes = new ArrayList<>(
                    objectMapper.readValue(json, new TypeReference<List<String>>() {}));
            for (int i = 0; i < hashes.size(); i++) {
                if (passwordEncoder.matches(code, hashes.get(i))) {
                    hashes.remove(i);
                    mfa.setBackupCodesHashJson(objectMapper.writeValueAsString(hashes));
                    mfaRepository.save(mfa);
                    log.info("MFA backup kód felhasználva — workerId={}, maradék={}", workerId, hashes.size());
                    return true;
                }
            }
        } catch (Exception e) {
            log.error("Backup kód ellenőrzés hiba — workerId={}", workerId, e);
        }
        return false;
    }

    // ==========================================================================
    // Response DTOs
    // ==========================================================================

    @Data @Builder @AllArgsConstructor
    public static class EnrollmentResponse {
        private String secret;
        private String otpAuthUrl;
        private String qrCodePngBase64;
    }

    @Data @Builder @AllArgsConstructor
    public static class EnrollmentCompleteResponse {
        private List<String> backupCodes;
        private String message;
    }
}
