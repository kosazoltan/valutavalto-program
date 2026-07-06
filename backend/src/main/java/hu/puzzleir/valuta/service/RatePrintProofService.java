package hu.puzzleir.valuta.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

@Service
@Slf4j
public class RatePrintProofService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String MESSAGE_PREFIX = "RATE-PRINT";

    private final String hmacSecret;

    public RatePrintProofService(
            @Value("${app.rate-print.hmac-secret:}") String hmacSecret,
            @Value("${app.rate-print.hmac-secret-required:false}") boolean secretRequired) {
        if (hmacSecret == null || hmacSecret.isBlank()) {
            if (secretRequired) {
                throw new IllegalStateException(
                        "app.rate-print.hmac-secret kotelezo (APP_RATE_PRINT_HMAC_SECRET env), "
                                + "de nincs beallitva — fail-fast (APP_RATE_PRINT_HMAC_SECRET_REQUIRED=true).");
            }
            this.hmacSecret = UUID.randomUUID().toString();
            log.warn("app.rate-print.hmac-secret nincs beallitva; processz-lokalis rate-print HMAC secret generálva");
        } else {
            this.hmacSecret = hmacSecret;
        }
    }

    public String issueToken(UUID distributionId, UUID branchId, UUID masterRateId, UUID companyId) {
        String message = canonicalMessage(distributionId, branchId, masterRateId, companyId);
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(hmacSecret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            byte[] raw = mac.doFinal(message.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(raw);
        } catch (Exception e) {
            throw new IllegalStateException("Rate Proof-of-Print HMAC token nem állítható elő", e);
        }
    }

    public boolean verifyToken(String token, UUID distributionId, UUID branchId, UUID masterRateId, UUID companyId) {
        if (token == null || token.isBlank()) {
            return false;
        }

        String normalizedToken = token.trim().toLowerCase(Locale.ROOT);
        String expectedToken = issueToken(distributionId, branchId, masterRateId, companyId);
        return MessageDigest.isEqual(
                expectedToken.getBytes(StandardCharsets.UTF_8),
                normalizedToken.getBytes(StandardCharsets.UTF_8));
    }

    private String canonicalMessage(UUID distributionId, UUID branchId, UUID masterRateId, UUID companyId) {
        Objects.requireNonNull(distributionId, "distributionId");
        Objects.requireNonNull(branchId, "branchId");
        Objects.requireNonNull(masterRateId, "masterRateId");
        Objects.requireNonNull(companyId, "companyId");
        return MESSAGE_PREFIX + "|" + distributionId + "|" + branchId + "|" + masterRateId + "|" + companyId;
    }
}
