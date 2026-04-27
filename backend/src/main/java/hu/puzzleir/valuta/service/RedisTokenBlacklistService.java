package hu.puzzleir.valuta.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

/**
 * Redis-alapu JWT token blacklist (vezerlokonyv par.12.5).
 *
 * A tokenId (JTI) a Redis kulcs, value: "revoked". TTL = a token hatralevo
 * elettartama. Automatikus tisztitas, nem kell cron.
 *
 * Aktivacio: redis.enabled=true a application.properties-ben.
 */
@Service("redisTokenBlacklistService")
@ConditionalOnProperty(name = "redis.enabled", havingValue = "true")
@RequiredArgsConstructor
@Slf4j
public class RedisTokenBlacklistService {

    private static final String KEY_PREFIX = "jwt:blacklist:";
    private static final String REVOKED_VALUE = "revoked";

    private final RedisTemplate<String, Object> redisTemplate;

    public void blacklist(String tokenId, Instant expiresAt) {
        if (tokenId == null || tokenId.isBlank()) return;
        Duration ttl = Duration.between(Instant.now(), expiresAt);
        if (ttl.isNegative() || ttl.isZero()) {
            // CodeQL java/sensitive-log fix: NEM logoljuk a teljes JTI-t, csak a hashet.
            log.debug("Token mar lejart, nem kerul blacklistre: hash={}", Integer.toHexString(tokenId.hashCode()));
            return;
        }
        String key = KEY_PREFIX + tokenId;
        redisTemplate.opsForValue().set(key, REVOKED_VALUE, ttl.getSeconds(), TimeUnit.SECONDS);
        // CodeQL java/sensitive-log fix: hashelt JTI a debug logban.
        log.debug("Token blacklistre kerult: hash={} TTL={}s", Integer.toHexString(tokenId.hashCode()), ttl.getSeconds());
    }

    public boolean isBlacklisted(String tokenId) {
        if (tokenId == null) return false;
        Boolean exists = redisTemplate.hasKey(KEY_PREFIX + tokenId);
        return Boolean.TRUE.equals(exists);
    }
}
