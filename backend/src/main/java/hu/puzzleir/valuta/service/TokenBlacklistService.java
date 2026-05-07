package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.TokenBlacklist;
import hu.puzzleir.valuta.repository.TokenBlacklistRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Token blacklist service — JWT tokenek visszavonásának kezelése.
 *
 * Logout-kor a token tokenId-ja ide kerül, és a JwtAuthenticationFilter
 * minden request-nél ellenőrzi, hogy a token nem lett-e visszavonva.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TokenBlacklistService {
    public static final String REASON_LOGOUT = "LOGOUT";
    public static final String REASON_REFRESH = "REFRESH";
    public static final String REASON_ROLE_CHANGE = "ROLE_CHANGE";
    public static final String REASON_ROLE_REVOKED = "ROLE_REVOKED";

    private final TokenBlacklistRepository tokenBlacklistRepository;

    /**
     * Token hozzáadása a blacklisthez.
     *
     * @param tokenId   JWT-ben lévő tokenId (UUID)
     * @param workerId  A worker aki kijelentkezett
     * @param reason    Oka (LOGOUT, FORCED, ROLE_CHANGE stb.)
     * @param expiresAt A JWT lejárati ideje — ennél tovább nem kell tárolni
     */
    @Transactional(rollbackFor = Exception.class)
    public void blacklistToken(String tokenId, Long workerId, String reason, LocalDateTime expiresAt) {
        if (tokenId == null || tokenBlacklistRepository.existsByTokenId(tokenId)) {
            return; // Már blacklistelve van vagy nincs tokenId
        }

        TokenBlacklist entry = TokenBlacklist.builder()
                .tokenId(tokenId)
                .workerId(workerId)
                .blacklistedAt(LocalDateTime.now())
                .reason(reason)
                .expiresAt(expiresAt)
                .build();

        tokenBlacklistRepository.save(entry);
        // CodeQL java/sensitive-log fix: NEM logoljuk a teljes JWT JTI-t - csak a hashet
        // (auditra elegendo + nem-rekonstrualhato).
        log.info("Token blacklisted: tokenIdHash={}, workerId={}, reason={}",
                Integer.toHexString(tokenId.hashCode()), workerId, reason);
    }

    /**
     * Ellenőrzi, hogy a token visszavonásra került-e.
     */
    public boolean isBlacklisted(String tokenId) {
        if (tokenId == null) return false;
        return tokenBlacklistRepository.existsByTokenId(tokenId);
    }

    /**
     * Lejárt blacklist bejegyzések takarítása — 6 óránként.
     * A JWT max 24 órás, tehát a lejárt bejegyzések már feleslegesek.
     */
    @Scheduled(fixedDelay = 6 * 60 * 60 * 1000L) // 6 óra
    @Transactional(rollbackFor = Exception.class)
    public void cleanupExpiredEntries() {
        int deleted = tokenBlacklistRepository.deleteExpiredEntries(LocalDateTime.now());
        if (deleted > 0) {
            log.info("Token blacklist cleanup: {} lejárt bejegyzés törölve", deleted);
        }
    }
}
